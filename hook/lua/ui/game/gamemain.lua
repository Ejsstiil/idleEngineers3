local Select = import('/mods/idleEngineers3/modules/select.lua')

local oldCreateUI = CreateUI
function CreateUI(isReplay)
    oldCreateUI(isReplay)
    AddBeatFunction(import('/mods/idleEngineers3/modules/main.lua').OnBeat)
end

local oldOnSelectionChanged = OnSelectionChanged
function OnSelectionChanged(oldSelection, newSelection, added, removed)
    if not Select.IsHidden() then
        oldOnSelectionChanged(oldSelection, newSelection, added, removed)
    end
end
