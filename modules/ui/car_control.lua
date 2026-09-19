-- Vista de control de auto integrada.
return function(context)
	setfenv(1,context)
	carControlPanel=Instance.new("ScrollingFrame"); carControlPanel.Size=UDim2.new(1,-16,1,-(titleH+20)); carControlPanel.Position=UDim2.new(0,8,0,titleH+8); carControlPanel.BackgroundTransparency=1; carControlPanel.BorderSizePixel=0; carControlPanel.ScrollBarThickness=3; carControlPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y; carControlPanel.CanvasSize=UDim2.new(); carControlPanel.Visible=false; carControlPanel.ZIndex=6; carControlPanel.Parent=content
	local card=Instance.new("Frame"); card.Size=UDim2.new(1,-4,0,390); card.BackgroundColor3=currentTheme.secondary; card.ZIndex=7; card.Parent=carControlPanel; Instance.new("UICorner",card).CornerRadius=UDim.new(0,14); RegisterTheme(card,"BackgroundColor3","secondary")
	local pad=Instance.new("UIPadding",card); pad.PaddingLeft=UDim.new(0,14); pad.PaddingRight=UDim.new(0,14); pad.PaddingTop=UDim.new(0,14); pad.PaddingBottom=UDim.new(0,14)
	local function label(text,y)
		local l=Instance.new("TextLabel"); l.Size=UDim2.new(1,0,0,18); l.Position=UDim2.new(0,0,0,y); l.BackgroundTransparency=1; l.Text=text; l.TextColor3=currentTheme.textDim; l.Font=Enum.Font.GothamMedium; l.TextSize=isMobile and 11 or 12; l.TextXAlignment=Enum.TextXAlignment.Left; l.ZIndex=8; l.Parent=card; RegisterTheme(l,"TextColor3","textDim"); return l
	end
	local function button(text,y,x,w,z)
		local b=Instance.new("TextButton"); b.Size=UDim2.new(w or 1,0,0,40); b.Position=UDim2.new(x or 0,0,0,y); b.BackgroundColor3=currentTheme.tertiary; b.Text=text; b.TextColor3=currentTheme.text; b.Font=Enum.Font.GothamBold; b.TextSize=isMobile and 10 or 12; b.AutoButtonColor=false; b.ZIndex=z or 8; b.Parent=card; Instance.new("UICorner",b).CornerRadius=UDim.new(0,10); RegisterTheme(b,"BackgroundColor3","tertiary"); RegisterTheme(b,"TextColor3","text"); return b
	end
	local function selector(text,y)
		local b=button(text,y); b.TextXAlignment=Enum.TextXAlignment.Left; b.Font=Enum.Font.GothamMedium; Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,12); b.ZIndex=10; return b
	end
	local function list(y)
		local f=Instance.new("ScrollingFrame"); f.Size=UDim2.new(1,0,0,110); f.Position=UDim2.new(0,0,0,y); f.BackgroundColor3=currentTheme.tertiary; f.BorderSizePixel=0; f.ScrollBarThickness=4; f.AutomaticCanvasSize=Enum.AutomaticSize.Y; f.CanvasSize=UDim2.new(); f.Visible=false; f.ZIndex=30; f.Parent=card; Instance.new("UICorner",f).CornerRadius=UDim.new(0,10); Instance.new("UIListLayout",f).Padding=UDim.new(0,3); RegisterTheme(f,"BackgroundColor3","tertiary"); return f
	end
	local function option(parent,text,callback)
		local b=button(text,0,0,1,31); b.Parent=parent; b.Size=UDim2.new(1,-4,0,32); b.Position=UDim2.new(); b.MouseButton1Click:Connect(callback)
	end
	label(isES and "Mi vehículo" or "My vehicle",0)
	local carButton=selector(isES and "Seleccionar vehículo" or "Select vehicle",22)
	label(isES and "Jugador objetivo" or "Target player",68)
	local targetButton=selector(isES and "Seleccionar jugador" or "Select player",90)
	local carList,targetList=list(64),list(132)
	label(isES and "Altura sobre el objetivo" or "Height above target",138)
	local heightMinus=button("−",160,0,0.20); local heightValue=button("",160,0.22,0.56); local heightPlus=button("+",160,0.80,0.20)
	label(isES and "Velocidad de giro" or "Spin speed",208)
	local speedMinus=button("−",230,0,0.20); local speedValue=button("",230,0.22,0.56); local speedPlus=button("+",230,0.80,0.20)
	local toggle=button(isES and "Activar control de auto" or "Enable car control",282)
	local status=label("",330); status.Size=UDim2.new(1,0,0,42); status.TextWrapped=true
	local function clearOptions(frame) for _,child in ipairs(frame:GetChildren()) do if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end end end
	UpdateCarControlPanel=function(message)
		local car,target=CarControlController:GetCar(),CarControlController:GetTarget()
		carButton.Text=car and car.Name or (isES and "Seleccionar vehículo" or "Select vehicle")
		targetButton.Text=target and (target.DisplayName.."  (@"..target.Name..")") or (isES and "Seleccionar jugador" or "Select player")
		heightValue.Text=(isES and "Altura: " or "Height: ")..tostring(CarControlController:GetHeight())
		speedValue.Text=(isES and "Giro: " or "Spin: ")..tostring(CarControlController:GetSpinSpeed()).."°/s"
		toggle.Text=CarControlController:IsRunning() and (isES and "Desactivar y regresar vehículo" or "Disable and return vehicle") or (isES and "Activar control de auto" or "Enable car control")
		toggle.BackgroundColor3=CarControlController:IsRunning() and currentTheme.critical or currentTheme.tertiary
		status.Text=message or CarControlController.Status or (isES and "Vehículo fijo sobre el objetivo con estabilización continua." or "Vehicle fixed above target with continuous stabilization.")
	end
	carButton.MouseButton1Click:Connect(function()
		carList.Visible=not carList.Visible; targetList.Visible=false
		if carList.Visible then clearOptions(carList); local cars=CarControlController:GetCarOptions(); if #cars==0 then option(carList,isES and "No se encontraron vehículos propios" or "No owned vehicles found",function() end) else for _,car in ipairs(cars) do option(carList,car.Name,function() if CarControlController:IsRunning() then CarControlController:Stop(true) end; CarControlController:SetCar(car); carList.Visible=false; UpdateCarControlPanel() end) end end end
	end)
	targetButton.MouseButton1Click:Connect(function()
		targetList.Visible=not targetList.Visible; carList.Visible=false
		if targetList.Visible then clearOptions(targetList); for _,target in ipairs(CarControlController:GetTargetOptions()) do option(targetList,target.DisplayName.."  (@"..target.Name..")",function() CarControlController:SetTarget(target); targetList.Visible=false; UpdateCarControlPanel() end) end end
	end)
	heightMinus.MouseButton1Click:Connect(function() CarControlController:ChangeHeight(-1); UpdateCarControlPanel() end); heightPlus.MouseButton1Click:Connect(function() CarControlController:ChangeHeight(1); UpdateCarControlPanel() end)
	speedMinus.MouseButton1Click:Connect(function() CarControlController:ChangeSpinSpeed(-60); UpdateCarControlPanel() end); speedPlus.MouseButton1Click:Connect(function() CarControlController:ChangeSpinSpeed(60); UpdateCarControlPanel() end)
	toggle.MouseButton1Click:Connect(function() local ok,err; if CarControlController:IsRunning() then CarControlController:Stop(true); ok=true else ok,err=CarControlController:Start() end; UpdateCarControlPanel(ok and nil or err) end)
	UpdateCarControlPanel(); return true
end