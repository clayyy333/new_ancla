-- Vista integrada de Control de auto libre.
return function(context)
	setfenv(1,context)
	freeCarControlPanel=Instance.new("ScrollingFrame"); freeCarControlPanel.Size=UDim2.new(1,-16,1,-(titleH+20)); freeCarControlPanel.Position=UDim2.new(0,8,0,titleH+8); freeCarControlPanel.BackgroundTransparency=1; freeCarControlPanel.BorderSizePixel=0; freeCarControlPanel.ScrollBarThickness=3; freeCarControlPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y; freeCarControlPanel.CanvasSize=UDim2.new(); freeCarControlPanel.Visible=false; freeCarControlPanel.ZIndex=6; freeCarControlPanel.Parent=content
	local card=Instance.new("Frame"); card.Size=UDim2.new(1,-4,0,isMobile and 530 or 420); card.BackgroundColor3=currentTheme.secondary; card.ZIndex=7; card.Parent=freeCarControlPanel; Instance.new("UICorner",card).CornerRadius=UDim.new(0,14); RegisterTheme(card,"BackgroundColor3","secondary")
	local padding=Instance.new("UIPadding",card); padding.PaddingLeft=UDim.new(0,14); padding.PaddingRight=UDim.new(0,14); padding.PaddingTop=UDim.new(0,14); padding.PaddingBottom=UDim.new(0,14)
	local function label(text,y,height)
		local item=Instance.new("TextLabel"); item.Size=UDim2.new(1,0,0,height or 18); item.Position=UDim2.new(0,0,0,y); item.BackgroundTransparency=1; item.Text=text; item.TextWrapped=true; item.TextColor3=currentTheme.textDim; item.Font=Enum.Font.GothamMedium; item.TextSize=isMobile and 10 or 12; item.TextXAlignment=Enum.TextXAlignment.Left; item.ZIndex=8; item.Parent=card; RegisterTheme(item,"TextColor3","textDim"); return item
	end
	local function button(text,y,x,width,height,z)
		local item=Instance.new("TextButton"); item.Size=UDim2.new(width or 1,0,0,height or 40); item.Position=UDim2.new(x or 0,0,0,y); item.BackgroundColor3=currentTheme.tertiary; item.Text=text; item.TextColor3=currentTheme.text; item.Font=Enum.Font.GothamBold; item.TextSize=isMobile and 10 or 12; item.AutoButtonColor=false; item.ZIndex=z or 8; item.Parent=card; Instance.new("UICorner",item).CornerRadius=UDim.new(0,10); RegisterTheme(item,"BackgroundColor3","tertiary"); RegisterTheme(item,"TextColor3","text"); return item
	end
	label(isES and "Mi vehículo" or "My vehicle",0)
	local carButton=button(isES and "Seleccionar vehículo" or "Select vehicle",22); carButton.TextXAlignment=Enum.TextXAlignment.Left; carButton.Font=Enum.Font.GothamMedium; carButton.ZIndex=10; Instance.new("UIPadding",carButton).PaddingLeft=UDim.new(0,12)
	local carList=Instance.new("ScrollingFrame"); carList.Size=UDim2.new(1,0,0,110); carList.Position=UDim2.new(0,0,0,64); carList.BackgroundColor3=currentTheme.tertiary; carList.BorderSizePixel=0; carList.ScrollBarThickness=4; carList.AutomaticCanvasSize=Enum.AutomaticSize.Y; carList.CanvasSize=UDim2.new(); carList.Visible=false; carList.ZIndex=30; carList.Parent=card; Instance.new("UICorner",carList).CornerRadius=UDim.new(0,10); Instance.new("UIListLayout",carList).Padding=UDim.new(0,3); RegisterTheme(carList,"BackgroundColor3","tertiary")
	label(isES and "Velocidad de movimiento" or "Movement speed",70)
	local speedMinus=button("−",92,0,0.20); local speedValue=button("",92,0.22,0.56); local speedPlus=button("+",92,0.80,0.20)
	label(isES and "Respuesta de inclinación vertical" or "Vertical tilt response",140)
	local tiltMinus=button("−",162,0,0.20); local tiltValue=button("",162,0.22,0.56); local tiltPlus=button("+",162,0.80,0.20)
	local toggle=button("",214)
	local boost=button(isES and "Mantener impulso" or "Hold boost",264)
	local cameraPad=button(isES and "Arrastra aquí o sobre el mundo: cámara" or "Drag here or over the world: camera",314,0,1,42)
	local status=label("",isMobile and 466 or 364,34)
	local directionButtons={}
	if isMobile then
		local controls={{"Forward","▲",364,0.34},{"Left","◀",410,0.08},{"Back","▼",410,0.34},{"Right","▶",410,0.60}}
		for _,entry in ipairs(controls) do
			local control=button(entry[2],entry[3],entry[4],0.24,40); directionButtons[entry[1]]=control
			local directionName=entry[1]
			control.InputBegan:Connect(function(input) if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end; FreeCarController:SetMobileDirection(directionName,true); control.BackgroundColor3=currentTheme.accent; local ended; ended=input:GetPropertyChangedSignal("UserInputState"):Connect(function() if input.UserInputState==Enum.UserInputState.End or input.UserInputState==Enum.UserInputState.Cancel then if ended then ended:Disconnect();ended=nil end; FreeCarController:SetMobileDirection(directionName,false); control.BackgroundColor3=currentTheme.tertiary end end) end)

		end
	end
	cameraPad.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.MouseButton2 then FreeCarController:BeginCameraDrag(input) end end)
	cameraPad.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.MouseButton2 then FreeCarController:EndCameraDrag(input) end end)
	local function clearOptions() for _,child in ipairs(carList:GetChildren()) do if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end end end
	local function option(text,callback)
		local item=button(text,0,0,1,32,31); item.Parent=carList; item.Position=UDim2.new(); item.Size=UDim2.new(1,-4,0,32); item.MouseButton1Click:Connect(callback)
	end
	UpdateFreeCarControlPanel=function(message)
		local car=FreeCarController:GetCar(); carButton.Text=car and car.Name or (isES and "Seleccionar vehículo" or "Select vehicle")
		speedValue.Text=(isES and "Velocidad: " or "Speed: ")..tostring(FreeCarController:GetSpeed())
		tiltValue.Text=(isES and "Respuesta: " or "Response: ")..tostring(FreeCarController:GetTiltResponse())
		toggle.Text=FreeCarController:IsRunning() and (isES and "Desactivar control libre" or "Disable free control") or (isES and "Activar control libre" or "Enable free control")
		toggle.BackgroundColor3=FreeCarController:IsRunning() and currentTheme.critical or currentTheme.tertiary
		status.Text=message or FreeCarController.Status or (isES and "WASD/flechas para mover · mirar arriba o abajo cambia la altura." or "WASD/arrows to move · looking up or down changes altitude.")
	end
	carButton.MouseButton1Click:Connect(function()
		carList.Visible=not carList.Visible
		if carList.Visible then clearOptions(); local cars=FreeCarController:GetCarOptions(); if #cars==0 then option(isES and "No se encontraron vehículos propios" or "No owned vehicles found",function() end) else for _,car in ipairs(cars) do option(car.Name,function() if FreeCarController:IsRunning() then FreeCarController:Stop() end; FreeCarController:SetCar(car); carList.Visible=false; UpdateFreeCarControlPanel() end) end end end
	end)
	speedMinus.MouseButton1Click:Connect(function() FreeCarController:ChangeSpeed(-20); UpdateFreeCarControlPanel() end); speedPlus.MouseButton1Click:Connect(function() FreeCarController:ChangeSpeed(20); UpdateFreeCarControlPanel() end)
	tiltMinus.MouseButton1Click:Connect(function() FreeCarController:ChangeTiltResponse(-2); UpdateFreeCarControlPanel() end); tiltPlus.MouseButton1Click:Connect(function() FreeCarController:ChangeTiltResponse(2); UpdateFreeCarControlPanel() end)
	toggle.MouseButton1Click:Connect(function() local ok,err; if FreeCarController:IsRunning() then FreeCarController:Stop(); ok=true else ok,err=FreeCarController:Start() end; UpdateFreeCarControlPanel(ok and nil or err) end)
	boost.InputBegan:Connect(function(input) if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end; FreeCarController:SetBoost(true); boost.BackgroundColor3=currentTheme.accent; local ended; ended=input:GetPropertyChangedSignal("UserInputState"):Connect(function() if input.UserInputState==Enum.UserInputState.End or input.UserInputState==Enum.UserInputState.Cancel then if ended then ended:Disconnect();ended=nil end; FreeCarController:SetBoost(false); boost.BackgroundColor3=currentTheme.tertiary end end) end)

	UpdateFreeCarControlPanel(); return true
end