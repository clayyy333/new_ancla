-- Nucleo Car Fling integrado; no crea una GUI independiente.
return function(context)
	setfenv(1, context)

	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Workspace = game:GetService("Workspace")
	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer then return false end
local CONFIG = {
	VERTICAL_DISTANCE = 1.5,
	LINEAR_SPEED = 900000000,
	ANGULAR_SPEED = 900000000,
	FLINGER_VELOCITY = Vector3.new(900000000, 900000000, 900000000),
	MAX_FORCE = Vector3.new(math.huge, math.huge, math.huge),
	P = 1250,

	NEAR_MIN_TIME = 0.060,
	NEAR_MAX_TIME = 0.100,
	DIRECT_RETURN_TOLERANCE = 4,

	FAR_DISTANCES = {50, 75, 100, 125, 150, 175, 200},

	STOP_STABILIZE_TIME = 2,
}

--------------------------------------------------
-- UTILIDADES CARRO + OWNER (CarSpawnPoints)
--------------------------------------------------

local function findCarRoot(model)
	if not model then return nil end
	if model:IsA("BasePart") then return model end
	if model.PrimaryPart then return model.PrimaryPart end

	local preferred = {
		"Body", "Chassis", "HumanoidRootPart",
		"VehicleSeat", "DriveSeat", "Seat",
		"WheelB", "W",
	}
	for _, name in ipairs(preferred) do
		local p = model:FindFirstChild(name, true)
		if p and p:IsA("BasePart") then return p end
	end

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and not d.Anchored then
			return d
		end
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then return d end
	end
	return nil
end

local function isMyCar(car)
	if not car then return false end
	local spawnPoints = Workspace:FindFirstChild("CarSpawnPoints")
	if not spawnPoints then return false end

	local expected = LocalPlayer.Name .. "_" .. car.Name
	local spawn = spawnPoints:FindFirstChild(expected)
	if not spawn then return false end

	local owner = spawn:FindFirstChild("Owner")
	return owner and owner:IsA("StringValue") and owner.Value == LocalPlayer.Name
end

local function listMyCars()
	local result = {}
	local seen = {}

	local cars = Workspace:FindFirstChild("Cars")
	local spawnPoints = Workspace:FindFirstChild("CarSpawnPoints")
	if not cars or not spawnPoints then
		return result
	end

	local myName = LocalPlayer.Name
	local prefix = myName .. "_"

	for _, spawn in ipairs(spawnPoints:GetChildren()) do
		local owner = spawn:FindFirstChild("Owner")
		if owner and owner:IsA("StringValue") and owner.Value == myName then
			local carName = nil
			if string.sub(spawn.Name, 1, #prefix) == prefix then
				carName = string.sub(spawn.Name, #prefix + 1)
			end

			if carName then
				local car = cars:FindFirstChild(carName)
				if car and not seen[car] and findCarRoot(car) then
					seen[car] = true
					table.insert(result, car)
				end
			end
		end
	end

	table.sort(result, function(a, b)
		return a.Name < b.Name
	end)
	return result
end

local function getPlayerRoot(player)
	if not player then return nil end
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or not root then return nil end
	return root
end

--------------------------------------------------
-- CORE
--------------------------------------------------

local function moveVehicle(model, root, targetCFrame)
	if not model or not root then return end
	local moved = pcall(function()
		if model:IsA("Model") then model:PivotTo(targetCFrame) else root.CFrame = targetCFrame end
	end)
	if not moved then pcall(function() root.CFrame = targetCFrame end) end
	for _, part in ipairs(model:IsA("Model") and model:GetDescendants() or {root}) do
		if part:IsA("BasePart") and not part.Anchored then
			part.AssemblyLinearVelocity = Vector3.new(900000000, 900000000, 900000000)
			part.AssemblyAngularVelocity = Vector3.new(900000000, 900000000, 900000000)
		end
	end
end
local CarFling2XenoCore = {}
CarFling2XenoCore.__index = CarFling2XenoCore

function CarFling2XenoCore.new()
	local self = setmetatable({}, CarFling2XenoCore)
	self.Running = false
	self.Stopping = false
	self.StopCycle = 0
	self.Connection = nil
	self.Flinger = nil
	self.SelectedCar = nil
	self.SelectedPlayer = nil
	self.CarCheckpoint = nil
	self.Direction = 1
	self.EfficientPhase = "IDLE"
	self.NearUntil = 0
	self.ReturnSide = 1
	self.State = "IDLE"
	self.LastDiagnostic = "READY"
	self.LastDiagnosticDetail = ""
	self.LastDiagnosticAt = os.clock()
	self.LastHeartbeatAt = 0
	self.LastCarRoot = nil
	return self
end

function CarFling2XenoCore:SetDiagnostic(code, detail)
	code, detail = tostring(code or "UNKNOWN"), tostring(detail or "")
	if self.LastDiagnostic ~= code or self.LastDiagnosticDetail ~= detail then
		self.LastDiagnostic, self.LastDiagnosticDetail, self.LastDiagnosticAt = code, detail, os.clock()
		warn("[CarFling2XenoDiag] " .. code .. (detail ~= "" and (" | " .. detail) or ""))
	end
end

function CarFling2XenoCore:GetDiagnostic()
	return self.LastDiagnostic or "READY", self.LastDiagnosticDetail or "", self.LastDiagnosticAt or 0
end
function CarFling2XenoCore:SetCar(car)
	self.SelectedCar = car
	return car ~= nil
end

function CarFling2XenoCore:SetPlayer(player)
	self.SelectedPlayer = player
	return player ~= nil
end

function CarFling2XenoCore:GetCar()
	return self.SelectedCar
end

function CarFling2XenoCore:GetPlayer()
	return self.SelectedPlayer
end

function CarFling2XenoCore:DestroyFlinger()
	if self.Flinger then
		pcall(function() self.Flinger:Destroy() end)
		self.Flinger = nil
	end
end

function CarFling2XenoCore:Disconnect()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	self:DestroyFlinger()
end

function CarFling2XenoCore:CreateFlinger(root)
	self:DestroyFlinger()
	if not root then return end
	local bv = Instance.new("BodyVelocity")
	bv.Name = "VR7CarFling2Xenoer"
	bv.P = CONFIG.P
	bv.MaxForce = CONFIG.MAX_FORCE
	bv.Velocity = CONFIG.FLINGER_VELOCITY
	bv.Parent = root
	self.Flinger = bv
end

function CarFling2XenoCore:Start()
	if AutoAnchorCore then
		local anchorOK,anchorErr=AutoAnchorCore:PrepareForFling()
		if not anchorOK then return false,anchorErr end
	end
	if self.Stopping then
		self.StopCycle = self.StopCycle + 1
		self.Stopping = false
	end
	if self.Running then return true end

	local car = self.SelectedCar
	if not car or not car.Parent then
		return false, "Selecciona un carro válido."
	end
	if not isMyCar(car) then
		return false, "Ese carro no es tuyo."
	end

	local carRoot = findCarRoot(car)
	if not carRoot then
		return false, "El carro no tiene pieza usable."
	end

	local targetRoot = getPlayerRoot(self.SelectedPlayer)
	if not targetRoot then
		return false, "Selecciona un jugador con personaje cargado."
	end

	self:Disconnect()

	self.CarCheckpoint = carRoot.CFrame
	self.Direction = 1
	self.Running = true
	self.State = "NORMAL"
	self.EfficientPhase = "NEAR"
	self.NearUntil = os.clock() + CONFIG.NEAR_MIN_TIME
	self.ReturnSide = 1

	local ownerOk, ownerErr = pcall(function()
		carRoot:SetNetworkOwner(LocalPlayer)
	end)
	self:SetDiagnostic(ownerOk and "NETWORK_OWNER_REQUESTED" or "NETWORK_OWNER_DENIED", ownerOk and carRoot:GetFullName() or tostring(ownerErr))
	self.LastCarRoot, self.LastHeartbeatAt = carRoot, os.clock()
	self:CreateFlinger(carRoot)
	self:SetDiagnostic("STARTED", (ownerOk and "NETWORK_OWNER_REQUESTED" or "NETWORK_OWNER_DENIED") .. " | " .. carRoot:GetFullName())

	self.Connection = RunService.Heartbeat:Connect(function()
		if not self.Running then return end
		self.LastHeartbeatAt = os.clock()

		local currentCar = self.SelectedCar
		if not currentCar or not currentCar.Parent then
			self:SetDiagnostic("CAR_REMOVED", currentCar and currentCar.Name or "nil")
			self:Stop()
			return
		end

		local currentCarRoot = findCarRoot(currentCar)
		local currentTargetRoot = getPlayerRoot(self.SelectedPlayer)

		if not currentCarRoot then
			self:SetDiagnostic("CAR_ROOT_MISSING", currentCar:GetFullName())
			self:Stop()
			return
		end

		if not currentTargetRoot then
			self:SetDiagnostic("TARGET_ROOT_MISSING", self.SelectedPlayer and self.SelectedPlayer.Name or "nil")
			return
		end

		if self.LastCarRoot ~= currentCarRoot then
			self:SetDiagnostic("CAR_ROOT_CHANGED", currentCarRoot:GetFullName())
			self.LastCarRoot = currentCarRoot
		end
		if not self.Flinger or self.Flinger.Parent ~= currentCarRoot then
			self:SetDiagnostic("FLINGER_RECREATED", currentCarRoot:GetFullName())
			self:CreateFlinger(currentCarRoot)
		end
		if self.Flinger and self.Flinger.Parent then
			self.Flinger.Velocity = CONFIG.FLINGER_VELOCITY
			self.Flinger.MaxForce = CONFIG.MAX_FORCE
			self.Flinger.P = CONFIG.P
		end

		local function placeNear()
			self.Direction = -self.Direction
			local desired = currentTargetRoot.CFrame * CFrame.new(0, CONFIG.VERTICAL_DISTANCE * self.Direction, 0)
			moveVehicle(currentCar, currentCarRoot, CFrame.new(desired.Position) * currentCarRoot.CFrame.Rotation)
			currentCarRoot.AssemblyLinearVelocity = Vector3.new(0, CONFIG.LINEAR_SPEED * self.Direction, 0)
			currentCarRoot.AssemblyAngularVelocity = Vector3.new(
				CONFIG.ANGULAR_SPEED,
				CONFIG.ANGULAR_SPEED,
				CONFIG.ANGULAR_SPEED
			)
		end

		if self.EfficientPhase == "NEAR" then
			placeNear()
			if os.clock() >= self.NearUntil then
				self.EfficientPhase = "FAR"
			end

		elseif self.EfficientPhase == "FAR" then
			local far = CONFIG.FAR_DISTANCES[math.random(1, #CONFIG.FAR_DISTANCES)]
			local sx = math.random(0, 1) == 0 and -1 or 1
			local sz = math.random(0, 1) == 0 and -1 or 1
			moveVehicle(currentCar, currentCarRoot, CFrame.new(currentTargetRoot.Position + Vector3.new(far * sx, far * 0.15 * self.Direction, far * sz)))
			currentCarRoot.AssemblyLinearVelocity = CONFIG.FLINGER_VELOCITY
			self.EfficientPhase = "RETURN_DIRECT"

		elseif self.EfficientPhase == "RETURN_DIRECT" then
			placeNear()
			self.EfficientPhase = "VERIFY_RETURN"

		elseif self.EfficientPhase == "VERIFY_RETURN" then
			local dist = (currentCarRoot.Position - currentTargetRoot.Position).Magnitude
			if dist <= CONFIG.DIRECT_RETURN_TOLERANCE then
				self.EfficientPhase = "NEAR"
				self.NearUntil = os.clock()
					+ CONFIG.NEAR_MIN_TIME
					+ math.random() * (CONFIG.NEAR_MAX_TIME - CONFIG.NEAR_MIN_TIME)
			else
				self.ReturnSide = -self.ReturnSide
				self.EfficientPhase = "RETURN_16"
			end

		elseif self.EfficientPhase == "RETURN_16" then
			moveVehicle(currentCar, currentCarRoot, currentTargetRoot.CFrame * CFrame.new(0, CONFIG.VERTICAL_DISTANCE * self.Direction, 16 * self.ReturnSide))
			self.EfficientPhase = "RETURN_NEAR"

		else
			placeNear()
			self.EfficientPhase = "NEAR"
			self.NearUntil = os.clock()
				+ CONFIG.NEAR_MIN_TIME
				+ math.random() * (CONFIG.NEAR_MAX_TIME - CONFIG.NEAR_MIN_TIME)
		end
	end)

	return true
end

function CarFling2XenoCore:Stop()
	local wasRunning = self.Running
	if self.Stopping then return wasRunning end

	self.Running = false
	self.State = "IDLE"
	self.Stopping = true
	self.StopCycle = self.StopCycle + 1
	local myStopCycle = self.StopCycle

	self:Disconnect()

	local car = self.SelectedCar
	local root = car and findCarRoot(car)
	local checkpoint = self.CarCheckpoint

	if not root then
		self.Stopping = false
		self.CarCheckpoint = nil
		self.EfficientPhase = "IDLE"
		return wasRunning
	end

	local previousAnchored = root.Anchored

	local function clearAndHold()
		if self.StopCycle ~= myStopCycle then return false end
		if not root or not root.Parent then return false end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		if checkpoint then
			root.CFrame = checkpoint
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		return true
	end

	clearAndHold()
	root.Anchored = true

	local start = os.clock()
	while os.clock() - start < CONFIG.STOP_STABILIZE_TIME do
		RunService.Heartbeat:Wait()
		if self.StopCycle ~= myStopCycle then return wasRunning end
		if not clearAndHold() then break end
	end

	if self.StopCycle ~= myStopCycle then return wasRunning end

	clearAndHold()
	if root and root.Parent then
		root.Anchored = previousAnchored
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	RunService.Heartbeat:Wait()
	if self.StopCycle ~= myStopCycle then return wasRunning end

	if root and root.Parent then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	self.CarCheckpoint = nil
	self.Direction = 1
	self.EfficientPhase = "IDLE"
	self.Stopping = false
	return wasRunning
end

	function CarFling2XenoCore:GetCarOptions()
		return listMyCars()
	end

	CarFling2Xeno = CarFling2XenoCore.new()
	_carFling2XenoPlayerRemovingConn = Players.PlayerRemoving:Connect(function(leaving)
		if CarFling2Xeno:GetPlayer() == leaving then
			if CarFling2Xeno.Running then CarFling2Xeno:Stop() end
			CarFling2Xeno:SetPlayer(nil)
			if UpdateCarFling2Panel then UpdateCarFling2Panel() end
		end
	end)

	local monitorElapsed = 0
	_carFling2XenoMonitorConn = RunService.Heartbeat:Connect(function(dt)
		monitorElapsed = monitorElapsed + dt
		if monitorElapsed < 0.5 then return end
		monitorElapsed = 0
		local car = CarFling2Xeno:GetCar()
		if car and (not car.Parent or not isMyCar(car)) then
			if CarFling2Xeno.Running then CarFling2Xeno:Stop() end
			CarFling2Xeno:SetCar(nil)
			if UpdateCarFling2Panel then UpdateCarFling2Panel() end
		end
	end)

	return true
end