-- Reposition at the current target every Heartbeat, then apply classic XYZ velocity.
return function(context)
	setfenv(1,context)
	local core={Running=false,Phase="IDLE",Config={Spin=10000,DiagonalSpeed=9000}}
	HybridFlingCore=core
	local connections,collisions={},{}
	local character,humanoid,root,checkpoint,saved,spin,target
	local function refresh(message)if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel(message)end end
	local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
	local function vector(v)return finite(v.X)and finite(v.Y)and finite(v.Z)end
	function core:IsAuthorized()return ExperimentalFlingCore and ExperimentalFlingCore:IsAuthorized()or false end
	function core:SetParameter(name,value)
		local limits={Spin={0,150000},DiagonalSpeed={0,150000}}
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
		if not vector(tr.Position)then core:Stop("Datos de posicion no validos.");return end
		if core.Phase=="WAIT_TARGET"then core.Phase="CONTACT";refresh()end
		local cfg=core.Config
		spin.AngularVelocity=Vector3.new(0,cfg.Spin,0)
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
		checkpoint=root.CFrame;target=selected
		saved={PlatformStand=humanoid.PlatformStand,AutoRotate=humanoid.AutoRotate,Seated=humanoid:GetStateEnabled(Enum.HumanoidStateType.Seated)}
		self.Running=true;self.Phase="CONTACT"
		local ok,err=xpcall(function()
			humanoid.AutoRotate=false;humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
			for _,part in ipairs(character:GetDescendants())do suppress(part)end
			spin=Instance.new("BodyAngularVelocity");spin.Name="VR7HybridSpin";spin.MaxTorque=Vector3.new(1e9,1e9,1e9);spin.AngularVelocity=Vector3.zero;spin.Parent=root
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
	function core:Destroy()self:Stop()end
	return true
end
