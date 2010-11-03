CooldownMonitor = {}
local onSpellCast
local spells = GeekWL
GeekCD = { }
mult = GetScreenWidth() * UIParent:GetScale() / select( GetCurrentResolution(), GetScreenResolutions() ):match( "%d+" )

function GeekCD.Scale(x)
	return mult*math.floor(x/mult+.5)
end

local chatPrefix = "|cffff7d0a<|r|cffffd200GeekCooldown|r|cffff7d0a>|r "
local function print(...)
	DEFAULT_CHAT_FRAME:AddMessage(chatPrefix..string.join(" ", tostringall(...)), 0.41, 0.8, 0.94)
end

local function onEvent(self, event, ...)
	if ( event == "COMBAT_LOG_EVENT_UNFILTERED" ) then
		local event = select(2, ...)
--		print(event)
		local sourceName, sourceFlags = select(4, ...)
		local spellId, spellName = select(9, ...)
		
		if ( spells[spellId] and (bit.band(sourceFlags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == 0) and (event == "SPELL_CAST_SUCCESS" or event == "SPELL_RESURRECT") ) then
			local cooldown = spells[spellId]
			onSpellCast(cooldown, sourceName, spellId, spellName)
		end
	end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", onEvent)

local anchor = CreateFrame("Frame", "CooldownMonitor_Anchor", UIParent)
anchor:SetHeight(GeekCD.Scale(1))
anchor:SetWidth(GeekCD.Scale(1))
anchor:SetPoint("TOP", Minimap, "BOTTOM", 0, -13)

local castInfo = "|Hplayer:%1$s|h[%1$s]|h cast |T%s:0|t|cFF71D5FF|Hspell:%d|h[%s]|h|r (Cooldown: %d minutes)"
function onSpellCast(timer, player, spellId, spellName)
	local texture = select(3, GetSpellInfo(spellId))
	print(castInfo:format(player, texture, spellId, spellName, timer / 60))
	CooldownMonitor.StartTimer(timer, player, spellName, texture)
end

function CooldownMonitor.GetClassByName(name)
	if UnitName("player") == name then
		return select(2, UnitClass("player"))
	end
	for i = 1, GetNumPartyMembers() do
		if UnitName("party"..i) == name then
			return select(2, UnitClass("party"..i))
		end
	end
	for i = 1, GetNumRaidMembers() do
		if UnitName("raid"..i) == name then
			return select(2, UnitClass("raid"..i))
		end
	end
	return "unknown"
end