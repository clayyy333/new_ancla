-- Vista de control de vuelo integrada.
return function(context)
	setfenv(1,context)
	flightControlPanel=Instance.new("ScrollingFrame"); flightControlPanel.Size=UDim2.new(1,-16,1,-(titleH+20)); flightControlPanel.Position=UDim2.new(0,8,0,titleH+8); flightControlPanel.BackgroundTransparency=1; flightControlPanel.BorderSizePixel=0; flightControlPanel.ScrollBarThickness=3; flightControlPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y; flightControlPanel.CanvasSize=UDim2.new(); flightControlPanel.Visible=false; flightControlPanel.ZIndex=6; flightControlPanel.Parent=content
	local card=Instance.new("Frame"); card.Size=UDim2.new(1,-4,0,isMobile and 390 or 300); card.BackgroundColor3=currentTheme.secondary; card.ZIndex=7; card.Parent=flightControlPanel; Instance.new("UICorner",card).CornerRadius=UDim.new(0,14); RegisterTheme(card,"BackgroundColor3","secondary")
	local pad=Instance.new("UIPadding",card); pad.PaddingLeft=UDim.new(0,14); pad.PaddingRight=UDim.new(0,14); pad.PaddingTop=UDim.new(0,14); pad.PaddingBottom=UDim.new(0,14)
	local function button(text,y,x,w)
		local b=Instance.new("TextButton"); b.Size=UDim2.new(w or 1,0,0,42); b.Position=UDim2.new(x or 0,0,0,y); b.BackgroundColor3=currentTheme.tertiary; b.Text=text; b.TextColor3=currentTheme.text; b.Font=Enum.Font.GothamBold; b.TextSize=isMobile and 11 or 13; b.AutoButtonColor=false; b.ZIndex=8; b.Parent=card; Instance.new("UICorner",b).CornerRadius=UDim.new(0,10); RegisterTheme(b,"BackgroundColor3","tertiary"); RegisterTheme(b,"TextColor3","text"); return b
	end
	local toggle=button("",0); local soft=button(isES and "Freno suave" or "Soft stop",50,0,0.49); local fast=button(isES and "Freno inmediato" or "Fast stop",50,0.51,0.49)
	local normalMinus=button("-",102,0,0.20); local normalValue=button("",102,0.22,0.56); local normalPlus=button("+",102,0.80,0.20)
	local sprintMinus=button("-",154,0,0.20); local sprintValue=button("",154,0.22,0.56); local sprintPlus=button("+",154,0.80,0.20)
	local sprint=button(isES and "Mantener sprint" or "Hold sprint",206)
	local directionButtons={}
	if isMobile then
		local labels={{"Up","↑",258,0.34},{"Left","←",304,0},{"Forward","▲",304,0.17},{"Backward","▼",304,0.51},{"Right","→",304,0.68},{"Down","↓",258,0.68}}
		for _,v in ipairs(labels) do local b=button(v[2],v[3],v[4],0.15); directionButtons[v[1]]=b; b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then FlightController:SetMobileDirection(v[1],true) end end); b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then FlightController:SetMobileDirection(v[1],false) end end) end
	end
	UpdateFlightControlPanel=function(message)
		toggle.Text=FlightController:IsFlying() and (isES and "Desactivar vuelo" or "Disable flight") or (isES and "Activar vuelo" or "Enable flight")
		toggle.BackgroundColor3=FlightController:IsFlying() and currentTheme.critical or currentTheme.tertiary
		normalValue.Text=(isES and "Velocidad normal: " or "Normal speed: ")..FlightController:GetNormalSpeed()
		sprintValue.Text=(isES and "Velocidad sprint: " or "Sprint speed: ")..FlightController:GetSprintSpeed()
		if message then sprint.Text=message else sprint.Text=isES and "Mantener sprint" or "Hold sprint" end
	end
	toggle.MouseButton1Click:Connect(function() local ok,err; if FlightController:IsFlying() then FlightController:Stop(); ok=true else ok,err=FlightController:Start() end; UpdateFlightControlPanel(ok and nil or err) end)
	soft.MouseButton1Click:Connect(function() FlightController:SoftStop() end); fast.MouseButton1Click:Connect(function() FlightController:FastStop() end)
	normalMinus.MouseButton1Click:Connect(function() FlightController:DecreaseNormalSpeed(); UpdateFlightControlPanel() end); normalPlus.MouseButton1Click:Connect(function() FlightController:IncreaseNormalSpeed(); UpdateFlightControlPanel() end)
	sprintMinus.MouseButton1Click:Connect(function() FlightController:DecreaseSprintSpeed(); UpdateFlightControlPanel() end); sprintPlus.MouseButton1Click:Connect(function() FlightController:IncreaseSprintSpeed(); UpdateFlightControlPanel() end)
	sprint.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then FlightController:SetSprint(true); sprint.BackgroundColor3=currentTheme.accent end end)
	sprint.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then FlightController:SetSprint(false); sprint.BackgroundColor3=currentTheme.tertiary end end)
	UpdateFlightControlPanel(); return true
end