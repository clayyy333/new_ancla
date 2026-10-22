-- Independent generic adapter for compatible placed objects attached to the local rig.
-- The existing table/balloon cleaners own their ToolIds and are not modified here.
return function(context)
	setfenv(1,context)
	local LP=game:GetService("Players").LocalPlayer
	local RS=game:GetService("ReplicatedStorage")
	local RunService=game:GetService("RunService")
	local Core={Enabled=false,Attempts=0,Clears=0,Completed=0,LastError=nil}
	GenericAttachedCleanupCore=Core
	local excluded={FoldingTable=true,ValentineBalloon=true}
	local alive,stepping=true,false
	local character,backpack,folder,operation
	local persistent,inventoryConnections,folderConnections={},{},{}
	local observed={}
	local cooldown=setmetatable({},{__mode="k"})
	local step,bindContainers
	local function disconnect(list)for _,connection in ipairs(list)do connection:Disconnect()end;table.clear(list)end
	function Core:IsAvailable()return game.GameId==4540138978 or game.PlaceId==12985361032 end
	local function active()return alive and Core.Enabled and FoldingCleanupCore and FoldingCleanupCore.Enabled and Core:IsAvailable()end
	local function identity(object)
		local id=object:GetAttribute("ToolId")
		local creator=tonumber(object:GetAttribute("CreatedPlayer"))
		if type(id)~="string"or id==""or #id>128 or excluded[id]then return end
		if not creator or creator~=creator or creator==math.huge or creator<=0 or creator%1~=0 then return end
		return id,creator
	end
	local function belongsToCharacter(part)
		return part and character and (part==character or part:IsDescendantOf(character))
	end
	local function belongsToObject(part,object)
		return part and (part==object or part:IsDescendantOf(object))
	end
	local function attached(object)
		local entry=observed[object]
		if not entry or object.Parent~=folder or not character then return false end
		for link in pairs(entry.Links)do
			if link.Parent and link:IsDescendantOf(object)then
				if link.Name=="AttachParentObject"and link:IsA("ObjectValue")then
					if belongsToCharacter(link.Value)then return true end
				elseif link.Name=="weld2target"and (link:IsA("JointInstance")or link:IsA("WeldConstraint"))then
					local a,b=link.Part0,link.Part1
					if (belongsToCharacter(a)and belongsToObject(b,object))or (belongsToCharacter(b)and belongsToObject(a,object))then return true end
				end
			end
		end
		return false
	end
	local function remotes()
		local remotesFolder=RS:FindFirstChild("Remotes")
		local release=remotesFolder and remotesFolder:FindFirstChild("ReleaseObjectRE")
		local clear=remotesFolder and remotesFolder:FindFirstChild("ClearToolRE")
		if release and clear and release:IsA("RemoteEvent")and clear:IsA("RemoteEvent")then return release,clear end
		Core.LastError="El objeto requiere ReleaseObjectRE y ClearToolRE compatibles."
	end
	local function inventory()
		local tools={}
		for _,container in ipairs({character or false,backpack or false})do
			if container then for _,item in ipairs(container:GetChildren())do if item:IsA("Tool")then tools[#tools+1]=item end end end
		end
		return tools
	end
	local function finish(reason,completed)
		local previous=operation
		operation=nil
		if previous then
			CleanupToolGate:Release(previous.Token)
			cooldown[previous.Object]=os.clock()+1
		end
		Core.LastError=reason
		if completed then Core.Completed=Core.Completed+1 end
	end
	local function matches(tool,op)
		return tool:IsA("Tool")and not op.Existing[tool]
			and (tool.Name==op.Id or tool:GetAttribute("ToolId")==op.Id)
			and tonumber(tool:GetAttribute("CreatedBy"))==op.Creator
	end
	local function advance()
		local op=operation
		if not op then return end
		if not active()or character~=op.Character or LP.Character~=op.Character or CleanupToolGate.Owner~=op.Token then finish("Recogida cancelada por cambio de estado.");return end
		local now=os.clock()
		if now>=op.Deadline then finish("Sin confirmacion de recogida/equipado/eliminacion; no se limpian herramientas ajenas.");return end
		if op.Stage=="WAIT_REMOVE"then
			if not op.Tool.Parent then finish(nil,true)end
			return
		end
		local candidates={}
		for _,tool in ipairs(inventory())do if matches(tool,op)then candidates[#candidates+1]=tool end end
		if #candidates>1 then finish("Recogida ambigua: varias herramientas nuevas coinciden.");return end
		if #candidates==0 then return end
		-- Require the placed object to have detached/disappeared, not merely a new Tool.
		if attached(op.Object)then return end
		local tool=candidates[1]
		if tool.Parent~=character then
			local humanoid=character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health<=0 then finish("Personaje no disponible.");return end
			if not op.EquipRequested then
				op.EquipRequested=true
				local ok,err=pcall(function()humanoid:EquipTool(tool)end)
				if not ok then finish(tostring(err));return end
			end
		end
		if not active()or operation~=op or LP.Character~=op.Character then return end
		if not CleanupToolGate:IsEquipped(tool,character)then return end
		local _,clear=remotes();if not clear then return end
		op.Tool=tool;op.Stage="WAIT_REMOVE";op.Deadline=now+1.5
		Core.Clears=Core.Clears+1
		local ok,err=pcall(function()clear:FireServer(true)end)
		if not ok then finish(tostring(err));return end
		if operation==op and not tool.Parent then finish(nil,true)end
	end
	local function beginPickup(object)
		if not active()or operation or not attached(object)then return end
		if cooldown[object]and os.clock()<cooldown[object]then return end
		local id,creator=identity(object);if not id then return end
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health<=0 then return end
		local release=remotes();if not release then return end
		local token=CleanupToolGate:Acquire(Core);if not token then return end
		local existing={};for _,tool in ipairs(inventory())do existing[tool]=true end
		operation={Object=object,Id=id,Creator=creator,Existing=existing,Character=character,Token=token,Stage="WAIT_TOOL",Deadline=os.clock()+2.5}
		Core.Attempts=Core.Attempts+1
		local ok,err=pcall(function()release:FireServer("InteractWithObject",{object=object})end)
		if not ok then finish(tostring(err))end
	end
	step=function()
		if stepping or not active()then return end
		stepping=true
		local ok,err=xpcall(function()
			if operation then advance();return end
			-- Do not occupy the shared inventory while a known cleaner has work.
			if FoldingCleanupCore and FoldingCleanupCore.Busy then return end
			for object in pairs(observed)do
				if excluded[object:GetAttribute("ToolId")]and attached(object)then return end
			end
			for object in pairs(observed)do
				beginPickup(object)
				if operation then advance();break end
			end
		end,debug.traceback)
		stepping=false
		if not ok then finish(tostring(err))end
	end
	local function unobserve(object)
		local entry=observed[object]
		if not entry then return end
		disconnect(entry.Connections)
		for _,list in pairs(entry.Links)do disconnect(list)end
		observed[object]=nil
	end
	local function observe(object)
		if observed[object]then return end
		local entry={Connections={},Links={}};observed[object]=entry
		local function watch(link)
			if entry.Links[link]then return end
			local properties
			if link:IsA("ObjectValue")then properties={"Name","Value"}
			elseif link:IsA("JointInstance")or link:IsA("WeldConstraint")then properties={"Name","Part0","Part1"}end
			if not properties then return end
			local list={};entry.Links[link]=list
			for _,property in ipairs(properties)do list[#list+1]=link:GetPropertyChangedSignal(property):Connect(step)end
		end
		for _,attribute in ipairs({"ToolId","CreatedPlayer"})do entry.Connections[#entry.Connections+1]=object:GetAttributeChangedSignal(attribute):Connect(step)end
		entry.Connections[#entry.Connections+1]=object.DescendantAdded:Connect(function(link)watch(link);step()end)
		entry.Connections[#entry.Connections+1]=object.DescendantRemoving:Connect(function(link)
			local list=entry.Links[link];if list then disconnect(list);entry.Links[link]=nil end
		end)
		for _,link in ipairs(object:GetDescendants())do watch(link)end
	end
	local function clearBindings()
		disconnect(inventoryConnections);disconnect(folderConnections)
		local objects={};for object in pairs(observed)do objects[#objects+1]=object end
		for _,object in ipairs(objects)do unobserve(object)end
	end
	bindContainers=function()
		local nextCharacter=LP.Character
		local nextBackpack=LP:FindFirstChildOfClass("Backpack")
		local nextFolder=workspace:FindFirstChild("ObjectPlaceFolder")
		if character==nextCharacter and backpack==nextBackpack and folder==nextFolder then return end
		if operation then finish("Contenedores cambiados; operacion cancelada.")end
		clearBindings();character=nextCharacter;backpack=nextBackpack;folder=nextFolder
		for _,container in ipairs({character or false,backpack or false})do
			if container then
				inventoryConnections[#inventoryConnections+1]=container.ChildAdded:Connect(step)
				inventoryConnections[#inventoryConnections+1]=container.ChildRemoved:Connect(step)
			end
		end
		if folder then
			folderConnections[#folderConnections+1]=folder.ChildAdded:Connect(function(object)observe(object);step()end)
			folderConnections[#folderConnections+1]=folder.ChildRemoved:Connect(function(object)unobserve(object);step()end)
			for _,object in ipairs(folder:GetChildren())do observe(object)end
		end
	end
	function Core:SetEnabled(value)
		if value and (not alive or not self:IsAvailable())then return false end
		self.Enabled=value==true
		if not self.Enabled then
			if operation then finish("Limpieza generica desactivada.")end
			clearBindings();character=nil;backpack=nil;folder=nil
		else bindContainers();step()end
		return true
	end
	function Core:Destroy()
		self:SetEnabled(false);alive=false;disconnect(persistent)
	end
	local accumulator=0
	persistent[#persistent+1]=RunService.Heartbeat:Connect(function(dt)
		-- Share only the existing opt-in preference; no backend or cleaner internals.
		local desired=alive and FoldingCleanupCore and FoldingCleanupCore.Enabled and Core:IsAvailable()or false
		if desired~=Core.Enabled then Core:SetEnabled(desired)end
		if not active()then accumulator=0;return end
		bindContainers()
		accumulator=accumulator+(tonumber(dt)or 0)
		if accumulator>=0.05 then accumulator=0;step()end
	end)
	return true
end
