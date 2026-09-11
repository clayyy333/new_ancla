-- Vista de Fling 2 integrada en la GUI principal.
return function(context)
	setfenv(1, context)

	fling2Panel = Instance.new("Frame")
	fling2Panel.Name = "Fling2Panel"
	fling2Panel.Size = UDim2.new(1, -16, 1, -(titleH + 20))
	fling2Panel.Position = UDim2.new(0, 8, 0, titleH + 8)
	fling2Panel.BackgroundTransparency = 1
	fling2Panel.Visible = false
	fling2Panel.ZIndex = 6
	fling2Panel.Parent = content

	local panelCard = Instance.new("Frame")
	panelCard.Size = UDim2.new(1, 0, 0, isMobile and 282 or 302)
	panelCard.BackgroundColor3 = currentTheme.secondary
	panelCard.ZIndex = 7
	panelCard.Parent = fling2Panel
	Instance.new("UICorner", panelCard).CornerRadius = UDim.new(0, 14)
	RegisterTheme(panelCard, "BackgroundColor3", "secondary")

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.Parent = panelCard

	local targetLabel = Instance.new("TextLabel")
	targetLabel.Size = UDim2.new(1, 0, 0, 20)
	targetLabel.BackgroundTransparency = 1
	targetLabel.Text = L.flingTarget
	targetLabel.TextColor3 = currentTheme.textDim
	targetLabel.Font = Enum.Font.GothamMedium
	targetLabel.TextSize = isMobile and 12 or 13
	targetLabel.TextXAlignment = Enum.TextXAlignment.Left
	targetLabel.ZIndex = 8
	targetLabel.Parent = panelCard
	RegisterTheme(targetLabel, "TextColor3", "textDim")

	local targetButton = Instance.new("TextButton")
	targetButton.Size = UDim2.new(1, 0, 0, 40)
	targetButton.Position = UDim2.new(0, 0, 0, 26)
	targetButton.BackgroundColor3 = currentTheme.tertiary
	targetButton.Text = L.selectPlayer
	targetButton.TextColor3 = currentTheme.text
	targetButton.Font = Enum.Font.GothamMedium
	targetButton.TextSize = isMobile and 12 or 14
	targetButton.TextXAlignment = Enum.TextXAlignment.Left
	targetButton.AutoButtonColor = false
	targetButton.ZIndex = 10
	targetButton.Parent = panelCard
	Instance.new("UICorner", targetButton).CornerRadius = UDim.new(0, 10)
	Instance.new("UIPadding", targetButton).PaddingLeft = UDim.new(0, 12)
	RegisterTheme(targetButton, "BackgroundColor3", "tertiary")
	RegisterTheme(targetButton, "TextColor3", "text")

	local targetList = Instance.new("ScrollingFrame")
	targetList.Size = UDim2.new(1, 0, 0, 120)
	targetList.Position = UDim2.new(0, 0, 0, 70)
	targetList.BackgroundColor3 = currentTheme.tertiary
	targetList.ScrollBarThickness = 4
	targetList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	targetList.CanvasSize = UDim2.new()
	targetList.Visible = false
	targetList.ZIndex = 30
	targetList.Parent = panelCard
	Instance.new("UICorner", targetList).CornerRadius = UDim.new(0, 10)
	RegisterTheme(targetList, "BackgroundColor3", "tertiary")
	local targetLayout = Instance.new("UIListLayout")
	targetLayout.Padding = UDim.new(0, 3)
	targetLayout.Parent = targetList

	local function MakeActionButton(y, text)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 44)
		button.Position = UDim2.new(0, 0, 0, y)
		button.BackgroundColor3 = currentTheme.tertiary
		button.Text = text
		button.TextColor3 = currentTheme.text
		button.Font = Enum.Font.GothamBold
		button.TextSize = isMobile and 13 or 14
		button.AutoButtonColor = false
		button.ZIndex = 8
		button.Parent = panelCard
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
		RegisterTheme(button, "BackgroundColor3", "tertiary")
		RegisterTheme(button, "TextColor3", "text")
		return button
	end

	local flingButton = MakeActionButton(82, isES and "Activar Fling 2" or "Enable Fling 2")
	local efficientButton = MakeActionButton(134, isES and "Activar Fling 2 eficiente" or "Enable Efficient Fling 2")
	local forceReturnButton = MakeActionButton(186, isES and "Forzar regreso" or "Force return")
	local lastStartedCore = Fling2Core

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0, 24)
	statusLabel.Position = UDim2.new(0, 0, 0, 238)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = currentTheme.textDim
	statusLabel.Font = Enum.Font.GothamMedium
	statusLabel.TextSize = isMobile and 11 or 12
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.ZIndex = 8
	statusLabel.Parent = panelCard
	RegisterTheme(statusLabel, "TextColor3", "textDim")

	UpdateFling2Panel = function(message)
		local target = Fling2Core:GetTarget()
		targetButton.Text = target and (target.DisplayName .. "  (@" .. target.Name .. ")") or L.selectPlayer
		flingButton.Text = Fling2Core.Running and (isES and "Desactivar Fling 2" or "Disable Fling 2") or (isES and "Activar Fling 2" or "Enable Fling 2")
		efficientButton.Text = Fling2EfficientCore.Running and (isES and "Desactivar Fling 2 eficiente" or "Disable Efficient Fling 2") or (isES and "Activar Fling 2 eficiente" or "Enable Efficient Fling 2")
		flingButton.BackgroundColor3 = Fling2Core.Running and currentTheme.critical or currentTheme.tertiary
		efficientButton.BackgroundColor3 = Fling2EfficientCore.Running and currentTheme.accent or currentTheme.tertiary
		statusLabel.Text = message or ((Fling2Core.Running or Fling2EfficientCore.Running) and L.flingActive or L.flingStopped)
	end

	local function RefreshTargets()
		for _, child in ipairs(targetList:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		for _, targetPlayer in ipairs(Fling2Core.Provider:GetTargetOptions()) do
			local option = Instance.new("TextButton")
			option.Size = UDim2.new(1, -4, 0, 34)
			option.BackgroundColor3 = currentTheme.secondary
			option.Text = targetPlayer.DisplayName .. "  (@" .. targetPlayer.Name .. ")"
			option.TextColor3 = currentTheme.text
			option.Font = Enum.Font.GothamMedium
			option.TextSize = isMobile and 11 or 12
			option.ZIndex = 31
			option.Parent = targetList
			Instance.new("UICorner", option).CornerRadius = UDim.new(0, 8)
			RegisterTheme(option, "BackgroundColor3", "secondary")
			RegisterTheme(option, "TextColor3", "text")
			option.MouseButton1Click:Connect(function()
				Fling2Core:SetTarget(targetPlayer)
				Fling2EfficientCore:SetTarget(targetPlayer)
				targetList.Visible = false
				UpdateFling2Panel()
			end)
		end
	end

	targetButton.MouseButton1Click:Connect(function()
		targetList.Visible = not targetList.Visible
		if targetList.Visible then RefreshTargets() end
	end)

	flingButton.MouseButton1Click:Connect(function()
		if Fling2Core.Running then
			Fling2Core:Stop()
			UpdateFling2Panel()
			return
		end
		if not Fling2Core:GetTarget() then
			UpdateFling2Panel(L.selectPlayerFirst)
			return
		end
		local ok, err = Fling2Core:Start()
		if ok then lastStartedCore = Fling2Core end
		UpdateFling2Panel(ok and nil or (err or L.flingStartFailed))
	end)

	efficientButton.MouseButton1Click:Connect(function()
		if Fling2EfficientCore.Running then
			Fling2EfficientCore:Stop()
		else
			if not Fling2EfficientCore:GetTarget() then UpdateFling2Panel(L.selectPlayerFirst); return end
			local ok, err = Fling2EfficientCore:Start()
			if not ok then UpdateFling2Panel(err or L.flingStartFailed); return end
			lastStartedCore = Fling2EfficientCore
		end
		UpdateFling2Panel()
	end)

	forceReturnButton.MouseButton1Click:Connect(function()
		if Fling2Core.Running or Fling2EfficientCore.Running then
			UpdateFling2Panel(isES and "Desactiva el fling antes de forzar el regreso." or "Disable the fling before forcing the return.")
			return
		end
		local ok, err = lastStartedCore:ForceReturn()
		UpdateFling2Panel(ok and (isES and "Regreso forzado al checkpoint." or "Returned to checkpoint.") or err)
	end)

	UpdateFling2Panel()
	return true
end