-- Control de auto integrado. No crea GUI independiente.
return function(context)
	setfenv(1,context)
	local Workspace=game:GetService("Workspace")
	local Controller={Running=false,SelectedCar=nil,SelectedPlayer=nil,Height=math.clamp(tonumber(Settings.carControlHeight) or 8,-10,50),SpinSpeed=math.clamp(tonumber(Settings.carControlSpinSpeed) or 360,0,1440),SpinY=0,Checkpoint=nil,Status=nil}
	local heartbeat,stepped,ancestry,playerRemoving
	local function findRoot(model)
		if not model then return nil end
		if model:IsA("BasePart") then return model end
		if model.PrimaryPart then return model.PrimaryPart end
		for _,name in ipairs({"Body","Chassis","HumanoidRootPart","VehicleSeat","DriveSeat","Seat","WheelB","W"}) do
			local part=model:FindFirstChild(name,true)
			if part and part:IsA("BasePart") then return part end
		end
		for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") and not part.Anchored then return part end end
		for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then return part end end
	end
	local function eachPart(model,callback)
		if model:IsA("BasePart") then callback(model); return end
		for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then callback(part) end end
	end
	local function clearPhysics(model)
		eachPart(model,function(part) part.AssemblyLinearVelocity=Vector3.zero; part.AssemblyAngularVelocity=Vector3.zero end)
	end
	local function targetRoot(target)
		local character=target and target.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		return humanoid and humanoid.Health>0 and root or nil
	end
	local function isMyCar(car)
		local spawnPoints=Workspace:FindFirstChild("CarSpawnPoints")
		if not car or not spawnPoints then return false end
		local spawn=spawnPoints:FindFirstChild(player.Name.."_"..car.Name)
		local owner=spawn and spawn:FindFirstChild("Owner")
		return owner and owner:IsA("StringValue") and owner.Value==player.Name
	end
	local function listCars()
		local result,seen={},{}
		local cars=Workspace:FindFirstChild("Cars")
		local spawnPoints=Workspace:FindFirstChild("CarSpawnPoints")
		if not cars or not spawnPoints then return result end
		local prefix=player.Name.."_"
		for _,spawn in ipairs(spawnPoints:GetChildren()) do
			local owner=spawn:FindFirstChild("Owner")
			if owner and owner:IsA("StringValue") and owner.Value==player.Name and spawn.Name:sub(1,#prefix)==prefix then
				local car=cars:FindFirstChild(spawn.Name:sub(#prefix+1))
				if car and not seen[car] and findRoot(car) then seen[car]=true; result[#result+1]=car end
			end
		end
		table.sort(result,function(a,b) return a.Name<b.Name end)
		return result
	end
	local function disconnectRuntime()
		if heartbeat then heartbeat:Disconnect(); heartbeat=nil end
		if stepped then stepped:Disconnect(); stepped=nil end
		if ancestry then ancestry:Disconnect(); ancestry=nil end
	end
	function Controller:GetCarOptions() return listCars() end
	function Controller:GetTargetOptions() local result={} for _,p in ipairs(Players:GetPlayers()) do if p~=player then result[#result+1]=p end end return result end
	function Controller:SetCar(car) self.SelectedCar=car; return car~=nil end
	function Controller:GetCar() return self.SelectedCar end
	function Controller:SetTarget(target) self.SelectedPlayer=target; return target~=nil end
	function Controller:GetTarget() return self.SelectedPlayer end
	function Controller:SetHeight(value) self.Height=math.clamp(tonumber(value) or self.Height,-10,50); Settings.carControlHeight=self.Height; SaveData(); return self.Height end
	function Controller:GetHeight() return self.Height end
	function Controller:ChangeHeight(amount) return self:SetHeight(self.Height+amount) end
	function Controller:SetSpinSpeed(value) self.SpinSpeed=math.clamp(tonumber(value) or self.SpinSpeed,0,1440); Settings.carControlSpinSpeed=self.SpinSpeed; SaveData(); return self.SpinSpeed end
	function Controller:GetSpinSpeed() return self.SpinSpeed end
	function Controller:ChangeSpinSpeed(amount) return self:SetSpinSpeed(self.SpinSpeed+amount) end
	function Controller:IsRunning() return self.Running end
	function Controller:Apply(dt)
		if not self.Running then return end
		local car=self.SelectedCar; local root=car and findRoot(car); local target=targetRoot(self.SelectedPlayer)
		if not car or not car.Parent or not root then self.Status=isES and "El vehículo desapareció." or "The vehicle disappeared."; self:Stop(false); return end
		if not target then self.Status=isES and "Esperando al jugador objetivo..." or "Waiting for target player..."; return end
		if dt and dt>0 then self.SpinY=(self.SpinY+self.SpinSpeed*math.min(dt,0.1))%360 end
		pcall(function() root:SetNetworkOwner(player) end)
		root.CFrame=CFrame.new(target.Position+Vector3.new(0,self.Height,0))*CFrame.Angles(0,math.rad(self.SpinY),0)
		clearPhysics(car)
		self.Status=isES and "Activo y estabilizando el vehículo." or "Active and stabilizing vehicle."
	end
	function Controller:Start()
		if self.Running then return true end
		local car=self.SelectedCar
		if not car or not car.Parent or not isMyCar(car) then return false,isES and "Selecciona un vehículo propio válido." or "Select a valid owned vehicle." end
		local root=findRoot(car)
		if not root then return false,isES and "El vehículo no tiene una pieza física utilizable." or "The vehicle has no usable physical part." end
		if not targetRoot(self.SelectedPlayer) then return false,isES and "Selecciona un jugador con personaje cargado." or "Select a player with a loaded character." end
		disconnectRuntime(); self.Checkpoint=root.CFrame; self.SpinY=0; self.Status=nil; self.Running=true
		pcall(function() root:SetNetworkOwner(player) end)
		ancestry=car.AncestryChanged:Connect(function(_,parent) if self.Running and (not parent or not car:IsDescendantOf(Workspace)) then self.Status=isES and "El vehículo desapareció." or "The vehicle disappeared."; self:Stop(false) end end)
		heartbeat=RunService.Heartbeat:Connect(function(dt) self:Apply(dt) end)
		stepped=RunService.Stepped:Connect(function() self:Apply(0) end)
		self:Apply(0); return true
	end
	function Controller:Stop(restore)
		local wasRunning=self.Running; self.Running=false; disconnectRuntime()
		local car=self.SelectedCar; local root=car and findRoot(car)
		if root then clearPhysics(car); if restore~=false and self.Checkpoint then root.CFrame=self.Checkpoint; clearPhysics(car) end end
		self.Checkpoint=nil; self.SpinY=0
		if restore~=false then self.Status=isES and "Control detenido; vehículo restaurado." or "Control stopped; vehicle restored." end
		return wasRunning
	end
	function Controller:Destroy() self:Stop(true); if playerRemoving then playerRemoving:Disconnect(); playerRemoving=nil end end
	playerRemoving=Players.PlayerRemoving:Connect(function(leaving)
		if Controller.SelectedPlayer==leaving then Controller:Stop(true); Controller.SelectedPlayer=nil; if UpdateCarControlPanel then UpdateCarControlPanel() end end
	end)
	CarControlController=Controller
	return true
end