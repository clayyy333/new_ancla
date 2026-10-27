-- Independent v1.3 based on v1.0, with integrated predictive fall protection.
return function(context)
 setfenv(1,context)

 local Core={
  Version="1.3",BaseVersion="1.0",Running=false,SafeCFrame=nil,LastPosition=nil,GraceUntil=0,Corrections=0,
  StableSince=0,RecoveryUntil=0,RecoveryMinUntil=0,ThreatUntil=0,
  LastReport=nil,History={},SafeHistory={},LastSafeSample=0,BrokenBridges=0,AntiRamBlocks=0,
  State="NORMAL",StateUntil=0,PhaseFolder=nil,LastThreatScan=0,LastHostileMaintain=0,
  FallProtectionEnabled=false,
 }
 local fallGuard=MobileFallGuardFactory.new()
 local persistent,runtime={},{ }
 local collisions={} -- [BasePart]={original=boolean,expires=number,permanent=boolean}
 local supports={} -- [BasePart]=expiry
 local hostiles={} -- [AssemblyRootPart]={expires,seed,reason,lastRecord,parts,phaseParts}
 local phaseLinks={} -- [ExternalPart]={expires,pairs={[CharacterPart]=NoCollisionConstraint}}
 local phaseBodyParts,pendingPhaseParts={},{}
 local phaseBudget=8 -- Maximum new phase constraints per physics frame.
 local pendingSeats={}
 local recentSeats=setmetatable({},{__mode="k"})
 local recentSeatBreaks=setmetatable({},{__mode="k"})
 local handledSeatWelds=setmetatable({},{__mode="k"})
 local pendingBridges=setmetatable({},{__mode="k"})
 local releaseRecovery=nil
 local function stabilizeReleased(character,root)
  if not root or not root.Parent then return end
  local safe=Core.SafeCFrame
  local displaced=safe and (root.Position-safe.Position).Magnitude>6
  root.AssemblyLinearVelocity=Vector3.zero
  root.AssemblyAngularVelocity=Vector3.zero
  releaseRecovery={Character=character,Root=root,Until=os.clock()+.18,Correct=displaced and true or false}
 end
 -- Session-only structural hints: strings/numbers, never retained Instances.
 local seatPatterns,seatPatternOrder={},{}
 local function seatScope(seat)
  local scope=seat.Parent
  if not scope or scope==workspace then scope=seat end
  return scope,scope.ClassName..":"..scope.Name..":"..seat.ClassName..":"..seat.Name
 end
 local function rememberSeatJoint(seat,joint)
  local scope,key=seatScope(seat)
  local path,node={},joint
  while node and node~=scope and #path<8 do
   table.insert(path,1,node.Name);node=node.Parent
  end
  if node~=scope or #path==0 then return end
  if not seatPatterns[key]then
   if #seatPatternOrder>=64 then seatPatterns[table.remove(seatPatternOrder,1)]=nil end
   seatPatternOrder[#seatPatternOrder+1]=key
  end
  seatPatterns[key]={Path=path,Class=joint.ClassName}
 end
 local lastSpatialScan=0
 local lastBridgeScan=0
 local lastSupportScan=0
 local safeCaptureBlockedUntil=0
 local lastCaptureScan=-math.huge
 local captureDetached=false

 local function authorized()return true end

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
  if Core.RecordDiagnostic then Core:RecordDiagnostic(kind,data)end
 end
 local diagnosticLines,deathReport={},nil
 local lastDiagnosticSample=-math.huge
 local function diagnosticOwner()
  return ExperimentalFlingCore and ExperimentalFlingCore:IsAuthorized()
 end
 function Core:RecordDiagnostic(kind,data)
  if not diagnosticOwner()then return end
  local c,h,r=rig()
  local fields={string.format("t=%.4f %s",os.clock(),kind),"Health="..tostring(h and h.Health),
   "Position="..tostring(r and r.Position),"Linear="..tostring(r and r.AssemblyLinearVelocity),
   "Angular="..tostring(r and r.AssemblyAngularVelocity),"Anchored="..tostring(r and r.Anchored),
   "Seat="..tostring(h and h.SeatPart),"Sit="..tostring(h and h.Sit),"Safe="..tostring(self.SafeCFrame)}
  if h then fields[#fields+1]="State="..tostring(h:GetState())end
  for key,value in pairs(data or {})do fields[#fields+1]=tostring(key).."="..tostring(value)end
  diagnosticLines[#diagnosticLines+1]=table.concat(fields," | ")
  if #diagnosticLines>180 then table.remove(diagnosticLines,1)end
  if kind=="DIED"then deathReport=table.concat(diagnosticLines,"\n")end
 end
 function Core:GetDiagnosticReport()
  if not diagnosticOwner()then return "Solo owners."end
  return "MUEVETE ANCLADO 1.3 | Observaciones locales; no demuestran causa del servidor\n"..
   "Running="..tostring(self.Running).." | muestras cada 0.1 s; eventos inmediatos\n"..
   (deathReport and "ULTIMA MUERTE (conservada):\n"..deathReport.."\n"or "Sin muerte registrada.\n")..
   "EVENTOS RECIENTES:\n"..table.concat(diagnosticLines,"\n")
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
  Core.PhaseFolder=folder
  folder.Parent=character
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
  local incomplete=false
  for _,bodyPart in ipairs(phaseBodyParts) do
   if count>=12 then break end
   if belongsTo(bodyPart,character) and not state.pairs[bodyPart] then
    if phaseBudget<=0 then incomplete=true;break end
    local ok,constraint=pcall(function()
     local noCollision=Instance.new("NoCollisionConstraint")
     noCollision.Part0=bodyPart
     noCollision.Part1=externalPart
     noCollision.Parent=folder
     return noCollision
    end)
    if ok and constraint then state.pairs[bodyPart]=constraint;count+=1;phaseBudget=phaseBudget-1 end
   end
  end
  if incomplete and not state.Pending then state.Pending=true;pendingPhaseParts[#pendingPhaseParts+1]=externalPart end
 end

 local function finishPendingPhases(now)
  local attempts=#pendingPhaseParts
  while phaseBudget>0 and attempts>0 and #pendingPhaseParts>0 do
   attempts=attempts-1
   local part=table.remove(pendingPhaseParts,1)
   local state=phaseLinks[part]
   if state then
    state.Pending=false
    if part.Parent and now<state.expires then phasePart(part,math.max(.2,state.expires-now))end
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
  if force then table.clear(pendingPhaseParts)end
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
  if part.CanCollide then pcall(function()part.CanCollide=false end)end
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
 local function pushSafePosition(root,now,verifiedFrame)
  if not root or now-Core.LastSafeSample<0.05 then return end
  Core.LastSafeSample=now
  Core.SafeHistory[#Core.SafeHistory+1]={CFrame=verifiedFrame or root.CFrame,Time=now}
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
  local params=Core.FallProtectionEnabled and fallGuard:Params()or RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Exclude
  local excluded={character}
  for _,name in ipairs({"Cars","ObjectPlaceFolder"})do
   local folder=workspace:FindFirstChild(name);if folder then excluded[#excluded+1]=folder end
  end
  for _,other in ipairs(Players:GetPlayers())do
   if other.Character and other.Character~=character then excluded[#excluded+1]=other.Character end
  end
  params.FilterDescendantsInstances=excluded
  params.IgnoreWater=false;params.RespectCanCollide=true
  local right=root.CFrame.RightVector*1.15
  local forward=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
  if forward.Magnitude>0.001 then forward=forward.Unit*1.15 else forward=Vector3.new(0,0,-1.15) end
  local origins={Vector3.zero,right,-right,forward,-forward}
  local length=math.max(5.5,humanoid.HipHeight+root.Size.Y*0.5+3)
  if Core.FallProtectionEnabled then fallGuard:BeginSample(now)end
  for index,offset in ipairs(origins) do
   local result=workspace:Raycast(root.Position+offset+Vector3.new(0,0.5,0),Vector3.new(0,-length,0),params)
   local part=result and result.Instance
   if Core.FallProtectionEnabled and part and not isOtherCharacterPart(part)then
    fallGuard:ObserveSupport(result,index==1,humanoid,root)
   end
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
  if Core.FallProtectionEnabled then fallGuard:EndSample()end
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
  -- Multiple touch/bridge/seat notifications for the same cached assembly
  -- extend its lifetime, but do not repeat a complete part pass immediately.
  if not isNew and hostile.lastPass and now-hostile.lastPass<.08 then
   for _,part in ipairs(hostile.phaseParts)do
    local phase=phaseLinks[part];if phase then phase.expires=math.max(phase.expires,hostile.expires)end
   end
   Core.ThreatUntil=math.max(Core.ThreatUntil,now+.45)
   return true
  end
  hostile.lastPass=now
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
      if collision then collision.expires=math.max(collision.expires,state.expires)end
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

 local function queueSeatIsolation(seat,needsScan)
  local now=os.clock()
  if needsScan and now-(recentSeatBreaks[seat]or -math.huge)<.08 then needsScan=false end
  local entry=pendingSeats[seat]
  if entry then entry.NeedsScan=entry.NeedsScan or needsScan;return end
  if now-(recentSeats[seat]or -math.huge)<.08 then return end
  local count=0;for _ in pairs(pendingSeats)do count=count+1 end
  if count>=16 then return end -- Direct release is never skipped by this bound.
  pendingSeats[seat]={NeedsScan=needsScan};recentSeats[seat]=now
 end

 local function releaseSeatWeld(weld,expectedSeat)
  if not Core.Running or not weld then return false end
  if handledSeatWelds[weld]then return true end
  if not weld.Parent or weld:IsA("Motor6D")or weld.Name=="AccessoryWeld"then return false end
  if not (weld:IsA("JointInstance")or weld:IsA("WeldConstraint"))then return false end
  local character,humanoid,root=rig()
  if not character or not humanoid then return false end
  local p,q=endpoints(weld)
  if not p or not q then return false end
  local insideP,insideQ=belongsTo(p,character),belongsTo(q,character)
  if insideP==insideQ then return false end
  local seat=insideP and q or p
  if not (seat:IsA("Seat")or seat:IsA("VehicleSeat"))or (expectedSeat and seat~=expectedSeat)then return false end
  if diagnosticOwner()then Core:RecordDiagnostic("BEFORE_SEAT_RELEASE",{Joint=weld:GetFullName(),Class=weld.ClassName,Part0=p:GetFullName(),Part1=q:GetFullName()})end
  rememberSeatJoint(seat,weld)
  handledSeatWelds[weld]=true
  lastCaptureScan=-math.huge
  safeCaptureBlockedUntil=os.clock()+.18
  local ok=pcall(function()weld:Destroy()end)
  if not ok then handledSeatWelds[weld]=nil;return false end
  stabilizeReleased(character,root)
  recentSeatBreaks[seat]=os.clock()
  -- Urgent path: no GetConnectedParts, character scan or constraint creation.
  humanoid.Sit=false
  pcall(function()humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)end)
  suppressPart(seat,3,false)
  Core.BrokenBridges=Core.BrokenBridges+1
  Core.FastSeatBreaks=Core.FastSeatBreaks+1
  Core.ThreatUntil=math.max(Core.ThreatUntil,os.clock()+.65)
  setState("CONTACT",.65,"FAST_SEAT_RELEASE")
  record("FAST_SEAT_RELEASE",{DirectBridge=weld,ExternalEndpoint=seat})
  queueSeatIsolation(seat,false)
  return true
 end

 local function releaseKnownSeat(seat)
  if releaseSeatWeld(seat:FindFirstChild("SeatWeld"),seat)then return true end
  -- Object seats may use another joint name or finish replicating endpoints later.
  -- Only inspect this seat's direct children, never the whole Workspace.
  for _,joint in ipairs(seat:GetChildren())do
   if releaseSeatWeld(joint,seat)then return true end
  end
  local scope,key=seatScope(seat)
  local pattern=seatPatterns[key]
  if not pattern then return false end
  local joint=scope
  for _,name in ipairs(pattern.Path)do
   joint=joint:FindFirstChild(name)
   if not joint then return false end
  end
  -- A path match is only a hint; releaseSeatWeld revalidates both endpoints.
  if joint.ClassName~=pattern.Class then return false end
  return releaseSeatWeld(joint,seat)
 end

 local function inspectBridge(connection)
  if not Core.Running or not connection or not connection.Parent then return false end
  local character=player.Character
  if not character then return false end
  if belongsTo(connection,Core.PhaseFolder)then return false end
  if releaseSeatWeld(connection)then return true end
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
  lastCaptureScan=-math.huge
  safeCaptureBlockedUntil=os.clock()+.18
  local characterEndpoint=inside0 and part0 or part1
  local externalEndpoint=inside0 and part1 or part0
  if diagnosticOwner()then Core:RecordDiagnostic("BEFORE_BRIDGE_RELEASE",{Joint=connection:GetFullName(),Class=connection.ClassName,Part0=part0:GetFullName(),Part1=part1:GetFullName()})end
  local report={
   DirectBridge=connection,BridgeClass=connection.ClassName,
   CharacterEndpoint=characterEndpoint,ExternalEndpoint=externalEndpoint,
   ExternalAssemblyRoot=externalEndpoint.AssemblyRootPart,
   ExternalContainer=externalContainer(externalEndpoint),
   ConnectionType="CHARACTER_EXTERNAL_BRIDGE",
  }
  -- Release first. Assembly discovery must never delay breaking the bridge.
  local removed=pcall(function()connection:Destroy()end)
  if not removed then return false end
  stabilizeReleased(character,character:FindFirstChild("HumanoidRootPart"))
  pendingBridges[externalEndpoint]=true
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

 local function processPendingSeat(now)
  -- At most one assembly discovery per frame. Direct weld release already ran.
  local seat,entry=next(pendingSeats)
  if not seat then return end
  pendingSeats[seat]=nil
  if not seat.Parent then return end
  recentSeats[seat]=now
  local broken=releaseKnownSeat(seat)
  if entry.NeedsScan and not broken then
   Core.DeferredSeatScans=Core.DeferredSeatScans+1
   scanCharacterBridges(player.Character)
  end
  isolateAssembly(seat,"FORCED_SEAT")
 end

 local function bindCharacter(character)
  if not character then return end
  for _,object in ipairs(character:GetDescendants()) do
   if object:IsA("BasePart") then
    if #phaseBodyParts<12 then phaseBodyParts[#phaseBodyParts+1]=object end
    runtime[#runtime+1]=object.Touched:Connect(function(other)
     if not Core.Running or not other or belongsTo(other,character) then return end
     local relative=(other.AssemblyLinearVelocity-object.AssemblyLinearVelocity).Magnitude
     local angular=other.AssemblyAngularVelocity.Magnitude
     if relative>24 or angular>9 then isolateAssembly(other,"TOUCHED") end
    end)
   end
  end
  runtime[#runtime+1]=character.DescendantAdded:Connect(function(object)
   if belongsTo(object,Core.PhaseFolder)then return end
   if object:IsA("BasePart") then
    if #phaseBodyParts<12 then phaseBodyParts[#phaseBodyParts+1]=object end
    runtime[#runtime+1]=object.Touched:Connect(function(other)
     if Core.Running and other and not belongsTo(other,character) then
      local relative=(other.AssemblyLinearVelocity-object.AssemblyLinearVelocity).Magnitude
      if relative>24 or other.AssemblyAngularVelocity.Magnitude>9 then isolateAssembly(other,"TOUCHED_NEW_PART") end
     end
    end)
   end
   if not releaseSeatWeld(object)then task.defer(function()if Core.Running then inspectBridge(object) end end)end
  end)
 end

 -- Seat prevention supplements existing selective collision protection; never noclip the floor.
 local preventionSeats,knownPreventionSeats={},{}
 local scannedSeatObjects=setmetatable({},{__mode="k"})
 local knownSeatObjects={Babycar_a=true,Babycar_b=true,Babycar_c=true,Stretcher=true,FoldingTable_1=true,Folding_table_02=true}
 local function knownSeatObject(part)
  local n=part
  while n and n~=workspace do if knownSeatObjects[n.Name]then return n end;n=n.Parent end
 end
 local function rememberPreventionSeat(part)
  if (part:IsA("Seat")or part:IsA("VehicleSeat"))and knownSeatObject(part)then knownPreventionSeats[part]=true end
 end
 local function restorePreventionSeat(seat,state)
  if seat.Parent then pcall(function()seat.Disabled=state.Disabled;seat.CanTouch=state.CanTouch end)end
  preventionSeats[seat]=nil
 end
 local function clearSeatPrevention()
  for seat,state in pairs(preventionSeats)do restorePreventionSeat(seat,state)end
  table.clear(knownPreventionSeats);scannedSeatObjects=setmetatable({},{__mode="k"})
 end
 local function preventNearbySeat(seat,character,root)
  if not seat.Parent or seat:IsDescendantOf(character)or (seat.Position-root.Position).Magnitude>15 then return end
  if not preventionSeats[seat]then preventionSeats[seat]={Disabled=seat.Disabled,CanTouch=seat.CanTouch}end
  seat.Disabled=true;seat.CanTouch=false
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
  for seat,state in pairs(preventionSeats)do
   if not seat:IsDescendantOf(workspace)or (seat.Position-root.Position).Magnitude>15 then restorePreventionSeat(seat,state)end
  end
  for seat in pairs(knownPreventionSeats)do
   if seat:IsDescendantOf(workspace)then preventNearbySeat(seat,character,root)else knownPreventionSeats[seat]=nil end
  end
  if not ok then return end
  local checked={}
  for _,part in ipairs(nearby) do
   local container=knownSeatObject(part)
   if container and not scannedSeatObjects[container]then
    scannedSeatObjects[container]=true
    for _,descendant in ipairs(container:GetDescendants())do
     rememberPreventionSeat(descendant)
     if knownPreventionSeats[descendant]then preventNearbySeat(descendant,character,root)end
    end
   end
   if part:IsA("Seat")or part:IsA("VehicleSeat")then preventNearbySeat(part,character,root)end
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
  if self.FallProtectionEnabled then fallGuard:Recovered(now,root)end
  self.ThreatUntil=math.max(self.ThreatUntil,now+0.45)
  setState("CONTACT",0.55,"IMPULSE_DEFLECTED")
  return true
 end
 function Core:Correct(verifiedFrame,reason)
  local character,humanoid,root=rig()
  if not character or not humanoid or not root or not self.SafeCFrame then return false end
  local now=os.clock()
  local returnCFrame=verifiedFrame or newestSafeBeforeImpact(now) or self.SafeCFrame
  self.SafeCFrame=returnCFrame
  character:PivotTo(returnCFrame)
  zeroCharacter(character)
  table.clear(self.SafeHistory)
  self.LastSafeSample=0
  pushSafePosition(root,now)
  self.LastPosition=returnCFrame.Position
  if self.FallProtectionEnabled then fallGuard:Recovered(now,root)end
  self.GraceUntil=os.clock()+0.08
  self.RecoveryMinUntil=os.clock()+0.08
  self.RecoveryUntil=os.clock()+0.18
  self.ThreatUntil=math.max(self.ThreatUntil,os.clock()+0.45)
  self.StableSince=0
  self.Corrections+=1
  setState("EMERGENCY",0.8,reason or "POSITION_CORRECTION")
  record("POSITION_CORRECTION",{SafeCFrame=self.SafeCFrame,Correction=self.Corrections,Reason=reason})
  return true
 end

 function Core:GetFallProtectionStatus()
  return {Enabled=self.FallProtectionEnabled,Status=fallGuard.Status,SafePoints=#fallGuard.History,Recoveries=fallGuard.Recoveries or 0,Brakes=fallGuard.Brakes or 0}
 end
 function Core:ResetFallProtectionReference()
  local character,humanoid,root=rig()
  local recoveries,brakes=fallGuard.Recoveries,fallGuard.Brakes
  fallGuard:Reset(character,humanoid,root,os.clock())
  fallGuard.Recoveries=recoveries or 0;fallGuard.Brakes=brakes or 0
  lastSupportScan=0
 end
 local function protectFall(now,dt,character,humanoid,root)
  if not Core.FallProtectionEnabled then return false end
  local decision=fallGuard:Step(now,dt,character,humanoid,root,now<Core.ThreatUntil)
  if not decision then return false end
  if decision.Action=="RETURN"then
   Core:Correct(decision.CFrame,decision.Reason)
  else
   -- A verified floor is mandatory for returns. If enabled in midair, only
   -- brake descent; never invent a safe checkpoint at the activation position.
   local v=root.AssemblyLinearVelocity
   root.AssemblyLinearVelocity=Vector3.new(v.X,decision.BrakeY,v.Z)
   Core.LastPosition=root.Position
  end
  record("FALL_PROTECTION",{Action=decision.Action,Reason=decision.Reason,DownSpeed=decision.DownSpeed,Drop=decision.Drop,Horizon=decision.Horizon,PredictedImpact=decision.PredictedImpact,SafePoints=#fallGuard.History,ServerDamagePrevented="UNKNOWN"})
  if UpdateMoveAnchoredPanel then UpdateMoveAnchoredPanel()end
  return true
 end

 function Core:Start()
  if MobileAnchorCore and MobileAnchorCore:IsRunning()then return false,isES and "Desactiva primero Muevete Anclado v1.0."or "Disable Move While Anchored v1.0 first."end
  if MobileAnchorV11Core and MobileAnchorV11Core:IsRunning() then return false,isES and "Desactiva primero Muévete Anclado v1.1." or "Disable Move While Anchored v1.1 first." end
  if self.Running then return true end
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
  self.FallProtectionEnabled=true
  self.SafeCFrame=root.CFrame
  self.LastPosition=root.Position
  self.GraceUntil=os.clock()+0.35
  self.RecoveryUntil=0
  self.RecoveryMinUntil=0
  self.ThreatUntil=0
  safeCaptureBlockedUntil=0;lastCaptureScan=-math.huge;captureDetached=false
  self.StableSince=os.clock()
  self.Corrections=0
  self.BrokenBridges=0
  self.AntiRamBlocks=0
  self.FastSeatBreaks=0;self.DeferredSeatScans=0
  table.clear(pendingSeats);table.clear(phaseBodyParts)
  recentSeats=setmetatable({},{__mode="k"});recentSeatBreaks=setmetatable({},{__mode="k"});handledSeatWelds=setmetatable({},{__mode="k"})
  phaseBudget=8
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
  fallGuard:Reset(character,humanoid,root,os.clock())

  bindPlayers()
  bindCharacter(character)
  scanCharacterBridges(character)
  if diagnosticOwner()then
   self:RecordDiagnostic("START")
   runtime[#runtime+1]=humanoid.HealthChanged:Connect(function(value)self:RecordDiagnostic("HEALTH_CHANGED",{HealthEvent=value})end)
   runtime[#runtime+1]=humanoid.Died:Connect(function()self:RecordDiagnostic("DIED")end)
  end

  runtime[#runtime+1]=workspace.DescendantAdded:Connect(function(object)
   if not self.Running then return end
   rememberPreventionSeat(object)
   if belongsTo(object,Core.PhaseFolder)then return end
   if releaseSeatWeld(object)then return end
   if object:IsA("WeldConstraint") or object:IsA("JointInstance") or object:IsA("Constraint") or object:IsA("BodyMover") then
    task.defer(function()if self.Running then inspectBridge(object) end end)
   end
  end)

  -- Existing equipped known objects are registered once; new descendants use events.
  for _,other in ipairs(Players:GetPlayers())do
   if other.Character and other.Character~=character then
    for _,part in ipairs(other.Character:GetDescendants())do rememberPreventionSeat(part)end
   end
  end
  local postureGuard=false
  local function recoverPosture()
   if postureGuard or not self.Running then return end
   local state=humanoid:GetState()
   if not humanoid.Sit and state~=Enum.HumanoidStateType.Seated and state~=Enum.HumanoidStateType.Ragdoll and state~=Enum.HumanoidStateType.FallingDown then return end
   postureGuard=true
   if humanoid.SeatPart then
    if not releaseKnownSeat(humanoid.SeatPart)then queueSeatIsolation(humanoid.SeatPart,true)end
   end
   humanoid.Sit=false
   humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
   postureGuard=false
  end
  runtime[#runtime+1]=humanoid:GetPropertyChangedSignal("Sit"):Connect(recoverPosture)
  runtime[#runtime+1]=humanoid.StateChanged:Connect(recoverPosture)
  -- One current SeatPart observer; no per-player or Workspace polling.
  local watchedSeat,seatConnections=nil,{}
  local function clearSeatWatch()
   for _,connection in ipairs(seatConnections)do connection:Disconnect()end
   table.clear(seatConnections);watchedSeat=nil
  end
  runtime[#runtime+1]={Disconnect=clearSeatWatch}
  local function watchSeat(seat)
   if watchedSeat==seat then return end
   clearSeatWatch()
   if not seat or not seat.Parent or not(seat:IsA("Seat")or seat:IsA("VehicleSeat"))then return end
   watchedSeat=seat
   seatConnections[#seatConnections+1]=seat.ChildAdded:Connect(function(object)
    if self.Running and watchedSeat==seat then releaseSeatWeld(object,seat)end
   end)
   seatConnections[#seatConnections+1]=seat.AncestryChanged:Connect(function()
    if not seat.Parent then clearSeatWatch()end
   end)
  end
  local function earlySeatPart()
   if not self.Running then return end
   local seat=humanoid.SeatPart
   watchSeat(seat)
   if not watchedSeat then return end
   self:RecordDiagnostic("SEATPART_EARLY")
   if not releaseKnownSeat(seat)then queueSeatIsolation(seat,true)end
   humanoid.Sit=false
   pcall(function()humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)end)
  end
  runtime[#runtime+1]=humanoid:GetPropertyChangedSignal("SeatPart"):Connect(earlySeatPart)
  earlySeatPart()
  runtime[#runtime+1]=humanoid.Seated:Connect(function(active,seat)
   if not self.Running or not active or not seat then return end
   watchSeat(seat)
   if not releaseKnownSeat(seat)then
    queueSeatIsolation(seat,true)
    humanoid.Sit=false
    pcall(function()humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)end)
   end
  end)

  local preSignal=RunService.PreSimulation or RunService.Stepped
  runtime[#runtime+1]=preSignal:Connect(function(timeOrDt,stepDt)
   local dt=stepDt or timeOrDt
   if not self.Running then return end
   phaseBudget=8
   local currentCharacter,currentHumanoid,currentRoot=rig()
   if currentCharacter and currentHumanoid and currentRoot and currentHumanoid.Health>0 then
    local now=os.clock()
    local activeSeat=currentHumanoid.SeatPart
    if activeSeat and activeSeat.Parent then
     releaseKnownSeat(activeSeat)
     currentHumanoid.Sit=false
     pcall(function()currentHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)end)
    end
    if diagnosticOwner()and now-lastDiagnosticSample>=.1 then
     lastDiagnosticSample=now;self:RecordDiagnostic("SAMPLE")
    end
    local recovery=releaseRecovery
    if recovery then
     if recovery.Character~=currentCharacter or recovery.Root~=currentRoot or now>=recovery.Until then
      releaseRecovery=nil
     else
      local unsafe=currentRoot.AssemblyLinearVelocity.Magnitude>58 or currentRoot.AssemblyAngularVelocity.Magnitude>16
      if recovery.Correct or unsafe then
       self:Correct(nil,"EXTERNAL_BRIDGE_RELEASE")
       recovery.Correct=false
      end
      currentRoot.AssemblyLinearVelocity=Vector3.zero
      currentRoot.AssemblyAngularVelocity=Vector3.zero
     end
    end
    processPendingSeat(now)
    local external=next(pendingBridges)
    if external then
     pendingBridges[external]=nil
     if external.Parent then isolateAssembly(external,"DIRECT_BRIDGE")end
    end
    finishPendingPhases(now)
    refreshSupports(now,currentCharacter,currentHumanoid,currentRoot)
    -- Run before the existing clamp can hide the incoming downward speed.
    if protectFall(now,dt,currentCharacter,currentHumanoid,currentRoot)then return end
    spatialAntiRam(now,currentCharacter,currentRoot)
    scanPlayerThreats(now,currentCharacter)
    maintainHostiles(now)
    clampThreatMotion(currentCharacter,currentHumanoid,currentRoot)
   end
  end)

  runtime[#runtime+1]=RunService.Heartbeat:Connect(function(dt)
   if not self.Running then return end
   if (MobileAnchorCore and MobileAnchorCore:IsRunning()) or (MobileAnchorV11Core and MobileAnchorV11Core:IsRunning()) or (AnchorCore and (AnchorCore.TestEnabled or AnchorCore.AnclaEnabled)) or (AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)) then self:Stop();return end
   local currentCharacter,currentHumanoid,currentRoot=rig()
   if not currentCharacter or not currentHumanoid or currentHumanoid.Health<=0 or not currentRoot then return end
   local now=os.clock()

   restoreExpiredCollisions(now)
   cleanupPhase(now,false)
   refreshSupports(now,currentCharacter,currentHumanoid,currentRoot)
   if protectFall(now,dt,currentCharacter,currentHumanoid,currentRoot)then return end
   maintainHostiles(now)
   if now>=self.StateUntil and next(hostiles)==nil and self.State~="NORMAL" then self.State="NORMAL";record("STATE_CHANGE",{State="NORMAL",Reason="CLEAR"}) end
   local bridgeInterval=now<self.ThreatUntil and 0.08 or 0.25
   if now-lastBridgeScan>=bridgeInterval then lastBridgeScan=now;scanCharacterBridges(currentCharacter) end

   local velocity=currentRoot.AssemblyLinearVelocity
   local angular=currentRoot.AssemblyAngularVelocity.Magnitude
   local delta=self.LastPosition and (currentRoot.Position-self.LastPosition).Magnitude or 0
   local allowed=math.max(5,(currentHumanoid.WalkSpeed+18)*math.max(dt,1/60)*3)
   local grounded=(self.FallProtectionEnabled and fallGuard:Grounded(now,currentHumanoid,currentRoot))or currentHumanoid.FloorMaterial~=Enum.Material.Air
   local motionStable=grounded and math.abs(velocity.Y)<8 and velocity.Magnitude<math.max(26,currentHumanoid.WalkSpeed+8) and angular<5
   if self.FallProtectionEnabled then
    local hadSafe=#fallGuard.History>0
    -- Nearby threats alone must not freeze walking checkpoints. Check actual
    -- attachment only when a new ground sample is due, never scan Workspace.
    local captureSafe=delta<=allowed and now>=self.RecoveryUntil and motionStable and not currentHumanoid.Sit and not currentHumanoid.SeatPart and now>=safeCaptureBlockedUntil
    if captureSafe and now-lastCaptureScan>=.10 then
     lastCaptureScan=now
     local ok,parts=pcall(function()return currentRoot:GetConnectedParts(true)end)
     captureDetached=ok
     if ok then
      for _,part in ipairs(parts)do
       if not belongsTo(part,currentCharacter)then captureDetached=false;break end
      end
     end
    end
    local verified=fallGuard:CommitSafe(now,currentHumanoid,currentRoot,captureSafe and captureDetached)
    if verified then
     -- CommitSafe has already confirmed continuous stable ground. Use its
     -- actual latest sample for both recovery paths; do not wait another .18s.
     local sample=fallGuard.History[#fallGuard.History]
     if sample then
      self.SafeCFrame=sample.CFrame
      pushSafePosition(currentRoot,sample.Time,sample.CFrame)
     end
    end
    if verified and not hadSafe then
     record("FALL_SAFE_GROUND",{SafeCFrame=currentRoot.CFrame})
     if UpdateMoveAnchoredPanel then UpdateMoveAnchoredPanel()end
    end
   else
    if motionStable then pushSafePosition(currentRoot,now) end
    local stable=motionStable and now>=self.ThreatUntil
    if stable then
     if self.StableSince==0 then self.StableSince=now end
     if now-self.StableSince>=0.18 then self.SafeCFrame=currentRoot.CFrame end
    else
     self.StableSince=0
    end
   end
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

  end)
  if UpdateMoveAnchoredPanel then task.defer(UpdateMoveAnchoredPanel) end
  if UpdateAnchorPanel then task.defer(UpdateAnchorPanel) end
  if UpdateAutoAnchorPanel then task.defer(UpdateAutoAnchorPanel) end
  return true
 end

 function Core:Stop()
  clearSeatPrevention()
  releaseRecovery=nil;table.clear(pendingBridges)
  if not self.Running then return true end
  self.Running=false
  self.FallProtectionEnabled=false
  disconnectRuntime()
  table.clear(pendingSeats);table.clear(phaseBodyParts)
  table.clear(recentSeats);table.clear(recentSeatBreaks);table.clear(handledSeatWelds)
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
  fallGuard:Reset(nil,nil,nil,os.clock())
  if UpdateMoveAnchoredPanel then task.defer(UpdateMoveAnchoredPanel) end
  if UpdateAnchorPanel then task.defer(UpdateAnchorPanel) end
  if UpdateAutoAnchorPanel then task.defer(UpdateAutoAnchorPanel) end
  return true
 end

 function Core:Toggle()if self.Running then return self:Stop()end;return self:Start()end
 function Core:Destroy()
  self:Stop()
  table.clear(seatPatterns);table.clear(seatPatternOrder)
  table.clear(diagnosticLines);deathReport=nil
  for _,connection in ipairs(persistent) do connection:Disconnect() end
  table.clear(persistent)
 end

 persistent[#persistent+1]=player.CharacterAdded:Connect(function(character)
  if not Core.Running then return end
  disconnectRuntime()
  clearSeatPrevention()
  restoreCollisions()
  local root=character:WaitForChild("HumanoidRootPart",8)
  if root and Core.Running then
   Core.Running=false
   task.defer(function()if root.Parent then Core:Start() end end)
  end
 end)

 MobileAnchorV13Core=Core
 return true
end
