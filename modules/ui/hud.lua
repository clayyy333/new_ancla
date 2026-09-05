-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

hudTrackerConn = nil
_hudHideToken  = 0

HUD = Instance.new("Frame")
HUD.Name                   = "VexroHUD"
HUD.Size                   = isMobile and UDim2.new(0, 320, 0, 100) or UDim2.new(0, 500, 0, 104)
HUD.Position               = UDim2.new(0.5, 0, 1, -120)
HUD.AnchorPoint            = Vector2.new(0.5, 1)
HUD.BackgroundColor3       = Color3.fromRGB(8, 8, 12)
HUD.BackgroundTransparency = 0.30
HUD.BorderSizePixel        = 0
HUD.Visible                = false
HUD.ZIndex                 = 500
HUD.ClipsDescendants       = false
HUD.Parent                 = gui
Instance.new("UICorner", HUD).CornerRadius = UDim.new(0, 14)

syncNotice = Instance.new("TextLabel")
syncNotice.Name = "SyncNotice"
syncNotice.Size = UDim2.new(1, 0, 0, 20)
syncNotice.Position = UDim2.new(0, 0, 1, 4)
syncNotice.BackgroundTransparency = 1
syncNotice.Text = ""
syncNotice.TextColor3 = Color3.new(1, 1, 1)
syncNotice.TextTransparency = 0.4
syncNotice.Font = Enum.Font.GothamMedium
syncNotice.TextSize = 11
syncNotice.Visible = false
syncNotice.ZIndex = 500
syncNotice.Parent = HUD

hudStroke = Instance.new("UIStroke")
hudStroke.Color        = currentTheme.stroke
hudStroke.Thickness    = 1.5
hudStroke.Transparency = 0.25
hudStroke.Parent       = HUD

hudFavBtn = Instance.new("ImageButton")
hudFavBtn.Size                   = UDim2.new(0, 22, 0, 22)
hudFavBtn.Position               = UDim2.new(0, 9, 0, 6)
hudFavBtn.BackgroundColor3       = Color3.fromRGB(30, 30, 46)
hudFavBtn.BackgroundTransparency = 0.20
hudFavBtn.Image                  = ResolveAssetImage(Icons.FavoriteEmpty)
hudFavBtn.ImageColor3            = currentTheme.accent
hudFavBtn.ZIndex                 = 502
hudFavBtn.Parent                 = HUD
Instance.new("UICorner", hudFavBtn).CornerRadius = UDim.new(1, 0)

function RefreshHUDFavBtn()
	if not _currentInfoId then return end
	local isFav = IsFavorite(_currentInfoId)
	hudFavBtn.Image      = ResolveAssetImage(isFav and Icons.FavoriteFull or Icons.FavoriteEmpty)
	TweenService:Create(hudFavBtn, TweenInfo.new(0.15), {
		ImageColor3      = isFav and Color3.fromRGB(255, 215, 0) or currentTheme.accent,
		BackgroundColor3 = isFav and Color3.fromRGB(55, 45, 10) or Color3.fromRGB(30, 30, 46)
	}):Play()
end

hudFavBtn.MouseButton1Click:Connect(function()
	if not _currentInfoId then return end
	ToggleFavorite(_currentInfoId)
	RefreshHUDFavBtn()
end)


hudName = Instance.new("TextLabel")
hudName.Size                   = UDim2.new(1, -130, 0, 22)
hudName.Position               = UDim2.new(0, 44, 0, 7)
hudName.BackgroundTransparency = 1
hudName.Text                   = ""
hudName.TextColor3             = Color3.new(1, 1, 1)
hudName.Font                   = Enum.Font.GothamBold
hudName.TextSize               = isMobile and 13 or 15
hudName.TextXAlignment         = Enum.TextXAlignment.Left
hudName.TextTruncate           = Enum.TextTruncate.AtEnd
hudName.ZIndex                 = 501
hudName.Parent                 = HUD

hudCreator = Instance.new("TextLabel")
hudCreator.Size                   = UDim2.new(1, -130, 0, 15)
hudCreator.Position               = UDim2.new(0, 44, 0, 30)
hudCreator.BackgroundTransparency = 1
hudCreator.Text                   = "Emotes"
hudCreator.TextColor3             = Color3.fromRGB(120, 120, 145)
hudCreator.Font                   = Enum.Font.Gotham
hudCreator.TextSize               = isMobile and 10 or 11
hudCreator.TextXAlignment         = Enum.TextXAlignment.Left
hudCreator.ZIndex                 = 501
hudCreator.Parent                 = HUD

hudSliderBg = Instance.new("Frame")
hudSliderBg.Size             = UDim2.new(1, -148, 0, 4)
hudSliderBg.Position         = UDim2.new(0, 44, 0, 54)
hudSliderBg.BackgroundColor3 = Color3.fromRGB(42, 42, 58)
hudSliderBg.ZIndex           = 501
hudSliderBg.Parent           = HUD
Instance.new("UICorner", hudSliderBg).CornerRadius = UDim.new(1, 0)

hudFill = Instance.new("Frame")
hudFill.Size             = UDim2.new(0, 0, 1, 0)
hudFill.BackgroundColor3 = currentTheme.accent
hudFill.ZIndex           = 502
hudFill.Parent           = hudSliderBg
Instance.new("UICorner", hudFill).CornerRadius = UDim.new(1, 0)

hudKnob = Instance.new("TextButton")
hudKnob.Size             = UDim2.new(0, 12, 0, 12)
hudKnob.AnchorPoint      = Vector2.new(0.5, 0.5)
hudKnob.Position         = UDim2.new(0, 0, 0.5, 0)
hudKnob.BackgroundColor3 = Color3.new(1, 1, 1)
hudKnob.Text             = ""
hudKnob.ZIndex           = 503
hudKnob.Parent           = hudSliderBg
Instance.new("UICorner", hudKnob).CornerRadius = UDim.new(1, 0)

hudPauseBtn = Instance.new("ImageButton")
hudPauseBtn.Size                   = UDim2.new(0, 60, 0, 22)
hudPauseBtn.AnchorPoint            = Vector2.new(0.5, 0)
hudPauseBtn.Position               = UDim2.new(0.5, 0, 0, 66)
hudPauseBtn.BackgroundColor3       = Color3.fromRGB(30, 30, 46)
hudPauseBtn.BackgroundTransparency = 0.10
hudPauseBtn.Image                  = ResolveAssetImage("rbxassetid://113416463749658")
hudPauseBtn.ImageColor3            = Color3.new(1, 1, 1)
hudPauseBtn.ScaleType              = Enum.ScaleType.Fit
hudPauseBtn.ZIndex                 = 503
hudPauseBtn.Parent                 = HUD
Instance.new("UICorner", hudPauseBtn).CornerRadius = UDim.new(0, 7)

hudPauseBtnStroke = Instance.new("UIStroke")
hudPauseBtnStroke.Color       = currentTheme.stroke
hudPauseBtnStroke.Thickness   = 1
hudPauseBtnStroke.Transparency = 0.40
hudPauseBtnStroke.Parent      = hudPauseBtn

function RefreshHudPauseBtn()
	if _isPaused then
		hudPauseBtn.Image = ResolveAssetImage("rbxassetid://129338178452237")
		hudPauseBtn.BackgroundColor3 = currentTheme.accent
	else
		hudPauseBtn.Image = ResolveAssetImage("rbxassetid://113416463749658")
		hudPauseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
	end
end

hudPauseBtn.MouseButton1Click:Connect(function()
	if currentAnimTrack and _isPaused then
		pcall(function() currentAnimTrack:AdjustSpeed(Settings.speed) end)
		_SetPauseState(false)
	elseif currentAnimTrack and currentAnimTrack.IsPlaying then
		pcall(function() currentAnimTrack:AdjustSpeed(0) end)
		_SetPauseState(true)
	end
end)

_onPauseStateChanged = function(paused)
	RefreshHudPauseBtn()
end

HUD_SPEEDS = {0.1, 0.5, 1, 1.5, 2}
HUD_LABELS = {"0.1", "0.5", "1x", "1.5", "2x"}
hudSpeedBtns = {}
spBtnW   = isMobile and 26 or 30
spBtnGap = 3
spTotalW = #HUD_SPEEDS * spBtnW + (#HUD_SPEEDS - 1) * spBtnGap

function RefreshHUDSpeedBtns()
	for i, btn in ipairs(hudSpeedBtns) do
		local active = math.abs(HUD_SPEEDS[i] - Settings.speed) < 0.01
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = active and currentTheme.accent or Color3.fromRGB(30, 30, 46)
		}):Play()
	end
end

for si, spd in ipairs(HUD_SPEEDS) do
	local xOff = -(spTotalW + 8) + (si - 1) * (spBtnW + spBtnGap)
	local sBtn = Instance.new("TextButton")
	sBtn.Size                   = UDim2.new(0, spBtnW, 0, 20)
	sBtn.Position               = UDim2.new(1, xOff, 0, 7)
	sBtn.BackgroundColor3       = (math.abs(spd - Settings.speed) < 0.01)
		and currentTheme.accent or Color3.fromRGB(30, 30, 46)
	sBtn.BackgroundTransparency = 0.15
	sBtn.Text                   = HUD_LABELS[si]
	sBtn.TextColor3             = Color3.new(1, 1, 1)
	sBtn.Font                   = Enum.Font.GothamBold
	sBtn.TextSize               = 10
	sBtn.ZIndex                 = 502
	sBtn.Parent                 = HUD
	Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 5)
	hudSpeedBtns[si] = sBtn

	sBtn.MouseButton1Click:Connect(function()
		Settings.speed = spd
		if currentAnimTrack and currentAnimTrack.IsPlaying then
			pcall(function() currentAnimTrack:AdjustSpeed(spd) end)
		end
		RefreshHUDSpeedBtns()
		SaveData()
	end)
end

	return true
end
