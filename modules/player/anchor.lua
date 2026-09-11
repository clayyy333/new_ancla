-- Sistema Ancla integrado. No crea GUI ni reproduce audio.
return function(context)
	setfenv(1,context)
	local Workspace=game:GetService("Workspace")
	local Core={AnclaEnabled=false,AntiSeatEnabled=false,HeartbeatEnabled=false,Checkpoint=nil,GuardianEnabled=false}
	local connections={}
	local alignPosition,alignAttachment
	local spawn=Workspace:FindFirstChild("SpawnLocation_city")
	local SafePos=spawn and spawn:FindFirstChild("SafePos")
	local ExceptionTrigger=spawn and spawn:FindFirstChild("ExceptionTrigger")
	local safeY=SafePos and SafePos.WorldPosition.Y or 15.7
	local TARGETS={"Babycar_a","Babycar_b","Babycar_c","Stretcher","FoldingTable_1","Folding_table_02"}

	local function refresh()
		if UpdateAnchorPanel then UpdateAnchorPanel() end
	end
	local function getRoot()
		local character=player.Character
		return character and character:FindFirstChild("HumanoidRootPart")
	end
	local function createAlignPosition(root)
		if alignPosition then return end
		alignAttachment=Instance.new("Attachment")
		alignAttachment.Name="AnclaAttachment"
		alignAttachment.Parent=root
		alignPosition=Instance.new("AlignPosition")
		alignPosition.Name="AnclaAlignPosition"
		alignPosition.Attachment0=alignAttachment
		alignPosition.Position=root.Position
		alignPosition.MaxForce=10000000
		alignPosition.Responsiveness=300
		alignPosition.RigidityEnabled=true
		alignPosition.Parent=root
	end
	local function destroyAlignPosition()
		if alignPosition then pcall(function() alignPosition:Destroy() end); alignPosition=nil end
		if alignAttachment then pcall(function() alignAttachment:Destroy() end); alignAttachment=nil end
	end
	local function isTarget(model)
		for _,name in ipairs(TARGETS) do if model.Name:find(name) then return true end end
		return false
	end
	local function antiSeat()
		if not Core.AntiSeatEnabled then return end
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then return end
		humanoid.Sit=false
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
		humanoid.PlatformStand=false
	end

	function Core:SetAncla(enabled)
		enabled=enabled and true or false
		if enabled==self.AnclaEnabled then return true end
		if enabled then
			local root=getRoot()
			if not root then return false,isES and "Tu personaje no está disponible." or "Your character is unavailable." end
			self.Checkpoint=root.CFrame
			self.GuardianEnabled=true
			createAlignPosition(root)
			self.AnclaEnabled=true
		else
			self.AnclaEnabled=false
			self.GuardianEnabled=false
			destroyAlignPosition()
		end
		refresh()
		return true
	end
	function Core:SetAntiSeat(enabled)
		self.AntiSeatEnabled=enabled and true or false
		refresh()
		return true
	end
	function Core:SetHeartbeat(enabled)
		self.HeartbeatEnabled=enabled and true or false
		refresh()
		return true
	end
	function Core:ToggleAncla() return self:SetAncla(not self.AnclaEnabled) end
	function Core:ToggleAntiSeat() return self:SetAntiSeat(not self.AntiSeatEnabled) end
	function Core:ToggleHeartbeat() return self:SetHeartbeat(not self.HeartbeatEnabled) end
	function Core:Destroy()
		self.AnclaEnabled,self.AntiSeatEnabled,self.HeartbeatEnabled,self.GuardianEnabled=false,false,false,false
		destroyAlignPosition()
		for _,connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
		table.clear(connections)
	end

	connections[#connections+1]=Workspace.DescendantAdded:Connect(function(obj)
		if not Core.AntiSeatEnabled or obj.Name~="SeatWeld" then return end
		local model=obj:FindFirstAncestorOfClass("Model")
		if model and isTarget(model) then pcall(function() obj:Destroy() end) end
	end)
	connections[#connections+1]=RunService.Stepped:Connect(function()
		if not Core.GuardianEnabled or not Core.Checkpoint then return end
		local root=getRoot()
		if not root then return end
		local pos=root.Position
		local distToCP=(pos-Core.Checkpoint.Position).Magnitude
		local distToTrigger=ExceptionTrigger and (pos-ExceptionTrigger.Position).Magnitude or 99999
		if distToTrigger<72 then
			root.CFrame=Core.Checkpoint
			root.AssemblyLinearVelocity=Vector3.new(0,135,0)
			root.AssemblyAngularVelocity=Vector3.zero
			return
		end
		if pos.Y<(Core.Checkpoint.Position.Y-7.2) then
			root.CFrame=Core.Checkpoint
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
		end
		if root.AssemblyLinearVelocity.Y< -98 then
			root.CFrame=CFrame.new(pos.X,Core.Checkpoint.Position.Y+14,pos.Z)
			root.AssemblyLinearVelocity=Vector3.new(0,110,0)
		end
		if distToCP>10.5 then root.CFrame=Core.Checkpoint end
	end)
	connections[#connections+1]=RunService.Heartbeat:Connect(function()
		if not Core.GuardianEnabled or not Core.Checkpoint then return end
		local root=getRoot()
		if not root then return end
		local velocity=root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity=Vector3.new(velocity.X*0.2,math.max(velocity.Y*0.08,-15),velocity.Z*0.2)
	end)
	connections[#connections+1]=RunService.RenderStepped:Connect(function()
		local root=getRoot()
		if Core.AnclaEnabled and root and Core.Checkpoint then
			root.CFrame=Core.Checkpoint
			root.Velocity=Vector3.zero
		end
		antiSeat()
	end)
	connections[#connections+1]=RunService.Heartbeat:Connect(function()
		if not Core.HeartbeatEnabled or not Core.AnclaEnabled then return end
		local root=getRoot()
		if root and Core.Checkpoint then
			root.CFrame=Core.Checkpoint
			root.Velocity=Vector3.zero
		end
	end)
	connections[#connections+1]=RunService.Stepped:Connect(function()
		if not Core.AnclaEnabled then return end
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or not Core.Checkpoint then return end
		root.CFrame=Core.Checkpoint
		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
		humanoid.Sit=false
		humanoid.PlatformStand=false
	end)
	local CUPULA=1.1
	connections[#connections+1]=RunService.RenderStepped:Connect(function()
		if not Core.AnclaEnabled then return end
		local root=getRoot()
		if root and Core.Checkpoint and (root.Position-Core.Checkpoint.Position).Magnitude>CUPULA then
			root.CFrame=Core.Checkpoint
		end
	end)
	connections[#connections+1]=RunService.Heartbeat:Connect(function()
		if not Core.AnclaEnabled then return end
		local root=getRoot()
		if root and Core.Checkpoint and root.Position.Y<(safeY-8) then root.CFrame=Core.Checkpoint end
	end)
	local MAX_DISTANCE=3.8
	connections[#connections+1]=RunService.Stepped:Connect(function()
		if not Core.AnclaEnabled then return end
		local root=getRoot()
		if not root or not Core.Checkpoint then return end
		if (root.Position-Core.Checkpoint.Position).Magnitude>MAX_DISTANCE then
			root.CFrame=Core.Checkpoint
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
		end
		if ExceptionTrigger and (root.Position-ExceptionTrigger.Position).Magnitude<70 then root.CFrame=Core.Checkpoint end
	end)

	AnchorCore=Core
	return true
end
