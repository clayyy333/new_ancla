-- Independent velocity launch test. No remote calls or target writes.
return function(context)
	setfenv(1, context)
	local TARGET_ID = 11773278300
	local SPEED, FAR_DISTANCE, MAX_TIME = 900000000, 1000000, 0.6
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
		if self.PostConnection then self.PostConnection:Disconnect();self.PostConnection=nil end
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
				.."Target UserId: "..TARGET_ID.." | velocidad solicitada: "..SPEED.." | umbral de regreso: "..FAR_DISTANCE.." | ciclos: "..(self.Cycles or 0)
				.."\nResultado: "..result.."\n"..table.concat(self.Samples,"\n")
			self.Checkpoint=nil;self.Character=nil;self.Humanoid=nil;self.Root=nil
			refresh(result)
		end
	end
	function core:GetDiagnosticReport()
		if self.Running then return "STRAIGHT PASS TEST | ACTIVO | velocidad solicitada: "..SPEED.." | umbral: "..FAR_DISTANCE.." | ciclos: "..(self.Cycles or 0).."\n"..table.concat(self.Samples,"\n") end
		return self.Report
	end
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
		self.Samples={};self.Cycles=0;self.Root=r;self.Running=true
		local origin=r.Position
		local elapsed,totalElapsed=0,0
		local direction
		local function record(label)
			table.insert(self.Samples,string.format("t=%.3f cycle=%d phase=%s observedDistance=%.2f speed=%.2f localHealth=%.2f targetHealth=%.2f",totalElapsed,self.Cycles,label,(r.Position-origin).Magnitude,r.AssemblyLinearVelocity.Magnitude,h.Health,th.Health))
			if #self.Samples>120 then table.remove(self.Samples,1) end
		end
		local function validate()
			local ch,cr=parts(player);local ct,ctr=parts(target)
			if cr~=r or ch~=h or ct~=th or ctr~=tr or target.Parent~=Players then return false,"Cambio o muerte de personaje." end
			if r.Anchored then return false,"Ancla detectada." end
			for _,name in ipairs(incompatible) do
				local other=context[name]
				if other and (other.Running or other.Stopping) then return false,"Otro flujo activo." end
			end
			if vehicleWeld and (not vehicleWeld.Parent or not vehicleWeld.Enabled or (vehicleWeld.Part0~=r and vehicleWeld.Part1~=r)) then return false,"Conexion del vehiculo modificada." end
			for _,seat in ipairs(seats) do
				if not seat.Parent or (seat.Occupant and seat.Occupant~=h) then return false,"Cambio de asiento u ocupante." end
			end
			return true
		end
		self.Connection=RunService.PreSimulation:Connect(function(dt)
			local ok,err=pcall(function()
				if not self.Running then return end
				local valid,reason=validate();if not valid then self:Stop(reason);return end
				if dt>0.1 then self:Stop("Paso de fisica demasiado largo.");return end
				totalElapsed=totalElapsed+dt
				if not direction then
					local aim=tr.Position-origin
					if aim.Magnitude<5 or aim.Magnitude>228 then self:Stop("Objetivo fuera del rango de prueba.");return end
					direction=aim.Unit
					elapsed=0
					self.Cycles=self.Cycles+1
				end
				elapsed=elapsed+dt
				r.AssemblyAngularVelocity=Vector3.zero
				r.AssemblyLinearVelocity=direction*SPEED
			end)
			if not ok then self:Stop("Error: "..tostring(err)) end
		end)
		self.PostConnection=RunService.PostSimulation:Connect(function()
			local ok,err=pcall(function()
				if not self.Running or not direction then return end
				local valid,reason=validate();if not valid then self:Stop(reason);return end
				record("POST_PHYSICS")
				if (r.Position-origin).Magnitude>=FAR_DISTANCE then
					-- Observe overshoot before returning. CFrame is only used for recovery.
					r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
					r.CFrame=self.Checkpoint
					direction=nil
				elseif elapsed>=MAX_TIME then
					self:Stop("No alcanzo el umbral; posible bloqueo o correccion.")
				end
			end)
			if not ok then self:Stop("Error: "..tostring(err)) end
		end)
		refresh("Prueba activa: velocidad solicitada 900 millones, regreso al superar 1 millon y repeticion. Distancia real puede exceder el umbral; pulsa para detener.")
		return true
	end
	function core:Destroy() self:Stop("GUI cerrada.") end
	return true
end
