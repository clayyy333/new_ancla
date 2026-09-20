-- Panel integrado de Parejas.
return function(context)
	setfenv(1, context)

	couplesPanel = Instance.new("ScrollingFrame")
	couplesPanel.Size = UDim2.new(1, -16, 1, -(titleH + 20))
	couplesPanel.Position = UDim2.new(0, 8, 0, titleH + 8)
	couplesPanel.BackgroundTransparency = 1
	couplesPanel.BorderSizePixel = 0
	couplesPanel.ScrollBarThickness = 3
	couplesPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
	couplesPanel.CanvasSize = UDim2.new()
	couplesPanel.Visible = false
	couplesPanel.ZIndex = 6
	couplesPanel.Parent = content

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -4, 0, 530)
	card.BackgroundColor3 = currentTheme.secondary
	card.ZIndex = 7
	card.Parent = couplesPanel
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
	RegisterTheme(card, "BackgroundColor3", "secondary")
	local padding = Instance.new("UIPadding", card)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 14)

	local function makeLabel(text, y)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 18)
		label.Position = UDim2.new(0, 0, 0, y)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextColor3 = currentTheme.textDim
		label.Font = Enum.Font.GothamMedium
		label.TextSize = isMobile and 10 or 12
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = 8
		label.Parent = card
		RegisterTheme(label, "TextColor3", "textDim")
		return label
	end

	local function makeButton(text, y, x, width, zIndex)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(width or 1, 0, 0, 40)
		button.Position = UDim2.new(x or 0, 0, 0, y)
		button.BackgroundColor3 = currentTheme.tertiary
		button.Text = text
		button.TextColor3 = currentTheme.text
		button.Font = Enum.Font.GothamBold
		button.TextSize = isMobile and 10 or 12
		button.AutoButtonColor = false
		button.ZIndex = zIndex or 8
		button.Parent = card
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
		RegisterTheme(button, "BackgroundColor3", "tertiary")
		RegisterTheme(button, "TextColor3", "text")
		return button
	end

	local function makeControlRow(caption, y)
		makeLabel(caption, y)
		return makeButton("−", y + 22, 0, 0.20),
			makeButton("", y + 22, 0.22, 0.56),
			makeButton("+", y + 22, 0.80, 0.20)
	end

	makeLabel(isES and "Jugador objetivo" or "Target player", 0)
	local targetButton = makeButton(isES and "Seleccionar jugador" or "Select player", 22)
	targetButton.TextXAlignment = Enum.TextXAlignment.Left
	targetButton.Font = Enum.Font.GothamMedium
	targetButton.ZIndex = 10
	Instance.new("UIPadding", targetButton).PaddingLeft = UDim.new(0, 12)

	local targetList = Instance.new("ScrollingFrame")
	targetList.Size = UDim2.new(1, 0, 0, 120)
	targetList.Position = UDim2.new(0, 0, 0, 64)
	targetList.BackgroundColor3 = currentTheme.tertiary
	targetList.BorderSizePixel = 0
	targetList.ScrollBarThickness = 4
	targetList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	targetList.CanvasSize = UDim2.new()
	targetList.Visible = false
	targetList.ZIndex = 30
	targetList.Parent = card
	Instance.new("UICorner", targetList).CornerRadius = UDim.new(0, 10)
	Instance.new("UIListLayout", targetList).Padding = UDim.new(0, 3)
	RegisterTheme(targetList, "BackgroundColor3", "tertiary")

	local distanceMinus, distanceValue, distancePlus = makeControlRow(isES and "Distancia" or "Distance", 72)
	local heightMinus, heightValue, heightPlus = makeControlRow(isES and "Altura" or "Height", 140)
	local angleMinus, angleValue, anglePlus = makeControlRow(isES and "Giro alrededor del jugador" or "Rotation around player", 208)
	angleMinus.Text, anglePlus.Text = "↶", "↷"
	local selfMinus, selfValue, selfPlus = makeControlRow(isES and "Giro sobre su eje" or "Rotation on own axis", 276)
	selfMinus.Text, selfPlus.Text = "↶", "↷"
	local positionButton = makeButton(isES and "Colocar frente a frente" or "Position face to face", 346, 0, 0.67)
	local resetButton = makeButton(isES and "Restablecer" or "Reset", 346, 0.69, 0.31)
	local savedButton = makeButton(isES and "Bucles guardados" or "Saved loops", 396)
	local savePoseButton = makeButton(isES and "Guardar bucle con ubicación" or "Save loop with location", 446)
	local selectedLoop = nil
	local status = makeLabel(isES and "Selecciona un jugador y ajusta la posición." or "Select a player and adjust the position.", 490)

	UpdateCouplesPanel = function(message)
		local target = CouplesPositionController:GetTarget()
		targetButton.Text = target and (target.DisplayName .. "  (@" .. target.Name .. ")") or (isES and "Seleccionar jugador" or "Select player")
		distanceValue.Text = string.format("%.1f studs", CouplesPositionController:GetDistance())
		heightValue.Text = string.format("%+.1f", CouplesPositionController:GetHeight())
		angleValue.Text = tostring(math.floor(CouplesPositionController:GetAngle())) .. "°"
		selfValue.Text = tostring(math.floor(CouplesPositionController:GetSelfAngle())) .. "°"
		positionButton.Text = CouplesPositionController:IsMaintaining() and (isES and "Liberar ubicación" or "Release location") or (isES and "Colocar frente a frente" or "Position face to face")
		positionButton.BackgroundColor3 = CouplesPositionController:IsMaintaining() and currentTheme.critical or currentTheme.tertiary
		if message then status.Text = message end
	end

	local function clearOptions()
		for _, child in ipairs(targetList:GetChildren()) do
			if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
		end
	end
	local function addOption(text, callback)
		local option = makeButton(text, 0, 0, 1, 31)
		option.Parent = targetList
		option.Position = UDim2.new()
		option.Size = UDim2.new(1, -4, 0, 34)
		if callback then option.MouseButton1Click:Connect(callback) end
	end

	targetButton.MouseButton1Click:Connect(function()
		targetList.Visible = not targetList.Visible
		if not targetList.Visible then return end
		clearOptions()
		local options = CouplesPositionController:GetTargetOptions()
		if #options == 0 then
			addOption(isES and "No hay otros jugadores" or "No other players")
		else
			for _, targetPlayer in ipairs(options) do
				addOption(targetPlayer.DisplayName .. "  (@" .. targetPlayer.Name .. ")", function()
					CouplesPositionController:SetTarget(targetPlayer)
					targetList.Visible = false
					UpdateCouplesPanel(isES and "Listo para posicionar." or "Ready to position.")
				end)
			end
		end
	end)

	local function adjust(method, delta)
		local ok, message = method(CouplesPositionController, delta)
		UpdateCouplesPanel(ok and nil or message)
	end
	distanceMinus.MouseButton1Click:Connect(function() adjust(CouplesPositionController.AdjustDistance, -0.1) end)
	distancePlus.MouseButton1Click:Connect(function() adjust(CouplesPositionController.AdjustDistance, 0.1) end)
	heightMinus.MouseButton1Click:Connect(function() adjust(CouplesPositionController.AdjustHeight, -0.1) end)
	heightPlus.MouseButton1Click:Connect(function() adjust(CouplesPositionController.AdjustHeight, 0.1) end)
	angleMinus.MouseButton1Click:Connect(function() adjust(CouplesPositionController.AdjustAngle, -15) end)
	anglePlus.MouseButton1Click:Connect(function() adjust(CouplesPositionController.AdjustAngle, 15) end)
	selfMinus.MouseButton1Click:Connect(function() adjust(CouplesPositionController.AdjustSelfAngle, -15) end)
	selfPlus.MouseButton1Click:Connect(function() adjust(CouplesPositionController.AdjustSelfAngle, 15) end)
	savedButton.MouseButton1Click:Connect(function() local loops=Settings.coupleLoops or {}; if #loops==0 then selectedLoop=nil; savedButton.Text=isES and "No hay bucles guardados" or "No saved loops" else selectedLoop=(selectedLoop or 0)%#loops+1; local v=loops[selectedLoop]; savedButton.Text=v.name.."  "..v.start.."–"..v.finish.."s" end end)
	savePoseButton.MouseButton1Click:Connect(function() local ok=CoupleMovementController:SavePose(selectedLoop); UpdateCouplesPanel(ok and (isES and "Pose guardada." or "Pose saved.") or (isES and "Selecciona un bucle guardado." or "Select a saved loop.")) end)
	positionButton.MouseButton1Click:Connect(function()
		local _, message
		if CouplesPositionController:IsMaintaining() then
			_, message = CouplesPositionController:Release()
		else
			_, message = CouplesPositionController:Position()
		end
		UpdateCouplesPanel(message)
	end)
	resetButton.MouseButton1Click:Connect(function()
		CouplesPositionController:Reset()
		UpdateCouplesPanel(isES and "Valores restablecidos." or "Values reset.")
	end)

	UpdateCouplesPanel()
	return true
end