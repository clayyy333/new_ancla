-- Independent copy of the efficient engine for the owner-only motorcycle passenger test.
return function(context)
	setfenv(1, context)

	local LocalPlayer = player
local CONFIG = {
	SHORT_STABILITY_TEST = false, -- Original lateral thrust and rotation restored.
	VERTICAL_DISTANCE = 1.5,
	LINEAR_SPEED = 90000000,
	ANGULAR_SPEED = 90000000,
	FLINGER_VELOCITY = Vector3.new(90000000, 90000000, 90000000),
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
	FAR_DISTANCE = 1000000,
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

local VR7MotoExperimentalCore = {}
VR7MotoExperimentalCore.__index = VR7MotoExperimentalCore

function VR7MotoExperimentalCore.new(provider)
	local self = setmetatable({}, VR7MotoExperimentalCore)
	self.Provider = provider
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
	self.ShortContactTime = 0.05
	self.ShortHomeInterval = 0.05
	self.HomeUntil = 0
	self.ShortTravelTime = 0
	self.ShortTravel = nil
	self.ShortApproachAngle = 0
	self.ShortContactHeight = 1.5
	self.ShortAngleCos = 1
	self.ShortAngleSin = 0
	self.ShortOrbitDistance = 0
	self.ShortOrbitDirection = Vector3.new(1,0,0)
	self.WaitingForTarget = false
	self.WaitingForLocalCharacter = false
	self.CurrentAttackerRoot = nil
	self.CurrentTargetRoot = nil

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

	local owners={[11739864999]="psychoo778",[11743514302]="ksablanca0",[11747901934]="psycho777oo",[11797966007]="psychoop77"}
	function VR7MotoExperimentalCore:IsAuthorized()
		return owners[player.UserId]~=nil and owners[player.UserId]==string.lower(player.Name)
	end
	local function text(es,en) return isES and es or en end
	local function refresh(message) if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel(message) end end
	-- Read-only passenger test, independent from the experimental physics loop.
	function VR7MotoExperimentalCore:StopPassengerMonitor()
		if self.PassengerConnection then self.PassengerConnection:Disconnect();self.PassengerConnection=nil end
		for _,connection in ipairs(self.PassengerObservers or {}) do connection:Disconnect() end
		self.PassengerObservers=nil
		self.PassengerMonitoring=false;self.PassengerState=nil;self.PassengerVehicle=nil;self.PassengerSeat=nil
	end
	function VR7MotoExperimentalCore:StartPassengerMonitor()
		if not self:IsAuthorized() then return false end
		self:StopPassengerMonitor()
		self.PassengerMonitoring=true
		local elapsed=0
		local cachedVehicle, cachedCars
		local dirty=true
		local nextSearch=0
		self.PassengerObservers={}
		local function observe(signal)
			table.insert(self.PassengerObservers,signal:Connect(function() dirty=true end))
		end
		local function inspect()
			local cars=workspace:FindFirstChild("Cars")
			if cars~=cachedCars then
				cachedCars=cars;dirty=true
				if cars then observe(cars.ChildAdded);observe(cars.ChildRemoved) end
			end
			local vehicle=cachedVehicle
			-- Keep the selected vehicle cached. Re-discover periodically for ownership
			-- and DriverId changes, or immediately when Cars adds/removes a vehicle.
			if dirty or os.clock()>=nextSearch or (vehicle and vehicle.Parent~=cars) then
			dirty=false;nextSearch=os.clock()+1
			local candidates={}
			if cars then for _,vehicle in ipairs(cars:GetChildren()) do
				local attribute=vehicle:GetAttribute("VehicleOwner")
				local reference=vehicle:FindFirstChild("VehicleOwner")
				local hasReference=reference and reference:IsA("ObjectValue")
				local attributeMatch=attribute==player.UserId or attribute==tostring(player.UserId)
				local referenceMatch=hasReference and reference.Value==player
				local contradictory=(attribute~=nil and not attributeMatch) or (hasReference and reference.Value~=nil and not referenceMatch)
				if not contradictory and (attributeMatch or referenceMatch) then table.insert(candidates,vehicle) end
			end end
			local driven={}
			for _,vehicle in ipairs(candidates) do
				local driver=vehicle:GetAttribute("DriverId")
				if driver==player.UserId or driver==tostring(player.UserId) then table.insert(driven,vehicle) end
			end
			vehicle=#driven==1 and driven[1] or (#driven==0 and #candidates==1 and candidates[1] or nil)
			cachedVehicle=vehicle
			end
			local state="WAIT_VEHICLE"
			local seat
			if vehicle then
				local mover=vehicle:FindFirstChild("MoverModel")
				local body=mover and mover:FindFirstChild("Body")
				seat=body and body:FindFirstChild("Seat")
				if seat and not (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then seat=nil end
				state=seat and "WAIT_PASSENGER" or "WAIT_SEAT"
				if seat and seat.Occupant then
					local occupant=seat.Occupant
					local account=Players:GetPlayerFromCharacter(occupant.Parent)
					if account and account.UserId==11773278300 then
						state="OCCUPIED"
						local root=account.Character and account.Character:FindFirstChild("HumanoidRootPart")
						local weld=seat:FindFirstChild("SeatWeld")
						if root and weld and weld:IsA("JointInstance") and ((weld.Part0==seat and weld.Part1==root) or (weld.Part1==seat and weld.Part0==root)) then state="CONFIRMED" end
					else state="OTHER_PASSENGER" end
				end
			end
			local changed=state~=self.PassengerState or vehicle~=self.PassengerVehicle or seat~=self.PassengerSeat
			self.PassengerState=state;self.PassengerVehicle=vehicle;self.PassengerSeat=seat
			if changed then refresh() end
		end
		self.PassengerConnection=RunService.Heartbeat:Connect(function(dt)
			elapsed=elapsed+dt;if elapsed<.1 then return end;elapsed=0
			local ok,err=pcall(inspect)
			if not ok then self:StopPassengerMonitor();refresh(tostring(err)) end
		end)
		inspect();return true
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

function VR7MotoExperimentalCore:SetTarget(option)
	if self.Running or self.Stopping then return false end
	if option == nil then self.SelectedTarget=nil;self.Target=nil;return true end
	local resolved = self.Provider:ResolveTarget(option)
	if not resolved or not resolved:IsA("Player") or resolved.UserId ~= 11773278300 then return false end
	self.SelectedTarget = resolved
	self.Target = resolved
	return resolved ~= nil
end

function VR7MotoExperimentalCore:GetTarget()
	return self.SelectedTarget
end

function VR7MotoExperimentalCore:SetShortDisplacementEnabled(enabled)
	self.ShortDisplacementEnabled = enabled and true or false
end

function VR7MotoExperimentalCore:IsShortDisplacementEnabled()
	return self.ShortDisplacementEnabled
end

function VR7MotoExperimentalCore:IsStableShortMode()
	return CONFIG.SHORT_STABILITY_TEST and self.ShortDisplacementEnabled
end

function VR7MotoExperimentalCore:GetFlingerVelocity()
	return self:IsStableShortMode() and Vector3.new(0, CONFIG.FLINGER_VELOCITY.Y, 0) or CONFIG.FLINGER_VELOCITY
end

function VR7MotoExperimentalCore:GetFlingerMaxForce()
	return self:IsStableShortMode() and Vector3.new(0, CONFIG.MAX_FORCE.Y, 0) or CONFIG.MAX_FORCE
end

function VR7MotoExperimentalCore:SetShortContactTime(value)
	value = tonumber(value)
	if not value or value ~= value or math.abs(value) == math.huge then return false end
	self.ShortContactTime = math.clamp(math.floor(value * 20 + 0.5) / 20, 0.05, 0.30)
	return true
end

function VR7MotoExperimentalCore:GetContactDuration(initial)
	if self.ShortDisplacementEnabled then return self.ShortContactTime end
	if initial then return CONFIG.NEAR_MIN_TIME end
	return CONFIG.NEAR_MIN_TIME + math.random() * (CONFIG.NEAR_MAX_TIME - CONFIG.NEAR_MIN_TIME)
end

function VR7MotoExperimentalCore:SetShortHomeInterval(value)
	value = tonumber(value)
	if not value or value ~= value or math.abs(value) == math.huge then return false end
	self.ShortHomeInterval = math.clamp(math.floor(value * 20 + 0.5) / 20, 0.05, 1)
	if self.Running and self.ShortDisplacementEnabled and self.EfficientPhase == "HOME" then
		self.HomeUntil = os.clock() + self.ShortHomeInterval
	end
	return true
end

function VR7MotoExperimentalCore:SetShortTravelTime(value)
	value = tonumber(value)
	if not value or value ~= value or math.abs(value) == math.huge then return false end
	self.ShortTravelTime = math.clamp(math.floor(value * 20 + 0.5) / 20, 0, 2)
	return true
end

function VR7MotoExperimentalCore:SetShortContactHeight(value)
	value = tonumber(value)
	if not value or value ~= value or math.abs(value) == math.huge then return false end
	self.ShortContactHeight = math.clamp(math.floor(value*10+0.5)/10,0,1.5)
	return true
end

function VR7MotoExperimentalCore:GetContactHeight()
	return self.ShortDisplacementEnabled and self.ShortContactHeight or CONFIG.VERTICAL_DISTANCE
end

function VR7MotoExperimentalCore:SetShortApproachAngle(value)
	value = tonumber(value)
	if not value or value ~= value or math.abs(value) == math.huge then return false end
	self.ShortApproachAngle = math.clamp(math.floor(value+0.5),0,90)
	local radians = math.rad(self.ShortApproachAngle)
	self.ShortAngleCos = self.ShortApproachAngle == 90 and 0 or math.cos(radians)
	self.ShortAngleSin = math.sin(radians)
	return true
end

function VR7MotoExperimentalCore:GetShortHome(targetRoot)
	if ExperimentalMotoAutoController and ExperimentalMotoAutoController.Running then return self.AttackerCheckpoint end
	if not targetRoot then return self.AttackerCheckpoint end
	local offset = self.ShortOrbitDirection * (self.ShortOrbitDistance*self.ShortAngleCos)
		+ Vector3.new(0,self.ShortOrbitDistance*self.ShortAngleSin,0)
	return CFrame.new(targetRoot.Position+offset) * self.AttackerCheckpoint.Rotation
end

function VR7MotoExperimentalCore:BeginShortTravel(phase, root)
	self:DestroyFlinger()
	self:DestroyFrontFlip()
	self.EfficientPhase = phase
	self.ShortTravel = {From=root.CFrame,Started=os.clock(),Duration=self.ShortTravelTime}
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

function VR7MotoExperimentalCore:AdvanceShortTravel(root, targetRoot)
	local travel = self.ShortTravel
	if not travel then return false end
	local returning = self.EfficientPhase == "TO_HOME"
	local goal = returning and self:GetShortHome(targetRoot) or
		(CFrame.new((targetRoot.CFrame * CFrame.new(0, self:GetContactHeight() * self.Direction, 0)).Position) * travel.From.Rotation)
	local alpha = travel.Duration == 0 and 1 or math.clamp((os.clock()-travel.Started)/travel.Duration,0,1)
	root.CFrame = travel.From:Lerp(goal,alpha)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	if alpha < 1 then return false end
	self.ShortTravel = nil
	if returning then
		self.EfficientPhase = "HOME"
		self.HomeUntil = os.clock() + self.ShortHomeInterval
		if ExperimentalMotoAutoController and ExperimentalMotoAutoController.Running then ExperimentalMotoAutoController:OnReturned() end
		return false
	end
	self.EfficientPhase = "NEAR"
	self.NearUntil = os.clock() + self:GetContactDuration()
	return true
end

function VR7MotoExperimentalCore:WaitForShortRespawn()
	if self.WaitingForLocalCharacter then return end
	self.WaitingForLocalCharacter = true
	self.CurrentAttackerRoot = nil
	self.ShortTravel = nil
	self:DestroyFlinger()
	self:DestroyFrontFlip()
end

function VR7MotoExperimentalCore:HoldShortHome(root, targetRoot)
	if self.Flinger then self:DestroyFlinger() end
	if self.FrontFlipAngular or self.FrontFlipAttachment then self:DestroyFrontFlip() end
	if self.AttackerCheckpoint then root.CFrame = self:GetShortHome(targetRoot) end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

--------------------------------------------------
-- FRONT FLIP
--------------------------------------------------

function VR7MotoExperimentalCore:DestroyFrontFlip()
	if self.FrontFlipAngular then
		pcall(function() self.FrontFlipAngular:Destroy() end)
		self.FrontFlipAngular = nil
	end
	if self.FrontFlipAttachment then
		pcall(function() self.FrontFlipAttachment:Destroy() end)
		self.FrontFlipAttachment = nil
	end
end

function VR7MotoExperimentalCore:ActivateFrontFlip(root)
	self:DestroyFrontFlip()
	if self:IsStableShortMode() then return end
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

function VR7MotoExperimentalCore:SetFrontFlipEnabled(enabled)
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

function VR7MotoExperimentalCore:EnsureFrontFlip(root)
	if self:IsStableShortMode() then self:DestroyFrontFlip(); return end
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

function VR7MotoExperimentalCore:DestroyFlinger()
	if self.Flinger then
		pcall(function() self.Flinger:Destroy() end)
		self.Flinger = nil
	end
end

function VR7MotoExperimentalCore:Disconnect()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	self:DestroyFlinger()
	self:DestroyFrontFlip()
end

function VR7MotoExperimentalCore:CreateFlinger(root)
	self:DestroyFlinger()
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "VR7VerticalFlinger"
	bodyVelocity.P = CONFIG.P
	bodyVelocity.MaxForce = self:GetFlingerMaxForce()
	bodyVelocity.Velocity = self:GetFlingerVelocity()
	bodyVelocity.Parent = root
	self.Flinger = bodyVelocity
end

--------------------------------------------------
-- FORCE TARGET / RECOVERY
--------------------------------------------------

function VR7MotoExperimentalCore:UpdateLastTarget(currentTargetRoot)
	if currentTargetRoot then
		self.LastTargetCFrame = currentTargetRoot.CFrame
	end
	-- Si desaparece temporalmente, se conserva el último CFrame válido
end

function VR7MotoExperimentalCore:UpdateDistance(currentRoot)
	if currentRoot and self.LastTargetCFrame then
		self.DistanceFromTarget = (currentRoot.Position - self.LastTargetCFrame.Position).Magnitude
	else
		self.DistanceFromTarget = 0
	end
end

function VR7MotoExperimentalCore:GoNearLastTarget(currentRoot)
	if not currentRoot or not self.LastTargetCFrame then
		return
	end
	-- Posición relativa al último target conocido
	local desired = self.LastTargetCFrame * CFrame.new(0, CONFIG.VERTICAL_DISTANCE * self.Direction, 0)
	currentRoot.CFrame = CFrame.new(desired.Position) * currentRoot.CFrame.Rotation
end

function VR7MotoExperimentalCore:IsNearLastTarget(currentRoot)
	if not currentRoot or not self.LastTargetCFrame then
		return false
	end
	return (currentRoot.Position - self.LastTargetCFrame.Position).Magnitude <= CONFIG.NEAR_DISTANCE
end

--------------------------------------------------
-- START / STOP
--------------------------------------------------

function VR7MotoExperimentalCore:Start()
	if not self:IsAuthorized() then return false, "Prueba exclusiva para owners." end
	if not self.SelectedTarget or self.SelectedTarget.UserId ~= 11773278300 then return false, "Selecciona dayzero777 para esta prueba." end
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
	if (CarFling and CarFling.Running) or (Fling2Core and Fling2Core.Running) or (Fling2EfficientCore and Fling2EfficientCore.Running) then
		return false, "Desactiva los otros flings antes de iniciar esta prueba."
	end

	local attackerCharacter = self.Provider:GetLocalCharacter()
	local targetCharacter = self.Provider:GetCharacterFromTarget(self.SelectedTarget)

	local attackerHumanoid, attackerRoot = getParts(attackerCharacter)
	local _, targetRoot = getParts(targetCharacter)
	if not targetRoot and not (ExperimentalMotoAutoController and ExperimentalMotoAutoController.Running) then
		targetRoot = TargetRootResolver:Resolve(self.SelectedTarget, 1)
	end

	if not attackerRoot then
		return false, "Tu personaje no está disponible."
	end
	if not targetRoot then
		return false, "El objetivo no tiene personaje cargado."
	end

	self:Disconnect()

	self.AttackerCheckpoint = attackerRoot.CFrame
	if self.ShortDisplacementEnabled and targetRoot then
		local offset = attackerRoot.Position-targetRoot.Position
		self.ShortOrbitDistance = offset.Magnitude
		local horizontal = Vector3.new(offset.X,0,offset.Z)
		if horizontal.Magnitude<0.001 then
			local look = targetRoot.CFrame.LookVector
			horizontal = Vector3.new(-look.X,0,-look.Z)
		end
		self.ShortOrbitDirection = horizontal.Magnitude>0.001 and horizontal.Unit or Vector3.new(1,0,0)
	end
	self.CurrentAttackerRoot = attackerRoot
	self.WaitingForLocalCharacter = false
	self.LastReturnCheckpoint = self.AttackerCheckpoint
	self.LastCheckpoint = self.AttackerCheckpoint
	self.Direction = 1
	self.Running = true
	self.State = "NORMAL"
	self.RecoveryConsecutiveNear = 0
	self.LastTargetCFrame = targetRoot.CFrame
	self.CurrentTargetRoot = targetRoot
	self.WaitingForTarget = false
	self.DistanceFromTarget = 0
	self.EfficientPhase = self.ShortDisplacementEnabled and "HOME" or "NEAR"
	self.ShortTravel = nil
	self.HomeUntil = os.clock() + self.ShortHomeInterval
	self.NearUntil = os.clock() + self:GetContactDuration(true)
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

	self:StartPassengerMonitor()
	self.Connection = RunService.Heartbeat:Connect(function()
		if not self.Running then return end
		local currentHumanoid, currentRoot = getParts(self.Provider:GetLocalCharacter())
		if currentHumanoid and currentRoot and ExperimentalMotoAutoController and ExperimentalMotoAutoController.Running then ExperimentalMotoAutoController:CheckTarget() end
		local _, currentTargetRoot = getParts(self.Provider:GetCharacterFromTarget(self.SelectedTarget))
		if not currentHumanoid or not currentRoot then
			if self.ShortDisplacementEnabled then self:WaitForShortRespawn() else self:Stop() end
			return
		end
		if self.ShortDisplacementEnabled and (self.WaitingForLocalCharacter or self.CurrentAttackerRoot ~= currentRoot) then
			self.WaitingForLocalCharacter = false
			self.CurrentAttackerRoot = currentRoot
			self.ShortTravel = nil
			self.EfficientPhase = "HOME"
			self.HomeUntil = os.clock() + self.ShortHomeInterval
			self.Direction = 1
			self.ReturnSide = 1
			currentHumanoid.PlatformStand = false
			currentHumanoid.AutoRotate = true
			self:HoldShortHome(currentRoot,currentTargetRoot)
		end

		-- Both modes keep the selected Player across target death/respawn.
		do
			if not currentTargetRoot then
				if not self.WaitingForTarget then
					self.WaitingForTarget = true
					self.ShortTravel = nil
					self.CurrentTargetRoot = nil
					self:DestroyFlinger()
					self:DestroyFrontFlip()
				end
				if self.AttackerCheckpoint then currentRoot.CFrame = self.AttackerCheckpoint end
				currentRoot.AssemblyLinearVelocity = Vector3.zero
				currentRoot.AssemblyAngularVelocity = Vector3.zero
				return
			end
			if self.WaitingForTarget or self.CurrentTargetRoot ~= currentTargetRoot then
				self.WaitingForTarget = false
				self.CurrentTargetRoot = currentTargetRoot
				self.EfficientPhase = self.ShortDisplacementEnabled and "HOME" or "NEAR"
				self.ShortTravel = nil
				self.HomeUntil = os.clock() + self.ShortHomeInterval
				self.NearUntil = os.clock() + self:GetContactDuration(true)
				self.Direction = 1
				self.ReturnSide = 1
				if not self.ShortDisplacementEnabled and self.FrontFlipEnabled then self:ActivateFrontFlip(currentRoot) end
			end
		end
		self:UpdateLastTarget(currentTargetRoot)
		-- Check prerequisites before allocating or updating physics actuators.
		if not self.PassengerVehicle or not self.PassengerVehicle.Parent or not self.PassengerSeat or not self.PassengerSeat.Parent then
			self:DestroyFlinger()
			self:DestroyFrontFlip()
			currentRoot.AssemblyLinearVelocity = Vector3.zero
			currentRoot.AssemblyAngularVelocity = Vector3.zero
			self.EfficientPhase = "NEAR"
			return
		end
		if self.ShortDisplacementEnabled and self.EfficientPhase == "HOME" then
			self:HoldShortHome(currentRoot,currentTargetRoot)
			if os.clock() < self.HomeUntil then return end
			self:BeginShortTravel("TO_TARGET",currentRoot)
		end
		if self.ShortDisplacementEnabled and self.ShortTravel then
			if not self:AdvanceShortTravel(currentRoot,currentTargetRoot) then return end
		end
		local function clearTravelPhysics()
			self:DestroyFlinger()
			self:DestroyFrontFlip()
			currentRoot.AssemblyLinearVelocity = Vector3.zero
			currentRoot.AssemblyAngularVelocity = Vector3.zero
		end
		local function travelTo(cframe)
			clearTravelPhysics()
			currentRoot.CFrame = cframe
			currentRoot.AssemblyLinearVelocity = Vector3.zero
			currentRoot.AssemblyAngularVelocity = Vector3.zero
		end
		if self.ShortDisplacementEnabled then self:EnsureFrontFlip(currentRoot) end

		local function placeNear()
			if not self.Flinger or self.Flinger.Parent ~= currentRoot then self:CreateFlinger(currentRoot) end
			self.Flinger.Velocity = self:GetFlingerVelocity()
			self.Flinger.MaxForce = self:GetFlingerMaxForce()
			self.Flinger.P = CONFIG.P
			self:EnsureFrontFlip(currentRoot)
			self.Direction = -self.Direction
			local desired = currentTargetRoot.CFrame * CFrame.new(0, self:GetContactHeight() * self.Direction, 0)
			currentRoot.CFrame = CFrame.new(desired.Position) * currentRoot.CFrame.Rotation
			currentRoot.AssemblyLinearVelocity = Vector3.new(0, CONFIG.LINEAR_SPEED * self.Direction, 0)
			currentRoot.AssemblyAngularVelocity = self:IsStableShortMode() and Vector3.zero or Vector3.new(CONFIG.ANGULAR_SPEED, CONFIG.ANGULAR_SPEED, CONFIG.ANGULAR_SPEED)
		end

		if self.ShortDisplacementEnabled then
			-- Short loop: home -> live target -> contact -> original home, never FAR.
			if os.clock() >= self.NearUntil then
				self:BeginShortTravel("TO_HOME",currentRoot)
				self:AdvanceShortTravel(currentRoot,currentTargetRoot)
			else
				placeNear()
			end
			return
		end

		if self.EfficientPhase == "NEAR" then
			placeNear()
			if self.PassengerState == "CONFIRMED" then
				self.TravelTargetCFrame = currentTargetRoot.CFrame
				clearTravelPhysics()
				self.EfficientPhase = "FAR"
			end
		elseif self.EfficientPhase == "FAR" then
			local reference = self.TravelTargetCFrame or currentTargetRoot.CFrame
			local look = reference.LookVector
			local forward = Vector3.new(look.X, 0, look.Z)
			if forward.Magnitude < 0.001 then forward = Vector3.new(0, 0, -1) end
			travelTo(CFrame.new(reference.Position + forward.Unit * CONFIG.FAR_DISTANCE) * currentRoot.CFrame.Rotation)
			self.EfficientPhase = "RETURN_DIRECT"
		elseif self.EfficientPhase == "RETURN_DIRECT" then
			local reference = self.TravelTargetCFrame or currentTargetRoot.CFrame
			travelTo(CFrame.new((reference * CFrame.new(0, self:GetContactHeight() * self.Direction, 0)).Position) * currentRoot.CFrame.Rotation)
			self.EfficientPhase = "VERIFY_RETURN"
		elseif self.EfficientPhase == "VERIFY_RETURN" then
			clearTravelPhysics()
			local reference = self.TravelTargetCFrame or currentTargetRoot.CFrame
			if (currentRoot.Position - reference.Position).Magnitude <= CONFIG.DIRECT_RETURN_TOLERANCE then
				self.EfficientPhase = "NEAR"
				self.NearUntil = os.clock() + self:GetContactDuration()
			else
				self.ReturnSide = -self.ReturnSide
				self.EfficientPhase = "RETURN_16"
			end
		elseif self.EfficientPhase == "RETURN_16" then
			travelTo((self.TravelTargetCFrame or currentTargetRoot.CFrame) * CFrame.new(0, CONFIG.VERTICAL_DISTANCE * self.Direction, 16 * self.ReturnSide))
			self.EfficientPhase = "RETURN_NEAR"
		else
			local reference = self.TravelTargetCFrame or currentTargetRoot.CFrame
			travelTo(CFrame.new((reference * CFrame.new(0, self:GetContactHeight() * self.Direction, 0)).Position) * currentRoot.CFrame.Rotation)
			self.EfficientPhase = "NEAR"
			self.NearUntil = os.clock() + self:GetContactDuration()
		end
	end)

	return true
end

function VR7MotoExperimentalCore:Stop()
	self:StopPassengerMonitor()
	local wasRunning = self.Running

	-- Si ya existe un Stop estabilizando, no iniciar otro encima.
	if self.Stopping then
		return wasRunning
	end

	self.Running = false
	self.WaitingForTarget = false
	self.WaitingForLocalCharacter = false
	self.CurrentAttackerRoot = nil
	self.ShortTravel = nil
	self.CurrentTargetRoot = nil
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

function VR7MotoExperimentalCore:ForceReturn()
	if self.Running then return false, "Desactiva Fling 2 eficiente antes de forzar el regreso." end
	local checkpoint = self.AttackerCheckpoint or self.LastReturnCheckpoint
	local humanoid, root = getParts(self.Provider:GetLocalCharacter())
	if not checkpoint then return false, "No hay un checkpoint guardado." end
	if not root then return false, "Tu personaje no está disponible." end
	local previousAnchored = root.Anchored
	root.Anchored = true
	local holdStarted = os.clock()
	while os.clock() - holdStarted < 0.35 do
		RunService.Heartbeat:Wait()
		if not root.Parent then return false, "Tu personaje ya no está disponible." end
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

	ExperimentalFlingCore = VR7MotoExperimentalCore.new(Provider)
	ExperimentalFlingCore.LastCheckpoint = nil

	-- Bounded local diagnostics only: never changes physical properties.
	local diagnostic = {rows={},next=1,count=0,elapsed=0,recording=false}
	local function appendDiagnostic(event)
		local core=ExperimentalFlingCore
		local character=LocalPlayer.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local function vector(v)
			return string.format("(%.3f,%.3f,%.3f)",v.X,v.Y,v.Z)
		end
		local row=string.format("t=%.3f event=%s phase=%s running=%s passenger=%s",os.clock(),event,tostring(core.EfficientPhase),tostring(core.Running),tostring(core.PassengerState))
		if root then
			row=row.." pos="..vector(root.Position).." linear="..vector(root.AssemblyLinearVelocity).." angular="..vector(root.AssemblyAngularVelocity).." anchored="..tostring(root.Anchored)
		else row=row.." HRP=missing" end
		if humanoid then row=row.." health="..tostring(humanoid.Health).." state="..humanoid:GetState().Name end
		row=row.." frame="..tostring(diagnostic.frame or 0).." simDt="..tostring(diagnostic.simDt or 0)
		local target=core:GetTarget()
		local targetCharacter=target and core.Provider:GetCharacterFromTarget(target)
		local targetRoot=targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
		local vehicle=core.PassengerVehicle
		local bikeRoot=vehicle and (vehicle:IsA("BasePart") and vehicle or vehicle.PrimaryPart)
		local seat=core.PassengerSeat
		if not bikeRoot and seat and seat:IsA("BasePart") then bikeRoot=seat.AssemblyRootPart or seat end
		local function describePart(label,part)
			if not part or not part.Parent then return " "..label.."=missing" end
			return " "..label.."={pos="..vector(part.Position).." linear="..vector(part.AssemblyLinearVelocity).." angular="..vector(part.AssemblyAngularVelocity).." anchored="..tostring(part.Anchored).."}"
		end
		row=row..describePart("target",targetRoot)..describePart("bike",bikeRoot)
		if root and targetRoot then row=row.." targetDistance="..string.format("%.3f",(root.Position-targetRoot.Position).Magnitude) end
		if root and event=="POST_SIM" and diagnostic.prePosition then
			row=row.." physicsDelta="..vector(root.Position-diagnostic.prePosition)
		end
		local force=core.Flinger
		row=row.." flingerActive="..tostring(force~=nil and force.Parent~=nil)
		if force and force.Parent then row=row.." forceVelocity="..vector(force.Velocity).." maxForce="..vector(force.MaxForce).." P="..tostring(force.P) end
		row=row.." frontFlipActive="..tostring(core.FrontFlipAngular~=nil and core.FrontFlipAngular.Parent~=nil)
		if seat and seat.Parent then
			local occupant=seat.Occupant
			local account=occupant and Players:GetPlayerFromCharacter(occupant.Parent)
			local weld=seat:FindFirstChild("SeatWeld")
			row=row.." seat="..seat:GetFullName().." occupantId="..tostring(account and account.UserId)
			row=row.." seatPartMatches="..tostring(occupant~=nil and occupant.SeatPart==seat)
			if weld and weld:IsA("JointInstance") then
				row=row.." seatWeld0="..(weld.Part0 and weld.Part0:GetFullName() or "nil").." seatWeld1="..(weld.Part1 and weld.Part1:GetFullName() or "nil")
			else row=row.." seatWeld=missing" end
		end
		local driverWeld=vehicle and vehicle:FindFirstChild("WeldToPlayer")
		if driverWeld and (driverWeld:IsA("WeldConstraint") or driverWeld:IsA("JointInstance")) then
			row=row.." driverWeld0="..(driverWeld.Part0 and driverWeld.Part0:GetFullName() or "nil").." driverWeld1="..(driverWeld.Part1 and driverWeld.Part1:GetFullName() or "nil")
		else row=row.." driverWeld=missing" end
		diagnostic.rows[diagnostic.next]=row
		diagnostic.next=diagnostic.next%300+1
		diagnostic.count=math.min(diagnostic.count+1,300)
	end
	function ExperimentalFlingCore:GetDiagnosticReport()
		local rows={"EXPERIMENTAL DIAGNOSTIC V2 | local observations only; server cause unknown", "Samples: "..diagnostic.count.." | bounded to 300 rows; paired PRE_SIM/POST_SIM every 0.05 s or phase change; SAMPLE is Heartbeat, not simulation boundary"}
		local first=diagnostic.count==300 and diagnostic.next or 1
		for offset=0,diagnostic.count-1 do table.insert(rows,diagnostic.rows[(first+offset-1)%300+1]) end
		if diagnostic.incident then
			table.insert(rows,"--- SAVED CHARACTER REMOVAL / RESPAWN ---")
			table.insert(rows,diagnostic.incident)
		end
		return table.concat(rows,"\n")
	end
	local function safeDiagnostic(event) pcall(appendDiagnostic,event) end
	ExperimentalFlingCore.DiagnosticPreConnection=RunService.PreSimulation:Connect(function(dt)
		diagnostic.paired=false
		if not ExperimentalFlingCore.Running then return end
		diagnostic.frame=(diagnostic.frame or 0)+1;diagnostic.simDt=dt
		diagnostic.pairElapsed=(diagnostic.pairElapsed or 0)+dt
		if diagnostic.pairElapsed<.05 and diagnostic.pairPhase==ExperimentalFlingCore.EfficientPhase then return end
		diagnostic.pairElapsed=0;diagnostic.pairPhase=ExperimentalFlingCore.EfficientPhase;diagnostic.paired=true
		local character=LocalPlayer.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		diagnostic.prePosition=root and root.Position;diagnostic.preRoot=root
		safeDiagnostic("PRE_SIM")
	end)
	ExperimentalFlingCore.DiagnosticPostConnection=RunService.PostSimulation:Connect(function()
		if not diagnostic.paired then return end
		diagnostic.paired=false
		local character=LocalPlayer.Character
		if not character or character:FindFirstChild("HumanoidRootPart")~=diagnostic.preRoot then diagnostic.prePosition=nil end
		safeDiagnostic("POST_SIM")
	end)
	ExperimentalFlingCore.DiagnosticConnection=RunService.Heartbeat:Connect(function(dt)
		local core=ExperimentalFlingCore
		if not core.Running then
			if diagnostic.recording then safeDiagnostic("STOP");diagnostic.recording=false end
			return
		end
		if not diagnostic.recording then
			diagnostic.recording=true;diagnostic.elapsed=0
			safeDiagnostic("START")
		end
		diagnostic.elapsed=diagnostic.elapsed+dt
		if diagnostic.elapsed>=.05 or diagnostic.phase~=core.EfficientPhase then
			diagnostic.elapsed=0;diagnostic.phase=core.EfficientPhase;safeDiagnostic("SAMPLE")
		end
	end)
	ExperimentalFlingCore.CharacterRemovingDiagnosticConnection=LocalPlayer.CharacterRemoving:Connect(function()
		if not diagnostic.recording and not ExperimentalFlingCore.Running then return end
		safeDiagnostic("CHARACTER_REMOVING")
		-- Snapshot survives stabilization, respawn and later sampling.
		diagnostic.incident=nil
		diagnostic.incident=ExperimentalFlingCore:GetDiagnosticReport()
	end)
	ExperimentalFlingCore.CharacterAddedDiagnosticConnection=LocalPlayer.CharacterAdded:Connect(function()
		if diagnostic.incident then
			diagnostic.incident=diagnostic.incident..string.format("\nt=%.3f event=CHARACTER_ADDED",os.clock())
		end
	end)

	ExperimentalFlingCore.PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(leavingPlayer)
		if ExperimentalFlingCore:GetTarget() == leavingPlayer then
			if ExperimentalMotoAutoController and ExperimentalMotoAutoController.Running then
				ExperimentalMotoAutoController:SkipMissing(leavingPlayer)
			else
				if ExperimentalFlingCore.Running then ExperimentalFlingCore:Stop() end
				ExperimentalFlingCore:SetTarget(nil)
				if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel() end
			end
		end
	end)

	ExperimentalFlingCore.CharacterAddedConnection = LocalPlayer.CharacterAdded:Connect(function()
		if ExperimentalFlingCore.Running and ExperimentalFlingCore:IsShortDisplacementEnabled() then
			ExperimentalFlingCore:WaitForShortRespawn()
			if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel() end
			return
		end
		if ExperimentalMotoAutoController and ExperimentalMotoAutoController.Running then
			ExperimentalMotoAutoController:Stop()
		elseif ExperimentalFlingCore.Running then
			ExperimentalFlingCore:Stop()
		end
		ExperimentalFlingCore.LastReturnCheckpoint = nil
		if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel() end
	end)

	return true
end
