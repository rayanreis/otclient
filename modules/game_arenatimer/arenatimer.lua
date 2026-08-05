local ARENA_OPCODE = ExtendedIds.ArenaTimer

local panel
local tickEvent
local remainingSeconds = 0
local totalSeconds = 30 * 60
local titleText = 'Arena'

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format('%02d:%02d', minutes, secs)
end

local function stopTick()
	if tickEvent then
		removeEvent(tickEvent)
		tickEvent = nil
	end
end

local function hidePanel()
	stopTick()
	remainingSeconds = 0
	if panel then
		panel:hide()
	end
end

local function tick()
	tickEvent = nil
	if remainingSeconds <= 0 then
		hidePanel()
		return
	end

	remainingSeconds = remainingSeconds - 1
	if panel then
		panel.time:setText(formatTime(remainingSeconds))
		if remainingSeconds <= 60 then
			panel.time:setColor('#ff6666')
		else
			panel.time:setColor('#ffffff')
		end
	end

	if remainingSeconds > 0 then
		tickEvent = scheduleEvent(tick, 1000)
	else
		hidePanel()
	end
end

local function startTimer(remaining, total, title)
	if not panel then
		return
	end

	remainingSeconds = math.max(0, tonumber(remaining) or 0)
	totalSeconds = math.max(1, tonumber(total) or (30 * 60))
	titleText = title and title ~= '' and title or 'Arena'
	panel.title:setText(titleText)
	panel.time:setText(formatTime(remainingSeconds))
	panel.time:setColor(remainingSeconds <= 60 and '#ff6666' or '#ffffff')
	panel:show()
	stopTick()
	if remainingSeconds > 0 then
		tickEvent = scheduleEvent(tick, 1000)
	end
end

local function onExtendedOpcode(protocol, opcode, buffer)
	if not buffer or buffer == '' then
		return
	end

	local action, remaining, total, label = buffer:match('^(%w+),(%-?%d+),(%-?%d+),([^,]*)$')
	if not action then
		action, remaining, total = buffer:match('^(%w+),(%-?%d+),(%-?%d+)$')
		label = nil
	end
	if not action then
		return
	end

	remaining = tonumber(remaining) or 0
	total = tonumber(total) or totalSeconds
	label = label or 'Arena'

	if action == 'wait' then
		startTimer(remaining, total, label ~= '' and label or 'Starts in')
	elseif action == 'start' or action == 'sync' then
		startTimer(remaining, total, label ~= '' and label or 'Arena')
	elseif action == 'stop' then
		hidePanel()
	end
end

local function onGameEnd()
	hidePanel()
end

function init()
	g_ui.importStyle('arenatimer')
	local root = modules.game_interface.getRootPanel()
	panel = g_ui.createWidget('ArenaTimerPanel', root)
	panel:hide()

	ProtocolGame.registerExtendedOpcode(ARENA_OPCODE, onExtendedOpcode)
	connect(g_game, {
		onGameEnd = onGameEnd,
	})
end

function terminate()
	ProtocolGame.unregisterExtendedOpcode(ARENA_OPCODE)
	disconnect(g_game, {
		onGameEnd = onGameEnd,
	})
	hidePanel()
	if panel then
		panel:destroy()
		panel = nil
	end
end
