-- Control de vuelo integrado. No crea GUI independiente.
return function(context)
	setfenv(1,context)
	local Workspace=game:GetService("Workspace")
	local Flight={NormalSpeed=80,SprintSpeed=400,Flying=false,Braking=false,SprintExternal=false,Velocity=Vector3.zero,Position=nil,CameraYaw=0,CameraPitch=0,CameraDistance=12,CameraTouch=nil,CameraLastTouch=nil,SavedCameraType=nil,SavedCameraSubject=nil,DesktopRotating=false,SavedMouseBehavior=nil,SavedMouseIconEnabled=nil}
	local keys={W=false,S=false,A=false,D=false,Up=false,Down=false}
	local mobile={Forward=false,Backward=false,Left=false,Right=false,Up=false,Down=false}
	local connections={}
	local heartbeat,cameraRender
	local function character()
		local c=player.Character
		return c,c and c:FindFirstChild("HumanoidRootPart"),c and c:FindFirstChildOfClass("Humanoid")
	end
	local function moving()
		return keys.W or keys.S or keys.A or keys.D or keys.Up or keys.Down or mobile.Forward or mobile.Backward or mobile.Left or mobile.Right or mobile.Up or mobile.Down
	end
	local function mobileFlightMode()
		local ok,platform=pcall(function() return UserInputService:GetPlatform() end)
		if ok then
			if platform==Enum.Platform.Android or platform==Enum.Platform.IOS then return true end
			if platform==Enum.Platform.Windows or platform==Enum.Platform.OSX then return false end
		end
		return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
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
		if root then self.Position=root.Position; root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end
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
		if not hasManualHorizontal and mobileFlightMode() and humanoid and humanoid.MoveDirection.Magnitude>0.05 then
			local move=humanoid.MoveDirection
			local flatLook=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
			local flatRight=Vector3.new(camera.CFrame.RightVector.X,0,camera.CFrame.RightVector.Z)
			if flatLook.Magnitude>0.001 and flatRight.Magnitude>0.001 then
				local forwardAmount=move:Dot(flatLook.Unit)
				local rightAmount=move:Dot(flatRight.Unit)
				d+=camera.CFrame.LookVector*forwardAmount+camera.CFrame.RightVector*rightAmount
			else
				d+=move
			end
		end
		return d.Magnitude>0 and d.Unit or d
	end
	local function pointerOverOwnGui(position)
		local playerGui=player:FindFirstChildOfClass("PlayerGui")
		if not playerGui then return false end
		local ok,objects=pcall(function() return playerGui:GetGuiObjectsAtPosition(position.X,position.Y) end)
		if not ok then return false end
		for _,object in ipairs(objects) do
			if not gui or object:IsDescendantOf(gui) then
				local current=object
				while current and current~=playerGui do
					if current:IsA("GuiButton") or current:IsA("TextBox") or current:IsA("ScrollingFrame") then return true end
					current=current.Parent
				end
			end
		end
		return false
	end
	function Flight:EnableMobileCamera(root,humanoid)
		local camera=Workspace.CurrentCamera;if not camera then return end
		self.SavedCameraType=camera.CameraType;self.SavedCameraSubject=camera.CameraSubject
		if not mobileFlightMode() then
			self.SavedMouseBehavior=UserInputService.MouseBehavior
			self.SavedMouseIconEnabled=UserInputService.MouseIconEnabled
		end
		local focus=root.Position+Vector3.new(0,2,0)
		local offset=camera.CFrame.Position-focus
		self.CameraDistance=math.clamp(offset.Magnitude,6,24)
		local look=camera.CFrame.LookVector
		self.CameraYaw=math.atan2(-look.X,-look.Z)
		self.CameraPitch=math.clamp(math.asin(look.Y),math.rad(-85),math.rad(85))
		camera.CameraType=Enum.CameraType.Scriptable
		if cameraRender then cameraRender:Disconnect() end
		cameraRender=RunService.RenderStepped:Connect(function()
			if not self.Flying then return end
			local _,currentRoot=character();camera=Workspace.CurrentCamera
			if not currentRoot or not camera then return end
			camera.CameraType=Enum.CameraType.Scriptable
			local target=currentRoot.Position+Vector3.new(0,2,0)
			local rotation=CFrame.fromOrientation(self.CameraPitch,self.CameraYaw,0)
			local cameraPosition=target-rotation.LookVector*self.CameraDistance
			camera.CFrame=CFrame.lookAt(cameraPosition,target,Vector3.yAxis)
			camera.Focus=CFrame.new(target)
		end)
	end
	function Flight:DisableMobileCamera()
		if cameraRender then cameraRender:Disconnect();cameraRender=nil end
		self.CameraTouch=nil;self.CameraLastTouch=nil;self.DesktopRotating=false
		if self.SavedMouseBehavior then UserInputService.MouseBehavior=self.SavedMouseBehavior end
		if self.SavedMouseIconEnabled~=nil then UserInputService.MouseIconEnabled=self.SavedMouseIconEnabled end
		local camera=Workspace.CurrentCamera
		if camera then
			camera.CameraType=self.SavedCameraType or Enum.CameraType.Custom
			if self.SavedCameraSubject and self.SavedCameraSubject.Parent then camera.CameraSubject=self.SavedCameraSubject
			else local _,_,humanoid=character();if humanoid then camera.CameraSubject=humanoid end end
		end
		self.SavedCameraType=nil;self.SavedCameraSubject=nil;self.SavedMouseBehavior=nil;self.SavedMouseIconEnabled=nil
	end
	function Flight:Start()
		if self.Flying then return true end
		local _,root,humanoid=character()
		if not root or not humanoid then return false,isES and "Tu personaje no está disponible." or "Your character is unavailable." end
		self.Flying=true; self.Braking=false; self.Velocity=Vector3.zero; self.Position=root.Position
		humanoid.PlatformStand=true; humanoid.AutoRotate=false
		root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
		self:EnableMobileCamera(root,humanoid)
		if heartbeat then heartbeat:Disconnect() end
		heartbeat=RunService.Heartbeat:Connect(function(dt)
			if not self.Flying then return end
			local _,r,h=character(); local camera=Workspace.CurrentCamera
			if not r or not h or not camera then return end
			h.PlatformStand=true; h.AutoRotate=false
			if mobileFlightMode() and h.MoveDirection.Magnitude>0.05 then self.Braking=false end
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
		self.Flying=false; self.Braking=false; self.SprintExternal=false; self.Velocity=Vector3.zero; self.Position=nil
		if heartbeat then heartbeat:Disconnect(); heartbeat=nil end
		self:DisableMobileCamera()
		self:ClearMobileInput(); for k in pairs(keys) do keys[k]=false end
		local _,root,humanoid=character()
		if root then root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero end
		if humanoid then humanoid.PlatformStand=false; humanoid.AutoRotate=true end
	end
	local function setKey(input,value)
		local key=input.KeyCode
		if key==Enum.KeyCode.W then keys.W=value elseif key==Enum.KeyCode.S then keys.S=value elseif key==Enum.KeyCode.A then keys.A=value elseif key==Enum.KeyCode.D then keys.D=value elseif key==Enum.KeyCode.Space then keys.Up=value elseif key==Enum.KeyCode.LeftControl or key==Enum.KeyCode.C then keys.Down=value elseif key==Enum.KeyCode.LeftShift then keys.Sprint=value end
		if value then Flight.Braking=false end
	end
	connections[#connections+1]=UserInputService.TouchStarted:Connect(function(touch,processed)
		if not Flight.Flying or not mobileFlightMode() or Flight.CameraTouch then return end
		local camera=Workspace.CurrentCamera;if not camera or touch.Position.X<camera.ViewportSize.X*0.34 or pointerOverOwnGui(touch.Position) then return end
		Flight.CameraTouch=touch;Flight.CameraLastTouch=touch.Position
	end)
	connections[#connections+1]=UserInputService.TouchMoved:Connect(function(touch)
		if not Flight.Flying or not mobileFlightMode() or touch~=Flight.CameraTouch or not Flight.CameraLastTouch then return end
		local delta=touch.Position-Flight.CameraLastTouch;Flight.CameraLastTouch=touch.Position
		Flight.CameraYaw-=delta.X*0.0065
		Flight.CameraPitch=math.clamp(Flight.CameraPitch-delta.Y*0.0065,math.rad(-85),math.rad(85))
	end)
	connections[#connections+1]=UserInputService.TouchEnded:Connect(function(touch)
		if touch==Flight.CameraTouch then Flight.CameraTouch=nil;Flight.CameraLastTouch=nil end
	end)
	connections[#connections+1]=UserInputService.InputBegan:Connect(function(input,processed)
		if Flight.Flying and not mobileFlightMode() and input.UserInputType==Enum.UserInputType.MouseButton2 and not pointerOverOwnGui(input.Position) then
			Flight.DesktopRotating=true
			UserInputService.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition
			UserInputService.MouseIconEnabled=false
			return
		end
		if not processed then setKey(input,true) end
	end)
	connections[#connections+1]=UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton2 then
			Flight.DesktopRotating=false
			if Flight.Flying and not mobileFlightMode() then
				UserInputService.MouseBehavior=Enum.MouseBehavior.Default
				UserInputService.MouseIconEnabled=true
			end
		end
		setKey(input,false)
	end)
	connections[#connections+1]=UserInputService.InputChanged:Connect(function(input)
		if not Flight.Flying or mobileFlightMode() or not Flight.DesktopRotating then return end
		if input.UserInputType==Enum.UserInputType.MouseMovement then
			local delta=input.Delta
			Flight.CameraYaw-=delta.X*0.0045
			Flight.CameraPitch=math.clamp(Flight.CameraPitch-delta.Y*0.0045,math.rad(-85),math.rad(85))
		end
	end)
	connections[#connections+1]=player.CharacterAdded:Connect(function() if Flight.Flying then task.wait(0.5); Flight:Stop() end end)
	function Flight:Destroy() self:Stop(); for _,c in ipairs(connections) do c:Disconnect() end; table.clear(connections) end
	FlightController=Flight
	return true
end