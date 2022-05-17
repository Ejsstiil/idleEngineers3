local modPath = '/mods/idleEngineers3/'

local oldCreateUI = CreateUI
function CreateUI(isReplay)
    oldCreateUI(isReplay)

    AddBeatFunction(function()
        import(modPath .. 'modules/units.lua').OnBeat()
    end)
end

--[[------------------------------------------------------------------------------------------------------------------------------------
Normally this part would not be needed at all, but there are other plugings which messes with this, which triggers a false build instead
of upgrading. So for the sake of compatibility we do import/rewrite, which also makes this plugin compatible with the vanila game
----------------------------------------------------------------------------------------------------------------------------------------]]
local oldOnSelectionChanged = OnSelectionChanged
local ignoreSelection = false
function OnSelectionChanged(oldSelection, newSelection, added, removed)
    if ignoreSelection then
        return
    end
    oldOnSelectionChanged(oldSelection, newSelection, added, removed)
end

function SetIgnoreSelection(ignore)
    ignoreSelection = ignore
    --import('/lua/ui/game/commandmode.lua').SetIgnoreSelection(ignore)
end

--[[------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------]]
