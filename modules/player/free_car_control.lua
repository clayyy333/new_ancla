-- Control libre de auto integrado. No crea GUI independiente.
return function(context)
	setfenv(1,context)
	local Workspace=game:GetService("Workspace")
	local Camera=Workspace.CurrentCamera
	local Core={Running=false,Car=nil,CarName=nil,BV=nil,Speed=120,BoostMultiplier=2.2,TiltResponse=16,LastOwnershipAttempt=0,Boost=false,CamYaw=0,CamPitch=-10,CameraDrag=false,Keys={Forward=false,Back=false,Left=false,Right=false},Mobile={Forward=false,Back=false,Left=false,Right=false},SavedAnchored={},SavedCharacterAnchored={},Status=nil}
	local heartbeat,cameraConnection,ancestryConnection
	local connections={}
	local function findRoot(model)
		if not model then return nil end
		if model:IsA("BasePart") then return model end
		if model.PrimaryPart then return model.PrimaryPart end
		for _,name in ipairs({"Body","Chassis","VehicleSeat","DriveSeat","Seat","WheelB","W"}) do local part=model:FindFirstChild(name,true); if part and part:IsA("BasePart") then return part end end
		for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") and not part.Anchored then return part end end
		for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then return part end end
	end
	local function eachPart(model,callback)
		if model:IsA("BasePart") then callback(model); return end
		for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then callback(part) end end
	end
	local function isMyCar(car)
		local points=Workspace:FindFirstChild("CarSpawnPoints")
		local spawn=car and points and points:FindFirstChild(player.Name.."_"..car.Name)
		local owner=spawn and spawn:FindFirstChild("Owner")
		return owner and owner:IsA("StringValue") and owner.Value==player.Name
	end
	local function listCars()
		local result,seenNames={},{}
		local cars=Workspace:FindFirstChild("Cars")
		if not cars or not Workspace:FindFirstChild("CarSpawnPoints") then return result end
		local children=cars:GetChildren()
		for index=#children,1,-1 do local car=children[index]; if not seenNames[car.Name] and isMyCar(car) and findRoot(car) then seenNames[car.Name]=true; result[#result+1]=car end end
		table.sort(result,function(a,b) return a.Name<b.Name end)
		return result
	end
	local function clearMotion(car)
		if car then eachPart(car,function(part) part.AssemblyLinearVelocity=Vector3.zero; part.AssemblyAngularVelocity=Vector3.zero end) end
	end
	function Core:GetCarOptions() return listCars() end
	function Core:SetCar(car) self.Car=car; self.CarName=car and car.Name or nil; return car~=nil end
	function Core:GetCar()
		if self.Running then return self.Car end
		if not self.CarName then return nil end
		for _,car in ipairs(listCars()) do if car.Name==self.CarName then self.Car=car; return car end end
		self.Car=nil; return nil
	end
	function Core:IsRunning() return self.Running end
	function Core:GetSpeed() return self.Speed end
	function Core:SetSpeed(value) self.Speed=math.clamp(tonumber(value) or self.Speed,40,400); return self.Speed end
	function Core:ChangeSpeed(amount) return self:SetSpeed(self.Speed+amount) end
	function Core:GetTiltResponse() return self.TiltResponse end
	function Core:SetTiltResponse(value) self.TiltResponse=math.clamp(tonumber(value) or self.TiltResponse,4,30); return self.TiltResponse end
	function Core:ChangeTiltResponse(amount) return self:SetTiltResponse(self.TiltResponse+amount) end
	function Core:SetBoost(enabled) self.Boost=enabled==true end
	function Core:SetMobileDirection(direction,enabled) if self.Mobile[direction]==nil then return false end; self.Mobile[direction]=enabled==true; return true end
	function Core:RotateCamera(delta) if not self.Running then return end; self.CamYaw-=delta.X*0.18; self.CamPitch=math.clamp(self.CamPitch-delta.Y*0.18,-80,80) end
	function Core:BeginCameraDrag() if self.Running then self.CameraDrag=true; return true end; return false end
	function Core:EndCameraDrag() self.CameraDrag=false end
	function Core:DestroyForce() if self.BV then pcall(function() self.BV:Destroy() end); self.BV=nil end end
	function Core:CreateForce(root)
		self:DestroyForce(); local body=Instance.new("BodyVelocity"); body.Name="VexroCarFreeControl"; body.MaxForce=Vector3.new(1e6,1e6,1e6); body.P=5000; body.Velocity=Vector3.zero; body.Parent=root; self.BV=body
	end
	function Core:PrepareCar(car)
		self.SavedAnchored={}; eachPart(car,function(part) self.SavedAnchored[part]=part.Anchored; part.Anchored=false; pcall(function() part:SetNetworkOwner(player) end) end)
	end
	function Core:RestoreCarAnchors() for part,value in pairs(self.SavedAnchored) do if part and part.Parent then part.Anchored=value end end; self.SavedAnchored={} end
	function Core:AnchorCharacter()
		self.SavedCharacterAnchored={}; local character=player.Character; if not character then return end
		for _,part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then self.SavedCharacterAnchored[part]=part.Anchored; part.Anchored=true end end
	end
	function Core:RestoreCharacter() for part,value in pairs(self.SavedCharacterAnchored) do if part and part.Parent then part.Anchored=value end end; self.SavedCharacterAnchored={} end
	function Core:StartCamera(root)
		Camera=Workspace.CurrentCamera; if not Camera then return false end
		self.SavedCameraType=Camera.CameraType; self.SavedCameraSubject=Camera.CameraSubject; self.SavedMouseBehavior=UserInputService.MouseBehavior; self.SavedMouseIconEnabled=UserInputService.MouseIconEnabled
		local _,yaw=root.CFrame:ToOrientation(); self.CamYaw=math.deg(yaw); self.CamPitch=-10
		Camera.CameraType=Enum.CameraType.Scriptable; UserInputService.MouseBehavior=Enum.MouseBehavior.Default; UserInputService.MouseIconEnabled=true
		cameraConnection=RunService.RenderStepped:Connect(function()
			if not self.Running then return end; local currentRoot=findRoot(self.Car); Camera=Workspace.CurrentCamera; if not currentRoot or not Camera then return end
			local rotation=CFrame.fromOrientation(math.rad(self.CamPitch),math.rad(self.CamYaw),0); local look=rotation.LookVector; local focus=currentRoot.Position+Vector3.new(0,2,0); local cameraPosition=focus-look*16+Vector3.new(0,5,0)
			Camera.CFrame=CFrame.lookAt(cameraPosition,focus+look*8); Camera.Focus=CFrame.new(focus)
		end)
		return true
	end
	function Core:StopCamera()
		if cameraConnection then cameraConnection:Disconnect(); cameraConnection=nil end
		Camera=Workspace.CurrentCamera
		if Camera then Camera.CameraType=self.SavedCameraType or Enum.CameraType.Custom; if self.SavedCameraSubject and self.SavedCameraSubject.Parent then Camera.CameraSubject=self.SavedCameraSubject else local character=player.Character; local humanoid=character and character:FindFirstChildOfClass("Humanoid"); if humanoid then Camera.CameraSubject=humanoid end end end
		UserInputService.MouseBehavior=self.SavedMouseBehavior or Enum.MouseBehavior.Default; if self.SavedMouseIconEnabled~=nil then UserInputService.MouseIconEnabled=self.SavedMouseIconEnabled end
	end
	function Core:Start()
		if self.Running then return true end
		if CarControlController then CarControlController:SetAutoEnabled(false); if CarControlController:IsRunning() then CarControlController:Stop(true) end end
		if SpectatorController and SpectatorController:IsActive() then SpectatorController:Stop() end; if FlightController and FlightController:IsFlying() then FlightController:Stop() end
		local car=self:GetCar(); if not car or not car.Parent or not isMyCar(car) then return false,isES and "Selecciona un vehículo propio." or "Select an owned vehicle." end
		local root=findRoot(car); if not root then return false,isES and "El vehículo no tiene una pieza física utilizable." or "The vehicle has no usable physical part." end
		self.Car=car; self.Running=true; self.LastOwnershipAttempt=0; self.Status=nil; self:PrepareCar(car); self:AnchorCharacter(); self:StartCamera(root); self:CreateForce(root)
		ancestryConnection=car.AncestryChanged:Connect(function(_,parent) if self.Running and (not parent or not car:IsDescendantOf(Workspace)) then self.Status=isES and "El vehículo desapareció." or "The vehicle disappeared."; self:Stop() end end)
		heartbeat=RunService.Heartbeat:Connect(function(dt)
			if not self.Running then return end; local current=self.Car; local r=current and findRoot(current); Camera=Workspace.CurrentCamera
			if not current or not current.Parent or not r or not Camera then self:Stop(); return end
			if not self.BV or self.BV.Parent~=r then self:CreateForce(r) end
			if os.clock()-self.LastOwnershipAttempt>=0.5 then self.LastOwnershipAttempt=os.clock(); pcall(function() r:SetNetworkOwner(player) end) end
			local look,right=Camera.CFrame.LookVector,Camera.CFrame.RightVector
			local forward=((self.Keys.Forward or self.Mobile.Forward) and 1 or 0)-((self.Keys.Back or self.Mobile.Back) and 1 or 0)
			local side=((self.Keys.Right or self.Mobile.Right) and 1 or 0)-((self.Keys.Left or self.Mobile.Left) and 1 or 0)
			local velocity=Vector3.zero; local direction=look*forward+right*side
			if direction.Magnitude>0.001 then velocity=direction.Unit*self.Speed*(self.Boost and self.BoostMultiplier or 1) end
			self.BV.Velocity=self.BV.Velocity:Lerp(velocity,1-math.exp(-10*dt)); self.BV.MaxForce=Vector3.new(1e6,1e6,1e6)
			local flat=Vector3.new(look.X,0,look.Z)
			if flat.Magnitude>0.05 then local desired=CFrame.lookAt(r.Position,r.Position+look,Vector3.yAxis); r.CFrame=r.CFrame:Lerp(desired,1-math.exp(-self.TiltResponse*dt)) end
			r.AssemblyAngularVelocity=Vector3.zero
		end)
		return true
	end
	function Core:Stop()
		self.Running=false; self.Boost=false; self.CameraDrag=false
		if heartbeat then heartbeat:Disconnect(); heartbeat=nil end; if ancestryConnection then ancestryConnection:Disconnect(); ancestryConnection=nil end
		self:DestroyForce(); clearMotion(self.Car); self:RestoreCarAnchors(); self:StopCamera(); self:RestoreCharacter()
		for key in pairs(self.Keys) do self.Keys[key]=false end; for key in pairs(self.Mobile) do self.Mobile[key]=false end
	end
	local function setKey(code,value)
		if code==Enum.KeyCode.W or code==Enum.KeyCode.Up then Core.Keys.Forward=value elseif code==Enum.KeyCode.S or code==Enum.KeyCode.Down then Core.Keys.Back=value elseif code==Enum.KeyCode.A or code==Enum.KeyCode.Left then Core.Keys.Left=value elseif code==Enum.KeyCode.D or code==Enum.KeyCode.Right then Core.Keys.Right=value elseif code==Enum.KeyCode.LeftShift then Core:SetBoost(value) end
	end
	connections[#connections+1]=UserInputService.InputBegan:Connect(function(input,processed) if not Core.Running then return end; if input.UserInputType==Enum.UserInputType.MouseButton2 then Core:BeginCameraDrag(); return end; if processed then return end; setKey(input.KeyCode,true) end)
	connections[#connections+1]=UserInputService.InputEnded:Connect(function(input) setKey(input.KeyCode,false); if input.UserInputType==Enum.UserInputType.MouseButton2 or input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then Core:EndCameraDrag() end end)
	connections[#connections+1]=UserInputService.InputChanged:Connect(function(input) if Core.Running and Core.CameraDrag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then Core:RotateCamera(input.Delta) end end)
	connections[#connections+1]=player.CharacterAdded:Connect(function() if Core.Running then task.wait(0.25); Core:Stop() end end)
	function Core:Destroy() self:Stop(); for _,connection in ipairs(connections) do connection:Disconnect() end; table.clear(connections) end
	FreeCarController=Core
	return true
end