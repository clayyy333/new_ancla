-- Independent overlap companion: parallel pickup requests, exclusive tool clears.
-- Identical models are attempted too; only observed failures trip queue-only mode.
return function(context)
 setfenv(1,context)
 local LP=game:GetService("Players").LocalPlayer
 local RunService=game:GetService("RunService")
 local RS=game:GetService("ReplicatedStorage")
 local Core={Enabled=false,Overlaps=0,Pending=0,Drains=0,LastError=nil,Pickups=0,Completed=0,Fallbacks=0,QueueOnly=false}
 CleanupBacklogCore=Core
 local alive,queued,draining=true,false,false
 local folder,character
 local connections,watched={},{}
 local burst=false
 local primary,jobs={},{}
 local requestSequence=0
 local toolRecords=setmetatable({},{__mode="k"})
 local function nextRequest()requestSequence=requestSequence+1;return requestSequence end
 local toolOwners=setmetatable({},{__mode="k"})
 local function inventory()
  local out={}
  for _,container in ipairs({LP.Character or false,LP:FindFirstChildOfClass("Backpack")or false})do
   if container then for _,tool in ipairs(container:GetChildren())do if tool:IsA("Tool")then out[#out+1]=tool end end end
  end
  return out
 end
 local function signature(object)
  local id=object:GetAttribute("ToolId")
  local creator=tonumber(object:GetAttribute("CreatedPlayer"))
  if type(id)=="string"and id~=""and creator and creator>0 and creator%1==0 then return id,creator end
 end
 local function matches(tool,job)
  return tool:IsA("Tool")and not job.Existing[tool]
   and(tool.Name==job.Id or tool:GetAttribute("ToolId")==job.Id)
   and tonumber(tool:GetAttribute("CreatedBy"))==job.Creator
 end
 local function snapshot()
  local result={};for _,tool in ipairs(inventory())do result[tool]=true end;return result
 end
 local function fallback(reason)
  if not Core.QueueOnly then Core.Fallbacks=Core.Fallbacks+1 end
  Core.QueueOnly=true;Core.LastError=reason
 end
 function Core:IsReserved(object)return jobs[object]~=nil end
 function Core:RegisterPrimary(object)
  if not alive or not FoldingCleanupCore or not FoldingCleanupCore.Enabled then return true end
  if jobs[object]then return false end
  local id,creator=signature(object)
  if id then
   local record=primary[object]
   if not record then primary[object]={Id=id,Creator=creator,Existing=snapshot(),Started=os.clock(),RequestOrder=nextRequest()}
   else record.Started=os.clock()end
  end
  return true
 end
 function Core:OwnsTool(tool)
  if not tool or not tool:IsA("Tool")then return false end
  local assigned=toolRecords[tool]
  if not assigned then
   local oldest
   -- Best-effort allocation by request/arrival order, NOT by name alone.
   -- A Tool instance is assigned once across both original and companion requests.
   for _,records in ipairs({primary,jobs})do
    for _,record in pairs(records)do
     if not record.Tool and matches(tool,record)
      and(not oldest or record.RequestOrder<oldest.RequestOrder)then oldest=record end
    end
   end
   if oldest then
    oldest.Tool=tool;toolRecords[tool]=oldest;assigned=oldest
    if oldest.Supplement then toolOwners[tool]=oldest end
   end
  end
  return assigned and assigned.Supplement==true or false
 end
 local function dropJob(object,job)
  if job.Token then CleanupToolGate:Release(job.Token)end
  if job.Tool then toolOwners[job.Tool]=nil;toolRecords[job.Tool]=nil end
  jobs[object]=nil
 end
 local function prunePrimary()
  local busy=false
  for _,tool in ipairs(inventory())do Core:OwnsTool(tool)end
  for object,record in pairs(primary)do
   if (record.Tool and not record.Tool.Parent)or os.clock()-record.Started>4 then primary[object]=nil
   else busy=true end
  end
  return busy
 end
 local function advanceJobs()
  local now=os.clock()
  for _,tool in ipairs(inventory())do Core:OwnsTool(tool)end
  for object,job in pairs(jobs)do
   if job.Character~=LP.Character then dropJob(object,job)
   else
    if jobs[object]==job then
     if job.Tool and not job.Tool.Parent then
      Core.Completed=Core.Completed+1;dropJob(object,job)
     elseif job.Stage=="CLEAR"then
      if now>=job.Deadline then
       fallback("Eliminacion sin confirmar: reintento en cola.")
       if job.Token then CleanupToolGate:Release(job.Token);job.Token=nil end
       job.Stage="RECOVER";job.Deadline=now+2.5
      end
     elseif job.Tool and not CleanupAttachmentDetector:IsAttached(object,job.Character)and not CleanupToolGate.Owner then
      local token=CleanupToolGate:Acquire(Core)
      if token then
       job.Token=token
       local hum=job.Character:FindFirstChildOfClass("Humanoid")
       local remotes=RS:FindFirstChild("Remotes")
       local clear=remotes and remotes:FindFirstChild("ClearToolRE")
       if hum and hum.Health>0 and clear and clear:IsA("RemoteEvent")then
        local ok,err=pcall(function()
         if job.Tool.Parent~=job.Character then hum:EquipTool(job.Tool)end
         if not CleanupToolGate:IsEquipped(job.Tool,job.Character)then error("Equipado no confirmado")end
         job.Stage="CLEAR";job.Deadline=now+1.5
         clear:FireServer(true)
        end)
        if not ok then
         fallback(tostring(err));CleanupToolGate:Release(token);job.Token=nil;job.Stage="RECOVER"
        end
       else fallback("Personaje o remoto no disponible");CleanupToolGate:Release(token);job.Token=nil end
      end
     elseif job.Tool and CleanupToolGate.Owner then
      -- A received tool remains owned while the preceding clear finishes.
      job.Deadline=now+2.5
     elseif now>=job.Deadline then
      fallback("Recogida sin confirmar: devolver al flujo en cola.")
      dropJob(object,job)
     end
    end
   end
  end
 end
 local function pickupExtra(objects,primaryBusy)
  if Core.QueueOnly then return end
  local busy=primaryBusy or CleanupToolGate.Owner~=nil or FoldingCleanupCore.Busy
  local skipFirst=not busy
  for _,object in ipairs(objects)do
   if not jobs[object]and not primary[object]then
    if skipFirst then skipFirst=false
    else
     local id,creator=signature(object)
     local r=RS:FindFirstChild("Remotes");local release=r and r:FindFirstChild("ReleaseObjectRE")
     if not release or not release:IsA("RemoteEvent")then fallback("ReleaseObjectRE no disponible");return end
     local count=0;for _ in pairs(jobs)do count=count+1 end
     if count>=3 then return end
     local job={Id=id,Creator=creator,Existing=snapshot(),Character=LP.Character,Stage="PICKUP",Deadline=os.clock()+2.5,RequestOrder=nextRequest(),Supplement=true}
     jobs[object]=job;Core.Pickups=Core.Pickups+1
     local ok,err=pcall(function()release:FireServer("InteractWithObject",{object=object})end)
     if not ok then fallback(tostring(err));dropJob(object,job);return end
    end
   end
  end
 end
 local function disconnect(list)for _,c in ipairs(list)do c:Disconnect()end;table.clear(list)end
 local function active()
  return alive and FoldingCleanupCore and FoldingCleanupCore.Enabled
   and (game.GameId==4540138978 or game.PlaceId==12985361032)
 end
 local function drain()
  queued=false
  if draining or not active()or not burst or CleanupToolGate.Owner then return end
  draining=true
  local ok,err=xpcall(function()
   -- Original cleaners retain tool correlation, retries, timeouts and exclusive clears.
   for _,core in ipairs({FoldingCleanupCore,ValentineCleanupCore,GenericAttachedCleanupCore})do
    if core and core.DrainPending then core:DrainPending()end
    if CleanupToolGate.Owner then break end
   end
   Core.Drains=Core.Drains+1
  end,debug.traceback)
  draining=false
  if not ok then Core.LastError=tostring(err)end
 end
 function Core:Wake()
  if not active()or not burst or queued or draining then return end
  queued=true
  task.defer(drain)
 end
 local inspecting=false
 local function inspect()
  if inspecting or not active()then return end
  inspecting=true
  local ok,err=xpcall(function()
  if not active()then return end
  local primaryBusy=prunePrimary()
  advanceJobs()
  local count=0
  local attachedObjects={}
  if folder and character and CleanupAttachmentDetector then
   for object in pairs(watched)do
    local id=object:GetAttribute("ToolId")
    local creator=tonumber(object:GetAttribute("CreatedPlayer"))
    if type(id)=="string"and id~=""and creator and creator>0 and creator%1==0
     and object.Parent==folder and CleanupAttachmentDetector:IsAttached(object,character)then count=count+1;attachedObjects[#attachedObjects+1]=object end
   end
  end
  Core.Pending=count
  local overlapping=count>1 or(count>0 and (CleanupToolGate.Owner~=nil or FoldingCleanupCore.Busy or primaryBusy))
  if overlapping and not burst then burst=true;Core.Overlaps=Core.Overlaps+1 end
  -- Keep an overlap session until attached backlog and in-flight clear are gone.
  if count==0 and not CleanupToolGate.Owner and not FoldingCleanupCore.Busy then burst=false end
  if overlapping then pickupExtra(attachedObjects,primaryBusy)end
  if burst then Core:Wake()end
  end,debug.traceback)
  inspecting=false
  if not ok then fallback(tostring(err));Core:Wake()end
 end
 local function unwatch(object)
  local list=watched[object];if list then disconnect(list);watched[object]=nil end
 end
 local function watch(object)
  if watched[object]then return end
  local list,links={},{};watched[object]=list
  local function watchLink(link)
   if links[link]then return end
   local props
   if link:IsA("ObjectValue")then props={"Value","Name"}
   elseif link:IsA("JointInstance")or link:IsA("WeldConstraint")then props={"Part0","Part1","Name"}end
   if not props then return end
   links[link]=true
   for _,prop in ipairs(props)do list[#list+1]=link:GetPropertyChangedSignal(prop):Connect(inspect)end
  end
  for _,attribute in ipairs({"ToolId","CreatedPlayer"})do list[#list+1]=object:GetAttributeChangedSignal(attribute):Connect(inspect)end
  list[#list+1]=object.DescendantAdded:Connect(function(link)watchLink(link);inspect()end)
  for _,link in ipairs(object:GetDescendants())do watchLink(link)end
 end
 local function reset()
  disconnect(connections)
  for object,job in pairs(jobs)do dropJob(object,job)end
  table.clear(primary);table.clear(toolOwners);table.clear(toolRecords)
  local old={};for object in pairs(watched)do old[#old+1]=object end
  for _,object in ipairs(old)do unwatch(object)end
  folder=nil;character=nil;burst=false;Core.Pending=0
 end
 local heartbeat
 function Core:Destroy()
  alive=false;self.Enabled=false;reset()
  if heartbeat then heartbeat:Disconnect()end
 end
 heartbeat=RunService.Heartbeat:Connect(function()
  local enabled=active();Core.Enabled=enabled==true
  local nextFolder=enabled and workspace:FindFirstChild("ObjectPlaceFolder")or nil
  if not enabled then if folder or character then reset()end;Core.QueueOnly=false;return end
  if folder~=nextFolder or character~=LP.Character then
   reset();folder=nextFolder;character=LP.Character
   if folder then
    connections[#connections+1]=folder.ChildAdded:Connect(function(object)watch(object);inspect()end)
    connections[#connections+1]=folder.ChildRemoved:Connect(function(object)unwatch(object);inspect()end)
    for _,object in ipairs(folder:GetChildren())do watch(object)end
   end
  end
  inspect()
 end)
 return true
end
