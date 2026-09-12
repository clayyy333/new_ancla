-- Preparacion de moto Xeno integrada. No crea ninguna GUI independiente.
return function(context)
	setfenv(1, context)
	local VirtualInputManager = game:GetService("VirtualInputManager")
	local MOTO_NAME = "ltp2_car_7"
	local GUI_INIT_TIMEOUT, MOTO_TIMEOUT, DRIVE_TIMEOUT = 6, 4, 6
	local Core = {Busy=false, RunningMode=nil, LastMode=nil, SelectedTarget=nil, WatchedMoto=nil, WatchId=0,
		Status=isES and "Listo para preparar la moto." or "Ready to prepare the motorcycle."}

	local function update(message)
		Core.Status = message or Core.Status
		if UpdateMotoFlingXenoPanel then UpdateMotoFlingXenoPanel(Core.Status) end
	end
	local function physicalClick(button)
		if not button or not button.Parent then return false,"Botón inválido" end
		local targetScreen=button:FindFirstAncestorOfClass("ScreenGui")
		local disabledScreens={}
		for _,child in ipairs(playerGui:GetChildren()) do
			if child:IsA("ScreenGui") and child~=targetScreen and child.Enabled then
				child.Enabled=false
				disabledScreens[#disabledScreens+1]=child
			end
		end
		local restoreMain=main and main.Parent and main.Visible
		if restoreMain then main.Visible=false; RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait() end
		local x=button.AbsolutePosition.X+button.AbsoluteSize.X/2
		local y=button.AbsolutePosition.Y+button.AbsoluteSize.Y/2
		local ok,err=pcall(function()
			VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,0)
			task.wait(0.08)
			VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,0)
		end)
		RunService.RenderStepped:Wait()
		for _,screen in ipairs(disabledScreens) do
			if screen and screen.Parent then screen.Enabled=true end
		end
		if restoreMain and main and main.Parent then RunService.RenderStepped:Wait(); main.Visible=true end
		return ok,ok and nil or tostring(err)
	end
	local function showGuiParents(obj)
		local current = obj
		while current and current ~= playerGui do
			if current:IsA("GuiObject") then pcall(function() current.Visible = true end) end
			if current:IsA("ScreenGui") then pcall(function() current.Enabled = true end) end
			current = current.Parent
		end
	end
	local function pressE()
		return pcall(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			task.wait(0.10)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end)
	end
	local function scrollDirect(scroll, target)
		if not scroll or not target then return false end
		RunService.RenderStepped:Wait()
		local targetCenter = target.AbsolutePosition.Y + target.AbsoluteSize.Y / 2
		local scrollCenter = scroll.AbsolutePosition.Y + scroll.AbsoluteSize.Y / 2
		local maxY = math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y)
		scroll.CanvasPosition = Vector2.new(scroll.CanvasPosition.X, math.clamp(scroll.CanvasPosition.Y + targetCenter - scrollCenter, 0, maxY))
		RunService.RenderStepped:Wait()
		return true
	end
	local function getPhoneParts()
		local screen=playerGui:FindFirstChild("ScreenGeneral")
		local role=screen and screen:FindFirstChild("FrameRoleInfo")
		local buttons=role and role:FindFirstChild("Buttons")
		local telescopic=role and role:FindFirstChild("TelescopicBtn")
		return telescopic,buttons,telescopic and telescopic:FindFirstChild("phone"),telescopic and telescopic:FindFirstChild("Arrow")
	end
	local function isPhoneOpen()
		local _,buttons=getPhoneParts()
		return buttons and buttons.Visible and buttons.Size.X.Scale>=0.9 and buttons.Size.Y.Scale>=0.9
	end
	local function forcePhoneOpenState()
		local telescopic,buttons,phone,arrow=getPhoneParts()
		if not telescopic or not buttons then return false,"No encontré la interfaz del teléfono" end
		buttons.Visible=true
		buttons.Size=UDim2.new(1,0,1,0)
		telescopic.Visible=true
		telescopic.Position=UDim2.new(-0.159039497,0,0.146093443,0)
		if phone then phone.Visible=false end
		if arrow then
			arrow.Position=UDim2.new(0.740999997,0,0.5,0)
			arrow.Rotation=0
		end
		return true
	end
	local function clearSelectBG(holderName)
		local _,buttons=getPhoneParts()
		local holder=buttons and buttons:FindFirstChild(holderName)
		local button=holder and holder:FindFirstChild("Button")
		local selectbg=button and button:FindFirstChild("selectbg")
		if selectbg then selectbg.Visible=false end
	end
	local function forcePhoneBack()
		local communicate=playerGui:FindFirstChild("DialogCommunicate")
		if communicate and communicate.Enabled then
			local root=communicate:FindFirstChild("Root")
			local panelUser=root and root:FindFirstChild("PanelUserList")
			local panelChat=root and root:FindFirstChild("PanelChat")
			if panelUser then panelUser.Visible=false end
			if panelChat then panelChat.Visible=false end
			communicate.Enabled=false
			clearSelectBG("CommunicateBtn")
		end
		local vehicle=playerGui:FindFirstChild("DialogVehicle")
		if vehicle and vehicle.Enabled then
			vehicle.Enabled=false
			clearSelectBG("VehicleBtn")
		end
		local backpack=playerGui:FindFirstChild("DialogBackpack")
		if backpack and backpack.Enabled then backpack.Enabled=false end
		local room=playerGui:FindFirstChild("DialogChooseRoomType")
		if room and room.Enabled then room.Enabled=false end
	end
	local function forcePhoneMinimized()
		forcePhoneBack()
		local opened,openErr=forcePhoneOpenState()
		if not opened then return false,openErr end
		for _=1,2 do RunService.RenderStepped:Wait() end
		local telescopic,buttons,phone,arrow=getPhoneParts()
		if not telescopic or not buttons then return false,"No encontré la interfaz del teléfono" end
		update(isES and "Reiniciando el teléfono..." or "Resetting phone...")
		buttons.Visible=false
		buttons.Size=UDim2.new(0.199999988,0,0.199999988,0)
		telescopic.Visible=true
		telescopic.Position=UDim2.new(0.685960591,0,0.146093443,0)
		if phone then phone.Visible=true end
		if arrow then
			arrow.Position=UDim2.new(0.141000003,0,0.5,0)
			arrow.Rotation=180
		end
		for _=1,2 do RunService.RenderStepped:Wait() end
		if isPhoneOpen() then return false,isES and "No pude establecer el teléfono minimizado." or "Could not set minimized phone state." end
		return true
	end
	local function ensurePhoneOpen()
		if isPhoneOpen() then return true end
		update(isES and "Abriendo el teléfono..." or "Opening phone...")
		local ok,err=forcePhoneOpenState()
		if not ok then return false,err end
		for _=1,3 do RunService.RenderStepped:Wait() end
		task.wait(0.10)
		if not isPhoneOpen() then return false,isES and "No pude establecer el teléfono abierto." or "Could not set open phone state." end
		return true
	end
	local function getVehicleMenuButton()
		local _, buttons = getPhoneParts()
		local vehicle = buttons and buttons:FindFirstChild("VehicleBtn")
		local button = vehicle and vehicle:FindFirstChild("Button")
		return button and button:IsA("GuiButton") and button or nil
	end
	local function getMotoButton()
		local dialog=playerGui:FindFirstChild("DialogVehicle")
		local root=dialog and dialog:FindFirstChild("root")
		local frame=root and root:FindFirstChild("Frame")
		local itemsFrame=frame and frame:FindFirstChild("ItemsFrame")
		local items=itemsFrame and itemsFrame:FindFirstChild("Items")
		local scroll=items and items:FindFirstChild("ScrollFrame")
		local item=scroll and scroll:FindFirstChild(MOTO_NAME)
		local button=item and item:FindFirstChild("Button")
		return button and button:IsA("GuiButton") and button or nil, scroll
	end
	local function waitForMotoButton(timeout)
		local deadline=os.clock()+timeout
		while os.clock()<deadline do
			local button,scroll=getMotoButton()
			if button then return button,scroll end
			task.wait(0.05)
		end
		return getMotoButton()
	end
	local function initializeVehicleMenu()
		local button,scroll=getMotoButton()
		if button then return button,scroll end
		local ok,err=ensurePhoneOpen()
		if not ok then return nil,nil,err end
		local vehicleButton=getVehicleMenuButton()
		if not vehicleButton then return nil,nil,"No encontré VehicleBtn.Button" end
		RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait(); task.wait(0.10)
		update(isES and "1/5 Abriendo Vehículos..." or "1/5 Opening Vehicles...")
		ok,err=physicalClick(vehicleButton)
		if not ok then return nil,nil,"Vehicle: "..tostring(err) end
		update("1/5 Esperando "..MOTO_NAME.."...")
		button,scroll=waitForMotoButton(GUI_INIT_TIMEOUT)
		if not button then return nil,nil,"No apareció "..MOTO_NAME..".Button" end
		return button,scroll
	end
	local function getOwnedVehicle()
		local cars=workspace:FindFirstChild("Cars")
		if not cars then return nil end
		for _,vehicle in ipairs(cars:GetChildren()) do
			local vehicleOwner=vehicle:FindFirstChild("VehicleOwner")
			if vehicleOwner and vehicleOwner:IsA("ObjectValue") and vehicleOwner.Value==player then return vehicle end
		end
		local spawnPoints=workspace:FindFirstChild("CarSpawnPoints")
		if not spawnPoints then return nil end
		local prefix=player.Name.."_"
		for _,spawnPoint in ipairs(spawnPoints:GetChildren()) do
			local owner=spawnPoint:FindFirstChild("Owner")
			if owner and owner:IsA("StringValue") and owner.Value==player.Name and spawnPoint.Name:sub(1,#prefix)==prefix then
				local vehicle=cars:FindFirstChild(spawnPoint.Name:sub(#prefix+1))
				if vehicle then return vehicle end
			end
		end
	end
	local function removeOwnedVehicle()
		local vehicle=getOwnedVehicle()
		if not vehicle or vehicle.Name==MOTO_NAME then return true end
		update(isES and "Retirando el vehículo actual..." or "Removing current vehicle...")
		local _,scroll,err=initializeVehicleMenu()
		if not scroll then return false,err or "No se pudo abrir Vehículos" end
		local item=scroll:FindFirstChild(vehicle.Name)
		local button=item and item:FindFirstChild("Button")
		if not button or not button:IsA("GuiButton") then return false,"No apareció el botón del vehículo actual" end
		showGuiParents(button); scrollDirect(scroll,button); task.wait(0.10)
		local clicked,clickErr=physicalClick(button)
		if not clicked then return false,clickErr or "No se pudo retirar el vehículo actual" end
		local deadline=os.clock()+MOTO_TIMEOUT
		while os.clock()<deadline and vehicle.Parent do task.wait(0.04) end
		return not vehicle.Parent,vehicle.Parent and "El servidor no confirmó la retirada del vehículo" or nil
	end
	local function isMyMoto(vehicle)
		if not vehicle or not vehicle.Parent or vehicle.Name~=MOTO_NAME then return false end
		local owner=vehicle:FindFirstChild("VehicleOwner")
		return owner and owner:IsA("ObjectValue") and owner.Value==player
	end
	local function getMyMoto()
		local cars=workspace:FindFirstChild("Cars")
		if not cars then return nil end
		for _,vehicle in ipairs(cars:GetChildren()) do if isMyMoto(vehicle) then return vehicle end end
	end
	local function waitForMyMoto(timeout)
		local deadline=os.clock()+timeout
		while os.clock()<deadline do
			local moto=getMyMoto()
			if moto then return moto end
			task.wait(0.04)
		end
		return getMyMoto()
	end
	local function motoStillValid(moto)
		local cars=workspace:FindFirstChild("Cars")
		return isMyMoto(moto) and cars and moto:IsDescendantOf(cars)
	end
	local function getWeldToPlayer(moto)
		return moto and moto.Parent and moto:FindFirstChild("WeldToPlayer",true) or nil
	end
	local function watchMoto(moto)
		Core.WatchId+=1
		local id=Core.WatchId
		Core.WatchedMoto=moto
		task.spawn(function()
			while id==Core.WatchId do
				if not motoStillValid(moto) then
					if id~=Core.WatchId then return end
					Core.WatchedMoto,Core.Busy=nil,false
					if Core.RunningMode then Core:Stop() end
					update(isES and "Moto eliminada. Listo para generar nuevamente." or "Motorcycle removed. Ready to generate again.")
					return
				end
				task.wait(0.20)
			end
		end)
	end
	local function generateMoto()
		local existing=getMyMoto()
		if existing then return existing end
		local resetOK,resetErr=forcePhoneMinimized()
		if not resetOK then return nil,resetErr end
		local removed,removeErr=removeOwnedVehicle()
		if not removed then return nil,removeErr end
		local button,scroll,err=initializeVehicleMenu()
		if not button then return nil,err or "No pude preparar Vehicle" end
		showGuiParents(button); scrollDirect(scroll,button); task.wait(0.10)
		update("2/5 Generando "..MOTO_NAME.."...")
		local clicked
		clicked,err=physicalClick(button)
		if not clicked then return nil,"Error en "..MOTO_NAME..": "..tostring(err) end
		local moto=waitForMyMoto(MOTO_TIMEOUT)
		if not moto then return nil,"La moto se activó pero no apareció como propia" end
		return moto
	end
	local function getDriveButton()
		local interact=playerGui:FindFirstChild("InteractGUI")
		local normal=interact and interact:FindFirstChild("NormalInteract")
		local root=normal and normal:FindFirstChild("Root")
		local button=root and root:FindFirstChild("Button")
		return button and button:IsA("GuiButton") and button or nil
	end
	local function waitForDriveButton(timeout)
		local deadline=os.clock()+timeout
		while os.clock()<deadline do
			local button=getDriveButton()
			if button then return button end
			task.wait(0.04)
		end
	end
	local function driveMoto(moto)
		if getWeldToPlayer(moto) then return true end
		update(isES and "4/5 Esperando Conducir..." or "4/5 Waiting for Drive...")
		if not waitForDriveButton(DRIVE_TIMEOUT) then return false,"No apareció Conducir" end
		task.wait(0.15)
		local deadline,attempt=os.clock()+DRIVE_TIMEOUT,0
		while os.clock()<deadline do
			if not motoStillValid(moto) then return false,"La moto desapareció durante el proceso" end
			if getWeldToPlayer(moto) then return true end
			attempt+=1
			update((isES and "5/5 Subiendo a la moto, intento #" or "5/5 Mounting motorcycle, attempt #")..tostring(attempt))
			pressE()
			local check=os.clock()+0.35
			while os.clock()<check do
				if not motoStillValid(moto) then return false,"La moto desapareció durante el proceso" end
				if getWeldToPlayer(moto) then return true end
				task.wait(0.02)
			end
			task.wait(0.08)
		end
		return false,"No apareció WeldToPlayer"
	end

	function Core:GetTargetOptions()
		local result={}
		for _,target in ipairs(Players:GetPlayers()) do if target~=player then result[#result+1]=target end end
		return result
	end
	function Core:SetTarget(target)
		self.SelectedTarget=typeof(target)=="Instance" and target:IsA("Player") and target or nil
		return self.SelectedTarget~=nil
	end
	function Core:GetTarget() return self.SelectedTarget end
	function Core:GetStatus() return self.Status end
	function Core:IsRunning()
		if self.RunningMode=="normal" then return Fling2Core.Running end
		if self.RunningMode=="efficient" then return Fling2EfficientCore.Running end
		return false
	end
	function Core:Stop()
		local mode=self.RunningMode
		self.RunningMode=nil
		if mode=="normal" and Fling2Core.Running then Fling2Core:Stop() end
		if mode=="efficient" and Fling2EfficientCore.Running then Fling2EfficientCore:Stop() end
		update(isES and "Fling con moto Xeno detenido." or "Xeno motorcycle fling stopped.")
		return mode~=nil
	end
	function Core:ForceReturn()
		if self.Busy then return false,isES and "Espera a que termine la preparación." or "Wait for preparation to finish." end
		if self:IsRunning() then return false,isES and "Desactiva el fling con moto antes de forzar el regreso." or "Disable the motorcycle fling before forcing the return." end
		local engine=self.LastMode=="efficient" and Fling2EfficientCore or Fling2Core
		return engine:ForceReturn()
	end
	function Core:Start(mode)
	if AutoAnchorCore then
		local anchorOK,anchorErr=AutoAnchorCore:PrepareForMotoFling()
		if not anchorOK then return false,anchorErr end
	end
		if self.Busy then return false,isES and "La preparación ya está en curso." or "Preparation is already running." end
		if self:IsRunning() then return true end
		if mode~="normal" and mode~="efficient" then return false,"Modo inválido" end
		if not self.SelectedTarget or self.SelectedTarget.Parent~=Players then return false,L.selectPlayerFirst end
		if Fling2Core.Running or Fling2EfficientCore.Running then
			return false,isES and "Desactiva primero el Fling 2 que está activo." or "Disable the active Fling 2 first."
		end
		self.Busy=true
		update(isES and "1/5 Preparando Vehículos..." or "1/5 Preparing Vehicles...")
		local moto,err=generateMoto()
		if not moto then self.Busy=false; update("ERROR: "..tostring(err)); return false,err end
		watchMoto(moto)
		update(isES and "3/5 Moto propia confirmada." or "3/5 Owned motorcycle confirmed.")
		task.wait(0.15)
		local driven
		driven,err=driveMoto(moto)
		if not driven then self.Busy=false; update("ERROR: "..tostring(err)); return false,err end
		if not getWeldToPlayer(moto) then self.Busy=false; return false,"No se confirmó WeldToPlayer" end
		local engine=mode=="efficient" and Fling2EfficientCore or Fling2Core
		engine:SetTarget(self.SelectedTarget)
		local ok
		ok,err=engine:Start()
		self.Busy=false
		if not ok then update("ERROR: "..tostring(err)); return false,err end
		self.RunningMode=mode
		self.LastMode=mode
		update(mode=="efficient" and (isES and "Fling con moto Xeno eficiente activo." or "Efficient Xeno motorcycle fling active.") or (isES and "Fling con moto Xeno activo." or "Xeno motorcycle fling active."))
		return true
	end
	function Core:Destroy()
		self.WatchId+=1
		self:Stop()
		self.WatchedMoto=nil
	end

	MotoFlingXenoCore=Core
	_motoFlingXenoPlayerRemovingConn=Players.PlayerRemoving:Connect(function(leaving)
		if Core.SelectedTarget==leaving then
			if Core:IsRunning() then Core:Stop() end
			Core:SetTarget(nil)
			update(isES and "El jugador objetivo salió." or "The target player left.")
		end
	end)
	_motoFlingXenoMonitorConn=RunService.Heartbeat:Connect(function()
		if Core.RunningMode and not Core:IsRunning() then
			Core.RunningMode=nil
			update(isES and "Fling con moto Xeno detenido." or "Xeno motorcycle fling stopped.")
		end
	end)
	return true
end
