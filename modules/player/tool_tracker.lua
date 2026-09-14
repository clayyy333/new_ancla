-- Relaciona SetupBuildTool con el objeto persistente colocado en Workspace.
return function(context)
	setfenv(1, context)
	local RunService = game:GetService("RunService")
	local Tracker = {Records={}, Connections={}, Placed={}, Running=true, LastError=nil, StableDelay=0.5}
	local detected, rootDetected, helperDetected, equipped = Instance.new("BindableEvent"), Instance.new("BindableEvent"), Instance.new("BindableEvent"), Instance.new("BindableEvent")
	Tracker.OnToolDetected, Tracker.OnObjectRootDetected = detected.Event, rootDetected.Event
	Tracker.OnLocalToolHelperDetected, Tracker.OnToolEquipped = helperDetected.Event, equipped.Event

	local function readMeta(object, key)
		local value = object:GetAttribute(key)
		if value ~= nil then return value end
		local holder = object:FindFirstChild(key, true)
		if not holder then return nil end
		if holder:IsA("ObjectValue") then return holder.Value end
		local ok, result = pcall(function() return holder.Value end)
		return ok and result or nil
	end
	local function samePlayer(value)
		if value == player then return true end
		if typeof(value) == "Instance" and value:IsA("Player") then return value == player end
		local text = tostring(value or "")
		return text == tostring(player.UserId) or text == player.Name
	end
	local function belongsToPlayer(object)
		for _, key in ipairs({"Owner","CreatedPlayer","CreatedPlayerName","UserId"}) do
			local value = readMeta(object,key)
			if value ~= nil and samePlayer(value) then return true end
		end
		return object.Parent and object.Parent.Name == "SetupBuild" and object.Name:sub(-(#tostring(player.UserId)+1)) == "_"..tostring(player.UserId)
	end
	local function matchesTool(object, tool)
		local toolName = tool.Name
		if object.Name == toolName.."_"..tostring(player.UserId) or object.Name:sub(1,#toolName+1) == toolName.."_" then return true end
		local objectToolId, toolId = readMeta(object,"ToolId"), tool:GetAttribute("ToolId")
		return objectToolId ~= nil and (tostring(objectToolId) == toolName or (toolId ~= nil and tostring(objectToolId) == tostring(toolId)))
	end
	local function assemblyRoot(object)
		if not object or not object:IsDescendantOf(workspace) then return nil,"El objeto final ya no está en Workspace." end
		local parts={}
		if object:IsA("BasePart") then parts[1]=object else for _,item in ipairs(object:GetDescendants()) do if item:IsA("BasePart") then parts[#parts+1]=item end end end
		if #parts==0 then return nil,"El objeto final no contiene BaseParts persistentes." end
		local area=object:FindFirstChild("Area",true)
		local preferred=(area and area:IsA("BasePart")) and area or parts[1]
		local root=preferred.AssemblyRootPart or preferred
		if root and (root==object or root:IsDescendantOf(object)) then return root end
		for _,part in ipairs(parts) do
			local candidate=part.AssemblyRootPart or part
			if candidate==object or candidate:IsDescendantOf(object) then return candidate end
		end
		return nil,"La raíz física está fuera del objeto; este ensamblaje necesita un flujo independiente."
	end
	local function trackPlaced(object)
		if not object or Tracker.Placed[object] then return end
		Tracker.Placed[object]={Object=object,DetectedAt=os.clock()}
	end
	local function bindFolder(folder)
		if not folder then return end
		for _,object in ipairs(folder:GetChildren()) do trackPlaced(object) end
		table.insert(Tracker.Connections,folder.ChildAdded:Connect(trackPlaced))
	end
	local function register(tool)
		if not Tracker.Running or not tool:IsA("Tool") then return end
		local record=Tracker.Records[tool]
		if record then return record end
		local backpack=player:FindFirstChildOfClass("Backpack")
		record={Tool=tool,ToolName=tool.Name,SeenInBackpack=backpack and tool.Parent==backpack or false,Equipped=tool.Parent==player.Character,Connections={}}
		Tracker.Records[tool]=record
		table.insert(record.Connections,tool.DescendantAdded:Connect(function(item)
			if item.Name=="LocalToolHelper" then record.LocalToolHelper=item; helperDetected:Fire(tool,item) end
		end))
		table.insert(record.Connections,tool.AncestryChanged:Connect(function(_,parent)
			local currentBackpack=player:FindFirstChildOfClass("Backpack"); if currentBackpack and parent==currentBackpack then record.SeenInBackpack=true end
			local now=parent==player.Character; if now and not record.Equipped then equipped:Fire(tool,record) end; record.Equipped=now
		end))
		detected:Fire(tool,record); return record
	end
	function Tracker:GetRecord(tool) return self.Records[tool] end
	function Tracker:GetActiveTools()
		local result,seen={},{}; local backpack=player:FindFirstChildOfClass("Backpack")
		if backpack then for _,object in ipairs(backpack:GetChildren()) do result[#result+1]=object;seen[object]=true end end
		if player.Character then for _,object in ipairs(player.Character:GetChildren()) do local record=self.Records[object]; if not seen[object] and object:IsA("Tool") and ((record and record.SeenInBackpack) or object:GetAttribute("ExtraType")=="SetupBuildTool") then result[#result+1]=object end end end
		table.sort(result,function(a,b)return a.Name:lower()<b.Name:lower()end);return result
	end
	function Tracker:GetPhysicalRoot(tool)
		self.LastError=nil; local record=self.Records[tool] or register(tool)
		if not record then self.LastError="No se pudo registrar el Tool.";return nil end
		for object,placed in pairs(self.Placed) do
			if not object.Parent then self.Placed[object]=nil
			elseif os.clock()-placed.DetectedAt>=self.StableDelay and belongsToPlayer(object) and matchesTool(object,tool) then
				local root,err=assemblyRoot(object)
				if root then record.FinalObject,record.PhysicalRoot=object,root;rootDetected:Fire(tool,object);return root end
				self.LastError=err
			end
		end
		self.LastError=self.LastError or "No apareció un objeto final propio en SetupBuild u ObjectPlaceFolder."
		return nil
	end
	function Tracker:WaitForPhysicalRoot(tool,timeout)
		local deadline=os.clock()+(timeout or 2.5)
		repeat local root=self:GetPhysicalRoot(tool);if root then return root end;RunService.Heartbeat:Wait() until os.clock()>=deadline
		return nil
	end
	function Tracker:Stop()
		if not self.Running then return end;self.Running=false
		for _,c in ipairs(self.Connections)do c:Disconnect()end;for _,r in pairs(self.Records)do for _,c in ipairs(r.Connections)do c:Disconnect()end end
		detected:Destroy();rootDetected:Destroy();helperDetected:Destroy();equipped:Destroy()
	end
	for _,name in ipairs({"SetupBuild","ObjectPlaceFolder"})do bindFolder(workspace:FindFirstChild(name))end
	table.insert(Tracker.Connections,workspace.ChildAdded:Connect(function(child)if child.Name=="SetupBuild" or child.Name=="ObjectPlaceFolder" then bindFolder(child)end end))
	local backpack=player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack",5)
	if backpack then for _,child in ipairs(backpack:GetChildren())do register(child)end;table.insert(Tracker.Connections,backpack.ChildAdded:Connect(register))end
	local function bindCharacter(character)table.insert(Tracker.Connections,character.ChildAdded:Connect(register))end
	if player.Character then bindCharacter(player.Character)end;table.insert(Tracker.Connections,player.CharacterAdded:Connect(bindCharacter))
	ToolTracker=Tracker
	return true
end