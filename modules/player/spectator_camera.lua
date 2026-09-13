-- Camara orbital integrada. No crea GUI independiente.
return function(context)
	setfenv(1,context)
	local Workspace=game:GetService("Workspace")
	local Spectator={Target=nil,Active=false,Yaw=0,Pitch=math.rad(-10),Distance=12,TargetDistance=12}
	local connections={}; local renderConnection; local rotating=false; local activeTouch; local lastTouch
	local function root(p) local c=p and p.Character; return c and c:FindFirstChild("HumanoidRootPart") end
	local function humanoid(p) local c=p and p.Character; return c and c:FindFirstChildOfClass("Humanoid") end
	function Spectator:GetTargetOptions() local t={} for _,p in ipairs(Players:GetPlayers()) do if p~=player then t[#t+1]=p end end return t end
	function Spectator:SetTarget(p) if p==player then return false end self.Target=typeof(p)=="Instance" and p:IsA("Player") and p or nil; return self.Target~=nil end
	function Spectator:GetTarget() return self.Target end
	function Spectator:IsActive() return self.Active end
	function Spectator:SetZoom(v) self.TargetDistance=math.clamp(tonumber(v) or 12,3,80); return self.TargetDistance end
	function Spectator:GetZoom() return self.TargetDistance end
	function Spectator:ZoomIn(v) return self:SetZoom(self.TargetDistance-(v or 2)) end
	function Spectator:ZoomOut(v) return self:SetZoom(self.TargetDistance+(v or 2)) end
	function Spectator:SetRotation(y,p) if y then self.Yaw=math.rad(y) end; if p then self.Pitch=math.clamp(math.rad(p),math.rad(-80),math.rad(80)) end end
	function Spectator:AddRotation(y,p) self.Yaw+=math.rad(y or 0); self.Pitch=math.clamp(self.Pitch+math.rad(p or 0),math.rad(-80),math.rad(80)) end
	function Spectator:Stop()
		self.Active=false; rotating=false; activeTouch=nil; lastTouch=nil
		if renderConnection then renderConnection:Disconnect(); renderConnection=nil end
		pcall(function() UserInputService.MouseBehavior=Enum.MouseBehavior.Default end)
		local camera=Workspace.CurrentCamera
		if camera then camera.CameraType=Enum.CameraType.Custom; local h=humanoid(player); if h then camera.CameraSubject=h end end
	end
	function Spectator:Start(target)
		if target then self:SetTarget(target) end
		if not self.Target or self.Target==player then return false,isES and "Selecciona otro jugador." or "Select another player." end
		local camera=Workspace.CurrentCamera
		if not camera then return false,isES and "La cámara no está disponible." or "Camera is unavailable." end
		if renderConnection then renderConnection:Disconnect() end
		self.Active=true; camera.CameraType=Enum.CameraType.Scriptable; self.TargetDistance=self.Distance
		renderConnection=RunService.RenderStepped:Connect(function(dt)
			if not self.Active then return end
			camera=Workspace.CurrentCamera; local r=root(self.Target)
			if not camera or not r then return end
			self.Distance+=(self.TargetDistance-self.Distance)*(1-math.exp(-12*dt))
			local targetPos=r.Position+Vector3.new(0,2,0)
			local rotation=CFrame.Angles(0,self.Yaw,0)*CFrame.Angles(self.Pitch,0,0)
			local cameraPos=targetPos+rotation:VectorToWorldSpace(Vector3.new(0,0,self.Distance))
			camera.CFrame=CFrame.lookAt(cameraPos,targetPos); camera.Focus=CFrame.new(targetPos)
		end)
		return true
	end
	connections[#connections+1]=UserInputService.InputBegan:Connect(function(input)
			if Spectator.Active and input.UserInputType==Enum.UserInputType.MouseButton2 then rotating=true; pcall(function() UserInputService.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition end) end
	end)
	connections[#connections+1]=UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton2 then rotating=false; pcall(function() UserInputService.MouseBehavior=Enum.MouseBehavior.Default end) end end)
	connections[#connections+1]=UserInputService.InputChanged:Connect(function(input)
		if not Spectator.Active then return end
		if rotating and input.UserInputType==Enum.UserInputType.MouseMovement then Spectator.Yaw-=input.Delta.X*0.006; Spectator.Pitch=math.clamp(Spectator.Pitch-input.Delta.Y*0.006,math.rad(-80),math.rad(80)) end
		if input.UserInputType==Enum.UserInputType.MouseWheel then if input.Position.Z>0 then Spectator:ZoomIn(math.abs(input.Position.Z)*2) elseif input.Position.Z<0 then Spectator:ZoomOut(math.abs(input.Position.Z)*2) end end
	end)
	connections[#connections+1]=UserInputService.TouchStarted:Connect(function(touch) if Spectator.Active and not activeTouch then activeTouch=touch; lastTouch=touch.Position end end)
	connections[#connections+1]=UserInputService.TouchMoved:Connect(function(touch)
		if Spectator.Active and touch==activeTouch and lastTouch then local d=touch.Position-lastTouch; lastTouch=touch.Position; Spectator.Yaw-=d.X*0.007; Spectator.Pitch=math.clamp(Spectator.Pitch-d.Y*0.007,math.rad(-80),math.rad(80)) end
	end)
	connections[#connections+1]=UserInputService.TouchEnded:Connect(function(touch) if touch==activeTouch then activeTouch=nil; lastTouch=nil end end)
	connections[#connections+1]=Players.PlayerRemoving:Connect(function(p) if Spectator.Target==p then Spectator:Stop(); Spectator.Target=nil; if UpdateCameraControlPanel then UpdateCameraControlPanel() end end end)
	function Spectator:Destroy() self:Stop(); for _,c in ipairs(connections) do c:Disconnect() end; table.clear(connections) end
	SpectatorController=Spectator
	return true
end