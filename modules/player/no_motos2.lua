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
	local elapsed,origin,completed
	local function finite(v)
		return v and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<math.huge and math.abs(v.Y)<math.huge and math.abs(v.Z)<math.huge
	end
	local function refresh(message)if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel(message)end end
	local function log(message)
		C.Rows[#C.Rows+1]=message
		if #C.Rows>100 then table.remove(C.Rows,1)end
	end
	local function owned(v,p)
		local value=v:FindFirstChild("VehicleOwner")
		local owner=value and value:IsA("ObjectValue")and value.Value
		-- Match the vehicle selector: a populated Player reference is authoritative
		-- for selection; only fall back to the attribute while that reference is empty.
		if owner then return owner:IsA("Player")and owner.UserId==p.UserId end
		return tonumber(v:GetAttribute("VehicleOwner"))==p.UserId
	end
	local function targetOwned(v,p)
		-- Resolve target ownership directly, like the original vehicle selector:
		-- a populated Player reference takes precedence over a possibly stale attribute.
		local value=v:FindFirstChild("VehicleOwner")
		local owner=value and value:IsA("ObjectValue")and value.Value
		if owner then return owner:IsA("Player")and owner.UserId==p.UserId end
		return tonumber(v:GetAttribute("VehicleOwner"))==p.UserId
	end
	local function vehicleRoot(v)
		-- Same reference-selection order as Fling con vehiculo's findCarRoot.
		-- Keep this local: never call or alter the original fling controller.
		if not v then return nil end
		if v:IsA("BasePart")then return v end
		if v.PrimaryPart then return v.PrimaryPart end
		for _,name in ipairs({"Body","Chassis","HumanoidRootPart","VehicleSeat","DriveSeat","Seat","WheelB","W"})do
			local p=v:FindFirstChild(name,true)
			if p and p:IsA("BasePart")then return p end
		end
		for _,p in ipairs(v:GetDescendants())do
			if p:IsA("BasePart")and not p.Anchored then return p end
		end
		for _,p in ipairs(v:GetDescendants())do
			if p:IsA("BasePart")then return p end
		end
	end
	local function contactPart(v,r)
		if r.CanCollide then return r end
		for _,p in ipairs(v:GetDescendants())do
			if p:IsA("BasePart")and p.CanCollide and not p.Anchored and p.AssemblyRootPart==r.AssemblyRootPart then return p end
		end
	end
	local function contactPosition(t)
		-- Align the source collision-part center, not merely the vehicle root.
		local reference=collider or root
		local center=t.Body.Position
		return center-(reference.Position-root.Position),center
	end
	local function free(v)
		for _,part in ipairs(v:GetDescendants())do
			if (part:IsA("Seat")or part:IsA("VehicleSeat"))and (part.Occupant or part:FindFirstChild("SeatWeld"))then return false end
		end
		local weld=v:FindFirstChild("WeldToPlayer")
		return not (weld and weld:IsA("WeldConstraint")and weld.Enabled and weld.Part0 and weld.Part1)
	end
	local function characterAnchorActive()
		for _,name in ipairs({"AnchorCore","MobileAnchorCore","MobileAnchorV11Core","StaticPassThroughAnchorCore","VerticalControlController","DeploymentAnchorMotorCore","EmergencyAnchorController"})do
			local a=context[name]
			if a and (a.Running or a.Stopping or a.AnclaEnabled or a.TestEnabled or a.AntiSeatEnabled or a.HeartbeatEnabled)then return true end
		end
		return AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)or false
	end
	local function sourceSafe()
		local cars=workspace:FindFirstChild("Cars")
		if not source or source.Parent~=cars or not owned(source,player)or not root or not root.Parent or (root~=source and not root:IsDescendantOf(source))or root.Anchored or not finite(root.Position)then return false end
		if collider and (not collider.Parent or (collider~=source and not collider:IsDescendantOf(source))or not collider.CanCollide or collider.Anchored or collider.AssemblyRootPart~=root.AssemblyRootPart)then return false end
		local assembly=root.AssemblyRootPart
		if not assembly or assembly.Anchored then return false end
		for _,part in ipairs(source:GetDescendants())do
			if (part:IsA("Seat")or part:IsA("VehicleSeat"))and part.Occupant and part.Occupant.Parent~=player.Character then return false end
		end
		local ok,parts=pcall(function()return root:GetConnectedParts(true)end)
		if not ok then return false end
		for _,p in ipairs(parts)do
			if p~=source and not p:IsDescendantOf(source)then
				if not (player.Character and p:IsDescendantOf(player.Character))then return false end
				-- Character anchors are compatible only when physically independent of our car.
				if p.Anchored or characterAnchorActive()then return false end
			end
		end
		return true
	end
	local function resolve(v)
		local cars=workspace:FindFirstChild("Cars")
		if v==source then return nil,"source vehicle"end
		if v.Parent~=cars then return nil,"not in Workspace.Cars"end
		if not targetOwned(v,C.Owner)then return nil,"owner mismatch"end
		if not occupiedTest and not free(v)then return nil,"occupied; free-only mode"end
		-- Preserve V5's Body target for models where that contact already worked.
		local mover=v:FindFirstChild("MoverModel")
		local body=mover and mover:FindFirstChild("Body")
		if body and body:IsA("BasePart")and body.CanCollide and finite(body.Position)then
			local assembly=body.AssemblyRootPart
			if assembly and (occupiedTest or (not body.Anchored and not assembly.Anchored and (assembly==v or assembly:IsDescendantOf(v))))then return body end
		end
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
		if best then return best.Part end
		return nil,"waiting for collidable part with valid assembly" -- Retried; not permanently excluded.
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
	local function refreshSource()
		local nextRoot=vehicleRoot(source)
		local nextCollider=nextRoot and contactPart(source,nextRoot)
		if not nextRoot then
			local oldSafe=sourceSafe()
			clear()
			if oldSafe then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
			C.Phase="WAIT_SOURCE_PARTS";C.SourceState="waiting for source physics"
			return false,false
		end
		if nextRoot~=root or nextCollider~=collider then
			local oldRoot=root
			local oldSafe=sourceSafe()
			clear()
			if oldSafe then oldRoot.AssemblyLinearVelocity=Vector3.zero;oldRoot.AssemblyAngularVelocity=Vector3.zero end
			if oldRoot and nextRoot~=oldRoot and oldRoot.AssemblyRootPart==nextRoot.AssemblyRootPart then
				local ok,relative=pcall(function()return oldRoot.CFrame:ToObjectSpace(nextRoot.CFrame)end)
				if ok then checkpoint=checkpoint*relative end
			end
			root,collider=nextRoot,nextCollider
			log("SOURCE_REBOUND root="..root:GetFullName().." collider="..tostring(collider and collider:GetFullName()))
		end
		if not sourceSafe()then return false,true end
		C.SourceState=collider and "ready"or "arrival ready; awaiting source collider"
		return true,false
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
		for _,name in ipairs({"NoMotosCore","ExperimentalFlingCore","CarFling","CarFlingXeno","CarFling2Delta","CarFling2Xeno","Fling2Core","Fling2EfficientCore","ContactFlingController","MotoFlingCore","MotoFlingXenoCore","CustomFlingCore"})do
			local other=context[name]
			if other and (other.Running or other.Stopping)then return name end
		end
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
		if not root then return false,"Tu vehiculo todavia no tiene una referencia fisica disponible."end
		if not sourceSafe()then return false,"Tu vehiculo esta anclado, unido a otro usuario o no tiene ensamblaje valido."end
		self.SourceState=collider and "ready"or "arrival ready; awaiting source collider"
		occupiedTest=self.TestOccupiedTargets
		checkpoint=root.CFrame;self.Owner=owner;self.Rows={};completed={};elapsed=1;target=nil
		self.LastArrivalObserved=false;self.LastContactError=nil
		self.Running=true;self.Phase="WAIT_MOTORCYCLE"
		local generations,spawnOrder,spawnSerial={},{},0
		local observedCharacter=owner.Character
		local observedHRP=observedCharacter and observedCharacter:FindFirstChild("HumanoidRootPart")
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
			local snapshot={}
			for _,v in ipairs(cars:GetChildren())do
				if not spawnOrder[v]then remember(v)end
				local body,reason=resolve(v)
				if v~=source and targetOwned(v,owner)then
					local reference=v:FindFirstChild("VehicleOwner")
					local refOwner=reference and reference:IsA("ObjectValue")and reference.Value
					snapshot[#snapshot+1]=v.Name.." ownerAttr="..tostring(v:GetAttribute("VehicleOwner"))
						.." ownerRef="..tostring(refOwner and refOwner.Name).." result="..tostring(body and body:GetFullName()or reason)
				end
				if body and available(v,body)and spawnOrder[v]>selectedOrder then
					selected,selectedBody,selectedOrder=v,body,spawnOrder[v]
				end
			end
			self.TargetScan=#snapshot>0 and table.concat(snapshot,"\n")or "No vehicle matched the selected owner in Workspace.Cars."
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
		-- Restore the original working write phase; spawn prioritization stays event-driven.
		connection=RunService.Heartbeat:Connect(function(dt)
			local ok,err=xpcall(function()
				if not self.Running then return end
				if owner.Parent~=Players or workspace:FindFirstChild("Cars")~=cars or not source or source.Parent~=cars or not owned(source,player)or conflict()then self:Stop("No motos 2: vehiculo, propietario o flujo cambio.");return end
				local character=owner.Character
				local hrp=character and character:FindFirstChild("HumanoidRootPart")
				if character~=observedCharacter or hrp~=observedHRP then
					observedCharacter,observedHRP=character,hrp
					-- A character/root replacement starts a fresh target-selection epoch.
					-- Do not carry completed-contact records across the owner's respawn.
					clear();target=nil;self.TargetBody=nil;completed={};elapsed=1
					self.LastArrivalObserved=false;self.LastContactError=nil
					self.Phase="WAIT_MOTORCYCLE"
					log("TARGET_CHARACTER_REBOUND completed records cleared; reacquiring vehicle by owner")
				end
				local ready,unsafe=refreshSource()
				if not ready then
					if unsafe then self:Stop("No motos 2: tu vehiculo esta anclado o unido a otro personaje.")end
					return
				end
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
				if not collider then
					clear()
					local position=contactPosition(target)
					root.CFrame=CFrame.new(position)*root.CFrame.Rotation
					self.Phase="ARRIVAL_WAIT_CONTACT"
					return
				end
				if not force then
					force=Instance.new("BodyVelocity");force.Name="NoMotos2CarFlinger";force.P=1250
					force.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
					force.Velocity=Vector3.new(speed,speed,speed)
					force.Parent=root
					log("SUSTAINED_CONTACT speedXYZ=900000000 angularY=900000000 angularXZ=0; alternating vertical write removed; no far travel")
				end
				local position,center=contactPosition(target)
				target.LastContactPoint=center
				root.CFrame=CFrame.new(position)*root.CFrame.Rotation
				-- BodyVelocity is the only linear driver during contact.
				root.AssemblyAngularVelocity=Vector3.new(0,speed,0)
				self.Phase="CONTACT"
			end,debug.traceback)
			if not ok then log(tostring(err));self:Stop("Error en No motos 2; fuerzas retiradas.")end
		end)
		verification=RunService.PostSimulation:Connect(function()
			if not self.Running or not target or not force then return end
			local ok,err=xpcall(function()
				if not root.Parent or not collider or not collider.Parent or not target.Body.Parent or player.Character==nil then return end
				local _,expected=contactPosition(target)
				local distance=(collider.Position-expected).Magnitude
				if distance~=distance or distance==math.huge then
					self.LastArrivalObserved=false;self.Phase="RECOVERING";return
				end
				self.LastContactError=distance;self.LastArrivalObserved=distance<=1
				local phase=self.LastArrivalObserved and "CONTACT"or "RECOVERING"
				if phase~=target.VerifiedPhase then
					target.VerifiedPhase=phase
					log(string.format("POST_SIMULATION %s geometry_error=%.3f (not collision proof)",phase,distance))
				end
				self.Phase=phase
			end,debug.traceback)
			if not ok then
				self.LastArrivalObserved=false
				if self.LastVerificationError~=tostring(err)then self.LastVerificationError=tostring(err);log("VERIFICATION_ONLY_ERROR "..tostring(err))end
			end
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
						-- Keep the newest owned instance even while its physics is loading.
						selected=v
					end
				end
			end
			local selectedRoot=selected and vehicleRoot(selected)
			local sourceReady=selectedRoot and selectedRoot.Parent
			if not selected or not sourceReady then
				local message=ownedCount>0 and "Automatico: tu vehiculo esta detectado, esperando ensamblaje y pieza colisionable."
					or ("Automatico: no se detecta un vehiculo de @"..player.Name.." (UserId="..player.UserId..").")
				self.AutoStatus=message
				if autoLastError~=message then autoLastError=message;refresh(message)end
			else self.AutoStatus="SOURCE_DETECTED "..selected:GetFullName()end
			if self.Running and (selected~=source or self.Owner~=autoOwner)then self:Stop("Cambio de auto o propietario objetivo.")end
			if not self.Running and selected and sourceReady then
				local called,ok,err=xpcall(function()return self:Start(autoOwner,selected)end,debug.traceback)
				if not called then err=tostring(ok);ok=false;self:Stop("Error al activar automaticamente.")end
				if not ok and err~=autoLastError then autoLastError=err;refresh(err)elseif ok then autoLastError=nil end
			end
		end)
		refresh("Automatico activo: elige/spawnea tu auto en la GUI del juego; se detecta por propietario. Objetivo: motos de @"..owner.Name)
		return true
	end
	function C:GetDiagnosticReport()
		local function identity(p)return p and (p.Name.."/"..p.UserId)or "nil"end
		local selected=ExperimentalFlingCore and ExperimentalFlingCore.GetTarget and ExperimentalFlingCore:GetTarget()
		local details={"UI target="..identity(selected).." | active owner="..identity(self.Owner).." | automatic owner="..identity(autoOwner)
			.."\nContext local="..identity(player).." | Players.LocalPlayer="..identity(Players.LocalPlayer)}
		local cars=workspace:FindFirstChild("Cars")
		local children=cars and cars:GetChildren()or {}
		details[#details+1]="Workspace.Cars children="..#children.."; snapshot on copy only; no physics writes"
		local localMatches,targetMatches=0,0
		local wanted=autoOwner or self.Owner or selected
		for _,v in ipairs(children)do
			local ok,line=pcall(function()
				local ref=v:FindFirstChild("VehicleOwner")
				local value=ref and ref:IsA("ObjectValue")and ref.Value
				local valueInfo=value and (value:GetFullName().." class="..value.ClassName)or "nil"
				if value and value:IsA("Player")then valueInfo=valueInfo.." UserId="..value.UserId end
				local mine=owned(v,player)
				local theirs=wanted and targetOwned(v,wanted)or false
				if mine then localMatches=localMatches+1 end
				if theirs then targetMatches=targetMatches+1 end
				local physical=""
				if mine then
					local r=vehicleRoot(v);local c=r and contactPart(v,r)
					physical=" sourceRoot="..tostring(r and r:GetFullName()).." sourceCollider="..tostring(c and c:GetFullName())
				end
				return v:GetFullName().." class="..v.ClassName.." VehicleOwnerAttr="..tostring(v:GetAttribute("VehicleOwner"))
					.." OwnerChildClass="..tostring(ref and ref.ClassName).." OwnerValue="..valueInfo
					.." matchesLOCAL="..tostring(mine).." matchesTARGET="..tostring(theirs)..physical
			end)
			details[#details+1]=ok and line or (v.Name.." READ_ERROR="..tostring(line))
		end
		details[#details+1]="MATCH COUNTS local="..localMatches.." target="..targetMatches
		return "NO MOTOS 2 V23 ORIGINAL SOURCE REFERENCE | client observations only; not server authority"
			.."\nRunning="..tostring(self.Running).." AutoEnabled="..tostring(self.AutoEnabled).." TestOccupiedTargets="..tostring(occupiedTest).." Phase="..self.Phase
			.."\nSourceState="..tostring(self.SourceState).." SourceRoot="..tostring(root and root:GetFullName())
			.."\nConfiguredOccupiedTest="..tostring(self.TestOccupiedTargets).." (active TestOccupiedTargets is initialized on Start)"
			.."\nLocalUserId="..player.UserId.." TargetOwnerId="..tostring(self.AutoOwnerId or (self.Owner and self.Owner.UserId)).." AutoStatus="..tostring(self.AutoStatus)
			.."\nArrivalObserved="..tostring(self.LastArrivalObserved).." GeometryError="..tostring(self.LastContactError).." (not collision/replication proof); writes=Heartbeat; verification=read-only PostSimulation"
			.."\nSourceContactPart="..tostring(collider and collider:GetFullName()).." contact=source collider center to target part center; outwardTravel=0; linearXYZ=900000000; angularY=900000000; angularXZ=0; MaxForce=infinite; alternating vertical override=removed; Body priority with generic fallback; NO FAR TRAVEL; independent character anchors allowed"
			.."\nTARGET SCAN:\n"..tostring(self.TargetScan or "No scan yet").."\nEVENTS:\n"..table.concat(self.Rows,"\n")
			.."\nRAW OWNERSHIP SNAPSHOT:\n"..table.concat(details,"\n")
	end
	function C:Destroy()self:SetAutoEnabled(false);self:Stop("No motos 2: GUI cerrada.")end
	return true
end
