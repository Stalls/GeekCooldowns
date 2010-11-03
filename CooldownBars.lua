local firstTimer, lastTimer
local timer = {}
local GeekCF = { }
GeekCF["media"] = {
	["blank"] = [[Interface\AddOns\GeekCooldown\media\textures\blank]],
	["empath3"] = [[Interface\AddOns\GeekCooldown\media\textures\empath3]],
	["pixelfont"] = [[Interface\AddOns\GeekCooldown\media\fonts\pixelfont.ttf]],
	["borderColor"] = { .21, .21, .21, 1 },
	["backdropColor"] = { .08, .08, .08, 1 },
}

local popOrCreateFrame, pushFrame
do
	local id = 1
	local frameStack
	
	function popOrCreateFrame()
		local frame
		if frameStack then
			frame = frameStack
			frameStack = frameStack.next
			frame:Show()
		else
			frame = CreateFrame("StatusBar", "CooldownMonitor_Bar"..id, CooldownMonitor_Anchor)
			id = id +1
		end
		return frame
	end
	
	function pushFrame(frame)
		frame.obj = nil
		frame.next = frameStack
		frameStack = frame
	end
end

local mt = { __index = timer }

function CooldownMonitor.StartTimer(timer, player, spell, texture)
	local frame = popOrCreateFrame()
	local class = CooldownMonitor.GetClassByName(player)
	frame:SetStatusBarTexture(GeekCF.media.empath3)
	frame:GetStatusBarTexture():SetHorizTile(false)
	frame:SetMinMaxValues(0, 1)
	frame:SetWidth(GeekCD.Scale(160))
	frame:SetHeight(GeekCD.Scale(13))
	
	frame:SetStatusBarTexture(GeekCF.media.empath3);
	if ( RAID_CLASS_COLORS[class] ) then
		local color = RAID_CLASS_COLORS[class]
		frame:SetStatusBarColor(color.r, color.g, color.b)
	else
		frame:SetStatusBarColor(1, 0.7, 0)
	end
	
	local bgframe = CreateFrame("Frame", _G[frame:GetName().."Background"], _G[frame:GetName()])
	bgframe:SetFrameLevel(0)
	bgframe:SetHeight(GeekCD.Scale(frame:GetHeight()+4))
	bgframe:SetWidth(GeekCD.Scale(frame:GetWidth()+20))
	bgframe:SetFrameStrata("BACKGROUND")
	bgframe:SetPoint("TOPLEFT", _G[frame:GetName()], "TOPLEFT", GeekCD.Scale(-18), GeekCD.Scale(2))
	bgframe:SetBackdrop({
	  bgFile = GeekCF.media.blank, 
	  edgeFile = GeekCF.media.blank, 
	  tile = false, tileSize = 0, edgeSize = mult, 
	  insets = { left = -mult, right = -mult, top = -mult, bottom = -mult}
	})
	bgframe:SetBackdropColor(unpack(GeekCF.media.backdropColor))
	bgframe:SetBackdropBorderColor(unpack(GeekCF.media.borderColor))
	
	_G[frame:GetName().."Text"] = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	_G[frame:GetName().."Text"]:SetFont(GeekCF.media.pixelfont, 8, "MONOCHROMEOUTLINE")
	_G[frame:GetName().."Text"]:SetWidth(GeekCD.Scale(155))
	_G[frame:GetName().."Text"]:SetPoint("LEFT", frame)
	_G[frame:GetName().."Text"]:SetJustifyH("LEFT")
	_G[frame:GetName().."Text"]:SetFormattedText("%s: %s", player, spell)
	
	_G[frame:GetName().."Timer"] = frame:CreateFontString(nil, "ARTWORK")
	_G[frame:GetName().."Timer"]:SetFont(GeekCF.media.pixelfont, 8, "MONOCHROMEOUTLINE")
	_G[frame:GetName().."Timer"]:SetPoint("RIGHT", frame)
	_G[frame:GetName().."Timer"]:SetJustifyH("RIGHT")
	
	_G[frame:GetName().."Icon"] = frame:CreateTexture(nil, 'OVERLAY')
	_G[frame:GetName().."Icon"]:SetPoint('LEFT', frame, -15, 0)
	_G[frame:GetName().."Icon"]:SetSize(GeekCD.Scale(13), GeekCD.Scale(13))	
	
	local ok = _G[frame:GetName().."Icon"]:SetTexture(texture)
	if ok then
		_G[frame:GetName().."Icon"]:Show()
	else
		_G[frame:GetName().."Icon"]:Hide()
	end
	_G[frame:GetName().."Icon"]:SetTexCoord(.08, .92, .08, .92)
	
	--UIFrameFadeOut(_G[frame:GetName().."Flash"], 0.5, 1, 0)
	local obj = setmetatable({ frame = frame, totalTime = timer, timer = timer }, mt)
	frame.obj = obj
	
	if ( firstTimer == nil ) then
		firstTimer = obj
		lastTimer = obj
	else
		obj.prev = lastTimer
		lastTimer.next = obj
		lastTimer = obj
	end
	
	obj:SetPosition()
	obj:Update(0)
	frame:SetScript("OnUpdate", function(self, elapsed) self.obj:Update(elapsed) end)
	return obj
end

function timer:SetPosition()
	self.frame:ClearAllPoints()
	if ( self == firstTimer ) then
		self.frame:SetPoint("CENTER", CooldownMonitor_Anchor, "CENTER")
	else
		self.frame:SetPoint("TOP", self.prev.frame, "BOTTOM", 0, GeekCD.Scale(-6))
	end
end

local function stringFromTimer(t)
	if ( t < 60 ) then
		return string.format("%.1f", t)
	else
		return string.format("%d:%0.2d", t / 60, t % 60)
	end
end

function timer:Update(elapsed)
	self.timer = self.timer - elapsed
	if ( self.timer <= 0 ) then
		self:Cancel()
	else
		local currentBarPos = self.timer / self.totalTime
		self.frame:SetValue(currentBarPos)
		
		_G[self.frame:GetName().."Timer"]:SetText(stringFromTimer(self.timer))
		--_G[self.frame:GetName().."Spark"]:SetPoint("CENTER", self.frame, "LEFT", self.frame:GetWidth() * currentBarPos, 2)
	end
end

function timer:Cancel()
	if ( self == firstTimer ) then
		firstTimer = self.next
	else
		node.prev.next = node.next
	end
	
	if ( self == lastTimer ) then
		lastTimer = self.prev
	else
		self.next.prev = self.prev
	end
	
	if ( self.next ) then
		self.next:SetPosition()
	end
	self.frame:Hide()
	pushFrame(self.frame)
end

local updater = CreateFrame("Frame")
updater:SetScript("OnUpdate", function(self, elapsed)
	if ( CooldownMonitor_Anchor:IsShown() and not CooldownMonitor_Anchor:IsVisible() ) then
		local timer = firstTimer
		while timer do
			timer:Update(elapsed)
			timer = timer.next
		end
	end
end)