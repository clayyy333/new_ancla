local source,anchorSource=...
setfenv=function()end
local vm={}
Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},vm)end}
Vector3.zero=Vector3.new(0,0,0)
vm.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vm.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__mul=function(a,n)return Vector3.new(a.X*n,a.Y*n,a.Z*n)end
vm.__index=function(a,k)if k=='Magnitude'then return math.sqrt(a.X^2+a.Y^2+a.Z^2)elseif k=='Unit'then local m=a.Magnitude;return m>0 and a*(1/m)or Vector3.zero elseif k=='Dot'then return function(v,b)return v.X*b.X+v.Y*b.Y+v.Z*b.Z end end end
local fm={};fm.__index=fm
CFrame={new=function(x,y,z)return setmetatable({Position=type(x)=='table'and x or Vector3.new(x or 0,y or 0,z or 0)},fm)end}
fm.__mul=function(a,b)return CFrame.new(a.Position+b.Position)end
function fm:ToObjectSpace(b)return CFrame.new(b.Position-self.Position)end
Enum={Material={Water='Water',Air='Air',Concrete='Concrete'},HumanoidRigType={R6='R6',R15='R15'},
 RaycastFilterType={Exclude='Exclude'},HumanoidStateType={Jumping='Jumping',Freefall='Freefall',Running='Running',Swimming='Swimming',Climbing='Climbing'}}
RaycastParams={new=function()return {}end}
local objects={}
local function instance(class,name,parent)
 local o={ClassName=class,Name=name,Parent=parent,CanCollide=true,Anchored=true,AssemblyLinearVelocity=Vector3.zero,AssemblyAngularVelocity=Vector3.zero,CFrame=CFrame.new()}
 function o:IsA(c)return c==class or ((class=='Part'or class=='Seat'or class=='VehicleSeat')and c=='BasePart')or (class=='Weld'and c=='JointInstance')or (class=='NoCollisionConstraint'and c=='Constraint')end
 function o:Destroy()self.Parent=nil;self.Destroyed=true end
 function o:IsDescendantOf(a)local p=self.Parent;while p do if p==a then return true end;p=p.Parent end;return false end
 function o:FindFirstChild(n)for _,p in ipairs(objects)do if p.Parent==self and p.Name==n then return p end end end
 function o:GetChildren()local result={};for _,p in ipairs(objects)do if p.Parent==self then result[#result+1]=p end end;return result end
 objects[#objects+1]=o;return o
end
workspace=instance('Workspace','Workspace');workspace.Gravity=196.2;workspace.FallenPartsDestroyHeight=-500
local character=instance('Model','Character',workspace)
local floor=instance('Part','Floor',workspace)
local cars=instance('Folder','Cars',workspace)
local placed=instance('Folder','ObjectPlaceFolder',workspace)
local terrain=instance('Terrain','Terrain',workspace)
local root=instance('Part','HumanoidRootPart',character);root.Anchored=false;root.Size=Vector3.new(2,2,1)
local h={HipHeight=2,RigType='R15',Health=100,JumpPower=50,UseJumpPower=true,MaxSlopeAngle=45,State='Running'}
function h:GetState()return self.State end
local function position(y)
 root.Position=Vector3.new(0,y,0);root.CFrame=CFrame.new(root.Position)
end
local rayCount=0
local noFloor=false
local queryNormal=Vector3.new(0,1,0)
function workspace:Raycast(origin,direction,params)
 rayCount=rayCount+1
 assert(params.FilterType=='Exclude')
 assert(params.FilterDescendantsInstances[1]==character)
 if noFloor or not floor.Parent then return nil end
 local y=floor.CFrame.Position.Y
 if origin.Y>=y and origin.Y+direction.Y<=y then
  return {Instance=floor,Position=Vector3.new(origin.X,y,origin.Z),Normal=queryNormal,Material='Concrete'}
 end
end
assert(load(source))()(_G)
local function newGuard()
 noFloor=false;queryNormal=Vector3.new(0,1,0);floor.Parent=workspace;floor.CanCollide=true
 floor.CFrame=CFrame.new();floor.AssemblyLinearVelocity=Vector3.zero;floor.AssemblyAngularVelocity=Vector3.zero
 position(3);root.Anchored=false;root.AssemblyLinearVelocity=Vector3.zero
 h.Health=100;h.State='Running';h.Sit=false;h.SeatPart=nil;h.RigType='R15';h.HipHeight=2
 local g=MobileFallGuardFactory.new();g:Reset(character,h,root,0)
 return g
end
local function sample(g,t,p,normal,center)
 g:BeginSample(t)
 g:ObserveSupport({Instance=p or floor,Position=Vector3.new(0,(p or floor).CFrame.Position.Y,0),Normal=normal or Vector3.new(0,1,0),Material='Concrete'},center~=false,h,root)
 g:EndSample()
end
local function seed(g)
 sample(g,0);assert(not g:CommitSafe(0,h,root,true),'do not immediately trust activation position')
 sample(g,.2);assert(g:CommitSafe(.2,h,root,true));assert(#g.History==1)
 g:Step(.2,.02,character,h,root,false)
end
local g=newGuard();assert(#g.History==0)
seed(g)
-- A stable ordinary jump must not be interpreted as a dangerous landing.
position(9);root.AssemblyLinearVelocity=Vector3.new(0,40,0);h.State='Jumping'
assert(not g:Step(.35,.02,character,h,root,false))
position(3.5);root.AssemblyLinearVelocity=Vector3.new(0,-45,0);h.State='Freefall'
assert(not g:Step(.65,.02,character,h,root,false),'respect normal jump budget near the ground')
assert(#g.History==1 and g.History[1].CFrame.Position.Y==3,'airborne motion must not replace safe ground')
-- Deep fall is intercepted even before a surface is within the short probe.
g=newGuard();seed(g)
position(30);root.AssemblyLinearVelocity=Vector3.zero;h.State='Freefall';g:Step(.3,.02,character,h,root,true)
position(20);root.AssemblyLinearVelocity=Vector3.new(0,-50,0)
local unchanged=root.CFrame
local decision=g:Step(.5,.02,character,h,root,true)
assert(decision and decision.Action=='RETURN'and decision.CFrame.Position.Y==3)
assert(decision.Reason=='UNSAFE_DROP'and root.CFrame==unchanged and h.Health==100,'decision helper never writes physics or health')
assert(not g:Step(.51,.01,character,h,root,true),'bound duplicate intervention in pre/post callbacks')
-- Predict dangerous contact with the floor using velocity + gravity.
g=newGuard();seed(g)
position(15);root.AssemblyLinearVelocity=Vector3.zero;h.State='Freefall';g:Step(.3,.02,character,h,root,true)
position(4);root.AssemblyLinearVelocity=Vector3.new(0,-60,0)
decision=g:Step(.6,.04,character,h,root,true)
assert(decision.Action=='RETURN'and decision.PredictedImpact and decision.Reason=='IMPACT_PREDICTED')
-- World kill-plane prediction does not wait for actual crossing.
g=newGuard();seed(g)
position(-480);root.AssemblyLinearVelocity=Vector3.new(0,-30,0);h.State='Freefall'
decision=g:Step(10,.10,character,h,root,true)
assert(decision.Action=='RETURN'and decision.Reason=='VOID_PREDICTED')
-- Midair activation must brake only, never treat the airborne origin as safe.
g=newGuard();position(50);g:Reset(character,h,root,0);h.State='Freefall'
root.AssemblyLinearVelocity=Vector3.new(4,-100,5);g:Step(0,.02,character,h,root,true)
position(48);noFloor=true;decision=g:Step(.02,.02,character,h,root,true)
assert(decision.Action=='BRAKE'and not decision.CFrame and decision.BrakeY==-16 and #g.History==0)
-- Removed floor or an invalid recovery surface cannot be used as a checkpoint.
g=newGuard();seed(g);floor.Parent=nil
position(-3);root.AssemblyLinearVelocity=Vector3.new(0,-100,0)
decision=g:Step(.4,.02,character,h,root,true)
assert(decision.Action=='BRAKE'and not decision.CFrame)
g=newGuard();seed(g);queryNormal=Vector3.new(.9,.4,0)
position(-3);root.AssemblyLinearVelocity=Vector3.new(0,-100,0)
assert(g:Step(.4,.02,character,h,root,true).Action=='BRAKE','revalidate checkpoint slope instead of trusting cached CFrame')
-- Slow platform checkpoints follow support transform and are revalidated there.
g=newGuard();floor.CFrame=CFrame.new(0,10,0);position(13)
sample(g,0);g:CommitSafe(0,h,root,true);sample(g,.2);assert(g:CommitSafe(.2,h,root,true))
floor.CFrame=CFrame.new(0,20,0);floor.AssemblyLinearVelocity=Vector3.new(2,0,0)
assert(g:RecoveryFrame(h,root).Position.Y==23)
-- Bodies, placed tools, vehicle parts, water, noncollidable surfaces and
-- steep normals must not contaminate safe history.
g=newGuard()
local tool=instance('Part','FakeFloor',placed)
local carPart=instance('Part','Collider',cars)
local ownPart=instance('Part','Foot',character)
for _,p in ipairs({tool,carPart,ownPart})do sample(g,0,p);assert(not g.Ground)end
floor.CanCollide=false;sample(g,0);assert(not g.Ground);floor.CanCollide=true
sample(g,0,nil,Vector3.new(.8,.6,0));assert(not g.Ground,'respect humanoid slope limit')
assert(not g:Accept({Instance=terrain,Position=Vector3.zero,Normal=Vector3.new(0,1,0),Material='Water'}))
assert(g:Accept({Instance=terrain,Position=Vector3.zero,Normal=Vector3.new(0,1,0),Material='Concrete'}))
-- One side sample is not enough to assert support at an edge.
sample(g,0,nil,nil,false);assert(not g.Ground)
g:BeginSample(.1)
for i=1,2 do g:ObserveSupport({Instance=floor,Position=Vector3.zero,Normal=Vector3.new(0,1,0),Material='Concrete'},false,h,root)end
g:EndSample();assert(g.Ground)
-- Special movement states and invalid numbers must not trigger a rescue.
for _,state in ipairs({'Swimming','Climbing'})do
 g=newGuard();seed(g);h.State=state;position(-480);root.AssemblyLinearVelocity=Vector3.new(0,-100,0)
 assert(not g:Step(.5,.02,character,h,root,true)and g.Status=='SUSPENDED')
end
g=newGuard();root.AssemblyLinearVelocity=Vector3.new(0/0,-100,0)
assert(not g:Step(.1,.02,character,h,root,true)and g.Status=='INVALID_PHYSICS')
g=newGuard();seed(g);local oldHistory=g.History
local newCharacter=instance('Model','NewCharacter',workspace);local oldCharacter=character;character=newCharacter
local oldRoot=root;root=instance('Part','HumanoidRootPart',character);root.Size=Vector3.new(2,2,1);root.Anchored=false
position(100);root.AssemblyLinearVelocity=Vector3.zero
g:Step(.4,.02,character,h,root,false)
assert(#g.History==0 and g.History~=oldHistory,'never return a respawned character to old-life checkpoints')
character=oldCharacter;root=oldRoot
-- R6 ground clearance includes leg height, unlike R15 HipHeight.
g=newGuard();h.RigType='R6';h.HipHeight=0
local leg=instance('Part','Left Leg',character);leg.Size=Vector3.new(1,2,1)
sample(g,0);assert(g.Ground)
-- Probes are rate-limited; no events or workspace descendant loops are used.
g=newGuard();position(50);g:Reset(character,h,root,0);h.State='Freefall';root.AssemblyLinearVelocity=Vector3.new(0,-20,0)
local before=rayCount
for i=1,10 do g:Step(i*.001,.001,character,h,root,false)end
assert(rayCount-before==1,'reuse predictive probe on rapid callbacks')
print('mobile_fall_guard_spec OK: verified ground, jump tolerance, predictive landing, void, safe returns, platform tracking, exclusions, no-safe braking, respawn, R6 and probe bounds')
if anchorSource then
 -- Exercise the actual v1.3 callbacks too. The harness does not simulate the
 -- server, damage scripts or collision impulses; it checks ordering/lifecycle.
 table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
 vm.__unm=function(v)return Vector3.new(-v.X,-v.Y,-v.Z)end
 local vectorIndex=vm.__index
 vm.__index=function(v,k)if k=='Unit'then return v*(1/v.Magnitude)end;return vectorIndex(v,k)end
 fm.__index=function(v,k)
  if k=='Rotation'then return CFrame.new()end
  if k=='RightVector'then return Vector3.new(1,0,0)end
  if k=='LookVector'then return Vector3.new(0,0,-1)end
  return fm[k]
 end
 local signals={}
 local function signal()
  local callbacks={};local s={}
  function s:Connect(fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;callbacks[#callbacks+1]={c,fn};return c end
  function s:Fire(...)for _,entry in ipairs(callbacks)do if entry[1].Connected then entry[2](...)end end end
  function s:Count()local n=0;for _,entry in ipairs(callbacks)do if entry[1].Connected then n=n+1 end end;return n end
  signals[#signals+1]=s;return s
 end
 local clock=10;os.clock=function()return clock end
 local deferredCalls=0
 task={defer=function(fn)deferredCalls=deferredCalls+1;fn()end}
 newGuard()
 root.CFrame=CFrame.new(root.Position)
 h.MoveDirection=Vector3.zero;h.WalkSpeed=16;h.FloorMaterial='Concrete';h.Parent=character
 h.Seated=signal()
 local seatPartChanged=signal()
 local sitChanged=signal()
 h.StateChanged=signal()
 function h:GetPropertyChangedSignal(name)return name=='Sit'and sitChanged or seatPartChanged end
 function h:ChangeState(state)self.State=state end
 root.Touched=signal()
 local jointScans=0
 function root:GetJoints()jointScans=jointScans+1;return {}end
 local externalConnection=nil
 function root:GetConnectedParts()return externalConnection and {externalConnection}or {}end
 local characterParts={root}
 for i=1,11 do
  local limb=instance('Part','Body'..i,character);limb.Touched=signal()
  function limb:GetJoints()jointScans=jointScans+1;return {}end
  characterParts[#characterParts+1]=limb
 end
 function character:GetDescendants()return characterParts end
 function character:FindFirstChildOfClass(c)if c=='Humanoid'then return h end end
 function character:PivotTo(frame)root.CFrame=frame;root.Position=frame.Position end
 character.DescendantAdded=signal()
 player={Character=character,CharacterAdded=signal()}
 Players={GetPlayers=function()return {player}end,PlayerAdded=signal()}
 workspace.DescendantAdded=signal()
 function workspace:GetPartBoundsInRadius()return {}end
 OverlapParams={new=function()return {}end}
 RunService={PreSimulation=signal(),Heartbeat=signal()}
 local creations={}
 Instance={new=function(class)local o=instance(class,class);creations[#creations+1]=o;return o end}
 MobileAnchorCore={Running=false,IsRunning=function(self)return self.Running end}
 MobileAnchorV11Core={Running=false,IsRunning=function(self)return self.Running end}
 local original10,original11=MobileAnchorCore,MobileAnchorV11Core
 isES=true
 assert(load(anchorSource))()(_G)
 local core=MobileAnchorV13Core
 assert(core.Version=='1.3'and core.BaseVersion=='1.0'and not core.FallProtectionEnabled)
 assert(MobileAnchorCore==original10 and MobileAnchorV11Core==original11,'independent export must never replace original cores')
 local function tick(dt)clock=clock+dt;RunService.PreSimulation:Fire(dt);RunService.Heartbeat:Fire(dt)end
 assert(core:Start())
 -- Walk on verified ground. The first .18s validation must update both paths
 -- immediately, without a second .18s hold of the activation checkpoint.
 for i=1,12 do
  root.Position=Vector3.new(i*.2,3,0);root.CFrame=CFrame.new(root.Position)
  tick(.02)
 end
 assert(core.SafeCFrame.Position.X>0,'verified walking ground must replace the activation checkpoint without a second stability delay')
 local latest=core.SafeHistory[#core.SafeHistory]
 assert(latest and latest.CFrame==core.SafeCFrame,'impact and fall recovery must share the same committed ground sample')
 for i=1,18 do
  root.Position=Vector3.new(2.4+i*.2,3,0);root.CFrame=CFrame.new(root.Position)
  tick(.02)
 end
 latest=core.SafeHistory[#core.SafeHistory]
 assert(clock-latest.Time<.13 and latest.CFrame==core.SafeCFrame and core.SafeCFrame.Position.X>5,'walking must keep both recovery paths current')
 core.ThreatUntil=clock+10
 local oldSafe=core.SafeCFrame
 for i=1,20 do
  root.Position=Vector3.new(6+i*.1,3,0);root.CFrame=CFrame.new(root.Position);tick(.02)
 end
 assert(core.SafeCFrame.Position.X>oldSafe.Position.X,'nearby threats must not freeze verified detached walking')
 -- A valid geometric floor must update even if FloorMaterial lags as Air.
 local beforeAir=core.SafeCFrame.Position.X
 h.FloorMaterial='Air'
 for i=1,25 do
  root.Position=Vector3.new(8+i*.1,3,0);root.CFrame=CFrame.new(root.Position);tick(.02)
 end
 assert(core.SafeCFrame.Position.X>beforeAir+1,'verified ground keeps checkpoint current despite stale FloorMaterial')
 local beforeImpact=core.SafeCFrame
 root.Position=Vector3.new(100,3,0);root.CFrame=CFrame.new(root.Position)
 tick(.02)
 assert(core.SafeCFrame.Position.X<20,'large displacement on floor must not become a safe checkpoint')
 h.FloorMaterial='Concrete'
 externalConnection=instance('Part','ExternalObject',workspace)
 h.Sit=true;h.SeatPart=externalConnection
 oldSafe=core.SafeCFrame
 for i=1,20 do tick(.02)end
 assert(core.SafeCFrame==oldSafe,'seated attachment must never become a checkpoint')
 h.Sit=false;h.SeatPart=nil
 for i=1,20 do tick(.02)end
 assert(core.SafeCFrame==oldSafe,'external weld without seated state must block capture')
 externalConnection=nil;core.ThreatUntil=0
 assert(core.Running and core.FallProtectionEnabled and core:GetFallProtectionStatus().SafePoints>0,'main activation automatically enables fall protection and ground sampling')
 core:ResetFallProtectionReference()
 for i=1,30 do tick(.02)end
 assert(core:GetFallProtectionStatus().SafePoints>0,'existing footprint rays feed verified checkpoint history')
 -- Introduce the dangerous descent directly; the pre-physics guard must act
 -- before v1.0's generic threat clamp hides the vertical velocity.
 position(-3);root.AssemblyLinearVelocity=Vector3.new(0,-100,0);h.State='Freefall';h.FloorMaterial='Air'
 tick(.02)
 assert(math.abs(root.Position.Y-3)<.001,'recovery uses verified ground from the same character')
 local found=false
 for _,entry in ipairs(core.History)do
  if entry.Kind=='FALL_PROTECTION'and entry.Action=='RETURN'then found=true;assert(entry.ServerDamagePrevented=='UNKNOWN')end
 end
 assert(found and core:GetFallProtectionStatus().Recoveries==1,'one recorded fall intervention, not competing pre/post writers')
 core:ResetFallProtectionReference()
 assert(core:GetFallProtectionStatus().SafePoints==0 and core:GetFallProtectionStatus().Recoveries==1,'intentional relocation invalidates checkpoints without losing counters')
 core:Stop()
 assert(not core.Running and not core.FallProtectionEnabled and RunService.PreSimulation:Count()==0 and RunService.Heartbeat:Count()==0,'main stop disables fall protection and all runtime callbacks')
 MobileAnchorCore.Running=true;assert(not core:Start());MobileAnchorCore.Running=false
 MobileAnchorV11Core.Running=true;assert(not core:Start());MobileAnchorV11Core.Running=false
 h.State='Running';h.FloorMaterial='Concrete';root.AssemblyLinearVelocity=Vector3.zero
 assert(core:Start())
 assert(core.FallProtectionEnabled,'each main activation enables integrated protection again')
 -- Urgent seat handling must break the exact local weld before any scan.
 local forcedSeat=instance('Seat','ForcedSeat',workspace)
 forcedSeat.ChildAdded=signal();forcedSeat.AncestryChanged=signal()
 forcedSeat.Position=root.Position;forcedSeat.AssemblyRootPart=forcedSeat
 local connected={forcedSeat}
 for i=1,6 do
  local p=instance('Part','VehicleCollider'..i,workspace)
  p.Position=root.Position;p.AssemblyRootPart=forcedSeat;connected[#connected+1]=p
 end
 local assemblyScans=0
 function forcedSeat:GetConnectedParts()assemblyScans=assemblyScans+1;return connected end
 local function seatWeld()
  local w=instance('Weld','SeatWeld',forcedSeat);w.Part0=forcedSeat;w.Part1=root;return w
 end
 local w=seatWeld()
 h.Sit=true;h.SeatPart=forcedSeat
 local beforeJoints=jointScans
 local beforeCreation=#creations
 h.Seated:Fire(true,forcedSeat)
 assert(w.Destroyed and not h.Sit and core.FastSeatBreaks==1)
 assert(assemblyScans==0 and jointScans==beforeJoints and #creations==beforeCreation,'Seated releases directly without assembly/character scans or phase allocations')
 local beforeDeferred=deferredCalls
 workspace.DescendantAdded:Fire(w);character.DescendantAdded:Fire(w)
 assert(core.FastSeatBreaks==1 and deferredCalls==beforeDeferred,'duplicate destroyed-weld notifications do not schedule repeated inspection')
 local second=seatWeld();workspace.DescendantAdded:Fire(second)
 assert(second.Destroyed and core.FastSeatBreaks==2 and assemblyScans==0,'new weld on same seat is never blocked by deduplication')
 h.Seated:Fire(true,forcedSeat)
 h.SeatPart=nil
 local function constraintsCreated()
  local n=0;for _,p in ipairs(creations)do if p.ClassName=='NoCollisionConstraint'then n=n+1 end end;return n
 end
 local totalBefore=constraintsCreated()
 for i=1,12 do
  local old=constraintsCreated()
  tick(.02)
  assert(constraintsCreated()-old<=8,'phase constraint creation must be bounded per physics frame')
 end
 assert(assemblyScans==1,'one secondary assembly discovery for burst of weld/seat events')
 assert(core.DeferredSeatScans==0,'late duplicate Seated notification must not trigger fallback after an already verified fast release')
 assert(constraintsCreated()-totalBefore==72,'secondary protection eventually covers the same six-by-twelve collision pairs')
 beforeDeferred=deferredCalls
 for _,p in ipairs(creations)do
  if p.ClassName=='NoCollisionConstraint'and p.Parent then
   workspace.DescendantAdded:Fire(p);character.DescendantAdded:Fire(p)
  end
 end
 assert(deferredCalls==beforeDeferred,'own phase constraints must not trigger generic inspection storms')
 local foreignCharacter=instance('Model','OtherCharacter',workspace)
 local foreignRoot=instance('Part','HumanoidRootPart',foreignCharacter)
 local foreignWeld=instance('Weld','SeatWeld',forcedSeat);foreignWeld.Part0=forcedSeat;foreignWeld.Part1=foreignRoot
 workspace.DescendantAdded:Fire(foreignWeld)
 assert(not foreignWeld.Destroyed and core.FastSeatBreaks==2,'never release another character from a seat')
 foreignWeld.Parent=nil
 -- Non-seat external connections retain the original general bridge fallback.
 local otherBridge=instance('Weld','ExternalBridge',forcedSeat);otherBridge.Part0=root;otherBridge.Part1=connected[2]
 workspace.DescendantAdded:Fire(otherBridge)
 assert(otherBridge.Destroyed and core.FastSeatBreaks==2,'general bridge removal remains available')
 -- Missing SeatWeld takes the deferred scan path, not a synchronous full scan.
 beforeJoints=jointScans
 h.Seated:Fire(true,forcedSeat)
 assert(jointScans==beforeJoints,'missing-weld event does not immediately scan the character')
 tick(.10)
 assert(core.DeferredSeatScans>=1 and jointScans>beforeJoints,'one coalesced fallback scan remains for delayed/unusual seat connections')
 -- Learn a custom object joint, then resolve the same structure on a new instance.
 local function customSeat()
  local model=instance('Model','Stroller',workspace)
  local seat=instance('Seat','PassengerSeat',model)
  seat.ChildAdded=signal();seat.AncestryChanged=signal()
  seat.Position=root.Position;seat.AssemblyRootPart=seat
  function seat:GetConnectedParts()return {}end
  local holder=instance('Folder','Connections',model)
  local joint=instance('Weld','PassengerLink',holder)
  joint.Part0=seat;joint.Part1=root
  return seat,joint
 end
 local custom,joint=customSeat()
 beforeJoints=jointScans
 root.AssemblyLinearVelocity=Vector3.new(120,40,0)
 root.AssemblyAngularVelocity=Vector3.new(0,80,0)
 workspace.DescendantAdded:Fire(joint)
 assert(joint.Destroyed and jointScans==beforeJoints,'custom seat joint releases immediately and learns its relative path')
 assert(root.AssemblyLinearVelocity.Magnitude==0 and root.AssemblyAngularVelocity.Magnitude==0,'release must immediately clear residual motion')
 local newSeat,newJoint=customSeat()
 h.Seated:Fire(true,newSeat)
 assert(newJoint.Destroyed and jointScans==beforeJoints,'new object uses learned path without character traversal')
 local foreignSeat,foreignJoint=customSeat();foreignJoint.Part1=foreignRoot
 h.Seated:Fire(true,foreignSeat)
 assert(not foreignJoint.Destroyed,'cached path never bypasses character endpoint verification')
 local earlySeat,earlyJoint=customSeat()
 h.SeatPart=earlySeat;h.Sit=true
 seatPartChanged:Fire()
 assert(earlyJoint.Destroyed and not h.Sit,'SeatPart must release before Seated fires')
 local repeatJoint=instance('Weld','SeatWeld',earlySeat);repeatJoint.Part0=earlySeat;repeatJoint.Part1=root
 earlySeat.ChildAdded:Fire(repeatJoint)
 assert(repeatJoint.Destroyed,'direct seat watcher releases each new weld')
 local delayedJoint=instance('Weld','DelayedPassengerLink',earlySeat)
 earlySeat.ChildAdded:Fire(delayedJoint)
 assert(not delayedJoint.Destroyed,'incomplete joint must wait for verified endpoints')
 delayedJoint.Part0=earlySeat;delayedJoint.Part1=root
 h.Sit=true
 tick(.02)
 assert(delayedJoint.Destroyed and not h.Sit,'physics retry releases late endpoints and custom joint names on the current seat')
 h.SeatPart=nil;seatPartChanged:Fire()
 assert(earlySeat.ChildAdded:Count()==0 and earlySeat.AncestryChanged:Count()==0,'clearing SeatPart disconnects seat observers')
 root.AssemblyLinearVelocity=Vector3.new(15,0,0)
 tick(.02)
 assert(root.AssemblyLinearVelocity.Magnitude==0,'short post-release stabilization clears residual impulse')
 -- Prevention shares the existing nearby query and restores exact seat properties.
 local preventive=instance('Seat','UnknownSeat',workspace)
 preventive.Position=root.Position;preventive.Disabled=false;preventive.CanTouch=true
 preventive.AssemblyRootPart=preventive
 preventive.AssemblyLinearVelocity=Vector3.zero;preventive.AssemblyAngularVelocity=Vector3.zero
 function workspace:GetPartBoundsInRadius()return {preventive}end
 tick(.2)
 assert(preventive.Disabled and not preventive.CanTouch,'nearby unknown seat prevented before sitting')
 preventive.Position=root.Position+Vector3.new(30,0,0);tick(.2)
 assert(not preventive.Disabled and preventive.CanTouch,'seat properties restored outside radius')
 h.Sit=true;sitChanged:Fire();assert(not h.Sit,'Sit property clears immediately')
 Enum.HumanoidStateType.Ragdoll='Ragdoll'
 h.State='Ragdoll';h.StateChanged:Fire()
 assert(h.State==Enum.HumanoidStateType.GettingUp,'ragdoll exits on state event')
 function workspace:GetPartBoundsInRadius()return {}end
 MobileAnchorCore.Running=true;tick(.02);assert(not core.Running,'switching to original core stops v1.3 instead of fighting it')
 MobileAnchorCore.Running=false
 ExperimentalFlingCore={IsAuthorized=function()return true end}
 core:RecordDiagnostic('DIED',{Marker='retained-death'})
 for i=1,200 do core:RecordDiagnostic('SAMPLE')end
 assert(core:GetDiagnosticReport():find('retained%-death'),'death snapshot survives bounded sample eviction')
 ExperimentalFlingCore.IsAuthorized=function()return false end
 assert(core:GetDiagnosticReport()=='Solo owners.','diagnostic access is owner only')
 core:Destroy()
 for _,s in ipairs(signals)do assert(s:Count()==0,'v1.3 must clean up its callbacks')end
 print('mobile_anchor_v13 integration OK: independent version, integrated fall guard, fast verified seat release, deduplication, bounded secondary work, fallback and cleanup')
end
