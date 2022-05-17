local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')
local Util = import('/lua/utilities.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local isGameUIHidden = function() return import('/lua/ui/game/gamemain.lua').gameUIHidden end
----------------------
local isObserver = IsObserver
local sessionIsPaused = SessionIsPaused
local gameTick = GameTick
local getFocusArmy = GetFocusArmy
local uiSelectionByCategory = UISelectionByCategory
local getSelectedUnits = GetSelectedUnits
local isDestroyed = IsDestroyed
----------------------
local LOG = function(...)
    _G.LOG("-ie3-:", repr(arg))
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
    "ENGINEERSTATION",
    --"MASSEXTRACTION"
}
local ovParams = { label = "", size = 0, offset = 0 }
local overlays = {}
local bgColor = 'FF000000' --argb
local colorIdle = 'ffff0400'

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
            uiSelectionByCategory(table.concat(watchedCategories, ', '), false, false, false, false)
            local un = getSelectedUnits() or {}
            for _, u in un do
                all_units[u:GetEntityId()] = u
            end
        end)
        --LOG("in table:" .. table.getn(all_units))
        --table.print(all_units)
        UpdateUnits()
    else
        TearDown()
    end
end

function UpdateUnits()
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

    --for teardown
    _G[globalsKey] = {}
    _G[globalsKey].overlays = overlays
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

    LOG(table.getsize(overlays))
end

function DestroyOverlay(i)
    if not overlays[i] then return end
    LOG('mark to destroy layer ' .. i)
    overlays[i].destroy = true
end

function _removeOverlay(i)
    LOG('remove layer ' .. i)
    overlays[i] = nil
    LOG(table.getsize(overlays))
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
        return false
    end
end

function myGetTechLevelString(bp)
    local tech = GetTechLevelString(bp)
    ovParams.label = ''
    ovParams.size = tech
    ovParams.offset = 0
    if EntityCategoryContains(categories.COMMAND, bp.BlueprintId) then
        ovParams.label = 'A'
        ovParams.size = 2
    elseif EntityCategoryContains(categories.SUBCOMMANDER, bp.BlueprintId) then
        ovParams.label = 'S'
    elseif EntityCategoryContains(categories.FACTORY, bp.BlueprintId) then
        ovParams.label = 'FAC'
        ovParams.offset = 10
    elseif EntityCategoryContains(categories.FIELDENGINEER, bp.BlueprintId) then
        ovParams.label = 'f'
        --elseif EntityCategoryContains(categories.MASSEXTRACTION, bp.BlueprintId) then
        --    label = 'M'
    elseif EntityCategoryContains(categories.ENGINEER, bp.BlueprintId) then
        ovParams.size = tech
        ovParams.label = tech
    end
    if ovParams.label == '' then ovParams.label = 'E' end

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
    local Max = math.max

    overlay.destroy = false
    overlay:SetSolidColor(bgColor) -- color of overlay background
    overlay:SetAlpha(.8)
    overlay:DisableHitTest()
    overlay:SetNeedsFrameUpdate(true)
    overlay.unit = unit
    overlay.id = unit:GetEntityId()
    overlay.time = 0

    overlay.text = UIUtil.CreateText(overlay, '0', 7 + ovParams.size, UIUtil.fixedFont, true)
    overlay.text:SetText(ovParams.label)

    overlay.Width:Set(function() return Max(overlay.text.Width() + (1.5 * ovParams.size), 8) end)
    overlay.Height:Set(function() return 10 + (0.5 * ovParams.size) end)

    LayoutHelpers.AtCenterIn(overlay.text, overlay, 0, 0)

    overlay.OnFrame = function(self, delta)
        if sessionIsPaused() then return end
        local removeExternals = _removeOverlay

        self.time = self.time + delta

        if isDestroyed(unit) or self.destroy then
            self:Hide()
            self:SetNeedsFrameUpdate(false)
            removeExternals(self.id)
            self = nil
            return
        end

        if isDestroyed(worldView) then
            worldView = import('/lua/ui/game/worldview.lua').GetWorldViews()['WorldCamera']
        end

        local ScreenPos = worldView:GetScreenPos(unit)
        if not ScreenPos or isObserver() or isGameUIHidden() then
            self.time = 0
            self:Hide()
            return
        else
            if self.time > 0.4 then
                self:Show()
            end
        end

        if not unit:IsDead() and not isDestroyed(self.unit) then
            --table.print(ScreenPos)

            local vec = unit:GetPosition()
            local pos = worldView:Project({ vec[1], vec[2] * 1.05, vec[3] })
            self.Left:Set(function()
                return worldView.Left() + pos.x - self.Width() / 2
            end)
            self.Top:Set(function()
                return (worldView.Top() + pos.y - self.Height() / 2 - 2) - ovParams.offset
            end)

            --print(ScreenPos[1])

            --self.Left:Set(ScreenPos[1] - self.Width() / 2)
            --self.Top:Set((ScreenPos[2] - self.Height() / 2 - 2) - offset)

            if unit:IsIdle() then
                self.text:SetColor(colorIdle)
            else
                self.text:SetColor('white')
            end
        end


    end

    return overlay
end

function TearDown()
    for i, u in overlays do
        DestroyOverlay(i)
    end
end

function OnChangeDetected()
    local a, b = pcall(function()
        LOG("iE3-OnChangeDetected")
        --teardown
        if rawget(_G, "ie3") ~= nil then
            overlays = _G[globalsKey].overlays
            for i, u in overlays do
                DestroyOverlay(i)
            end
            _G[globalsKey].overlays = {}
        end

    end)
    if not a then LOG("iE3-OnChangeDetected RESULT: ", a, b) end
end

OnChangeDetected()
