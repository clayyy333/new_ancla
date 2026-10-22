-- Observe only: no Sit(), remote calls, joint deletion, or physics writes.
return function(context)
	setfenv(1,context)
	local core={Running=false,Lines={},Connections={},Vehicles={},Characters={}}
	SeatDiagnosticCore=core
	local function path(instance)
		if not instance then return "nil" end
		local ok,result=pcall(function()return instance:GetFullName()end)
		return ok and result or "unavailable"
	end
	local function disconnect(list)for _,connection in ipairs(list)do connection:Disconnect()end end
	local function disconnectVehicle(data)
		disconnect(data.Connections)
		for _,seatData in pairs(data.Seats)do disconnect(seatData.WeldConnections)end
	end
	local function append(message)
		core.Lines[#core.Lines+1]=string.format("t=%.3f %s",os.clock()-core.Started,message)
		if #core.Lines>160 then table.remove(core.Lines,1)end
	end
	local function watched(p)return p and (p==player or p.UserId==11773278300)end
	local function ownerMatches(vehicle)
		local id=tonumber(vehicle:GetAttribute("VehicleOwner"))
		local value=vehicle:FindFirstChild("VehicleOwner")
		return id==player.UserId or id==11773278300 or (value and value:IsA("ObjectValue") and watched(value.Value))
	end
	function core:SnapshotSeat(seat,event)
		local humanoid=seat.Occupant
		local occupant=humanoid and Players:GetPlayerFromCharacter(humanoid.Parent)
		local weld=seat:FindFirstChild("SeatWeld")
		local joint=weld and weld:IsA("JointInstance") and weld or nil
		local status="unknown"
		if humanoid then pcall(function()status=humanoid:GetState().Name end)end
		append(event.." seat="..path(seat).." occupant="..(occupant and (occupant.Name.."/"..occupant.UserId) or (humanoid and "NPC" or "EMPTY"))
			.." Sit="..tostring(humanoid and humanoid.Sit).." SeatPart="..path(humanoid and humanoid.SeatPart).." state="..status
			.." Health="..tostring(humanoid and humanoid.Health).." SeatWeld="..tostring(weld~=nil).." Part0="..path(joint and joint.Part0).." Part1="..path(joint and joint.Part1))
	end
	function core:BindVehicle(vehicle)
		if self.Vehicles[vehicle] or not ownerMatches(vehicle)then return end
		local data={Connections={},Seats={}}
		self.Vehicles[vehicle]=data
		append("VEHICLE_FOUND "..path(vehicle).." VehicleOwner="..tostring(vehicle:GetAttribute("VehicleOwner")))
		local function bindSeat(seat)
			if not (seat:IsA("Seat")or seat:IsA("VehicleSeat"))or data.Seats[seat]then return end
			local seatData={WeldConnections={}}
			data.Seats[seat]=seatData
			local function snapshot(label)
				if self.Running and seat.Parent and ownerMatches(vehicle)then self:SnapshotSeat(seat,label)end
			end
			local function bindWeld(weld)
				if weld.Name~="SeatWeld"or not weld:IsA("JointInstance")then return end
				disconnect(seatData.WeldConnections);seatData.WeldConnections={};seatData.Weld=weld
				for _,property in ipairs({"Part0","Part1"})do
					seatData.WeldConnections[#seatData.WeldConnections+1]=weld:GetPropertyChangedSignal(property):Connect(function()snapshot("WELD_ENDPOINT_CHANGED")end)
				end
			end
			data.Connections[#data.Connections+1]=seat:GetPropertyChangedSignal("Occupant"):Connect(function()snapshot("OCCUPANT_CHANGED")end)
			data.Connections[#data.Connections+1]=seat.ChildAdded:Connect(function(child)
				if child.Name=="SeatWeld"then bindWeld(child);snapshot("SEATWELD_ADDED")end
			end)
			data.Connections[#data.Connections+1]=seat.ChildRemoved:Connect(function(child)
				if child==seatData.Weld then disconnect(seatData.WeldConnections);seatData.WeldConnections={};seatData.Weld=nil end
				if child.Name=="SeatWeld"then snapshot("SEATWELD_REMOVED")end
			end)
			local weld=seat:FindFirstChild("SeatWeld");if weld then bindWeld(weld)end
			snapshot("SEAT_INITIAL")
		end
		data.Connections[#data.Connections+1]=vehicle.DescendantAdded:Connect(bindSeat)
		for _,item in ipairs(vehicle:GetDescendants())do bindSeat(item)end
	end
	function core:BindCharacter(p)
		local current=p.Character
		local previous=self.Characters[p]
		if previous and previous.Character==current then return end
		if previous then disconnect(previous.Connections)end
		local data={Character=current,Connections={}}
		self.Characters[p]=data
		append("CHARACTER "..p.Name.." "..path(current))
		if not current then return end
		local function bindHumanoid(h)
			if not h:IsA("Humanoid")or data.Humanoid==h then return end
			data.Humanoid=h
			data.Connections[#data.Connections+1]=h.Seated:Connect(function(active,seat)append("HUMANOID_SEATED "..p.Name.." active="..tostring(active).." seat="..path(seat))end)
			data.Connections[#data.Connections+1]=h.HealthChanged:Connect(function(health)append("HEALTH "..p.Name.."="..tostring(health))end)
			data.Connections[#data.Connections+1]=h.Died:Connect(function()append("DIED "..p.Name)end)
		end
		data.Connections[#data.Connections+1]=current.ChildAdded:Connect(bindHumanoid)
		data.Connections[#data.Connections+1]=current.DescendantRemoving:Connect(function(item)
			if item:IsA("Motor6D")or item.Name=="HumanoidRootPart"or item.Name=="Head"then append("RIG_REMOVING "..p.Name.." "..path(item))end
		end)
		local h=current:FindFirstChildOfClass("Humanoid");if h then bindHumanoid(h)end
	end
	function core:Refresh()
		local cars=workspace:FindFirstChild("Cars")
		for vehicle,data in pairs(self.Vehicles)do
			if vehicle.Parent~=cars or not ownerMatches(vehicle)then disconnectVehicle(data);self.Vehicles[vehicle]=nil;append("VEHICLE_UNBOUND "..path(vehicle))end
		end
		if cars then for _,vehicle in ipairs(cars:GetChildren())do self:BindVehicle(vehicle)end end
		local actors={player,Players:GetPlayerByUserId(11773278300)}
		for _,p in ipairs(actors)do self:BindCharacter(p)end
		for p,data in pairs(self.Characters)do
			if p~=player and p.Parent~=Players then disconnect(data.Connections);self.Characters[p]=nil;append("PLAYER_LEFT "..p.Name)end
		end
	end
	function core:Start()
		if self.Running then return true end
		if not ExperimentalFlingCore:IsAuthorized()then return false,"Solo owners."end
		self.Running=true;self.Started=os.clock();self.Lines={}
		local ok,err=pcall(function()self:Refresh()end)
		if not ok then self:Stop();append("START_ERROR "..tostring(err));return false,tostring(err)end
		local elapsed=0
		self.Connections[#self.Connections+1]=RunService.Heartbeat:Connect(function(dt)
			elapsed=elapsed+dt;if elapsed<0.25 then return end;elapsed=0
			local ok,err=pcall(function()self:Refresh()end)
			if not ok then append("REFRESH_ERROR "..tostring(err))end
		end)
		return true
	end
	function core:Stop()
		self.Running=false;disconnect(self.Connections);self.Connections={}
		for _,data in pairs(self.Vehicles)do disconnectVehicle(data)end
		for _,data in pairs(self.Characters)do disconnect(data.Connections)end
		self.Vehicles={};self.Characters={}
	end
	function core:GetReport()
		return "SEAT OBSERVER V1 | read-only client observations; events do not prove cause of death\nRunning="..tostring(self.Running)
			.."\nAccounts: "..player.UserId..",11773278300 | vehicles identified by VehicleOwner, not name\n"..table.concat(self.Lines,"\n")
	end
	function core:Destroy()self:Stop()end
	return true
end
