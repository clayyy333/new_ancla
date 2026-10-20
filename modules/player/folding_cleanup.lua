-- V16 pickup -> equip -> clear, without its standalone GUI.
-- Only tables welded to local accessories; creator identity correlates pickup tools.
return function(context)
 setfenv(1,context)
 local Players=game:GetService("Players")
 local RS=game:GetService("ReplicatedStorage")
 local RunService=game:GetService("RunService")
 local LP=Players.LocalPlayer
 local Core={Enabled=false,Busy=false,Cycles=0,Attempts=0,LastError=nil}
	function Core:IsAvailable()
	 return game.GameId==4540138978 or game.PlaceId==12985361032
	end
 local TOOL_ID="FoldingTable"
 local pending
 local alive,epoch,accumulator=true,0,0
 local connections,rigConnections,backpackConnections,folderConnections={},{},{},{}
 local boundCharacter,boundBackpack,boundFolder,lastObject,lastAttempt
 lastAttempt=0
 local function disconnect(list)
  for _,connection in ipairs(list) do connection:Disconnect() end
  table.clear(list)
 end
 local function running()return alive and Core.Enabled and Core:IsAvailable() end
 local function remotes()
  local folder=RS:FindFirstChild("Remotes")
  local release=folder and folder:FindFirstChild("ReleaseObjectRE")
  local clear=folder and folder:FindFirstChild("ClearToolRE")
  if release and clear and release:IsA("RemoteEvent") and clear:IsA("RemoteEvent") then return release,clear end
  Core.LastError="ReleaseObjectRE/ClearToolRE no disponibles."
 end
 local function isTable(object)
  if not object or not object.Parent or object:GetAttribute("ToolId")~=TOOL_ID then return false end
  local character=LP.Character
  local link=object:FindFirstChild("weld2target")
  if not character or not link or not (link:IsA("JointInstance") or link:IsA("WeldConstraint")) then return false end
  local a,b=link.Part0,link.Part1
  local attached
  if a and b then
   if a:IsDescendantOf(character) and (b==object or b:IsDescendantOf(object)) then attached=a
   elseif b:IsDescendantOf(character) and (a==object or a:IsDescendantOf(object)) then attached=b end
  end
  local accessory=attached and attached:FindFirstAncestorOfClass("Accessory")
  return accessory~=nil and accessory:IsDescendantOf(character)
 end
 local function isOurTool(tool)
  return pending and tool and tool:IsA("Tool") and tool.Name==TOOL_ID
   and not pending.existing[tool] and tonumber(tool:GetAttribute("CreatedBy"))==pending.creator
 end
 local function findTool()
  for _,container in ipairs({LP.Character or false,LP:FindFirstChildOfClass("Backpack") or false}) do
   if container then for _,item in ipairs(container:GetChildren()) do if isOurTool(item) then return item end end end
  end
 end
 local function processTool(tool)
  if not running() or Core.Busy or not isOurTool(tool) then return end
  local _,clear=remotes();if not clear then return end
  Core.Busy=true
  local cycleEpoch=epoch
  local cyclePending=pending
  task.spawn(function()
   local ok,err=xpcall(function()
    local character=LP.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local function valid()return running() and epoch==cycleEpoch and LP.Character==character end
    if not valid() then return end
    if tool.Parent~=character then pcall(function()humanoid:EquipTool(tool)end) end
    local deadline=os.clock()+1.5
    while valid() and tool.Parent~=character and os.clock()<deadline do RunService.Heartbeat:Wait() end
    if not valid() or tool.Parent~=character then return end
    local fired=pcall(function()clear:FireServer(true)end)
    if not fired then return end
    local timeout=os.clock()+1.5
    while valid() and tool.Parent and os.clock()<timeout do RunService.Heartbeat:Wait() end
    if valid() and not tool.Parent then
     Core.Cycles=Core.Cycles+1
     if pending==cyclePending then pending=nil end
    end
   end,debug.traceback)
   if not ok then Core.LastError=tostring(err) end
   Core.Busy=false
  end)
 end
 local function processTable()
  if not running() or Core.Busy then return end
  local existing=findTool()
  if existing then processTool(existing);return end
  local folder=workspace:FindFirstChild("ObjectPlaceFolder")
  if not folder then return end
  local object
  if pending then
   if isTable(pending.object) then object=pending.object
   elseif os.clock()-pending.started<1.5 then return
   else pending=nil end
  end
  if not object then for _,item in ipairs(folder:GetChildren()) do if isTable(item) then object=item;break end end end
  if not object then return end
  local now=os.clock()
  if object==lastObject and now-lastAttempt<0.15 then return end
  local release=remotes();if not release then return end
  if not pending then
   local creator=tonumber(object:GetAttribute("CreatedPlayer"))
   if not creator or creator<=0 or creator%1~=0 then Core.LastError="Esperando el creador de la mesa conectada.";return end
   local existingTools={}
   for _,container in ipairs({LP.Character or false,LP:FindFirstChildOfClass("Backpack") or false}) do
    if container then for _,item in ipairs(container:GetChildren()) do existingTools[item]=true end end
   end
   pending={object=object,creator=creator,existing=existingTools,started=now}
  end
  lastObject=object;lastAttempt=now;Core.Attempts=Core.Attempts+1
  local ok,err=pcall(function()release:FireServer("InteractWithObject",{object=object})end)
  Core.LastError=not ok and tostring(err) or nil
 end
 local function bindCharacter(character)
  epoch=epoch+1;pending=nil;disconnect(rigConnections);boundCharacter=character
  if character then table.insert(rigConnections,character.ChildAdded:Connect(function(child)
   if running() and isOurTool(child) then task.defer(processTool,child) end
  end)) end
 end
 local function bindBackpack(backpack)
  disconnect(backpackConnections);boundBackpack=backpack
  if backpack then table.insert(backpackConnections,backpack.ChildAdded:Connect(function(child)
   if running() and isOurTool(child) then task.defer(processTool,child) end
  end)) end
 end
 local function bindFolder(folder)
  disconnect(folderConnections);boundFolder=folder
  if folder then table.insert(folderConnections,folder.ChildAdded:Connect(function()
   if running() then task.defer(processTable) end
  end)) end
 end
 local function bindContainers()
  if LP.Character~=boundCharacter then bindCharacter(LP.Character) end
  local backpack=LP:FindFirstChildOfClass("Backpack")
  if backpack~=boundBackpack then bindBackpack(backpack) end
  local folder=workspace:FindFirstChild("ObjectPlaceFolder")
  if folder~=boundFolder then bindFolder(folder) end
 end
 function Core:SetEnabled(value)
	 if value and not self:IsAvailable() then return false,"Disponible únicamente en Metro Life." end
  self.Enabled=value==true;epoch=epoch+1;pending=nil
  if self.Enabled then bindContainers();task.defer(processTable) end
  if FoldingCleanupControls then FoldingCleanupControls:Refresh() end
  return true
 end
 function Core:Destroy()
  self.Enabled=false;alive=false;epoch=epoch+1;pending=nil
  disconnect(connections);disconnect(rigConnections);disconnect(backpackConnections);disconnect(folderConnections)
 end
 local wasRunning=false
 table.insert(connections,RunService.Heartbeat:Connect(function(dt)
  local active=running()
  if wasRunning and not active then epoch=epoch+1 end
  local starting=active and not wasRunning;wasRunning=active
  if not active then accumulator=0;return end
  bindContainers()
  if Core.Busy then return end
  accumulator=accumulator+dt
  if starting or accumulator>=0.05 then accumulator=0;processTable() end
 end))
 FoldingCleanupCore=Core
 return true
end
