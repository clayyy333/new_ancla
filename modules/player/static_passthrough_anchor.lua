-- Independent copy of anchor.lua; selective bridge/phase protection adapted from mobile_anchor.lua v1.0.
return function(context)
	setfenv(1,context)
	local Workspace=game:GetService("Workspace")
	local Core={AnclaEnabled=false,AntiSeatEnabled=false,HeartbeatEnabled=false,TestEnabled=false,Checkpoint=nil,TestCheckpoint=nil,GuardianEnabled=false}
	local connections={}
	local alignPosition,alignAttachment
	local testRoot,testRootWasAnchored,testAttachment,testPosition,testOrientation
	local testRootConnections,testImmediateGuard={},false
	local testCollisions={}
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
	local function belongsToCharacter(instance,character)
		return instance and character and instance:IsDescendantOf(character)
	end
	local function externalLinkTouchesCharacter(link,character)
		if link:IsA("JointInstance") then
			local a,b=link.Part0,link.Part1
			return (belongsToCharacter(a,character) or belongsToCharacter(b,character))
				and not (belongsToCharacter(a,character) and belongsToCharacter(b,character))
		end
		if link:IsA("Constraint") then
			local a0,a1=link.Attachment0,link.Attachment1
			return (belongsToCharacter(a0,character) or belongsToCharacter(a1,character))
				and not (belongsToCharacter(a0,character) and belongsToCharacter(a1,character))
		end
		return false
	end
	local function removeExternalTestLinks(scanWorkspace)
		local character=player.Character
		if not character then return end
		local humanoid=character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Sit=false
			humanoid.PlatformStand=false
			pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false) end)
			local state=humanoid:GetState()
			if state==Enum.HumanoidStateType.Seated or state==Enum.HumanoidStateType.Physics
				or state==Enum.HumanoidStateType.Ragdoll or state==Enum.HumanoidStateType.FallingDown then
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
		for _,part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				for _,joint in ipairs(part:GetJoints()) do
					if joint.Name=="SeatWeld" or externalLinkTouchesCharacter(joint,character) then
						pcall(function() joint:Destroy() end)
					end
				end
			end
		end
		if scanWorkspace then
			for _,link in ipairs(Workspace:GetDescendants()) do
				if link.Name=="SeatWeld" then
					local p0=link:IsA("JointInstance") and link.Part0
					local p1=link:IsA("JointInstance") and link.Part1
					if belongsToCharacter(p0,character) or belongsToCharacter(p1,character) then
						pcall(function() link:Destroy() end)
					end
				elseif externalLinkTouchesCharacter(link,character) then
					pcall(function() link:Destroy() end)
				end
			end
		end
	end
	local function suppressTestCollisions()
		local character=player.Character
		if not character then return end
		for _,part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				if testCollisions[part]==nil then testCollisions[part]=part.CanCollide end
				part.CanCollide=false
			end
		end
	end
	local function restoreTestCollisions()
		for part,value in pairs(testCollisions) do
			if part and part.Parent then pcall(function() part.CanCollide=value end) end
		end
		table.clear(testCollisions)
	end
	local function cleanAllPhysics()
		local character=player.Character
		if not character then return end
		for _,part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity=Vector3.zero
				part.AssemblyAngularVelocity=Vector3.zero
				part.Velocity=Vector3.zero
				part.RotVelocity=Vector3.zero
			end
		end
	end
	local function destroyTestForces()
		if testPosition then pcall(function() testPosition:Destroy() end); testPosition=nil end
		if testOrientation then pcall(function() testOrientation:Destroy() end); testOrientation=nil end
		if testAttachment then pcall(function() testAttachment:Destroy() end); testAttachment=nil end
	end
	local function createTestForces(root)
		destroyTestForces()
		testAttachment=Instance.new("Attachment")
		testAttachment.Name="AnclaTestAttachment"
		testAttachment.Parent=root
		testPosition=Instance.new("AlignPosition")
		testPosition.Name="AnclaTestPosition"
		testPosition.Mode=Enum.PositionAlignmentMode.OneAttachment
		testPosition.Attachment0=testAttachment
		testPosition.Position=Core.TestCheckpoint.Position
		testPosition.MaxForce=1e12
		testPosition.MaxVelocity=math.huge
		testPosition.Responsiveness=200
		testPosition.RigidityEnabled=true
		testPosition.ApplyAtCenterOfMass=true
		testPosition.Parent=root
		testOrientation=Instance.new("AlignOrientation")
		testOrientation.Name="AnclaTestOrientation"
		testOrientation.Mode=Enum.OrientationAlignmentMode.OneAttachment
		testOrientation.Attachment0=testAttachment
		testOrientation.CFrame=Core.TestCheckpoint.Rotation
		testOrientation.MaxTorque=1e12
		testOrientation.MaxAngularVelocity=math.huge
		testOrientation.Responsiveness=200
		testOrientation.RigidityEnabled=true
		testOrientation.Parent=root
	end
	local function disconnectTestRootWatch()
		for _,connection in ipairs(testRootConnections) do
			pcall(function() connection:Disconnect() end)
		end
		table.clear(testRootConnections)
	end
	local function bindTestRootWatch(root)
		disconnectTestRootWatch()
		local function correctImmediately()
			if testImmediateGuard or not Core.TestEnabled or not Core.TestCheckpoint or testRoot~=root or not root.Parent then return end
			testImmediateGuard=true
			root.Anchored=false
			root.CFrame=Core.TestCheckpoint
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
			root.Velocity=Vector3.zero
			root.RotVelocity=Vector3.zero
			testImmediateGuard=false
		end
		testRootConnections[#testRootConnections+1]=root:GetPropertyChangedSignal("Anchored"):Connect(correctImmediately)
	end
	local function lockTestRoot(root)
		if not root then return end
		if testRoot~=root then
			if testRoot and testRoot.Parent then testRoot.Anchored=testRootWasAnchored==true end
			testRoot=root
			testRootWasAnchored=root.Anchored
		createTestForces(root)
		bindTestRootWatch(root)
		end
		root.Anchored=false
		if Core.TestCheckpoint then root.CFrame=Core.TestCheckpoint end
		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
		root.Velocity=Vector3.zero
		root.RotVelocity=Vector3.zero
	end
	local function unlockTestRoot()
		destroyTestForces()
		disconnectTestRootWatch()
		if testRoot and testRoot.Parent then
			testRoot.Anchored=testRootWasAnchored==true
			testRoot.AssemblyLinearVelocity=Vector3.zero
			testRoot.AssemblyAngularVelocity=Vector3.zero
		end
		testRoot=nil
		testRootWasAnchored=nil
	end
	local function testAntiSeat()
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		if AnchorTestSkateDelta and (AnchorTestSkateDelta:AllowsSeat(humanoid) or AnchorTestSkateDelta:IsAttachGraceActive()) then
			pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true) end)
			humanoid.PlatformStand=false
			return
		end
		pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false) end)
		humanoid.Sit=false
		humanoid.PlatformStand=false
		local state=humanoid:GetState()
		if state==Enum.HumanoidStateType.Seated or state==Enum.HumanoidStateType.Physics
			or state==Enum.HumanoidStateType.Ragdoll or state==Enum.HumanoidStateType.FallingDown then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	local function createAlignPosition(root)
		if alignPosition then return end
		alignAttachment=Instance.new("Attachment")
		alignAttachment.Name="AnclaAttachment"
		alignAttachment.Parent=root
		alignPosition=Instance.new("AlignPosition")
		alignPosition.Name="AnclaAlignPosition"
		alignPosition.Mode=Enum.PositionAlignmentMode.OneAttachment
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
	function Core:SetTest(enabled)
		enabled=enabled and true or false
		if enabled==self.TestEnabled then return true end
		if enabled then
			local root=getRoot()
			if not root then return false,isES and "Tu personaje no está disponible." or "Your character is unavailable." end
			if self.AnclaEnabled then self:SetAncla(false) end
			if self.AntiSeatEnabled then self:SetAntiSeat(false) end
			if self.HeartbeatEnabled then self:SetHeartbeat(false) end
			self.TestCheckpoint=root.CFrame
			if AnchorTestSkateDelta then AnchorTestSkateDelta:Start() end
			if AnchorTestAntiRam then AnchorTestAntiRam:Start() end
			self.TestEnabled=true
			lockTestRoot(root)
			testAntiSeat()
			cleanAllPhysics()
		else
			self.TestEnabled=false
			if AnchorTestAntiRam then AnchorTestAntiRam:Stop() end
			if AnchorTestSkateDelta then AnchorTestSkateDelta:Stop(true) end

			unlockTestRoot()
			local character=player.Character
			local humanoid=character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true) end) end
			self.TestCheckpoint=nil
		end
		refresh()
		return true
	end
	function Core:ToggleTest() return self:SetTest(not self.TestEnabled) end
	function Core:ToggleAncla() return self:SetAncla(not self.AnclaEnabled) end
	function Core:ToggleAntiSeat() return self:SetAntiSeat(not self.AntiSeatEnabled) end
	function Core:ToggleHeartbeat() return self:SetHeartbeat(not self.HeartbeatEnabled) end
	function Core:Destroy()
		self.AnclaEnabled,self.AntiSeatEnabled,self.HeartbeatEnabled,self.TestEnabled,self.GuardianEnabled=false,false,false,false,false
		destroyAlignPosition()
		unlockTestRoot()
		if AnchorTestAntiRam then AnchorTestAntiRam:Destroy() end
		if AnchorTestSkateDelta then AnchorTestSkateDelta:Destroy() end
		self.TestCheckpoint=nil
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true) end) end
		for _,connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
		table.clear(connections)
	end

	connections[#connections+1]=player.CharacterAdded:Connect(function(character)
		if not Core.TestEnabled or not Core.TestCheckpoint then return end
		local root=character:WaitForChild("HumanoidRootPart",10)
		if root and Core.TestEnabled then
			lockTestRoot(root)
			cleanAllPhysics()
			testAntiSeat()
		end
	end)
	do
		local ok,signal=pcall(function() return RunService.PreSimulation end)
		if ok and signal then
			connections[#connections+1]=signal:Connect(function()
				if not Core.TestEnabled or not Core.TestCheckpoint then return end
				lockTestRoot(getRoot())
				cleanAllPhysics()
				testAntiSeat()
			end)
		end
	end
	connections[#connections+1]=RunService.Stepped:Connect(function()
		if not Core.TestEnabled or not Core.TestCheckpoint then return end
		lockTestRoot(getRoot())
		cleanAllPhysics()
		testAntiSeat()
	end)
	do
		local ok,signal=pcall(function() return RunService.PostSimulation end)
		if ok and signal then
			connections[#connections+1]=signal:Connect(function()
				if not Core.TestEnabled or not Core.TestCheckpoint then return end
				lockTestRoot(getRoot())
				cleanAllPhysics()
				testAntiSeat()
			end)
		end
	end
	connections[#connections+1]=RunService.Heartbeat:Connect(function()
		if not Core.TestEnabled or not Core.TestCheckpoint then return end
		lockTestRoot(getRoot())
		cleanAllPhysics()
		testAntiSeat()
	end)
	connections[#connections+1]=RunService.RenderStepped:Connect(function()
		if not Core.TestEnabled or not Core.TestCheckpoint then return end
		lockTestRoot(getRoot())
		testAntiSeat()
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
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
			return
		end
		if pos.Y<(Core.Checkpoint.Position.Y-7.2) then
			root.CFrame=Core.Checkpoint
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
		end
		if root.AssemblyLinearVelocity.Y< -98 then
			root.CFrame=Core.Checkpoint
			root.AssemblyLinearVelocity=Vector3.zero
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


	local owners={[11739864999]="psychoo778",[11743514302]="ksablanca0",[11747901934]="psycho777oo"}
	Core.Running=false;Core.PhaseEnabled=false;Core.Distances={Left=4,Right=4,Up=4}
	Core.ShiftInterval=0.25
	local destinationProbe
	local function phaseStatus(message)
		if Core.PhaseStatus==message then return end
		Core.PhaseStatus=message
		if UpdateAnchorPanel then UpdateAnchorPanel() end
	end
	local random=Random.new()
	local nextShift,lastScan,bridgeUntil,index=0,0,0,1
	local pairsByPart={}
	local character,humanoid,seatState
	local function allowed() return owners[player.UserId] and string.lower(player.Name)==owners[player.UserId] end
	local function conflict()
		return (AnchorCore and (AnchorCore.AnclaEnabled or AnchorCore.AntiSeatEnabled or AnchorCore.HeartbeatEnabled or AnchorCore.TestEnabled))
			or (MobileAnchorCore and MobileAnchorCore:IsRunning()) or (MobileAnchorV11Core and MobileAnchorV11Core:IsRunning())
			or (AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy))
	end
	local function clean(force)
		for part,state in pairs(pairsByPart) do
			if force or not part.Parent or os.clock()>state.expires then
				for _,link in ipairs(state.links) do link:Destroy() end
				pairsByPart[part]=nil
			end
		end
	end
	-- Adapted from v1.0 phasePart/cleanupPhase with bounded, expiring pairs.
	local function phase(part)
		if not character or not part or not part:IsA("BasePart") or part:IsDescendantOf(character) or part.Anchored then return end
		if pairsByPart[part] then pairsByPart[part].expires=os.clock()+1.35;return end
		local count=0
		for _ in pairs(pairsByPart) do count=count+1 end
		if count>=24 then return end
		local state={links={},expires=os.clock()+1.35};pairsByPart[part]=state
		for _,body in ipairs(character:GetDescendants()) do
			if #state.links>=16 then break end
			if body:IsA("BasePart") then
				local link=Instance.new("NoCollisionConstraint")
				link.Name="StaticShiftNoCollision";link.Part0=body;link.Part1=part;link.Parent=body
				state.links[#state.links+1]=link
			end
		end
	end
	-- Structural bridge classification copied/adapted from v1.0 inspectBridge.
	local function inspect(link)
		if not Core.Running or not link.Parent or link:IsA("Motor6D") or link.Name=="AccessoryWeld" or link:IsA("NoCollisionConstraint") then return end
		local a,b
		if link:IsA("JointInstance") or link:IsA("WeldConstraint") then a,b=link.Part0,link.Part1
		elseif link:IsA("Constraint") then
			pcall(function()
				a=link.Attachment0 and link.Attachment0:FindFirstAncestorWhichIsA("BasePart")
				b=link.Attachment1 and link.Attachment1:FindFirstAncestorWhichIsA("BasePart")
			end)
		end
		if not a or not b then return end
		local insideA,insideB=a:IsDescendantOf(character),b:IsDescendantOf(character)
		if insideA==insideB then return end
		phase(insideA and b or a)
		pcall(function() link:Destroy() end)
		bridgeUntil=os.clock()+0.5
	end
	local function threat(part)
		if part.Anchored then return false end
		for _,other in ipairs(Players:GetPlayers()) do
			if other~=player and other.Character and part:IsDescendantOf(other.Character) then return true end
		end
		local node=part.Parent
		while node and node~=Workspace do
			if node.Name=="Cars" or node.Name=="ObjectPlaceFolder" then return true end
			node=node.Parent
		end
		return part.AssemblyLinearVelocity.Magnitude>24 or part.AssemblyAngularVelocity.Magnitude>9
	end
	local function scan()
		local root=getRoot()
		if not root then return end
		for _,item in ipairs(character:GetDescendants()) do
			if item:IsA("BasePart") then
				for _,joint in ipairs(item:GetJoints()) do inspect(joint) end
			elseif item:IsA("Attachment") then
				local ok,links=pcall(function()return item:GetConstraints()end)
				if ok then for _,link in ipairs(links) do inspect(link) end end
			end
		end
		local params=OverlapParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={character};params.MaxParts=80
		local ray=RaycastParams.new()
		ray.FilterType=Enum.RaycastFilterType.Exclude;ray.FilterDescendantsInstances={character}
		local support=Workspace:Raycast(root.Position,Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+2),0),ray)
		for _,part in ipairs(Workspace:GetPartBoundsInRadius(root.Position,12,params)) do
			if threat(part) then
				if not support or support.Instance~=part then phase(part) end
				for _,joint in ipairs(part:GetJoints()) do inspect(joint) end
			end
		end
	end
	local function commit(target)
		local root=getRoot()
		if not root then return end
		Core.Checkpoint=target
		if alignPosition then alignPosition.Position=target.Position end
		root.CFrame=target;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
	end
	local function destination(i)
		local c=Core.Center
		local right=Vector3.new(c.RightVector.X,0,c.RightVector.Z)
		right=right.Magnitude>0.001 and right.Unit or Vector3.new(1,0,0)
		return c+(i==2 and -right*Core.Distances.Left or i==3 and right*Core.Distances.Right or i==4 and Vector3.new(0,Core.Distances.Up,0) or Vector3.zero)
	end
	function Core:IsRunning()return self.Running end
	function Core:SetInterval(value)
		value=tonumber(value)
		if not allowed() or not value or value~=value or math.abs(value)==math.huge then return false end
		self.ShiftInterval=math.clamp(math.floor(value*20+0.5)/20,0.1,1)
		nextShift=os.clock()+self.ShiftInterval
		refresh();return true
	end
	function Core:SetDistance(axis,value)
		value=tonumber(value)
		if not allowed() or self.Distances[axis]==nil or not value or value~=value or math.abs(value)==math.huge then return false end
		self.Distances[axis]=math.clamp(value,0,10);refresh();return true
	end
	function Core:SetPhase(enabled)
		if not allowed() then return false end
		self.PhaseEnabled=enabled==true and self.Running;nextShift=os.clock()
		phaseStatus(nil)
		if not self.PhaseEnabled and self.Running then index=1;commit(self.Center) end
		refresh();return true
	end
	function Core:Start()
		if not allowed() then return false,isES and "Solo owners." or "Owners only." end
		if self.Running then return true end
		if conflict() then return false,isES and "Desactiva las otras anclas primero." or "Disable other anchors first." end
		character=player.Character;humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if not getRoot() or not humanoid or humanoid.Health<=0 then return false,isES and "Personaje no disponible." or "Character unavailable." end
		local ok,message=self:SetAncla(true);if not ok then return false,message end
		self.Center=self.Checkpoint;self.Running=true;self.PhaseEnabled=false;index=1
		seatState=humanoid:GetStateEnabled(Enum.HumanoidStateType.Seated)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
		self:SetAntiSeat(true);self:SetHeartbeat(true);refresh();return true
	end
	function Core:Stop()
		self.Running=false;self.PhaseEnabled=false
		phaseStatus(nil)
		if destinationProbe then destinationProbe:Destroy();destinationProbe=nil end
		self:SetHeartbeat(false);self:SetAntiSeat(false);self:SetAncla(false);clean(true)
		if humanoid and humanoid.Parent and seatState~=nil then humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,seatState) end
		character=nil;humanoid=nil;seatState=nil;self.Center=nil;self.Checkpoint=nil
		refresh();return true
	end
	function Core:Toggle()if self.Running then return self:Stop()end;return self:Start()end
	function Core:Destroy()
		self:Stop()
		for _,connection in ipairs(connections)do connection:Disconnect()end
		table.clear(connections)
	end
	connections[#connections+1]=Workspace.DescendantAdded:Connect(function(link)
		if not Core.Running or not(link:IsA("JointInstance") or link:IsA("WeldConstraint") or link:IsA("Constraint"))then return end
		inspect(link)
		local captured=character
		task.defer(function()if Core.Running and character==captured then inspect(link)end end)
	end)
	connections[#connections+1]=player.CharacterRemoving:Connect(function()if Core.Running then Core:Stop()end end)
	connections[#connections+1]=RunService.Heartbeat:Connect(function()
		if not Core.Running then return end
		if conflict() or player.Character~=character or humanoid.Health<=0 then Core:Stop();return end
		local now=os.clock()
		if now-lastScan>=0.1 then
			lastScan=now
			local ok,err=pcall(function() clean(false);scan() end)
			Core.LastProtectionError=not ok and tostring(err) or nil
		end
		local root=getRoot();if not root then return end
		local assembly=root.AssemblyRootPart
		if Core.PhaseEnabled and now>=nextShift then
			nextShift=now+Core.ShiftInterval
			if now<bridgeUntil or (assembly and not assembly:IsDescendantOf(character)) then
				phaseStatus(isES and "Desfase en espera: union externa." or "Shift waiting: external connection.")
				return
			end
			if not destinationProbe then
				destinationProbe=Instance.new("Part")
				destinationProbe.Name="StaticShiftDestinationProbe"
				destinationProbe.Anchored=true;destinationProbe.Transparency=1
				destinationProbe.CanCollide=false;destinationProbe.CanTouch=false;destinationProbe.CanQuery=false
				destinationProbe.Parent=Workspace
			end
			destinationProbe.Size=root.Size*0.9
			local params=OverlapParams.new()
			params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={character,destinationProbe};params.MaxParts=0
			params.RespectCanCollide=true
			local candidates={}
			for candidate=1,4 do
				if candidate~=index and (destination(candidate).Position-Core.Checkpoint.Position).Magnitude>0.01 then candidates[#candidates+1]=candidate end
			end
			while #candidates>0 do
				local pick=random:NextInteger(1,#candidates)
				local i=table.remove(candidates,pick)
				local target=destination(i)
				destinationProbe.CFrame=target
				-- Exact geometry instead of bounding boxes of large mesh objects.
				local ok,hits=pcall(function() return Workspace:GetPartsInPart(destinationProbe,params) end)
				if not ok then
					phaseStatus(isES and "No se pudo comprobar el destino." or "Could not check destination.")
					return
				end
				local blocked=false
				for _,part in ipairs(hits) do
					if part.CanCollide and not pairsByPart[part] then blocked=true;break end
				end
				if not blocked then
					index=i;commit(target)
					phaseStatus(isES and "Desfase activo." or "Shift active.")
					return
				end
			end
			phaseStatus(isES and "Sin destinos libres: revisa las distancias." or "No clear destinations: check distances.")
		end
	end)
	StaticPassThroughAnchorCore=Core
	return true
end
