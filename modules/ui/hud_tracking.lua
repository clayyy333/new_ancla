-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

hudKnobDragging = false

hudKnob.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1
	or inp.UserInputType == Enum.UserInputType.Touch then
		hudKnobDragging = true
	end
end)

hudSliderBg.InputBegan:Connect(function(inp)
	if inp.UserInputType ~= Enum.UserInputType.MouseButton1
	and inp.UserInputType ~= Enum.UserInputType.Touch then return end
	if currentAnimTrack and currentAnimTrack.Length and currentAnimTrack.Length > 0 then
		local alpha = math.clamp(
			(inp.Position.X - hudSliderBg.AbsolutePosition.X) / hudSliderBg.AbsoluteSize.X,
			0, 1)
		pcall(function() currentAnimTrack.TimePosition = alpha * currentAnimTrack.Length end)
	end
end)

UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1
	or inp.UserInputType == Enum.UserInputType.Touch then
		hudKnobDragging = false
	end
end)

UserInputService.InputChanged:Connect(function(inp)
	if not hudKnobDragging then return end
	if inp.UserInputType ~= Enum.UserInputType.MouseMovement
	and inp.UserInputType ~= Enum.UserInputType.Touch then return end
	if currentAnimTrack and currentAnimTrack.Length and currentAnimTrack.Length > 0 then
		local alpha = math.clamp(
			(inp.Position.X - hudSliderBg.AbsolutePosition.X) / hudSliderBg.AbsoluteSize.X,
			0, 1)
		pcall(function() currentAnimTrack.TimePosition = alpha * currentAnimTrack.Length end)
	end
end)

function StartHUDTracking()
	if hudTrackerConn then
		hudTrackerConn:Disconnect()
		hudTrackerConn = nil
	end

	hudTrackerConn = RunService.RenderStepped:Connect(function()
		if not currentAnimTrack or not currentAnimTrack.IsPlaying then return end
		local len = currentAnimTrack.Length
		if not len or len <= 0 then return end

		local alpha = math.clamp(currentAnimTrack.TimePosition / len, 0, 1)

		hudFill.Size     = UDim2.new(alpha, 0, 1, 0)
		hudKnob.Position = UDim2.new(alpha, 0, 0.5, 0)

		hudFill.BackgroundColor3    = currentTheme.accent
		hudStroke.Color             = currentTheme.stroke
	end)
end

function StopHUDTracking()
	if hudTrackerConn then
		hudTrackerConn:Disconnect()
		hudTrackerConn = nil
	end
end

ShowEmoteHUD = function(emoteId, emoteName)
	if not Settings.showHUD then return end
	_hudHideToken = _hudHideToken + 1

	_currentInfoId   = emoteId
	_currentInfoName = emoteName

	RefreshHUDFavBtn()
	hudName.Text    = emoteName or "Emote"
	hudCreator.Text = "Emotes"

	_isPaused = false
	RefreshHudPauseBtn()
	
	local hasSync = false
	if FriendData and FriendData.syncEmote and FriendData.friends then
		for _, f in pairs(FriendData.friends) do
			if f.syncEnabled and f.online then
				hasSync = true
				break
			end
		end
	end
	if hasSync then
		syncNotice.Text = isTR and "Emote'unuz arkadaşınıza gönderiliyor, bu 5-10 saniye sürebilir." or "Your emote is sending to your friend this will take 5-10 seconds."
		syncNotice.Visible = true
	else
		syncNotice.Visible = false
	end

	local startY = isMobile and -20 or -88
	local endY = isMobile and -60 or -120

	HUD.Position               = UDim2.new(0.5, 0, 1, startY)
	HUD.BackgroundTransparency = 1
	HUD.Visible                = true

	TweenService:Create(HUD,
		TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.new(0.5, 0, 1, endY), BackgroundTransparency = 0.30}
	):Play()

	RefreshHUDSpeedBtns()
	StartHUDTracking()
end

HideEmoteHUD = function()
	_isPaused = false
	RefreshHudPauseBtn()
	if _stopBtnSquare then _stopBtnSquare.Image = ResolveAssetImage("rbxassetid://113416463749658") end
	StopHUDTracking()
	local hideY = isMobile and -20 or -88
	TweenService:Create(HUD,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = UDim2.new(0.5, 0, 1, hideY), BackgroundTransparency = 1}
	):Play()
	local token = _hudHideToken
	task.delay(0.22, function()
		if HUD and _hudHideToken == token then
			HUD.Visible = false
		end
	end)
end

-- ----------------------------------------------------------------
-- BOLUM 4 - HUD & BLENDING ENTEGRASYONU
-- ----------------------------------------------------------------

	return true
end
