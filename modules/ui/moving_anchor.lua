-- Vista de Ancla con movimiento en la GUI principal.
return function(context)
	setfenv(1,context)
	movingAnchorPanel=Instance.new("Frame")
	movingAnchorPanel.Name="MovingAnchorPanel"
	movingAnchorPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
	movingAnchorPanel.Position=UDim2.new(0,8,0,titleH+8)
	movingAnchorPanel.BackgroundTransparency=1
	movingAnchorPanel.Visible=false
	movingAnchorPanel.ZIndex=6
	movingAnchorPanel.Parent=content
	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,0,0,isMobile and 176 or 190)
	card.BackgroundColor3=currentTheme.secondary
	card.ZIndex=7
	card.Parent=movingAnchorPanel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
	RegisterTheme(card,"BackgroundColor3","secondary")
	local padding=Instance.new("UIPadding")
	padding.PaddingLeft=UDim.new(0,14);padding.PaddingRight=UDim.new(0,14)
	padding.PaddingTop=UDim.new(0,14);padding.Parent=card
	local description=Instance.new("TextLabel")
	description.Size=UDim2.new(1,0,0,46)
	description.BackgroundTransparency=1
	description.Text=isES and "Protege del fling mientras caminas. No ancla físicamente al personaje." or "Protects against fling while walking. It does not physically anchor your character."
	description.TextColor3=currentTheme.textDim
	description.Font=Enum.Font.GothamMedium
	description.TextSize=isMobile and 11 or 13
	description.TextWrapped=true
	description.TextXAlignment=Enum.TextXAlignment.Left
	description.ZIndex=8
	description.Parent=card
	RegisterTheme(description,"TextColor3","textDim")
	local button=Instance.new("TextButton")
	button.Size=UDim2.new(1,0,0,46)
	button.Position=UDim2.new(0,0,0,58)
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
	local status=Instance.new("TextLabel")
	status.Size=UDim2.new(1,0,0,44)
	status.Position=UDim2.new(0,0,0,112)
	status.BackgroundTransparency=1
	status.TextColor3=currentTheme.textDim
	status.Font=Enum.Font.GothamMedium
	status.TextSize=isMobile and 10 or 12
	status.TextWrapped=true
	status.TextXAlignment=Enum.TextXAlignment.Left
	status.ZIndex=8
	status.Parent=card
	RegisterTheme(status,"TextColor3","textDim")
	UpdateMovingAnchorPanel=function(message)
		button.Text=MovingAnchorController.Enabled and (isES and "Desactivar Ancla con movimiento" or "Disable Moving Anchor") or (isES and "Activar Ancla con movimiento" or "Enable Moving Anchor")
		button.BackgroundColor3=MovingAnchorController.Enabled and currentTheme.accent or currentTheme.tertiary
		status.Text=message or (MovingAnchorController.Enabled and (isES and "Protección activa: puedes caminar normalmente." or "Protection active: you can walk normally.") or (isES and "Protección desactivada." or "Protection disabled."))
	end
	button.MouseButton1Click:Connect(function()
		local ok,err=MovingAnchorController:SetEnabled(not MovingAnchorController.Enabled)
		UpdateMovingAnchorPanel(ok and nil or err)
	end)
	UpdateMovingAnchorPanel()
	return true
end