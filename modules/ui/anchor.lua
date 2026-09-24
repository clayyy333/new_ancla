-- Vista Ancla integrada en la GUI principal.
return function(context)
	setfenv(1,context)
	anchorPanel=Instance.new("Frame")
	anchorPanel.Name="AnchorPanel"
	anchorPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
	anchorPanel.Position=UDim2.new(0,8,0,titleH+8)
	anchorPanel.BackgroundTransparency=1
	anchorPanel.Visible=false
	anchorPanel.ZIndex=6
	anchorPanel.Parent=content

	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,0,0,isMobile and 266 or 282)
	card.BackgroundColor3=currentTheme.secondary
	card.ZIndex=7
	card.Parent=anchorPanel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
	RegisterTheme(card,"BackgroundColor3","secondary")
	local padding=Instance.new("UIPadding")
	padding.PaddingLeft,padding.PaddingRight=UDim.new(0,14),UDim.new(0,14)
	padding.PaddingTop,padding.PaddingBottom=UDim.new(0,14),UDim.new(0,14)
	padding.Parent=card

	local description=Instance.new("TextLabel")
	description.Size=UDim2.new(1,0,0,30)
	description.BackgroundTransparency=1
	description.Text=isES and "Controles de estabilidad del personaje" or "Character stability controls"
	description.TextColor3=currentTheme.textDim
	description.Font=Enum.Font.GothamMedium
	description.TextSize=isMobile and 11 or 13
	description.TextXAlignment=Enum.TextXAlignment.Left
	description.ZIndex=8
	description.Parent=card
	RegisterTheme(description,"TextColor3","textDim")

	local function makeButton(y)
		local button=Instance.new("TextButton")
		button.Size=UDim2.new(1,0,0,44)
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
	local anchorButton=makeButton(38)
	local antiSeatButton=makeButton(90)
	local heartbeatButton=makeButton(142)
	local testButton=makeButton(194)

	UpdateAnchorPanel=function(message)
		anchorButton.Text=AnchorCore.AnclaEnabled and (isES and "Desactivar Ancla" or "Disable Anchor") or (isES and "Activar Ancla" or "Enable Anchor")
		antiSeatButton.Text=AnchorCore.AntiSeatEnabled and (isES and "Desactivar AntiSeat" or "Disable AntiSeat") or (isES and "Activar AntiSeat" or "Enable AntiSeat")
		heartbeatButton.Text=AnchorCore.HeartbeatEnabled and (isES and "Desactivar Heartbeat" or "Disable Heartbeat") or (isES and "Activar Heartbeat" or "Enable Heartbeat")
		testButton.Text=AnchorCore.TestEnabled and (isES and "Desactivar Ancla test" or "Disable Test Anchor") or (isES and "Activar Ancla test" or "Enable Test Anchor")
		anchorButton.BackgroundColor3=AnchorCore.AnclaEnabled and currentTheme.accent or currentTheme.tertiary
		antiSeatButton.BackgroundColor3=AnchorCore.AntiSeatEnabled and currentTheme.accent or currentTheme.tertiary
		heartbeatButton.BackgroundColor3=AnchorCore.HeartbeatEnabled and currentTheme.accent or currentTheme.tertiary
		testButton.BackgroundColor3=AnchorCore.TestEnabled and currentTheme.accent or currentTheme.tertiary
		local automaticBusy=AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)
		local manualEnabled=not automaticBusy and not AnchorCore.TestEnabled
		anchorButton.Active=manualEnabled
		antiSeatButton.Active=manualEnabled
		heartbeatButton.Active=manualEnabled
		testButton.Active=not automaticBusy
		description.Text=message or (AnchorCore.TestEnabled
			and (isES and "Ancla test reforzada activa" or "Reinforced Test Anchor active")
			or (AnchorCore.HeartbeatEnabled and not AnchorCore.AnclaEnabled
			and (isES and "Heartbeat está preparado; se aplicará al activar Ancla." or "Heartbeat is ready; it applies when Anchor is enabled.")
			or (isES and "Controles de estabilidad del personaje" or "Character stability controls")))
	end
	anchorButton.MouseButton1Click:Connect(function()
		if AnchorCore.TestEnabled then return end
		local ok,err=AnchorCore:ToggleAncla()
		UpdateAnchorPanel(ok and nil or err)
	end)
	antiSeatButton.MouseButton1Click:Connect(function()
		if AnchorCore.TestEnabled then return end
		AnchorCore:ToggleAntiSeat()
		UpdateAnchorPanel()
	end)
	heartbeatButton.MouseButton1Click:Connect(function()
		if AnchorCore.TestEnabled then return end
		AnchorCore:ToggleHeartbeat()
		UpdateAnchorPanel()
	end)
	testButton.MouseButton1Click:Connect(function()
		local ok,err=AnchorCore:ToggleTest()
		UpdateAnchorPanel(ok and nil or err)
	end)
	UpdateAnchorPanel()
	return true
end
