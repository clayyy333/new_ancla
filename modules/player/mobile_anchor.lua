-- Ancla movil experimental: locomocion protegida, puentes externos y Anti-Ram local.
return function(context)
 setfenv(1,context)

 local OWNERS={
  [11739864999]="psychoo778",
  [11743514302]="ksablanca0",
  [11747901934]="psycho777oo",
 }
 local expected=OWNERS[player.UserId]
 local Core={
  Running=false,SafeCFrame=nil,LastPosition=nil,GraceUntil=0,Corrections=0,
  StableSince=0,RecoveryUntil=0,RecoveryMinUntil=0,ThreatUntil=0,
  LastReport=nil,History={},SafeHistory={},LastSafeSample=0,BrokenBridges=0,AntiRamBlocks=0,
  State="NORMAL",StateUntil=0,PhaseFolder=nil,LastThreatScan=0,LastHostileMaintain=0,
 }
 local persistent,runtime={},{ }
 local collisions={} -- [BasePart]={original=boolean,expires=number,permanent=boolean}
 local supports={} -- [BasePart]=expiry
 local hostiles={} -- [AssemblyRootPart]={until,seed,reason,lastRecord}
 local phaseLinks={} -- [ExternalPart]={expires,pairs={[CharacterPart]=NoCollisionConstraint}}
 local lastSpatialScan=0
 local lastBridgeScan=0
 local lastSupportScan=0

 local function authorized()
  return expected~=nil and string.lower(player.Name)==expected
 end

 local function rig()
  local character=player.Character
  return character,character and character:FindFirstChildOfClass("Humanoid"),character and character:FindFirstChild("HumanoidRootPart")
 end

 local function belongsTo(instance,ancestor)
  return instance~=nil and ancestor~=nil and (instance==ancestor or instance:IsDescendantOf(ancestor))
 end

 local function disconnectRuntime()
  for _,connection in ipairs(runtime) do pcall(function()connection:Disconnect()end) end
  table.clear(runtime)
 end

 local function record(kind,data)
  local report=data or {}
  report.Kind=kind
  report.Time=os.clock()
  Core.LastReport=report
  Core.History[#Core.History+1]=report
  if #Core.History>40 then table.remove(Core.History,1) end
 end
 local function setState(state,duration,reason)
  local now=os.clock()
  local rank={NORMAL=0,ALERT=1,CONTACT=2,EMERGENCY=3}
  local previousUntil=Core.StateUntil
  if Core.State~=state and (now>=previousUntil or (rank[state] or 0)>=(rank[Core.State] or 0)) then
   Core.State=state
   record("STATE_CHANGE",{State=state,Reason=reason})
  end
  Core.StateUntil=math.max(previousUntil,now+(duration or 0))
 end

 local function isOtherCharacterPart(part)
  for _,other in ipairs(Players:GetPlayers()) do
   if other~=player and other.Character and belongsTo(part,other.Character) then return true end
  end
  return false
 end

 local function isSupportPart(part,now)
  return part~=nil and (supports[part] or 0)>(now or os.clock())
 end

 local function ensurePhaseFolder(character)
  if Core.PhaseFolder and Core.PhaseFolder.Parent==character then return Core.PhaseFolder end
  if Core.PhaseFolder then pcall(function()Core.PhaseFolder:Destroy()end) end
  local folder=Instance.new("Folder")
  folder.Name="MobileAnchorPhase"
  folder.Parent=character
  Core.PhaseFolder=folder
  return folder
 end

 local function phasePart(externalPart,duration)
  local character=player.Character
  if not character or not externalPart or not externalPart:IsA("BasePart") or belongsTo(externalPart,character) or isSupportPart(externalPart) then return end
  local state=phaseLinks[externalPart]
  if not state then state={expires=0,pairs={}};phaseLinks[externalPart]=state end
  state.expires=math.max(state.expires,os.clock()+(duration or 1))
  local folder=ensurePhaseFolder(character)
  local count=0
  for _ in pairs(state.pairs) do count+=1 end
  for _,bodyPart in ipairs(character:GetDescendants()) do
   if count>=12 then break end
   if bodyPart:IsA("BasePart") and not state.pairs[bodyPart] then
    local ok,constraint=pcall(function()
     local noCollision=Instance.new("NoCollisionConstraint")
     noCollision.Part0=bodyPart
     noCollision.Part1=externalPart
     noCollision.Parent=folder
     return noCollision
    end)
    if ok and constraint then state.pairs[bodyPart]=constraint;count+=1 end
   end
  end
 end

 local function cleanupPhase(now,force)
  for externalPart,state in pairs(phaseLinks) do
   if force or not externalPart or not externalPart.Parent or now>=state.expires then
    for _,constraint in pairs(state.pairs) do pcall(function()constraint:Destroy()end) end
    phaseLinks[externalPart]=nil
   end
  end
  if force and Core.PhaseFolder then pcall(function()Core.PhaseFolder:Destroy()end);Core.PhaseFolder=nil end
 end

 local function clearSupportState()
  table.clear(supports)
 end

 local function suppressPart(part,duration,permanent)
  if not part or not part:IsA("BasePart") then return false end
  if not permanent and isSupportPart(part) then return false end
  local state=collisions[part]
  if not state then
   state={original=part.CanCollide,expires=0,permanent=false}
   collisions[part]=state
  end
  state.permanent=state.permanent or permanent==true
  state.expires=math.max(state.expires,os.clock()+(duration or 1))
  pcall(function()part.CanCollide=false end)
  return true
 end

 local function restoreExpiredCollisions(now)
  for part,state in pairs(collisions) do
   if not part or not part.Parent then
    collisions[part]=nil
   elseif not state.permanent and now>=state.expires then
    pcall(function()part.CanCollide=state.original end)
    collisions[part]=nil
   elseif part.CanCollide then
    pcall(function()part.CanCollide=false end)
   end
  end
 end

 local function restoreCollisions()
  for part,state in pairs(collisions) do
   if part and part.Parent then pcall(function()part.CanCollide=state.original end) end
  end
  table.clear(collisions)
 end

 local function suppressCharacter(character)
  if not character or character==player.Character then return end
  for _,object in ipairs(character:GetDescendants()) do suppressPart(object,1,true) end
  runtime[#runtime+1]=character.DescendantAdded:Connect(function(object)suppressPart(object,1,true)end)
 end

 local function bindPlayers()
  for _,other in ipairs(Players:GetPlayers()) do
   if other~=player then
    suppressCharacter(other.Character)
    runtime[#runtime+1]=other.CharacterAdded:Connect(suppressCharacter)
   end
  end
  runtime[#runtime+1]=Players.PlayerAdded:Connect(function(other)
   if other~=player then runtime[#runtime+1]=other.CharacterAdded:Connect(suppressCharacter) end
  end)
 end

 local function zeroCharacter(character)
  for _,object in ipairs(character:GetDescendants()) do
   if object:IsA("BasePart") then
    object.AssemblyLinearVelocity=Vector3.zero
    object.AssemblyAngularVelocity=Vector3.zero
   end
  end
 end
 local function pushSafePosition(root,now)
  if not root or now-Core.LastSafeSample<0.05 then return end
  Core.LastSafeSample=now
  Core.SafeHistory[#Core.SafeHistory+1]={CFrame=root.CFrame,Time=now}
  if #Core.SafeHistory>30 then table.remove(Core.SafeHistory,1) end
 end

 local function newestSafeBeforeImpact(now)
  for index=#Core.SafeHistory,1,-1 do
   local sample=Core.SafeHistory[index]
   if sample and now-sample.Time>=0.08 and now-sample.Time<=2 then return sample.CFrame end
  end
  return Core.SafeCFrame
 end
 local function refreshSupports(now,character,humanoid,root)
  if now-lastSupportScan<0.04 then return end
  lastSupportScan=now
  for part,expiry in pairs(supports) do
   if not part or not part.Parent or now>=expiry then supports[part]=nil end
  end
  local params=RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={character}
  params.IgnoreWater=false
  local right=root.CFrame.RightVector*1.15
  local forward=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
  if forward.Magnitude>0.001 then forward=forward.Unit*1.15 else forward=Vector3.new(0,0,-1.15) end
  local origins={Vector3.zero,right,-right,forward,-forward}
  local length=math.max(5.5,humanoid.HipHeight+root.Size.Y*0.5+3)
  for _,offset in ipairs(origins) do
   local result=workspace:Raycast(root.Position+offset+Vector3.new(0,0.5,0),Vector3.new(0,-length,0),params)
   local part=result and result.Instance
   if part and part:IsA("BasePart") and not isOtherCharacterPart(part) then
    local linear=part.AssemblyLinearVelocity
    local angular=part.AssemblyAngularVelocity.Magnitude
    local behavesAsFloor=math.abs(linear.Y)<12 and linear.Magnitude<35 and angular<6 and result.Normal.Y>0.35
    if behavesAsFloor then
     supports[part]=now+0.24
     local collisionState=collisions[part]
     if collisionState and not collisionState.permanent then
      pcall(function()part.CanCollide=collisionState.original end)
      collisions[part]=nil
     end
    end
   end
  end
 end

 local function externalContainer(part)
  if not part then return nil end
  local candidate=part
  local current=part.Parent
  while current and current~=workspace do
   if current:IsA("Model") then candidate=current end
   current=current.Parent
  end
  return candidate
 end

 local function connectedAssembly(seed)
  local result={}
  if not seed or not seed:IsA("BasePart") then return result end
  local assemblyRoot=seed.AssemblyRootPart or seed
  local ok,parts=pcall(function()return assemblyRoot:GetConnectedParts(true)end)
  if ok and parts then
   result[#result+1]=assemblyRoot
   for _,part in ipairs(parts) do if part~=assemblyRoot then result[#result+1]=part end end
  else
   result[1]=seed
  end
  return result,assemblyRoot
 end

 local function isolateAssembly(seed,reason)
  local character=player.Character
  if not seed or not seed:IsA("BasePart") or belongsTo(seed,character) then return false end
  local now=os.clock()
  local assemblyRoot=seed.AssemblyRootPart or seed
  local hostile=hostiles[assemblyRoot]
  local isNew=hostile==nil
  local parts
  if hostile and hostile.parts then
   parts=hostile.parts
  else
   parts,assemblyRoot=connectedAssembly(seed)
   hostile=hostiles[assemblyRoot]
   isNew=hostile==nil
  end
  local duration=(reason=="DIRECT_BRIDGE" or reason=="FORCED_SEAT" or reason=="HIGH_SPEED_PLAYER") and 3 or 1.35
  if not hostile then
   hostile={expires=0,seed=seed,reason=reason,lastRecord=0,parts=parts,phaseParts={}}
   hostiles[assemblyRoot]=hostile
  end
  hostile.expires=math.max(hostile.expires,now+duration)
  hostile.seed=seed
  hostile.reason=reason
  hostile.parts=hostile.parts or parts
  hostile.phaseParts=hostile.phaseParts or {}
  local root=character:FindFirstChild("HumanoidRootPart")
  local count,phaseCount=0,0
  for _,part in ipairs(hostile.parts) do
   if part and part.Parent and part:IsA("BasePart") and not belongsTo(part,character) and not isSupportPart(part,now) then
    local closeEnough=root and (part.Position-root.Position).Magnitude<11
    local shouldPhase=(part.CanCollide or closeEnough) and #hostile.phaseParts<6
    if suppressPart(part,duration,false) then
     count+=1
     if shouldPhase then
      phasePart(part,duration)
      hostile.phaseParts[#hostile.phaseParts+1]=part
      phaseCount+=1
     end
    end
   end
  end
  -- Una detección repetida solo extiende la protección; no vuelve a crear
  -- cientos de constraints ni vuelve a analizar todo el vehículo.
  if not isNew then
   for _,part in ipairs(hostile.phaseParts) do
    local phase=phaseLinks[part]
    if phase then phase.expires=math.max(phase.expires,hostile.expires) end
   end
  end
  if count>0 then
   Core.ThreatUntil=math.max(Core.ThreatUntil,now+0.45)
   Core.AntiRamBlocks+=1
   local contact=reason=="TOUCHED" or reason=="TOUCHED_NEW_PART" or reason=="DIRECT_BRIDGE" or reason=="FORCED_SEAT"
   setState(contact and "CONTACT" or "ALERT",0.55,reason)
   if isNew or now-hostile.lastRecord>0.75 then
    hostile.lastRecord=now
    record("COLLISION_ASSEMBLY",{
     Reason=reason,ExternalEndpoint=seed,ExternalAssemblyRoot=assemblyRoot,
     ExternalContainer=externalContainer(seed),PartCount=count,PhaseParts=phaseCount,
    })
   end
   return true
  end
  return false
 end

 local function maintainHostiles(now)
  local active=now<Core.ThreatUntil
  local interval=active and 0.08 or 0.18
  if now-Core.LastHostileMaintain<interval then return end
  Core.LastHostileMaintain=now
  for assemblyRoot,state in pairs(hostiles) do
   if not assemblyRoot or not assemblyRoot.Parent or now>=state.expires then
    hostiles[assemblyRoot]=nil
   else
    local remaining=math.max(0.2,state.expires-now)
    for _,part in ipairs(state.parts or {}) do
     if part and part.Parent and part:IsA("BasePart") and not isSupportPart(part,now) then
      local collision=collisions[part]
      if part.CanCollide or not collision then suppressPart(part,remaining,false) end
     end
    end
    for _,part in ipairs(state.phaseParts or {}) do
     local phase=phaseLinks[part]
     if phase then phase.expires=math.max(phase.expires,state.expires) end
    end
   end
  end
 end
 local function endpoints(connection)
  local part0,part1
  if connection:IsA("WeldConstraint") or connection:IsA("JointInstance") then
   pcall(function()part0=connection.Part0;part1=connection.Part1 end)
  elseif connection:IsA("Constraint") then
   local attachment0,attachment1
   pcall(function()attachment0=connection.Attachment0;attachment1=connection.Attachment1 end)
   part0=attachment0 and attachment0.Parent
   part1=attachment1 and attachment1.Parent
  end
  if part0 and not part0:IsA("BasePart") then part0=nil end
  if part1 and not part1:IsA("BasePart") then part1=nil end
  return part0,part1
 end

 local function inspectBridge(connection)
  if not Core.Running or not connection or not connection.Parent then return false end
  local character=player.Character
  if not character then return false end
  if connection:IsA("Motor6D") or connection.Name=="AccessoryWeld" then return false end
  if connection:IsA("BodyMover") and belongsTo(connection,character) then
   local parent=connection.Parent
   local className=connection.ClassName
   pcall(function()connection:Destroy()end)
   Core.ThreatUntil=math.max(Core.ThreatUntil,os.clock()+0.65)
   setState("CONTACT",0.65,"EXTERNAL_BODY_MOVER")
   record("EXTERNAL_ACTUATOR_REMOVED",{BridgeClass=className,CharacterEndpoint=parent})
   return true
  end
  local part0,part1=endpoints(connection)
  if (part0 and not part1) or (part1 and not part0) then
   local endpoint=part0 or part1
   if belongsTo(endpoint,character) and not belongsTo(connection,character) then
    local className=connection.ClassName
    pcall(function()connection:Destroy()end)
    Core.ThreatUntil=math.max(Core.ThreatUntil,os.clock()+0.65)
    setState("CONTACT",0.65,"EXTERNAL_ACTUATOR")
    record("EXTERNAL_ACTUATOR_REMOVED",{BridgeClass=className,CharacterEndpoint=endpoint})
    return true
   end
  end
  if not part0 or not part1 then return false end
  local inside0=belongsTo(part0,character)
  local inside1=belongsTo(part1,character)
  if inside0==inside1 then return false end
  local characterEndpoint=inside0 and part0 or part1
  local externalEndpoint=inside0 and part1 or part0
  local report={
   DirectBridge=connection,BridgeClass=connection.ClassName,
   CharacterEndpoint=characterEndpoint,ExternalEndpoint=externalEndpoint,
   ExternalAssemblyRoot=externalEndpoint.AssemblyRootPart,
   ExternalContainer=externalContainer(externalEndpoint),
   ConnectionType="CHARACTER_EXTERNAL_BRIDGE",
  }
  isolateAssembly(externalEndpoint,"DIRECT_BRIDGE")
  pcall(function()connection:Destroy()end)
  Core.BrokenBridges+=1
  Core.ThreatUntil=math.max(Core.ThreatUntil,os.clock()+0.65)
  record("DIRECT_EXTERNAL_BRIDGE",report)
  local _,humanoid=rig()
  if humanoid then
   humanoid.Sit=false
   pcall(function()humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)end)
  end
  return true
 end

 local function scanCharacterBridges(character)
  if not character then return end
  local seen={}
  for _,object in ipairs(character:GetDescendants()) do
   if object:IsA("BasePart") then
    local ok,joints=pcall(function()return object:GetJoints()end)
    if ok then
     for _,joint in ipairs(joints) do
      if not seen[joint] then seen[joint]=true;inspectBridge(joint) end
     end
    end
   elseif object:IsA("BodyMover") then
    inspectBridge(object)
   elseif object:IsA("Attachment") then
    local ok,constraints=pcall(function()return object:GetConstraints()end)
    if ok then
     for _,constraint in ipairs(constraints) do
      if not seen[constraint] then seen[constraint]=true;inspectBridge(constraint) end
     end
    end
   end
  end
 end

 local function bindCharacter(character)
  if not character then return end
  for _,object in ipairs(character:GetDescendants()) do
   if object:IsA("BasePart") then
    runtime[#runtime+1]=object.Touched:Connect(function(other)
     if not Core.Running or not other or belongsTo(other,character) then return end
     local relative=(other.AssemblyLinearVelocity-object.AssemblyLinearVelocity).Magnitude
     local angular=other.AssemblyAngularVelocity.Magnitude
     if relative>24 or angular>9 then isolateAssembly(other,"TOUCHED") end
    end)
   end
  end
  runtime[#runtime+1]=character.DescendantAdded:Connect(function(object)
   if object:IsA("BasePart") then
    runtime[#runtime+1]=object.Touched:Connect(function(other)
     if Core.Running and other and not belongsTo(other,character) then
      local relative=(other.AssemblyLinearVelocity-object.AssemblyLinearVelocity).Magnitude
      if relative>24 or other.AssemblyAngularVelocity.Magnitude>9 then isolateAssembly(other,"TOUCHED_NEW_PART") end
     end
    end)
   end
   task.defer(function()if Core.Running then inspectBridge(object) end end)
  end)
 end

 local function spatialAntiRam(now,character,root)
  local interval=now<Core.ThreatUntil and 0.045 or 0.11
  if now-lastSpatialScan<interval then return end
  lastSpatialScan=now
  local params=OverlapParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={character}
  params.MaxParts=80
  local ok,nearby=pcall(function()return workspace:GetPartBoundsInRadius(root.Position,22,params)end)
  if not ok then return end
  local checked={}
  for _,part in ipairs(nearby) do
   if part:IsA("BasePart") and not belongsTo(part,character) then
    local assemblyRoot=part.AssemblyRootPart or part
    if not checked[assemblyRoot] then
     checked[assemblyRoot]=true
     local offset=root.Position-assemblyRoot.Position
     local distance=offset.Magnitude
     local externalVelocity=assemblyRoot.AssemblyLinearVelocity
     local relativeVelocity=externalVelocity-root.AssemblyLinearVelocity
     local closing=distance>0 and relativeVelocity:Dot(offset.Unit) or 0
     local angular=assemblyRoot.AssemblyAngularVelocity.Magnitude
     local dangerous=(closing>18 and externalVelocity.Magnitude>24) or (distance<10 and angular>10) or externalVelocity.Magnitude>85
     if dangerous then isolateAssembly(part,"PROXIMITY_ANTI_RAM") end
    end
   end
  end
 end

 local function scanPlayerThreats(now,localCharacter)
  local interval=now<Core.ThreatUntil and 0.06 or 0.14
  if now-Core.LastThreatScan<interval then return end
  Core.LastThreatScan=now
  for _,other in ipairs(Players:GetPlayers()) do
   local otherCharacter=other~=player and other.Character
   local otherRoot=otherCharacter and otherCharacter:FindFirstChild("HumanoidRootPart")
   local otherHumanoid=otherCharacter and otherCharacter:FindFirstChildOfClass("Humanoid")
   if otherRoot then
    local speed=otherRoot.AssemblyLinearVelocity.Magnitude
    local angular=otherRoot.AssemblyAngularVelocity.Magnitude
    if speed>85 or angular>14 then
     if otherHumanoid and otherHumanoid.SeatPart then
      isolateAssembly(otherHumanoid.SeatPart,"HIGH_SPEED_PLAYER")
     else
      local params=OverlapParams.new()
      params.FilterType=Enum.RaycastFilterType.Exclude
      params.FilterDescendantsInstances={localCharacter,otherCharacter}
      params.MaxParts=50
      local ok,parts=pcall(function()return workspace:GetPartBoundsInRadius(otherRoot.Position,14,params)end)
      if ok then
       local checked={}
       for _,part in ipairs(parts) do
        if part:IsA("BasePart") then
         local assemblyRoot=part.AssemblyRootPart or part
         if not checked[assemblyRoot] then
          checked[assemblyRoot]=true
          if assemblyRoot.AssemblyLinearVelocity.Magnitude>45 or assemblyRoot.AssemblyAngularVelocity.Magnitude>8 then
           isolateAssembly(part,"HIGH_SPEED_PLAYER")
          end
         end
        end
       end
      end
     end
    end
   end
  end
 end
 local function clampThreatMotion(character,humanoid,root)
  local linear=root.AssemblyLinearVelocity
  local angular=root.AssemblyAngularVelocity.Magnitude
  local active=os.clock()<Core.ThreatUntil or linear.Magnitude>58 or angular>16
  if not active then return end
  local desired=humanoid.MoveDirection*math.min(humanoid.WalkSpeed,26)
  local vertical=linear.Y
  local humanoidState=humanoid:GetState()
  local legitimateJump=(humanoidState==Enum.HumanoidStateType.Jumping or humanoidState==Enum.HumanoidStateType.Freefall) and vertical>0 and vertical<70
  if math.abs(vertical)>70 or (not legitimateJump and math.abs(vertical)>42) then vertical=0 end
  -- El HRP gobierna el ensamblaje del personaje; no recorremos cada miembro
  -- en cada paso físico salvo durante las correcciones de emergencia.
  root.AssemblyLinearVelocity=Vector3.new(desired.X,vertical,desired.Z)
  root.AssemblyAngularVelocity=Vector3.zero
 end

 function Core:IsAuthorized()return authorized()end
 function Core:IsRunning()return self.Running end
 function Core:GetLastReport()return self.LastReport end
 function Core:GetHistory()return self.History end
 function Core:GetState()return self.State end

 function Core:Deflect(dt)
  local character,humanoid,root=rig()
  if not character or not humanoid or not root or not self.LastPosition then return false end
  local now=os.clock()
  local velocity=root.AssemblyLinearVelocity
  local step=math.min(humanoid.WalkSpeed*math.max(dt,1/60)*1.2,2.5)
  local horizontal=humanoid.MoveDirection.Magnitude>0.05 and humanoid.MoveDirection.Unit*step or Vector3.zero
  local targetY=root.Position.Y
  local humanoidState=humanoid:GetState()
  local legitimateJump=(humanoidState==Enum.HumanoidStateType.Jumping or humanoidState==Enum.HumanoidStateType.Freefall) and velocity.Y>0 and velocity.Y<70
  if math.abs(velocity.Y)>70 or (not legitimateJump and math.abs(velocity.Y)>42) then targetY=self.LastPosition.Y end
  local targetPosition=Vector3.new(self.LastPosition.X+horizontal.X,targetY,self.LastPosition.Z+horizontal.Z)
  local targetCFrame=CFrame.new(targetPosition)*root.CFrame.Rotation
  character:PivotTo(targetCFrame)
  zeroCharacter(character)
  root.AssemblyLinearVelocity=humanoid.MoveDirection*math.min(humanoid.WalkSpeed,26)
  root.AssemblyAngularVelocity=Vector3.zero
  self.LastPosition=targetPosition
  self.ThreatUntil=math.max(self.ThreatUntil,now+0.45)
  setState("CONTACT",0.55,"IMPULSE_DEFLECTED")
  return true
 end
 function Core:Correct()
  local character,humanoid,root=rig()
  if not character or not humanoid or not root or not self.SafeCFrame then return false end
  local now=os.clock()
  local returnCFrame=newestSafeBeforeImpact(now) or self.SafeCFrame
  self.SafeCFrame=returnCFrame
  character:PivotTo(returnCFrame)
  zeroCharacter(character)
  table.clear(self.SafeHistory)
  self.LastSafeSample=0
  pushSafePosition(root,now)
  self.LastPosition=returnCFrame.Position
  self.GraceUntil=os.clock()+0.08
  self.RecoveryMinUntil=os.clock()+0.08
  self.RecoveryUntil=os.clock()+0.18
  self.ThreatUntil=math.max(self.ThreatUntil,os.clock()+0.45)
  self.StableSince=0
  self.Corrections+=1
  setState("EMERGENCY",0.8,"POSITION_CORRECTION")
  record("POSITION_CORRECTION",{SafeCFrame=self.SafeCFrame,Correction=self.Corrections})
  return true
 end

 function Core:Start()
  if self.Running then return true end
  if not authorized() then return false,isES and "Función experimental no disponible." or "Experimental feature unavailable." end
  local character,humanoid,root=rig()
  if not character or not humanoid or humanoid.Health<=0 or not root then return false,isES and "Tu personaje no está disponible." or "Your character is unavailable." end
  if AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy) then return false,isES and "Desactiva primero el Ancla automática." or "Disable Automatic Anchor first." end
  if AnchorCore then
   if AnchorCore.TestEnabled then AnchorCore:SetTest(false) end
   if AnchorCore.AnclaEnabled then AnchorCore:SetAncla(false) end
   if AnchorCore.AntiSeatEnabled then AnchorCore:SetAntiSeat(false) end
   if AnchorCore.HeartbeatEnabled then AnchorCore:SetHeartbeat(false) end
  end

  self.Running=true
  self.SafeCFrame=root.CFrame
  self.LastPosition=root.Position
  self.GraceUntil=os.clock()+0.35
  self.RecoveryUntil=0
  self.RecoveryMinUntil=0
  self.ThreatUntil=0
  self.StableSince=os.clock()
  self.Corrections=0
  self.BrokenBridges=0
  self.AntiRamBlocks=0
  self.State="NORMAL"
  self.StateUntil=0
  self.LastThreatScan=0
  self.LastHostileMaintain=0
  table.clear(supports)
  table.clear(hostiles)
  cleanupPhase(os.clock(),true)
  table.clear(self.History)
  self.LastReport=nil
  table.clear(self.SafeHistory)
  self.LastSafeSample=0
  pushSafePosition(root,os.clock())
  lastSpatialScan=0
  lastBridgeScan=0
  lastSupportScan=0

  bindPlayers()
  bindCharacter(character)
  scanCharacterBridges(character)

  runtime[#runtime+1]=workspace.DescendantAdded:Connect(function(object)
   if not self.Running then return end
   if object:IsA("WeldConstraint") or object:IsA("JointInstance") or object:IsA("Constraint") or object:IsA("BodyMover") then
    task.defer(function()if self.Running then inspectBridge(object) end end)
   end
  end)

  runtime[#runtime+1]=humanoid.Seated:Connect(function(active,seat)
   if not self.Running or not active or not seat then return end
   isolateAssembly(seat,"FORCED_SEAT")
   task.defer(function()
    if not self.Running then return end
    scanCharacterBridges(player.Character)
    humanoid.Sit=false
    pcall(function()humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)end)
   end)
  end)

  local preSignal=RunService.PreSimulation or RunService.Stepped
  runtime[#runtime+1]=preSignal:Connect(function()
   if not self.Running then return end
   local currentCharacter,currentHumanoid,currentRoot=rig()
   if currentCharacter and currentHumanoid and currentRoot and currentHumanoid.Health>0 then
    local now=os.clock()
    refreshSupports(now,currentCharacter,currentHumanoid,currentRoot)
    spatialAntiRam(now,currentCharacter,currentRoot)
    scanPlayerThreats(now,currentCharacter)
    maintainHostiles(now)
    clampThreatMotion(currentCharacter,currentHumanoid,currentRoot)
   end
  end)

  runtime[#runtime+1]=RunService.Heartbeat:Connect(function(dt)
   if not self.Running then return end
   if (AnchorCore and (AnchorCore.TestEnabled or AnchorCore.AnclaEnabled)) or (AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)) then self:Stop();return end
   local currentCharacter,currentHumanoid,currentRoot=rig()
   if not currentCharacter or not currentHumanoid or currentHumanoid.Health<=0 or not currentRoot then return end
   local now=os.clock()

   restoreExpiredCollisions(now)
   cleanupPhase(now,false)
   refreshSupports(now,currentCharacter,currentHumanoid,currentRoot)
   maintainHostiles(now)
   if now>=self.StateUntil and next(hostiles)==nil and self.State~="NORMAL" then self.State="NORMAL";record("STATE_CHANGE",{State="NORMAL",Reason="CLEAR"}) end
   local bridgeInterval=now<self.ThreatUntil and 0.08 or 0.25
   if now-lastBridgeScan>=bridgeInterval then lastBridgeScan=now;scanCharacterBridges(currentCharacter) end

   local velocity=currentRoot.AssemblyLinearVelocity
   local angular=currentRoot.AssemblyAngularVelocity.Magnitude
   local delta=self.LastPosition and (currentRoot.Position-self.LastPosition).Magnitude or 0
   local allowed=math.max(5,(currentHumanoid.WalkSpeed+18)*math.max(dt,1/60)*3)
   local threatened=now>self.GraceUntil and (velocity.Magnitude>58 or angular>16 or delta>allowed)
   if threatened then
    self.ThreatUntil=math.max(self.ThreatUntil,now+0.45)
    if delta>22 or (self.SafeCFrame and currentRoot.Position.Y<self.SafeCFrame.Position.Y-30) then
     self:Correct()
    else
     self:Deflect(dt)
     record("IMPULSE_DEFLECTED",{Delta=delta,Velocity=velocity.Magnitude,AngularVelocity=angular})
    end
    return
   end

   if now<self.RecoveryUntil then
    currentCharacter:PivotTo(self.SafeCFrame)
    zeroCharacter(currentCharacter)
    self.LastPosition=self.SafeCFrame.Position
    if now>=self.RecoveryMinUntil and velocity.Magnitude<8 and angular<4 then
     self.RecoveryUntil=0;self.RecoveryMinUntil=0
    else
     return
    end
   end

   self.LastPosition=currentRoot.Position
   local grounded=currentHumanoid.FloorMaterial~=Enum.Material.Air
   local motionStable=grounded and math.abs(velocity.Y)<8 and velocity.Magnitude<math.max(26,currentHumanoid.WalkSpeed+8) and angular<5
   if motionStable then pushSafePosition(currentRoot,now) end
   local stable=motionStable and now>=self.ThreatUntil
   if stable then
    if self.StableSince==0 then self.StableSince=now end
    if now-self.StableSince>=0.18 then self.SafeCFrame=currentRoot.CFrame end
   else
    self.StableSince=0
   end
  end)
  return true
 end

 function Core:Stop()
  if not self.Running then return true end
  self.Running=false
  disconnectRuntime()
  restoreCollisions()
  self.SafeCFrame=nil
  self.LastPosition=nil
  self.GraceUntil=0
  self.RecoveryUntil=0
  self.RecoveryMinUntil=0
  self.ThreatUntil=0
  self.StableSince=0
  self.State="NORMAL"
  self.StateUntil=0
  table.clear(supports)
  table.clear(hostiles)
  cleanupPhase(os.clock(),true)
  table.clear(self.SafeHistory)
  self.LastSafeSample=0
  if UpdateAnchorPanel then task.defer(UpdateAnchorPanel) end
  return true
 end

 function Core:Toggle()if self.Running then return self:Stop()end;return self:Start()end
 function Core:Destroy()
  self:Stop()
  for _,connection in ipairs(persistent) do connection:Disconnect() end
  table.clear(persistent)
 end

 persistent[#persistent+1]=player.CharacterAdded:Connect(function(character)
  if not Core.Running then return end
  disconnectRuntime()
  restoreCollisions()
  local root=character:WaitForChild("HumanoidRootPart",8)
  if root and Core.Running then
   Core.Running=false
   task.defer(function()if root.Parent then Core:Start() end end)
  end
 end)

 MobileAnchorCore=Core
 return true
end