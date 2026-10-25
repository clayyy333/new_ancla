-- Timed target contact followed by free diagonal launch. Own rig only.
return function(context)
	setfenv(1,context)
	local core={Running=false,Phase="IDLE",Config={Spin=10000,DiagonalSpeed=9000,ContactTime=.20,LaunchTime=.10}}
	HybridFlingCore=core
	local connections,collisions={},{}
	local character,humanoid,root,checkpoint,saved,spin,target,phaseStart
	local function refresh(message)if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel(message)end end
	local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
	local function vector(v)return finite(v.X)and finite(v.Y)and finite(v.Z)end
	function core:IsAuthorized()return ExperimentalFlingCore and ExperimentalFlingCore:IsAuthorized()or false end
	function core:SetParameter(name,value)
		local limits={Spin={0,150000},DiagonalSpeed={0,150000},ContactTime={.05,2},LaunchTime={.05,2}}
		local range=limits[name]
		if not self:IsAuthorized()or not range or not finite(value)or value<range[1]or value>range[2]then return false end
		self.Config[name]=value;return true
	end
	local function zero()
		if root and root.Parent then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
	end
	function core:Stop(message)
		if not self.Running then return false end
		self.Running=false;self.Phase="IDLE"
		for _,c in ipairs(connections)do c:Disconnect()end;table.clear(connections)
		if spin then spin:Destroy();spin=nil end
		if character==player.Character and root and root.Parent and humanoid and humanoid.Parent then
			zero()
			if humanoid.Health>0 and checkpoint then root.CFrame=checkpoint end
			humanoid.PlatformStand=saved.PlatformStand;humanoid.AutoRotate=saved.AutoRotate
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,saved.Seated)
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
	local function step()
		if not core:IsAuthorized()then core:Stop("Prueba exclusiva para owners.");return end
		if player.Character~=character or not root.Parent or humanoid.Health<=0 then core:Stop("Personaje local perdido.");return end
		if target.Parent~=Players then core:Stop("El jugador seleccionado salio.");return end
		local tc=target.Character
		local tr=tc and tc:FindFirstChild("HumanoidRootPart")
		local th=tc and tc:FindFirstChildOfClass("Humanoid")
		if not tr or not th or th.Health<=0 then
			if core.Phase~="WAIT_TARGET"then zero();root.CFrame=checkpoint;core.Phase="WAIT_TARGET";refresh("Esperando la reaparicion del jugador seleccionado.")end
			spin.AngularVelocity=Vector3.zero
			return
		end
		if not vector(tr.Position)or not vector(tr.AssemblyLinearVelocity)then core:Stop("Datos del objetivo no validos.");return end
		local now=os.clock()
		if core.Phase=="WAIT_TARGET"then core.Phase="CONTACT";phaseStart=now;refresh()end
		local cfg=core.Config
		if core.Phase=="LAUNCH"and now-phaseStart>=cfg.LaunchTime then
			zero();core.Phase="CONTACT";phaseStart=now
		end
		spin.AngularVelocity=Vector3.new(0,cfg.Spin,0)
		if core.Phase=="CONTACT"then
			-- Exact half-stud offset from the current target, without prediction drift.
			local destination=tr.Position+tr.CFrame.RightVector*.5
			root.CFrame=CFrame.new(destination)*root.CFrame.Rotation
			root.AssemblyLinearVelocity=Vector3.zero
			if now-phaseStart>=cfg.ContactTime then core.Phase="LAUNCH";phaseStart=now end
		end
		if core.Phase=="LAUNCH"then
			-- World XYZ, as in the classic. No position writes during outgoing flight.
			local speed=cfg.DiagonalSpeed
			root.AssemblyLinearVelocity=Vector3.new(speed,speed,speed)
		end
		humanoid.PlatformStand=true;humanoid.Sit=false
	end
	function core:Start(selected)
		if not self:IsAuthorized()then return false,"Prueba exclusiva para owners."end
		if self.Running then return true end
		if not selected or selected==player or selected.Parent~=Players then return false,"Selecciona un jugador."end
		character=player.Character;humanoid=character and character:FindFirstChildOfClass("Humanoid");root=character and character:FindFirstChild("HumanoidRootPart")
		if not root or not humanoid or humanoid.Health<=0 then return false,"Tu personaje no esta disponible."end
		checkpoint=root.CFrame;target=selected
		saved={PlatformStand=humanoid.PlatformStand,AutoRotate=humanoid.AutoRotate,Seated=humanoid:GetStateEnabled(Enum.HumanoidStateType.Seated)}
		self.Running=true;self.Phase="CONTACT";phaseStart=os.clock()
		local ok,err=xpcall(function()
			humanoid.AutoRotate=false;humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
			for _,part in ipairs(character:GetDescendants())do suppress(part)end
			spin=Instance.new("BodyAngularVelocity");spin.Name="VR7HybridSpin";spin.MaxTorque=Vector3.new(1e9,1e9,1e9);spin.AngularVelocity=Vector3.zero;spin.Parent=root
			connections[#connections+1]=character.DescendantAdded:Connect(suppress)
			connections[#connections+1]=humanoid.Died:Connect(function()self:Stop("Personaje sin vida.")end)
			connections[#connections+1]=RunService.PreSimulation:Connect(function()
				local success,failure=xpcall(step,debug.traceback)
				if not success then self:Stop("Error del flujo hibrido: "..tostring(failure))end
			end)
		end,debug.traceback)
		if not ok then self:Stop();return false,tostring(err)end
		refresh();return true
	end
	function core:Destroy()self:Stop()end
	return true
end
