-- Nucleo Object Fling integrado; no crea una GUI independiente.
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

local resolvedRoots = setmetatable({}, {__mode = "k"})

local function directRoot(object)
	if not object then return nil end
	if object:IsA("BasePart") then return object end
	if object:IsA("Model") and object.PrimaryPart then return object.PrimaryPart end
	local handle = object:FindFirstChild("Handle", true)
	if handle and handle:IsA("BasePart") then return handle end
	for _, descendant in ipairs(object:GetDescendants()) do
		if descendant:IsA("BasePart") and not descendant.Anchored then return descendant end
	end
	for _, descendant in ipairs(object:GetDescendants()) do
		if descendant:IsA("BasePart") then return descendant end
	end
	return nil
end

local function ownerMatches(object)
	for _, attributeName in ipairs({"UserId", "OwnerId", "Owner"}) do
		local value = object and object:GetAttribute(attributeName)
		if value ~= nil then
			local text = tostring(value)
			return text == tostring(LocalPlayer.UserId) or text == LocalPlayer.Name
		end
	end
	local owner = object and object:FindFirstChild("Owner")
	if owner then
		if owner:IsA("ObjectValue") then return owner.Value == LocalPlayer end
		local ok, value = pcall(function() return owner.Value end)
		if ok then
			local text = tostring(value)
			return text == tostring(LocalPlayer.UserId) or text == LocalPlayer.Name
		end
	end
	return nil
end
local function findObjectRoot(object)
	if not object then return nil end
	if ToolTracker then
		local tracked = ToolTracker:GetPhysicalRoot(object)
		if tracked then return tracked end
	end
	local cached = resolvedRoots[object]
	if cached and cached.Parent then return cached end
	local root = directRoot(object)
	if root then resolvedRoots[object] = root; return root end
	if object:IsA("ObjectValue") and typeof(object.Value) == "Instance" then
		root = directRoot(object.Value)
		if root then resolvedRoots[object] = root; return root end
	end
	for _, descendant in ipairs(object:GetDescendants()) do
		if descendant:IsA("ObjectValue") and typeof(descendant.Value) == "Instance" then
			root = directRoot(descendant.Value)
			if root then resolvedRoots[object] = root; return root end
		end
	end
	for _, candidate in ipairs(Workspace:GetDescendants()) do
		if candidate.Name == object.Name and candidate ~= object and ownerMatches(candidate) == true then
			root = directRoot(candidate)
			if root then resolvedRoots[object] = root; return root end
		end
	end
	return nil
end

local function isMyObject(object)
	if not object then return false end
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	local localContainer = (backpack and object.Parent == backpack) or object.Parent == LocalPlayer.Character
	local owned = ownerMatches(object)
	if owned ~= nil then return owned end
	return localContainer
end

local function listMyObjects()
	if ToolTracker then return ToolTracker:GetActiveTools() end
	local result = {}
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if not backpack then return result end
	for _, object in ipairs(backpack:GetChildren()) do
		if isMyObject(object) then table.insert(result, object) end
	end
	table.sort(result, function(a, b) return a.Name:lower() < b.Name:lower() end)
	return result
end

local function prepareObject(object)
	if not isMyObject(object) then return nil end
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if object:IsA("Tool") and backpack and object.Parent == backpack then
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return nil end
		pcall(function() humanoid:EquipTool(object) end)
		RunService.Heartbeat:Wait()
	end
	local root = findObjectRoot(object)
	local character = LocalPlayer.Character
	if root and character then
		for _, joint in ipairs(character:GetDescendants()) do
			local isJoint = joint:IsA("JointInstance") or joint:IsA("WeldConstraint")
			if isJoint then
				local part0, part1 = joint.Part0, joint.Part1
				local other = part0 == root and part1 or (part1 == root and part0 or nil)
				if other and other:IsDescendantOf(character) and not other:IsDescendantOf(object) then
					pcall(function() joint:Destroy() end)
				end
			end
		end
	end
	return root
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
local ObjectFling2XenoCore = {}
ObjectFling2XenoCore.__index = ObjectFling2XenoCore

function ObjectFling2XenoCore.new()
	local self = setmetatable({}, ObjectFling2XenoCore)
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

function ObjectFling2XenoCore:SetDiagnostic(code, detail)
	code, detail = tostring(code or "UNKNOWN"), tostring(detail or "")
	if self.LastDiagnostic ~= code or self.LastDiagnosticDetail ~= detail then
		self.LastDiagnostic, self.LastDiagnosticDetail, self.LastDiagnosticAt = code, detail, os.clock()
		warn("[ObjectFling2XenoDiag] " .. code .. (detail ~= "" and (" | " .. detail) or ""))
	end
end

function ObjectFling2XenoCore:GetDiagnostic()
	return self.LastDiagnostic or "READY", self.LastDiagnosticDetail or "", self.LastDiagnosticAt or 0
end
function ObjectFling2XenoCore:SetCar(car)
	self.SelectedCar = car
	return car ~= nil
end

function ObjectFling2XenoCore:SetPlayer(player)
	self.SelectedPlayer = player
	return player ~= nil
end

function ObjectFling2XenoCore:GetCar()
	return self.SelectedCar
end

function ObjectFling2XenoCore:GetPlayer()
	return self.SelectedPlayer
end

function ObjectFling2XenoCore:DestroyFlinger()
	if self.Flinger then
		pcall(function() self.Flinger:Destroy() end)
		self.Flinger = nil
	end
end

function ObjectFling2XenoCore:Disconnect()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	self:DestroyFlinger()
end

function ObjectFling2XenoCore:CreateFlinger(root)
	self:DestroyFlinger()
	if not root then return end
	local bv = Instance.new("BodyVelocity")
	bv.Name = "VR7ObjectFling2Xenoer"
	bv.P = CONFIG.P
	bv.MaxForce = CONFIG.MAX_FORCE
	bv.Velocity = CONFIG.FLINGER_VELOCITY
	bv.Parent = root
	self.Flinger = bv
end

function ObjectFling2XenoCore:Start()
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
		return false, "Selecciona un objeto válido."
	end
	if not isMyObject(car) then
		return false, "Ese objeto no pertenece a tu Backpack."
	end

	local carRoot = prepareObject(car)
	if not carRoot then
		return false, "El objeto no tiene una pieza física utilizable."
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

		local currentCarRoot = findObjectRoot(currentCar)
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

function ObjectFling2XenoCore:Stop()
	local wasRunning = self.Running
	if self.Stopping then return wasRunning end

	self.Running = false
	self.State = "IDLE"
	self.Stopping = true
	self.StopCycle = self.StopCycle + 1
	local myStopCycle = self.StopCycle

	self:Disconnect()

	local car = self.SelectedCar
	local root = car and findObjectRoot(car)
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
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if car and car:IsA("Tool") and backpack then pcall(function() car.Parent = backpack end) end
	return wasRunning
end

	function ObjectFling2XenoCore:GetCarOptions()
		return listMyObjects()
	end

	ObjectFling2Xeno = ObjectFling2XenoCore.new()
	_objectFling2XenoPlayerRemovingConn = Players.PlayerRemoving:Connect(function(leaving)
		if ObjectFling2Xeno:GetPlayer() == leaving then
			if ObjectFling2Xeno.Running then ObjectFling2Xeno:Stop() end
			ObjectFling2Xeno:SetPlayer(nil)
			if UpdateObjectFlingPanel then UpdateObjectFlingPanel() end
		end
	end)

	local monitorElapsed = 0
	_objectFling2XenoMonitorConn = RunService.Heartbeat:Connect(function(dt)
		monitorElapsed = monitorElapsed + dt
		if monitorElapsed < 0.5 then return end
		monitorElapsed = 0
		local car = ObjectFling2Xeno:GetCar()
		if car and (not car.Parent or not isMyObject(car)) then
			if ObjectFling2Xeno.Running then ObjectFling2Xeno:Stop() end
			ObjectFling2Xeno:SetCar(nil)
			if UpdateObjectFlingPanel then UpdateObjectFlingPanel() end
		end
	end)

	return true
end