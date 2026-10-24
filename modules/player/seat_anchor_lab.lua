-- Independent, owner-only local experiments; no changes to other anchor engines.
return function(context)
	setfenv(1,context)
	local C={Running=false,Mode=nil,Phase="IDLE",Status=""}
	SeatAnchorLabCore=C
	local connections={}
	local character,humanoid,root,seat,checkpoint,previousAnchored
	local elapsed,displayElapsed,confirmed=0,0,false
	local function text(es,en)return isES and es or en end
	local function update(message)
		C.Status=message or C.Status
		if UpdateSeatAnchorLabPanel then UpdateSeatAnchorLabPanel()end
	end
	function C:IsAuthorized()return ExperimentalFlingCore and ExperimentalFlingCore:IsAuthorized()or false end
	local function conflict()
		if AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)then return "Ancla automatica"end
		for _,name in ipairs({"AnchorCore","StaticPassThroughAnchorCore","MobileAnchorCore","MobileAnchorV11Core","VerticalControlController","EmergencyAnchorController","ExperimentalFlingCore","NoMotosCore","NoMotos2Core","Fling2Core","Fling2EfficientCore","CustomFlingCore","ContactFlingController","CarFling","CarFlingXeno","CarFling2Delta","CarFling2Xeno","MotoFlingCore","MotoFlingXenoCore"})do
			local core=context[name]
			if core and (core.Running or core.Stopping or core.AnclaEnabled or core.TestEnabled or core.AntiSeatEnabled or core.HeartbeatEnabled)then return name end
		end
	end
	local function disconnect()
		for _,connection in ipairs(connections)do connection:Disconnect()end
		connections={}
	end
	local function evidence()
		local a=seat.Occupant==humanoid
		local b=humanoid.SeatPart==seat
		local welded=false
		local weld=seat:FindFirstChild("SeatWeld")
		if weld and weld:IsA("JointInstance")then
			local p,q=weld.Part0,weld.Part1
			welded=(p==seat and q and q:IsDescendantOf(character))or (q==seat and p and p:IsDescendantOf(character))or false
		end
		C.OccupantMatches=a;C.SeatPartMatches=b;C.WeldMatches=welded
		return a and b and welded
	end
	function C:Stop(message)
		local active=self.Running
		self.Running=false;disconnect()
		if active and root and root.Parent then
			pcall(function()
				if humanoid and humanoid.Parent and humanoid.Health>0 then
					humanoid.Sit=false;humanoid.Jump=true
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)
			pcall(function()
				root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
				if character==player.Character and humanoid.Health>0 then root.CFrame=checkpoint end
			end)
			-- Restore this separately even if releasing/returning failed.
			pcall(function()root.Anchored=previousAnchored end)
		end
		self.Mode=nil;self.Phase="IDLE"
		update(message or text("Prueba detenida; anclaje anterior restaurado.","Test stopped; previous anchoring restored."))
		return active
	end
	local function nearestSeat()
		local best,distance
		-- Only one full scan per activation, never per frame.
		for _,candidate in ipairs(workspace:GetDescendants())do
			if (candidate:IsA("Seat")or candidate:IsA("VehicleSeat"))and not candidate.Disabled and not candidate.Occupant then
				local d=(candidate.Position-root.Position).Magnitude
				if not distance or d<distance then best,distance=candidate,d end
			end
		end
		return best
	end
	local function hold()
		-- Seat-compatible: no anti-seat, weld deletion or forced GettingUp here.
		root.Anchored=true
		root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
		root.CFrame=checkpoint
	end
	local function sit()
		local ok,err=pcall(function()seat:Sit(humanoid)end)
		if not ok then C:Stop(text("Fallo de sentado: ","Seat attempt failed: ")..tostring(err))end
		return ok
	end
	function C:Start(mode)
		if not self:IsAuthorized()then return false,"Solo owners."end
		if self.Running then return false,text("Deten primero la prueba actual.","Stop the current test first.")end
		if mode~="trip"and mode~="anchor"then return false,"Modo invalido."end
		local other=conflict();if other then return false,text("Desactiva primero: ","Disable first: ")..other end
		character=player.Character
		humanoid=character and character:FindFirstChildOfClass("Humanoid")
		root=character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root or humanoid.Health<=0 then return false,text("Personaje no disponible.","Character unavailable.")end
		if humanoid.SeatPart or humanoid.Sit then return false,text("Levantate antes de empezar.","Leave your current seat first.")end
		if root.Anchored then return false,text("Desactiva el anclaje actual.","Disable existing anchoring first.")end
		seat=nearestSeat()
		if not seat then return false,text("No hay asientos libres disponibles.","No free seats available.")end
		checkpoint=root.CFrame;previousAnchored=root.Anchored
		self.Checkpoint=checkpoint;self.Seat=seat
		self.OccupantMatches=false;self.SeatPartMatches=false;self.WeldMatches=false
		elapsed,displayElapsed,confirmed=0,0,false
		self.Running=true;self.Mode=mode;self.Phase=mode=="trip"and "APPROACH"or "ANCHOR_SIT"
		if mode=="trip"then
			root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
			root.CFrame=seat.CFrame*CFrame.new(0,2.5,0)
		else
			hold()
			if not sit()then return false,self.Status end
		end
		local function tick(dt,post)
			if not self.Running then return end
			local ok,err=xpcall(function()
				if player.Character~=character or not root.Parent or not humanoid.Parent or humanoid.Health<=0 then self:Stop(text("Personaje cambiado o muerto; prueba detenida.","Character changed or died; test stopped."));return end
				if not seat:IsDescendantOf(workspace)or seat.Disabled then self:Stop(text("Asiento retirado o desactivado.","Seat removed or disabled."));return end
				if seat.Occupant and seat.Occupant~=humanoid then self:Stop(text("Asiento ocupado por otro personaje.","Seat occupied by another character."));return end
				local competing=conflict();if competing then self:Stop(text("Conflicto: ","Conflict: ")..competing);return end
				if mode=="anchor"then hold()end
				if post then return end
				elapsed=elapsed+dt;displayElapsed=displayElapsed+dt
				local seated=evidence()
				if mode=="trip"then
					if self.Phase=="APPROACH"and elapsed>=.12 then
						self.Phase="SIT_WAIT";elapsed=0;if not sit()then return end
					elseif self.Phase=="SIT_WAIT"and elapsed>=.37 then
						self:Stop(text("Ida y regreso completados; flujo detenido automaticamente.","Round trip completed; flow stopped automatically."));return
					end
				else
					if seated then confirmed=true;self.Phase="HOLD"
					elseif confirmed then self:Stop(text("Se perdio la union con el asiento.","Seat attachment lost."));return
					elseif elapsed>=2.5 then self:Stop(text("Sin confirmacion local del asiento; intento finalizado.","No local seat confirmation; attempt ended."));return end
				end
				if displayElapsed>=.15 then
					displayElapsed=0
					update(self.Phase.." | Occupant="..tostring(self.OccupantMatches).." SeatPart="..tostring(self.SeatPartMatches).." Weld="..tostring(self.WeldMatches)..text(" | Solo evidencia local."," | Local evidence only."))
				end
			end,debug.traceback)
			if not ok then self:Stop(text("Error de prueba: ","Test error: ")..tostring(err))end
		end
		connections[#connections+1]=RunService.PreSimulation:Connect(function(dt)tick(dt,false)end)
		if mode=="anchor"then connections[#connections+1]=RunService.PostSimulation:Connect(function()tick(0,true)end)end
		update(text("Prueba iniciada. Asiento: ","Test started. Seat: ")..seat:GetFullName())
		return true
	end
	function C:Destroy()self:Stop()end
	return true
end
