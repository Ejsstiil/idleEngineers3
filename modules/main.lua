local import = import
local _G = _G
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
local EntityCategoryContains = EntityCategoryContains
----------------------
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Util = import('/lua/utilities.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local isGameUIHidden = function() return import('/lua/ui/game/gamemain.lua').gameUIHidden end
----------------------
local debug = false
local LOG = function(...)
    if debug then
        _G.LOG("-ie3-:", repr(arg)) -- just for debug
    end
end
----------------------
local modPath = '/mods/idleEngineers3/'
local Select = import(modPath .. 'modules/select.lua')

local globalsKey = 'ie3'
local all_units = {}
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
local colorIdle = 'ffff0400'
local colorWorking = 'ffffffff'

function OnBeat()
    if sessionIsPaused() then return end

    local tick = gameTick()
    local modulo = tick - math.floor(tick / 10) * 10

    if modulo == 0 then
        _selectAppropriate()
    end

end

function _selectAppropriate()

    if getFocusArmy() > 0 then
        Select.Hidden(function()
            --function INFO: UISelectionByCategory(expression, addToCurSel, inViewFrustum, nearestToMouse, mustBeIdle)
            --UISelectionByCategory("LAND ENGINEER, FACTORY, SUBCOMMANDER, FIELDENGINEER, ENGINEERSTATION, MASSEXTRACTION", false, true, false, false)
            uiSelectionByCategory(categString, false, false, false, false)
            local un = getSelectedUnits() or {}
            for _, u in un do
                all_units[u:GetEntityId()] = u
            end
        end)
        --LOG("in table:" .. table.getn(all_units))
        --table.print(all_units)
        ManageOverlays()
    else
        TearDown(overlays)
    end
end

function ManageOverlays()
    ForkThread(function()
        for i, u in all_units do
            if (isDestroyed(u)) then
                DestroyOverlay(i)
                all_units[i] = nil
            else
                if not overlays[i] then
                    CreateOverlay(i, u)
                end
            end
        end
        --table.print(overlays)
        if debug then
            --for teardown, copy to globals
            _G[globalsKey] = {}
            _G[globalsKey].overlays = overlays
        end
    end)
end

function CreateOverlay(i, u)
    if not u then
        DestroyOverlay(i)
        return
    end
    if overlays[i] then
        DestroyOverlay(i)
    end
    LOG('create layer ' .. i .. ' for unit ' .. u:GetUnitId())

    overlays[i] = _CreateUnitOverlay(u)

    --reprsl(overlays[i])

    LOG(sizeof(overlays))
end

function DestroyOverlay(i)
    if not overlays[i] then return end
    LOG('mark to destroy layer ' .. i)
    overlays[i].destroy = true
end

function _removeOverlay(i)
    LOG('remove layer ' .. i)
    overlays[i] = nil
    LOG(sizeof(overlays))
end

--[[function updateArmyTotals()

    if (current_army > 0) then
        local currentScores = import('/lua/ui/game/score.lua').currentScores
        army_units[current_army] = currentScores[current_army].general.currentunits
        print(currentScores[current_army].general.currentunits)
        return currentScores[current_army].general.currentunits
    end
end
]]


function GetTechLevelString(bp)
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

function myGetTechLevelString(bp)
    local tech = GetTechLevelString(bp)
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

function _CreateUnitOverlay(unit, overlayId)
    --[[
    --disable when in Screen Capture mode
    if import('/lua/ui/game/gamemain.lua').gameUIHidden then
        return
    end
    if sessionIsPaused() then return end
]]
    --if unit:IsBeingBuilt() then ibb = 10 end -- set engy label higher when being built
    --local worldView = import('/lua/ui/game/worldview.lua').viewLeft
    local worldView = import('/lua/ui/game/worldview.lua').GetWorldViews()['WorldCamera']
    local overlay = Bitmap(GetFrame(0))
    local ovParams = myGetTechLevelString(unit:GetBlueprint())

    --print(repr(unit))

    overlay.destroy = false
    overlay:SetSolidColor(ovParams.bgColor) -- color of overlay background
    overlay:SetAlpha(.8)
    overlay:DisableHitTest()
    overlay:SetFrameRate(0)
    overlay:SetFramePattern({ 0 })
    overlay:SetNeedsFrameUpdate(true)
    overlay.unit = unit
    overlay.id = unit:GetEntityId()
    overlay.time = 0

    overlay.text = UIUtil.CreateText(overlay, '0', 6 + ovParams.size, UIUtil.fixedFont, true)
    overlay.text:SetText(ovParams.label)

    overlay.Width:Set(function() return max(overlay.text.Width() + (1.5 * ovParams.size), 8) end)
    overlay.Height:Set(function() return 10 + (0.5 * ovParams.size) end)

    LayoutHelpers.AtCenterIn(overlay.text, overlay, 0, 0)

    overlay.OnFrame = function(self, delta)
        local selfUnit = self.unit
        if sessionIsPaused() then
            self:Hide()
            return
        end
        local removeExternals = _removeOverlay

        self.time = self.time + delta

        if isDestroyed(selfUnit) or self.destroy or not selfUnit:GetBlueprint() then
            self:Hide()
            self.destroy = true
            self:SetNeedsFrameUpdate(false)
            removeExternals(self.id)
            --self = nil
            return
        end

        if isDestroyed(worldView) then
            worldView = import('/lua/ui/game/worldview.lua').GetWorldViews()['WorldCamera']
        end

        if not worldView:GetScreenPos(selfUnit) or isObserver() or isGameUIHidden() then
            self.time = 0
            self:Hide()
            return
        else
            if self.time > 0.4 then
                self:Show()
            end
        end

        if not selfUnit:IsDead() and not isDestroyed(selfUnit) then
            --table.print(ScreenPos)

            local vec = selfUnit:GetPosition()
            local pos = worldView:Project({ vec[1], vec[2] * ovParams.groundHeight, vec[3] })
            self.Left:Set(function()
                return worldView.Left() + pos.x - self.Width() / 2
            end)
            self.Top:Set(function()
                return (worldView.Top() + pos.y - self.Height() / 2 - 2) - ovParams.offsetTop
            end)

            --print(ScreenPos[1])

            --self.Left:Set(ScreenPos[1] - self.Width() / 2)
            --self.Top:Set((ScreenPos[2] - self.Height() / 2 - 2) - offset)

            if selfUnit:IsIdle() then
                self.text:SetColor(ovParams.colorIdle)
            else
                self.text:SetColor(ovParams.colorWorking)
            end
        end


    end

    return overlay
end

function TearDown()
    for i, u in overlays do
        DestroyOverlay(i)
    end
    overlays = {}
    if debug then
        table.print(overlays)
        _G[globalsKey].overlays = {}
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
