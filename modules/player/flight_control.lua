-- Control de vuelo integrado. No crea GUI independiente.
return function(context)
	setfenv(1,context)
	local Workspace=game:GetService("Workspace")
	local Flight={NormalSpeed=80,SprintSpeed=400,Flying=false,Braking=false,SprintExternal=false,Velocity=Vector3.zero,Position=nil,VehicleSeat=nil,VehicleAttachment=nil,VehicleVelocity=nil,VehicleOrientation=nil,VehicleYaw=0}
	local keys={W=false,S=false,A=false,D=false,Up=false,Down=false}
	local mobile={Forward=false,Backward=false,Left=false,Right=false,Up=false,Down=false}
	local connections={}
	local heartbeat
	local function character()
		local c=player.Character
		return c,c and c:FindFirstChild("HumanoidRootPart"),c and c:FindFirstChildOfClass("Humanoid")
	end
	local function moving()
		return keys.W or keys.S or keys.A or keys.D or keys.Up or keys.Down or mobile.Forward or mobile.Backward or mobile.Left or mobile.Right or mobile.Up or mobile.Down
	end
	local function driverSeat(humanoid)
		local seat=humanoid and humanoid.SeatPart
		return seat and seat:IsA("VehicleSeat") and seat.Occupant==humanoid and seat or nil
	end
	function Flight:ClearVehicleFlight()
		for _,object in ipairs({self.VehicleVelocity,self.VehicleOrientation,self.VehicleAttachment}) do
			if object then pcall(function() object:Destroy() end) end
		end
		self.VehicleVelocity,self.VehicleOrientation,self.VehicleAttachment,self.VehicleSeat=nil,nil,nil,nil
	end
	function Flight:StartVehicleFlight(seat,humanoid)
		if not seat or seat.Anchored or (seat.AssemblyRootPart and seat.AssemblyRootPart.Anchored) then return false,isES and "El asiento del conductor no puede volar." or "The driver's seat cannot fly." end
		self:ClearVehicleFlight()
		local attachment=Instance.new("Attachment")
		attachment.Name="VexroFlightAttachment"
		attachment.Parent=seat
		local velocity=Instance.new("LinearVelocity")
		velocity.Name="VexroVehicleFlightVelocity"
		velocity.Attachment0=attachment
		velocity.RelativeTo=Enum.ActuatorRelativeTo.World
		velocity.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector
		velocity.ForceLimitsEnabled=true
		velocity.MaxForce=math.clamp(seat.AssemblyMass*Workspace.Gravity*12,50000,1000000000)
		velocity.VectorVelocity=Vector3.zero
		velocity.Parent=seat
		local orientation=Instance.new("AlignOrientation")
		orientation.Name="VexroVehicleFlightOrientation"
		orientation.Attachment0=attachment
		orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment
		orientation.MaxTorque=1000000000
		orientation.Responsiveness=25
		orientation.CFrame=seat.CFrame.Rotation
		orientation.Parent=seat
		local _,yaw=seat.CFrame:ToOrientation()
		self.VehicleSeat,self.VehicleAttachment,self.VehicleVelocity,self.VehicleOrientation,self.VehicleYaw=seat,attachment,velocity,orientation,yaw
		self.Velocity=Vector3.zero
		self.Position=nil
		humanoid.PlatformStand=false
		humanoid.AutoRotate=true
		return true
	end
	function Flight:StepVehicleFlight(dt,seat)
		local forward=(keys.W or mobile.Forward) and 1 or (keys.S or mobile.Backward) and -1 or seat.ThrottleFloat
		local turn=(keys.D or mobile.Right) and 1 or (keys.A or mobile.Left) and -1 or seat.SteerFloat
		local vertical=((keys.Up or mobile.Up) and 1 or 0)-((keys.Down or mobile.Down) and 1 or 0)
		self.VehicleYaw+=turn*math.rad(90)*dt
		local heading=CFrame.Angles(0,self.VehicleYaw,0)
		local direction=heading.LookVector*forward+Vector3.yAxis*vertical
		local target=direction.Magnitude>0 and direction.Unit*(self:IsSprinting() and self.SprintSpeed or self.NormalSpeed) or Vector3.zero
		self.Velocity=self.Velocity:Lerp(self.Braking and Vector3.zero or target,1-math.exp(-10*dt))
		if self.VehicleVelocity and self.VehicleVelocity.Parent==seat then self.VehicleVelocity.VectorVelocity=self.Velocity end
		if self.VehicleOrientation and self.VehicleOrientation.Parent==seat then self.VehicleOrientation.CFrame=heading end
	end
	function Flight:SetNormalSpeed(v) self.NormalSpeed=math.clamp(tonumber(v) or self.NormalSpeed,20,300); return self.NormalSpeed end
	function Flight:SetSprintSpeed(v) self.SprintSpeed=math.clamp(tonumber(v) or self.SprintSpeed,100,1000); return self.SprintSpeed end
	function Flight:GetNormalSpeed() return self.NormalSpeed end
	function Flight:GetSprintSpeed() return self.SprintSpeed end
	function Flight:IncreaseNormalSpeed() return self:SetNormalSpeed(self.NormalSpeed+20) end
	function Flight:DecreaseNormalSpeed() return self:SetNormalSpeed(self.NormalSpeed-20) end
	function Flight:IncreaseSprintSpeed() return self:SetSprintSpeed(self.SprintSpeed+50) end
	function Flight:DecreaseSprintSpeed() return self:SetSprintSpeed(self.SprintSpeed-50) end
	function Flight:SetSprint(v) self.SprintExternal=v==true end
	function Flight:IsSprinting() return keys.Sprint or self.SprintExternal end
	function Flight:IsFlying() return self.Flying end
	function Flight:SetMobileDirection(direction,enabled)
		if mobile[direction]==nil then return false end
		mobile[direction]=enabled==true
		if enabled then self.Braking=false end
		return true
	end
	function Flight:ClearMobileInput() for k in pairs(mobile) do mobile[k]=false end end
	function Flight:SoftStop() if self.Flying then self.Braking=true end end
	function Flight:FastStop()
		if not self.Flying then return end
		local _,root=character()
		self.Braking=true; self.Velocity=Vector3.zero
		if self.VehicleSeat then
			if self.VehicleVelocity then self.VehicleVelocity.VectorVelocity=Vector3.zero end
		elseif root then self.Position=root.Position; root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end
	end
	local function direction(camera,humanoid)
		local d=Vector3.zero
		if keys.W or mobile.Forward then d+=camera.CFrame.LookVector end
		if keys.S or mobile.Backward then d-=camera.CFrame.LookVector end
		if keys.A or mobile.Left then d-=camera.CFrame.RightVector end
		if keys.D or mobile.Right then d+=camera.CFrame.RightVector end
		if keys.Up or mobile.Up then d+=Vector3.yAxis end
		if keys.Down or mobile.Down then d-=Vector3.yAxis end
		local hasManualHorizontal=keys.W or keys.S or keys.A or keys.D or mobile.Forward or mobile.Backward or mobile.Left or mobile.Right
		if not hasManualHorizontal and UserInputService.TouchEnabled and humanoid and humanoid.MoveDirection.Magnitude>0.05 then
			d+=humanoid.MoveDirection
		end
		return d.Magnitude>0 and d.Unit or d
	end
	function Flight:Start()
		if self.Flying then return true end
		local _,root,humanoid=character()
		if not root or not humanoid then return false,isES and "Tu personaje no está disponible." or "Your character is unavailable." end
		local seat=driverSeat(humanoid)
		if seat then
			local ok,err=self:StartVehicleFlight(seat,humanoid)
			if not ok then return false,err end
		end
		self.Flying=true; self.Braking=false; self.Velocity=Vector3.zero; self.Position=root.Position
		if not seat then
			humanoid.PlatformStand=true; humanoid.AutoRotate=false
			root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
		end
		if heartbeat then heartbeat:Disconnect() end
		heartbeat=RunService.Heartbeat:Connect(function(dt)
			if not self.Flying then return end
			local _,r,h=character(); local camera=Workspace.CurrentCamera
			if not r or not h or not camera then return end
			if self.VehicleSeat then
				if driverSeat(h)~=self.VehicleSeat then self:Stop(); return end
				h.PlatformStand=false
				self:StepVehicleFlight(dt,self.VehicleSeat)
				return
			end
			local newSeat=driverSeat(h)
			if newSeat then
				local ok=self:StartVehicleFlight(newSeat,h)
				if not ok then self:Stop() end
				return
			end
			h.PlatformStand=true; h.AutoRotate=false
			if UserInputService.TouchEnabled and h.MoveDirection.Magnitude>0.05 then self.Braking=false end
			local d=self.Braking and Vector3.zero or direction(camera,h)
			local target=d*(self:IsSprinting() and self.SprintSpeed or self.NormalSpeed)
			local response=target.Magnitude>0 and (self:IsSprinting() and 18 or 8) or 14
			self.Velocity=self.Velocity:Lerp(target,1-math.exp(-response*dt))
			if not keys.Up and not keys.Down and not mobile.Up and not mobile.Down and d.Magnitude==0 then
				self.Velocity=Vector3.new(self.Velocity.X,self.Velocity.Y+(0-self.Velocity.Y)*(1-math.exp(-18*dt)),self.Velocity.Z)
			end
			if self.Velocity.Magnitude<0.01 then self.Velocity=Vector3.zero end
			self.Position+=self.Velocity*dt
			if self.Velocity.Magnitude>1 then
				local desired=CFrame.lookAt(self.Position,self.Position+self.Velocity.Unit)
				local current=CFrame.new(self.Position)*r.CFrame.Rotation
				r.CFrame=current:Lerp(desired,1-math.exp(-8*dt))
			else r.CFrame=CFrame.new(self.Position)*r.CFrame.Rotation end
			r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero
		end)
		return true
	end
	function Flight:Stop()
		local wasVehicle=self.VehicleSeat~=nil
		self.Flying=false; self.Braking=false; self.SprintExternal=false; self.Velocity=Vector3.zero; self.Position=nil
		if heartbeat then heartbeat:Disconnect(); heartbeat=nil end
		self:ClearVehicleFlight()
		self:ClearMobileInput(); for k in pairs(keys) do keys[k]=false end
		local _,root,humanoid=character()
		if root and not wasVehicle then root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end
		if humanoid then humanoid.PlatformStand=false; humanoid.AutoRotate=true end
	end
	local function setKey(input,value)
		local key=input.KeyCode
		if key==Enum.KeyCode.W then keys.W=value elseif key==Enum.KeyCode.S then keys.S=value elseif key==Enum.KeyCode.A then keys.A=value elseif key==Enum.KeyCode.D then keys.D=value elseif key==Enum.KeyCode.Space then keys.Up=value elseif key==Enum.KeyCode.LeftControl or key==Enum.KeyCode.C then keys.Down=value elseif key==Enum.KeyCode.LeftShift then keys.Sprint=value end
		if value then Flight.Braking=false end
	end
	connections[#connections+1]=UserInputService.InputBegan:Connect(function(input,processed) if not processed then setKey(input,true) end end)
	connections[#connections+1]=UserInputService.InputEnded:Connect(function(input) setKey(input,false) end)
	connections[#connections+1]=player.CharacterAdded:Connect(function() if Flight.Flying then task.wait(0.5); Flight:Stop() end end)
	function Flight:Destroy() self:Stop(); for _,c in ipairs(connections) do c:Disconnect() end; table.clear(connections) end
	FlightController=Flight
	return true
end