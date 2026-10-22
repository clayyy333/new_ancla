-- Independent efficient-short vehicle test. Never writes vehicle parts or calls remotes.
return function(context)
	setfenv(1,context)
	local CONFIG={Speed=900000000,P=1250,Height=1.5,ContactTime=0.05,HomeTime=0.05,StopTime=2,Attempts=3,Displacement=20}
	local core={Running=false,Stopping=false,Owner=nil,Rows={},Records={},Completed=0,Phase="IDLE"}
	NoMotosCore=core
	local runtime={}
	local root,humanoid,character,checkpoint,flinger,current,contactStarted,homeUntil,scanElapsed
	local savedPlatformStand,savedAutoRotate
	local savedSeatedEnabled
	local function restoreSeatState()
		if savedSeatedEnabled~=nil and humanoid and humanoid.Parent then
			pcall(function()humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,savedSeatedEnabled)end)
		end
		savedSeatedEnabled=nil
	end
	local function preventSeat()
		if not core.Running or not humanoid or not humanoid.Parent or player.Character~=character then return end
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
		if humanoid.Sit then humanoid.Sit=false end
		if humanoid:GetState()==Enum.HumanoidStateType.Seated then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	local function refresh(message)if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel(message)end end
	local function disconnect(list)for _,c in ipairs(list)do c:Disconnect()end;table.clear(list)end
	local function finiteVector(v)
		return v and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<math.huge and math.abs(v.Y)<math.huge and math.abs(v.Z)<math.huge
	end
	local function log(message)
		core.Rows[#core.Rows+1]=string.format("t=%.3f %s",os.clock(),message)
		if #core.Rows>100 then table.remove(core.Rows,1)end
	end
	local function rig()
		local c=player.Character
		local h=c and c:FindFirstChildOfClass("Humanoid")
		local r=c and c:FindFirstChild("HumanoidRootPart")
		local torso=c and (c:FindFirstChild("UpperTorso")or c:FindFirstChild("Torso"))
		if h and h.Health>0 and r and torso then return c,h,r,torso end
		local reason=not c and "Character no disponible"or not h and "Humanoid no disponible"
			or h.Health<=0 and "Humanoid sin vida"or not r and "HumanoidRootPart no disponible"
			or "UpperTorso/Torso no disponible"
		return nil,nil,nil,nil,reason
	end
	local function externalConnection(r,c)
		local ok,parts=pcall(function()return r:GetConnectedParts(true)end)
		if not ok then return true,"GetConnectedParts fallo: "..tostring(parts)end
		for _,part in ipairs(parts)do
			if part~=r and not part:IsDescendantOf(c)then return true,part:GetFullName()end
		end
		return false
	end
	local function destroyFlinger()
		if flinger then flinger:Destroy();flinger=nil end
	end
	local function zero()
		if root and root.Parent then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
	end
	local function owns(vehicle)
		if not core.Owner or core.Owner.Parent~=Players then return false end
		local id=tonumber(vehicle:GetAttribute("VehicleOwner"))
		local reference=vehicle:FindFirstChild("VehicleOwner")
		local owner=reference and reference:IsA("ObjectValue")and reference.Value or nil
		if id and id~=core.Owner.UserId then return false end
		if owner and owner~=core.Owner then return false end
		return id==core.Owner.UserId or owner==core.Owner
	end
	local function isMotorcycle(vehicle,mover)
		for _,key in ipairs({"Animation","RunAnim"})do
			if tostring(vehicle:GetAttribute(key)):match("%d+")=="13112445577"then return true end
		end
		-- Alternative evidence from the two motorcycle wheel meshes, not car names.
		local front,back=mover:FindFirstChild("WheelF"),mover:FindFirstChild("WheelB")
		if vehicle:GetAttribute("MoverType")~="WheelAttachMover"or not front or not back then return false end
		local function motorcycleWheel(wheel)
			for _,item in ipairs(wheel:GetDescendants())do if item.Name:find("Motorcycle",1,true)then return true end end
			return false
		end
		return motorcycleWheel(front)and motorcycleWheel(back)
	end
	local function eligible(target)
		local cars=workspace:FindFirstChild("Cars")
		if target.Vehicle.Parent~=cars or not owns(target.Vehicle)or not target.Body.Parent then return false end
		local body=target.Body
		if not body.CanCollide or body.Anchored or not finiteVector(body.Position)then return false end
		local assembly=body.AssemblyRootPart
		if not assembly or assembly.Anchored or (assembly~=target.Vehicle and not assembly:IsDescendantOf(target.Vehicle))then return false end
		local driver=target.Vehicle:FindFirstChild("WeldToPlayer")
		if driver and driver:IsA("WeldConstraint")and driver.Enabled and driver.Part0 and driver.Part1 then return false end
		for _,seat in ipairs(target.Seats)do
			if not seat.Parent or seat.Occupant or seat:FindFirstChild("SeatWeld")then return false end
		end
		return true
	end
	local function resolve(vehicle)
		if not owns(vehicle)then return end
		local mover=vehicle:FindFirstChild("MoverModel")
		local body=mover and mover:FindFirstChild("Body")
		if not body or not body:IsA("BasePart")or not isMotorcycle(vehicle,mover)then return end
		local seats={}
		for _,item in ipairs(vehicle:GetDescendants())do
			if item:IsA("Seat")or item:IsA("VehicleSeat")then seats[#seats+1]=item end
		end
		if #seats==0 then return end
		local result={Vehicle=vehicle,Body=body,Seats=seats}
		if eligible(result)then return result end
	end
	local function home()
		destroyFlinger()
		if root and root.Parent and player.Character==character and not externalConnection(root,character)then
			root.CFrame=checkpoint;zero();return true
		end
		return false
	end
	function core:IsAuthorized()return ExperimentalFlingCore and ExperimentalFlingCore:IsAuthorized()end
	function core:FinishStop()
		if self.StopConnection then self.StopConnection:Disconnect();self.StopConnection=nil end
		if self.StopRoot and self.StopRoot.Parent then
			self.StopRoot.Anchored=self.PreviousAnchored
			self.StopRoot.AssemblyLinearVelocity=Vector3.zero;self.StopRoot.AssemblyAngularVelocity=Vector3.zero
		end
		if humanoid and humanoid.Parent then humanoid.PlatformStand=savedPlatformStand;humanoid.AutoRotate=savedAutoRotate end
		self.StopRoot=nil;self.Stopping=false;self.Phase="IDLE"
		refresh(self.LastMessage)
	end
	function core:Stop(message)
		if self.Stopping then return true end
		local wasRunning=self.Running
		self.Running=false;disconnect(runtime);destroyFlinger();current=nil
		restoreSeatState()
		self.LastMessage=message or "No motos desactivado; regreso y limpieza."
		if not wasRunning then return false end
		log("STOP "..self.LastMessage)
		if not home()then
			self.LastMessage="Fuerzas retiradas. No se teletransporta un personaje unido a un vehiculo o reemplazado."
			if player.Character==character and humanoid and humanoid.Parent then humanoid.PlatformStand=savedPlatformStand;humanoid.AutoRotate=savedAutoRotate end
			self.Phase="IDLE";refresh(self.LastMessage);return true
		end
		self.Stopping=true;self.Phase="STABILIZING";self.StopRoot=root;self.PreviousAnchored=root.Anchored
		root.Anchored=true
		local elapsed=0
		self.StopConnection=RunService.Heartbeat:Connect(function(dt)
			elapsed=elapsed+dt
			if player.Character~=character or not root.Parent or elapsed>=CONFIG.StopTime then self:FinishStop();return end
			root.CFrame=checkpoint;zero()
		end)
		refresh(self.LastMessage)
		return true
	end
	local function conflicts()
		for _,name in ipairs({"ExperimentalFlingCore","Fling2Core","Fling2EfficientCore","CarFling","ContactFlingController","MotoFlingCore","MotoFlingXenoCore","CarFlingXeno","CarFling2Delta","CarFling2Xeno","CustomFlingCore","MobileAnchorCore","MobileAnchorV11Core","StaticPassThroughAnchorCore","VerticalControlController"})do
			local other=context[name]
			if other and (other.Running or other.Stopping)then return name end
		end
		if AnchorCore and (AnchorCore.AnclaEnabled or AnchorCore.TestEnabled)then return "Ancla"end
		if AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)then return "Ancla automatica"end
	end
	local function recordAttempt()
		local target=current
		if not target then return end
		local record=core.Records[target.Vehicle]
		local moved=finiteVector(target.Body.Position)and (target.Body.Position-record.Origin).Magnitude or 0
		record.Attempts=record.Attempts+1;record.Displacement=moved
		record.Done=moved>=CONFIG.Displacement or record.Attempts>=CONFIG.Attempts
		if moved>=CONFIG.Displacement then core.Completed=core.Completed+1 end
		log(string.format("RETURN attempts=%d displacement=%.2f done=%s",record.Attempts,moved,tostring(record.Done)))
		current=nil;core.Phase="HOME";homeUntil=os.clock()+CONFIG.HomeTime
		if not home()then core:Stop("Conexion externa detectada durante el regreso.")end
	end
	local function consider(vehicle)
		if not core.Running then return end
		local record=core.Records[vehicle]
		local target=resolve(vehicle)
		if not target then return end
		-- A reused container can receive a new physical Body on regeneration.
		if record and record.Body~=target.Body then core.Records[vehicle]=nil;record=nil end
		if record and record.Done then return end
		if not record then
			local ok,name=pcall(function()return vehicle:GetFullName()end)
			core.Records[vehicle]={Body=target.Body,Attempts=0,Origin=target.Body.Position,Done=false,Name=ok and name or vehicle.Name}
			log("FREE_MOTORCYCLE "..core.Records[vehicle].Name)
		end
	end
	function core:Start(owner)
		if not self:IsAuthorized()then return false,"No motos solo esta disponible para owners."end
		if self.Stopping then return false,"Espera a que termine la estabilizacion."end
		if self.Running then return true end
		if not owner or not owner:IsA("Player")or owner.Parent~=Players then return false,"Selecciona el propietario de las motos en la lista de usuarios."end
		local conflict=conflicts();if conflict then return false,"Desactiva primero: "..conflict end
		local function blocked(reason)
			self.LastStartFailure=reason
			log("START_BLOCKED "..reason)
			return false,reason
		end
		local c,h,r,_,rigFailure=rig()
		if not r then return blocked(rigFailure)end
		if r.Anchored then return blocked("HumanoidRootPart.Anchored sigue en true.")end
		local connected,connectionPath=externalConnection(r,c)
		if connected then return blocked("Tu HRP sigue unido a: "..connectionPath..". Sal de esa union antes de activar.")end
		if h.SeatPart then return blocked("Humanoid.SeatPart sigue apuntando a: "..h.SeatPart:GetFullName())end
		-- Sit can remain true after leaving a seat even with no external physical joint.
		-- Clear only that stale local request; never detach an actual vehicle assembly.
		if h.Sit then
			h.Sit=false
			if h:GetState()==Enum.HumanoidStateType.Seated then h:ChangeState(Enum.HumanoidStateType.GettingUp)end
		end
		character,humanoid,root=c,h,r;checkpoint=r.CFrame
		savedPlatformStand=h.PlatformStand;savedAutoRotate=h.AutoRotate
		local seatOK,seatState=pcall(function()
			local previous=h:GetStateEnabled(Enum.HumanoidStateType.Seated)
			h:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
			return previous
		end)
		if not seatOK then return false,"No se pudo activar la proteccion anti-asiento."end
		savedSeatedEnabled=seatState
		self.LastStartFailure=nil
		self.LastCheckpoint=checkpoint;self.Owner=owner;self.Records={};self.Rows={};self.Completed=0;self.Phase="HOME";self.Running=true
		-- Prevent auto-seating before physics, without activating an anchor or editing seats/welds.
		runtime[#runtime+1]=RunService.PreSimulation:Connect(function()
			local ok=pcall(preventSeat)
			if not ok then self:Stop("Fallo en la proteccion anti-asiento.")end
		end)
		runtime[#runtime+1]=h.Seated:Connect(function(active)
			if active then
				local ok=pcall(preventSeat)
				if not ok then self:Stop("Fallo en la proteccion anti-asiento.")end
			end
		end)
		homeUntil=os.clock()+CONFIG.HomeTime;scanElapsed=1
		local boundCars
		local carsConnections={}
		local function scan()
			local cars=workspace:FindFirstChild("Cars")
			if cars~=boundCars then
				disconnect(carsConnections);boundCars=cars
				if cars then
					carsConnections[#carsConnections+1]=cars.ChildAdded:Connect(function(vehicle)
						-- Instances, not names, identify a spawn. Reinsertions are new spawns too.
						self.Records[vehicle]=nil
						consider(vehicle)
					end)
					carsConnections[#carsConnections+1]=cars.DescendantAdded:Connect(function(item)
						local top=item
						while top.Parent and top.Parent~=cars do top=top.Parent end
						if top.Parent==cars then
							if current and current.Vehicle==top and (item:IsA("Seat")or item:IsA("VehicleSeat"))then current.Seats[#current.Seats+1]=item end
							consider(top)
						end
					end)
				end
			end
			if cars then for _,vehicle in ipairs(cars:GetChildren())do consider(vehicle)end end
			for vehicle in pairs(self.Records)do if vehicle.Parent~=cars then self.Records[vehicle]=nil end end
		end
		runtime[#runtime+1]={Disconnect=function()disconnect(carsConnections)end}
		runtime[#runtime+1]=RunService.PostSimulation:Connect(function()
			if not self.Running or self.Phase~="CONTACT"or not current then return end
			local ok,err=xpcall(function()
				if player.Character~=character or not root.Parent or externalConnection(root,character)then return end
				if current.Body.Parent and finiteVector(current.Body.Position)
					and (current.Body.Position-current.ContactFrame.Position).Magnitude>=CONFIG.Displacement then
					recordAttempt()
				end
			end,debug.traceback)
			if not ok then log("ERROR "..tostring(err));self:Stop("Error al finalizar contacto.")end
		end)
		runtime[#runtime+1]=RunService.Heartbeat:Connect(function(dt)
			local ok,err=xpcall(function()
				if not self.Running then return end
				local currentCharacter,currentHumanoid,currentRoot,torso=rig()
				if currentCharacter~=character or currentRoot~=root or currentHumanoid~=humanoid then self:Stop("Tu personaje cambio o murio.");return end
				if owner.Parent~=Players then self:Stop("El propietario seleccionado salio.");return end
				if conflicts()then self:Stop("Otro flujo fue activado.");return end
				preventSeat()
				if humanoid.Sit or humanoid.SeatPart or externalConnection(root,character)then
					-- Do not move an externally welded assembly or disable monitoring future spawns.
					destroyFlinger();current=nil
					if self.Phase~="WAIT_RELEASE"then log("WAIT_RELEASE external seat/assembly")end
					self.Phase="WAIT_RELEASE";return
				end
				if self.Phase=="WAIT_RELEASE"then
					self.Phase="HOME";homeUntil=os.clock()+CONFIG.HomeTime;home()
				end
				scanElapsed=scanElapsed+dt
				if scanElapsed>=0.25 then scanElapsed=0;scan()end
				if self.Phase=="CONTACT"then
					if not current or not eligible(current)then
						log("CONTACT_CANCELLED occupied/removed/owner_changed")
						current=nil;self.Phase="HOME";homeUntil=os.clock()+CONFIG.HomeTime
						if not home()then self:Stop("No se pudo regresar de forma independiente.")end
						return
					end
					if (current.Body.Position-current.ContactFrame.Position).Magnitude>=CONFIG.Displacement
						or os.clock()-contactStarted>=CONFIG.ContactTime then recordAttempt();return end
				else
					if not home()then self:Stop("No se pudo mantener el checkpoint.");return end
					if os.clock()<homeUntil then return end
					for vehicle,record in pairs(self.Records)do
						if not record.Done then local target=resolve(vehicle);if target then current=target;break end end
					end
					if not current then return end
					current.ContactFrame=current.Body.CFrame
					self.Phase="CONTACT";contactStarted=os.clock();self.Direction=1
					flinger=Instance.new("BodyVelocity");flinger.Name="NoMotosFlinger";flinger.P=CONFIG.P
					flinger.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
					flinger.Velocity=Vector3.new(CONFIG.Speed,CONFIG.Speed,CONFIG.Speed);flinger.Parent=root
					log("CONTACT_BEGIN Body + "..torso.Name)
				end
				self.Direction=-self.Direction
				-- Contact is fixed at entry: never chase a motorcycle after it leaves.
				local desired=(current.ContactFrame*CFrame.new(0,CONFIG.Height*self.Direction,0)).Position
				-- Translate HRP by the live torso offset, preserving our rotation.
				local offset=torso.Position-root.Position
				root.CFrame=CFrame.new(desired-offset)*root.CFrame.Rotation
				root.AssemblyLinearVelocity=Vector3.new(0,CONFIG.Speed*self.Direction,0)
				root.AssemblyAngularVelocity=Vector3.new(CONFIG.Speed,CONFIG.Speed,CONFIG.Speed)
			end,debug.traceback)
			if not ok then log("ERROR "..tostring(err));self:Stop("Error en No motos; fuerzas retiradas.")end
		end)
		scan();log("START owner="..owner.Name.." UserId="..owner.UserId)
		refresh("No motos activo: solo motos libres del propietario seleccionado; sin garantia de desplazamiento.")
		return true
	end
	function core:ForceReturn()
		if self.Running then return self:Stop("Regreso solicitado.")end
		if self.Stopping then return true end
		local c,h,r=rig()
		if not self.LastCheckpoint or not r or r.Anchored or externalConnection(r,c)then return false,"No hay regreso independiente disponible."end
		r.CFrame=self.LastCheckpoint;r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
		return true
	end
	function core:GetDiagnosticReport()
		return "NO MOTOS V1 | local observations only; displacement does not prove replication\nOwner="..tostring(self.Owner and self.Owner.UserId).." Running="..tostring(self.Running).." Phase="..self.Phase.." Completed="..self.Completed
			.."\nLastStartFailure="..tostring(self.LastStartFailure or "none")
			.."\nContact/Home=0.05s Speed=900000000 P=1250 | free motorcycles only | anti-seat local enabled while running | 3 attempts or 20 studs\n"..table.concat(self.Rows,"\n")
	end
	function core:Destroy()self:Stop("GUI cerrada.");if self.Stopping then self:FinishStop()end end
	return true
end
