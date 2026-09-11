-- Vista Car Fling integrada en la categoria Fling 2.
return function(context)
	setfenv(1, context)

	carFling2Panel = Instance.new("Frame")
	carFling2Panel.Name = "CarFling2Panel"
	carFling2Panel.Size = UDim2.new(1, -16, 1, -(titleH + 20))
	carFling2Panel.Position = UDim2.new(0, 8, 0, titleH + 8)
	carFling2Panel.BackgroundTransparency = 1
	carFling2Panel.Visible = false
	carFling2Panel.ZIndex = 6
	carFling2Panel.Parent = content

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, isMobile and 338 or 352)
	card.BackgroundColor3 = currentTheme.secondary
	card.ZIndex = 7
	card.Parent = carFling2Panel
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
	action.BackgroundColor3, action.Text = currentTheme.tertiary, isES and "Activar Delta estable" or "Enable Stable Delta"
	action.TextColor3, action.Font, action.TextSize = currentTheme.text, Enum.Font.GothamBold, isMobile and 12 or 14
	action.AutoButtonColor, action.ZIndex, action.Parent = false, 8, card
	Instance.new("UICorner", action).CornerRadius = UDim.new(0,10)
	RegisterTheme(action, "BackgroundColor3", "tertiary"); RegisterTheme(action, "TextColor3", "text")

	local xenoAction = action:Clone()
	xenoAction.Name = "XenoCarFling2Button"
	xenoAction.Position = UDim2.new(0,0,0,198)
	xenoAction.Text = isES and "Activar Xeno estable" or "Enable Stable Xeno"
	xenoAction.Parent = card
	RegisterTheme(xenoAction, "BackgroundColor3", "tertiary"); RegisterTheme(xenoAction, "TextColor3", "text")

	local info = makeLabel(isES and "Modo estable: FAR moderado de 50 a 200 studs." or "Stable mode: moderate FAR from 50 to 200 studs.", 250)
	info.TextWrapped, info.Size = true, UDim2.new(1,0,0,34)
	local status = makeLabel("", 286)
	status.Size = UDim2.new(1, 0, 0, 42)
	status.TextWrapped = true

	UpdateCarFling2Panel = function(message)
		local car, target = CarFling2Delta:GetCar(), CarFling2Delta:GetPlayer()
		carButton.Text = car and car.Name or (isES and "Seleccionar vehículo" or "Select vehicle")
		playerButton.Text = target and (target.DisplayName.."  (@"..target.Name..")") or L.selectPlayer
		action.Text = CarFling2Delta.Running and (isES and "Desactivar Delta estable" or "Disable Stable Delta") or (isES and "Activar Delta estable" or "Enable Stable Delta")
		xenoAction.Text = CarFling2Xeno.Running and (isES and "Desactivar Xeno estable" or "Disable Stable Xeno") or (isES and "Activar Xeno estable" or "Enable Stable Xeno")
		action.BackgroundColor3 = CarFling2Delta.Running and currentTheme.critical or currentTheme.tertiary
		xenoAction.BackgroundColor3 = CarFling2Xeno.Running and currentTheme.critical or currentTheme.tertiary
		local activeCore = CarFling2Xeno.Running and CarFling2Xeno or CarFling2Delta
		local code, detail = "DELTA_STABLE", ""
		if CarFling2Xeno.Running then code, detail = CarFling2Xeno:GetDiagnostic() end
		local diagnostic = code .. (detail ~= "" and (" | " .. detail) or "")
		status.Text = message or ((CarFling2Delta.Running or CarFling2Xeno.Running) and ((isES and "Estado: " or "State: ")..tostring(activeCore.EfficientPhase).." | "..diagnostic) or ((isES and "Estado: detenido" or "State: stopped").." | "..diagnostic))
	end
	local function clearOptions(list)
		for _, child in ipairs(list:GetChildren()) do if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end end
	end
	local function refreshCars()
		clearOptions(carList)
		local cars = CarFling2Delta:GetCarOptions()
		if #cars == 0 then makeOption(carList, isES and "No se encontraron vehículos propios" or "No owned vehicles found", function() end); return end
		for _, car in ipairs(cars) do makeOption(carList, car.Name, function()
			CarFling2Delta:SetCar(car); CarFling2Xeno:SetCar(car); carList.Visible=false; UpdateCarFling2Panel()
		end) end
	end
	local function refreshPlayers()
		clearOptions(playerList)
		for _, target in ipairs(Players:GetPlayers()) do if target ~= player then makeOption(playerList, target.DisplayName.."  (@"..target.Name..")", function()
			CarFling2Delta:SetPlayer(target); CarFling2Xeno:SetPlayer(target); playerList.Visible=false; UpdateCarFling2Panel()
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
		if CarFling2Delta.Running then CarFling2Delta:Stop(); UpdateCarFling2Panel(); return end
		if CarFling2Xeno.Running then UpdateCarFling2Panel(isES and "Desactiva Xeno primero" or "Disable Stable Xeno first"); return end
		if not CarFling2Delta:GetCar() then UpdateCarFling2Panel(isES and "Selecciona un vehículo propio" or "Select an owned vehicle"); return end
		if not CarFling2Delta:GetPlayer() then UpdateCarFling2Panel(L.selectPlayerFirst); return end
		local ok, err = CarFling2Delta:Start(); UpdateCarFling2Panel(ok and nil or (err or L.flingStartFailed))
	end)
	xenoAction.MouseButton1Click:Connect(function()
		if CarFling2Xeno.Running then CarFling2Xeno:Stop(); UpdateCarFling2Panel(); return end
		if CarFling2Delta.Running then UpdateCarFling2Panel(isES and "Desactiva Delta estable primero" or "Disable Stable Delta first"); return end
		if not CarFling2Xeno:GetCar() then UpdateCarFling2Panel(isES and "Selecciona un vehículo propio" or "Select an owned vehicle"); return end
		if not CarFling2Xeno:GetPlayer() then UpdateCarFling2Panel(L.selectPlayerFirst); return end
		local ok, err = CarFling2Xeno:Start(); UpdateCarFling2Panel(ok and nil or (err or L.flingStartFailed))
	end)
	_carFling2UiConn = RunService.Heartbeat:Connect(function()
		if not carFling2Panel.Visible or (not CarFling2Delta.Running and not CarFling2Xeno.Running) then return end
		local activeCore = CarFling2Xeno.Running and CarFling2Xeno or CarFling2Delta
		local code, detail = "DELTA_STABLE", ""
		if CarFling2Xeno.Running then
			code, detail = CarFling2Xeno:GetDiagnostic()
			if CarFling2Xeno.LastHeartbeatAt > 0 and os.clock() - CarFling2Xeno.LastHeartbeatAt > 0.5 then
				code, detail = "HEARTBEAT_STALLED", string.format("%.2fs", os.clock() - CarFling2Xeno.LastHeartbeatAt)
			end
		end
		status.Text = (isES and "Estado: " or "State: ") .. tostring(activeCore.EfficientPhase) .. " | " .. code .. (detail ~= "" and (" | " .. detail) or "")
	end)
	UpdateCarFling2Panel()
	return true
end
