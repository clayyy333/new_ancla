-- Control de auto integrado. No crea GUI independiente.
return function(context)
	setfenv(1,context)
	local Workspace=game:GetService("Workspace")
	local Controller={Running=false,AutoEnabled=false,AutoStarting=false,SelectedCar=nil,SelectedCarName=nil,SelectedPlayer=nil,Height=math.clamp(tonumber(Settings.carControlHeight) or 8,-10,50),SpinSpeed=math.clamp(tonumber(Settings.carControlSpinSpeed) or 360,0,1440),SpinY=0,Checkpoint=nil,PivotOffset=nil,LastTargetPosition=nil,LastOwnershipAttempt=0,Status=nil}
	local heartbeat,stepped,rendered,ancestry,playerRemoving,autoMonitor
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
		local result,seenNames={},{}
		local cars=Workspace:FindFirstChild("Cars")
		local spawnPoints=Workspace:FindFirstChild("CarSpawnPoints")
		if not cars or not spawnPoints then return result end
		local children=cars:GetChildren()
		for index=#children,1,-1 do
			local car=children[index]
			if not seenNames[car.Name] and isMyCar(car) and findRoot(car) then seenNames[car.Name]=true; result[#result+1]=car end
		end
		table.sort(result,function(a,b) return a.Name<b.Name end)
		return result
	end
	local function disconnectRuntime()
		if heartbeat then heartbeat:Disconnect(); heartbeat=nil end
		if stepped then stepped:Disconnect(); stepped=nil end
		if rendered then rendered:Disconnect(); rendered=nil end
		if ancestry then ancestry:Disconnect(); ancestry=nil end
	end
	function Controller:GetCarOptions() return listCars() end
	function Controller:GetTargetOptions() local result={} for _,p in ipairs(Players:GetPlayers()) do if p~=player then result[#result+1]=p end end return result end
	function Controller:SetCar(car) self.SelectedCar=car; self.SelectedCarName=car and car.Name or nil; return car~=nil end
	function Controller:GetCar()
		if self.Running then return self.SelectedCar end
		if not self.SelectedCarName then return nil end
		for _,car in ipairs(listCars()) do if car.Name==self.SelectedCarName then self.SelectedCar=car; return car end end
		self.SelectedCar=nil; return nil
	end
	function Controller:SetTarget(target) self.SelectedPlayer=target; return target~=nil end
	function Controller:GetTarget() return self.SelectedPlayer end
	function Controller:SetHeight(value) self.Height=math.clamp(tonumber(value) or self.Height,-10,50); Settings.carControlHeight=self.Height; SaveData(); return self.Height end
	function Controller:GetHeight() return self.Height end
	function Controller:ChangeHeight(amount) return self:SetHeight(self.Height+amount) end
	function Controller:SetSpinSpeed(value) self.SpinSpeed=math.clamp(tonumber(value) or self.SpinSpeed,0,1440); Settings.carControlSpinSpeed=self.SpinSpeed; SaveData(); return self.SpinSpeed end
	function Controller:GetSpinSpeed() return self.SpinSpeed end
	function Controller:ChangeSpinSpeed(amount) return self:SetSpinSpeed(self.SpinSpeed+amount) end
	function Controller:IsRunning() return self.Running end
	function Controller:IsAutoEnabled() return self.AutoEnabled end
	function Controller:SetAutoEnabled(enabled) self.AutoEnabled=enabled==true; return self.AutoEnabled end
	function Controller:Apply(dt)
		if not self.Running then return end
		local car=self.SelectedCar; local root=car and findRoot(car); local target=targetRoot(self.SelectedPlayer)
		if not car or not car.Parent or not root then self.Status=isES and "El vehículo desapareció." or "The vehicle disappeared."; self:Stop(false); return end
		if not target then self.Status=isES and "Esperando al jugador objetivo..." or "Waiting for target player..."; return end
		if dt and dt>0 then self.SpinY=(self.SpinY+self.SpinSpeed*math.min(dt,0.1))%360 end
		if os.clock()-self.LastOwnershipAttempt>=0.5 then self.LastOwnershipAttempt=os.clock(); pcall(function() root:SetNetworkOwner(player) end) end
		local targetPosition=target.Position
		local humanoid=self.SelectedPlayer and self.SelectedPlayer.Character and self.SelectedPlayer.Character:FindFirstChildOfClass("Humanoid")
		local targetIsOccupant=false
		if humanoid then for _,item in ipairs(car:GetDescendants()) do if (item:IsA("VehicleSeat") or item:IsA("Seat")) and item.Occupant==humanoid then targetIsOccupant=true; break end end end
		if targetIsOccupant and self.LastTargetPosition then targetPosition=self.LastTargetPosition else self.LastTargetPosition=targetPosition end
		local desired=CFrame.new(targetPosition+Vector3.new(0,self.Height,0))*CFrame.Angles(0,math.rad(self.SpinY),0)
		if car:IsA("Model") and self.PivotOffset then car:PivotTo(desired*self.PivotOffset) else root.CFrame=desired end
		clearPhysics(car)
		self.Status=isES and "Activo y estabilizando el vehículo." or "Active and stabilizing vehicle."
	end
	function Controller:Start()
		if self.Running then return true end
		if FreeCarController and FreeCarController:IsRunning() then FreeCarController:Stop() end
		local car=self:GetCar()
		if not car or not car.Parent or not isMyCar(car) then return false,isES and "Selecciona un vehículo propio válido." or "Select a valid owned vehicle." end
		local root=findRoot(car)
		if not root then return false,isES and "El vehículo no tiene una pieza física utilizable." or "The vehicle has no usable physical part." end
		if not targetRoot(self.SelectedPlayer) then return false,isES and "Selecciona un jugador con personaje cargado." or "Select a player with a loaded character." end
		disconnectRuntime(); self.Checkpoint=root.CFrame; self.PivotOffset=car:IsA("Model") and root.CFrame:ToObjectSpace(car:GetPivot()) or nil; self.LastTargetPosition=targetRoot(self.SelectedPlayer).Position; self.LastOwnershipAttempt=0; self.SpinY=0; self.Status=nil; self.Running=true
		pcall(function() root:SetNetworkOwner(player) end)
		ancestry=car.AncestryChanged:Connect(function(_,parent) if self.Running and (not parent or not car:IsDescendantOf(Workspace)) then self.Status=isES and "El vehículo desapareció." or "The vehicle disappeared."; self:Stop(false) end end)
		heartbeat=RunService.Heartbeat:Connect(function(dt) self:Apply(dt) end)
		stepped=RunService.Stepped:Connect(function() self:Apply(0) end)
		rendered=RunService.RenderStepped:Connect(function() self:Apply(0) end)
		self:Apply(0); return true
	end
	function Controller:Stop(restore)
		local wasRunning=self.Running; self.Running=false; disconnectRuntime()
		local car=self.SelectedCar; local root=car and findRoot(car)
		if root then clearPhysics(car); if restore~=false and self.Checkpoint then root.CFrame=self.Checkpoint; clearPhysics(car) end end
		self.Checkpoint=nil; self.PivotOffset=nil; self.LastTargetPosition=nil; self.SpinY=0
		if restore~=false then self.Status=isES and "Control detenido; vehículo restaurado." or "Control stopped; vehicle restored." end
		return wasRunning
	end
	function Controller:Destroy() self.AutoEnabled=false; self:Stop(true); if playerRemoving then playerRemoving:Disconnect(); playerRemoving=nil end; if autoMonitor then autoMonitor:Disconnect(); autoMonitor=nil end end
	playerRemoving=Players.PlayerRemoving:Connect(function(leaving)
		if Controller.SelectedPlayer==leaving then Controller:Stop(true); Controller.SelectedPlayer=nil; if UpdateCarControlPanel then UpdateCarControlPanel() end end
	end)
	local autoElapsed=0
	autoMonitor=RunService.Heartbeat:Connect(function(dt)
		if not Controller.AutoEnabled or Controller.Running or Controller.AutoStarting then return end
		autoElapsed+=dt
		if autoElapsed<0.25 then return end
		autoElapsed=0
		if not Controller.SelectedPlayer or not targetRoot(Controller.SelectedPlayer) then return end
		local car=Controller:GetCar()
		if not car then
			local options=listCars()
			if #options==1 then Controller:SetCar(options[1]); car=options[1] end
		end
		if not car then return end
		Controller.AutoStarting=true
		local ok,err=Controller:Start()
		Controller.AutoStarting=false
		if not ok then Controller.Status=err end
		if UpdateCarControlPanel then UpdateCarControlPanel() end
	end)
	CarControlController=Controller
	return true
end