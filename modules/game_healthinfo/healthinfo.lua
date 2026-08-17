local iconTopMenu = nil

local function setBarFill(bar, current, maximum)
    local totalWidth = bar.total:getWidth()
    local fillWidth = 0
    if maximum > 0 and current > 0 then
        fillWidth = math.floor((totalWidth * math.min(current, maximum)) / maximum)
        fillWidth = math.max(12, math.min(totalWidth, fillWidth))
    end
    bar.current:setWidth(fillWidth)
    bar.text:setText(string.format('%d/%d', current, maximum))
end

local function healthManaEvent()
    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    setBarFill(healthManaController.ui.health, player:getHealth(), player:getMaxHealth())
    setBarFill(healthManaController.ui.mana, player:getMana(), player:getMaxMana())
end

healthManaController = Controller:new()
healthManaController:setUI('healthinfo', modules.game_interface.getMainRightPanel())

function healthManaController:onInit()
end

function healthManaController:onTerminate()
    if iconTopMenu then
        iconTopMenu:destroy()
        iconTopMenu = nil
    end
end

function healthManaController:onGameStart()
    healthManaController:registerEvents(LocalPlayer, {
        onHealthChange = healthManaEvent,
        onManaChange = healthManaEvent
    }):execute()
end

function extendedView(extendedView)
    if extendedView then
        if not iconTopMenu then
            iconTopMenu = modules.client_topmenu.addTopRightToggleButton('healthMana', tr('Show health'),
                '/images/topbuttons/healthinfo', toggle)
            iconTopMenu:setOn(healthManaController.ui:isVisible())
            healthManaController.ui:setBorderColor('black')
            healthManaController.ui:setBorderWidth(2)
        end
    else
        if iconTopMenu then
            iconTopMenu:destroy()
            iconTopMenu = nil
        end
        healthManaController.ui:setBorderColor('alpha')
        healthManaController.ui:setBorderWidth(0)
        local mainRightPanel = modules.game_interface.getMainRightPanel()
        if not mainRightPanel:hasChild(healthManaController.ui) then
            mainRightPanel:insertChild(2, healthManaController.ui)
        end
        healthManaController.ui:show()
    end
    healthManaController.ui.moveOnlyToMain = not extendedView
end

function toggle()
    if iconTopMenu:isOn() then
        healthManaController.ui:hide()
        iconTopMenu:setOn(false)
    else
        healthManaController.ui:show()
        iconTopMenu:setOn(true)
    end
end
