-- Independent car-fling adaptation: our vehicle -> unoccupied motorcycle Body.
return function(context)
	setfenv(1,context)
	local C={Running=false,Stopping=false,Phase="IDLE",Rows={}}
	NoMotos2Core=C
	local speed=900000000
	local source,root,collider,checkpoint,force,target,connection,watch
	local elapsed,nearUntil,direction,origin,completed
	local farDistances={4487425,7554477,9193601,11000000,12572022,15000000,17003482,21098414}
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
		if body and body:IsA("BasePart")then return body end
		if v:IsA("BasePart")then return v end
		return v.PrimaryPart
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
		if collider and (not collider.Parent or not collider:IsDescendantOf(source)or not collider.CanCollide or collider.Anchored or collider.AssemblyRootPart~=root.AssemblyRootPart)then return false end
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
		if v==source or v.Parent~=cars or not owned(v,C.Owner)or not free(v)then return end
		local mover=v:FindFirstChild("MoverModel")
		local body=mover and mover:FindFirstChild("Body")
		if not body or not body:IsA("BasePart")or not body.CanCollide or body.Anchored or not finite(body.Position)then return end
		local motorcycle=false
		for _,key in ipairs({"Animation","RunAnim"})do
			if tostring(v:GetAttribute(key)):match("%d+")=="13112445577"then motorcycle=true end
		end
		if not motorcycle and v:GetAttribute("MoverType")=="WheelAttachMover"then
			local count=0
			for _,name in ipairs({"WheelF","WheelB"})do
				local wheel=mover:FindFirstChild(name)
				if wheel then for _,d in ipairs(wheel:GetDescendants())do if d.Name:find("Motorcycle",1,true)then count=count+1;break end end end
			end
			motorcycle=count==2
		end
		local assembly=body.AssemblyRootPart
		if motorcycle and assembly and not assembly.Anchored and (assembly==v or assembly:IsDescendantOf(v))then return body end
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
	function C:Start(owner)
		if not ExperimentalFlingCore or not ExperimentalFlingCore:IsAuthorized()then return false,"Solo owners."end
		if self.Running then return true end
		if not owner or not owner:IsA("Player")or owner.Parent~=Players or owner==player then return false,"Selecciona al otro propietario de la moto."end
		local other=conflict();if other then return false,"Desactiva primero: "..other end
		local cars=workspace:FindFirstChild("Cars")
		if not cars then return false,"Workspace.Cars no esta disponible."end
		local chosen=CarFling and CarFling:GetCar()
		if chosen and (chosen.Parent~=cars or not owned(chosen,player))then return false,"El auto seleccionado ya no es tuyo o no esta disponible."end
		if not chosen then
			for _,v in ipairs(cars:GetChildren())do
				if owned(v,player)and vehicleRoot(v)then
					if chosen then return false,"Tienes varios vehiculos: selecciona el tuyo en Fling con auto."end
					chosen=v
				end
			end
		end
		if not chosen then return false,"Necesitas un vehiculo propio para No motos 2."end
		source=chosen;root=vehicleRoot(source);collider=root and contactPart(source,root)
		if not collider then return false,"Tu vehiculo no tiene una pieza colisionable en su ensamblaje principal."end
		if not sourceSafe()then return false,"Tu vehiculo esta anclado, unido a otro usuario o no tiene ensamblaje valido."end
		checkpoint=root.CFrame;self.Owner=owner;self.Rows={};completed={};elapsed=1;target=nil;direction=1
		self.Running=true;self.Phase="WAIT_MOTORCYCLE"
		local function choose()
			if target then return end
			for _,v in ipairs(cars:GetChildren())do
				local body=resolve(v)
				if body and completed[v]~=body then
					local relative=body.CFrame:PointToObjectSpace(root.Position)
					local face
					if math.abs(relative.X)/math.max(body.Size.X,0.001)>math.abs(relative.Z)/math.max(body.Size.Z,0.001)then
						face=Vector3.new(relative.X>=0 and 1 or -1,0,0)
					else face=Vector3.new(0,0,relative.Z>=0 and 1 or -1)end
					target={Vehicle=v,Body=body,Face=face};self.TargetBody=body
					origin=body.Position;nearUntil=os.clock()+0.04
					self.Phase="NEAR";log("TARGET "..v:GetFullName());return
				end
			end
		end
		watch=cars.DescendantAdded:Connect(function()elapsed=1 end)
		connection=RunService.Heartbeat:Connect(function(dt)
			local ok,err=xpcall(function()
				if not self.Running then return end
				if owner.Parent~=Players or workspace:FindFirstChild("Cars")~=cars or not sourceSafe()or conflict()then self:Stop("No motos 2: vehiculo, propietario o flujo cambio.");return end
				if target then
					if resolve(target.Vehicle)~=target.Body then
						log("CONTACT_CANCELLED");target=nil;home();self.Phase="WAIT_MOTORCYCLE"
					elseif (target.Body.Position-origin).Magnitude>=20 then
						completed[target.Vehicle]=target.Body;log("DISPLACED >=20 studs");target=nil;home();self.Phase="WAIT_MOTORCYCLE"
					end
				end
				elapsed=elapsed+dt
				if not target and elapsed>=0.25 then elapsed=0;choose()end
				if not target then return end
				if not force then
					force=Instance.new("BodyVelocity");force.Name="NoMotos2CarFlinger";force.P=1250
					force.MaxForce=Vector3.new(math.huge,math.huge,math.huge);force.Velocity=Vector3.new(speed,speed,speed);force.Parent=root
				end
				local body=target.Body
				local function near()
					direction=-direction
					local p,center=contactPosition(target)
					target.LastContactPoint=center
					root.CFrame=CFrame.new(p)*root.CFrame.Rotation
					root.AssemblyLinearVelocity=Vector3.new(0,speed*direction,0)
					root.AssemblyAngularVelocity=Vector3.new(speed,speed,speed)
				end
				if self.Phase=="NEAR"then
					near();if os.clock()>=nearUntil then self.Phase="FAR"end
				elseif self.Phase=="FAR"then
					local far=farDistances[math.random(1,#farDistances)]
					local sx=math.random(0,1)==0 and -1 or 1;local sz=math.random(0,1)==0 and -1 or 1
					root.CFrame=CFrame.new(body.Position+Vector3.new(far*sx,far*0.15*direction,far*sz))
					root.AssemblyLinearVelocity=Vector3.new(speed,speed,speed);self.Phase="RETURN_DIRECT"
				elseif self.Phase=="RETURN_DIRECT"then near();self.Phase="VERIFY_RETURN"
				elseif self.Phase=="VERIFY_RETURN"then
					local _,center=contactPosition(target)
					if (collider.Position-center).Magnitude<=4 then self.Phase="NEAR";nearUntil=os.clock()+0.04+math.random()*0.045
					else self.Phase="RETURN_CONTACT"end
				elseif self.Phase=="RETURN_CONTACT"then near();self.Phase="RETURN_NEAR"
				else near();self.Phase="NEAR";nearUntil=os.clock()+0.04 end
			end,debug.traceback)
			if not ok then log(tostring(err));self:Stop("Error en No motos 2; fuerzas retiradas.")end
		end)
		choose();log("START source="..source:GetFullName())
		refresh("No motos 2: tu vehiculo contra motos libres de @"..owner.Name..". Flujo de auto con alejamiento y regreso.")
		return true
	end
	function C:ForceReturn()
		if self.Running then return self:Stop("Regreso de No motos 2 solicitado.")end
		return checkpoint and home()or false,"No hay regreso seguro disponible."
	end
	function C:GetDiagnosticReport()return "NO MOTOS 2 V2 FACE CONTACT | client observations only; OBB alignment, not exact mesh collision geometry\nRunning="..tostring(self.Running).." Phase="..self.Phase.."\nContactPart="..tostring(collider and collider:GetFullName()).." overlap=0.05 studs; no vertical offset\n"..table.concat(self.Rows,"\n")end
	function C:Destroy()self:Stop("No motos 2: GUI cerrada.")end
	return true
end
