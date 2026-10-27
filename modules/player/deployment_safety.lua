-- FoldingTable safety: event-driven attachment detection and precomputed relocation.
return function(context)
 setfenv(1,context)
 local Core={StaticEnabled=false,MobileEnabled=false,Ready=false,Destinations={},Owners={},LastError=nil}
 function Core:IsAvailable()
  return game.GameId==4540138978 or game.PlaceId==12985361032
 end
 local center=Vector3.new(-224.5553,62.8129,494.7579)
	local safetyDistance=18
 -- First 11 entries are the user's original measurements, in their original order.
 -- Remaining X/Z coordinates were calculated offline, not at reaction time.
 local positions={
		Vector3.new(-226.8972, 65.2985, 456.1806),
		Vector3.new(-190.0703, 65.2985, 490.7628),
		Vector3.new(-196.2556, 65.2985, 468.7681),
		Vector3.new(-194.7382, 65.2987, 512.4031),
		Vector3.new(-215.5733, 65.2985, 531.0378),
		Vector3.new(-230.8835, 65.2984, 529.6299),
		Vector3.new(-244.8878, 65.2982, 524.5547),
		Vector3.new(-259.7762, 65.2985, 505.5299),
		Vector3.new(-261.8176, 65.298, 485.618),
		Vector3.new(-252.8583, 65.2986, 463.4034),
		Vector3.new(-238.2311, 65.2986, 452.4068),
		Vector3.new(-184.5553, 65.2985, 494.7579),
		Vector3.new(-189.9143, 65.2985, 514.7579),
		Vector3.new(-204.5553, 65.2985, 529.3989),
		Vector3.new(-224.5553, 65.2985, 534.7579),
		Vector3.new(-244.5553, 65.2985, 529.3989),
		Vector3.new(-259.1963, 65.2985, 514.7579),
		Vector3.new(-264.5553, 65.2985, 494.7579),
		Vector3.new(-259.1963, 65.2985, 474.7579),
		Vector3.new(-244.5553, 65.2985, 460.1169),
		Vector3.new(-224.5553, 65.2985, 454.7579),
		Vector3.new(-204.5553, 65.2985, 460.1169),
		Vector3.new(-189.9143, 65.2985, 474.7579),
		Vector3.new(-185.9183, 65.2985, 505.1107),
 }
 local persistent,runtime,rigConnections={},{},{}
 local watched={}
 local preparedCharacter,folder,busy
 local rng=Random.new()
 local function disconnect(list)
  for _,connection in ipairs(list) do connection:Disconnect() end
  table.clear(list)
 end
 local function refresh()
  if UpdateAnchorPanel then UpdateAnchorPanel() end
  if UpdateMoveAnchoredPanel then UpdateMoveAnchoredPanel() end
 end
 local function mobile()
  if not Core.MobileEnabled then return nil end
  if MobileAnchorCore and MobileAnchorCore:IsRunning() then return MobileAnchorCore end
  if MobileAnchorV11Core and MobileAnchorV11Core:IsRunning() then return MobileAnchorV11Core end
  if MobileAnchorV13Core and MobileAnchorV13Core:IsRunning() then return MobileAnchorV13Core end
 end
 local function active()
  return mobile()~=nil -- Static button now runs the Babycar cycle, not FoldingTable relocation.
 end
 local function resetWatchers()
  disconnect(runtime)
  for _,entry in pairs(watched) do disconnect(entry.connections) end
  table.clear(watched);folder=nil
 end
 function Core:Prepare()
  self.Ready=false;self.Destinations={}
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if not root or not humanoid or humanoid.Health<=0 then self.LastError="Esperando personaje.";return false end
  local height=humanoid.HipHeight+root.Size.Y/2
  if humanoid.RigType==Enum.HumanoidRigType.R6 then
   local leg=character:FindFirstChild("Left Leg")
   height=height+(leg and leg.Size.Y or 2)
  end
  local excluded={}
  for _,account in ipairs(Players:GetPlayers()) do if account.Character then table.insert(excluded,account.Character) end end
  for _,name in ipairs({"ObjectPlaceFolder","Cars"}) do local item=workspace:FindFirstChild(name);if item then table.insert(excluded,item) end end
  local params=RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances=excluded;params.RespectCanCollide=true
  for _,point in ipairs(positions) do
   local hit=workspace:Raycast(Vector3.new(point.X,point.Y+50,point.Z),Vector3.new(0,-200,0),params)
   if hit then
    local destination=Vector3.new(point.X,hit.Position.Y+height,point.Z)
    table.insert(self.Destinations,CFrame.lookAt(destination,Vector3.new(center.X,destination.Y,center.Z)))
   end
  end
  preparedCharacter=character
  self.Ready=#self.Destinations>0
  self.LastError=not self.Ready and "No hay suelo detectado en los destinos." or nil
  return self.Ready
 end
 function Core:Relocate(allowUnknownCreator)
  if busy or not self.Ready or not active() then return false end
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  if not root or character~=preparedCharacter then return false end
  local hazards={}
  for id in pairs(self.Owners) do
   local account=Players:GetPlayerByUserId(id)
   local other=account and account.Character and account.Character:FindFirstChild("HumanoidRootPart")
   if other then table.insert(hazards,other.Position) end
  end
  if #hazards==0 and not allowUnknownCreator then self.LastError="Creador identificado, posición no disponible.";return false end
  local first=rng:NextInteger(1,#self.Destinations)
  for offset=0,#self.Destinations-1 do
   local target=self.Destinations[(first+offset-1)%#self.Destinations+1]
   local valid=(target.Position-root.Position).Magnitude>0.1
   for _,position in ipairs(hazards) do
    if (target.Position-position).Magnitude<=safetyDistance then valid=false;break end
   end
   if valid then
    busy=true
    local movable=mobile()
    if movable then
     -- Update only the public recovery reference; original locomotion code is untouched.
     movable.SafeCFrame=target;movable.LastPosition=target.Position
     movable.GraceUntil=os.clock()+0.35;movable.StableSince=os.clock()
     movable.RecoveryUntil=0;movable.RecoveryMinUntil=0
     if movable.SafeHistory then table.clear(movable.SafeHistory) end
     movable.LastSafeSample=0
     for _,part in ipairs(character:GetDescendants()) do
      if part:IsA("BasePart") then part.AssemblyLinearVelocity=Vector3.zero;part.AssemblyAngularVelocity=Vector3.zero end
     end
     root.CFrame=target
     if movable.ResetFallProtectionReference then movable:ResetFallProtectionReference()end
    else
     DeploymentAnchorMotorCore:RelocateForDeployment(target)
    end
    busy=false;self.LastError=nil;self.LastDestination=target
    return true
   end
  end
  self.LastError="Ningún destino respeta los 18 studs de todos los creadores."
  return false
 end
 local function tryObject(object,entry)
  if not active() or not Core.Ready or not object.Parent or object:GetAttribute("ToolId")~="FoldingTable" then return end
  local character=player.Character
  local link=object:FindFirstChild("weld2target")
  if not character or not link or not (link:IsA("JointInstance") or link:IsA("WeldConstraint")) then return end
  local a,b=link.Part0,link.Part1
  local attached
  if a and b then
   if a:IsDescendantOf(character) and (b==object or b:IsDescendantOf(object)) then attached=a
   elseif b:IsDescendantOf(character) and (a==object or a:IsDescendantOf(object)) then attached=b end
  end
  local accessory=attached and attached:FindFirstAncestorOfClass("Accessory")
  if not accessory or not accessory:IsDescendantOf(character) then return end
  local id=tonumber(object:GetAttribute("CreatedPlayer"))
  local identified=id and id>0 and id%1==0
  if identified and id==player.UserId then return end
  if entry.character~=character then
   entry.character=character;entry.relocated=false;entry.owner=nil
  end
  if identified then
   Core.Owners[id]=true;Core.LastCreatorId=id;Core.LastCreatorName=object:GetAttribute("CreatedPlayerName")
  end
  if not entry.relocated then
   -- The attachment is sufficient for the initial escape. Creator replication
   -- is not a prerequisite; already-known owners are still excluded.
   entry.relocated=Core:Relocate(true)
   if identified then entry.owner=id end
   refresh()
  elseif identified and entry.owner~=id then
   entry.owner=id
   local account=Players:GetPlayerByUserId(id)
   local other=account and account.Character and account.Character:FindFirstChild("HumanoidRootPart")
   local root=character:FindFirstChild("HumanoidRootPart")
   if other and root and (root.Position-other.Position).Magnitude<=safetyDistance then Core:Relocate() end
   refresh()
  end
 end
 local function watchObject(object)
  if watched[object] then return end
  local entry={connections={},links={}};watched[object]=entry
  local function attempt() tryObject(object,entry) end
  local function watchLink(link)
   if entry.links[link] or not (link:IsA("JointInstance") or link:IsA("WeldConstraint")) then return end
   entry.links[link]=true
   table.insert(entry.connections,link:GetPropertyChangedSignal("Name"):Connect(attempt))
   table.insert(entry.connections,link:GetPropertyChangedSignal("Part0"):Connect(attempt))
   table.insert(entry.connections,link:GetPropertyChangedSignal("Part1"):Connect(attempt))
  end
  for _,attribute in ipairs({"ToolId","CreatedPlayer","CreatedPlayerName"}) do
   table.insert(entry.connections,object:GetAttributeChangedSignal(attribute):Connect(attempt))
  end
  table.insert(entry.connections,object.ChildAdded:Connect(function(child)watchLink(child);attempt()end))
  for _,child in ipairs(object:GetChildren()) do watchLink(child) end
  attempt()
 end
 local function bindFolder(container)
  resetWatchers()
  folder=container
  if not folder then return end
  table.insert(runtime,folder.ChildAdded:Connect(watchObject))
  table.insert(runtime,folder.ChildRemoved:Connect(function(object)
   local entry=watched[object]
   if entry then disconnect(entry.connections);watched[object]=nil end
  end))
  for _,object in ipairs(folder:GetChildren()) do watchObject(object) end
 end
 local function enableWatchers()
  if not Core.MobileEnabled then resetWatchers();return end
  local container=workspace:FindFirstChild("ObjectPlaceFolder")
  if container~=folder then bindFolder(container) end
  for object,entry in pairs(watched) do tryObject(object,entry) end
 end
 function Core:SetMobileEnabled(enabled)
  if enabled and not self:IsAvailable() then return false,"Disponible únicamente en Metro Life." end
  self.MobileEnabled=enabled==true
  if self.MobileEnabled then self:Prepare() end
  enableWatchers();refresh();return true
 end
 function Core:Start()
  if not ExperimentalFlingCore or not ExperimentalFlingCore:IsAuthorized()then return false,"Disponible solo para owners."end
  if not self:IsAvailable() then return false,"Disponible únicamente en Metro Life." end
  if self.StaticEnabled then return true end
  if StaticPassThroughAnchorCore:IsRunning() then return false,"Desactiva primero el ancla normal con desfase." end
  local ok,message=BabyVehicleAnchorCore:Start()
  if not ok then return false,message end
  DeploymentAnchorMotorCore:SetPhase(false)
  self.StaticEnabled=true;enableWatchers();refresh();return true
 end
 function Core:Stop()
  local was=self.StaticEnabled
  self.StaticEnabled=false
  if was then BabyVehicleAnchorCore:Stop() end
  if not self.MobileEnabled then self.Owners={} end
  enableWatchers();refresh();return true
 end
 function Core:IsRunning()return self.StaticEnabled and BabyVehicleAnchorCore:IsRunning()end
 function Core:Destroy()
  self:Stop();self.MobileEnabled=false;resetWatchers();disconnect(rigConnections);disconnect(persistent)
  DeploymentAnchorMotorCore:Destroy()
 end
 local rebuildQueued=false
 local function rebuild()
  if rebuildQueued or not Core.MobileEnabled then return end
  rebuildQueued=true
  task.defer(function()
   rebuildQueued=false
   if not Core.MobileEnabled then return end
   Core:Prepare()
   for object,entry in pairs(watched) do tryObject(object,entry) end
  end)
 end
 local function bindCharacter(character)
  disconnect(rigConnections);preparedCharacter=nil;Core.Ready=false;Core.Owners={}
  local function observe(instance)
   if instance:IsA("Humanoid") then
    table.insert(rigConnections,instance:GetPropertyChangedSignal("HipHeight"):Connect(rebuild))
   elseif instance:IsA("BasePart") and (instance.Name=="HumanoidRootPart" or instance.Name=="Left Leg") then
    table.insert(rigConnections,instance:GetPropertyChangedSignal("Size"):Connect(rebuild))
   end
  end
  for _,instance in ipairs(character:GetChildren()) do observe(instance) end
  table.insert(rigConnections,character.ChildAdded:Connect(function(instance)observe(instance);rebuild()end))
  rebuild()
 end
 table.insert(persistent,player.CharacterAdded:Connect(bindCharacter))
 if player.Character then bindCharacter(player.Character) end
 table.insert(persistent,workspace.ChildAdded:Connect(function(item)
  if item.Name=="ObjectPlaceFolder" and Core.MobileEnabled then bindFolder(item) end
 end))
 table.insert(persistent,workspace.ChildRemoved:Connect(function(item)
  if item==folder then resetWatchers() end
 end))
 local previouslyActive=false
 table.insert(persistent,RunService.Heartbeat:Connect(function()
  if Core.StaticEnabled and not BabyVehicleAnchorCore:IsRunning() then Core.StaticEnabled=false;enableWatchers();refresh() end
  if not active() then previouslyActive=false;return end
  local justActivated=not previouslyActive;previouslyActive=true
  if not Core.Ready then rebuild();return end
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if root then
   for id in pairs(Core.Owners) do
    local account=Players:GetPlayerByUserId(id)
    local other=account and account.Character and account.Character:FindFirstChild("HumanoidRootPart")
    if other and (root.Position-other.Position).Magnitude<=safetyDistance then Core:Relocate();break end
   end
  end
  -- Re-evaluate existing objects when a mobile anchor starts; no world scan.
  if justActivated then for object,entry in pairs(watched) do tryObject(object,entry) end end
 end))
 DeploymentSafetyCore=Core
 return true
end
