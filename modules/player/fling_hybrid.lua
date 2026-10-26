-- Reposition at the current target every Heartbeat, then apply classic XYZ velocity.
return function(context)
	setfenv(1,context)
	local core={Running=false,Phase="IDLE",Config={DescentSpeed=9000,DiagonalSpeed=9000}}
	HybridFlingCore=core
	local connections,collisions={},{}
	local character,humanoid,root,checkpoint,saved,target
	local settling
	local function cancelSettling()
		if settling then settling:Disconnect();settling=nil end
	end
	local function refresh(message)if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel(message)end end
	local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
	local function vector(v)return finite(v.X)and finite(v.Y)and finite(v.Z)end
	function core:IsAuthorized()return ExperimentalFlingCore and ExperimentalFlingCore:IsAuthorized()or false end
	function core:SetParameter(name,value)
		local limits={DescentSpeed={0,150000},DiagonalSpeed={0,150000}}
		local range=limits[name]
		if not self:IsAuthorized()or not range or not finite(value)or value<range[1]or value>range[2]then return false end
		self.Config[name]=value;return true
	end
	local function zero()
		if root and root.Parent then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
	end
	local function zeroRig(parts)
		for _,part in ipairs(parts)do
			if part.Parent then part.AssemblyLinearVelocity=Vector3.zero;part.AssemblyAngularVelocity=Vector3.zero end
		end
	end
	function core:Stop(message)
		if not self.Running then return false end
		self.Running=false;self.Phase="IDLE"
		for _,c in ipairs(connections)do c:Disconnect()end;table.clear(connections)
		cancelSettling()
		if character==player.Character and root and root.Parent and humanoid and humanoid.Parent then
			local parts={root}
			for _,part in ipairs(character:GetDescendants())do
				if part~=root and part:IsA("BasePart")then parts[#parts+1]=part end
			end
			zeroRig(parts)
			if humanoid.Health>0 and checkpoint then root.CFrame=checkpoint end
			zeroRig(parts)
			humanoid.PlatformStand=saved.PlatformStand;humanoid.AutoRotate=saved.AutoRotate
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,saved.Seated)
			if humanoid.Health>0 then
				local stoppedCharacter,stoppedRoot,stoppedHumanoid=character,root,humanoid
				local returnFrame=checkpoint
				local started=os.clock()
				local untilTime,deadline=started+.25,started+1.5
				settling=RunService.Heartbeat:Connect(function()
					local now=os.clock()
					if self.Running or player.Character~=stoppedCharacter or not stoppedRoot.Parent or stoppedHumanoid.Health<=0 or now>=deadline then cancelSettling();return end
					local position=stoppedRoot.Position
					local displaced=returnFrame and(not vector(position)or(position-returnFrame.Position).Magnitude>.5)
					if displaced then
						zeroRig(parts)
						stoppedRoot.CFrame=returnFrame
						untilTime=now+.25
					elseif now>=untilTime then cancelSettling();return end
					zeroRig(parts)
				end)
			end
		end
		for part,value in pairs(collisions)do if part.Parent then part.CanCollide=value end end
		table.clear(collisions);target=nil
		refresh(message or "Fling hibrido detenido; velocidades limpiadas.");return true
	end
	local function suppress(part)
		if part:IsA("BasePart")then
			if collisions[part]==nil then collisions[part]=part.CanCollide end
			part.CanCollide=false
		end
	end
	local function passengerConnected(tc,th)
		local seat=th.SeatPart
		if not seat or not(seat:IsA("Seat")or seat:IsA("VehicleSeat"))or seat.Occupant~=th then return false end
		local cars=workspace:FindFirstChild("Cars")
		if not cars then return false end
		local vehicle=seat
		while vehicle and vehicle.Parent~=cars do vehicle=vehicle.Parent end
		if not vehicle then return false end
		local reference=vehicle:FindFirstChild("VehicleOwner")
		local owner=reference and reference:IsA("ObjectValue")and reference.Value
		if owner then
			if owner~=player then return false end
		elseif tonumber(vehicle:GetAttribute("VehicleOwner"))~=player.UserId then return false end
		local weld=seat:FindFirstChild("SeatWeld")
		if not weld or not(weld:IsA("JointInstance")or weld:IsA("WeldConstraint"))then return false end
		local a,b=weld.Part0,weld.Part1
		if not(a==seat and b and b:IsDescendantOf(tc)or b==seat and a and a:IsDescendantOf(tc))then return false end
		-- Ownership alone is insufficient: our character must also be riding
		-- this assembly. Discovery runs only when occupancy and weld already match.
		for _,part in ipairs(root:GetConnectedParts(true))do
			if part==vehicle or part:IsDescendantOf(vehicle)then return true end
		end
		return false
	end
	local function escape()
		local cfg=core.Config
		root.AssemblyAngularVelocity=Vector3.zero
		root.AssemblyLinearVelocity=Vector3.new(0,-cfg.DescentSpeed,0)
		humanoid.PlatformStand=true
	end
	local function step()
		if not core:IsAuthorized()then core:Stop("Prueba exclusiva para owners.");return end
		if player.Character~=character or not root.Parent or humanoid.Health<=0 then core:Stop("Personaje local perdido.");return end
		if target.Parent~=Players then core:Stop("El jugador seleccionado salio.");return end
		local tc=target.Character
		local tr=tc and tc:FindFirstChild("HumanoidRootPart")
		local th=tc and tc:FindFirstChildOfClass("Humanoid")
		if not tr or not th or th.Health<=0 then
			if core.Phase~="WAIT_TARGET"then zero();root.CFrame=checkpoint;core.Phase="WAIT_TARGET";refresh("Esperando la reaparicion del jugador seleccionado.")end
			root.AssemblyAngularVelocity=Vector3.zero
			return
		end
		if passengerConnected(tc,th)then
			if core.Phase~="ESCAPE"then
				core.Phase="ESCAPE"
				refresh("Copiloto confirmado: descenso mientras conserve la conexion al asiento.")
			end
			escape();return
		end
		if core.Phase=="ESCAPE"then
			zero();core.Phase="CONTACT"
			refresh("Copiloto desconectado: retomando contacto con el jugador seleccionado.")
		end
		if not vector(tr.Position)then core:Stop("Datos de posicion no validos.");return end
		if core.Phase=="WAIT_TARGET"then core.Phase="CONTACT";refresh()end
		local cfg=core.Config
		root.AssemblyAngularVelocity=Vector3.zero
		-- Always use the live HRP position: no lead, timers or distance gating.
		local destination=tr.Position+tr.CFrame.RightVector*.5
		root.CFrame=CFrame.new(destination)*root.CFrame.Rotation
		local speed=cfg.DiagonalSpeed
		root.AssemblyLinearVelocity=Vector3.new(speed,speed,speed)
		humanoid.PlatformStand=true;humanoid.Sit=false
	end
	function core:Start(selected)
		if not self:IsAuthorized()then return false,"Prueba exclusiva para owners."end
		if self.Running then return true end
		if not selected or selected==player or selected.Parent~=Players then return false,"Selecciona un jugador."end
		character=player.Character;humanoid=character and character:FindFirstChildOfClass("Humanoid");root=character and character:FindFirstChild("HumanoidRootPart")
		if not root or not humanoid or humanoid.Health<=0 then return false,"Tu personaje no esta disponible."end
		cancelSettling()
		checkpoint=root.CFrame;target=selected
		saved={PlatformStand=humanoid.PlatformStand,AutoRotate=humanoid.AutoRotate,Seated=humanoid:GetStateEnabled(Enum.HumanoidStateType.Seated)}
		self.Running=true;self.Phase="CONTACT"
		local ok,err=xpcall(function()
			humanoid.AutoRotate=false;humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
			for _,part in ipairs(character:GetDescendants())do suppress(part)end
			connections[#connections+1]=character.DescendantAdded:Connect(suppress)
			connections[#connections+1]=humanoid.Died:Connect(function()self:Stop("Personaje sin vida.")end)
			connections[#connections+1]=RunService.Heartbeat:Connect(function()
				local success,failure=xpcall(step,debug.traceback)
				if not success then self:Stop("Error del flujo hibrido: "..tostring(failure))end
			end)
			step()
		end,debug.traceback)
		if not ok then self:Stop();return false,tostring(err)end
		refresh();return true
	end
	function core:Destroy()self:Stop();cancelSettling()end
	return true
end
