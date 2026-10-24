-- Independent, owner-only local experiments; no changes to other anchor engines.
return function(context)
	setfenv(1,context)
	local C={Running=false,Mode=nil,Phase="IDLE",Status="",Seats={},SelectedIndex=0}
	SeatAnchorLabCore=C
	local connections={}
	local holdAttachment,holdPosition,holdOrientation
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
	local function clearHold()
		for _,object in pairs({holdPosition,holdOrientation,holdAttachment})do
			pcall(function()object:Destroy()end)
		end
		holdPosition,holdOrientation,holdAttachment=nil,nil,nil
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
		self.Running=false;disconnect();clearHold()
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
	local function selectSeat(index)
		C.SelectedIndex=index;C.Seat=C.Seats[index]
		local current=player.Character
		local reference=current and current:FindFirstChild("HumanoidRootPart")
		C.SeatDistance=C.Seat and reference and (C.Seat.Position-reference.Position).Magnitude or nil
		if not C.Seat then return false,text("No se encontraron asientos.","No seats found.")end
		update(text("Asiento ","Seat ")..index.."/"..#C.Seats..": "..C.Seat:GetFullName())
		return true
	end
	function C:RefreshSeat()
		if not self:IsAuthorized()then return false,"Solo owners."end
		if self.Running then return false,text("Deten la prueba antes de actualizar el asiento.","Stop the test before refreshing the seat.")end
		local current=player.Character
		local reference=current and current:FindFirstChild("HumanoidRootPart")
		if not reference then return false,text("Personaje no disponible.","Character unavailable.")end
		-- Original selector: Seat instances sorted by full path, no nearest-seat
		-- substitution or VehicleSeat fallback. Validate availability on Start.
		self.Seats={}
		for _,candidate in ipairs(workspace:GetDescendants())do
			if candidate:IsA("Seat")then self.Seats[#self.Seats+1]=candidate end
		end
		table.sort(self.Seats,function(a,b)return a:GetFullName()<b:GetFullName()end)
		if #self.Seats==0 then
			self.Seat=nil;self.SeatDistance=nil;self.SelectedIndex=0
			local message=text("No se encontraron asientos.","No seats found.")
			update(message);return false,message
		end
		return selectSeat(1)
	end
	function C:SelectSeat(direction)
		if not self:IsAuthorized()then return false,"Solo owners."end
		if self.Running then return false,text("Deten la prueba antes de cambiar de asiento.","Stop the test before changing seats.")end
		if #self.Seats==0 then return self:RefreshSeat()end
		return selectSeat(((self.SelectedIndex-1+(direction<0 and -1 or 1))%#self.Seats)+1)
	end
	local function hold()
		-- Physical alternative: only local character constraints, no SeatWeld
		-- edits, anchored-seat edits, or repeated CFrame/velocity overrides.
		root.Anchored=false
		if not holdAttachment or not holdAttachment.Parent or not holdPosition or not holdPosition.Parent or not holdOrientation or not holdOrientation.Parent then
			clearHold()
			holdAttachment=Instance.new("Attachment")
			holdAttachment.Name="SeatLabHoldAttachment";holdAttachment.Parent=root
			holdPosition=Instance.new("AlignPosition")
			holdPosition.Name="SeatLabHoldPosition"
			holdPosition.Mode=Enum.PositionAlignmentMode.OneAttachment
			holdPosition.Attachment0=holdAttachment
			holdPosition.MaxForce=1000000;holdPosition.MaxVelocity=150
			holdPosition.Responsiveness=200;holdPosition.RigidityEnabled=false
			holdPosition.ApplyAtCenterOfMass=true;holdPosition.ReactionForceEnabled=false
			holdPosition.Position=checkpoint.Position;holdPosition.Parent=root
			holdOrientation=Instance.new("AlignOrientation")
			holdOrientation.Name="SeatLabHoldOrientation"
			holdOrientation.Mode=Enum.OrientationAlignmentMode.OneAttachment
			holdOrientation.Attachment0=holdAttachment
			holdOrientation.MaxTorque=1000000;holdOrientation.MaxAngularVelocity=20
			holdOrientation.Responsiveness=200;holdOrientation.RigidityEnabled=false
			holdOrientation.ReactionTorqueEnabled=false
			holdOrientation.CFrame=checkpoint;holdOrientation.Parent=root
		end
		holdPosition.Position=checkpoint.Position;holdOrientation.CFrame=checkpoint
	end
	local function sit()
		local ok,err=pcall(function()
			-- A previous round trip releases with Jump=true. Do not carry that
			-- request into the next sitting attempt.
			humanoid.Jump=false
			seat:Sit(humanoid)
		end)
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
		if mode=="trip"and (humanoid.SeatPart or humanoid.Sit)then return false,text("Levantate antes de empezar la ida y regreso.","Leave your current seat before the round trip.")end
		if root.Anchored then return false,text("Desactiva el anclaje actual.","Disable existing anchoring first.")end
		-- Respect the selection displayed by RefreshSeat. Never silently switch
		-- seats just because the character or another seat moved after refresh.
		if not self.Seat then
			local ok,err=self:RefreshSeat()
			if not ok then return false,err end
		end
		seat=self.Seat
		if not seat:IsDescendantOf(workspace)or not (seat:IsA("Seat")or seat:IsA("VehicleSeat"))then
			return false,text("El asiento seleccionado ya no esta disponible. Pulsa Actualizar asiento.","Selected seat is unavailable. Refresh the seat first.")
		end
		if seat.Occupant and not (mode=="anchor"and seat.Occupant==humanoid)then return false,text("El asiento seleccionado esta ocupado. Pulsa Actualizar asiento.","Selected seat is occupied. Refresh the seat first.")end
		if mode=="anchor"and humanoid.SeatPart and humanoid.SeatPart~=seat then
			return false,text("Estas sentado en otro asiento distinto del seleccionado.","You are sitting in a different seat than the selected one.")
		end
		self.SeatDistance=(seat.Position-root.Position).Magnitude
		if mode=="trip"then
			-- The reference is where the round-trip button was pressed, not where
			-- a later seat correction happens to place the character.
			self.TripCheckpoint=root.CFrame;self.TripCharacter=character;self.TripSeat=seat
		else
			if not self.TripCheckpoint or self.TripCharacter~=character or self.TripSeat~=seat then
				return false,text("Ejecuta primero la prueba de ida y regreso con este personaje y asiento para guardar el punto.","Run the round trip with this character and seat first to save the checkpoint.")
			end
		end
		checkpoint=mode=="anchor"and self.TripCheckpoint or root.CFrame
		previousAnchored=root.Anchored
		self.Checkpoint=checkpoint;self.Seat=seat
		self.HoldStrategy=mode=="anchor"and "PHYSICAL_CONSTRAINTS"or nil
		self.OccupantMatches=false;self.SeatPartMatches=false;self.WeldMatches=false
		elapsed,displayElapsed,confirmed=0,0,false
		self.Running=true;self.Mode=mode;self.Phase=mode=="trip"and "APPROACH"or "ANCHOR_SIT"
		if mode=="trip"then
			root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
			root.CFrame=seat.CFrame*CFrame.new(0,2.5,0)
		else
			humanoid.Jump=false
			hold()
			-- Preserve an existing seat attachment instead of rejecting it or
			-- requesting another Sit that may interrupt the current attachment.
			if humanoid.SeatPart~=seat and seat.Occupant~=humanoid then
				if not sit()then return false,self.Status end
			end
		end
		local function tick(dt,post)
			if not self.Running then return end
			local ok,err=xpcall(function()
				if player.Character~=character or not root.Parent or not humanoid.Parent or humanoid.Health<=0 then self:Stop(text("Personaje cambiado o muerto; prueba detenida.","Character changed or died; test stopped."));return end
				if not seat:IsDescendantOf(workspace)then self:Stop(text("Asiento retirado.","Seat removed."));return end
				if seat.Occupant and seat.Occupant~=humanoid then self:Stop(text("Asiento ocupado por otro personaje.","Seat occupied by another character."));return end
				local competing=conflict();if competing then self:Stop(text("Conflicto: ","Conflict: ")..competing);return end
				if mode=="anchor"then hold()end
				if post then return end
				elapsed=elapsed+dt;displayElapsed=displayElapsed+dt
				local seated=evidence()
				if mode=="trip"then
					if self.Phase=="APPROACH"and elapsed>=.12 then
						self.Phase="SIT_WAIT";elapsed=0;if not sit()then return end
					elseif self.Phase=="SIT_WAIT"and elapsed>=.12 then
						-- Original sequence: wait .12 after Sit(), inspect, then hold .25.
						self.Phase="SIT_HOLD";elapsed=0
					elseif self.Phase=="SIT_HOLD"and elapsed>=.25 then
						self:Stop(text("Ida y regreso completados; flujo detenido automaticamente.","Round trip completed; flow stopped automatically."));return
					end
				else
					self.LocalCheckpointError=(root.Position-checkpoint.Position).Magnitude
					self.SeatAnchored=seat.Anchored
					local assembly=root.AssemblyRootPart
					self.AssemblyAnchored=assembly and assembly.Anchored
					if seated then confirmed=true;self.Phase=self.LocalCheckpointError<=1 and "HOLD"or "SEATED_RETURNING"
					elseif confirmed then self.Phase="HOLD_SEAT_UNCONFIRMED"
					else self.Phase="WAIT_SEAT"end
					-- Missing or delayed evidence is not a reason to stand the player
					-- up. Keep anchoring until explicit stop, invalid seat, or lifecycle exit.
				end
				if displayElapsed>=.15 then
					displayElapsed=0
					local physical=mode=="anchor"and string.format(" | error=%.2f studs Seat.Anchored=%s Assembly.Anchored=%s",self.LocalCheckpointError,tostring(self.SeatAnchored),tostring(self.AssemblyAnchored))or ""
					update(self.Phase.." | Occupant="..tostring(self.OccupantMatches).." SeatPart="..tostring(self.SeatPartMatches).." Weld="..tostring(self.WeldMatches)..physical..text(" | Solo evidencia local."," | Local evidence only."))
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
