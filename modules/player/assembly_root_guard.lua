return function(context)
 setfenv(1,context)
 local Players=game:GetService("Players")
 local RunService=game:GetService("RunService")
 local player=Players.LocalPlayer
 local Core={Enabled=false,Active=false,Interventions=0,LastError=nil}
 local alive=true
 local character,root
 local nativeParts=setmetatable({},{__mode="k"})
 local savedParts=setmetatable({},{__mode="k"})
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
 end
 local function noSitRunning()
  return NoSitAnchorCore and NoSitAnchorCore.Running
 end
 local function protectPart(part)
  if not part or not part.Parent then return end
  remember(part)
  pcall(function()part.RootPriority=-127 end)
  pcall(function()part.Massless=true end)
  pcall(function()part.CanCollide=false end)
  pcall(function()part.AssemblyLinearVelocity=Vector3.zero end)
  pcall(function()part.AssemblyAngularVelocity=Vector3.zero end)
 end
 local function apply()
  if not alive then return end
  if not Core.Enabled or not noSitRunning()then
   if Core.Active then restore()updateUI()end
   return
  end
  if not character or character~=player.Character or not root or not root.Parent then return end
  Core.Active=true
  remember(root)
  pcall(function()root.RootPriority=127 end)
  pcall(function()root.Massless=false end)
  local before=root.AssemblyRootPart
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
  if before~=root or after~=root then Core.Interventions+=1 end
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
  for _,descendant in ipairs(newCharacter:GetDescendants())do
   if descendant:IsA("BasePart")then nativeParts[descendant]=true end
  end
  connect(newCharacter.DescendantAdded,function(descendant)
   if not alive or not Core.Enabled then return end
   if descendant:IsA("BasePart")or descendant:IsA("WeldConstraint")then task.defer(apply)end
  end,characterConnections)
  apply()
 end
 function Core:SetEnabled(enabled)
  enabled=enabled and true or false
  if self.Enabled==enabled then return true end
  self.Enabled=enabled
  self.LastError=nil
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
 if player.Character then task.spawn(function()bindCharacter(player.Character)end)end
 AssemblyRootGuardCore=Core
 return true
end
