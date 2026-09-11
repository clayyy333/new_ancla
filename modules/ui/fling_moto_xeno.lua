-- Vista de Fling con moto Xeno integrada en la GUI principal.
return function(context)
	setfenv(1,context)
	motoFlingXenoPanel=Instance.new("Frame")
	motoFlingXenoPanel.Name="MotoFlingXenoPanel"
	motoFlingXenoPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
	motoFlingXenoPanel.Position=UDim2.new(0,8,0,titleH+8)
	motoFlingXenoPanel.BackgroundTransparency=1
	motoFlingXenoPanel.Visible=false
	motoFlingXenoPanel.ZIndex=6
	motoFlingXenoPanel.Parent=content

	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,0,0,isMobile and 282 or 302)
	card.BackgroundColor3=currentTheme.secondary
	card.ZIndex=7
	card.Parent=motoFlingXenoPanel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
	RegisterTheme(card,"BackgroundColor3","secondary")
	local padding=Instance.new("UIPadding")
	padding.PaddingLeft,padding.PaddingRight=UDim.new(0,14),UDim.new(0,14)
	padding.PaddingTop,padding.PaddingBottom=UDim.new(0,14),UDim.new(0,14)
	padding.Parent=card

	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,0,0,20)
	label.BackgroundTransparency=1
	label.Text=L.flingTarget
	label.TextColor3=currentTheme.textDim
	label.Font=Enum.Font.GothamMedium
	label.TextSize=isMobile and 12 or 13
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.ZIndex=8
	label.Parent=card
	RegisterTheme(label,"TextColor3","textDim")

	local targetButton=Instance.new("TextButton")
	targetButton.Size=UDim2.new(1,0,0,40)
	targetButton.Position=UDim2.new(0,0,0,26)
	targetButton.BackgroundColor3=currentTheme.tertiary
	targetButton.TextColor3=currentTheme.text
	targetButton.Font=Enum.Font.GothamMedium
	targetButton.TextSize=isMobile and 12 or 14
	targetButton.TextXAlignment=Enum.TextXAlignment.Left
	targetButton.AutoButtonColor=false
	targetButton.ZIndex=10
	targetButton.Parent=card
	Instance.new("UICorner",targetButton).CornerRadius=UDim.new(0,10)
	Instance.new("UIPadding",targetButton).PaddingLeft=UDim.new(0,12)
	RegisterTheme(targetButton,"BackgroundColor3","tertiary")
	RegisterTheme(targetButton,"TextColor3","text")

	local targetList=Instance.new("ScrollingFrame")
	targetList.Size=UDim2.new(1,0,0,120)
	targetList.Position=UDim2.new(0,0,0,70)
	targetList.BackgroundColor3=currentTheme.tertiary
	targetList.ScrollBarThickness=4
	targetList.AutomaticCanvasSize=Enum.AutomaticSize.Y
	targetList.CanvasSize=UDim2.new()
	targetList.Visible=false
	targetList.ZIndex=30
	targetList.Parent=card
	Instance.new("UICorner",targetList).CornerRadius=UDim.new(0,10)
	RegisterTheme(targetList,"BackgroundColor3","tertiary")
	Instance.new("UIListLayout",targetList).Padding=UDim.new(0,3)

	local function makeAction(y,text)
		local button=Instance.new("TextButton")
		button.Size=UDim2.new(1,0,0,44)
		button.Position=UDim2.new(0,0,0,y)
		button.BackgroundColor3=currentTheme.tertiary
		button.Text=text
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
	local normalButton=makeAction(82,isES and "Activar Fling con moto Xeno" or "Enable Xeno Motorcycle Fling")
	local efficientButton=makeAction(134,isES and "Activar Fling con moto Xeno eficiente" or "Enable Efficient Xeno Motorcycle Fling")
	local status=Instance.new("TextLabel")
	status.Size=UDim2.new(1,0,0,54)
	status.Position=UDim2.new(0,0,0,190)
	status.BackgroundTransparency=1
	status.TextColor3=currentTheme.textDim
	status.Font=Enum.Font.GothamMedium
	status.TextSize=isMobile and 11 or 12
	status.TextWrapped=true
	status.TextXAlignment=Enum.TextXAlignment.Left
	status.ZIndex=8
	status.Parent=card
	RegisterTheme(status,"TextColor3","textDim")

	UpdateMotoFlingXenoPanel=function(message)
		local target=MotoFlingXenoCore:GetTarget()
		targetButton.Text=target and (target.DisplayName.."  (@"..target.Name..")") or L.selectPlayer
		local mode=MotoFlingXenoCore.RunningMode
		normalButton.Text=mode=="normal" and (isES and "Desactivar Fling con moto Xeno" or "Disable Xeno Motorcycle Fling") or (isES and "Activar Fling con moto Xeno" or "Enable Xeno Motorcycle Fling")
		efficientButton.Text=mode=="efficient" and (isES and "Desactivar Fling con moto Xeno eficiente" or "Disable Efficient Xeno Motorcycle Fling") or (isES and "Activar Fling con moto Xeno eficiente" or "Enable Efficient Xeno Motorcycle Fling")
		normalButton.BackgroundColor3=mode=="normal" and currentTheme.critical or currentTheme.tertiary
		efficientButton.BackgroundColor3=mode=="efficient" and currentTheme.critical or currentTheme.tertiary
		normalButton.Active=not MotoFlingXenoCore.Busy
		efficientButton.Active=not MotoFlingXenoCore.Busy
		status.Text=message or MotoFlingXenoCore:GetStatus()
	end
	local function refreshTargets()
		for _,child in ipairs(targetList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
		for _,target in ipairs(MotoFlingXenoCore:GetTargetOptions()) do
			local option=Instance.new("TextButton")
			option.Size=UDim2.new(1,-4,0,34)
			option.BackgroundColor3=currentTheme.secondary
			option.Text=target.DisplayName.."  (@"..target.Name..")"
			option.TextColor3=currentTheme.text
			option.Font=Enum.Font.GothamMedium
			option.TextSize=isMobile and 11 or 12
			option.ZIndex=31
			option.Parent=targetList
			Instance.new("UICorner",option).CornerRadius=UDim.new(0,8)
			RegisterTheme(option,"BackgroundColor3","secondary")
			RegisterTheme(option,"TextColor3","text")
			option.MouseButton1Click:Connect(function()
				MotoFlingXenoCore:SetTarget(target)
				targetList.Visible=false
				UpdateMotoFlingXenoPanel()
			end)
		end
	end
	targetButton.MouseButton1Click:Connect(function()
		if MotoFlingXenoCore.Busy then return end
		targetList.Visible=not targetList.Visible
		if targetList.Visible then refreshTargets() end
	end)
	local function toggle(mode)
		if MotoFlingXenoCore.RunningMode==mode then
			task.spawn(function() MotoFlingXenoCore:Stop(); UpdateMotoFlingXenoPanel() end)
			return
		end
		if MotoFlingXenoCore:IsRunning() then
			UpdateMotoFlingXenoPanel(isES and "Desactiva primero el otro modo." or "Disable the other mode first.")
			return
		end
		if not MotoFlingXenoCore:GetTarget() then UpdateMotoFlingXenoPanel(L.selectPlayerFirst); return end
		task.spawn(function()
			local ok,err=MotoFlingXenoCore:Start(mode)
			UpdateMotoFlingXenoPanel(ok and nil or (err or L.flingStartFailed))
		end)
	end
	normalButton.MouseButton1Click:Connect(function() toggle("normal") end)
	efficientButton.MouseButton1Click:Connect(function() toggle("efficient") end)
	UpdateMotoFlingXenoPanel()
	return true
end
