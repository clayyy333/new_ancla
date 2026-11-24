return function(context)
 setfenv(1,context)
 local Players=game:GetService("Players")
 local RunService=game:GetService("RunService")
 local player=Players.LocalPlayer
 local Core={Enabled=false,Active=false,Interventions=0,LastError=nil,Logs={},MaxLogs=900}
 local alive=true
 local startedAt=os.clock()
 local character,root
 local nativeParts=setmetatable({},{__mode="k"})
 local savedParts=setmetatable({},{__mode="k"})
 local seenExternal=setmetatable({},{__mode="k"})
 local lastAssemblyRoot=nil
 local connections={}
 local characterConnections={}

 local function connect(signal,callback,collection)
  local connection=signal:Connect(callback)
  table.insert(collection or connections,connection)
  return connection
 end
 local function disconnectAll(collection)
  for _,connection in ipairs(collection)do pcall(function()connection:Disconnect()end)end
  table.clear(collection)
 end
 local function updateUI()
  if UpdateAnchorPanel then UpdateAnchorPanel()end
 end
 local function pathOf(instance)
  if not instance then return "nil"end
  local ok,path=pcall(function()return instance:GetFullName()end)
  return ok and path or tostring(instance)
 end
 local function log(kind,detail)
  local line=string.format("[%.4fs] [%s] %s",os.clock()-startedAt,tostring(kind),tostring(detail or ""))
  Core.Logs[#Core.Logs+1]=line
  while #Core.Logs>Core.MaxLogs do table.remove(Core.Logs,1)end
 end
 local function partState(part)
  if not part then return "part=nil"end
  local ok,state=pcall(function()
   return "part="..pathOf(part).." rootPriority="..tostring(part.RootPriority).." massless="..tostring(part.Massless).." anchored="..tostring(part.Anchored).." assemblyRoot="..pathOf(part.AssemblyRootPart).." linear="..tostring(part.AssemblyLinearVelocity).." angular="..tostring(part.AssemblyAngularVelocity)
  end)
  return ok and state or("part="..pathOf(part).." unavailable="..tostring(state))
 end
 local function remember(part)
  if not part or savedParts[part]then return end
  savedParts[part]={RootPriority=part.RootPriority,Massless=part.Massless,CanCollide=part.CanCollide}
 end
 local function restore()
  for part,state in pairs(savedParts)do
   if part and part.Parent then
    pcall(function()part.RootPriority=state.RootPriority end)
    pcall(function()part.Massless=state.Massless end)
    pcall(function()part.CanCollide=state.CanCollide end)
   end
  end
  table.clear(savedParts)
  Core.Active=false
  lastAssemblyRoot=nil
 end
 local function noSitRunning()
  return NoSitAnchorCore and NoSitAnchorCore.Running
 end
 local function protectPart(part)
  if not part or not part.Parent then return end
  local firstSeen=not seenExternal[part]
  if firstSeen then
   seenExternal[part]=true
   log("EXTERNAL_BEFORE",partState(part))
  end
  remember(part)
  pcall(function()part.RootPriority=-127 end)
  pcall(function()part.Massless=true end)
  pcall(function()part.CanCollide=false end)
  pcall(function()part.AssemblyLinearVelocity=Vector3.zero end)
  pcall(function()part.AssemblyAngularVelocity=Vector3.zero end)
  if firstSeen then log("EXTERNAL_AFTER",partState(part))end
 end
 local function apply()
  if not alive then return end
  if not Core.Enabled or not noSitRunning()then
   if Core.Active then log("PAUSED","Ancla No Sit no está activa");restore()updateUI()end
   return
  end
  if not character or character~=player.Character or not root or not root.Parent then return end
  Core.Active=true
  remember(root)
  pcall(function()root.RootPriority=127 end)
  pcall(function()root.Massless=false end)
  local before=root.AssemblyRootPart
  if before~=lastAssemblyRoot then
   log("ASSEMBLY_ROOT","before="..pathOf(before).." hrp="..pathOf(root))
   lastAssemblyRoot=before
  end
  local ok,connected=pcall(function()return root:GetConnectedParts(true)end)
  if ok and type(connected)=="table"then
   for _,part in ipairs(connected)do
    if part~=root and not nativeParts[part]then protectPart(part)end
   end
  end
  if before and before~=root and not nativeParts[before]then protectPart(before)end
  pcall(function()root.RootPriority=127 end)
  pcall(function()root.AssemblyLinearVelocity=Vector3.zero end)
  pcall(function()root.AssemblyAngularVelocity=Vector3.zero end)
  local after=root.AssemblyRootPart
  if before~=root or after~=root then
   Core.Interventions+=1
   if after~=lastAssemblyRoot then log("ASSEMBLY_ROOT_AFTER","after="..pathOf(after).." hrp="..pathOf(root));lastAssemblyRoot=after end
  end
 end
 local function bindCharacter(newCharacter)
  disconnectAll(characterConnections)
  restore()
  table.clear(nativeParts)
  character=newCharacter
  root=nil
  local newRoot=newCharacter and newCharacter:WaitForChild("HumanoidRootPart",10)
  if not alive or player.Character~=newCharacter or not newRoot then return end
  root=newRoot
  local humanoid=newCharacter:FindFirstChildOfClass("Humanoid")
  table.clear(seenExternal)
  lastAssemblyRoot=nil
  for _,descendant in ipairs(newCharacter:GetDescendants())do
   if descendant:IsA("BasePart")then nativeParts[descendant]=true end
  end
  connect(newCharacter.DescendantAdded,function(descendant)
   if not alive or not Core.Enabled then return end
   if descendant:IsA("BasePart")then
    log("PART_ADDED",partState(descendant))
    task.defer(apply)
   elseif descendant:IsA("WeldConstraint")then
    local function logWeld(stage)
     log(stage,"weld="..pathOf(descendant).." part0="..pathOf(descendant.Part0).." part1="..pathOf(descendant.Part1).." enabled="..tostring(descendant.Enabled))
    end
    logWeld("WELD_ADDED")
    connect(descendant:GetPropertyChangedSignal("Part0"),function()if Core.Enabled then logWeld("WELD_PART0")task.defer(apply)end end,characterConnections)
    connect(descendant:GetPropertyChangedSignal("Part1"),function()if Core.Enabled then logWeld("WELD_PART1")task.defer(apply)end end,characterConnections)
    connect(descendant:GetPropertyChangedSignal("Enabled"),function()if Core.Enabled then logWeld("WELD_ENABLED")task.defer(apply)end end,characterConnections)
    task.defer(apply)
   end
  end,characterConnections)
  connect(newCharacter.DescendantRemoving,function(descendant)
   if not alive or not Core.Enabled then return end
   if descendant:IsA("BasePart")or descendant:IsA("WeldConstraint")then log("DESCENDANT_REMOVING",pathOf(descendant))end
  end,characterConnections)
  if humanoid then
   connect(humanoid.StateChanged,function(oldState,newState)
    if Core.Enabled then log("HUMANOID_STATE",tostring(oldState).." -> "..tostring(newState))end
   end,characterConnections)
   connect(humanoid:GetPropertyChangedSignal("Health"),function()
    if Core.Enabled then log("HEALTH","value="..tostring(humanoid.Health).." state="..tostring(humanoid:GetState()))end
   end,characterConnections)
   connect(humanoid.Died,function()if Core.Enabled then log("HUMANOID_DIED","health="..tostring(humanoid.Health))end end,characterConnections)
  end
  connect(root:GetPropertyChangedSignal("AssemblyRootPart"),function()
   if Core.Enabled then log("ROOT_PROPERTY_CHANGED",partState(root));task.defer(apply)end
  end,characterConnections)
  log("CHARACTER_BOUND","character="..pathOf(newCharacter).." nativeParts="..tostring(#newCharacter:GetDescendants()).." "..partState(root))
  apply()
 end
 function Core:SetEnabled(enabled)
  enabled=enabled and true or false
  if self.Enabled==enabled then return true end
  self.Enabled=enabled
  self.LastError=nil
  log(enabled and "ENABLED"or"DISABLED","NoSit="..tostring(noSitRunning()))
  if enabled then
   if player.Character and(character~=player.Character or not root)then bindCharacter(player.Character)end
   apply()
  else
   restore()
  end
  updateUI()
  return true
 end
 function Core:Toggle()return self:SetEnabled(not self.Enabled)end
 function Core:GetRecords()
  local header={
   "=== REFUERZO DE RAÍZ — REGISTROS ===",
   "Jugador: "..tostring(player.Name).." | UserId="..tostring(player.UserId),
   "Enabled: "..tostring(self.Enabled).." | Active: "..tostring(self.Active).." | Intervenciones="..tostring(self.Interventions),
   "NoSit: "..tostring(noSitRunning()),
   "Líneas: "..tostring(#self.Logs),
   "",
  }
  return table.concat(header,"\n")..table.concat(self.Logs,"\n")
 end
 function Core:CopyRecords()
  local text=self:GetRecords()
  local environment=getgenv and getgenv()or nil
  local copier=(environment and environment.setclipboard)or setclipboard or toclipboard
  if type(copier)~="function"then return false,"El ejecutor no ofrece portapapeles.",text end
  local ok,err=pcall(copier,text)
  return ok,ok and("Registros copiados: "..tostring(#self.Logs))or tostring(err),text
 end
 function Core:ClearRecords()
  table.clear(self.Logs)
  self.Interventions=0
  startedAt=os.clock()
  return true
 end
 function Core:Destroy()
  if not alive then return true end
  self:SetEnabled(false)
  alive=false
  disconnectAll(characterConnections)
  disconnectAll(connections)
  return true
 end
 if RunService.PreSimulation then connect(RunService.PreSimulation,apply)end
 connect(RunService.Heartbeat,apply)
 connect(player.CharacterAdded,function(newCharacter)task.spawn(function()bindCharacter(newCharacter)updateUI()end)end)
 connect(player.CharacterRemoving,function(oldCharacter)if Core.Enabled then log("CHARACTER_REMOVING","character="..pathOf(oldCharacter).." root="..partState(root))end end)
 if player.Character then task.spawn(function()bindCharacter(player.Character)end)end
 AssemblyRootGuardCore=Core
 return true
end
