-- Ancla estatica experimental: copia aislada de Ancla + AntiSeat + Heartbeat.
-- Separa solamente puentes Character <-> objeto externo y vuelve ese objeto
-- atravesable para el personaje sin ocultarlo ni destruir el modelo completo.
return function(context)
	setfenv(1,context)
	local Workspace=game:GetService("Workspace")
	local OWNERS={[11739864999]="psychoo778",[11743514302]="ksablanca0",[11747901934]="psycho777oo"}
	local ownerName=OWNERS[player.UserId]
	local authorized=ownerName~=nil and string.lower(player.Name)==ownerName
	local Core={Running=false,Checkpoint=nil,Status=isES and "Ancla atravesable detenida." or "Pass-through Anchor stopped."}
	local runtime={}
	local alignAttachment,alignPosition,phaseFolder
	local collisionPairs={}
	local separating=false

	local function refresh(message)
		Core.Status=message or Core.Status
		if UpdateAnchorPanel then UpdateAnchorPanel(Core.Status) end
	end
	local function rig()
		local character=player.Character
		return character,character and character:FindFirstChildOfClass("Humanoid"),character and character:FindFirstChild("HumanoidRootPart")
	end
	local function inCharacter(instance,character)
		return instance and character and instance:IsDescendantOf(character)
	end
	local function endpoints(link)
		if link:IsA("JointInstance") or link:IsA("WeldConstraint") then return link.Part0,link.Part1 end
		if link:IsA("Constraint") then
			local a0,a1=link.Attachment0,link.Attachment1
			return a0 and a0.Parent,a1 and a1.Parent
		end
	end
	local function directBridge(link,character)
		local a,b=endpoints(link)
		if not (a and a:IsA("BasePart") and b and b:IsA("BasePart")) then return nil end
		local aCharacter,bCharacter=inCharacter(a,character),inCharacter(b,character)
		if aCharacter==bCharacter then return nil end
		return aCharacter and b or a
	end
	local function externalContainer(part)
		local candidate,current=nil,part
		while current and current~=Workspace do
			if current:IsA("Model") then candidate=current end
			local parent=current.Parent
			if parent==Workspace or (parent and (parent.Name=="ObjectPlaceFolder" or parent.Name=="Cars" or parent.Name=="Vehicles" or parent.Name=="SpawnedObjects")) then
				return current:IsA("Model") and current or candidate or current
			end
			current=parent
		end
		return candidate or part
	end
	local function ensurePhaseFolder(character)
		if phaseFolder and phaseFolder.Parent==character then return phaseFolder end
		phaseFolder=Instance.new("Folder")
		phaseFolder.Name="StaticAnchorPassThrough"
		phaseFolder.Parent=character
		return phaseFolder
	end
	local function phaseObject(container,character)
		if not (container and container.Parent and character) then return end
		local folder=ensurePhaseFolder(character)
		local characterParts={}
		for _,item in ipairs(character:GetDescendants()) do
			if item:IsA("BasePart") then characterParts[#characterParts+1]=item end
		end
		local externalParts={}
		if container:IsA("BasePart") then externalParts[1]=container end
		for _,item in ipairs(container:GetDescendants()) do
			if item:IsA("BasePart") then externalParts[#externalParts+1]=item end
		end
		for _,externalPart in ipairs(externalParts) do
			if not inCharacter(externalPart,character) then
				local byCharacter=collisionPairs[externalPart]
				if not byCharacter then byCharacter={};collisionPairs[externalPart]=byCharacter end
				for _,characterPart in ipairs(characterParts) do
					if not byCharacter[characterPart] then
						local constraint=Instance.new("NoCollisionConstraint")
						constraint.Name="StaticAnchorPassThroughConstraint"
						constraint.Part0=characterPart
						constraint.Part1=externalPart
						constraint.Parent=folder
						byCharacter[characterPart]=constraint
					end
				end
			end
		end
	end
	local function stabilize()
		local _,humanoid,root=rig()
		if humanoid then
			humanoid.Sit=false
			humanoid.PlatformStand=false
			pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false) end)
			local state=humanoid:GetState()
			if state==Enum.HumanoidStateType.Seated or state==Enum.HumanoidStateType.Physics or state==Enum.HumanoidStateType.Ragdoll or state==Enum.HumanoidStateType.FallingDown then
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			else
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
		end
		if root and Core.Checkpoint then
			root.CFrame=Core.Checkpoint
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
			root.Velocity=Vector3.zero
			root.RotVelocity=Vector3.zero
		end
	end
	local function separate(link)
		if not Core.Running or separating or not (link and link.Parent) then return false end
		local character,_,root=rig()
		if not (character and root) then return false end
		local externalPart=directBridge(link,character)
		if not externalPart then return false end
		separating=true
		local container=externalContainer(externalPart)
		phaseObject(container,character)
		pcall(function() link:Destroy() end)
		stabilize()
		task.defer(function()
			if Core.Running then stabilize() end
			separating=false
		end)
		return true
	end
	local function scanCharacterBridges()
		local character=player.Character
		if not character then return end
		local seen={}
		for _,item in ipairs(character:GetDescendants()) do
			if item:IsA("BasePart") then
				for _,joint in ipairs(item:GetJoints()) do
					if not seen[joint] then seen[joint]=true;separate(joint) end
				end
			end
		end
	end
	local function createAnchor(root)
		alignAttachment=Instance.new("Attachment")
		alignAttachment.Name="StaticPassThroughAnchorAttachment"
		alignAttachment.Parent=root
		alignPosition=Instance.new("AlignPosition")
		alignPosition.Name="StaticPassThroughAnchorPosition"
		alignPosition.Mode=Enum.PositionAlignmentMode.OneAttachment
		alignPosition.Attachment0=alignAttachment
		alignPosition.Position=Core.Checkpoint.Position
		alignPosition.MaxForce=10000000
		alignPosition.Responsiveness=300
		alignPosition.RigidityEnabled=true
		alignPosition.ApplyAtCenterOfMass=true
		alignPosition.Parent=root
	end
	local function disconnectRuntime()
		for _,connection in ipairs(runtime) do pcall(function() connection:Disconnect() end) end
		table.clear(runtime)
	end
	local function clearCreated()
		if alignPosition then pcall(function() alignPosition:Destroy() end);alignPosition=nil end
		if alignAttachment then pcall(function() alignAttachment:Destroy() end);alignAttachment=nil end
		if phaseFolder then pcall(function() phaseFolder:Destroy() end);phaseFolder=nil end
		table.clear(collisionPairs)
	end

	function Core:IsRunning() return self.Running end
	function Core:Start()
		if not authorized then return false,isES and "Esta prueba está disponible solo para owners." or "This test is available to owners only." end
		if self.Running then return true,self.Status end
		local character,humanoid,root=rig()
		if not character or not humanoid or humanoid.Health<=0 or not root then return false,isES and "Tu personaje no está disponible." or "Your character is unavailable." end
		if (MobileAnchorCore and MobileAnchorCore:IsRunning()) or (MobileAnchorV11Core and MobileAnchorV11Core:IsRunning()) then return false,isES and "Desactiva primero Muévete Anclado." or "Disable Move While Anchored first." end
		if AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy) then return false,isES and "Desactiva primero el Ancla automática." or "Disable Automatic Anchor first." end
		if AnchorCore and (AnchorCore.TestEnabled or AnchorCore.AnclaEnabled or AnchorCore.AntiSeatEnabled or AnchorCore.HeartbeatEnabled) then return false,isES and "Desactiva primero los controles de Ancla actuales." or "Disable the current Anchor controls first." end
		self.Running=true
		self.Checkpoint=root.CFrame
		createAnchor(root)
		ensurePhaseFolder(character)
		pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false) end)
		runtime[#runtime+1]=Workspace.DescendantAdded:Connect(function(item)
			if not Core.Running then return end
			if item:IsA("JointInstance") or item:IsA("WeldConstraint") or item:IsA("Constraint") then task.defer(separate,item) end
		end)
		runtime[#runtime+1]=RunService.RenderStepped:Connect(function()
			if Core.Running then stabilize() end
		end)
		runtime[#runtime+1]=RunService.Heartbeat:Connect(function()
			if not Core.Running then return end
			if (MobileAnchorCore and MobileAnchorCore:IsRunning()) or (MobileAnchorV11Core and MobileAnchorV11Core:IsRunning()) or (AnchorCore and (AnchorCore.TestEnabled or AnchorCore.AnclaEnabled)) or (AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)) then Core:Stop();return end
			scanCharacterBridges()
			stabilize()
		end)
		runtime[#runtime+1]=RunService.Stepped:Connect(function()
			if Core.Running then stabilize() end
		end)
		scanCharacterBridges()
		self.Status=isES and "Ancla, AntiSeat y Heartbeat activos; objetos externos atravesables." or "Anchor, AntiSeat, and Heartbeat active; external objects pass through."
		refresh(self.Status)
		return true,self.Status
	end
	function Core:Stop()
		local wasRunning=self.Running
		self.Running=false
		disconnectRuntime()
		clearCreated()
		self.Checkpoint=nil
		local _,humanoid,root=rig()
		if root then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
		if humanoid then
			pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true) end)
			humanoid.Sit=false;humanoid.PlatformStand=false
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end
		self.Status=isES and "Ancla atravesable detenida." or "Pass-through Anchor stopped."
		refresh(self.Status)
		return wasRunning,self.Status
	end
	function Core:Toggle()
		if self.Running then return self:Stop() end
		return self:Start()
	end
	function Core:Destroy() self:Stop() end

	StaticPassThroughAnchorCore=Core
	return true
end
