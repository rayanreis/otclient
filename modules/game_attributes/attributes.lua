local ATTRIBUTE_OPCODE = ExtendedIds.AttributeBuild
local RESET_STORE_QUERY = 'Attribute Reset Tool'

local ATTRS = {
	{
		key = 'str',
		label = 'Strength',
		desc = 'Increases physical attack power.\nAdds Strength to your weapon skill for damage calculations and a flat bonus to physical hits.',
	},
	{
		key = 'dex',
		label = 'Dexterity',
		desc = 'Increases attack speed and dodge chance.\nEach point reduces attack interval. Dodge chance has diminishing returns and cannot make you unhittable.',
	},
	{
		key = 'con',
		label = 'Constitution',
		desc = 'Increases health points (HP), capacity and defence.\nEach point grants +4 health points (HP), carrying capacity and a defence multiplier.',
	},
	{
		key = 'int',
		label = 'Intelligence',
		desc = 'Increases magic attack and MP.\nEach point grants bonus mana and flat magic attack on spells and wands (does not raise Magic Level).',
	},
	{
		key = 'luck',
		label = 'Luck',
		desc = 'Increases critical attack chance.\nEach point improves your chance to land a critical hit.',
	},
}

local alertButton
local storeButton
local window
local flashEvent
local pendingLevelUpAlert = false
local lastKnownLevel = 0

local state = {
	str = 0,
	dex = 0,
	con = 0,
	int = 0,
	luck = 0,
	unspent = 0,
	power = 0,
	perLevel = 5,
	hasReset = false,
}

local draft = {
	str = 0,
	dex = 0,
	con = 0,
	int = 0,
	luck = 0,
}

local function spentOf(values)
	return (values.str or 0) + (values.dex or 0) + (values.con or 0) + (values.int or 0) + (values.luck or 0)
end

local function remainingDraft()
	local total = spentOf(state) + (state.unspent or 0)
	return total - spentOf(draft)
end

local function estimatePower()
	local player = g_game.getLocalPlayer()
	local level = player and player:getLevel() or 1
	return (level * 10)
		+ (draft.str * 4)
		+ (draft.dex * 3)
		+ (draft.con * 4)
		+ (draft.int * 4)
		+ (draft.luck * 2)
end

local function stopFlash()
	if flashEvent then
		removeEvent(flashEvent)
		flashEvent = nil
	end
	if alertButton then
		alertButton:setOpacity(1.0)
	end
end

local function refreshStoreButton()
	if not storeButton then
		return
	end

	storeButton:setTooltip(tr('Attribute Build'))
	if storeButton.pointsBadge then
		storeButton.pointsBadge:destroy()
		storeButton.pointsBadge = nil
	end
end

local function startFlash()
	stopFlash()
	local visible = true
	flashEvent = cycleEvent(function()
		if not alertButton or not alertButton:isVisible() then
			return
		end
		visible = not visible
		alertButton:setOpacity(visible and 1.0 or 0.35)
	end, 500)
end

local function hideLevelUpAlert()
	pendingLevelUpAlert = false
	stopFlash()
	if alertButton then
		alertButton:setVisible(false)
	end
end

local function showLevelUpAlert()
	if not alertButton then
		return
	end
	pendingLevelUpAlert = true
	alertButton:setVisible(true)
	alertButton:setTooltip(tr('You leveled up! Click to distribute attribute points.'))
	alertButton:raise()
	startFlash()
end

local function updateResetButton()
	if not window or not window.resetButton then
		return
	end

	if state.hasReset then
		window.resetButton:setEnabled(true)
		window.resetButton:setOpacity(1.0)
		window.resetButton:setTooltip(tr('Consume an Attribute Reset Tool from your store inbox to reset all points.'))
	else
		-- Still clickable so we can open the store, but visually gated.
		window.resetButton:setEnabled(true)
		window.resetButton:setOpacity(0.55)
		window.resetButton:setTooltip(tr('Requires an Attribute Reset Tool in your store inbox. Click to buy one in the Store.'))
	end
end

local function refreshWindow()
	if not window then
		return
	end

	window.pointsLabel:setText(tr('Points remaining: %d', remainingDraft()))
	window.powerLabel:setText(tr('Character Power: %d', estimatePower()))
	updateResetButton()

	for _, def in ipairs(ATTRS) do
		local row = window.attrsPanel:getChildById('row_' .. def.key)
		if row then
			local value = draft[def.key] or 0
			local confirmed = state[def.key] or 0
			row.valueLabel:setText(tostring(value))
			-- Confirmed points are locked; only unconfirmed draft points can be removed with -
			if row.minusButton then
				local canDecrease = value > confirmed
				row.minusButton:setEnabled(canDecrease)
				row.minusButton:setOpacity(canDecrease and 1.0 or 0.4)
			end
			if row.plusButton then
				local canIncrease = remainingDraft() > 0
				row.plusButton:setEnabled(canIncrease)
				row.plusButton:setOpacity(canIncrease and 1.0 or 0.4)
			end
			if row.maxButton then
				local canMax = remainingDraft() > 0
				row.maxButton:setEnabled(canMax)
				row.maxButton:setOpacity(canMax and 1.0 or 0.4)
			end
		end
	end
end

local HOLD_REPEAT_DELAY_MS = 350
local HOLD_REPEAT_INTERVAL_MS = 80
local HOLD_FAST_AFTER_MS = 5000
local HOLD_FAST_STEP = 10

local function changeAttr(key, delta)
	local current = draft[key] or 0
	local confirmed = state[key] or 0
	local nextValue = current + delta
	-- Never go below confirmed (locked) points; Reset is required to redistribute those.
	if nextValue < confirmed then
		return
	end
	if delta > 0 and remainingDraft() < delta then
		return
	end
	draft[key] = nextValue
	refreshWindow()
end

local function maxAttr(key)
	local remaining = remainingDraft()
	if remaining <= 0 then
		return
	end
	draft[key] = (draft[key] or 0) + remaining
	refreshWindow()
end

local function holdStep(elapsedMs)
	if (elapsedMs or 0) >= HOLD_FAST_AFTER_MS then
		return HOLD_FAST_STEP
	end
	return 1
end

local function bindHoldAdjust(button, key, sign)
	g_mouse.bindAutoPress(button, function(_, _, _, elapsedMs)
		if not window or not window:isVisible() then
			return
		end

		local step = holdStep(elapsedMs)
		if sign > 0 then
			local remaining = remainingDraft()
			if remaining <= 0 then
				return
			end
			changeAttr(key, math.min(step, remaining))
			return
		end

		local removable = (draft[key] or 0) - (state[key] or 0)
		if removable <= 0 then
			return
		end
		changeAttr(key, -math.min(step, removable))
	end, HOLD_REPEAT_DELAY_MS, MouseLeftButton, HOLD_REPEAT_INTERVAL_MS)
end

local function buildRows()
	if not window then
		return
	end

	window.attrsPanel:destroyChildren()
	for _, def in ipairs(ATTRS) do
		local row = g_ui.createWidget('AttributeRow', window.attrsPanel)
		row:setId('row_' .. def.key)
		row.nameLabel:setText(def.label)
		if row.infoIcon then
			row.infoIcon:setTooltip(def.desc)
		end
		bindHoldAdjust(row.plusButton, def.key, 1)
		bindHoldAdjust(row.minusButton, def.key, -1)
		row.maxButton.onClick = function()
			maxAttr(def.key)
		end
	end
end

local function openResetStoreOffer()
	hideWindow()
	if modules.game_store and modules.game_store.openSearch then
		modules.game_store.openSearch(RESET_STORE_QUERY)
	elseif modules.game_store and modules.game_store.toggle then
		modules.game_store.toggle()
	elseif modules.game_mainpanel and modules.game_mainpanel.toggleStore then
		modules.game_mainpanel.toggleStore()
	end
end

function hideWindow()
	if window then
		window:hide()
	end
end

function showWindow()
	if not window then
		return
	end

	hideLevelUpAlert()

	draft.str = state.str
	draft.dex = state.dex
	draft.con = state.con
	draft.int = state.int
	draft.luck = state.luck
	refreshWindow()
	window:show()
	window:raise()
	window:focus()
end

function toggleWindow()
	if window and window:isVisible() then
		hideWindow()
	else
		showWindow()
	end
end

function confirmAttributes()
	local protocol = g_game.getProtocolGame()
	if not protocol then
		return
	end

	protocol:sendExtendedOpcode(ATTRIBUTE_OPCODE, string.format(
		'set,%d,%d,%d,%d,%d',
		draft.str or 0,
		draft.dex or 0,
		draft.con or 0,
		draft.int or 0,
		draft.luck or 0
	))
	hideWindow()
end

function resetAttributes()
	if not state.hasReset then
		openResetStoreOffer()
		return
	end

	local protocol = g_game.getProtocolGame()
	if not protocol then
		return
	end
	protocol:sendExtendedOpcode(ATTRIBUTE_OPCODE, 'reset')
end

local function applySync(str, dex, con, intel, luck, unspent, power, perLevel, hasReset, fromLevelUp)
	state.str = str or 0
	state.dex = dex or 0
	state.con = con or 0
	state.int = intel or 0
	state.luck = luck or 0
	state.unspent = unspent or 0
	state.power = power or 0
	state.perLevel = perLevel or 5
	state.hasReset = (tonumber(hasReset) or 0) > 0

	if window and window:isVisible() then
		draft.str = state.str
		draft.dex = state.dex
		draft.con = state.con
		draft.int = state.int
		draft.luck = state.luck
		refreshWindow()
	elseif window then
		updateResetButton()
	end

	if fromLevelUp then
		showLevelUpAlert()
	end

	refreshStoreButton()
end

local function parseSyncBuffer(buffer)
	-- sync|levelup,str,dex,con,int,luck,unspent,power,perLevel,hasReset
	local action, str, dex, con, intel, luck, unspent, power, perLevel, hasReset =
		buffer:match('^(%w+),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+)$')

	if not action then
		action, str, dex, con, intel, luck, unspent, power, perLevel =
			buffer:match('^(%w+),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+),(%-?%d+)$')
		hasReset = 0
	end

	return action, str, dex, con, intel, luck, unspent, power, perLevel, hasReset
end

local function onExtendedOpcode(protocol, opcode, buffer)
	if not buffer or buffer == '' then
		return
	end

	local action, str, dex, con, intel, luck, unspent, power, perLevel, hasReset = parseSyncBuffer(buffer)
	if not action then
		return
	end

	local fromLevelUp = (action == 'levelup')
	if action ~= 'sync' and action ~= 'levelup' then
		return
	end

	applySync(
		tonumber(str),
		tonumber(dex),
		tonumber(con),
		tonumber(intel),
		tonumber(luck),
		tonumber(unspent),
		tonumber(power),
		tonumber(perLevel),
		tonumber(hasReset),
		fromLevelUp
	)
end

local function requestSync()
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(ATTRIBUTE_OPCODE, 'request')
	end
end

local function ensureAlertOnMapPanel()
	local mapPanel = modules.game_interface.getMapPanel and modules.game_interface.getMapPanel()
	if not mapPanel then
		return false
	end

	if alertButton and alertButton:getParent() ~= mapPanel then
		alertButton:destroy()
		alertButton = nil
	end

	if not alertButton then
		alertButton = g_ui.createWidget('AttributeAlertButton', mapPanel)
		alertButton.onClick = function()
			showWindow()
		end
	end
	return true
end

local function ensureStoreButton()
	if storeButton or not modules.game_mainpanel or not modules.game_mainpanel.addStoreButton then
		return
	end

	storeButton = modules.game_mainpanel.addStoreButton(
		'AttributesBuild',
		tr('Attribute Build'),
		'/images/options/attributes_large',
		function()
			toggleWindow()
		end,
		false
	)

	refreshStoreButton()

	if modules.game_mainpanel.reloadMainPanelSizes then
		modules.game_mainpanel.reloadMainPanelSizes()
	end
end

local function onLevelChange(localPlayer, level, percent, oldLevel)
	if not oldLevel or oldLevel == 0 or not level or level <= oldLevel then
		lastKnownLevel = level or lastKnownLevel
		return
	end

	lastKnownLevel = level
	showLevelUpAlert()
end

local function onGameStart()
	hideLevelUpAlert()
	local player = g_game.getLocalPlayer()
	lastKnownLevel = player and player:getLevel() or 0

	scheduleEvent(function()
		ensureAlertOnMapPanel()
		ensureStoreButton()
		requestSync()
	end, 800)
end

local function onGameEnd()
	hideLevelUpAlert()
	hideWindow()
	state.unspent = 0
	state.hasReset = false
	lastKnownLevel = 0
	refreshStoreButton()
end

function init()
	g_ui.importStyle('attributes')

	local root = modules.game_interface.getRootPanel()
	if not ensureAlertOnMapPanel() then
		alertButton = g_ui.createWidget('AttributeAlertButton', root)
		alertButton.onClick = function()
			showWindow()
		end
	end

	window = g_ui.createWidget('AttributeBuildWindow', root)
	window:hide()
	buildRows()

	ProtocolGame.registerExtendedOpcode(ATTRIBUTE_OPCODE, onExtendedOpcode)
	connect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd,
	})
	connect(LocalPlayer, {
		onLevelChange = onLevelChange,
	})
end

function terminate()
	ProtocolGame.unregisterExtendedOpcode(ATTRIBUTE_OPCODE)
	disconnect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd,
	})
	disconnect(LocalPlayer, {
		onLevelChange = onLevelChange,
	})
	stopFlash()
	if alertButton then
		alertButton:destroy()
		alertButton = nil
	end
	if storeButton then
		storeButton:destroy()
		storeButton = nil
	end
	if window then
		window:destroy()
		window = nil
	end
end
