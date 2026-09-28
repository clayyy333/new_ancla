-- Patin DELTA independiente y exclusivo para Ancla test.
return function(context)
	setfenv(1,context)
	local TARGET_NAME="ltp2_car_57"
	local WATCH_INTERVAL,SPAWN_TIMEOUT,GUI_TIMEOUT=0.04,1.5,6
	local Core={Enabled=false,Busy=false,Generation=0,LastPatin=nil,Failures=0,GraceUntil=0}
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
	local function inCharacter(instance)
		local character=player.Character
		return instance and character and instance:IsDescendantOf(character)
	end
	local function inVehicle(instance,vehicle)
		return instance and vehicle and instance:IsDescendantOf(vehicle)
	end
	local function isCharacterVehicleLink(item,vehicle)
		if item:IsA("JointInstance") then
			return (inCharacter(item.Part0) and inVehicle(item.Part1,vehicle))
				or (inCharacter(item.Part1) and inVehicle(item.Part0,vehicle))
		end
		if item:IsA("Constraint") then
			local a0,a1=item.Attachment0,item.Attachment1
			local p0,p1=a0 and a0.Parent,a1 and a1.Parent
			return (inCharacter(p0) and inVehicle(p1,vehicle))
				or (inCharacter(p1) and inVehicle(p0,vehicle))
		end
		return false
	end
	local function getOtherOwnedVehicle()
		local cars=getCars()
		if not cars then return nil end
		for _,vehicle in ipairs(cars:GetChildren()) do
			local owner=vehicle:FindFirstChild("VehicleOwner")
			if owner and owner:IsA("ObjectValue") and owner.Value==player and vehicle.Name~=TARGET_NAME then return vehicle end
		end
	end
	local function getValidLink(vehicle)
		if not isMine(vehicle) then return nil end
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsDescendantOf(vehicle) then return humanoid.SeatPart end
		for _,container in ipairs({vehicle,character}) do
			for _,item in ipairs(container:GetDescendants()) do
				if isCharacterVehicleLink(item,vehicle) then return item end
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
		if not button or not button.Parent or type(firesignal)~="function" then return false end
		return pcall(function() firesignal(button.MouseButton1Click) end)
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
		RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait(); task.wait(0.10)
		if not click(vehicleButton) then return nil,nil,"No se pudo abrir Vehículos" end
		local deadline=os.clock()+GUI_TIMEOUT
		repeat
			button,scroll=findButton()
			if button then return button,scroll end
			task.wait(0.05)
		until os.clock()>=deadline
		return nil,nil,TARGET_NAME.." no apareció en Vehículos"
	end
	local function togglePatin(generation)
		if Core.Busy then return false,"busy" end
		Core.Busy=true
		local button,scroll,err=initializeVehicleMenu()
		if not button then Core.Busy=false; return false,err end
		showParents(button); scrollTo(scroll,button)
		if generation~=Core.Generation then Core.Busy=false; return false,"cancelled" end
		local ok=click(button)
		Core.Busy=false
		return ok,ok and nil or "click_error"
	end
	local function waitForVehicle(expected,generation)
		local deadline=os.clock()+SPAWN_TIMEOUT
		repeat
			if generation~=Core.Generation then return false end
			if (getMine()~=nil)==expected then return true end
			task.wait(0.02)
		until os.clock()>=deadline
		return (getMine()~=nil)==expected
	end
	local function spawnPatin(generation)
		if getMine() then return true end
		local other=getOtherOwnedVehicle()
		if other then
			local _,scroll,err=initializeVehicleMenu()
			if not scroll then return false,err or "No se pudo abrir Vehículos" end
			local item=scroll:FindFirstChild(other.Name)
			local removeButton=item and item:FindFirstChild("Button")
			if not removeButton or not removeButton:IsA("GuiButton") then return false,"No apareció el botón del vehículo actual" end
			showParents(removeButton); scrollTo(scroll,removeButton)
			if not click(removeButton) then return false,"No se pudo retirar el vehículo actual" end
			local deadline=os.clock()+SPAWN_TIMEOUT
			while generation==Core.Generation and os.clock()<deadline and other.Parent do task.wait(0.03) end
			if other.Parent then return false,"El servidor no retiró el vehículo actual" end
		end
		local ok,reason=togglePatin(generation)
		if not ok then return false,reason end
		if not waitForVehicle(true,generation) then return false,"spawn_no_confirmado" end
		return true
	end
	local function removePatin(generation)
		if not getMine() then return true end
		local ok,reason=togglePatin(generation)
		if not ok then return false,reason end
		if not waitForVehicle(false,generation) then return false,"remove_no_confirmado" end
		return true
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
				if not vehicle then
					Core.LastPatin=nil
					local ok,reason=spawnPatin(generation)
					if not ok and reason~="busy" and reason~="cancelled" then Core.Failures+=1; task.wait(retryDelay()) end
				else
					Core.Failures=0
					task.wait(WATCH_INTERVAL)
				end
			end
			Core.WorkerRunning=false
			if Core.Enabled then task.defer(startWorker) end
		end)
	end
	function Core:AllowsSeat(humanoid)
		if not self.Enabled then return false end
		local vehicle=getMine()
		if not vehicle then return false end
		if humanoid and humanoid.SeatPart then return humanoid.SeatPart:IsDescendantOf(vehicle) end
		return true
	end
	function Core:IsAttachGraceActive() return self.Enabled and self.Busy end
	function Core:Start()
		if self.Enabled then return true end
		self.Enabled=true; self.Generation+=1; self.Failures=0
		startWorker()
		return true
	end
	function Core:Stop(removeVehicle)
		self.Enabled=false; self.Generation+=1
		local generation=self.Generation
		while self.Busy do task.wait() end
		if removeVehicle then removePatin(generation) end
		self.LastPatin=nil
		return true
	end
	function Core:Destroy() return self:Stop(false) end
	AnchorTestSkateDelta=Core
	return true
end
