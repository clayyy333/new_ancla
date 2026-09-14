-- Rastrea SetupBuildTool y su contenedor fisico temporal mediante eventos.
return function(context)
	setfenv(1, context)
	local Tracker = {Records = {}, Connections = {}, Running = true}
	local detected = Instance.new("BindableEvent")
	local rootDetected = Instance.new("BindableEvent")
	local helperDetected = Instance.new("BindableEvent")
	local equipped = Instance.new("BindableEvent")
	Tracker.OnToolDetected = detected.Event
	Tracker.OnObjectRootDetected = rootDetected.Event
	Tracker.OnLocalToolHelperDetected = helperDetected.Event
	Tracker.OnToolEquipped = equipped.Event

	local function physicalPart(container)
		if not container or not container.Parent then return nil end
		if container:IsA("BasePart") then return container end
		if container:IsA("Model") and container.PrimaryPart then return container.PrimaryPart end
		local handle = container:FindFirstChild("Handle", true)
		if handle and handle:IsA("BasePart") then return handle end
		for _, item in ipairs(container:GetDescendants()) do if item:IsA("BasePart") and not item.Anchored then return item end end
		for _, item in ipairs(container:GetDescendants()) do if item:IsA("BasePart") then return item end end
	end
	local function looksLikeRoot(tool, child)
		if not child or child.Parent ~= tool then return false end
		if child.Name == "Object" or child.Name == tool.Name .. "_Object" or child.Name:sub(-7) == "_Object" then return true end
		if not (child:IsA("Model") or child:IsA("Folder")) then return false end
		return child:FindFirstChild("Area", true) ~= nil or child:FindFirstChild("SetupFrom", true) ~= nil or child:FindFirstChild("ColorObject", true) ~= nil or child:FindFirstChild("SeatInteract", true) ~= nil or child:FindFirstChild("Handle", true) ~= nil
	end
	local function inspect(record)
		local tool = record.Tool
		if not tool then return end
		local helper = tool:FindFirstChild("LocalToolHelper", true)
		if helper and helper ~= record.LocalToolHelper then record.LocalToolHelper = helper; helperDetected:Fire(tool, helper) end
		local preferred = tool:FindFirstChild("Object") or tool:FindFirstChild(tool.Name .. "_Object")
		if preferred and preferred ~= record.ObjectRoot then record.ObjectRoot, record.ObjectRootName = preferred, preferred.Name; rootDetected:Fire(tool, preferred); return end
		for _, child in ipairs(tool:GetChildren()) do
			if looksLikeRoot(tool, child) and child ~= record.ObjectRoot then record.ObjectRoot, record.ObjectRootName = child, child.Name; rootDetected:Fire(tool, child); return end
		end
	end
	local function register(tool)
		if not Tracker.Running or not tool:IsA("Tool") then return end
		local record = Tracker.Records[tool]
		if record then inspect(record); return record end
		local backpack = player:FindFirstChildOfClass("Backpack")
		record = {Tool=tool, ToolName=tool.Name, Attributes=tool:GetAttributes(), CurrentParent=tool.Parent, SeenInBackpack=backpack and tool.Parent==backpack or false, Equipped=tool.Parent==player.Character, Connections={}}
		Tracker.Records[tool] = record
		table.insert(record.Connections, tool.ChildAdded:Connect(function() task.defer(inspect, record) end))
		table.insert(record.Connections, tool.DescendantAdded:Connect(function() task.defer(inspect, record) end))
		table.insert(record.Connections, tool.AncestryChanged:Connect(function(_, parent)
			record.CurrentParent = parent
			local currentBackpack = player:FindFirstChildOfClass("Backpack")
			if currentBackpack and parent == currentBackpack then record.SeenInBackpack = true end
			local nowEquipped = parent == player.Character
			if nowEquipped and not record.Equipped then equipped:Fire(tool, record) end
			record.Equipped = nowEquipped
		end))
		inspect(record); detected:Fire(tool, record); return record
	end
	function Tracker:GetRecord(tool) return self.Records[tool] end
	function Tracker:GetActiveTools()
		local result = {}; local backpack = player:FindFirstChildOfClass("Backpack")
		if not backpack then return result end
		local seen = {}
		for _, object in ipairs(backpack:GetChildren()) do result[#result+1] = object; seen[object] = true end
		local character = player.Character
		if character then
			for _, object in ipairs(character:GetChildren()) do
				local record = self.Records[object]
				if not seen[object] and object:IsA("Tool") and ((record and record.SeenInBackpack) or object:GetAttribute("ExtraType") == "SetupBuildTool") then
					result[#result+1] = object
				end
			end
		end
		table.sort(result, function(a,b) return a.Name:lower() < b.Name:lower() end)
		return result
	end
	function Tracker:GetPhysicalRoot(tool)
		local record = self.Records[tool] or register(tool)
		if not record then return nil end
		inspect(record); return physicalPart(record.ObjectRoot) or physicalPart(tool)
	end
	function Tracker:Stop()
		if not self.Running then return end; self.Running = false
		for _, connection in ipairs(self.Connections) do connection:Disconnect() end
		for _, record in pairs(self.Records) do for _, connection in ipairs(record.Connections) do connection:Disconnect() end end
		detected:Destroy(); rootDetected:Destroy(); helperDetected:Destroy(); equipped:Destroy()
	end
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
	if backpack then for _, child in ipairs(backpack:GetChildren()) do register(child) end; table.insert(Tracker.Connections, backpack.ChildAdded:Connect(register)) end
	table.insert(Tracker.Connections, player.CharacterAdded:Connect(function(character) table.insert(Tracker.Connections, character.ChildAdded:Connect(register)) end))
	if player.Character then table.insert(Tracker.Connections, player.Character.ChildAdded:Connect(register)) end
	ToolTracker = Tracker
	return true
end