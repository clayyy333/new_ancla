-- Independent V8 phase flow. Keeps the selected Player across character replacement.
return function(context)
	setfenv(1,context)
	local core={Running=false,Phase="IDLE",Cycles=0,Recoveries=0,LastError=nil,
		Config={ContactSpeed=100,Speed=10000,Distance=100,Azimuth=60,Elevation=0,ContactTime=.20,LaunchTime=.25}}
	ObjectV8FlingCore=core
	local connection,selected,character,humanoid,root,checkpoint,saved,targetCharacter,targetRoot
	local pulseConnection,renderConnection,pulseRoot,pulseVelocity
	local function restorePulse()
		local r,v=pulseRoot,pulseVelocity;pulseRoot=nil;pulseVelocity=nil
		if r and r.Parent and v then r.AssemblyLinearVelocity=v end
	end
	local phaseStart,direction,launchPosition,retryAt=0,nil,nil,0
	local incoming,previousPosition,previousTarget,flightDeadline
	local crossingPosition
	local function dot(a,b)return a.X*b.X+a.Y*b.Y+a.Z*b.Z end
	-- Relative to the target's horizontal facing: 0 front, 90 right, 180 rear.
	local function departureDirection(tr)
		local look=tr.CFrame.LookVector
		local forward=Vector3.new(look.X,0,look.Z)
		forward=forward.Magnitude>.001 and forward.Unit or Vector3.new(0,0,-1)
		local right=Vector3.new(-forward.Z,0,forward.X)
		local az,el=math.rad(core.Config.Azimuth),math.rad(core.Config.Elevation)
		return ((forward*math.cos(az)+right*math.sin(az))*math.cos(el)+Vector3.new(0,math.sin(el),0)).Unit
	end
	local function refresh(message)if UpdateObjectFlingPanel then UpdateObjectFlingPanel(message)end end
	local function finite(v)return type(v)=="number"and v==v and math.abs(v)<math.huge end
	local function valid(v)return finite(v.X)and finite(v.Y)and finite(v.Z)end
	local function zero()
		if root and root.Parent then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
	end
	function core:IsAuthorized()return true end
	function core:SetParameter(name,value)
		local limits={ContactSpeed={0,1000000000},Speed={0,1000000000},Distance={.5,2000000000},Azimuth={-360,360},Elevation={-90,90},ContactTime={.01,10},LaunchTime={.01,10}}
		local range=limits[name]
		if not range or not finite(value)or value<range[1]or value>range[2]then return false end
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
		direction=departureDirection(tr)
		targetCharacter=selected.Character;targetRoot=tr
		launchPosition=tr.Position+direction*core.Config.Distance
		root.CFrame=CFrame.new(launchPosition)*root.CFrame.Rotation
		incoming=direction*(-1);previousPosition=nil;previousTarget=nil;crossingPosition=nil
		phaseStart=now;core.Phase="PREPARE"
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
	function core:GetTarget()return selected end
	function core:SetTarget(value)
		if not value or value==player or value.Parent~=Players then return false end
		selected=value;zero();self.Phase="WAIT_TARGET";targetCharacter=nil;targetRoot=nil;launchPosition=nil
		return true
	end
	local function step()
		restorePulse()
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
		-- Target Health can be changed locally by another script without a real respawn.
		-- Keep tracking an existing rig; missing parts and invalid coordinates still wait.
		if not tr or not th then waitFor("WAIT_TARGET");return end
		if not valid(tr.Position)then waitFor("WAIT_TARGET");return end
		local now=os.clock();if now<retryAt then return end
		if tc~=targetCharacter or tr~=targetRoot or core.Phase=="WAIT_TARGET"or core.Phase=="WAIT_LOCAL"or core.Phase=="RECOVERING"then beginContact(tr,now)end
		local cfg=core.Config
		if not valid(r.Position)then beginContact(tr,now)end
		local elapsed=now-phaseStart
		local angular=Vector3.zero
		if core.Phase=="PREPARE"then
			r.CFrame=CFrame.new(launchPosition)*r.CFrame.Rotation;zero()
			if elapsed>=cfg.ContactTime then
				local offset=tr.Position-r.Position
				if offset.Magnitude>.001 then incoming=offset.Unit end
				previousPosition=r.Position;previousTarget=tr.Position
				flightDeadline=now+offset.Magnitude/math.max(cfg.Speed,1)+cfg.LaunchTime
				r.AssemblyLinearVelocity=incoming*cfg.Speed
				core.Phase="INBOUND";phaseStart=now
			end
		elseif core.Phase=="INBOUND"then
			-- Relative swept segment measures observed passage, not collision proof.
			local offset=tr.Position-r.Position
			local before=previousPosition-previousTarget
			local after=r.Position-tr.Position
			local segment=after-before
			local length2=dot(segment,segment)
			local t=length2>0 and math.max(0,math.min(1,-dot(before,segment)/length2))or 0
			local near=(before+segment*t).Magnitude<=.5
			if near and dot(after,incoming)>=0 then
				crossingPosition=tr.Position
				if dot(after,incoming)>=.5 then beginContact(tr,now);return end
				core.Phase="PASS_THROUGH";phaseStart=now
			elseif now>=flightDeadline then
				core.Recoveries=core.Recoveries+1;beginContact(tr,now);return
			elseif offset.Magnitude>.001 then incoming=offset.Unit end
			r.AssemblyLinearVelocity=incoming*cfg.Speed;r.AssemblyAngularVelocity=angular
			previousPosition=r.Position;previousTarget=tr.Position
		elseif core.Phase=="PASS_THROUGH"then
			-- Keep heading beyond HRP. No target teleport and no parking at HRP.
			r.AssemblyLinearVelocity=incoming*cfg.Speed;r.AssemblyAngularVelocity=angular
			-- Distance threshold, not an extra timed flight. A physics step can overshoot.
			if dot(r.Position-crossingPosition,incoming)>=.5 then
				beginContact(tr,now)
			elseif elapsed>=cfg.LaunchTime+.5/math.max(cfg.Speed,1) then
				core.Recoveries=core.Recoveries+1;beginContact(tr,now)
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
		if V8PersistentFlingCore and V8PersistentFlingCore.Running then return false,"Desactiva el otro V8 persistente primero."end
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
			if self.Running and (self.Phase=="INBOUND"or self.Phase=="PASS_THROUGH")and targetRoot and targetRoot.Parent and root and root.Parent and player.Character==character and humanoid.Health>0 and (root.Position-targetRoot.Position).Magnitude<=.5 then
				pulseRoot=root;pulseVelocity=root.AssemblyLinearVelocity
				local speed=math.max(self.Config.Speed,self.Config.ContactSpeed)
				root.AssemblyLinearVelocity=incoming*speed
				root.AssemblyAngularVelocity=Vector3.zero
			end
		end)
		renderConnection=RunService.RenderStepped:Connect(restorePulse)
		protectedStep();refresh();return true
	end
	function core:Destroy()self:Stop()end
	return true
end
