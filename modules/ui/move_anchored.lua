-- Vista publica y selector de versiones de Muévete Anclado.
return function(context)
	setfenv(1,context)
	local selectedVersion="1.0"

	moveAnchoredPanel=Instance.new("ScrollingFrame")
	moveAnchoredPanel.Name="MoveAnchoredPanel"
	moveAnchoredPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
	moveAnchoredPanel.Position=UDim2.new(0,8,0,titleH+8)
	moveAnchoredPanel.BackgroundTransparency=1
	moveAnchoredPanel.BorderSizePixel=0
	moveAnchoredPanel.ScrollBarThickness=3
	moveAnchoredPanel.ScrollingDirection=Enum.ScrollingDirection.Y
	moveAnchoredPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y
	moveAnchoredPanel.CanvasSize=UDim2.new()
	moveAnchoredPanel.Active=true
	moveAnchoredPanel.Visible=false
	moveAnchoredPanel.ZIndex=6
	moveAnchoredPanel.Parent=content

	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,0,0,isMobile and 210 or 222)
	card.BackgroundColor3=currentTheme.secondary
	card.ZIndex=7
	card.Parent=moveAnchoredPanel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
	RegisterTheme(card,"BackgroundColor3","secondary")
	local padding=Instance.new("UIPadding")
	padding.PaddingLeft,padding.PaddingRight=UDim.new(0,14),UDim.new(0,14)
	padding.PaddingTop,padding.PaddingBottom=UDim.new(0,14),UDim.new(0,14)
	padding.Parent=card

	local beta=Instance.new("TextLabel")
	beta.Size=UDim2.new(1,0,0,38)
	beta.BackgroundTransparency=1
	beta.TextColor3=currentTheme.textDim
	beta.Font=Enum.Font.GothamMedium
	beta.TextSize=isMobile and 10 or 12
	beta.TextWrapped=true
	beta.TextXAlignment=Enum.TextXAlignment.Left
	beta.ZIndex=8
	beta.Parent=card
	RegisterTheme(beta,"TextColor3","textDim")

	local versionButton=Instance.new("TextButton")
	versionButton.Size=UDim2.new(1,0,0,38)
	versionButton.Position=UDim2.new(0,0,0,46)
	versionButton.BackgroundColor3=currentTheme.tertiary
	versionButton.TextColor3=currentTheme.text
	versionButton.TextXAlignment=Enum.TextXAlignment.Left
	versionButton.Font=Enum.Font.GothamSemibold
	versionButton.TextSize=isMobile and 11 or 13
	versionButton.AutoButtonColor=false
	versionButton.ZIndex=8
	versionButton.Parent=card
	Instance.new("UICorner",versionButton).CornerRadius=UDim.new(0,10)
	RegisterTheme(versionButton,"TextColor3","text")
	local versionPadding=Instance.new("UIPadding")
	versionPadding.PaddingLeft=UDim.new(0,12)
	versionPadding.PaddingRight=UDim.new(0,38)
	versionPadding.Parent=versionButton
	local versionArrow=Instance.new("TextLabel")
	versionArrow.Size=UDim2.new(0,28,1,0)
	versionArrow.Position=UDim2.new(1,-32,0,0)
	versionArrow.BackgroundTransparency=1
	versionArrow.TextColor3=currentTheme.textDim
	versionArrow.Font=Enum.Font.GothamBold
	versionArrow.TextSize=isMobile and 11 or 13
	versionArrow.ZIndex=9
	versionArrow.Parent=versionButton
	RegisterTheme(versionArrow,"TextColor3","textDim")

	local dismissOverlay=Instance.new("TextButton")
	dismissOverlay.Name="VersionDropdownDismiss"
	dismissOverlay.Size=UDim2.new(1,0,1,0)
	dismissOverlay.Position=UDim2.new(0,0,0,0)
	dismissOverlay.BackgroundTransparency=1
	dismissOverlay.Text=""
	dismissOverlay.AutoButtonColor=false
	dismissOverlay.Visible=false
	dismissOverlay.ZIndex=18
	dismissOverlay.Parent=content

	local versionDropdown=Instance.new("Frame")
	versionDropdown.Name="VersionDropdown"
	versionDropdown.Size=UDim2.new(1,0,0,82)
	versionDropdown.Position=UDim2.new(0,0,0,88)
	versionDropdown.BackgroundColor3=currentTheme.tertiary
	versionDropdown.BorderSizePixel=0
	versionDropdown.Visible=false
	versionDropdown.ZIndex=20
	versionDropdown.Parent=card
	Instance.new("UICorner",versionDropdown).CornerRadius=UDim.new(0,10)
	local dropdownStroke=Instance.new("UIStroke")
	dropdownStroke.Color=currentTheme.accent
	dropdownStroke.Thickness=1
	dropdownStroke.Transparency=.35
	dropdownStroke.Parent=versionDropdown
	RegisterTheme(versionDropdown,"BackgroundColor3","tertiary")
	RegisterTheme(dropdownStroke,"Color","accent")
	local dropdownPadding=Instance.new("UIPadding")
	dropdownPadding.PaddingTop=UDim.new(0,4)
	dropdownPadding.PaddingBottom=UDim.new(0,4)
	dropdownPadding.PaddingLeft=UDim.new(0,4)
	dropdownPadding.PaddingRight=UDim.new(0,4)
	dropdownPadding.Parent=versionDropdown
	local dropdownLayout=Instance.new("UIListLayout")
	dropdownLayout.Padding=UDim.new(0,4)
	dropdownLayout.SortOrder=Enum.SortOrder.LayoutOrder
	dropdownLayout.Parent=versionDropdown
	local versionOptions={}
	for index,version in ipairs({"1.0","1.1"}) do
		local option=Instance.new("TextButton")
		option.Name="Version"..version
		option.Size=UDim2.new(1,0,0,35)
		option.BackgroundColor3=currentTheme.secondary
		option.TextColor3=currentTheme.text
		option.TextXAlignment=Enum.TextXAlignment.Left
		option.Font=Enum.Font.GothamMedium
		option.TextSize=isMobile and 11 or 13
		option.AutoButtonColor=false
		option.ZIndex=21
		option.LayoutOrder=index
		option.Parent=versionDropdown
		Instance.new("UICorner",option).CornerRadius=UDim.new(0,8)
		local optionPadding=Instance.new("UIPadding")
		optionPadding.PaddingLeft=UDim.new(0,12)
		optionPadding.PaddingRight=UDim.new(0,12)
		optionPadding.Parent=option
		RegisterTheme(option,"TextColor3","text")
		versionOptions[version]=option
	end
	local dropdownOpen=false
	local function SetVersionDropdown(open)
		dropdownOpen=open==true
		versionDropdown.Visible=dropdownOpen
		dismissOverlay.Visible=dropdownOpen
	end

	local toggle=Instance.new("TextButton")
	toggle.Size=UDim2.new(1,0,0,46)
	toggle.Position=UDim2.new(0,0,0,94)
	toggle.BackgroundColor3=currentTheme.tertiary
	toggle.TextColor3=currentTheme.text
	toggle.Font=Enum.Font.GothamBold
	toggle.TextSize=isMobile and 12 or 14
	toggle.AutoButtonColor=false
	toggle.ZIndex=8
	toggle.Parent=card
	Instance.new("UICorner",toggle).CornerRadius=UDim.new(0,10)
	RegisterTheme(toggle,"TextColor3","text")

	local status=Instance.new("TextLabel")
	status.Size=UDim2.new(1,0,0,42)
	status.Position=UDim2.new(0,0,0,150)
	status.BackgroundTransparency=1
	status.TextColor3=currentTheme.textDim
	status.Font=Enum.Font.GothamMedium
	status.TextSize=isMobile and 9 or 11
	status.TextWrapped=true
	status.TextXAlignment=Enum.TextXAlignment.Left
	status.ZIndex=8
	status.Parent=card
	RegisterTheme(status,"TextColor3","textDim")

	UpdateMoveAnchoredPanel=function(message)
		local running10=MobileAnchorCore and MobileAnchorCore:IsRunning()
		local running11=MobileAnchorV11Core and MobileAnchorV11Core:IsRunning()
		local running=running10 or running11
		local activeVersion=running11 and "1.1" or (running10 and "1.0" or nil)
		beta.Text=selectedVersion=="1.1"
			and (isES and "Versión beta 1.1 (esta versión puede tener errores)" or "Beta version 1.1 (this version may contain errors)")
			or (isES and "Versión beta 1.0 (esta versión puede tener errores)" or "Beta version 1.0 (this version may contain errors)")
		versionButton.Text=(isES and "Versión seleccionada: " or "Selected version: ")..selectedVersion
		versionArrow.Text=dropdownOpen and "▲" or "▼"
		versionButton.Active=not running
		versionButton.BackgroundColor3=running and currentTheme.secondary or currentTheme.tertiary
		if running and dropdownOpen then SetVersionDropdown(false) end
		for version,option in pairs(versionOptions) do
			local selected=version==selectedVersion
			option.Text=(selected and "✓  " or "     ")..(isES and "Versión " or "Version ")..version
			option.BackgroundColor3=selected and currentTheme.accent or currentTheme.secondary
		end
		toggle.Text=running and (isES and "Desactivar v"..activeVersion or "Disable v"..activeVersion) or (isES and "Activar" or "Enable")
		toggle.BackgroundColor3=running and currentTheme.accent or currentTheme.tertiary
		local automaticBusy=AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)
		toggle.Active=not automaticBusy
		status.Text=message or (running
			and (isES and "Protección v"..activeVersion.." activa. Puedes caminar con el ancla." or "Protection v"..activeVersion.." active. You can walk while anchored.")
			or (isES and "Protección detenida." or "Protection stopped."))
	end

	versionButton.Activated:Connect(function()
		local running10=MobileAnchorCore and MobileAnchorCore:IsRunning()
		local running11=MobileAnchorV11Core and MobileAnchorV11Core:IsRunning()
		if running10 or running11 then return end
		SetVersionDropdown(not dropdownOpen)
		UpdateMoveAnchoredPanel()
	end)
	dismissOverlay.Activated:Connect(function()
		SetVersionDropdown(false)
		UpdateMoveAnchoredPanel()
	end)
	for version,option in pairs(versionOptions) do
		option.Activated:Connect(function()
			selectedVersion=version
			SetVersionDropdown(false)
			UpdateMoveAnchoredPanel()
		end)
	end

	toggle.MouseButton1Click:Connect(function()
		local core10=MobileAnchorCore
		local core11=MobileAnchorV11Core
		local ok,message
		if core10 and core10:IsRunning() then
			ok,message=core10:Stop()
		elseif core11 and core11:IsRunning() then
			ok,message=core11:Stop()
		else
			local selectedCore=selectedVersion=="1.1" and core11 or core10
			if not selectedCore then return end
			ok,message=selectedCore:Start()
		end
		UpdateMoveAnchoredPanel(ok and nil or message)
		if UpdateAnchorPanel then UpdateAnchorPanel() end
		if UpdateAutoAnchorPanel then UpdateAutoAnchorPanel() end
	end)
	UpdateMoveAnchoredPanel()
	return true
end