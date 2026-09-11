-- Vista de Ancla automatica integrada.
return function(context)
	setfenv(1,context)
	autoAnchorPanel=Instance.new("Frame")
	autoAnchorPanel.Name="AutoAnchorPanel"
	autoAnchorPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
	autoAnchorPanel.Position=UDim2.new(0,8,0,titleH+8)
	autoAnchorPanel.BackgroundTransparency=1
	autoAnchorPanel.Visible=false
	autoAnchorPanel.ZIndex=6
	autoAnchorPanel.Parent=content
	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,0,0,isMobile and 220 or 238)
	card.BackgroundColor3=currentTheme.secondary
	card.ZIndex=7
	card.Parent=autoAnchorPanel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
	RegisterTheme(card,"BackgroundColor3","secondary")
	local padding=Instance.new("UIPadding")
	padding.PaddingLeft,padding.PaddingRight=UDim.new(0,14),UDim.new(0,14)
	padding.PaddingTop,padding.PaddingBottom=UDim.new(0,14),UDim.new(0,14)
	padding.Parent=card
	local description=Instance.new("TextLabel")
	description.Size=UDim2.new(1,0,0,38)
	description.BackgroundTransparency=1
	description.Text=isES and "Activa las tres protecciones y mantiene automáticamente tu patín." or "Enables all three protections and automatically maintains your skateboard."
	description.TextColor3=currentTheme.textDim
	description.Font=Enum.Font.GothamMedium
	description.TextSize=isMobile and 10 or 12
	description.TextWrapped=true
	description.TextXAlignment=Enum.TextXAlignment.Left
	description.ZIndex=8
	description.Parent=card
	RegisterTheme(description,"TextColor3","textDim")
	local function makeButton(y)
		local button=Instance.new("TextButton")
		button.Size=UDim2.new(1,0,0,46)
		button.Position=UDim2.new(0,0,0,y)
		button.BackgroundColor3=currentTheme.tertiary
		button.TextColor3=currentTheme.text
		button.Font=Enum.Font.GothamBold
		button.TextSize=isMobile and 12 or 14
		button.AutoButtonColor=false
		button.ZIndex=8
		button.Parent=card
		Instance.new("UICorner",button).CornerRadius=UDim.new(0,10)
		RegisterTheme(button,"BackgroundColor3","tertiary")
		RegisterTheme(button,"TextColor3","text")
		return button
	end
	local deltaButton=makeButton(48)
	local xenoButton=makeButton(102)
	local status=Instance.new("TextLabel")
	status.Size=UDim2.new(1,0,0,44)
	status.Position=UDim2.new(0,0,0,158)
	status.BackgroundTransparency=1
	status.TextColor3=currentTheme.textDim
	status.Font=Enum.Font.GothamMedium
	status.TextSize=isMobile and 10 or 12
	status.TextWrapped=true
	status.TextXAlignment=Enum.TextXAlignment.Left
	status.ZIndex=8
	status.Parent=card
	RegisterTheme(status,"TextColor3","textDim")
	UpdateAutoAnchorPanel=function(message)
		local mode=AutoAnchorCore.Mode
		deltaButton.Text=mode=="delta" and (isES and "Desactivar Ancla con asiento Delta" or "Disable Delta Seat Anchor") or (isES and "Activar Ancla con asiento Delta" or "Enable Delta Seat Anchor")
		xenoButton.Text=mode=="xeno" and (isES and "Desactivar Ancla con asiento Xeno" or "Disable Xeno Seat Anchor") or (isES and "Activar Ancla con asiento Xeno" or "Enable Xeno Seat Anchor")
		deltaButton.BackgroundColor3=mode=="delta" and currentTheme.critical or currentTheme.tertiary
		xenoButton.BackgroundColor3=mode=="xeno" and currentTheme.critical or currentTheme.tertiary
		deltaButton.Active=not AutoAnchorCore.Busy
		xenoButton.Active=not AutoAnchorCore.Busy
		local engineStatus=mode=="delta" and AutoSkateDelta.Status or mode=="xeno" and AutoSkateXeno.Status or nil
		status.Text=message or engineStatus or AutoAnchorCore.Status
	end
	local function toggle(mode)
		if AutoAnchorCore.Busy then return end
		task.spawn(function()
			local ok,err=AutoAnchorCore:Toggle(mode)
			UpdateAutoAnchorPanel(ok and nil or err)
			if UpdateAnchorPanel then UpdateAnchorPanel() end
		end)
	end
	deltaButton.MouseButton1Click:Connect(function() toggle("delta") end)
	xenoButton.MouseButton1Click:Connect(function() toggle("xeno") end)
	UpdateAutoAnchorPanel()
	return true
end
