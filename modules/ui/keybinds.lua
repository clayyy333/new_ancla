-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

-- KEYBIND DIALOG
-- ===============================================================

function ShowKeybindDialog(emoteId, emote, isEdit)
	local existing = main:FindFirstChild("VexroKeybindOverlay")
	if existing then existing:Destroy() end

	local overlay = Instance.new("TextButton")
	overlay.Name = "VexroKeybindOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.Text = ""
	overlay.AutoButtonColor = false
	overlay.ZIndex = 200
	overlay.Parent = main
	overlay.MouseButton1Click:Connect(function() end)

	local dialog = Instance.new("Frame")
	dialog.Size = UDim2.new(0.85, 0, 0, 260)
	dialog.Position = UDim2.fromScale(0.5, 0.5)
	dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	dialog.BackgroundColor3 = currentTheme.secondary
	dialog.ZIndex = 201
	dialog.Parent = overlay
	Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 16)
	local dStroke = Instance.new("UIStroke")
	dStroke.Color = currentTheme.accent
	dStroke.Thickness = 2
	dStroke.Transparency = 0.4
	dStroke.Parent = dialog

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -16, 0, 36)
	titleLbl.Position = UDim2.new(0, 8, 0, 8)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = isEdit and L.editKeybind or L.newKeybind
	titleLbl.TextColor3 = currentTheme.text
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 16
	titleLbl.ZIndex = 202
	titleLbl.Parent = dialog

	local nameLblTitle = Instance.new("TextLabel")
	nameLblTitle.Size = UDim2.new(0, 60, 0, 24)
	nameLblTitle.Position = UDim2.new(0, 12, 0, 52)
	nameLblTitle.BackgroundTransparency = 1
	nameLblTitle.Text = L.kbName
	nameLblTitle.TextColor3 = currentTheme.textDim
	nameLblTitle.Font = Enum.Font.GothamBold
	nameLblTitle.TextSize = 13
	nameLblTitle.TextXAlignment = Enum.TextXAlignment.Left
	nameLblTitle.ZIndex = 202
	nameLblTitle.Parent = dialog

	local nameBox = Instance.new("TextBox")
	nameBox.Size = UDim2.new(1, -24, 0, 32)
	nameBox.Position = UDim2.new(0, 12, 0, 78)
	nameBox.BackgroundColor3 = currentTheme.tertiary
	nameBox.PlaceholderText = emote.name
	nameBox.Text = isEdit and (GetKeybind(emoteId) and GetKeybind(emoteId).name or "") or ""
	nameBox.TextColor3 = currentTheme.text
	nameBox.PlaceholderColor3 = currentTheme.textDim
	nameBox.Font = Enum.Font.Gotham
	nameBox.TextSize = 13
	nameBox.ClearTextOnFocus = false
	nameBox.ZIndex = 202
	nameBox.Parent = dialog
	Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 8)
	local nbStroke = Instance.new("UIStroke")
	nbStroke.Color = currentTheme.stroke
	nbStroke.Thickness = 1.5
	nbStroke.Parent = nameBox

	local atamaLbl = Instance.new("TextLabel")
	atamaLbl.Size = UDim2.new(0, 80, 0, 24)
	atamaLbl.Position = UDim2.new(0, 12, 0, 122)
	atamaLbl.BackgroundTransparency = 1
	atamaLbl.Text = L.kbAssign
	atamaLbl.TextColor3 = currentTheme.textDim
	atamaLbl.Font = Enum.Font.GothamBold
	atamaLbl.TextSize = 13
	atamaLbl.TextXAlignment = Enum.TextXAlignment.Left
	atamaLbl.ZIndex = 202
	atamaLbl.Parent = dialog

	local recordedKey = isEdit and (GetKeybind(emoteId) and GetKeybind(emoteId).key or nil) or nil
	local isRecording = false
	local recordConn

	local keyBtn = Instance.new("TextButton")
	keyBtn.Size = UDim2.new(1, -24, 0, 36)
	keyBtn.Position = UDim2.new(0, 12, 0, 148)
	keyBtn.BackgroundColor3 = currentTheme.tertiary
	keyBtn.Text = recordedKey and ("[" .. recordedKey .. "]") or L.kbRecording
	keyBtn.TextColor3 = recordedKey and currentTheme.accent or currentTheme.textDim
	keyBtn.Font = Enum.Font.GothamBold
	keyBtn.TextSize = 13
	keyBtn.ZIndex = 202
	keyBtn.Parent = dialog
	Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 8)
	local kbStroke = Instance.new("UIStroke")
	kbStroke.Color = currentTheme.stroke
	kbStroke.Thickness = 1.5
	kbStroke.Parent = keyBtn

	keyBtn.MouseButton1Click:Connect(function()
		if isRecording then return end
		isRecording = true
		keyBtn.Text = "..."
		kbStroke.Color = currentTheme.accent
		TweenService:Create(kbStroke, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.7}):Play()
		local UIS2 = game:GetService("UserInputService")
		recordConn = UIS2.InputBegan:Connect(function(inp, gp)
			if gp then return end
			if inp.UserInputType == Enum.UserInputType.Keyboard then
				recordedKey = inp.KeyCode.Name
				isRecording = false
				recordConn:Disconnect()
				keyBtn.Text = "[" .. recordedKey .. "]"
				keyBtn.TextColor3 = currentTheme.accent
				kbStroke.Color = currentTheme.stroke
				TweenService:Create(kbStroke, TweenInfo.new(0.1), {Transparency = 0}):Play()
			end
		end)
	end)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Size = UDim2.new(0.45, -6, 0, 38)
	cancelBtn.Position = UDim2.new(0, 12, 0, 208)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	cancelBtn.Text = L.kbCancel
	cancelBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 14
	cancelBtn.ZIndex = 202
	cancelBtn.Parent = dialog
	Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 10)

	local saveBtn = Instance.new("TextButton")
	saveBtn.Size = UDim2.new(0.55, -18, 0, 38)
	saveBtn.Position = UDim2.new(0.45, 6, 0, 208)
	saveBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
	saveBtn.Text = L.kbSave
	saveBtn.TextColor3 = Color3.new(1, 1, 1)
	saveBtn.Font = Enum.Font.GothamBold
	saveBtn.TextSize = 14
	saveBtn.ZIndex = 202
	saveBtn.Parent = dialog
	Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 10)

	cancelBtn.MouseButton1Click:Connect(function()
		if recordConn then pcall(function() recordConn:Disconnect() end) end
		overlay:Destroy()
	end)

	local _KB_BLACKLIST = {Unknown=true, Backspace=true, Delete=true, Escape=true,
		Return=true, Tab=true, CapsLock=true, LeftShift=true, RightShift=true,
		LeftControl=true, RightControl=true, LeftAlt=true, RightAlt=true,
		LeftMeta=true, RightMeta=true, Insert=true, Home=true, End=true,
		PageUp=true, PageDown=true, NumLock=true, ScrollLock=true, Pause=true, Print=true}

	saveBtn.MouseButton1Click:Connect(function()
		if not recordedKey then return end
		if _KB_BLACKLIST[recordedKey] then
			keyBtn.Text = L.kbInvalidKey or "Invalid key!"
			keyBtn.TextColor3 = Color3.fromRGB(220, 50, 50)
			task.delay(1.5, function()
				if recordedKey then
					keyBtn.Text = "[" .. recordedKey .. "]"
					keyBtn.TextColor3 = currentTheme.accent
				end
			end)
			return
		end
		if recordConn then pcall(function() recordConn:Disconnect() end) end
		local kbName = nameBox.Text ~= "" and nameBox.Text or emote.name
		SetKeybind(emoteId, kbName, recordedKey)
		overlay:Destroy()
		Refresh(false)
		if currentTab == "keybinds" and RefreshKeybindsPanel then RefreshKeybindsPanel() end
	end)

	dialog.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(dialog, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = UDim2.new(0.85, 0, 0, 260)}):Play()
end

RefreshKeybindsPanel = function()
	for _, c in ipairs(keybindsPanel:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
	local hasAny = false
	for emoteId, kb in pairs(KeybindsSet) do
		if tonumber(emoteId) then
			hasAny = true
			local emote = EmotesById[emoteId]
		local emoteName = emote and emote.name or ("Emote #"..emoteId)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 56)
		row.BackgroundColor3 = currentTheme.secondary
		row.BorderSizePixel = 0
		row.ZIndex = 6
		row.Parent = keybindsPanel
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
		local thumb = Instance.new("ImageLabel")
		thumb.Size = UDim2.new(0, 44, 0, 44)
		thumb.Position = UDim2.new(0, 6, 0.5, -22)
		thumb.BackgroundTransparency = 1
		thumb.Image = "rbxthumb://type=Asset&id="..emoteId.."&w=420&h=420"
		thumb.ZIndex = 7
		thumb.Parent = row
		Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 6)
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -130, 0, 20)
		nameLbl.Position = UDim2.new(0, 56, 0, 8)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = emoteName
		nameLbl.TextColor3 = currentTheme.text
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 13
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.ZIndex = 7
		nameLbl.Parent = row
		local keyLbl = Instance.new("TextLabel")
		keyLbl.Size = UDim2.new(0, 38, 0, 24)
		keyLbl.Position = UDim2.new(0, 56, 0, 28)
		keyLbl.BackgroundColor3 = currentTheme.accent
		keyLbl.Text = kb.key
		keyLbl.TextColor3 = currentTheme.primary
		keyLbl.Font = Enum.Font.GothamBold
		keyLbl.TextSize = 12
		keyLbl.ZIndex = 7
		keyLbl.Parent = row
		Instance.new("UICorner", keyLbl).CornerRadius = UDim.new(0, 6)
		local customName = Instance.new("TextLabel")
		customName.Size = UDim2.new(1, -110, 0, 14)
		customName.Position = UDim2.new(0, 100, 0, 30)
		customName.BackgroundTransparency = 1
		customName.Text = kb.name ~= "" and kb.name or ""
		customName.TextColor3 = currentTheme.textDim
		customName.Font = Enum.Font.Gotham
		customName.TextSize = 11
		customName.TextXAlignment = Enum.TextXAlignment.Left
		customName.ZIndex = 7
		customName.Parent = row
		local delBtn = Instance.new("ImageButton")
		delBtn.Size = UDim2.new(0, 42, 0, 42)
		delBtn.Position = UDim2.new(1, -40, 0.5, -16)
		delBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		delBtn.Image = ResolveAssetImage(Icons.KeybindRemove)
		delBtn.ImageColor3 = Color3.new(1,1,1)
		delBtn.ZIndex = 7
		delBtn.Parent = row
		Instance.new("UICorner", delBtn).CornerRadius = UDim.new(1, 0)
		delBtn.MouseButton1Click:Connect(function()
			RemoveKeybind(emoteId)
			RefreshKeybindsPanel()
		end)
		end
	end
	if not hasAny then
		local emptyLbl2 = Instance.new("TextLabel")
		emptyLbl2.Size = UDim2.new(1, 0, 0, 60)
		emptyLbl2.BackgroundTransparency = 1
		emptyLbl2.Text = L.kbEmpty
		emptyLbl2.TextColor3 = currentTheme.textDim
		emptyLbl2.Font = Enum.Font.Gotham
		emptyLbl2.TextSize = 14
		emptyLbl2.ZIndex = 6
		emptyLbl2.Parent = keybindsPanel
	end
end

-- ===============================================================
-- CARD SYSTEM
-- ===============================================================

	return true
end
