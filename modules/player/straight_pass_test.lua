-- Independent velocity launch test. No remote calls or target writes.
return function(context)
	setfenv(1, context)
	local TARGET_ID = 11773278300
	local SPEED, FAR_DISTANCE, MAX_TIME = 900000000, 1000000, 0.6
	local NEAR_SPEED, NEAR_STEP, NEAR_TIMEOUT = 240, 2, 5
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
	local function read(object,key)
		local ok,value=pcall(function()return object[key]end)
		if ok then return value end
	end
	local function path(object)
		if not object then return "nil" end
		local ok,value=pcall(function()return object:GetFullName()end)
		return ok and value or tostring(read(object,"Name") or "unknown")
	end
	local function vector(value)
		if not value then return "nil" end
		return string.format("(%.3f,%.3f,%.3f)",value.X,value.Y,value.Z)
	end
	local function state(humanoid)
		local ok,value=pcall(function()return humanoid:GetState().Name end)
		return ok and value or "unknown"
	end
	function core:BuildDiagnosticReport(result)
		local lines={"LAUNCH DIAGNOSTIC V3 | client observations only; server cause/network ownership unknown",
			"Status: "..tostring(result or (self.Running and "ACTIVE" or "STOPPED")),
			"Local: "..tostring(player.Name).." | UserId="..tostring(player.UserId).." | TargetId="..TARGET_ID,
			"RequestedSpeed="..SPEED.." returnThreshold="..FAR_DISTANCE.." cycleTimeout="..MAX_TIME,
			"NearSpeedMax="..NEAR_SPEED.." nearStepBudget="..NEAR_STEP.." nearTimeout="..NEAR_TIMEOUT.." geometricCrossings="..(self.Crossings or 0).." | crossing does not prove collision",
			"Origin="..vector(self.DiagnosticOrigin).." vehicle="..tostring(self.DiagnosticVehicle or "none"),
			"cycles="..(self.Cycles or 0).." returns="..(self.Returns or 0).." preEvents="..(self.PreEvents or 0).." postEvents="..(self.PostEvents or 0).." renderEvents="..(self.RenderEvents or 0),
			string.format("maxPreDistance=%.3f maxPostDistance=%.3f maxRenderDistance=%.3f",self.MaxPreDistance or 0,self.MaxPostDistance or 0,self.MaxRenderDistance or 0),
			"LastStartFailure="..tostring(self.LastStartFailure or "none")}
		local root=self.Root
		if root then
			local assembly=read(root,"AssemblyRootPart")
			lines[#lines+1]="HRP="..path(root).." anchored="..tostring(read(root,"Anchored")).." assemblyRoot="..path(assembly).." assemblyAnchored="..tostring(assembly and read(assembly,"Anchored")).." mass="..tostring(read(root,"AssemblyMass"))
			local ok,connected=pcall(function()return root:GetConnectedParts(true)end)
			if ok then
				local anchored={}
				for _,part in ipairs(connected) do if part.Anchored and #anchored<12 then anchored[#anchored+1]=path(part) end end
				lines[#lines+1]="ConnectedParts="..#connected.." anchoredConnected="..table.concat(anchored,"; ")
			else lines[#lines+1]="ConnectedParts=unavailable" end
		end
		for _,name in ipairs({"AnchorCore","AutoAnchorCore","StaticPassThroughAnchorCore","MobileAnchorCore","MobileAnchorV11Core","VerticalControlController"}) do
			local other=context[name]
			if other then lines[#lines+1]=name..": Running="..tostring(other.Running).." AnclaEnabled="..tostring(other.AnclaEnabled).." Mode="..tostring(other.Mode).." HeartbeatEnabled="..tostring(other.HeartbeatEnabled) end
		end
		local owners={self.Character,self.DiagnosticVehicleObject}
		local count=0
		for _,owner in ipairs(owners) do
			local ok,descendants=pcall(function()return owner:GetDescendants()end)
			if ok then for _,item in ipairs(descendants) do
				if count<24 and (item:IsA("BodyMover") or item:IsA("AlignPosition") or item:IsA("AlignOrientation") or item:IsA("LinearVelocity") or item:IsA("AngularVelocity") or item:IsA("VectorForce")) then
					count=count+1
					lines[#lines+1]="PotentialController="..path(item).." class="..item.ClassName.." enabled="..tostring(read(item,"Enabled")).." velocity="..vector(read(item,"Velocity") or read(item,"VectorVelocity"))
				end
			end end
		end
		lines[#lines+1]="FIRST EVENTS (preserved):"
		lines[#lines+1]=table.concat(self.FirstSamples or {},"\n")
		lines[#lines+1]="LATEST EVENTS (bounded):"
		lines[#lines+1]=table.concat(self.Samples,"\n")
		return table.concat(lines,"\n")
	end
	function core:Stop(reason)
		if self.Connection then self.Connection:Disconnect();self.Connection=nil end
		if self.PostConnection then self.PostConnection:Disconnect();self.PostConnection=nil end
		if self.RenderConnection then self.RenderConnection:Disconnect();self.RenderConnection=nil end
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
			self.Report=self:BuildDiagnosticReport(result)
			self.Checkpoint=nil;self.Character=nil;self.Humanoid=nil;self.Root=nil
			refresh(result)
		end
	end
	function core:GetDiagnosticReport()
		if self.Running then return self:BuildDiagnosticReport() end
		if self.LastStartFailure then return "LAST START REJECTED: "..self.LastStartFailure.."\n"..self.Report end
		return self.Report
	end
	function core:Start()
		local function rejected(message)self.LastStartFailure=message;return false,message end
		if self.Running then return false,"La prueba ya esta activa." end
		if not ExperimentalFlingCore or not ExperimentalFlingCore:IsAuthorized() then return rejected("Prueba solo para owners.") end
		for _,name in ipairs(incompatible) do
			local other=context[name]
			if other and (other.Running or other.Stopping) then return rejected("Desactiva los otros flujos antes de probar: "..name) end
		end
		local h,r=parts(player)
		local target=Players:GetPlayerByUserId(TARGET_ID)
		local th,tr=parts(target)
		if not r or not tr or target==player then return rejected("Tu personaje y dayzero777 deben estar disponibles.") end
		if r.Anchored then return rejected("Desactiva el ancla antes de probar.") end
		local delta=tr.Position-r.Position
		if delta.Magnitude<5 or delta.Magnitude>228 then return rejected("Colocate entre 5 y 228 studs del objetivo.") end
		-- Validate any attached vehicle once. Never select a vehicle by its name.
		local seats={}
		local vehicleWeld
		local selectedVehicle
		local cars=workspace:FindFirstChild("Cars")
		if cars then for _,vehicle in ipairs(cars:GetChildren()) do
			local weld=vehicle:FindFirstChild("WeldToPlayer")
			if weld and weld:IsA("WeldConstraint") and weld.Enabled and (weld.Part0==r or weld.Part1==r) then
				vehicleWeld=weld
				selectedVehicle=vehicle
				local owner=vehicle:GetAttribute("VehicleOwner")
				local reference=vehicle:FindFirstChild("VehicleOwner")
				if tonumber(owner)~=player.UserId and not (reference and reference:IsA("ObjectValue") and reference.Value==player) then
					return rejected("No se pudo confirmar la propiedad del vehiculo conectado.")
				end
				for _,item in ipairs(vehicle:GetDescendants()) do
					if item:IsA("Seat") or item:IsA("VehicleSeat") then
						if item.Occupant and item.Occupant~=h then return rejected("Prueba cancelada: vehiculo con otro ocupante.") end
						table.insert(seats,item)
					end
				end
			end
		end end
		self.Checkpoint=r.CFrame;self.Character=player.Character;self.Humanoid=h
		self.Samples={};self.FirstSamples={};self.Cycles=0;self.Returns=0;self.Crossings=0;self.Root=r;self.Running=true
		self.LastStartFailure=nil;self.PreEvents=0;self.PostEvents=0;self.RenderEvents=0
		self.MaxPreDistance=0;self.MaxPostDistance=0;self.MaxRenderDistance=0
		self.DiagnosticOrigin=r.Position;self.DiagnosticVehicle=selectedVehicle and path(selectedVehicle) or "none";self.DiagnosticVehicleObject=selectedVehicle
		local origin=r.Position
		local elapsed,totalElapsed=0,0
		local direction
		local stage="APPROACH"
		local crossCenter,crossedPlane,prePosition
		local pendingReturn,renderSeen=false,false
		local renderWait=0
		local stepDt=0
		local function record(label)
			local row=string.format("t=%.4f dt=%.5f cycle=%d phase=%s observedDistance=%.2f pos=%s vel=%s speed=%.2f targetPos=%s localHealth=%.2f targetHealth=%.2f anchored=%s state=%s sit=%s seat=%s weld=%s",totalElapsed,stepDt,self.Cycles,label,(r.Position-origin).Magnitude,vector(r.Position),vector(r.AssemblyLinearVelocity),r.AssemblyLinearVelocity.Magnitude,vector(tr.Position),h.Health,th.Health,tostring(r.Anchored),state(h),tostring(h.Sit),path(h.SeatPart),tostring(vehicleWeld and vehicleWeld.Enabled or false))
			if #self.FirstSamples<24 then self.FirstSamples[#self.FirstSamples+1]=row end
			table.insert(self.Samples,row)
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
		record("START")
		self.Connection=RunService.PreSimulation:Connect(function(dt)
			local ok,err=pcall(function()
				if not self.Running then return end
				self.PreEvents=self.PreEvents+1;stepDt=dt
				self.MaxPreDistance=math.max(self.MaxPreDistance,(r.Position-origin).Magnitude)
				record("PRE_BEFORE_WRITE")
				local valid,reason=validate();if not valid then self:Stop(reason);return end
				if dt>0.1 then self:Stop("Paso de fisica demasiado largo.");return end
				totalElapsed=totalElapsed+dt
				if pendingReturn then
					r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
					renderWait=renderWait+dt
					if renderSeen then
						-- Return on a later simulation step, never inside the render callback.
						r.CFrame=self.Checkpoint
						self.Returns=self.Returns+1
						record("RETURN_ORIGIN_AFTER_RENDER")
						pendingReturn=false;renderSeen=false;direction=nil
						stage="APPROACH";crossCenter=nil;crossedPlane=false
					elseif renderWait>=0.25 then
						self:Stop("No hubo render local; regreso de seguridad.")
					end
					return
				end
				if not direction then
					local aim=tr.Position-origin
					if aim.Magnitude<5 or aim.Magnitude>228 then self:Stop("Objetivo fuera del rango de prueba.");return end
					direction=aim.Unit
					elapsed=0
					self.Cycles=self.Cycles+1
				end
				elapsed=elapsed+dt
				r.AssemblyAngularVelocity=Vector3.zero
				prePosition=r.Position
				if stage~="FAR" then
					local aim=tr.Position-r.Position
					if not crossCenter and aim.Magnitude>0.001 then
						direction=aim.Unit
						if aim.Magnitude<=6 then crossCenter=tr.Position;crossedPlane=false;stage="CROSS";record("CROSS_BEGIN") end
					end
					-- Bound requested near travel per simulation step, not the far leg.
					r.AssemblyLinearVelocity=direction*math.min(NEAR_SPEED,NEAR_STEP/math.max(dt,0.001))
				else
					r.AssemblyLinearVelocity=direction*SPEED
				end
				record("PRE_AFTER_WRITE")
			end)
			if not ok then self:Stop("Error: "..tostring(err)) end
		end)
		self.PostConnection=RunService.PostSimulation:Connect(function()
			local ok,err=pcall(function()
				if not self.Running or not direction or pendingReturn then return end
				self.PostEvents=self.PostEvents+1
				self.MaxPostDistance=math.max(self.MaxPostDistance,(r.Position-origin).Magnitude)
				local valid,reason=validate();if not valid then self:Stop(reason);return end
				record("POST_PHYSICS")
				if stage~="FAR" then
					if crossCenter then
						if (tr.Position-crossCenter).Magnitude>2 then
							crossCenter=nil;crossedPlane=false;stage="APPROACH";record("CROSS_TARGET_MOVED")
						else
							local offset=r.Position-crossCenter
							local progress=offset:Dot(direction)
							local lateral=(offset-direction*progress).Magnitude
							local before=(prePosition-crossCenter):Dot(direction)
							if before<=0 and progress>=0 and lateral<=2 then crossedPlane=true end
							if crossedPlane and progress>=2 and lateral<=2 then
								self.Crossings=self.Crossings+1
								stage="FAR";elapsed=0
								record("CROSS_GEOMETRIC_CONFIRMED")
							end
						end
					end
					if stage~="FAR" and elapsed>=NEAR_TIMEOUT then self:Stop("Cruce cercano no confirmado; no se inicia despegue fuerte.") end
					return
				end
				if (r.Position-origin).Magnitude>=FAR_DISTANCE then
					-- Stop further thrust, but leave the outgoing position for local render.
					r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
					pendingReturn=true;renderSeen=false;renderWait=0
					record("WAIT_OUTGOING_RENDER")
				elseif elapsed>=MAX_TIME then
					self:Stop("No alcanzo el umbral; posible bloqueo o correccion.")
				end
			end)
			if not ok then self:Stop("Error: "..tostring(err)) end
		end)
		self.RenderConnection=RunService.RenderStepped:Connect(function()
			if not self.Running or player.Character~=self.Character or not r.Parent then return end
			self.RenderEvents=self.RenderEvents+1
			self.MaxRenderDistance=math.max(self.MaxRenderDistance,(r.Position-origin).Magnitude)
			if pendingReturn and not renderSeen then
				renderSeen=true
				record("RENDER_OUTGOING_LOCAL")
			elseif self.RenderEvents<=12 or self.RenderEvents%30==0 then record("RENDER_LOCAL") end
		end)
		refresh("Prueba activa: aproximacion controlada, cruce geometrico y luego despegue a 900 millones. Regreso al superar 1 millon; no garantiza colision. Pulsa para detener.")
		return true
	end
	function core:Destroy() self:Stop("GUI cerrada.") end
	return true
end
