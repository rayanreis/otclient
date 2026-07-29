local SKULL_SUMMON_OPCODE = ExtendedIds.SkullSummon
local SD_EFFECT_ID = 18 -- CONST_ME_MORTAREA

local SHADERS = {
	green = 'Effect - SkullGreen',
	red = 'Effect - SkullRed',
	black = nil, -- keep original SD look
}

local function playColoredSd(position, color)
	local effect = Effect.create()
	effect:setId(SD_EFFECT_ID)

	local shader = SHADERS[color]
	if shader then
		effect:setShader(shader)
	end

	g_map.addThing(effect, position)
end

local function onExtendedOpcode(protocol, opcode, buffer)
	if not buffer or buffer == '' then
		return
	end

	local x, y, z, color = buffer:match('^(%d+),(%d+),(%d+),(%w+)$')
	if not x then
		return
	end

	playColoredSd({
		x = tonumber(x),
		y = tonumber(y),
		z = tonumber(z),
	}, color:lower())
end

function init()
	ProtocolGame.registerExtendedOpcode(SKULL_SUMMON_OPCODE, onExtendedOpcode)
end

function terminate()
	ProtocolGame.unregisterExtendedOpcode(SKULL_SUMMON_OPCODE)
end
