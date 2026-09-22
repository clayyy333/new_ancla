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
	panelCard.Size = UDim2.new(1, 0, 0, 350)
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

	local function MakeButton(y, text, height)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, height or 44)
		button.Position = UDim2.new(0, 0, 0, y)
		button.BackgroundColor3 = currentTheme.tertiary
		button.Text = text
		button.TextColor3 = currentTheme.text
		button.Font = Enum.Font.GothamBold
		button.TextSize = isMobile and 12 or 14
		button.AutoButtonColor = false
		button.ZIndex = 8
		button.Parent = panelCard
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
		RegisterTheme(button, "BackgroundColor3", "tertiary")
		RegisterTheme(button, "TextColor3", "text")
		return button
	end

	local manualModeButton = MakeButton(0, isES and "Jugador objetivo" or "Target player", 38)
	manualModeButton.Size = UDim2.new(0.5, -4, 0, 38)
	local autoModeButton = MakeButton(0, isES and "Fling sin objetivo" or "No-target Fling", 38)
	autoModeButton.Size = UDim2.new(0.5, -4, 0, 38)
	autoModeButton.Position = UDim2.new(0.5, 4, 0, 0)

	local targetLabel = Instance.new("TextLabel")
	targetLabel.Size = UDim2.new(1, 0, 0, 20)
	targetLabel.Position = UDim2.new(0, 0, 0, 48)
	targetLabel.BackgroundTransparency = 1
	targetLabel.Text = L.flingTarget
	targetLabel.TextColor3 = currentTheme.textDim
	targetLabel.Font = Enum.Font.GothamMedium
	targetLabel.TextSize = isMobile and 11 or 13
	targetLabel.TextXAlignment = Enum.TextXAlignment.Left
	targetLabel.ZIndex = 8
	targetLabel.Parent = panelCard
	RegisterTheme(targetLabel, "TextColor3", "textDim")

	local targetButton = MakeButton(72, L.selectPlayer, 40)
	targetButton.Font = Enum.Font.GothamMedium
	targetButton.TextXAlignment = Enum.TextXAlignment.Left
	Instance.new("UIPadding", targetButton).PaddingLeft = UDim.new(0, 12)

	local targetList = Instance.new("ScrollingFrame")
	targetList.Size = UDim2.new(1, 0, 0, 120)
	targetList.Position = UDim2.new(0, 0, 0, 116)
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

	local efficientButton = MakeButton(124, isES and "Activar Fling 2 eficiente" or "Enable Efficient Fling 2")
	local flingButton = MakeButton(176, isES and "Activar Fling 2" or "Enable Fling 2")

	local restartWarning = Instance.new("TextLabel")
	restartWarning.Size = UDim2.new(1, 0, 0, 18)
	restartWarning.Position = UDim2.new(0, 0, 0, 222)
	restartWarning.BackgroundTransparency = 1
	restartWarning.Text = isES and "Este Fling te reinicia, usa el eficiente" or "This Fling resets you; use the efficient one"
	restartWarning.TextColor3 = currentTheme.textDim
	restartWarning.Font = Enum.Font.GothamMedium
	restartWarning.TextSize = isMobile and 9 or 10
	restartWarning.TextXAlignment = Enum.TextXAlignment.Left
	restartWarning.ZIndex = 8
	restartWarning.Parent = panelCard
	RegisterTheme(restartWarning, "TextColor3", "textDim")

	local forceReturnButton = MakeButton(246, isES and "Forzar regreso" or "Force return")
	local lastStartedCore = Fling2Core

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0, 42)
	statusLabel.Position = UDim2.new(0, 0, 0, 296)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = currentTheme.textDim
	statusLabel.Font = Enum.Font.GothamMedium
	statusLabel.TextSize = isMobile and 10 or 12
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.ZIndex = 8
	statusLabel.Parent = panelCard
	RegisterTheme(statusLabel, "TextColor3", "textDim")

	local autoDescription = Instance.new("TextLabel")
	autoDescription.Size = UDim2.new(1, 0, 0, 40)
	autoDescription.Position = UDim2.new(0, 0, 0, 52)
	autoDescription.BackgroundTransparency = 1
	autoDescription.Text = isES and "Recorre continuamente a todos los jugadores válidos, cambiando de objetivo cada 3 segundos." or "Continuously cycles through valid players, changing target every 3 seconds."
	autoDescription.TextColor3 = currentTheme.textDim
	autoDescription.Font = Enum.Font.GothamMedium
	autoDescription.TextSize = isMobile and 10 or 12
	autoDescription.TextWrapped = true
	autoDescription.TextXAlignment = Enum.TextXAlignment.Left
	autoDescription.ZIndex = 8
	autoDescription.Parent = panelCard
	RegisterTheme(autoDescription, "TextColor3", "textDim")

	local autoToggleButton = MakeButton(102, isES and "Activar Fling automático" or "Enable automatic Fling")
	local autoForceReturnButton = MakeButton(154, isES and "Forzar regreso" or "Force return")
	local autoStatusLabel = statusLabel:Clone()
	autoStatusLabel.Position = UDim2.new(0, 0, 0, 208)
	autoStatusLabel.Parent = panelCard
	RegisterTheme(autoStatusLabel, "TextColor3", "textDim")

	local manualObjects={targetLabel,targetButton,targetList,efficientButton,flingButton,restartWarning,forceReturnButton,statusLabel}
	local autoObjects={autoDescription,autoToggleButton,autoForceReturnButton,autoStatusLabel}
	local mode="manual"

	local function SetMode(nextMode)
		if mode==nextMode then return end
		if nextMode=="manual" then
			if Fling2AutoController.Running then Fling2AutoController:Stop() end
			Fling2EfficientCore:SetTarget(Fling2Core:GetTarget())
		else
			if Fling2Core.Running then Fling2Core:Stop() end
			if Fling2EfficientCore.Running then Fling2EfficientCore:Stop() end
		end
		mode=nextMode
		targetList.Visible=false
		for _,object in ipairs(manualObjects) do object.Visible=mode=="manual" end
		for _,object in ipairs(autoObjects) do object.Visible=mode=="auto" end
		manualModeButton.BackgroundColor3=mode=="manual" and currentTheme.accent or currentTheme.tertiary
		autoModeButton.BackgroundColor3=mode=="auto" and currentTheme.accent or currentTheme.tertiary
	end

	UpdateFling2Panel = function(message)
		local target = Fling2Core:GetTarget()
		targetButton.Text = target and (target.DisplayName .. "  (@" .. target.Name .. ")") or L.selectPlayer
		flingButton.Text = Fling2Core.Running and (isES and "Desactivar Fling 2" or "Disable Fling 2") or (isES and "Activar Fling 2" or "Enable Fling 2")
		efficientButton.Text = (Fling2EfficientCore.Running and not Fling2AutoController.Running) and (isES and "Desactivar Fling 2 eficiente" or "Disable Efficient Fling 2") or (isES and "Activar Fling 2 eficiente" or "Enable Efficient Fling 2")
		flingButton.BackgroundColor3 = Fling2Core.Running and currentTheme.critical or currentTheme.tertiary
		efficientButton.BackgroundColor3 = (Fling2EfficientCore.Running and not Fling2AutoController.Running) and currentTheme.accent or currentTheme.tertiary
		statusLabel.Text = mode=="manual" and (message or ((Fling2Core.Running or (Fling2EfficientCore.Running and not Fling2AutoController.Running)) and L.flingActive or L.flingStopped)) or statusLabel.Text

		autoToggleButton.Text=Fling2AutoController.Running and (isES and "Desactivar Fling automático" or "Disable automatic Fling") or (isES and "Activar Fling automático" or "Enable automatic Fling")
		autoToggleButton.BackgroundColor3=Fling2AutoController.Running and currentTheme.critical or currentTheme.tertiary
		if mode=="auto" then
			local autoTarget=Fling2AutoController.CurrentTarget
			autoStatusLabel.Text=message or (autoTarget and ((isES and "Objetivo actual: " or "Current target: ")..autoTarget.DisplayName) or (isES and "Fling automático detenido" or "Automatic Fling stopped"))
		end
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
			option.Activated:Connect(function()
				Fling2Core:SetTarget(targetPlayer)
				Fling2EfficientCore:SetTarget(targetPlayer)
				targetList.Visible = false
				UpdateFling2Panel()
			end)
		end
	end

	manualModeButton.Activated:Connect(function() SetMode("manual");UpdateFling2Panel() end)
	autoModeButton.Activated:Connect(function() SetMode("auto");UpdateFling2Panel() end)
	targetButton.Activated:Connect(function()
		targetList.Visible = not targetList.Visible
		if targetList.Visible then RefreshTargets() end
	end)

	flingButton.Activated:Connect(function()
		if Fling2Core.Running then
			Fling2Core:Stop()
			UpdateFling2Panel()
			return
		end
		if not Fling2Core:GetTarget() then UpdateFling2Panel(L.selectPlayerFirst);return end
		local ok, err = Fling2Core:Start()
		if ok then lastStartedCore = Fling2Core end
		UpdateFling2Panel(ok and nil or (err or L.flingStartFailed))
	end)

	efficientButton.Activated:Connect(function()
		if Fling2EfficientCore.Running and not Fling2AutoController.Running then
			Fling2EfficientCore:Stop()
		else
			if not Fling2EfficientCore:GetTarget() then UpdateFling2Panel(L.selectPlayerFirst); return end
			local ok, err = Fling2EfficientCore:Start()
			if not ok then UpdateFling2Panel(err or L.flingStartFailed); return end
			lastStartedCore = Fling2EfficientCore
		end
		UpdateFling2Panel()
	end)

	forceReturnButton.Activated:Connect(function()
		if Fling2Core.Running or Fling2EfficientCore.Running or Fling2AutoController.Running then
			UpdateFling2Panel(isES and "Desactiva el fling antes de forzar el regreso." or "Disable the fling before forcing the return.")
			return
		end
		local ok, err = lastStartedCore:ForceReturn()
		UpdateFling2Panel(ok and (isES and "Regreso forzado al checkpoint." or "Returned to checkpoint.") or err)
	end)

	autoToggleButton.Activated:Connect(function()
		if Fling2AutoController.Running then
			Fling2AutoController:Stop()
			UpdateFling2Panel()
			return
		end
		local ok,err=Fling2AutoController:Start()
		if ok then lastStartedCore=Fling2EfficientCore end
		UpdateFling2Panel(ok and nil or err)
	end)

	autoForceReturnButton.Activated:Connect(function()
		local ok,err=Fling2AutoController:ForceReturn()
		UpdateFling2Panel(ok and (isES and "Regreso forzado al checkpoint." or "Returned to checkpoint.") or err)
	end)

	for _,object in ipairs(autoObjects) do object.Visible=false end
	manualModeButton.BackgroundColor3=currentTheme.accent
	UpdateFling2Panel()
	return true
end