local UI = nil

function showMagicalArchives()
    UI = g_ui.loadUI("/game_cyclopedia/tab/magicalArchives/magicalArchives", contentContainer)
    if not UI then
        return
    end
    UI:show()
    controllerCyclopedia.ui.CharmsBase:setVisible(false)
    controllerCyclopedia.ui.GoldBase:setVisible(false)
    controllerCyclopedia.ui.BestiaryTrackerButton:setVisible(false)
    if g_game.getClientVersion() >= 1410 then
        controllerCyclopedia.ui.CharmsBase1410:setVisible(false)
    end
end

