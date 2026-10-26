-- Independent V8 phase flow. Keeps the selected Player across character replacement.
return function(context)
	setfenv(1,context)
	local core={Running=false,Phase="IDLE",Cycles=0,Recoveries=0,LastError=nil,
		Config={ContactSpeed=100000,Speed=174463.14492872442,Distance=1828025672.522707,ContactTime=.20,LaunchTime=.25,ReturnTime=.25}}
	V8PersistentFlingCore=core
	local connection,selected,character,humanoid,root,checkpoint,saved,targetCharacter,targetRoot
	local pulseConnection,renderConnection,pulseRoot,pulseVelocity
	local function restorePulse()
		local r,v=pulseRoot,pulseVelocity;pulseRoot=nil;pulseVelocity=nil
		if r and r.Parent and v then r.AssemblyLinearVelocity=v end
	end
	-- Only a physically connected, locally owned vehicle enables the passenger gate.
	local function connectedVehicle()
		local cars=workspace:FindFirstChild("Cars")
		if not cars then return nil end
		for _,part in ipairs(root:GetConnectedParts(true))do
			local vehicle=part
			while vehicle and vehicle.Parent~=cars do vehicle=vehicle.Parent end
			if vehicle then
				local owner=vehicle:FindFirstChild("VehicleOwner")
				local owned=owner and owner:IsA("ObjectValue")and owner.Value==player
				if not owner or not owner:IsA("ObjectValue")or not owner.Value then
					owned=tonumber(vehicle:GetAttribute("VehicleOwner"))==player.UserId
				end
				if owned then return vehicle end
			end
		end
	end
	local function passengerReady(vehicle,tc,th)
		local seat=th.SeatPart
		if not seat or not seat:IsDescendantOf(vehicle)or seat.Occupant~=th then return false end
		local weld=seat:FindFirstChild("SeatWeld")
		if not weld or not(weld:IsA("JointInstance")or weld:IsA("WeldConstraint"))then return false end
		local a,b=weld.Part0,weld.Part1
		return(a==seat and b and b:IsDescendantOf(tc))or(b==seat and a and a:IsDescendantOf(tc))or false
	end
	local phaseStart,direction,launchPosition,retryAt=0,nil,nil,0
	-- Only XYZ diagonals, alternating sides. Normalize to preserve configured speed/distance.
	local directions={Vector3.new(1,1,1).Unit,Vector3.new(-1,1,1).Unit,Vector3.new(-1,1,-1).Unit,Vector3.new(1,1,-1).Unit}
	local function refresh(message)if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel(message)end end
	local function finite(v)return type(v)=="number"and v==v and math.abs(v)<math.huge end
	local function valid(v)return finite(v.X)and finite(v.Y)and finite(v.Z)end
	local function zero()
		if root and root.Parent then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
	end
	function core:IsAuthorized()return ExperimentalFlingCore and ExperimentalFlingCore:IsAuthorized()or false end
	function core:SetParameter(name,value)
		local limits={ContactSpeed={0,1000000000},Speed={0,1000000000},Distance={.5,2000000000},ContactTime={.01,10},LaunchTime={.01,10},ReturnTime={.01,10}}
		local range=limits[name]
		if not self:IsAuthorized()or not range or not finite(value)or value<range[1]or value>range[2]then return false end
		self.Config[name]=value;return true
	end
	function core:Stop(message)
		restorePulse()
		if pulseConnection then pulseConnection:Disconnect();pulseConnection=nil end
		if renderConnection then renderConnection:Disconnect();renderConnection=nil end
		local wasRunning=self.Running;self.Running=false;self.Phase="IDLE";self.WaitingForPassenger=false
		if connection then connection:Disconnect();connection=nil end
		if saved and root and root.Parent then
			zero();root.CanCollide=saved.CanCollide
			if humanoid and humanoid.Parent then humanoid.AutoRotate=saved.AutoRotate end
			if player.Character==character and humanoid and humanoid.Health>0 and checkpoint then root.CFrame=checkpoint;zero()end
		end
		saved=nil;targetCharacter=nil;targetRoot=nil;launchPosition=nil
		if wasRunning then refresh(message or "V8 persistente detenido; regreso al checkpoint.")end
		return wasRunning
	end
	local function beginContact(tr,now)
		core.WaitingForPassenger=false
		zero();core.Cycles=core.Cycles+1
		direction=directions[(core.Cycles-1)%#directions+1]
		targetCharacter=selected.Character;targetRoot=tr;launchPosition=nil
		phaseStart=now;core.Phase="CONTACT"
	end
	local function bindCharacter(c,h,r)
		character=c;humanoid=h;root=r
		saved={CanCollide=r.CanCollide,AutoRotate=h.AutoRotate}
		r.CanCollide=true;h.AutoRotate=false
	end
	local function waitFor(phase)
		if core.Phase~=phase then
			zero();core.Phase=phase;targetCharacter=nil;targetRoot=nil;launchPosition=nil
			refresh()
		end
	end
	function core:SetTarget(value)
		if not self:IsAuthorized()or not value or value==player or value.Parent~=Players then return false end
		selected=value;zero();self.Phase="WAIT_TARGET";targetCharacter=nil;targetRoot=nil;launchPosition=nil
		return true
	end
	local function step()
		restorePulse()
		if not core:IsAuthorized()then core:Stop("Prueba exclusiva para owners.");return end
		if not selected or selected.Parent~=Players then core:Stop("El jugador seleccionado salio.");return end
		local c=player.Character
		local h=c and c:FindFirstChildOfClass("Humanoid")
		local r=c and c:FindFirstChild("HumanoidRootPart")
		if not r or not h or h.Health<=0 then waitFor("WAIT_LOCAL");return end
		if r~=root or c~=character then
			-- Restore the previous rig without moving the new life to old physics state.
			if saved and root and root.Parent then zero();root.CanCollide=saved.CanCollide end
			if saved and humanoid and humanoid.Parent then humanoid.AutoRotate=saved.AutoRotate end
			bindCharacter(c,h,r);core.Phase="WAIT_TARGET";targetRoot=nil;targetCharacter=nil
		end
		local tc=selected.Character
		local tr=tc and tc:FindFirstChild("HumanoidRootPart")
		local th=tc and tc:FindFirstChildOfClass("Humanoid")
		if not tr or not th or th.Health<=0 then waitFor("WAIT_TARGET");return end
		if not valid(tr.Position)then waitFor("WAIT_TARGET");return end
		local now=os.clock();if now<retryAt then return end
		if tc~=targetCharacter or tr~=targetRoot or core.Phase=="WAIT_TARGET"or core.Phase=="WAIT_LOCAL"or core.Phase=="RECOVERING"then beginContact(tr,now)end
		local cfg=core.Config
		if not valid(r.Position)then beginContact(tr,now)end
		-- A stalled/outdated phase always reacquires the live target.
		local duration=core.Phase=="CONTACT"and cfg.ContactTime or core.Phase=="LAUNCH"and cfg.LaunchTime or cfg.ReturnTime
		if not core.WaitingForPassenger and now-phaseStart>duration+1 then core.Recoveries=core.Recoveries+1;beginContact(tr,now)end
		local elapsed=now-phaseStart
		local angular=Vector3.zero
		if core.Phase=="CONTACT"then
			local vehicle=connectedVehicle()
			core.WaitingForPassenger=vehicle~=nil and not passengerReady(vehicle,tc,th)
			r.CFrame=CFrame.new(tr.Position+direction*.5)*r.CFrame.Rotation
			r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=angular
			if elapsed>=cfg.ContactTime and not core.WaitingForPassenger then
				launchPosition=tr.Position+direction*cfg.Distance
				r.AssemblyLinearVelocity=direction*cfg.Speed
				core.Phase="LAUNCH";phaseStart=now
			end
		elseif core.Phase=="LAUNCH"then
			r.AssemblyLinearVelocity=direction*cfg.Speed;r.AssemblyAngularVelocity=angular
			if elapsed>=cfg.LaunchTime then
				-- Preserve the supplied V8's far placement at the return transition.
				r.CFrame=CFrame.new(launchPosition)*r.CFrame.Rotation
				r.AssemblyLinearVelocity=direction*(-cfg.Speed)
				core.Phase="RETURN";phaseStart=now
			end
		elseif core.Phase=="RETURN"then
			r.AssemblyLinearVelocity=direction*(-cfg.Speed);r.AssemblyAngularVelocity=angular
			if elapsed>=cfg.ReturnTime then
				beginContact(tr,now)
				r.CFrame=CFrame.new(tr.Position+direction*.5)*r.CFrame.Rotation;r.AssemblyAngularVelocity=angular
			end
		else core.Recoveries=core.Recoveries+1;beginContact(tr,now)end
	end
	local function protectedStep()
		local ok,err=xpcall(step,debug.traceback)
		if not ok then
			core.LastError=tostring(err);core.Recoveries=core.Recoveries+1
			core.Phase="RECOVERING";targetCharacter=nil;targetRoot=nil;launchPosition=nil;retryAt=os.clock()+.1
			pcall(zero);refresh("V8: recuperando contacto tras un error; reintento automatico.")
		end
	end
	function core:Start(value)
		if not self:IsAuthorized()then return false,"Prueba exclusiva para owners."end
		if self.Running then return self:SetTarget(value)end
		if not value or value==player or value.Parent~=Players then return false,"Selecciona un jugador."end
		local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
		if not r or not h or h.Health<=0 then return false,"Tu personaje no esta disponible."end
		checkpoint=r.CFrame;bindCharacter(c,h,r);selected=value
		self.Running=true;self.Phase="WAIT_TARGET";self.Cycles=0;self.Recoveries=0;self.LastError=nil;retryAt=0
		connection=RunService.Heartbeat:Connect(protectedStep)
		-- Independent contact pulse; never overwrites launch/return velocities.
		pulseConnection=RunService.PostSimulation:Connect(function()
			restorePulse()
			if self.Running and self.Phase=="CONTACT"and root and root.Parent and player.Character==character and humanoid.Health>0 then
				pulseRoot=root;pulseVelocity=root.AssemblyLinearVelocity
				local speed=self.Config.ContactSpeed
				root.AssemblyLinearVelocity=Vector3.new(speed,speed,speed)
				root.AssemblyAngularVelocity=Vector3.zero
			end
		end)
		renderConnection=RunService.RenderStepped:Connect(restorePulse)
		protectedStep();refresh();return true
	end
	function core:Destroy()self:Stop()end
	return true
end
