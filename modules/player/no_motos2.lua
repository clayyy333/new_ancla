-- Independent car-fling adaptation: our vehicle -> owner's vehicle assembly collider.
return function(context)
	setfenv(1,context)
	local C={Running=false,Stopping=false,Phase="IDLE",Rows={},AutoEnabled=false,TestOccupiedTargets=true}
	-- Temporary test switch: false restores the previous free/unanchored-target filter.
	local occupiedTest=false
	local autoConnection,autoOwner,autoElapsed,autoLastError
	NoMotos2Core=C
	local speed=900000000
	local source,root,collider,checkpoint,force,target,connection,verification,watch
	local elapsed,origin,completed,direction
	local function finite(v)
		return v and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<math.huge and math.abs(v.Y)<math.huge and math.abs(v.Z)<math.huge
	end
	local function refresh(message)if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel(message)end end
	local function log(message)
		C.Rows[#C.Rows+1]=message
		if #C.Rows>100 then table.remove(C.Rows,1)end
	end
	local function owned(v,p)
		local id=tonumber(v:GetAttribute("VehicleOwner"))
		local value=v:FindFirstChild("VehicleOwner")
		local owner=value and value:IsA("ObjectValue")and value.Value
		return (not id or id==p.UserId)and (not owner or owner==p)and (id==p.UserId or owner==p)
	end
	local function vehicleRoot(v)
		local mover=v:FindFirstChild("MoverModel")
		local body=mover and mover:FindFirstChild("Body")
		local parts=v:GetDescendants()
		if v:IsA("BasePart")then parts[#parts+1]=v end
		local groups,order={},{}
		for _,p in ipairs(parts)do
			if p:IsA("BasePart")and (p==v or p:IsDescendantOf(v))then
				local assembly=p.AssemblyRootPart
				if assembly then
					local g=groups[assembly]
					if not g then g={Root=assembly,Member=p,Count=0,Volume=0};groups[assembly]=g;order[#order+1]=g end
					g.Count=g.Count+1
					if p.CanCollide and finite(p.Position)and finite(p.Size)then
						g.Volume=g.Volume+p.Size.X*p.Size.Y*p.Size.Z;g.Collidable=true
					end
				end
			end
		end
		-- Keep the previously working Body when its assembly can actually collide.
		if body and body:IsA("BasePart")and body.AssemblyRootPart then
			local g=groups[body.AssemblyRootPart]
			if g and g.Collidable then return body end
		end
		local best
		for _,g in ipairs(order)do
			if g.Collidable and (not best or g.Count>best.Count or (g.Count==best.Count and g.Volume>best.Volume))then best=g end
		end
		if best then
			if best.Root==v or best.Root:IsDescendantOf(v)then return best.Root end
			return best.Member
		end
	end
	local function contactPart(v,r)
		if r.CanCollide then return r end
		for _,p in ipairs(v:GetDescendants())do
			if p:IsA("BasePart")and p.CanCollide and not p.Anchored and p.AssemblyRootPart==r.AssemblyRootPart then return p end
		end
	end
	local function contactPosition(t)
		local body=t.Body
		local n=body.CFrame:VectorToWorldSpace(t.Face)
		local localNormal=collider.CFrame:VectorToObjectSpace(n)
		local extent=(math.abs(localNormal.X)*collider.Size.X+math.abs(localNormal.Y)*collider.Size.Y+math.abs(localNormal.Z)*collider.Size.Z)*0.5
		local facePoint=body.CFrame:PointToWorldSpace(Vector3.new(t.Face.X*body.Size.X*0.5,0,t.Face.Z*body.Size.Z*0.5))
		local center=facePoint+n*math.max(0,extent-0.05)
		return center-(collider.Position-root.Position),center
	end
	local function free(v)
		for _,part in ipairs(v:GetDescendants())do
			if (part:IsA("Seat")or part:IsA("VehicleSeat"))and (part.Occupant or part:FindFirstChild("SeatWeld"))then return false end
		end
		local weld=v:FindFirstChild("WeldToPlayer")
		return not (weld and weld:IsA("WeldConstraint")and weld.Enabled and weld.Part0 and weld.Part1)
	end
	local function sourceSafe()
		local cars=workspace:FindFirstChild("Cars")
		if not source or source.Parent~=cars or not owned(source,player)or not root or not root.Parent or root.Anchored or vehicleRoot(source)~=root or not finite(root.Position)then return false end
		if collider and (not collider.Parent or (collider~=source and not collider:IsDescendantOf(source))or not collider.CanCollide or collider.Anchored or collider.AssemblyRootPart~=root.AssemblyRootPart)then return false end
		local assembly=root.AssemblyRootPart
		if not assembly or assembly.Anchored then return false end
		for _,part in ipairs(source:GetDescendants())do
			if (part:IsA("Seat")or part:IsA("VehicleSeat"))and part.Occupant and part.Occupant.Parent~=player.Character then return false end
		end
		local ok,parts=pcall(function()return root:GetConnectedParts(true)end)
		if not ok then return false end
		for _,p in ipairs(parts)do
			if p~=source and not p:IsDescendantOf(source)and not (player.Character and p:IsDescendantOf(player.Character))then return false end
		end
		return true
	end
	local function resolve(v)
		local cars=workspace:FindFirstChild("Cars")
		if v==source or v.Parent~=cars or not owned(v,C.Owner)or (not occupiedTest and not free(v))then return end
		-- Rank actual assemblies, not model names, animations, seats or Body paths.
		-- Main assembly heuristic: most vehicle parts; largest collision volume breaks ties.
		local parts=v:GetDescendants()
		if v:IsA("BasePart")then parts[#parts+1]=v end
		local groups,order={},{}
		for _,p in ipairs(parts)do
			if p:IsA("BasePart")and (p==v or p:IsDescendantOf(v))then
				local assembly=p.AssemblyRootPart
				if assembly and (occupiedTest or (not p.Anchored and not assembly.Anchored and (assembly==v or assembly:IsDescendantOf(v))))then
					local g=groups[assembly]
					if not g then g={Count=0,Volume=0};groups[assembly]=g;order[#order+1]=g end
					g.Count=g.Count+1
					if p.CanCollide and finite(p.Position)and finite(p.Size)then
						local volume=p.Size.X*p.Size.Y*p.Size.Z
						g.Volume=g.Volume+volume
						if volume>0 and (not g.Part or volume>g.PartVolume)then g.Part=p;g.PartVolume=volume end
					end
				end
			end
		end
		local best
		for _,g in ipairs(order)do
			if g.Part and (not best or g.Count>best.Count or (g.Count==best.Count and g.Volume>best.Volume))then best=g end
		end
		if best then return best.Part end -- Incomplete spawns remain eligible for the next scan.
	end
	local function observe(t)
		local body=t.Body
		local assembly=body.AssemblyRootPart
		local occupants={}
		for _,seat in ipairs(t.Vehicle:GetDescendants())do
			if (seat:IsA("Seat")or seat:IsA("VehicleSeat"))and seat.Occupant then
				occupants[#occupants+1]=seat.Occupant.Parent and seat.Occupant.Parent.Name or "unknown"
			end
		end
		table.sort(occupants)
		local state="occupants="..table.concat(occupants,",").." DriverId="..tostring(t.Vehicle:GetAttribute("DriverId"))
			.." Body.Anchored="..tostring(body.Anchored).." Assembly.Anchored="..tostring(assembly and assembly.Anchored)
			.." AssemblyRoot="..tostring(assembly and assembly:GetFullName())
		if state~=t.Observed then t.Observed=state;log(string.format("t=%.3f TARGET_STATE %s",os.clock(),state))end
	end
	local function clear()
		if force then force:Destroy();force=nil end
	end
	local function home()
		clear()
		if not sourceSafe()then return false end
		root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
		root.CFrame=checkpoint
		return true
	end
	function C:Stop(message)
		local active=self.Running
		self.Running=false
		if connection then connection:Disconnect();connection=nil end
		if verification then verification:Disconnect();verification=nil end
		if watch then watch:Disconnect();watch=nil end
		clear();target=nil
		if active then
			local returned=home()
			self.LastMessage=message or (returned and "No motos 2 detenido; vehiculo devuelto y velocidades limpiadas."or "No motos 2 detenido; regreso omitido por cambio de propietario o union externa.")
			log(self.LastMessage);refresh(self.LastMessage)
		end
		self.Phase="IDLE"
		return active
	end
	local function conflict()
		for _,name in ipairs({"NoMotosCore","ExperimentalFlingCore","CarFling","CarFlingXeno","CarFling2Delta","CarFling2Xeno","Fling2Core","Fling2EfficientCore","ContactFlingController","MotoFlingCore","MotoFlingXenoCore","CustomFlingCore","MobileAnchorCore","MobileAnchorV11Core","StaticPassThroughAnchorCore","VerticalControlController"})do
			local other=context[name]
			if other and (other.Running or other.Stopping)then return name end
		end
		if AnchorCore and (AnchorCore.AnclaEnabled or AnchorCore.TestEnabled)then return "Ancla"end
		if AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)then return "Ancla automatica"end
	end
	function C:Start(owner,detectedCar)
		if not ExperimentalFlingCore or not ExperimentalFlingCore:IsAuthorized()then return false,"Solo owners."end
		if not owner or not owner:IsA("Player")or owner.Parent~=Players or owner==player then return false,"Selecciona al otro propietario de la moto."end
		if self.Running then
			if self.Owner==owner then return true end
			detectedCar=detectedCar or source
			self:Stop("Cambio de propietario objetivo.")
		end
		local other=conflict();if other then return false,"Desactiva primero: "..other end
		local cars=workspace:FindFirstChild("Cars")
		if not cars then return false,"Workspace.Cars no esta disponible."end
		local chosen=detectedCar or (CarFling and CarFling:GetCar())
		if chosen and (chosen.Parent~=cars or not owned(chosen,player))then return false,"El auto seleccionado ya no es tuyo o no esta disponible."end
		if not chosen then
			for _,v in ipairs(cars:GetChildren())do
				if v.Parent==cars and owned(v,player)and vehicleRoot(v)then
					if chosen then return false,"Tienes varios vehiculos: selecciona el tuyo en Fling con auto."end
					chosen=v
				end
			end
		end
		if not chosen then return false,"Necesitas un vehiculo propio para No motos 2."end
		source=chosen;root=vehicleRoot(source);collider=root and contactPart(source,root)
		if not collider then return false,"Tu vehiculo no tiene una pieza colisionable en su ensamblaje principal."end
		if not sourceSafe()then return false,"Tu vehiculo esta anclado, unido a otro usuario o no tiene ensamblaje valido."end
		occupiedTest=self.TestOccupiedTargets
		checkpoint=root.CFrame;self.Owner=owner;self.Rows={};completed={};elapsed=1;target=nil
		self.LastArrivalObserved=false;self.LastContactError=nil
		direction=1
		self.Running=true;self.Phase="WAIT_MOTORCYCLE"
		local generations,spawnOrder,spawnSerial={},{},0
		local readiness,referenceReadiness={},{}
		local function watchReference(value)
			if value and value:IsA("ObjectValue")and value.Name=="VehicleOwner"and not referenceReadiness[value]then
				referenceReadiness[value]=value:GetPropertyChangedSignal("Value"):Connect(function()elapsed=1 end)
			end
		end
		local function remember(v)
			spawnSerial=spawnSerial+1;spawnOrder[v]=spawnSerial
			if not readiness[v]then readiness[v]=v:GetAttributeChangedSignal("VehicleOwner"):Connect(function()elapsed=1 end)end
			watchReference(v:FindFirstChild("VehicleOwner"))
		end
		for _,v in ipairs(cars:GetChildren())do remember(v)end
		local function available(v,body)
			local record=completed[v]
			if not record or record.Part~=body then return true end
			-- Some games reuse the same Part and teleport it back instead of reparenting.
			local returned=(body.Position-record.Origin).Magnitude<=8
			local movedBack=(body.Position-record.Position).Magnitude>=12
			if body.AssemblyRootPart~=record.Assembly or (returned and movedBack)then
				completed[v]=nil;log("REARM reused assembly/returned vehicle "..v:GetFullName());return true
			end
			return false
		end
		local function choose()
			local selected,selectedBody,selectedOrder=nil,nil,-1
			for _,v in ipairs(cars:GetChildren())do
				if not spawnOrder[v]then remember(v)end
				local body=resolve(v)
				if body and available(v,body)and spawnOrder[v]>selectedOrder then
					selected,selectedBody,selectedOrder=v,body,spawnOrder[v]
				end
			end
			if selected then
				local v,body=selected,selectedBody
				if target and target.Vehicle==v and target.Body==body and target.Generation==(generations[v]or 0)then return end
				clear()
					local relative=body.CFrame:PointToObjectSpace(root.Position)
					local face
					if math.abs(relative.X)/math.max(body.Size.X,0.001)>math.abs(relative.Z)/math.max(body.Size.Z,0.001)then
						face=Vector3.new(relative.X>=0 and 1 or -1,0,0)
					else face=Vector3.new(0,0,relative.Z>=0 and 1 or -1)end
					target={Vehicle=v,Body=body,Face=face,Generation=generations[v]or 0};self.TargetBody=body
					self.LastArrivalObserved=false;self.LastContactError=nil
					origin=body.Position
					self.Phase="CONTACT";log("TARGET "..v:GetFullName().." CONTACT_PART="..body:GetFullName());observe(target);return
			end
		end
		local descendants=cars.DescendantAdded:Connect(function(item)watchReference(item);elapsed=1 end)
		local children=cars.ChildAdded:Connect(function(v)
			completed[v]=nil;generations[v]=(generations[v]or 0)+1
			-- Record the spawn even before VehicleOwner/descendants have replicated.
			remember(v)
			elapsed=1
		end)
		watch={Disconnect=function()
			descendants:Disconnect();children:Disconnect()
			for _,c in pairs(readiness)do c:Disconnect()end
			for _,c in pairs(referenceReadiness)do c:Disconnect()end
		end}
		connection=RunService.PreSimulation:Connect(function(dt)
			local ok,err=xpcall(function()
				if not self.Running then return end
				if owner.Parent~=Players or workspace:FindFirstChild("Cars")~=cars or not sourceSafe()or conflict()then self:Stop("No motos 2: vehiculo, propietario o flujo cambio.");return end
				if target then
					observe(target)
					if target.Generation~=(generations[target.Vehicle]or 0)then
						log("TARGET_RESPAWN generation changed");target=nil;self.TargetBody=nil;home();self.Phase="WAIT_MOTORCYCLE";elapsed=1
					elseif resolve(target.Vehicle)~=target.Body then
						log("CONTACT_CANCELLED");target=nil;home();self.Phase="WAIT_MOTORCYCLE"
					elseif (target.Body.Position-origin).Magnitude>=20 then
						completed[target.Vehicle]={Part=target.Body,Origin=origin,Position=target.Body.Position,Assembly=target.Body.AssemblyRootPart}
						log("DISPLACED >=20 studs");target=nil;self.TargetBody=nil;home();self.Phase="WAIT_MOTORCYCLE"
					end
				end
				elapsed=elapsed+dt
				if elapsed>=0.25 then
					elapsed=0
					for v in pairs(spawnOrder)do
						if v.Parent~=cars then
							completed[v]=nil;generations[v]=nil;spawnOrder[v]=nil
							if readiness[v]then readiness[v]:Disconnect();readiness[v]=nil end
						end
					end
					for v,c in pairs(referenceReadiness)do if not v:IsDescendantOf(cars)then c:Disconnect();referenceReadiness[v]=nil end end
					choose()
				end
				if not target then return end
				if not force then
					force=Instance.new("BodyVelocity");force.Name="NoMotos2CarFlinger";force.P=1250
					force.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
					force.Velocity=Vector3.new(speed,speed,speed);force.Parent=root
					log("SUSTAINED_CONTACT original car forces=900000000; no far travel")
				end
				local position,center=contactPosition(target)
				target.LastContactPoint=center
				-- Restore the original contact writes, but never enter a FAR/return cycle.
				root.CFrame=CFrame.new(position)*root.CFrame.Rotation
				direction=-direction
				root.AssemblyLinearVelocity=Vector3.new(0,speed*direction,0)
				root.AssemblyAngularVelocity=Vector3.new(speed,speed,speed)
				self.Phase="CONTACT"
			end,debug.traceback)
			if not ok then log(tostring(err));self:Stop("Error en No motos 2; fuerzas retiradas.")end
		end)
		verification=RunService.PostSimulation:Connect(function()
			if not self.Running or not target or not force then return end
			local ok,err=xpcall(function()
				if not root.Parent or not collider.Parent or not target.Body.Parent or player.Character==nil then return end
				local _,expected=contactPosition(target)
				local distance=(collider.Position-expected).Magnitude
				if distance~=distance or distance==math.huge then self:Stop("Posicion de contacto no valida.");return end
				self.LastContactError=distance;self.LastArrivalObserved=distance<=1
				local phase=self.LastArrivalObserved and "CONTACT"or "RECOVERING"
				if phase~=target.VerifiedPhase then
					target.VerifiedPhase=phase
					log(string.format("POST_SIMULATION %s geometry_error=%.3f (not collision proof)",phase,distance))
				end
				self.Phase=phase
			end,debug.traceback)
			if not ok then log(tostring(err));self:Stop("Error verificando contacto.")end
		end)
		choose();log("START source="..source:GetFullName())
		refresh("No motos 2: tu vehiculo contra vehiculos de @"..owner.Name..(occupiedTest and ". Incluye ocupados; pieza colisionable elegida por ensamblaje."or ". Solo vehiculos libres; contacto por ensamblaje."))
		return true
	end
	function C:ForceReturn()
		if self.Running then return self:Stop("Regreso de No motos 2 solicitado.")end
		return checkpoint and home()or false,"No hay regreso seguro disponible."
	end
	function C:SetTargetOwner(owner)
		if not owner or not owner:IsA("Player")or owner.Parent~=Players or owner==player then return false,"Selecciona otro usuario del servidor."end
		local changed=self.Owner~=owner or (self.AutoEnabled and autoOwner~=owner)
		if not changed then return true end
		local resume=self.Running and not self.AutoEnabled
		local previousSource=source
		if self.Running then self:Stop("Cambio de propietario objetivo.")end
		self.Owner=owner;self.TargetBody=nil
		if self.AutoEnabled then
			autoOwner=owner;self.AutoOwnerId=owner.UserId;autoElapsed=0.25;autoLastError=nil
			refresh("Automatico: objetivo actualizado a @"..owner.Name.."; buscando sus vehiculos.")
		elseif resume then return self:Start(owner,previousSource)end
		return true
	end
	function C:SetAutoEnabled(enabled,owner)
		if enabled and (not ExperimentalFlingCore or not ExperimentalFlingCore:IsAuthorized())then return false,"Solo owners."end
		if enabled and (not owner or owner.Parent~=Players or owner==player)then return false,"Selecciona primero al propietario objetivo."end
		if enabled and self.Running and self.Owner~=owner then self:Stop("Cambio de propietario objetivo.")end
		if enabled then
			if self.Owner~=owner then self.TargetBody=nil end
			self.Owner=owner
		end
		if autoConnection then autoConnection:Disconnect();autoConnection=nil end
		self.AutoEnabled=enabled and true or false;autoOwner=owner;autoElapsed=0.25;autoLastError=nil
		self.AutoOwnerId=owner and owner.UserId;self.AutoStatus=enabled and "WAIT_SOURCE"or "OFF"
		if not self.AutoEnabled then self:Stop("Activacion automatica desactivada.");refresh("Activacion automatica de No motos 2 desactivada.");return true end
		autoConnection=RunService.Heartbeat:Connect(function(dt)
			autoElapsed=autoElapsed+dt;if autoElapsed<0.25 then return end;autoElapsed=0
			if not autoOwner or autoOwner.Parent~=Players then self:SetAutoEnabled(false);return end
			-- Independent spawn discovery, like car2's syncSpawnedCar. Do not read or
			-- mutate another fling panel's selection or require that panel to be opened.
			local selected,ownedCount=nil,0
			local cars=workspace:FindFirstChild("Cars")
			if cars then
				for _,v in ipairs(cars:GetChildren())do
					if v.Parent==cars and owned(v,player)then
						ownedCount=ownedCount+1
						local r=vehicleRoot(v)
						if r and r.Parent and contactPart(v,r)then selected=v end
					end
				end
			end
			if not selected then
				local message=ownedCount>0 and "Automatico: tu vehiculo esta detectado, esperando ensamblaje y pieza colisionable."
					or ("Automatico: no se detecta un vehiculo de @"..player.Name.." (UserId="..player.UserId..").")
				self.AutoStatus=message
				if autoLastError~=message then autoLastError=message;refresh(message)end
			else self.AutoStatus="SOURCE_DETECTED "..selected:GetFullName()end
			if self.Running and (selected~=source or self.Owner~=autoOwner)then self:Stop("Cambio de auto o propietario objetivo.")end
			if not self.Running and selected then
				local called,ok,err=xpcall(function()return self:Start(autoOwner,selected)end,debug.traceback)
				if not called then err=tostring(ok);ok=false;self:Stop("Error al activar automaticamente.")end
				if not ok and err~=autoLastError then autoLastError=err;refresh(err)elseif ok then autoLastError=nil end
			end
		end)
		refresh("Automatico activo: elige/spawnea tu auto en la GUI del juego; se detecta por propietario. Objetivo: motos de @"..owner.Name)
		return true
	end
	function C:GetDiagnosticReport()return "NO MOTOS 2 V8 SPAWN PRIORITY PRE/POST | client observations only; not server authority\nRunning="..tostring(self.Running).." AutoEnabled="..tostring(self.AutoEnabled).." TestOccupiedTargets="..tostring(occupiedTest).." Phase="..self.Phase.."\nLocalUserId="..player.UserId.." TargetOwnerId="..tostring(self.AutoOwnerId or (self.Owner and self.Owner.UserId)).." AutoStatus="..tostring(self.AutoStatus).."\nArrivalObserved="..tostring(self.LastArrivalObserved).." GeometryError="..tostring(self.LastContactError).." (not collision/replication proof); contact writes=PreSimulation; verification=PostSimulation; ownership/descendant events accelerate discovery\nSourceContactPart="..tostring(collider and collider:GetFullName()).." overlap=0.05 studs; target: owner's vehicles, no motorcycle/name/Body filter; main assembly ranked by part count then collision volume; largest collidable part selected; BodyVelocity diagonal=900000000 per axis; alternating vertical=900000000; angular XYZ=900000000; NO FAR TRAVEL\n"..table.concat(self.Rows,"\n")end
	function C:Destroy()self:SetAutoEnabled(false);self:Stop("No motos 2: GUI cerrada.")end
	return true
end
