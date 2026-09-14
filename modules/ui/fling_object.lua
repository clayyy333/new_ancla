-- Vista Object Fling integrada en la categoria Fling 2.
return function(context)
	setfenv(1, context)

	objectFlingPanel = Instance.new("Frame")
	objectFlingPanel.Name = "ObjectFlingPanel"
	objectFlingPanel.Size = UDim2.new(1, -16, 1, -(titleH + 20))
	objectFlingPanel.Position = UDim2.new(0, 8, 0, titleH + 8)
	objectFlingPanel.BackgroundTransparency = 1
	objectFlingPanel.Visible = false
	objectFlingPanel.ZIndex = 6
	objectFlingPanel.Parent = content

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, isMobile and 398 or 412)
	card.BackgroundColor3 = currentTheme.secondary
	card.ZIndex = 7
	card.Parent = objectFlingPanel
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
	RegisterTheme(card, "BackgroundColor3", "secondary")
	local pad = Instance.new("UIPadding", card)
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop = UDim.new(0,14), UDim.new(0,14), UDim.new(0,14)

	local function makeLabel(text, y)
		local label = Instance.new("TextLabel")
		label.Size, label.Position = UDim2.new(1,0,0,18), UDim2.new(0,0,0,y)
		label.BackgroundTransparency, label.Text = 1, text
		label.TextColor3, label.Font, label.TextSize = currentTheme.textDim, Enum.Font.GothamMedium, isMobile and 11 or 12
		label.TextXAlignment, label.ZIndex, label.Parent = Enum.TextXAlignment.Left, 8, card
		RegisterTheme(label, "TextColor3", "textDim")
		return label
	end
	local function makeSelector(text, y)
		local button = Instance.new("TextButton")
		button.Size, button.Position = UDim2.new(1,0,0,38), UDim2.new(0,0,0,y)
		button.BackgroundColor3, button.Text = currentTheme.tertiary, text
		button.TextColor3, button.Font, button.TextSize = currentTheme.text, Enum.Font.GothamMedium, isMobile and 11 or 13
		button.TextXAlignment, button.AutoButtonColor, button.ZIndex, button.Parent = Enum.TextXAlignment.Left, false, 10, card
		Instance.new("UICorner", button).CornerRadius = UDim.new(0,10)
		Instance.new("UIPadding", button).PaddingLeft = UDim.new(0,12)
		RegisterTheme(button, "BackgroundColor3", "tertiary"); RegisterTheme(button, "TextColor3", "text")
		return button
	end
	local function makeList(y)
		local list = Instance.new("ScrollingFrame")
		list.Size, list.Position = UDim2.new(1,0,0,108), UDim2.new(0,0,0,y)
		list.BackgroundColor3, list.ScrollBarThickness = currentTheme.tertiary, 4
		list.AutomaticCanvasSize, list.CanvasSize, list.Visible = Enum.AutomaticSize.Y, UDim2.new(), false
		list.ZIndex, list.Parent = 30, card
		Instance.new("UICorner", list).CornerRadius = UDim.new(0,10)
		Instance.new("UIListLayout", list).Padding = UDim.new(0,3)
		RegisterTheme(list, "BackgroundColor3", "tertiary")
		return list
	end
	local function makeOption(list, text, callback)
		local option = Instance.new("TextButton")
		option.Size, option.BackgroundColor3 = UDim2.new(1,-4,0,32), currentTheme.secondary
		option.Text, option.TextColor3, option.Font = text, currentTheme.text, Enum.Font.GothamMedium
		option.TextSize, option.ZIndex, option.Parent = isMobile and 10 or 12, 31, list
		Instance.new("UICorner", option).CornerRadius = UDim.new(0,8)
		RegisterTheme(option, "BackgroundColor3", "secondary"); RegisterTheme(option, "TextColor3", "text")
		option.MouseButton1Click:Connect(callback)
	end

	makeLabel(isES and "Mi objeto" or "My object", 0)
	local carButton = makeSelector(isES and "Seleccionar objeto" or "Select object", 22)
	makeLabel(isES and "Jugador objetivo" or "Target player", 70)
	local playerButton = makeSelector(L.selectPlayer, 92)
	local carList, playerList = makeList(64), makeList(134)

	local action = Instance.new("TextButton")
	action.Size, action.Position = UDim2.new(1,0,0,44), UDim2.new(0,0,0,194)
	action.BackgroundColor3, action.Text = currentTheme.tertiary, isES and "Activar Delta estable" or "Enable Stable Delta"
	action.TextColor3, action.Font, action.TextSize = currentTheme.text, Enum.Font.GothamBold, isMobile and 12 or 14
	action.AutoButtonColor, action.ZIndex, action.Parent = false, 8, card
	Instance.new("UICorner", action).CornerRadius = UDim.new(0,10)
	RegisterTheme(action, "BackgroundColor3", "tertiary"); RegisterTheme(action, "TextColor3", "text")

	local xenoAction = action:Clone()
	xenoAction.Name = "XenoObjectFlingButton"
	xenoAction.Position = UDim2.new(0,0,0,246)
	xenoAction.Text = isES and "Activar Xeno estable" or "Enable Stable Xeno"
	xenoAction.Parent = card
	RegisterTheme(xenoAction, "BackgroundColor3", "tertiary"); RegisterTheme(xenoAction, "TextColor3", "text")
	local autoDelta, autoXeno, autoStarting = false, false, false
	local autoDeltaButton = action:Clone()
	autoDeltaButton.Name = "AutoDeltaButton"
	autoDeltaButton.Size = UDim2.new(0.5, -4, 0, 40)
	autoDeltaButton.Position = UDim2.new(0, 0, 0, 146)
	autoDeltaButton.TextSize = isMobile and 10 or 11
	autoDeltaButton.Parent = card
	local autoXenoButton = action:Clone()
	autoXenoButton.Name = "AutoXenoButton"
	autoXenoButton.Size = UDim2.new(0.5, -4, 0, 40)
	autoXenoButton.Position = UDim2.new(0.5, 4, 0, 146)
	autoXenoButton.TextSize = isMobile and 10 or 11
	autoXenoButton.Parent = card

	local info = makeLabel(isES and "Modo estable: FAR moderado de 50 a 200 studs." or "Stable mode: moderate FAR from 50 to 200 studs.", 298)
	info.TextWrapped, info.Size = true, UDim2.new(1,0,0,34)
	local status = makeLabel("", 334)
	status.Size = UDim2.new(1, 0, 0, 42)
	status.TextWrapped = true

	UpdateObjectFlingPanel = function(message)
		local car, target = ObjectFling2Delta:GetCar(), ObjectFling2Delta:GetPlayer()
		carButton.Text = car and car.Name or (isES and "Seleccionar objeto" or "Select object")
		playerButton.Text = target and (target.DisplayName.."  (@"..target.Name..")") or L.selectPlayer
		action.Text = ObjectFling2Delta.Running and (isES and "Desactivar Delta estable" or "Disable Stable Delta") or (isES and "Activar Delta estable" or "Enable Stable Delta")
		xenoAction.Text = ObjectFling2Xeno.Running and (isES and "Desactivar Xeno estable" or "Disable Stable Xeno") or (isES and "Activar Xeno estable" or "Enable Stable Xeno")
		action.BackgroundColor3 = ObjectFling2Delta.Running and currentTheme.critical or currentTheme.tertiary
		xenoAction.BackgroundColor3 = ObjectFling2Xeno.Running and currentTheme.critical or currentTheme.tertiary
		local activeCore = ObjectFling2Xeno.Running and ObjectFling2Xeno or ObjectFling2Delta
		local code, detail = "DELTA_STABLE", ""
		if ObjectFling2Xeno.Running then code, detail = ObjectFling2Xeno:GetDiagnostic() end
		local diagnostic = code .. (detail ~= "" and (" | " .. detail) or "")
		status.Text = message or ((ObjectFling2Delta.Running or ObjectFling2Xeno.Running) and ((isES and "Estado: " or "State: ")..tostring(activeCore.EfficientPhase).." | "..diagnostic) or ((isES and "Estado: detenido" or "State: stopped").." | "..diagnostic))
		autoDeltaButton.Text = (autoDelta and "[x] " or "[ ] ") .. (isES and "Activación automática Delta" or "Automatic Delta activation")
		autoXenoButton.Text = (autoXeno and "[x] " or "[ ] ") .. (isES and "Activación automática Xeno" or "Automatic Xeno activation")
		autoDeltaButton.BackgroundColor3 = autoDelta and currentTheme.accent or currentTheme.tertiary
		autoXenoButton.BackgroundColor3 = autoXeno and currentTheme.accent or currentTheme.tertiary
	end
	local tryAutomaticStart
	tryAutomaticStart = function()
		if autoStarting or ObjectFling2Delta.Running or ObjectFling2Xeno.Running then return end
		local selected = autoDelta and ObjectFling2Delta or (autoXeno and ObjectFling2Xeno or nil)
		if not selected or not selected:GetCar() or not selected:GetPlayer() then return end
		autoStarting = true
		local ok, err = selected:Start()
		autoStarting = false
		UpdateObjectFlingPanel(ok and nil or (err or L.flingStartFailed))
	end

	autoDeltaButton.MouseButton1Click:Connect(function()
		autoDelta = not autoDelta
		if autoDelta then autoXeno = false end
		UpdateObjectFlingPanel()
		tryAutomaticStart()
	end)
	autoXenoButton.MouseButton1Click:Connect(function()
		autoXeno = not autoXeno
		if autoXeno then autoDelta = false end
		UpdateObjectFlingPanel()
		tryAutomaticStart()
	end)

	local function clearOptions(list)
		for _, child in ipairs(list:GetChildren()) do if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end end
	end
	local function refreshObjects()
		clearOptions(carList)
		local cars = ObjectFling2Delta:GetCarOptions()
		if #cars == 0 then makeOption(carList, isES and "No se encontraron objetos utilizables" or "No usable Backpack objects found", function() end); return end
		for _, car in ipairs(cars) do makeOption(carList, car.Name, function()
			ObjectFling2Delta:SetCar(car); ObjectFling2Xeno:SetCar(car); carList.Visible=false; UpdateObjectFlingPanel(); task.defer(tryAutomaticStart)
		end) end
	end
	local function refreshPlayers()
		clearOptions(playerList)
		for _, target in ipairs(Players:GetPlayers()) do if target ~= player then makeOption(playerList, target.DisplayName.."  (@"..target.Name..")", function()
			ObjectFling2Delta:SetPlayer(target); ObjectFling2Xeno:SetPlayer(target); playerList.Visible=false; UpdateObjectFlingPanel(); task.defer(tryAutomaticStart)
		end) end end
	end
	carButton.MouseButton1Click:Connect(function()
		carList.Visible=not carList.Visible; playerList.Visible=false
		if carList.Visible then refreshObjects() end
	end)
	playerButton.MouseButton1Click:Connect(function()
		playerList.Visible=not playerList.Visible; carList.Visible=false
		if playerList.Visible then refreshPlayers() end
	end)
	action.MouseButton1Click:Connect(function()
		if ObjectFling2Delta.Running then autoDelta = false; ObjectFling2Delta:Stop(); UpdateObjectFlingPanel(); return end
		if ObjectFling2Xeno.Running then UpdateObjectFlingPanel(isES and "Desactiva Xeno primero" or "Disable Stable Xeno first"); return end
		if not ObjectFling2Delta:GetCar() then UpdateObjectFlingPanel(isES and "Selecciona un objeto del Backpack" or "Select a Backpack object"); return end
		if not ObjectFling2Delta:GetPlayer() then UpdateObjectFlingPanel(L.selectPlayerFirst); return end
		local ok, err = ObjectFling2Delta:Start(); UpdateObjectFlingPanel(ok and nil or (err or L.flingStartFailed))
	end)
	xenoAction.MouseButton1Click:Connect(function()
		if ObjectFling2Xeno.Running then autoXeno = false; ObjectFling2Xeno:Stop(); UpdateObjectFlingPanel(); return end
		if ObjectFling2Delta.Running then UpdateObjectFlingPanel(isES and "Desactiva Delta estable primero" or "Disable Stable Delta first"); return end
		if not ObjectFling2Xeno:GetCar() then UpdateObjectFlingPanel(isES and "Selecciona un objeto del Backpack" or "Select a Backpack object"); return end
		if not ObjectFling2Xeno:GetPlayer() then UpdateObjectFlingPanel(L.selectPlayerFirst); return end
		local ok, err = ObjectFling2Xeno:Start(); UpdateObjectFlingPanel(ok and nil or (err or L.flingStartFailed))
	end)
	_objectFlingUiConn = RunService.Heartbeat:Connect(function()
		if not objectFlingPanel.Visible then return end
		if (not ObjectFling2Delta.Running and not ObjectFling2Xeno.Running) then return end
		local activeCore = ObjectFling2Xeno.Running and ObjectFling2Xeno or ObjectFling2Delta
		local code, detail = "DELTA_STABLE", ""
		if ObjectFling2Xeno.Running then
			code, detail = ObjectFling2Xeno:GetDiagnostic()
			if ObjectFling2Xeno.LastHeartbeatAt > 0 and os.clock() - ObjectFling2Xeno.LastHeartbeatAt > 0.5 then
				code, detail = "HEARTBEAT_STALLED", string.format("%.2fs", os.clock() - ObjectFling2Xeno.LastHeartbeatAt)
			end
		end
		status.Text = (isES and "Estado: " or "State: ") .. tostring(activeCore.EfficientPhase) .. " | " .. code .. (detail ~= "" and (" | " .. detail) or "")
	end)
	UpdateObjectFlingPanel()
	return true
end
