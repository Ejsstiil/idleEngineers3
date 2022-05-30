local hidden_select = false

function IsHidden()
    return hidden_select == true
end

function Hidden(callback)
    local SetIgnoreSelection = import('/lua/ui/game/gamemain.lua').SetIgnoreSelection
    local CM = import('/lua/ui/game/commandmode.lua')
    local current_command = CM.GetCommandMode()
    local old_selection = GetSelectedUnits()
    SetIgnoreSelection(true)
    hidden_select = true

    callback()

    SelectUnits(old_selection)
    CM.StartCommandMode(current_command[1], current_command[2])
    hidden_select = false
    SetIgnoreSelection(false)
end
