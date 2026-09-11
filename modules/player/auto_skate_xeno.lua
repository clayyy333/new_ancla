-- Auto patin XENO integrado. Sin GUI independiente.
return function(context)
	setfenv(1,context)
	local VirtualInputManager=game:GetService("VirtualInputManager")

	local TARGET_NAME="ltp2_car_57"
	local WATCH_INTERVAL,SPAWN_CONFIRM_TIMEOUT,GUI_INIT_TIMEOUT=0.04,1.5,6
	local Core={Enabled=false,Busy=false,Generation=0,LastPatin=nil,Failures=0,Status="AUTO desactivado"}
	local connections={}
	local function update(text)
		Core.Status=text
		if UpdateAutoAnchorPanel then UpdateAutoAnchorPanel() end
	end
	local function getCars() return workspace:FindFirstChild("Cars") end
	local function isMine(vehicle)
		if not vehicle or not vehicle.Parent or vehicle.Name~=TARGET_NAME then return false end
		local owner=vehicle:FindFirstChild("VehicleOwner")
		return owner and owner:IsA("ObjectValue") and owner.Value==player
	end
	local function getMine()
		local cars=getCars()
		if not cars then return nil end
		for _,vehicle in ipairs(cars:GetChildren()) do
			if isMine(vehicle) then Core.LastPatin=vehicle; return vehicle end
		end
	end
	local function getOwnedVehicle()
		local cars=getCars()
		if not cars then return nil end
		for _,vehicle in ipairs(cars:GetChildren()) do
			local owner=vehicle:FindFirstChild("VehicleOwner")
			if owner and owner:IsA("ObjectValue") and owner.Value==player then return vehicle end
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
	local function showParents(obj)
		local current=obj
		while current and current~=playerGui do
			if current:IsA("GuiObject") then pcall(function() current.Visible=true end) end
			if current:IsA("ScreenGui") then pcall(function() current.Enabled=true end) end
			current=current.Parent
		end
	end
	local function findButton()
		local dialog=playerGui:FindFirstChild("DialogVehicle")
		local root=dialog and dialog:FindFirstChild("root")
		local frame=root and root:FindFirstChild("Frame")
		local itemsFrame=frame and frame:FindFirstChild("ItemsFrame")
		local items=itemsFrame and itemsFrame:FindFirstChild("Items")
		local scroll=items and items:FindFirstChild("ScrollFrame")
		local item=scroll and scroll:FindFirstChild(TARGET_NAME)
		local button=item and item:FindFirstChild("Button")
		if not button or not button:IsA("GuiButton") then return nil,scroll,TARGET_NAME.." no disponible" end
		return button,scroll
	end
	local function scrollTo(scroll,button)
		RunService.RenderStepped:Wait()
		local targetY=button.AbsolutePosition.Y+button.AbsoluteSize.Y/2
		local centerY=scroll.AbsolutePosition.Y+scroll.AbsoluteSize.Y/2
		local maxY=math.max(0,scroll.AbsoluteCanvasSize.Y-scroll.AbsoluteWindowSize.Y)
		scroll.CanvasPosition=Vector2.new(scroll.CanvasPosition.X,math.clamp(scroll.CanvasPosition.Y+targetY-centerY,0,maxY))
		RunService.RenderStepped:Wait()
	end
	local function click(button)
		if not button or not button.Parent then return false end
		local restoreMain=main and main.Parent and main.Visible
		if restoreMain then main.Visible=false; RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait() end
		local x=button.AbsolutePosition.X+button.AbsoluteSize.X/2
		local y=button.AbsolutePosition.Y+button.AbsoluteSize.Y/2
		local ok=pcall(function()
			VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,0)
			task.wait(0.08)
			VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,0)
		end)
		if restoreMain and main and main.Parent then RunService.RenderStepped:Wait(); main.Visible=true end
		return ok
	end
	local function getPhoneParts()
		local screen=playerGui:FindFirstChild("ScreenGeneral")
		local role=screen and screen:FindFirstChild("FrameRoleInfo")
		return role and role:FindFirstChild("TelescopicBtn"),role and role:FindFirstChild("Buttons")
	end
	local function ensurePhoneOpen()
		local telescopic,buttons=getPhoneParts()
		if not telescopic then return false,"No encontré TelescopicBtn" end
		if not buttons then return false,"No encontré Buttons" end
		if not (buttons.Visible and buttons.Size.X.Scale>=0.9 and buttons.Size.Y.Scale>=0.9) then
			update(isES and "Abriendo el teléfono..." or "Opening phone...")
			telescopic.Position=UDim2.new(-0.159039438,0,0.146093443,0)
			buttons.Visible,buttons.Size=true,UDim2.new(1,0,1,0)
			for _=1,3 do RunService.RenderStepped:Wait() end
			task.wait(0.10)
		end
		return true
	end
	local function initializeVehicleMenu()
		local button,scroll=findButton()
		if button then return button,scroll end
		local ok,err=ensurePhoneOpen()
		if not ok then return nil,nil,err end
		local _,buttons=getPhoneParts()
		local vehicle=buttons and buttons:FindFirstChild("VehicleBtn")
		local vehicleButton=vehicle and vehicle:FindFirstChild("Button")
		if not vehicleButton or not vehicleButton:IsA("GuiButton") then return nil,nil,"No encontré VehicleBtn.Button" end
		update(isES and "Inicializando el selector de vehículos..." or "Initializing vehicle selector...")
		RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait(); task.wait(0.10)
		if not click(vehicleButton) then return nil,nil,"No se pudo abrir Vehículos" end
		local deadline=os.clock()+GUI_INIT_TIMEOUT
		repeat
			button,scroll=findButton()
			if button then return button,scroll end
			task.wait(0.05)
		until os.clock()>=deadline
		return nil,nil,TARGET_NAME.." no apareció en Vehículos"
	end
	local function waitForMine(timeout,generation)
		local started=os.clock()
		while os.clock()-started<timeout do
			if generation and generation~=Core.Generation then return nil end
			local vehicle=getMine()
			if vehicle then return vehicle end
			task.wait(0.02)
		end
		return getMine()
	end
	local function spawnPatin(generation)
		if Core.Busy then return false,"busy" end
		if getMine() then return true,"already_exists" end
		Core.Busy=true
		local button,scroll,err=initializeVehicleMenu()
		if not button then Core.Busy=false; return false,err end
		showParents(button); scrollTo(scroll,button)
		if generation and generation~=Core.Generation then Core.Busy=false; return false,"cancelled" end
		if not click(button) then Core.Busy=false; Core.Failures+=1; return false,"click_error" end
		local vehicle=waitForMine(SPAWN_CONFIRM_TIMEOUT,generation)
		Core.Busy=false
		if vehicle then Core.LastPatin=vehicle; Core.Failures=0; return true,"spawned" end
		Core.Failures+=1
		return false,"spawn_no_confirmado"
	end
	local function retryDelay()
		if Core.Failures<=2 then return 0.08 end
		if Core.Failures<=5 then return 0.12 end
		if Core.Failures<=10 then return 0.18 end
		return 0.25
	end
	local function startWorker()
		if Core.WorkerRunning then return end
		Core.WorkerRunning=true
		local generation=Core.Generation
		task.spawn(function()
			while Core.Enabled and generation==Core.Generation do
				local vehicle=getMine()
				if vehicle then
					Core.LastPatin=vehicle; Core.Failures=0
					update((isES and "Mi patín activo" or "My skateboard is active").." | XENO")
					task.wait(WATCH_INTERVAL)
				else
					Core.LastPatin=nil
					update(isES and "Patín ausente; recuperando..." or "Skateboard missing; recovering...")
					local ok,reason=spawnPatin(generation)
					if not ok and reason~="busy" and reason~="cancelled" then
						update((isES and "Reintentando: " or "Retrying: ")..tostring(reason))
						task.wait(retryDelay())
					end
				end
			end
			Core.WorkerRunning=false
			if Core.Enabled then task.defer(startWorker) end
		end)
	end
	function Core:Start()
		if self.Enabled then return true end
		self.Enabled=true; self.Generation+=1; self.Failures=0
		update(isES and "Buscando mi patín..." or "Finding my skateboard...")
		startWorker()
		return true
	end
	function Core:RemoveOwnedVehicle()
		local vehicle=getOwnedVehicle()
		if not vehicle or vehicle.Name==TARGET_NAME then return true end
		self.Busy=true
		local _,scroll,err=initializeVehicleMenu()
		if not scroll then self.Busy=false; return false,err or "No se pudo abrir Vehículos" end
		local item=scroll:FindFirstChild(vehicle.Name)
		local button=item and item:FindFirstChild("Button")
		if not button or not button:IsA("GuiButton") then self.Busy=false; return false,"No apareció el botón del vehículo actual" end
		showParents(button); scrollTo(scroll,button)
		if not click(button) then self.Busy=false; return false,"No se pudo retirar el vehículo actual" end
		local deadline=os.clock()+SPAWN_CONFIRM_TIMEOUT
		while os.clock()<deadline and vehicle.Parent do task.wait(0.03) end
		self.Busy=false
		return not vehicle.Parent,vehicle.Parent and "El servidor no confirmó la retirada del vehículo" or nil
	end
	function Core:StopAndRemove()
		self.Enabled=false; self.Generation+=1
		while self.Busy do task.wait() end
		local vehicle=getMine()
		if not vehicle then self.LastPatin=nil; update("AUTO desactivado"); return true end
		update(isES and "Retirando patín..." or "Removing skateboard...")
		local button,scroll=findButton()
		local clicked=false
		if button then showParents(button); scrollTo(scroll,button); clicked=click(button) end
		local deadline=os.clock()+SPAWN_CONFIRM_TIMEOUT
		while clicked and os.clock()<deadline and getMine() do task.wait(0.03) end
		vehicle=getMine()
		if vehicle then pcall(function() vehicle:Destroy() end) end
		self.LastPatin=nil; update("AUTO desactivado")
		return not getMine(),clicked and nil or "No se confirmó el botón de retirada"
	end
	function Core:Destroy()
		self.Enabled=false; self.Generation+=1
		for _,connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
		table.clear(connections)
	end
	AutoSkateXeno=Core
	return true
end
