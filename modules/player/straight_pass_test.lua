-- One-shot, bounded client physics observation. No remote calls or target writes.
return function(context)
	setfenv(1, context)
	local TARGET_ID = 11773278300
	local SPEED, FAR_DISTANCE, MAX_TIME = 600, 1000000, 0.6
	local incompatible={"ExperimentalFlingCore","Fling2Core","Fling2EfficientCore","CarFling","ContactFlingController","MotoFlingCore","MotoFlingXenoCore","CarFlingXeno","CarFling2Delta","CarFling2Xeno","ObjectFling2Delta","ObjectFling2Xeno","CustomFlingCore"}
	local core = {Running=false, Samples={}, Report="Sin prueba registrada."}
	StraightPassTestCore = core
	local function parts(p)
		local c=p and p.Character
		local h=c and c:FindFirstChildOfClass("Humanoid")
		local r=c and c:FindFirstChild("HumanoidRootPart")
		if h and h.Health>0 and r then return h,r end
	end
	local function refresh(message)
		if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel(message) end
	end
	function core:Stop(reason)
		if self.Connection then self.Connection:Disconnect();self.Connection=nil end
		local wasRunning=self.Running
		self.Running=false
		local returned=false
		if wasRunning and self.Root and self.Root.Parent then
			self.Root.AssemblyLinearVelocity=Vector3.zero
			self.Root.AssemblyAngularVelocity=Vector3.zero
			local humanoid,root=parts(player)
			if root==self.Root and humanoid==self.Humanoid and player.Character==self.Character and self.Checkpoint then
				root.CFrame=self.Checkpoint
				root.AssemblyLinearVelocity=Vector3.zero
				root.AssemblyAngularVelocity=Vector3.zero
				returned=true
			end
		end
		if wasRunning then
			local result=tostring(reason or "Cancelado")..(returned and " Regreso al punto de activacion completado." or " Sin regreso: personaje original no disponible.")
			self.Report="STRAIGHT PASS TEST | observaciones locales; causa del servidor desconocida\n"
				.."Target UserId: "..TARGET_ID.." | velocidad: "..SPEED.." | salto CFrame: "..FAR_DISTANCE
				.."\nResultado: "..result.."\n"..table.concat(self.Samples,"\n")
			self.Checkpoint=nil;self.Character=nil;self.Humanoid=nil;self.Root=nil
			refresh(result)
		end
	end
	function core:GetDiagnosticReport() return self.Report end
	function core:Start()
		if self.Running then return false,"La prueba ya esta activa." end
		if not ExperimentalFlingCore or not ExperimentalFlingCore:IsAuthorized() then return false,"Prueba solo para owners." end
		for _,name in ipairs(incompatible) do
			local other=context[name]
			if other and (other.Running or other.Stopping) then return false,"Desactiva los otros flujos antes de probar." end
		end
		local h,r=parts(player)
		local target=Players:GetPlayerByUserId(TARGET_ID)
		local th,tr=parts(target)
		if not r or not tr or target==player then return false,"Tu personaje y dayzero777 deben estar disponibles." end
		if r.Anchored then return false,"Desactiva el ancla antes de probar." end
		local delta=tr.Position-r.Position
		if delta.Magnitude<5 or delta.Magnitude>228 then return false,"Colocate entre 5 y 228 studs del objetivo." end
		-- Validate any attached vehicle once. Never select a vehicle by its name.
		local seats={}
		local vehicleWeld
		local cars=workspace:FindFirstChild("Cars")
		if cars then for _,vehicle in ipairs(cars:GetChildren()) do
			local weld=vehicle:FindFirstChild("WeldToPlayer")
			if weld and weld:IsA("WeldConstraint") and weld.Enabled and (weld.Part0==r or weld.Part1==r) then
				vehicleWeld=weld
				local owner=vehicle:GetAttribute("VehicleOwner")
				local reference=vehicle:FindFirstChild("VehicleOwner")
				if tonumber(owner)~=player.UserId and not (reference and reference:IsA("ObjectValue") and reference.Value==player) then
					return false,"No se pudo confirmar la propiedad del vehiculo conectado."
				end
				for _,item in ipairs(vehicle:GetDescendants()) do
					if item:IsA("Seat") or item:IsA("VehicleSeat") then
						if item.Occupant and item.Occupant~=h then return false,"Prueba cancelada: vehiculo con otro ocupante." end
						table.insert(seats,item)
					end
				end
			end
		end end
		self.Checkpoint=r.CFrame;self.Character=player.Character;self.Humanoid=h
		self.Samples={};self.Root=r;self.Running=true
		local direction=delta.Unit
		-- Ray starts at activation, points through the snapshotted target HRP.
		-- CFrame skips intermediate positions; this is not a swept collision.
		local origin=r.Position
		local rotation=self.Checkpoint.Rotation
		local phases={
			{Name="FAR",Position=origin+direction*FAR_DISTANCE,Velocity=direction*SPEED},
		}
		local elapsed,phaseIndex=0,1
		self.Connection=RunService.PreSimulation:Connect(function(dt)
			local ok,err=pcall(function()
				elapsed=elapsed+dt
				local ch,cr=parts(player);local ct,ctr=parts(target)
				if cr~=r or ch~=h or ct~=th or ctr~=tr or target.Parent~=Players then self:Stop("Cambio o muerte de personaje.");return end
				if r.Anchored then self:Stop("Ancla detectada.");return end
				for _,name in ipairs(incompatible) do
					local other=context[name]
					if other and (other.Running or other.Stopping) then self:Stop("Otro flujo activo.");return end
				end
				if vehicleWeld and (not vehicleWeld.Parent or not vehicleWeld.Enabled or (vehicleWeld.Part0~=r and vehicleWeld.Part1~=r)) then
					self:Stop("Conexion del vehiculo modificada.");return
				end
				for _,seat in ipairs(seats) do
					if not seat.Parent or (seat.Occupant and seat.Occupant~=h) then self:Stop("Cambio de asiento u ocupante.");return end
				end
				if dt>0.1 or elapsed>=MAX_TIME then
					self:Stop("Tiempo de seguridad alcanzado.");return
				end
				local phase=phases[phaseIndex]
				if not phase then self:Stop("Recorrido terminado; velocidades limpiadas.");return end
				-- One phase per physics step, no copied fling motor or continuous loop.
				r.AssemblyLinearVelocity=Vector3.zero
				r.AssemblyAngularVelocity=Vector3.zero
				r.CFrame=CFrame.new(phase.Position)*rotation
				r.AssemblyLinearVelocity=phase.Velocity
				table.insert(self.Samples,string.format("t=%.3f phase=%s commandedDistance=%.2f observedDistance=%.2f speed=%.2f localHealth=%.2f targetHealth=%.2f",elapsed,phase.Name,(phase.Position-origin).Magnitude,(r.Position-origin).Magnitude,r.AssemblyLinearVelocity.Magnitude,h.Health,th.Health))
				phaseIndex=phaseIndex+1
			end)
			if not ok then self:Stop("Error: "..tostring(err)) end
		end)
		refresh("Prueba CFrame: salto desde el origen, direccion al HRP, destino a 1 millon y regreso al origen. Velocidad: 600 studs/s. Sin retorno al target; no garantiza colision ni replicacion.")
		return true
	end
	function core:Destroy() self:Stop("GUI cerrada.") end
	return true
end
