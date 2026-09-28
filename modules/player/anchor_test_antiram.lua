-- Anti-ram independiente para Ancla test.
-- Protege el personaje sin modificar vehículos ni el flujo del patín.
return function(context)
	setfenv(1,context)

	local Workspace=game:GetService("Workspace")
	local Core={Enabled=false,ThreatUntil=0}
	local connections={}
	local originalCollisions=setmetatable({},{__mode="k"})
	local lastScan=0
	local SCAN_INTERVAL,RADIUS,LINEAR_LIMIT,ANGULAR_LIMIT,THREAT_TIME=0.10,20,65,40,0.65

	local function getCharacter()
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		return character,root
	end
	local function getOwnSkate()
		local cars=Workspace:FindFirstChild("Cars")
		if not cars then return nil end
		for _,vehicle in ipairs(cars:GetChildren()) do
			if vehicle.Name=="ltp2_car_57" then
				local owner=vehicle:FindFirstChild("VehicleOwner")
				if owner and owner:IsA("ObjectValue") and owner.Value==player then return vehicle end
			end
		end
	end
	local function rememberAndDisable(part)
		if not part:IsA("BasePart") then return end
		if originalCollisions[part]==nil then originalCollisions[part]=part.CanCollide end
		if part.CanCollide then part.CanCollide=false end
	end
	local function suppressCharacterCollisions()
		local character=getCharacter()
		if not character then return end
		for _,item in ipairs(character:GetDescendants()) do rememberAndDisable(item) end
	end
	local function restoreCharacterCollisions()
		for part,value in pairs(originalCollisions) do
			if part and part.Parent then pcall(function() part.CanCollide=value end) end
		end
		table.clear(originalCollisions)
	end
	local function hardCorrect()
		if not AnchorCore or not AnchorCore.TestEnabled or not AnchorCore.TestCheckpoint then return end
		local character,root=getCharacter()
		if not character or not root then return end
		pcall(function() character:PivotTo(AnchorCore.TestCheckpoint) end)
		root.CFrame=AnchorCore.TestCheckpoint
		for _,part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity=Vector3.zero
				part.AssemblyAngularVelocity=Vector3.zero
				part.Velocity=Vector3.zero
				part.RotVelocity=Vector3.zero
			end
		end
	end
	local function isOwnSkatePart(part)
		local skate=getOwnSkate()
		if part and skate and part:IsDescendantOf(skate) then return true end
		local cars=Workspace:FindFirstChild("Cars")
		local current=part
		while current and current~=cars and current~=Workspace do
			if current:IsA("Model") and current.Name=="ltp2_car_57" then
				local owner=current:FindFirstChild("VehicleOwner")
				if (owner and owner:IsA("ObjectValue") and owner.Value==player)
					or (not owner and AnchorTestSkateDelta and AnchorTestSkateDelta.Enabled) then return true end
			end
			current=current.Parent
		end
		return false
	end
	local function externalJointParts(link)
		local character=getCharacter()
		if not character then return nil,nil end
		if link:IsA("JointInstance") then
			local p0,p1=link.Part0,link.Part1
			local c0=p0 and p0:IsDescendantOf(character)
			local c1=p1 and p1:IsDescendantOf(character)
			if c0~=c1 then return c0 and p0 or p1,c0 and p1 or p0 end
		elseif link:IsA("Constraint") then
			local a0,a1=link.Attachment0,link.Attachment1
			local p0,p1=a0 and a0.Parent,a1 and a1.Parent
			local c0=p0 and p0:IsDescendantOf(character)
			local c1=p1 and p1:IsDescendantOf(character)
			if c0~=c1 then return c0 and p0 or p1,c0 and p1 or p0 end
		end
		return nil,nil
	end
	local function rejectForeignLink(link)
		if not Core.Enabled then return end
		local _,outside=externalJointParts(link)
		if outside and not isOwnSkatePart(outside) then
			pcall(function() link:Destroy() end)
			Core.ThreatUntil=os.clock()+THREAT_TIME
			hardCorrect()
		end
	end
	local function scanNearbyThreats()
		local now=os.clock()
		if now-lastScan<SCAN_INTERVAL then return end
		lastScan=now
		local character,root=getCharacter()
		if not character or not root then return end
		local filter={character}
		local skate=getOwnSkate()
		if skate then filter[#filter+1]=skate end
		local params=OverlapParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances=filter
		params.MaxParts=64
		local ok,parts=pcall(function() return Workspace:GetPartBoundsInRadius(root.Position,RADIUS,params) end)
		if not ok then return end
		for _,part in ipairs(parts) do
			if part:IsA("BasePart") and not part.Anchored then
				local assembly=part.AssemblyRootPart or part
				local linear=assembly.AssemblyLinearVelocity.Magnitude
				local angular=assembly.AssemblyAngularVelocity.Magnitude
				if linear>=LINEAR_LIMIT or angular>=ANGULAR_LIMIT then
					Core.ThreatUntil=now+THREAT_TIME
					hardCorrect()
					return
				end
			end
		end
	end
	local function disconnectAll()
		for _,connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
		table.clear(connections)
	end
	function Core:Start()
		if self.Enabled then return true end
		self.Enabled=true
		self.ThreatUntil=0
		suppressCharacterCollisions()
		connections[#connections+1]=Workspace.DescendantAdded:Connect(function(item)
			if not Core.Enabled then return end
			if item:IsA("BasePart") then
				local character=getCharacter()
				if character and item:IsDescendantOf(character) then rememberAndDisable(item) end
			elseif item:IsA("JointInstance") or item:IsA("Constraint") then
				rejectForeignLink(item)
			end
		end)
		connections[#connections+1]=player.CharacterAdded:Connect(function()
			if not Core.Enabled then return end
			task.defer(function()
				task.wait()
				suppressCharacterCollisions()
				hardCorrect()
			end)
		end)
		local function simulationStep()
			if not Core.Enabled then return end
			suppressCharacterCollisions()
			scanNearbyThreats()
			if os.clock()<Core.ThreatUntil then hardCorrect() end
		end
		local ok,signal=pcall(function() return RunService.PreSimulation end)
		if ok and signal then connections[#connections+1]=signal:Connect(simulationStep) end
		connections[#connections+1]=RunService.Heartbeat:Connect(simulationStep)
		return true
	end
	function Core:Stop()
		if not self.Enabled then return true end
		self.Enabled=false
		self.ThreatUntil=0
		disconnectAll()
		restoreCharacterCollisions()
		return true
	end
	function Core:Destroy() return self:Stop() end

	AnchorTestAntiRam=Core
	return true
end
