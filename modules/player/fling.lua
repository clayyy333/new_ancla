-- Nucleo de Fling integrado. Este modulo no crea ninguna GUI independiente.
return function(context)
	setfenv(1, context)

	local LocalPlayer = player
local CONFIG = {
	VERTICAL_DISTANCE = 3.4,
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

local VR7Core = {}
VR7Core.__index = VR7Core

function VR7Core.new(provider)
	local self = setmetatable({}, VR7Core)
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

function VR7Core:SetTarget(option)
	local resolved = self.Provider:ResolveTarget(option)
	self.SelectedTarget = resolved
	return resolved ~= nil
end

function VR7Core:GetTarget()
	return self.SelectedTarget
end

--------------------------------------------------
-- FRONT FLIP
--------------------------------------------------

function VR7Core:DestroyFrontFlip()
	if self.FrontFlipAngular then
		pcall(function() self.FrontFlipAngular:Destroy() end)
		self.FrontFlipAngular = nil
	end
	if self.FrontFlipAttachment then
		pcall(function() self.FrontFlipAttachment:Destroy() end)
		self.FrontFlipAttachment = nil
	end
end

function VR7Core:ActivateFrontFlip(root)
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

function VR7Core:SetFrontFlipEnabled(enabled)
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

function VR7Core:EnsureFrontFlip(root)
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

function VR7Core:DestroyFlinger()
	if self.Flinger then
		pcall(function() self.Flinger:Destroy() end)
		self.Flinger = nil
	end
end

function VR7Core:Disconnect()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	self:DestroyFlinger()
	self:DestroyFrontFlip()
end

function VR7Core:CreateFlinger(root)
	self:DestroyFlinger()
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "VR7VerticalFlinger"
	bodyVelocity.P = CONFIG.P
	bodyVelocity.MaxForce = CONFIG.MAX_FORCE
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = root
	self.Flinger = bodyVelocity
end

--------------------------------------------------
-- FORCE TARGET / RECOVERY
--------------------------------------------------

function VR7Core:UpdateLastTarget(currentTargetRoot)
	if currentTargetRoot then
		self.LastTargetCFrame = currentTargetRoot.CFrame
	end
	-- Si desaparece temporalmente, se conserva el último CFrame válido
end

function VR7Core:UpdateDistance(currentRoot)
	if currentRoot and self.LastTargetCFrame then
		self.DistanceFromTarget = (currentRoot.Position - self.LastTargetCFrame.Position).Magnitude
	else
		self.DistanceFromTarget = 0
	end
end

function VR7Core:GoNearLastTarget(currentRoot)
	if not currentRoot or not self.LastTargetCFrame then
		return
	end
	-- Posición relativa al último target conocido
	local desired = self.LastTargetCFrame * CFrame.new(0, CONFIG.VERTICAL_DISTANCE * self.Direction, 0)
	currentRoot.CFrame = CFrame.new(desired.Position) * currentRoot.CFrame.Rotation
end

function VR7Core:IsNearLastTarget(currentRoot)
	if not currentRoot or not self.LastTargetCFrame then
		return false
	end
	return (currentRoot.Position - self.LastTargetCFrame.Position).Magnitude <= CONFIG.NEAR_DISTANCE
end

--------------------------------------------------
-- START / STOP
--------------------------------------------------

function VR7Core:Start()
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
	if Fling2Core and Fling2Core.Running then Fling2Core:Stop() end
	if Fling2EfficientCore and Fling2EfficientCore.Running then Fling2EfficientCore:Stop() end

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

		local currentAttacker = self.Provider:GetLocalCharacter()
		local currentTargetChar = self.Provider:GetCharacterFromTarget(self.SelectedTarget)

		local currentHumanoid, currentRoot = getParts(currentAttacker)
		local _, currentTargetRoot = getParts(currentTargetChar)

		if not currentRoot then
			self:Stop()
			return
		end

		------------------------------------------
		-- 1) Actualizar última posición del target
		------------------------------------------
		self:UpdateLastTarget(currentTargetRoot)
		self:UpdateDistance(currentRoot)

		-- Si no hay ninguna referencia válida, no se puede seguir
		if not self.LastTargetCFrame then
			self:Stop()
			return
		end

		------------------------------------------
		-- 2) Detectar separación excesiva → RECOVERY
		------------------------------------------
		if self.State == "NORMAL" and self.DistanceFromTarget > CONFIG.RECOVERY_DISTANCE then
			self.State = "RECOVERY"
			self.RecoveryConsecutiveNear = 0
		end

		------------------------------------------
		-- 3) RECOVERY: volver usando LastTargetCFrame
		------------------------------------------
		if self.State == "RECOVERY" then
			self:GoNearLastTarget(currentRoot)

			-- Mantener flinger / flip
			if self.Flinger and self.Flinger.Parent ~= currentRoot then
				self:CreateFlinger(currentRoot)
			end
			if self.Flinger and self.Flinger.Parent then
				self.Flinger.Velocity = Vector3.new(0, CONFIG.LINEAR_SPEED * self.Direction, 0)
				self.Flinger.MaxForce = CONFIG.MAX_FORCE
				self.Flinger.P = CONFIG.P
			end
			self:EnsureFrontFlip(currentRoot)

			-- Comprobar DESPUÉS de este frame en el próximo Heartbeat
			-- (aquí medimos la distancia ya actualizada)
			self:UpdateDistance(currentRoot)

			if self:IsNearLastTarget(currentRoot) then
				self.RecoveryConsecutiveNear = self.RecoveryConsecutiveNear + 1
			else
				self.RecoveryConsecutiveNear = 0
			end

			if self.RecoveryConsecutiveNear >= CONFIG.REQUIRED_NEAR_FRAMES then
				self.State = "NORMAL"
				self.RecoveryConsecutiveNear = 0
			end

			return -- en recovery no hacemos el fling vertical normal
		end

		------------------------------------------
		-- 4) NORMAL: fling vertical ±3.4
		------------------------------------------
		if not currentTargetRoot then
			-- Target temporalmente ausente: no spamear TP con CFrame viejo en NORMAL;
			-- solo conservar LastTargetCFrame y esperar.
			return
		end

		self.Direction = -self.Direction
		local offsetY = CONFIG.VERTICAL_DISTANCE * self.Direction

		local desired = currentTargetRoot.CFrame * CFrame.new(0, offsetY, 0)
		currentRoot.CFrame = CFrame.new(desired.Position) * currentRoot.CFrame.Rotation

		currentRoot.AssemblyLinearVelocity = Vector3.new(
			0,
			CONFIG.LINEAR_SPEED * self.Direction,
			0
		)

		if not self.FrontFlipEnabled then
			currentRoot.AssemblyAngularVelocity = Vector3.zero
		end

		if self.Flinger and self.Flinger.Parent ~= currentRoot then
			self:CreateFlinger(currentRoot)
		end
		if self.Flinger and self.Flinger.Parent then
			self.Flinger.Velocity = Vector3.new(0, CONFIG.LINEAR_SPEED * self.Direction, 0)
			self.Flinger.MaxForce = CONFIG.MAX_FORCE
			self.Flinger.P = CONFIG.P
		end

		self:EnsureFrontFlip(currentRoot)
	end)

	return true
end

function VR7Core:Stop()
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


	FlingCore = VR7Core.new(Provider)

	_flingPlayerRemovingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
		if FlingCore:GetTarget() == leavingPlayer then
			if FlingCore.Running then FlingCore:Stop() end
			FlingCore:SetTarget(nil)
			if UpdateFlingPanel then UpdateFlingPanel() end
		end
	end)

	_flingCharacterAddedConn = LocalPlayer.CharacterAdded:Connect(function()
		if FlingCore.Running then FlingCore:Stop() end
		if UpdateFlingPanel then UpdateFlingPanel() end
	end)

	return true
end