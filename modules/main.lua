------ upvalues ------
local import = import
local categories = categories
local isObserver = IsObserver
local sessionIsPaused = SessionIsPaused
local gameTick = GameTick
local getFocusArmy = GetFocusArmy
local uiSelectionByCategory = UISelectionByCategory
local getSelectedUnits = GetSelectedUnits
local isDestroyed = IsDestroyed
local max = math.max
local join = table.concat
local sizeof = table.getsize
local str_repeat = string.rep
local GetFrame = GetFrame
local EntityCategoryContains = EntityCategoryContains
----------------------
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local isGameUIHidden = function() return import('/lua/ui/game/gamemain.lua').gameUIHidden end
----------------------
local debug = false
local LOG = function(...)
    if debug then
        LOG("-ie3-:", repr(arg)) -- just for debug
    end
end
----------------------
local modPath = '/mods/idleEngineers3/'
local Select = import(modPath .. 'modules/select.lua')
local globalsKey = 'ie3'

local watchedCategories = {
    "LAND ENGINEER",
    "FACTORY",
    "SUBCOMMANDER",
    "FIELDENGINEER",
    --"(POD * ENGINEER - ENGINEERSTATION)", -- too slow when crowding them
    "MASSEXTRACTION"
}
local categString = join(watchedCategories, ', ')
local overlays = {}
local bgColor = 'FF000000' --argb
local colorIdle = 'ffff0000'
local colorIdleNoProgress = 'ffFF5500' -- idling and also doing nothing, eq. not reclaiming
local colorWorkingNoProgress = 'ffff6600' --helping but doing nothing
local colorWorking = 'ffffffff'

----------------------------

local function destroyOverlay(i)
    if not overlays[i] then return end
    LOG('mark to destroy layer ' .. i)
    overlays[i].destroy = true
    overlays[i]:Destroy()
    overlays[i] = nil
end

local function tearDown()
    for i, u in overlays do
        destroyOverlay(i)
    end
    overlays = {}
    if debug then
        table.print(overlays)
        _G[globalsKey].overlays = {}
    end
end

local function createUnitOverlay(unit, overlayId)
    if debug then
        import('/lua/lazyvar.lua').ExtendedErrorMessages = true
    end

    local function getTechLevelString(bp)
        local function getTechLevel(bp)
            if EntityCategoryContains(categories.TECH1, bp.BlueprintId) then
                return 1
            elseif EntityCategoryContains(categories.TECH2, bp.BlueprintId) then
                return 2
            elseif EntityCategoryContains(categories.TECH3, bp.BlueprintId) then
                return 3
            else
                return 4
            end
        end
    
        local tech = getTechLevel(bp)
        local ovParams = { label = "?", size = tech, offsetTop = 0, groundHeight = 1.025, bgColor = bgColor,
            colorIdle = colorIdle, colorWorking = colorWorking }
        if EntityCategoryContains(categories.COMMAND, bp.BlueprintId) then
            ovParams.label = 'A'
            ovParams.size = 2
        elseif EntityCategoryContains(categories.SUBCOMMANDER, bp.BlueprintId) then
            ovParams.label = 'S'
            ovParams.size = 4
        elseif EntityCategoryContains(categories.EXPERIMENTAL * categories.FACTORY, bp.BlueprintId) then
            ovParams.label = '▼'
            ovParams.size = 4
        elseif EntityCategoryContains(categories.FACTORY, bp.BlueprintId) then
            ovParams.label = 'FAC'
            ovParams.offsetTop = 10
        elseif EntityCategoryContains(categories.FIELDENGINEER, bp.BlueprintId) then
            ovParams.label = 'F'
            ovParams.groundHeight = 1.01
        elseif EntityCategoryContains(categories.ENGINEER, bp.BlueprintId) then
            ovParams.size = tech
            ovParams.label = tech
            ovParams.groundHeight = (tech * 0.005) + 1 -- ground height by tech
        elseif EntityCategoryContains(categories.MASSEXTRACTION, bp.BlueprintId) then
            ovParams.label = str_repeat("I", tech)
            ovParams.colorIdle = 'ff00FF00' -- means normal operation
            ovParams.colorWorking = 'ffff00e1' -- means upgrading
        end
    
        return ovParams
    end
    
    local worldView = import('/lua/ui/game/worldview.lua').GetWorldViews()['WorldCamera']
    local ovParams = getTechLevelString(unit:GetBlueprint())

    local overlay = Bitmap(GetFrame(0))
    overlay:SetNeedsFrameUpdate(false)
    overlay.destroy = false
    overlay:SetSolidColor(ovParams.bgColor) -- color of overlay background
    overlay:SetAlpha(.8)
    overlay:DisableHitTest()
    overlay:SetFrameRate(1)
    overlay:SetFramePattern({ 0 })
    overlay.unit = unit
    overlay.id = unit:GetEntityId()
    overlay.time = 0

    overlay.OnFrame = function(self, delta)
        if sessionIsPaused() then
            self:Hide()
            return
        end

        self.time = self.time + delta

        if isDestroyed(self.unit) or self.destroy or not self.unit:GetBlueprint() or self.unit:IsDead() then
            self:Hide()
            self.destroy = true
            self:SetNeedsFrameUpdate(false)
            return
        end

        if isDestroyed(worldView) then
            worldView = import('/lua/ui/game/worldview.lua').GetWorldViews()['WorldCamera']
            return
        end

        if not worldView:GetScreenPos(self.unit) or isObserver() or isGameUIHidden() then
            self.time = 0
            self:Hide()
            self:SetFrameRate(0)
            return
        else
            if self.time > 0.4 then
                self:SetFrameRate(1)
                self:Show()
            end
        end

        if not self.unit:IsDead() and not isDestroyed(self.unit) then
            --table.print(ScreenPos)

            local vec = self.unit:GetPosition()
            local pos = worldView:Project({ vec[1], vec[2] * ovParams.groundHeight, vec[3] })
            overlay.Left:Set(function()
                return worldView.Left() + pos.x - self.Width() / 2
            end)
            self.Top:Set(function()
                return (worldView.Top() + pos.y - self.Height() / 2 - 2) - ovParams.offsetTop
            end)

            local progress = self.unit:GetWorkProgress()
            local idle = self.unit:IsIdle()
            local mode = self.unit:IsAutoMode()
            if idle == true then
                --print(progress, self.unit:GetBlueprint().BlueprintId, mode)
                if progress == 0 then
                    self.text:SetColor(ovParams.colorIdle)
                else
                    self.text:SetColor(colorIdleNoProgress)
                end
            else
                if progress == 0 then
                    self.text:SetColor(colorWorkingNoProgress)
                else
                    self.text:SetColor(ovParams.colorWorking)
                end
            end
        end
    end

    

    overlay.text = UIUtil.CreateText(overlay, '0', 6 + ovParams.size, UIUtil.fixedFont, true)
    overlay.text:SetText(ovParams.label)

    LayoutHelpers.SetDimensions(overlay, 8, 8)
    LayoutHelpers.SetDimensions(overlay,
        max(overlay.text.Width() + (1.5 * ovParams.size), 8),
        10 + (0.5 * ovParams.size)
    )
    LayoutHelpers.AtCenterIn(overlay.text, overlay, 0, 0)

    overlay:SetNeedsFrameUpdate(true)
    return overlay
end

local function manageOverlays(units)
    for i, unit in units do
        if not overlays[i] or overlays[i].destroy ~= false then
            overlays[i] = createUnitOverlay(unit)
        end
    end
    for i, unit in overlays do
        if overlays[i].destroy and isDestroyed(overlays[i].unit) then
            destroyOverlay(i)
        end
    end

    if debug then
        --for teardown, copy to globals
        _G[globalsKey] = {}
        _G[globalsKey].overlays = overlays
    end
end

local function selectAppropriate()
    if getFocusArmy() > 0 then
        local units = {}
        Select.Hidden(function()
            --function INFO: UISelectionByCategory(expression, addToCurSel, inViewFrustum, nearestToMouse, mustBeIdle)
            --UISelectionByCategory("LAND ENGINEER, FACTORY, SUBCOMMANDER, FIELDENGINEER, ENGINEERSTATION, MASSEXTRACTION", false, true, false, false)
            uiSelectionByCategory(categString, false, false, false, false)
            units = getSelectedUnits() or {}
            for _, u in units do
                units[u:GetEntityId()] = u
            end
        end)
        manageOverlays(units)
    else
        tearDown()
    end
end

function OnBeat()
    if sessionIsPaused() then return end

    local tick = gameTick()

    if tick < 80 then return end -- delay our stuff, let UI-party do its start sequence

    local modulo = tick - math.floor(tick / 10) * 10
    if modulo == 0 then
        selectAppropriate()
    end
end

function OnChangeDetected()
    local a, b = pcall(function()
        LOG("iE3-OnChangeDetected")
        --teardown
        if rawget(_G, "ie3") ~= nil then
            for i, u in _G[globalsKey].overlays do
                _G[globalsKey].overlays[i].destroy = true
            end
        end
    end)
    if not a then LOG("iE3-OnChangeDetected RESULT: ", a, b) end
end

OnChangeDetected()
--LOG(repr(debug.listcode(_CreateUnitOverlay)))
