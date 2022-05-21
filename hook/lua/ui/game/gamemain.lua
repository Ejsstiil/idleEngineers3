local modPath = '/mods/idleEngineers3/'

local oldCreateUI = CreateUI
function CreateUI(isReplay)
    oldCreateUI(isReplay)

    AddBeatFunction(function()
        import(modPath .. 'modules/main.lua').OnBeat()
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
if false then
    ForkThread(function()
        WaitSeconds(5)
        CreateUnitAtMouse('urb4206', 0, -8.65, -2.15, 0.00000)
        CreateUnitAtMouse('urb4204', 0, 1.35, 3.85, 0.00000)
        CreateUnitAtMouse('urb1301', 0, -5.65, 4.85, 0.00000)
        CreateUnitAtMouse('urb3101', 0, 0.35, -0.15, 0.00000)
        CreateUnitAtMouse('urb0101', 0, -1.65, -6.15, 0.00000)
        CreateUnitAtMouse('url0105', 0, -5.28, -1.67, 1.49915)
        CreateUnitAtMouse('urb3201', 0, 5.35, -1.15, 0.00000)
        CreateUnitAtMouse('url0208', 0, -1.26, -1.66, 1.55829)
        CreateUnitAtMouse('xeb0104', 0, 6.35, 2.85, 0.00000)
        CreateUnitAtMouse('xea3204', 0, 6.35, 3.04, 0.00000)
        CreateUnitAtMouse('url0309', 0, 2.72, -1.67, 1.52960)
    end)
end
