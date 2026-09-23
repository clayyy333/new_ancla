-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

-- Transparencia visual de superficies; no altera textos, imágenes ni bordes.
ApplyGUITransparencyElement = function(element)
	if not element or not element:IsA("GuiObject") then return end
	local base = element:GetAttribute("VexroBaseBackgroundTransparency")
	if type(base) ~= "number" then
		base = element.BackgroundTransparency
		element:SetAttribute("VexroBaseBackgroundTransparency", base)
	end
	element.BackgroundTransparency = math.max(base, math.clamp(tonumber(Settings.guiTransparency) or 0, 0, 0.8))
end

ApplyGUITransparency = function()
	local visited = {}
	for _,entry in ipairs(themeElements) do
		if entry.prop == "BackgroundColor3" and entry.el and entry.el.Parent and not visited[entry.el] then
			visited[entry.el] = true
			ApplyGUITransparencyElement(entry.el)
		end
	end
	if main and main.Parent then
		local glass = Settings.theme == "FrostedGlass" or Settings.theme == "GTAMode"
		main:SetAttribute("VexroBaseBackgroundTransparency", glass and 0.18 or 0)
		ApplyGUITransparencyElement(main)
		local gradient = main:FindFirstChild("VexroGradFrame")
		if gradient and gradient:IsA("GuiObject") then
			gradient:SetAttribute("VexroBaseBackgroundTransparency", glass and 0.45 or 0)
			ApplyGUITransparencyElement(gradient)
		end
	end
end
-- SETTINGS PANEL
-- ===============================================================

settingsPanel = Instance.new("ScrollingFrame")
settingsPanel.Size = UDim2.new(1, -16, 1, -(titleH + bottomBarH + 20))
settingsPanel.Position = UDim2.new(0, 8, 0, titleH + 8)
settingsPanel.BackgroundTransparency = 1
settingsPanel.ScrollBarThickness = isMobile and 6 or 4
settingsPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
settingsPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
settingsPanel.Visible = false
settingsPanel.ZIndex = 5
settingsPanel.Parent = content

settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 6)
settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
settingsLayout.Parent = settingsPanel

friendsPanel = Instance.new("ScrollingFrame")
friendsPanel.Size = UDim2.new(1, -16, 1, -(titleH + bottomBarH + 20))
friendsPanel.Position = UDim2.new(0, 8, 0, titleH + 8)
friendsPanel.BackgroundTransparency = 1
friendsPanel.ScrollBarThickness = isMobile and 6 or 4
friendsPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y

playlistsPanel = Instance.new("ScrollingFrame")
playlistsPanel.Size = UDim2.new(1, -16, 1, -(titleH + bottomBarH + 20))
playlistsPanel.Position = UDim2.new(0, 8, 0, titleH + 8)
playlistsPanel.BackgroundTransparency = 1
playlistsPanel.ScrollBarThickness = isMobile and 6 or 4
playlistsPanel.AutomaticCanvasSize = Enum.AutomaticSize.None
playlistsPanel.CanvasSize = UDim2.new(0,0,0,0)
playlistsPanel.Visible = false
playlistsPanel.ZIndex = 5
playlistsPanel.ZIndex = 5
playlistsPanel.Parent = content

playlistsLayout = Instance.new("UIListLayout")
playlistsLayout.SortOrder = Enum.SortOrder.LayoutOrder
playlistsLayout.Padding = UDim.new(0, 6)
playlistsLayout.Parent = playlistsPanel

playlistTopBar = Instance.new("Frame")
playlistTopBar.Size = UDim2.new(1, 0, 0, 40)
playlistTopBar.BackgroundTransparency = 1
playlistTopBar.LayoutOrder = -1
playlistTopBar.ZIndex = 6
playlistTopBar.Parent = playlistsPanel

playlistSearchBox = Instance.new("Frame")
playlistSearchBox.Size = UDim2.new(1, -50, 1, 0)
playlistSearchBox.BackgroundColor3 = currentTheme.secondary
playlistSearchBox.ZIndex = 7
playlistSearchBox.Parent = playlistTopBar
Instance.new("UICorner", playlistSearchBox).CornerRadius = UDim.new(0, 10)
RegisterTheme(playlistSearchBox, "BackgroundColor3", "secondary")

playlistListSearch = Instance.new("TextBox")
playlistListSearch.Size = UDim2.new(1, -20, 1, 0)
playlistListSearch.Position = UDim2.new(0, 10, 0, 0)
playlistListSearch.BackgroundTransparency = 1
playlistListSearch.Text = ""
playlistListSearch.PlaceholderText = L.searchPlaylists
playlistListSearch.TextColor3 = currentTheme.text
playlistListSearch.PlaceholderColor3 = currentTheme.text
playlistListSearch.Font = Enum.Font.Gotham
playlistListSearch.TextSize = 14
playlistListSearch.TextXAlignment = Enum.TextXAlignment.Left
playlistListSearch.ZIndex = 8
playlistListSearch.Parent = playlistSearchBox
RegisterTheme(playlistListSearch, "TextColor3", "text")
RegisterTheme(playlistListSearch, "PlaceholderColor3", "text")
playlistListSearch:GetPropertyChangedSignal("Text"):Connect(function()
	if RefreshPlaylistsList then RefreshPlaylistsList() end
end)

playlistAddBtn = Instance.new("TextButton")
playlistAddBtn.Size = UDim2.new(0, 40, 0, 40)
playlistAddBtn.Position = UDim2.new(1, -40, 0, 0)
playlistAddBtn.BackgroundColor3 = currentTheme.accent
playlistAddBtn.Text = "+"
playlistAddBtn.TextColor3 = Color3.new(1,1,1)
playlistAddBtn.Font = Enum.Font.GothamBold
playlistAddBtn.TextSize = 24
playlistAddBtn.ZIndex = 7
playlistAddBtn.Parent = playlistTopBar
Instance.new("UICorner", playlistAddBtn).CornerRadius = UDim.new(0, 10)
RegisterTheme(playlistAddBtn, "BackgroundColor3", "accent")

playlistAddBtn.MouseButton1Click:Connect(function()
	_isPlaylistMode = true
	_selectedEmotesForPlaylist = {}
	currentTab = "emotes"
	search.Text = ""
	UpdateTabData()
end)

friendsPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
friendsPanel.Visible = false
friendsPanel.ZIndex = 5
friendsPanel.Parent = content
friendsPanelLayout = Instance.new("UIListLayout")
	friendsPanelLayout.Padding = UDim.new(0, 10)
	friendsPanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
	friendsPanelLayout.Parent = friendsPanel

keybindsPanel = Instance.new("ScrollingFrame")
keybindsPanel.Size = UDim2.new(1, -16, 1, -(titleH + bottomBarH + 20))
keybindsPanel.Position = UDim2.new(0, 8, 0, titleH + 8)
keybindsPanel.BackgroundTransparency = 1
keybindsPanel.ScrollBarThickness = isMobile and 6 or 4
keybindsPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
keybindsPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
keybindsPanel.Visible = false
keybindsPanel.ZIndex = 5
keybindsPanel.Parent = content
keybindsPanelLayout = Instance.new("UIListLayout")
keybindsPanelLayout.Padding = UDim.new(0, 8)
keybindsPanelLayout.Parent = keybindsPanel

RefreshKeybindsPanel = nil

-- ---------------------------------------------------------------
-- Yardımcı: bölüm başlığı
-- ---------------------------------------------------------------
MakeSectionHeader = function(text, order)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 26)
	container.BackgroundTransparency = 1
	container.LayoutOrder = order
	container.ZIndex = 6
	container.Parent = settingsPanel

	local hdr = Instance.new("TextLabel")
	hdr.Size = UDim2.new(1, -4, 1, 0)
	hdr.BackgroundTransparency = 1
	hdr.Text = text:upper()
	hdr.TextColor3 = currentTheme.accent
	hdr.Font = Enum.Font.GothamBold
	hdr.TextSize = 11
	hdr.TextXAlignment = Enum.TextXAlignment.Left
	hdr.ZIndex = 7
	hdr.Parent = container
	RegisterTheme(hdr, "TextColor3", "accent")
	return container
end

-- ---------------------------------------------------------------
-- Yardımcı: ayar satırı (ikon + başlık + opsiyonel açıklama)
-- ---------------------------------------------------------------
MakeRow = function(imgId, title, subtitle, order, customH)
	local iconBoxSz = isMobile and 46 or 54
	local hasDesc = subtitle and subtitle ~= ""
	local h = customH or (hasDesc and 72 or 60)

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, h)
	row.BackgroundColor3 = currentTheme.secondary
	row.LayoutOrder = order
	row.ZIndex = 6
	row.Parent = settingsPanel
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 14)
	RegisterTheme(row, "BackgroundColor3", "secondary")

	local leftPad = 12
	if imgId and imgId ~= "" then
		local iconBox = Instance.new("Frame")
		iconBox.Size = UDim2.new(0, iconBoxSz, 0, iconBoxSz)
		iconBox.AnchorPoint = Vector2.new(0, 0.5)
		iconBox.Position = UDim2.new(0, leftPad, 0.5, 0)
		iconBox.BackgroundColor3 = currentTheme.tertiary
		iconBox.ZIndex = 7
		iconBox.Parent = row
		Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 9)
		RegisterTheme(iconBox, "BackgroundColor3", "tertiary")

		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0.85, 0, 0.85, 0)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Image = ResolveAssetImage("rbxassetid://" .. imgId)
		icon.ImageColor3 = currentTheme.accent
		icon.ZIndex = 8
		icon.Parent = iconBox
		RegisterTheme(icon, "ImageColor3", "accent")
	end

	local textLeft = (imgId and imgId ~= "") and (leftPad + iconBoxSz + 10) or leftPad
	local rightGap = 72

	local titleLbl = Instance.new("TextLabel")
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = title
	titleLbl.TextColor3 = currentTheme.text
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = isMobile and 13 or 14
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.ZIndex = 7
	titleLbl.Parent = row
	RegisterTheme(titleLbl, "TextColor3", "text")

	if hasDesc then
		titleLbl.Size = UDim2.new(1, -(textLeft + rightGap), 0, 20)
		titleLbl.Position = UDim2.new(0, textLeft, 0, 12)

		local subLbl = Instance.new("TextLabel")
		subLbl.Size = UDim2.new(1, -(textLeft + rightGap), 0, 18)
		subLbl.Position = UDim2.new(0, textLeft, 0, 33)
		subLbl.BackgroundTransparency = 1
		subLbl.Text = subtitle
		subLbl.TextColor3 = currentTheme.textDim
		subLbl.Font = Enum.Font.Gotham
		subLbl.TextSize = isMobile and 10 or 11
		subLbl.TextXAlignment = Enum.TextXAlignment.Left
		subLbl.TextWrapped = true
		subLbl.ZIndex = 7
		subLbl.Parent = row
		RegisterTheme(subLbl, "TextColor3", "textDim")
	else
		titleLbl.Size = UDim2.new(1, -(textLeft + rightGap), 1, 0)
		titleLbl.Position = UDim2.new(0, textLeft, 0, 0)
	end

	return row
end

-- ---------------------------------------------------------------
-- Yardımcı: pill toggle anahtarı
-- ---------------------------------------------------------------
MakePillToggle = function(parent, value, onChange)
	local pillW, pillH, pad = 50, 28, 3
	local knobSz = pillH - pad * 2

	local pill = Instance.new("Frame")
	pill.Size = UDim2.new(0, pillW, 0, pillH)
	pill.AnchorPoint = Vector2.new(1, 0.5)
	pill.Position = UDim2.new(1, -12, 0.5, 0)
	pill.BackgroundColor3 = value and currentTheme.success or currentTheme.stroke
	pill.ZIndex = 8
	pill.Parent = parent
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, knobSz, 0, knobSz)
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Position = value
		and UDim2.new(1, -(knobSz + pad), 0.5, 0)
		or  UDim2.new(0, pad, 0.5, 0)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.ZIndex = 9
	knob.Parent = pill
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local state = value
	local pillBtn = Instance.new("TextButton")
	pillBtn.Size = UDim2.fromScale(1, 1)
	pillBtn.BackgroundTransparency = 1
	pillBtn.Text = ""
	pillBtn.ZIndex = 10
	pillBtn.Parent = pill

	local function SetState(v)
		state = v
		TweenService:Create(pill, TweenInfo.new(0.22), {
			BackgroundColor3 = v and currentTheme.success or currentTheme.stroke
		}):Play()
		TweenService:Create(knob, TweenInfo.new(0.22, Enum.EasingStyle.Back), {
			Position = v and UDim2.new(1, -(knobSz + pad), 0.5, 0) or UDim2.new(0, pad, 0.5, 0)
		}):Play()
	end

	pillBtn.MouseButton1Click:Connect(function()
		state = not state
		SetState(state)
		onChange(state)
	end)

	return SetState
end

-- ===============================================================
-- GÖRÜNÜM
-- ===============================================================
MakeSectionHeader(isTR and "Görünüm" or (isES and "Apariencia" or (isAR and "المظهر" or (isFR and "Apparence" or (isHI and "दिखावट" or (isPT and "Aparência" or (isRU and "Внешний вид" or "Appearance")))))), 1)

do
	local themeRow = MakeRow("110192525313214", L.theme, "", 2)
	local themeNames = {"Dark", "Purple", "Blue", "Green", "Red", "Light", "MaterialYou", "FrostedGlass", "GTAMode"}
	local function DisplayThemeName(name) return name == "GTAMode" and "GTA Mode" or name end

	local chip = Instance.new("TextButton")
	chip.Size = UDim2.new(0, 80, 0, 30)
	chip.AnchorPoint = Vector2.new(1, 0.5)
	chip.Position = UDim2.new(1, -12, 0.5, 0)
	chip.BackgroundColor3 = currentTheme.accent
	chip.Text = DisplayThemeName(Settings.theme)
	chip.TextColor3 = Color3.new(1, 1, 1)
	chip.Font = Enum.Font.GothamBold
	chip.TextSize = isMobile and 10 or 11
	chip.ZIndex = 8
	chip.Parent = themeRow
	Instance.new("UICorner", chip).CornerRadius = UDim.new(1, 0)
	RegisterTheme(chip, "BackgroundColor3", "accent")

	local themeIdx = 1
	for i, n in ipairs(themeNames) do if n == Settings.theme then themeIdx = i end end

	chip.MouseButton1Click:Connect(function()
		themeIdx = themeIdx % #themeNames + 1
		Settings.theme = themeNames[themeIdx]
		chip.Text = DisplayThemeName(Settings.theme)
		ApplyTheme(Settings.theme)
		SaveData()
	end)
end

do
	local transparencyTitle = isES and "Transparencia de la GUI" or "GUI transparency"
	local transparencyDesc = isES and "Permite ver el juego detrás de la interfaz" or "Lets you see the game behind the interface"
	local transparencyRow = MakeRow("", transparencyTitle, transparencyDesc, 3, 88)

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0, 48, 0, 24)
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.Position = UDim2.new(1, -12, 0, 10)
	valueLabel.BackgroundTransparency = 1
	valueLabel.TextColor3 = currentTheme.accent
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 13
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.ZIndex = 9
	valueLabel.Parent = transparencyRow
	RegisterTheme(valueLabel, "TextColor3", "accent")

	local slider = Instance.new("TextButton")
	slider.Size = UDim2.new(1, -24, 0, 18)
	slider.Position = UDim2.new(0, 12, 1, -25)
	slider.BackgroundTransparency = 1
	slider.Text = ""
	slider.AutoButtonColor = false
	slider.ZIndex = 9
	slider.Parent = transparencyRow

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, 6)
	track.AnchorPoint = Vector2.new(0, 0.5)
	track.Position = UDim2.new(0, 0, 0.5, 0)
	track.BackgroundColor3 = currentTheme.tertiary
	track.ZIndex = 9
	track.Parent = slider
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
	RegisterTheme(track, "BackgroundColor3", "tertiary")

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = currentTheme.accent
	fill.ZIndex = 10
	fill.Parent = track
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	RegisterTheme(fill, "BackgroundColor3", "accent")

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(18, 18)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.ZIndex = 11
	knob.Parent = track
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local dragging = false
	local function setFromAlpha(alpha, save)
		alpha = math.clamp(alpha, 0, 1)
		local percent = math.floor(alpha * 80 + 0.5)
		Settings.guiTransparency = percent / 100
		valueLabel.Text = tostring(percent) .. "%"
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		ApplyGUITransparency()
		if save then SaveData() end
	end
	local function setFromInput(input, save)
		if slider.AbsoluteSize.X <= 0 then return end
		setFromAlpha((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, save)
	end
	slider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromInput(input, false)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromInput(input, false)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			setFromInput(input, true)
		end
	end)
	setFromAlpha((tonumber(Settings.guiTransparency) or 0) / 0.8, false)
end
do
	local ambientTitle = isES and "Sonido de ambiente" or "Ambient sound"
	local ambientDesc = isES and "Activa o silencia el ambiente de día y noche" or "Enable or mute daytime and nighttime ambience"
	local ambientRow = MakeRow("", ambientTitle, ambientDesc, 4)
	MakePillToggle(ambientRow, Settings.ambientSound ~= false, function(v)
		Settings.ambientSound = v
		if AmbientSoundController then AmbientSoundController:SetEnabled(v) end
		SaveData()
	end)
end

do
	local emergencyTitle = isES and "Ancla de Emergencia" or "Emergency Anchor"
	local emergencyDesc = isES and "Activa para evitar fling sorpresivo" or "Enable to prevent unexpected flings"
	local emergencyRow = MakeRow("", emergencyTitle, emergencyDesc, 5)
	MakePillToggle(emergencyRow, Settings.emergencyAnchor ~= false, function(v)
		Settings.emergencyAnchor = v
		_genv()["VexroEmergencyAnchorPreference_" .. tostring(player.UserId)] = v
		if EmergencyAnchorController then EmergencyAnchorController:SetEnabled(v) end
		SaveData()
	end)
end

do
	local antiAFKTitle = "Anti-AFK"
	local antiAFKDesc = isES and "Evita la expulsión por inactividad con una interacción cada 10 minutos" or "Prevents idle disconnection with an interaction every 10 minutes"
	local antiAFKRow = MakeRow("", antiAFKTitle, antiAFKDesc, 6)
	MakePillToggle(antiAFKRow, Settings.antiAFK == true, function(v)
		Settings.antiAFK = v
		if AntiAFKController then AntiAFKController:SetEnabled(v) end
		SaveData()
	end)
end
do
	local shortcutTitle=isES and "Activar Atajo de usuarios" or "Enable user shortcut"
	local shortcutDesc=isES and "Toca o haz clic sobre un personaje para elegir su objetivo" or "Tap or click a character to choose its target"
	local shortcutRow=MakeRow("",shortcutTitle,shortcutDesc,7)
	MakePillToggle(shortcutRow,Settings.userShortcut==true,function(v)
		Settings.userShortcut=v
		if UserShortcutController then UserShortcutController:SetEnabled(v) end
		SaveData()
	end)
end

do
	local speedRow = MakeRow("113837085020684", L.speed, "", 8, 78)
	local speeds = {0.25, 0.5, 0.75, 1, 1.25, 1.5, 2, 3}
	local speedIdx = 4
	for i, s in ipairs(speeds) do if s == Settings.speed then speedIdx = i end end

	local speedLbl = Instance.new("TextLabel")
	speedLbl.Size = UDim2.new(0, 48, 0, 28)
	speedLbl.AnchorPoint = Vector2.new(1, 0)
	speedLbl.Position = UDim2.new(1, -12, 0, 12)
	speedLbl.BackgroundTransparency = 1
	speedLbl.Text = Settings.speed .. "x"
	speedLbl.TextColor3 = currentTheme.accent
	speedLbl.Font = Enum.Font.GothamBlack
	speedLbl.TextSize = isMobile and 14 or 15
	speedLbl.TextXAlignment = Enum.TextXAlignment.Right
	speedLbl.ZIndex = 8
	speedLbl.Parent = speedRow
	RegisterTheme(speedLbl, "TextColor3", "accent")

	local iconBoxSz = isMobile and 46 or 54
	local sliderLeft = 12 + iconBoxSz + 10
	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(1, -(sliderLeft + 12), 0, 6)
	sliderBg.Position = UDim2.new(0, sliderLeft, 1, -20)
	sliderBg.BackgroundColor3 = currentTheme.tertiary
	sliderBg.ZIndex = 8
	sliderBg.Parent = speedRow
	Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
	RegisterTheme(sliderBg, "BackgroundColor3", "tertiary")

	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new(0, 0, 1, 0)
	sliderFill.BackgroundColor3 = currentTheme.accent
	sliderFill.ZIndex = 9
	sliderFill.Parent = sliderBg
	Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)
	RegisterTheme(sliderFill, "BackgroundColor3", "accent")

	local sliderKnob = Instance.new("TextButton")
	sliderKnob.Size = UDim2.new(0, 18, 0, 18)
	sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
	sliderKnob.Position = UDim2.new(0, 0, 0.5, 0)
	sliderKnob.BackgroundColor3 = Color3.new(1, 1, 1)
	sliderKnob.Text = ""
	sliderKnob.ZIndex = 10
	sliderKnob.Parent = sliderBg
	Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

	local function UpdateSpeedUI()
		Settings.speed = speeds[speedIdx]
		speedLbl.Text = Settings.speed .. "x"
		local alpha = (speedIdx - 1) / (#speeds - 1)
		TweenService:Create(sliderFill, TweenInfo.new(0.2), {Size = UDim2.new(alpha, 0, 1, 0)}):Play()
		TweenService:Create(sliderKnob, TweenInfo.new(0.2), {Position = UDim2.new(alpha, 0, 0.5, 0)}):Play()
		SaveData()
		ApplySpeedToAllTracks()
		if _onSpeedChanged then _onSpeedChanged() end
	end

	local sliderDragging = false
	sliderKnob.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			sliderDragging = true
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			sliderDragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if sliderDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local ax = math.clamp((inp.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
			local ni = math.floor(ax * (#speeds - 1) + 1.5)
			if ni ~= speedIdx then speedIdx = ni; UpdateSpeedUI() end
		end
	end)

	UpdateSpeedUI()
end

-- ===============================================================
-- DAVRANIŞ
-- ===============================================================
MakeSectionHeader(isTR and "Davranış" or (isES and "Comportamiento" or (isAR and "السلوك" or (isFR and "Comportement" or (isHI and "व्यवहार" or (isPT and "Comportamento" or (isRU and "Поведение" or "Behaviour")))))), 9)

do
	local row = MakeRow("103179694587186", L.loopText or "Loop", "", 11)
	MakePillToggle(row, Settings.loopEmote, function(v)
		Settings.loopEmote = v
		_genv().autoReloadEnabled_Vexro = v
		SaveData()
	end)
end

do
	local row = MakeRow("", L.stopOnWalk, L.stopOnWalkDesc, 12)
	MakePillToggle(row, Settings.stopOnWalk, function(v)
		Settings.stopOnWalk = v
		SaveData()
	end)
end

do
	local row = MakeRow("", L.showHUD, L.showHUDDesc, 13)
	MakePillToggle(row, Settings.showHUD, function(v)
		Settings.showHUD = v
		if not v then HideEmoteHUD() end
		SaveData()
	end)
end

-- ===============================================================
-- GENEL
-- ===============================================================
MakeSectionHeader(isTR and "Genel" or (isES and "General" or (isAR and "عام" or (isFR and "Général" or (isHI and "सामान्य" or (isPT and "Geral" or (isRU and "Общее" or "General")))))), 19)

do
	local row = MakeRow("76975628127992", L.resetLangLbl, L.resetLangDesc, 20)

	local resetBtn = Instance.new("TextButton")
	resetBtn.Size = UDim2.new(0, isMobile and 68 or 78, 0, 30)
	resetBtn.AnchorPoint = Vector2.new(1, 0.5)
	resetBtn.Position = UDim2.new(1, -12, 0.5, 0)
	resetBtn.BackgroundColor3 = currentTheme.critical
	resetBtn.Text = L.resetButton
	resetBtn.TextColor3 = Color3.new(1, 1, 1)
	resetBtn.Font = Enum.Font.GothamBold
	resetBtn.TextSize = isMobile and 11 or 12
	resetBtn.ZIndex = 8
	resetBtn.Parent = row
	Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 10)
	RegisterTheme(resetBtn, "BackgroundColor3", "critical")

	resetBtn.MouseButton1Click:Connect(function()
		Settings.language = nil
		SaveData()
		gui:Destroy()
		pcall(function()
			if _genv().lastVexroEmote then _genv().lastVexroEmote = nil end
		end)
		ReloadLocal()
	end)
end

do
	MakeSectionHeader(isES and "Acerca de" or "About", 21)
	MakeRow("", "Versión 1.0", "Desarrollada por Psycho @Thranduil553", 22)
end

	return true
end
