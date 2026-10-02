-- Motor Fling personalizable independiente. No modifica los motores existentes.
return function(context)
	setfenv(1, context)

	local LocalPlayer = player
	local CUSTOM_FLING_OWNERS = {
		[11739864999] = "psychoo778",
		[11743514302] = "ksablanca0",
	}
	local function T(es,en) return isES and es or en end
local CONFIG = {
	VERTICAL_DISTANCE = 0.1,
	LINEAR_SPEED = 1000,
	ANGULAR_SPEED = 1000,
	FLINGER_SPEED = 1000,
	FLINGER_VELOCITY = Vector3.new(1000, 1000, 1000),
	MAX_FORCE = Vector3.new(math.huge, math.huge, math.huge),
	P = 1,

	-- Force Target / Recovery
	RECOVERY_DISTANCE = 1,
	NEAR_DISTANCE = 1,
	REQUIRED_NEAR_FRAMES = 4,     -- frames consecutivos cerca para salir de RECOVERY
	MAX_RECOVERY_ATTEMPTS = 40,

	-- Front Flip
	FRONT_FLIP_SPEED = 1,
	NEAR_MIN_TIME = 0.040,
	NEAR_MAX_TIME = 0.085,
	CONTACT_TIME = 0.10,
	DIRECT_RETURN_TOLERANCE = 4,
	FAR_DISTANCES = {4487425, 7554477, 9193601, 11000000, 12572022, 15000000, 17003482, 21098414},
	SHORT_DISTANCE_SCALE = 0.10,
	DISPLACEMENT_DISTANCE = 1000,
}
local LIMITS = {
	VERTICAL_DISTANCE={min=0.1,max=1.5,decimal=true},
	LINEAR_SPEED={min=1,max=900000000}, ANGULAR_SPEED={min=1,max=900000000},
	FLINGER_SPEED={min=1,max=900000000}, P={min=1,max=1250},
	RECOVERY_DISTANCE={min=1,max=80}, NEAR_DISTANCE={min=0.5,max=6,decimal=true},
	CONTACT_TIME={min=0.05,max=0.30,decimal=true},
	FRONT_FLIP_SPEED={min=1,max=60},
	DISPLACEMENT_DISTANCE={min=1,max=2109841},
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
	local ownerName = CUSTOM_FLING_OWNERS[LocalPlayer.UserId]
	self.Authorized = ownerName ~= nil and string.lower(LocalPlayer.Name) == ownerName
	self.Running = false
	self.Stopping = false
	self.StopCycle = 0
	self.Connection = nil
	self.Flinger = nil
	self.AttackerCheckpoint = nil
	self.LastReturnCheckpoint = nil
	self.Direction = 1
	self.SelectedTarget = nil
	self.ShortDisplacementEnabled = false
	self.ContactTimeEnabled = false

	-- Front Flip
	self.FrontFlipEnabled = true
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

function VR7EfficientCore:IsAuthorized()
	return true
end

function VR7EfficientCore:SetTarget(option)
	local resolved = self.Provider:ResolveTarget(option)
	if not self:IsAuthorized() then return false end
	self.SelectedTarget = resolved
	return resolved ~= nil
end

function VR7EfficientCore:GetTarget()
	return self.SelectedTarget
end

function VR7EfficientCore:SetShortDisplacementEnabled(enabled)
	self.ShortDisplacementEnabled = enabled and true or false
end

function VR7EfficientCore:IsShortDisplacementEnabled()
	return self.ShortDisplacementEnabled
end

function VR7EfficientCore:SetContactTimeEnabled(enabled)
	if self.Running or self.Stopping then return false,T("Detén el Fling personalizable para cambiar esta opción.","Stop Custom Fling before changing this option.") end
	if not self:IsAuthorized() then return false,T("Disponible próximamente.","Coming soon.") end
	self.ContactTimeEnabled = enabled and true or false
	return true,self.ContactTimeEnabled
end

function VR7EfficientCore:IsContactTimeEnabled()
	return self.ContactTimeEnabled == true
end

function VR7EfficientCore:GetContactDuration()
	if self.ContactTimeEnabled then return CONFIG.CONTACT_TIME end
	return CONFIG.NEAR_MIN_TIME + math.random() * (CONFIG.NEAR_MAX_TIME - CONFIG.NEAR_MIN_TIME)
end

function VR7EfficientCore:GetParameters()
	local result={}
	for name in pairs(LIMITS) do result[name]=CONFIG[name] end
	return result
end
function VR7EfficientCore:GetParameterLimits()
	local result={}
	for name,limit in pairs(LIMITS) do result[name]={min=limit.min,max=limit.max,decimal=limit.decimal==true} end
	return result
end
function VR7EfficientCore:SetParameter(name,value)
	if self.Running or self.Stopping then return false,T("Detén el Fling personalizable para cambiar valores.","Stop Custom Fling before changing values.") end
	if not self:IsAuthorized() then return false,T("Disponible próximamente.","Coming soon.") end
	local limit=LIMITS[name];value=tonumber(value)
	if not limit or not value then return false,T("Parámetro inválido.","Invalid parameter.") end
	value=math.clamp(value,limit.min,limit.max)
	if name=="NEAR_DISTANCE" then value=value<1 and 0.5 or math.floor(value+0.5)
	elseif name=="CONTACT_TIME" then value=math.floor(value*20+0.5)/20
	elseif not limit.decimal then value=math.floor(value+0.5) end
	CONFIG[name]=value
	if name=="FLINGER_SPEED" then CONFIG.FLINGER_VELOCITY=Vector3.new(value,value,value) end
	return true,value
end
function VR7EfficientCore:ExportSettings()
	return {parameters=self:GetParameters(),contact_time_enabled=self:IsContactTimeEnabled()}
end

function VR7EfficientCore:ApplySettings(profile)
	if self.Running or self.Stopping or type(profile)~="table" or type(profile.parameters)~="table" then return false end
	for name in pairs(LIMITS) do if profile.parameters[name]==nil then return false end end
	for name,value in pairs(profile.parameters) do if LIMITS[name] then self:SetParameter(name,value) end end
	self.ContactTimeEnabled=profile.contact_time_enabled==true
	return true
end

function VR7EfficientCore:ApplyPreset(preset)
	if self.Running or self.Stopping then return false end
	if not self:IsAuthorized() then return false end
	preset=string.upper(tostring(preset or "MINIMUM"))
	if preset~="MINIMUM" and preset~="MEDIUM" and preset~="MAXIMUM" then return false end
	for name,limit in pairs(LIMITS) do
		local value=limit.min
		if preset=="MAXIMUM" then value=limit.max
		elseif preset=="MEDIUM" and name=="NEAR_DISTANCE" then value=3
		elseif preset=="MEDIUM" and name=="CONTACT_TIME" then value=0.15
		elseif preset=="MEDIUM" then
			value=(limit.min+limit.max)/2
			if limit.decimal then value=math.floor(value*10+0.5)/10 else value=math.floor(value+0.5) end
		end
		CONFIG[name]=value
	end
	CONFIG.FLINGER_VELOCITY=Vector3.new(CONFIG.FLINGER_SPEED,CONFIG.FLINGER_SPEED,CONFIG.FLINGER_SPEED)
	return true
end
function VR7EfficientCore:ResetParameters()
	return self:ApplyPreset("MINIMUM")
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
	if not self:IsAuthorized() then return false, T("Disponible próximamente.","Coming soon.") end
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
	if not self.SelectedTarget then
		return false, T("Selecciona un jugador antes de activar el Fling personalizable.","Select a player before enabling Custom Fling.")
	end
	if CarFling and CarFling.Running then CarFling:Stop() end
	if Fling2Core and Fling2Core.Running then Fling2Core:Stop() end
	if Fling2AutoController and Fling2AutoController.Running then Fling2AutoController:Stop() end
	if Fling2EfficientCore and Fling2EfficientCore.Running then Fling2EfficientCore:Stop() end

	local attackerCharacter = self.Provider:GetLocalCharacter()
	local targetCharacter = self.Provider:GetCharacterFromTarget(self.SelectedTarget)

	local attackerHumanoid, attackerRoot = getParts(attackerCharacter)
	local _, targetRoot = getParts(targetCharacter)
	if not targetRoot and not (Fling2AutoController and Fling2AutoController.Running) then
		targetRoot = TargetRootResolver:Resolve(self.SelectedTarget, 1)
	end

	if not attackerRoot then
		return false, T("Tu personaje no está disponible.","Your character is unavailable.")
	end
	if not targetRoot then
		return false, T("El objetivo no tiene personaje cargado.","The target's character is not loaded.")
	end

	self:Disconnect()

	self.AttackerCheckpoint = attackerRoot.CFrame
	self.LastReturnCheckpoint = self.AttackerCheckpoint
	self.Direction = 1
	self.Running = true
	self.State = "NORMAL"
	self.RecoveryConsecutiveNear = 0
	self.LastTargetCFrame = targetRoot.CFrame
	self.DistanceFromTarget = 0
	self.EfficientPhase = "NEAR"
	self.NearUntil = os.clock() + self:GetContactDuration()
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
		if (Fling2Core and Fling2Core.Running) or (Fling2EfficientCore and Fling2EfficientCore.Running) or (Fling2AutoController and Fling2AutoController.Running) then
			self:Stop();return
		end

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
			local far = CONFIG.DISPLACEMENT_DISTANCE
			local sx = math.random(0, 1) == 0 and -1 or 1
			local sz = math.random(0, 1) == 0 and -1 or 1
			currentRoot.CFrame = CFrame.new(currentTargetRoot.Position + Vector3.new(far * sx, far * 0.15 * self.Direction, far * sz))
			currentRoot.AssemblyLinearVelocity = CONFIG.FLINGER_VELOCITY
			self.EfficientPhase = "RETURN_DIRECT"
		elseif self.EfficientPhase == "RETURN_DIRECT" then
			placeNear()
			self.EfficientPhase = "VERIFY_RETURN"
		elseif self.EfficientPhase == "VERIFY_RETURN" then
			if (currentRoot.Position - currentTargetRoot.Position).Magnitude <= CONFIG.NEAR_DISTANCE then
				self.EfficientPhase = "NEAR"
				self.NearUntil = os.clock() + self:GetContactDuration()
			else
				self.ReturnSide = -self.ReturnSide
				self.EfficientPhase = "RETURN_16"
			end
		elseif self.EfficientPhase == "RETURN_16" then
			currentRoot.CFrame = currentTargetRoot.CFrame * CFrame.new(0, CONFIG.VERTICAL_DISTANCE * self.Direction, CONFIG.RECOVERY_DISTANCE * self.ReturnSide)
			self.EfficientPhase = "RETURN_NEAR"
		else
			placeNear()
			self.EfficientPhase = "NEAR"
			self.NearUntil = os.clock() + self:GetContactDuration()
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

function VR7EfficientCore:ForceReturn()
	if self.Running then return false, T("Desactiva Fling personalizable antes de forzar el regreso.","Disable Custom Fling before forcing the return.") end
	if not self:IsAuthorized() then return false, T("Disponible próximamente.","Coming soon.") end
	local checkpoint = self.AttackerCheckpoint or self.LastReturnCheckpoint
	local humanoid, root = getParts(self.Provider:GetLocalCharacter())
	if not checkpoint then return false, T("No hay un checkpoint guardado.","There is no saved checkpoint.") end
	if not root then return false, T("Tu personaje no está disponible.","Your character is unavailable.") end
	local previousAnchored = root.Anchored
	root.Anchored = true
	local holdStarted = os.clock()
	while os.clock() - holdStarted < 0.35 do
		RunService.Heartbeat:Wait()
		if not root.Parent then return false, T("Tu personaje ya no está disponible.","Your character is no longer available.") end
		root.CFrame = checkpoint
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end
	root.CFrame = checkpoint
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.Anchored = previousAnchored
	if humanoid and humanoid.Parent then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
		pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
	end
	return true
end

	CustomFlingCore = VR7EfficientCore.new(Provider)
	if Settings and type(Settings.customFlingSettings)=="table" then CustomFlingCore:ApplySettings(Settings.customFlingSettings) end

	_customFlingPlayerRemovingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
		if CustomFlingCore:GetTarget() == leavingPlayer then
			if CustomFlingCore.Running then CustomFlingCore:Stop() end
			CustomFlingCore:SetTarget(nil)
			if UpdateCustomFlingPanel then UpdateCustomFlingPanel() end
		end
	end)

	_customFlingCharacterAddedConn = LocalPlayer.CharacterAdded:Connect(function()
		if CustomFlingCore.Running then CustomFlingCore:Stop() end
		CustomFlingCore.LastReturnCheckpoint = nil
		if UpdateCustomFlingPanel then UpdateCustomFlingPanel() end
	end)

	return true
end