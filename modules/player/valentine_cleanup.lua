-- Independent ValentineBalloon cleanup, adapted from the supplied Ultra Fast V1.
return function(context)
 setfenv(1,context)
 local LP=game:GetService("Players").LocalPlayer
 local RS=game:GetService("ReplicatedStorage")
 local RunService=game:GetService("RunService")
 local Core={Enabled=false,Releases=0,Clears=0,Completed=0,LastError=nil}
 local alive=true
 local persistent,rigConnections,backpackConnections,folderConnections={},{},{},{}
 local observed,releaseTimes,tracked,waiting={},{},{},{}
 local character,backpack,folder,operation
 local lastBackup,clearLast=0,-math.huge
 local TARGET="ValentineBalloon"
 local function disconnect(list)for _,c in ipairs(list)do c:Disconnect()end;table.clear(list)end
 local function active()return alive and Core.Enabled and (game.GameId==4540138978 or game.PlaceId==12985361032)end
 local function remotes()
  local r=RS:FindFirstChild("Remotes")
  local release=r and r:FindFirstChild("ReleaseObjectRE")
  local clear=r and r:FindFirstChild("ClearToolRE")
  if release and clear and release:IsA("RemoteEvent") and clear:IsA("RemoteEvent")then return release,clear end
  Core.LastError="ReleaseObjectRE/ClearToolRE no disponibles."
 end
 local function isTool(tool)return tool and tool:IsA("Tool") and tool.Name==TARGET end
 local function belongs(part)return part and character and part:IsDescendantOf(character)end
 local function attached(object)
  local reference=object:FindFirstChild("AttachParentObject")
  if reference and reference:IsA("ObjectValue") and belongs(reference.Value)then return true end
  local weld=object:FindFirstChild("weld2target")
  return weld and weld:IsA("WeldConstraint") and (belongs(weld.Part0) or belongs(weld.Part1))
 end
 local function releaseBalloon(object)
  if not active() or not object.Parent or object:GetAttribute("ToolId")~=TARGET or not attached(object)then return end
  -- Pickup can auto-equip on the server: do not interrupt an active clear cycle.
  if CleanupToolGate.Owner then return end
  local now=os.clock()
  if releaseTimes[object] and now-releaseTimes[object]<.25 then return end
  local release=remotes();if not release then return end
  releaseTimes[object]=now;tracked[object]=tracked[object] or now
  Core.Releases=Core.Releases+1
  local ok,err=pcall(function()release:FireServer("InteractWithObject",{object=object})end)
  Core.LastError=not ok and tostring(err) or nil
 end
 local function clearBalloon(tool)
  if not active() or not isTool(tool) or operation or not character then return end
  local inCharacter=tool.Parent==character
  -- Only recover a Backpack tool if it was displaced during contention.
  if not inCharacter and not (waiting[tool] and tool.Parent==backpack)then return end
  if os.clock()-clearLast<.25 then return end
  local _,clear=remotes();if not clear then return end
  local token=CleanupToolGate:Acquire(Core)
  if not token then waiting[tool]=true;return end
  local captured=character
  if not inCharacter then
   local humanoid=captured:FindFirstChildOfClass("Humanoid")
   if humanoid then pcall(function()humanoid:EquipTool(tool)end)end
  end
  if not active() or character~=captured or not CleanupToolGate:IsEquipped(tool,captured)then
   waiting[tool]=true;CleanupToolGate:Release(token);return
  end
  operation={token=token,tool=tool,character=captured,started=os.clock()}
  waiting[tool]=nil;clearLast=os.clock();Core.Clears=Core.Clears+1
  local ok,err=pcall(function()clear:FireServer(true)end)
  if not ok then Core.LastError=tostring(err);CleanupToolGate:Release(token);operation=nil end
 end
 local function updateOperation()
  if not operation then return end
  local tool=operation.tool
  if tool.Parent and tool.Parent~=operation.character then waiting[tool]=true end
  if not active() or operation.character~=character or tool.Parent~=operation.character or os.clock()-operation.started>=1.5 then
   CleanupToolGate:Release(operation.token);operation=nil
  end
 end
 local function unwatchObjects()
  for _,entry in pairs(observed)do disconnect(entry)end
  table.clear(observed);table.clear(releaseTimes)
 end
 local function observe(object)
  if observed[object]then return end
  local list={};observed[object]=list
  local function attempt()releaseBalloon(object)end
  local linked={}
  local function watchLink(child)
   if linked[child]then return end
   if child:IsA("ObjectValue")then
    linked[child]=true;table.insert(list,child:GetPropertyChangedSignal("Value"):Connect(attempt))
    table.insert(list,child:GetPropertyChangedSignal("Name"):Connect(attempt))
   elseif child:IsA("WeldConstraint")then
    linked[child]=true
    for _,property in ipairs({"Part0","Part1","Name"})do table.insert(list,child:GetPropertyChangedSignal(property):Connect(attempt))end
   end
  end
  table.insert(list,object:GetAttributeChangedSignal("ToolId"):Connect(attempt))
  table.insert(list,object.ChildAdded:Connect(function(child)watchLink(child);attempt()end))
  for _,child in ipairs(object:GetChildren())do watchLink(child)end
  attempt()
 end
 local function bindCharacter(value)
  if operation then CleanupToolGate:Release(operation.token);operation=nil end
  disconnect(rigConnections);table.clear(waiting);character=value
  if value then
   table.insert(rigConnections,value.ChildAdded:Connect(function(child)if active()then clearBalloon(child)end end))
   for _,child in ipairs(value:GetChildren())do clearBalloon(child)end
  end
 end
 local function bindBackpack(value)
  disconnect(backpackConnections);backpack=value
  -- V1 does not automatically equip ordinary Balloon tools from the Backpack.
  if value then table.insert(backpackConnections,value.ChildAdded:Connect(function(child)
   if active() and waiting[child]then clearBalloon(child)end
  end))end
 end
 local function bindFolder(value)
  disconnect(folderConnections);unwatchObjects();folder=value
  if not value then return end
  table.insert(folderConnections,value.ChildAdded:Connect(observe))
  table.insert(folderConnections,value.ChildRemoved:Connect(function(object)
   local entry=observed[object];if entry then disconnect(entry);observed[object]=nil end
   releaseTimes[object]=nil
  end))
  for _,object in ipairs(value:GetChildren())do observe(object)end
 end
 local function bindContainers()
  if character~=LP.Character then bindCharacter(LP.Character)end
  local bp=LP:FindFirstChildOfClass("Backpack");if backpack~=bp then bindBackpack(bp)end
  local f=workspace:FindFirstChild("ObjectPlaceFolder");if folder~=f then bindFolder(f)end
 end
 function Core:SetEnabled(value)
  if value and not (game.GameId==4540138978 or game.PlaceId==12985361032)then return false end
  self.Enabled=value==true
  if self.Enabled then
   bindContainers()
   if folder then for _,object in ipairs(folder:GetChildren())do releaseBalloon(object)end end
   if character then for _,tool in ipairs(character:GetChildren())do clearBalloon(tool)end end
  else
   updateOperation();disconnect(rigConnections);disconnect(backpackConnections);disconnect(folderConnections);unwatchObjects()
   character=nil;backpack=nil;folder=nil;table.clear(waiting);table.clear(tracked)
  end
  return true
 end
 function Core:Destroy()
  self:SetEnabled(false);alive=false;disconnect(persistent)
 end
 table.insert(persistent,LP.CharacterAdded:Connect(function(value)if active()then bindCharacter(value)end end))
 table.insert(persistent,LP.ChildAdded:Connect(function(value)if active() and value:IsA("Backpack")then bindBackpack(value)end end))
 table.insert(persistent,workspace.ChildAdded:Connect(function(value)if active() and value.Name=="ObjectPlaceFolder"then bindFolder(value)end end))
 table.insert(persistent,RunService.Heartbeat:Connect(function()
  updateOperation()
  if not active()then return end
  local now=os.clock();if now-lastBackup<.05 then return end;lastBackup=now
  bindContainers()
  if folder then for _,object in ipairs(folder:GetChildren())do releaseBalloon(object)end end
  if character then for _,tool in ipairs(character:GetChildren())do if isTool(tool)then clearBalloon(tool)end end end
  for tool in pairs(waiting)do if tool.Parent then clearBalloon(tool)else waiting[tool]=nil end end
  for object,time in pairs(tracked)do
   if not object.Parent then
    Core.Completed=Core.Completed+1;Core.LastRemovalMilliseconds=(now-time)*1000;tracked[object]=nil
   end
  end
 end))
 ValentineCleanupCore=Core
 return true
end
