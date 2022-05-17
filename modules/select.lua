do
    function Hidden(callback)
        local SetIgnoreSelection = import('/lua/ui/game/gamemain.lua').SetIgnoreSelection
        local CM = import('/lua/ui/game/commandmode.lua')
        local current_command = CM.GetCommandMode()
        local old_selection = GetSelectedUnits()
        SetIgnoreSelection(true)

        callback()
        SelectUnits(old_selection)
        CM.StartCommandMode(current_command[1], current_command[2])
        SetIgnoreSelection(false)
    end
end
