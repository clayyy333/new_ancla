-- One-shot, bounded client physics observation. No remote calls or target writes.
return function(context)
	setfenv(1, context)
	local TARGET_ID = 11773278300
	local SPEED, MAX_DISTANCE, MAX_TIME = 300, 120, 0.6
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
				.."Target UserId: "..TARGET_ID.." | velocidad: "..SPEED.." | distancia maxima: "..MAX_DISTANCE
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
		if delta.Magnitude<5 or delta.Magnitude>80 then return false,"Colocate entre 5 y 80 studs del objetivo." end
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
		local origin=r.Position
		local direction=delta.Unit
		local distance=math.min(delta.Magnitude+12,MAX_DISTANCE)
		local elapsed,sampleElapsed=0,0
		self.Connection=RunService.PreSimulation:Connect(function(dt)
			local ok,err=pcall(function()
				elapsed=elapsed+dt;sampleElapsed=sampleElapsed+dt
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
				local displacement=r.Position-origin
				if sampleElapsed>=0.03 then
					sampleElapsed=0
					table.insert(self.Samples,string.format("t=%.3f distance=%.2f speed=%.2f localHealth=%.2f targetHealth=%.2f targetDistance=%.2f",elapsed,displacement.Magnitude,r.AssemblyLinearVelocity.Magnitude,h.Health,th.Health,(tr.Position-r.Position).Magnitude))
				end
				if dt>0.1 or elapsed>=MAX_TIME or displacement.Magnitude>=MAX_DISTANCE or displacement:Dot(direction)>=distance then
					self:Stop("Recorrido terminado; velocidades limpiadas.");return
				end
				-- Fixed direction captured at activation: no tracking, teleport or spin.
				local remaining=distance-math.max(0,displacement:Dot(direction))
				r.AssemblyAngularVelocity=Vector3.zero
				r.AssemblyLinearVelocity=direction*math.min(SPEED,remaining/math.max(dt,0.001))
			end)
			if not ok then self:Stop("Error: "..tostring(err)) end
		end)
		refresh("Prueba recta activa: 300 studs/s, un recorrido; pulsa de nuevo para detener.")
		return true
	end
	function core:Destroy() self:Stop("GUI cerrada.") end
	return true
end
