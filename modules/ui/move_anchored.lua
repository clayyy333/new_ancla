-- Vista publica del modo Muévete Anclado.
return function(context)
	setfenv(1,context)
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
	card.Size=UDim2.new(1,0,0,isMobile and 154 or 166)
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
	beta.Text=isES and "Versión beta 1.0 (esta versión puede tener errores)" or "Beta version 1.0 (this version may contain errors)"
	beta.TextColor3=currentTheme.textDim
	beta.Font=Enum.Font.GothamMedium
	beta.TextSize=isMobile and 10 or 12
	beta.TextWrapped=true
	beta.TextXAlignment=Enum.TextXAlignment.Left
	beta.ZIndex=8
	beta.Parent=card
	RegisterTheme(beta,"TextColor3","textDim")

	local toggle=Instance.new("TextButton")
	toggle.Size=UDim2.new(1,0,0,46)
	toggle.Position=UDim2.new(0,0,0,48)
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
	status.Size=UDim2.new(1,0,0,36)
	status.Position=UDim2.new(0,0,0,104)
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
		local running=MobileAnchorCore and MobileAnchorCore:IsRunning()
		toggle.Text=running and (isES and "Desactivar" or "Disable") or (isES and "Activar" or "Enable")
		toggle.BackgroundColor3=running and currentTheme.accent or currentTheme.tertiary
		local automaticBusy=AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)
		toggle.Active=not automaticBusy
		status.Text=message or (running
			and (isES and "Protección activa. Puedes caminar con el ancla." or "Protection active. You can walk while anchored.")
			or (isES and "Protección detenida." or "Protection stopped."))
	end

	toggle.MouseButton1Click:Connect(function()
		if not MobileAnchorCore then return end
		local ok,message=MobileAnchorCore:Toggle()
		UpdateMoveAnchoredPanel(ok and nil or message)
		if UpdateAnchorPanel then UpdateAnchorPanel() end
		if UpdateAutoAnchorPanel then UpdateAutoAnchorPanel() end
	end)
	UpdateMoveAnchoredPanel()
	return true
end