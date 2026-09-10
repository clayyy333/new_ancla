# Fling 2 eficiente — implementación actual

Este documento conserva la implementación que resultó efectiva durante las pruebas. El motor es independiente de `Fling` y `Fling 2`; no modifica sus parámetros internos.

## Flujo

```text
NEAR (±1.5 studs durante 0.040–0.085 s)
→ FAR
→ RETURN_DIRECT hacia la posición actual del objetivo
→ VERIFY_RETURN
   ├─ éxito → NEAR
   └─ fallo → RETURN_16 (±16 studs) → RETURN_NEAR → NEAR
```

El objetivo se vuelve a consultar en cada `Heartbeat`. Si su personaje falta temporalmente, el ciclo espera y no utiliza una posición antigua.

## Parámetros principales

- Fuerza: `900000000`; no fue aumentada.
- `MaxForce`: infinito en X, Y y Z.
- `P`: `1250`.
- Contacto NEAR: `±1.5` studs.
- Duración NEAR: `0.040–0.085` segundos.
- Tolerancia del retorno directo: `4` studs.
- Estabilización al detener: `2` segundos, limpiando las físicas en cada `Heartbeat`.
- Los tres motores Fling son mutuamente excluyentes.

## Módulo completo del motor

```lua-- Motor Fling 2 eficiente independiente. Este modulo no crea ninguna GUI independiente.
return function(context)
	setfenv(1, context)

	local LocalPlayer = player
local CONFIG = {
	VERTICAL_DISTANCE = 1.5,
	LINEAR_SPEED = 900000000,
	ANGULAR_SPEED = 900000000,
	FLINGER_VELOCITY = Vector3.new(900000000, 900000000, 900000000),
	MAX_FORCE = Vector3.new(math.huge, math.huge, math.huge),
	P = 1250,

	-- Force Target / Recovery
	RECOVERY_DISTANCE = 80,       -- si te alejas más → RECOVERY
	NEAR_DISTANCE = 6,            -- se considera recuperado
	REQUIRED_NEAR_FRAMES = 4,     -- frames consecutivos cerca para salir de RECOVERY
	MAX_RECOVERY_ATTEMPTS = 40,

	-- Front Flip
	FRONT_FLIP_SPEED = 60,        -- rad/s
	NEAR_MIN_TIME = 0.040,
	NEAR_MAX_TIME = 0.085,
	DIRECT_RETURN_TOLERANCE = 4,
	FAR_DISTANCES = {4487425, 7554477, 9193601, 11000000, 12572022, 15000000, 17003482, 21098414},
}

--------------------------------------------------
-- PROVIDER
--------------------------------------------------

local Provider = {}

function Provider:GetLocalCharacter()
	return LocalPlayer.Character
end

function Provider:GetTargetOptions()
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(result, player)
		end
	end
	return result
end

function Provider:ResolveTarget(option)
	if typeof(option) == "Instance" and option:IsA("Player") then
		return option
	end
	if typeof(option) == "Instance" and option:IsA("Model") and option.Parent then
		return option
	end
	return nil
end

function Provider:GetCharacterFromTarget(target)
	if not target then return nil end
	if target:IsA("Player") then
		return target.Character
	end
	return target
end

--------------------------------------------------
-- CORE
--------------------------------------------------

local VR7EfficientCore = {}
VR7EfficientCore.__index = VR7EfficientCore

function VR7EfficientCore.new(provider)
	local self = setmetatable({}, VR7EfficientCore)
	self.Provider = provider
	self.Running = false
	self.Stopping = false
	self.StopCycle = 0
	self.Connection = nil
	self.Flinger = nil
	self.AttackerCheckpoint = nil
	self.Direction = 1
	self.SelectedTarget = nil

	-- Front Flip
	self.FrontFlipEnabled = false
	self.FrontFlipAngular = nil
	self.FrontFlipAttachment = nil

	-- Force Target
	self.LastTargetCFrame = nil
	self.DistanceFromTarget = 0
	self.State = "IDLE" -- IDLE / NORMAL / RECOVERY
	self.RecoveryConsecutiveNear = 0

	return self
end

local function getParts(character)
	if not character then return nil, nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return nil, nil
	end
	return humanoid, root
end

function VR7EfficientCore:SetTarget(option)
	local resolved = self.Provider:ResolveTarget(option)
	self.SelectedTarget = resolved
	return resolved ~= nil
end

function VR7EfficientCore:GetTarget()
	return self.SelectedTarget
end

--------------------------------------------------
-- FRONT FLIP
--------------------------------------------------

function VR7EfficientCore:DestroyFrontFlip()
	if self.FrontFlipAngular then
		pcall(function() self.FrontFlipAngular:Destroy() end)
		self.FrontFlipAngular = nil
	end
	if self.FrontFlipAttachment then
		pcall(function() self.FrontFlipAttachment:Destroy() end)
		self.FrontFlipAttachment = nil
	end
end

function VR7EfficientCore:ActivateFrontFlip(root)
	self:DestroyFrontFlip()
	if not root then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = "FrontFlipAttachment"
	attachment.Parent = root

	local angular = Instance.new("AngularVelocity")
	angular.Name = "FrontFlipAngularVelocity"
	angular.Attachment0 = attachment
	angular.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	angular.AngularVelocity = Vector3.new(CONFIG.FRONT_FLIP_SPEED, 0, 0)
	angular.MaxTorque = math.huge
	angular.Parent = root

	self.FrontFlipAttachment = attachment
	self.FrontFlipAngular = angular
end

function VR7EfficientCore:SetFrontFlipEnabled(enabled)
	self.FrontFlipEnabled = enabled and true or false

	if not self.Running then
		self:DestroyFrontFlip()
		return
	end

	local _, root = getParts(self.Provider:GetLocalCharacter())
	if self.FrontFlipEnabled and root then
		self:ActivateFrontFlip(root)
	else
		self:DestroyFrontFlip()
	end
end

function VR7EfficientCore:EnsureFrontFlip(root)
	if not self.FrontFlipEnabled or not root then
		return
	end
	if self.FrontFlipAngular and self.FrontFlipAngular.Parent == root then
		self.FrontFlipAngular.AngularVelocity = Vector3.new(CONFIG.FRONT_FLIP_SPEED, 0, 0)
		self.FrontFlipAngular.MaxTorque = math.huge
		return
	end
	self:ActivateFrontFlip(root)
end

--------------------------------------------------
-- FLINGER
--------------------------------------------------

function VR7EfficientCore:DestroyFlinger()
	if self.Flinger then
		pcall(function() self.Flinger:Destroy() end)
		self.Flinger = nil
	end
end

function VR7EfficientCore:Disconnect()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	self:DestroyFlinger()
	self:DestroyFrontFlip()
end

function VR7EfficientCore:CreateFlinger(root)
	self:DestroyFlinger()
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "VR7VerticalFlinger"
	bodyVelocity.P = CONFIG.P
	bodyVelocity.MaxForce = CONFIG.MAX_FORCE
	bodyVelocity.Velocity = CONFIG.FLINGER_VELOCITY
	bodyVelocity.Parent = root
	self.Flinger = bodyVelocity
end

--------------------------------------------------
-- FORCE TARGET / RECOVERY
--------------------------------------------------

function VR7EfficientCore:UpdateLastTarget(currentTargetRoot)
	if currentTargetRoot then
		self.LastTargetCFrame = currentTargetRoot.CFrame
	end
	-- Si desaparece temporalmente, se conserva el último CFrame válido
end

function VR7EfficientCore:UpdateDistance(currentRoot)
	if currentRoot and self.LastTargetCFrame then
		self.DistanceFromTarget = (currentRoot.Position - self.LastTargetCFrame.Position).Magnitude
	else
		self.DistanceFromTarget = 0
	end
end

function VR7EfficientCore:GoNearLastTarget(currentRoot)
	if not currentRoot or not self.LastTargetCFrame then
		return
	end
	-- Posición relativa al último target conocido
	local desired = self.LastTargetCFrame * CFrame.new(0, CONFIG.VERTICAL_DISTANCE * self.Direction, 0)
	currentRoot.CFrame = CFrame.new(desired.Position) * currentRoot.CFrame.Rotation
end

function VR7EfficientCore:IsNearLastTarget(currentRoot)
	if not currentRoot or not self.LastTargetCFrame then
		return false
	end
	return (currentRoot.Position - self.LastTargetCFrame.Position).Magnitude <= CONFIG.NEAR_DISTANCE
end

--------------------------------------------------
-- START / STOP
--------------------------------------------------

function VR7EfficientCore:Start()
	-- Si INICIAR se pulsa durante la estabilización del Stop anterior,
	-- cancelar inmediatamente ese ciclo y liberar nuestro HumanoidRootPart.
	if self.Stopping then
		self.StopCycle = self.StopCycle + 1
		self.Stopping = false

		local _, currentRoot = getParts(self.Provider:GetLocalCharacter())
		if currentRoot then
			currentRoot.Anchored = false
			currentRoot.AssemblyLinearVelocity = Vector3.zero
			currentRoot.AssemblyAngularVelocity = Vector3.zero
		end
	end

	if self.Running then return true end
	if FlingCore and FlingCore.Running then FlingCore:Stop() end
	if Fling2Core and Fling2Core.Running then Fling2Core:Stop() end

	local attackerCharacter = self.Provider:GetLocalCharacter()
	local targetCharacter = self.Provider:GetCharacterFromTarget(self.SelectedTarget)

	local attackerHumanoid, attackerRoot = getParts(attackerCharacter)
	local _, targetRoot = getParts(targetCharacter)

	if not attackerRoot then
		return false, "Tu personaje no está disponible."
	end
	if not targetRoot then
		return false, "El objetivo no tiene personaje cargado."
	end

	self:Disconnect()

	self.AttackerCheckpoint = attackerRoot.CFrame
	self.Direction = 1
	self.Running = true
	self.State = "NORMAL"
	self.RecoveryConsecutiveNear = 0
	self.LastTargetCFrame = targetRoot.CFrame
	self.DistanceFromTarget = 0
	self.EfficientPhase = "NEAR"
	self.NearUntil = os.clock() + CONFIG.NEAR_MIN_TIME
	self.ReturnSide = 1

	attackerHumanoid.PlatformStand = false
	attackerHumanoid.AutoRotate = true
	pcall(function()
		attackerHumanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
	end)

	self:CreateFlinger(attackerRoot)

	if self.FrontFlipEnabled then
		self:ActivateFrontFlip(attackerRoot)
	end

	self.Connection = RunService.Heartbeat:Connect(function()
		if not self.Running then return end
		local currentHumanoid, currentRoot = getParts(self.Provider:GetLocalCharacter())
		local _, currentTargetRoot = getParts(self.Provider:GetCharacterFromTarget(self.SelectedTarget))
		if not currentHumanoid or not currentRoot then self:Stop(); return end

		-- Esperar si el objetivo reaparece; nunca regresar a una posición antigua.
		if not currentTargetRoot then return end
		self:UpdateLastTarget(currentTargetRoot)
		if not self.Flinger or self.Flinger.Parent ~= currentRoot then self:CreateFlinger(currentRoot) end
		self.Flinger.Velocity = CONFIG.FLINGER_VELOCITY
		self.Flinger.MaxForce = CONFIG.MAX_FORCE
		self.Flinger.P = CONFIG.P

		local function placeNear()
			self.Direction = -self.Direction
			local desired = currentTargetRoot.CFrame * CFrame.new(0, CONFIG.VERTICAL_DISTANCE * self.Direction, 0)
			currentRoot.CFrame = CFrame.new(desired.Position) * currentRoot.CFrame.Rotation
			currentRoot.AssemblyLinearVelocity = Vector3.new(0, CONFIG.LINEAR_SPEED * self.Direction, 0)
			currentRoot.AssemblyAngularVelocity = Vector3.new(CONFIG.ANGULAR_SPEED, CONFIG.ANGULAR_SPEED, CONFIG.ANGULAR_SPEED)
		end

		if self.EfficientPhase == "NEAR" then
			placeNear()
			if os.clock() >= self.NearUntil then self.EfficientPhase = "FAR" end
		elseif self.EfficientPhase == "FAR" then
			local far = CONFIG.FAR_DISTANCES[math.random(1, #CONFIG.FAR_DISTANCES)]
			local sx = math.random(0, 1) == 0 and -1 or 1
			local sz = math.random(0, 1) == 0 and -1 or 1
			currentRoot.CFrame = CFrame.new(currentTargetRoot.Position + Vector3.new(far * sx, far * 0.15 * self.Direction, far * sz))
			currentRoot.AssemblyLinearVelocity = CONFIG.FLINGER_VELOCITY
			self.EfficientPhase = "RETURN_DIRECT"
		elseif self.EfficientPhase == "RETURN_DIRECT" then
			placeNear()
			self.EfficientPhase = "VERIFY_RETURN"
		elseif self.EfficientPhase == "VERIFY_RETURN" then
			if (currentRoot.Position - currentTargetRoot.Position).Magnitude <= CONFIG.DIRECT_RETURN_TOLERANCE then
				self.EfficientPhase = "NEAR"
				self.NearUntil = os.clock() + CONFIG.NEAR_MIN_TIME + math.random() * (CONFIG.NEAR_MAX_TIME - CONFIG.NEAR_MIN_TIME)
			else
				self.ReturnSide = -self.ReturnSide
				self.EfficientPhase = "RETURN_16"
			end
		elseif self.EfficientPhase == "RETURN_16" then
			currentRoot.CFrame = currentTargetRoot.CFrame * CFrame.new(0, CONFIG.VERTICAL_DISTANCE * self.Direction, 16 * self.ReturnSide)
			self.EfficientPhase = "RETURN_NEAR"
		else
			placeNear()
			self.EfficientPhase = "NEAR"
			self.NearUntil = os.clock() + CONFIG.NEAR_MIN_TIME + math.random() * (CONFIG.NEAR_MAX_TIME - CONFIG.NEAR_MIN_TIME)
		end
	end)

	return true
end

function VR7EfficientCore:Stop()
	local wasRunning = self.Running

	-- Si ya existe un Stop estabilizando, no iniciar otro encima.
	if self.Stopping then
		return wasRunning
	end

	self.Running = false
	self.State = "IDLE"
	self.Stopping = true

	-- Nuevo identificador de este ciclo de estabilización.
	self.StopCycle = self.StopCycle + 1
	local myStopCycle = self.StopCycle

	-- Primero cortar el flujo activo y destruir fuerzas creadas por el script.
	self:Disconnect()

	local attackerCharacter = self.Provider:GetLocalCharacter()
	local humanoid, root = getParts(attackerCharacter)
	local checkpoint = self.AttackerCheckpoint

	if not root then
		self.Stopping = false
		self.AttackerCheckpoint = nil
		return wasRunning
	end

	local previousAnchored = root.Anchored

	local function clearPhysicsAndHold()
		-- Si otro Start canceló este Stop, salir sin tocar el nuevo ciclo.
		if self.StopCycle ~= myStopCycle then
			return false
		end

		if not root or not root.Parent then
			return false
		end

		-- Limpiar impulso residual.
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero

		-- Mantener exactamente el checkpoint guardado al activar.
		if checkpoint then
			root.CFrame = checkpoint
		end

		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		return true
	end

	--------------------------------------------------
	-- 1) PRIMERO VOLVER AL CHECKPOINT
	--------------------------------------------------
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	if checkpoint then
		root.CFrame = checkpoint
	end

	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero

	--------------------------------------------------
	-- 2) DESPUÉS ANCLAR EN ESE CHECKPOINT
	--------------------------------------------------
	root.Anchored = true

	--------------------------------------------------
	-- 3) ESTABILIZAR 2 SEGUNDOS, FRAME POR FRAME
	--------------------------------------------------
	local stabilizationStart = os.clock()
	while os.clock() - stabilizationStart < 2 do
		RunService.Heartbeat:Wait()

		-- Un nuevo Start invalida inmediatamente este Stop.
		if self.StopCycle ~= myStopCycle then
			return wasRunning
		end

		if not clearPhysicsAndHold() then
			break
		end
	end

	-- Si se canceló justo al salir del bucle, no interferir con Start().
	if self.StopCycle ~= myStopCycle then
		return wasRunning
	end

	--------------------------------------------------
	-- 4) LIMPIEZA FINAL ANTES DE DESANCLAR
	--------------------------------------------------
	clearPhysicsAndHold()

	if root and root.Parent then
		-- Normalmente era false; restauramos el estado que tenía antes.
		root.Anchored = previousAnchored
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	if humanoid and humanoid.Parent then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end

	--------------------------------------------------
	-- 5) UN FRAME LIBRE + ÚLTIMA LIMPIEZA
	--------------------------------------------------
	RunService.Heartbeat:Wait()

	if self.StopCycle ~= myStopCycle then
		return wasRunning
	end

	if root and root.Parent then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	self.AttackerCheckpoint = nil
	self.Direction = 1
	self.LastTargetCFrame = nil
	self.DistanceFromTarget = 0
	self.RecoveryConsecutiveNear = 0
	self.Stopping = false

	return wasRunning
end


	Fling2EfficientCore = VR7EfficientCore.new(Provider)

	_fling2EfficientPlayerRemovingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
		if Fling2EfficientCore:GetTarget() == leavingPlayer then
			if Fling2EfficientCore.Running then Fling2EfficientCore:Stop() end
			Fling2EfficientCore:SetTarget(nil)
			if UpdateFling2Panel then UpdateFling2Panel() end
		end
	end)

	_fling2EfficientCharacterAddedConn = LocalPlayer.CharacterAdded:Connect(function()
		if Fling2EfficientCore.Running then Fling2EfficientCore:Stop() end
		if UpdateFling2Panel then UpdateFling2Panel() end
	end)

	return true
end```

## Vista y botón integrados

El siguiente módulo contiene el selector compartido y los botones `Activar Fling 2` y `Activar Fling 2 eficiente`.

```lua-- Vista de Fling 2 integrada en la GUI principal.
return function(context)
	setfenv(1, context)

	fling2Panel = Instance.new("Frame")
	fling2Panel.Name = "Fling2Panel"
	fling2Panel.Size = UDim2.new(1, -16, 1, -(titleH + 20))
	fling2Panel.Position = UDim2.new(0, 8, 0, titleH + 8)
	fling2Panel.BackgroundTransparency = 1
	fling2Panel.Visible = false
	fling2Panel.ZIndex = 6
	fling2Panel.Parent = content

	local panelCard = Instance.new("Frame")
	panelCard.Size = UDim2.new(1, 0, 0, isMobile and 230 or 250)
	panelCard.BackgroundColor3 = currentTheme.secondary
	panelCard.ZIndex = 7
	panelCard.Parent = fling2Panel
	Instance.new("UICorner", panelCard).CornerRadius = UDim.new(0, 14)
	RegisterTheme(panelCard, "BackgroundColor3", "secondary")

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.Parent = panelCard

	local targetLabel = Instance.new("TextLabel")
	targetLabel.Size = UDim2.new(1, 0, 0, 20)
	targetLabel.BackgroundTransparency = 1
	targetLabel.Text = L.flingTarget
	targetLabel.TextColor3 = currentTheme.textDim
	targetLabel.Font = Enum.Font.GothamMedium
	targetLabel.TextSize = isMobile and 12 or 13
	targetLabel.TextXAlignment = Enum.TextXAlignment.Left
	targetLabel.ZIndex = 8
	targetLabel.Parent = panelCard
	RegisterTheme(targetLabel, "TextColor3", "textDim")

	local targetButton = Instance.new("TextButton")
	targetButton.Size = UDim2.new(1, 0, 0, 40)
	targetButton.Position = UDim2.new(0, 0, 0, 26)
	targetButton.BackgroundColor3 = currentTheme.tertiary
	targetButton.Text = L.selectPlayer
	targetButton.TextColor3 = currentTheme.text
	targetButton.Font = Enum.Font.GothamMedium
	targetButton.TextSize = isMobile and 12 or 14
	targetButton.TextXAlignment = Enum.TextXAlignment.Left
	targetButton.AutoButtonColor = false
	targetButton.ZIndex = 10
	targetButton.Parent = panelCard
	Instance.new("UICorner", targetButton).CornerRadius = UDim.new(0, 10)
	Instance.new("UIPadding", targetButton).PaddingLeft = UDim.new(0, 12)
	RegisterTheme(targetButton, "BackgroundColor3", "tertiary")
	RegisterTheme(targetButton, "TextColor3", "text")

	local targetList = Instance.new("ScrollingFrame")
	targetList.Size = UDim2.new(1, 0, 0, 120)
	targetList.Position = UDim2.new(0, 0, 0, 70)
	targetList.BackgroundColor3 = currentTheme.tertiary
	targetList.ScrollBarThickness = 4
	targetList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	targetList.CanvasSize = UDim2.new()
	targetList.Visible = false
	targetList.ZIndex = 30
	targetList.Parent = panelCard
	Instance.new("UICorner", targetList).CornerRadius = UDim.new(0, 10)
	RegisterTheme(targetList, "BackgroundColor3", "tertiary")
	local targetLayout = Instance.new("UIListLayout")
	targetLayout.Padding = UDim.new(0, 3)
	targetLayout.Parent = targetList

	local function MakeActionButton(y, text)
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 44)
		button.Position = UDim2.new(0, 0, 0, y)
		button.BackgroundColor3 = currentTheme.tertiary
		button.Text = text
		button.TextColor3 = currentTheme.text
		button.Font = Enum.Font.GothamBold
		button.TextSize = isMobile and 13 or 14
		button.AutoButtonColor = false
		button.ZIndex = 8
		button.Parent = panelCard
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
		RegisterTheme(button, "BackgroundColor3", "tertiary")
		RegisterTheme(button, "TextColor3", "text")
		return button
	end

	local flingButton = MakeActionButton(82, isES and "Activar Fling 2" or "Enable Fling 2")
	local efficientButton = MakeActionButton(134, isES and "Activar Fling 2 eficiente" or "Enable Efficient Fling 2")

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, 0, 0, 24)
	statusLabel.Position = UDim2.new(0, 0, 0, 140)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = currentTheme.textDim
	statusLabel.Font = Enum.Font.GothamMedium
	statusLabel.TextSize = isMobile and 11 or 12
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.ZIndex = 8
	statusLabel.Parent = panelCard
	RegisterTheme(statusLabel, "TextColor3", "textDim")

	UpdateFling2Panel = function(message)
		local target = Fling2Core:GetTarget()
		targetButton.Text = target and (target.DisplayName .. "  (@" .. target.Name .. ")") or L.selectPlayer
		flingButton.Text = Fling2Core.Running and (isES and "Desactivar Fling 2" or "Disable Fling 2") or (isES and "Activar Fling 2" or "Enable Fling 2")
		efficientButton.Text = Fling2EfficientCore.Running and (isES and "Desactivar Fling 2 eficiente" or "Disable Efficient Fling 2") or (isES and "Activar Fling 2 eficiente" or "Enable Efficient Fling 2")
		flingButton.BackgroundColor3 = Fling2Core.Running and currentTheme.critical or currentTheme.tertiary
		efficientButton.BackgroundColor3 = Fling2EfficientCore.Running and currentTheme.accent or currentTheme.tertiary
		statusLabel.Text = message or ((Fling2Core.Running or Fling2EfficientCore.Running) and L.flingActive or L.flingStopped)
	end

	local function RefreshTargets()
		for _, child in ipairs(targetList:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		for _, targetPlayer in ipairs(Fling2Core.Provider:GetTargetOptions()) do
			local option = Instance.new("TextButton")
			option.Size = UDim2.new(1, -4, 0, 34)
			option.BackgroundColor3 = currentTheme.secondary
			option.Text = targetPlayer.DisplayName .. "  (@" .. targetPlayer.Name .. ")"
			option.TextColor3 = currentTheme.text
			option.Font = Enum.Font.GothamMedium
			option.TextSize = isMobile and 11 or 12
			option.ZIndex = 31
			option.Parent = targetList
			Instance.new("UICorner", option).CornerRadius = UDim.new(0, 8)
			RegisterTheme(option, "BackgroundColor3", "secondary")
			RegisterTheme(option, "TextColor3", "text")
			option.MouseButton1Click:Connect(function()
				Fling2Core:SetTarget(targetPlayer)
				Fling2EfficientCore:SetTarget(targetPlayer)
				targetList.Visible = false
				UpdateFling2Panel()
			end)
		end
	end

	targetButton.MouseButton1Click:Connect(function()
		targetList.Visible = not targetList.Visible
		if targetList.Visible then RefreshTargets() end
	end)

	flingButton.MouseButton1Click:Connect(function()
		if Fling2Core.Running then
			Fling2Core:Stop()
			UpdateFling2Panel()
			return
		end
		if not Fling2Core:GetTarget() then
			UpdateFling2Panel(L.selectPlayerFirst)
			return
		end
		local ok, err = Fling2Core:Start()
		UpdateFling2Panel(ok and nil or (err or L.flingStartFailed))
	end)

	efficientButton.MouseButton1Click:Connect(function()
		if Fling2EfficientCore.Running then
			Fling2EfficientCore:Stop()
		else
			if not Fling2EfficientCore:GetTarget() then UpdateFling2Panel(L.selectPlayerFirst); return end
			local ok, err = Fling2EfficientCore:Start()
			if not ok then UpdateFling2Panel(err or L.flingStartFailed); return end
		end
		UpdateFling2Panel()
	end)

	UpdateFling2Panel()
	return true
end```

## Registro necesario en `modules/manifest.lua`

El orden de carga incluye:

```lua
"player/fling2_efficient",
```

Los nombres compartidos correspondientes son:

```lua
"Fling2EfficientCore",
"_fling2EfficientPlayerRemovingConn",
"_fling2EfficientCharacterAddedConn",
```

## Limpieza al cerrar

```lua
pcall(function() if Fling2EfficientCore then Fling2EfficientCore:Stop() end end)
pcall(function() if _fling2EfficientPlayerRemovingConn then _fling2EfficientPlayerRemovingConn:Disconnect() end end)
pcall(function() if _fling2EfficientCharacterAddedConn then _fling2EfficientCharacterAddedConn:Disconnect() end end)
```

## Archivos de la implementación

- `modules/player/fling2_efficient.lua`: motor físico.
- `modules/ui/fling2.lua`: selector, estado y botones.
- `modules/manifest.lua`: carga y variables compartidas.
- `modules/ui/window_controls.lua`: limpieza al cerrar.

## Nota

Esta es una reproducción experimental basada en observaciones y pruebas, no el código fuente de VR7 ORIGINAL. Los desplazamientos FAR pueden comportarse de forma diferente según FPS, latencia, propiedad de red y físicas del juego.