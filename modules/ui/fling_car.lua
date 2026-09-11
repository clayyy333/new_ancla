-- Vista Car Fling integrada en la categoria Fling 2.
return function(context)
	setfenv(1, context)

	carFlingPanel = Instance.new("Frame")
	carFlingPanel.Name = "CarFlingPanel"
	carFlingPanel.Size = UDim2.new(1, -16, 1, -(titleH + 20))
	carFlingPanel.Position = UDim2.new(0, 8, 0, titleH + 8)
	carFlingPanel.BackgroundTransparency = 1
	carFlingPanel.Visible = false
	carFlingPanel.ZIndex = 6
	carFlingPanel.Parent = content

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, isMobile and 278 or 292)
	card.BackgroundColor3 = currentTheme.secondary
	card.ZIndex = 7
	card.Parent = carFlingPanel
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

	makeLabel(isES and "Mi vehículo" or "My vehicle", 0)
	local carButton = makeSelector(isES and "Seleccionar vehículo" or "Select vehicle", 22)
	makeLabel(isES and "Jugador objetivo" or "Target player", 70)
	local playerButton = makeSelector(L.selectPlayer, 92)
	local carList, playerList = makeList(64), makeList(134)

	local action = Instance.new("TextButton")
	action.Size, action.Position = UDim2.new(1,0,0,44), UDim2.new(0,0,0,146)
	action.BackgroundColor3, action.Text = currentTheme.tertiary, isES and "Activar Fling con vehículo" or "Enable Fling with Car"
	action.TextColor3, action.Font, action.TextSize = currentTheme.text, Enum.Font.GothamBold, isMobile and 12 or 14
	action.AutoButtonColor, action.ZIndex, action.Parent = false, 8, card
	Instance.new("UICorner", action).CornerRadius = UDim.new(0,10)
	RegisterTheme(action, "BackgroundColor3", "tertiary"); RegisterTheme(action, "TextColor3", "text")

	local info = makeLabel(isES and "El vehículo realiza el Fling; tu personaje no se mueve." or "The vehicle performs the Fling; your character does not move.", 200)
	info.TextWrapped, info.Size = true, UDim2.new(1,0,0,34)
	local status = makeLabel("", 236)
	status.Size = UDim2.new(1, 0, 0, 42)
	status.TextWrapped = true

	UpdateCarFlingPanel = function(message)
		local car, target = CarFling:GetCar(), CarFling:GetPlayer()
		carButton.Text = car and car.Name or (isES and "Seleccionar vehículo" or "Select vehicle")
		playerButton.Text = target and (target.DisplayName.."  (@"..target.Name..")") or L.selectPlayer
		action.Text = CarFling.Running and (isES and "Desactivar Fling con vehículo" or "Disable Fling with Car") or (isES and "Activar Fling con vehículo" or "Enable Fling with Car")
		action.BackgroundColor3 = CarFling.Running and currentTheme.critical or currentTheme.tertiary
		local code, detail = CarFling:GetDiagnostic()
		local diagnostic = code .. (detail ~= "" and (" | " .. detail) or "")
		status.Text = message or (CarFling.Running and ((isES and "Estado: " or "State: ")..tostring(CarFling.EfficientPhase).." | "..diagnostic) or ((isES and "Estado: detenido" or "State: stopped").." | "..diagnostic))
	end
	local function clearOptions(list)
		for _, child in ipairs(list:GetChildren()) do if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end end
	end
	local function refreshCars()
		clearOptions(carList)
		local cars = CarFling:GetCarOptions()
		if #cars == 0 then makeOption(carList, isES and "No se encontraron vehículos propios" or "No owned vehicles found", function() end); return end
		for _, car in ipairs(cars) do makeOption(carList, car.Name, function()
			CarFling:SetCar(car); carList.Visible=false; UpdateCarFlingPanel()
		end) end
	end
	local function refreshPlayers()
		clearOptions(playerList)
		for _, target in ipairs(Players:GetPlayers()) do if target ~= player then makeOption(playerList, target.DisplayName.."  (@"..target.Name..")", function()
			CarFling:SetPlayer(target); playerList.Visible=false; UpdateCarFlingPanel()
		end) end end
	end
	carButton.MouseButton1Click:Connect(function()
		carList.Visible=not carList.Visible; playerList.Visible=false
		if carList.Visible then refreshCars() end
	end)
	playerButton.MouseButton1Click:Connect(function()
		playerList.Visible=not playerList.Visible; carList.Visible=false
		if playerList.Visible then refreshPlayers() end
	end)
	action.MouseButton1Click:Connect(function()
		if CarFling.Running then CarFling:Stop(); UpdateCarFlingPanel(); return end
		if not CarFling:GetCar() then UpdateCarFlingPanel(isES and "Selecciona un vehículo propio" or "Select an owned vehicle"); return end
		if not CarFling:GetPlayer() then UpdateCarFlingPanel(L.selectPlayerFirst); return end
		local ok, err = CarFling:Start(); UpdateCarFlingPanel(ok and nil or (err or L.flingStartFailed))
	end)
	_carFlingUiConn = RunService.Heartbeat:Connect(function()
		if not carFlingPanel.Visible or not CarFling.Running then return end
		local code, detail = CarFling:GetDiagnostic()
		if CarFling.LastHeartbeatAt > 0 and os.clock() - CarFling.LastHeartbeatAt > 0.5 then
			code, detail = "HEARTBEAT_STALLED", string.format("%.2fs", os.clock() - CarFling.LastHeartbeatAt)
		end
		status.Text = (isES and "Estado: " or "State: ") .. tostring(CarFling.EfficientPhase) .. " | " .. code .. (detail ~= "" and (" | " .. detail) or "")
	end)
	UpdateCarFlingPanel()
	return true
end
