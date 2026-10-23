local source,source2=...
setfenv=function()end
table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
local now=1;os.clock=function()return now end
local signals={}
local function signal()
 local entries={};local s={}
 function s:Connect(fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;entries[#entries+1]={c,fn};return c end
 function s:Fire(...)local copy={};for i,e in ipairs(entries)do copy[i]=e end;for _,e in ipairs(copy)do if e[1].Connected then e[2](...)end end end
 function s:Count()local n=0;for _,e in ipairs(entries)do if e[1].Connected then n=n+1 end end;return n end
 signals[#signals+1]=s;return s
end
local vm={}
Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},vm)end};Vector3.zero=Vector3.new(0,0,0)
vm.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vm.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__mul=function(a,b)return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
vm.__index=function(a,k)if k=='Magnitude'then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
local fm={}
CFrame={new=function(x,y,z)return setmetatable({Position=type(x)=='table'and x or Vector3.new(x or 0,y or 0,z or 0)},fm)end}
fm.__mul=function(a,b)return CFrame.new(a.Position+b.Position)end
fm.__index=function(_,k)if k=='Rotation'then return CFrame.new()end end
function fm:PointToObjectSpace(v)return v-self.Position end
function fm:PointToWorldSpace(v)return v+self.Position end
function fm:VectorToObjectSpace(v)return v end
function fm:VectorToWorldSpace(v)return v end
local frameIndex=fm.__index
fm.__index=function(a,k)return fm[k]or frameIndex(a,k)end
local created={}
local function instance(class,name,parent)
 local data={ClassName=class,Name=name or class,Parent=parent,items={},attributes={},ChildAdded=signal(),DescendantAdded=signal(),Size=Vector3.new(2,2,2),Position=Vector3.zero,CFrame=CFrame.new(),CanCollide=true,Anchored=false,Health=100,AutoRotate=true,PlatformStand=false}
 local item=setmetatable({}, {__index=function(_,key)
  if data.PoseRoot and key=='Position'then return data.PoseRoot.Position+(data.PoseOffset or Vector3.zero)end
  if data.PoseRoot and key=='CFrame'then return CFrame.new(data.PoseRoot.Position+(data.PoseOffset or Vector3.zero))*data.PoseRoot.CFrame.Rotation end
  if key=='Position'then return data.TorsoRoot and data.TorsoRoot.Position+Vector3.new(0,2,0)or data.Position end
  return data[key]
 end,__newindex=function(_,key,value)data[key]=value;if key=='CFrame'then data.Position=value.Position end end})
 if parent then parent.items[#parent.items+1]=item end
 function item:IsA(c)return class==c or (c=='BasePart'and class=='Part')end
 function item:GetChildren()return self.items end
 function item:GetDescendants()local list={};local function walk(n)for _,c in ipairs(n.items)do list[#list+1]=c;walk(c)end end;walk(self);return list end
 function item:FindFirstChild(name)for _,c in ipairs(self.items)do if c.Name==name and c.Parent==self then return c end end end
 function item:FindFirstChildOfClass(c)for _,v in ipairs(self.items)do if v:IsA(c)then return v end end end
 function item:IsDescendantOf(ancestor)local p=self.Parent;while p do if p==ancestor then return true end;p=p.Parent end;return false end
 function item:GetAttribute(k)return self.attributes[k]end
 local propertySignals,attributeSignals={},{}
 function item:GetPropertyChangedSignal(k)if not propertySignals[k]then propertySignals[k]=signal()end;return propertySignals[k]end
 function item:GetAttributeChangedSignal(k)if not attributeSignals[k]then attributeSignals[k]=signal()end;return attributeSignals[k]end
 function item:GetFullName()return self.Parent and self.Parent:GetFullName()..'.'..self.Name or self.Name end
 function item:GetConnectedParts()return self.ConnectedParts or {}end
 function item:Destroy()self.Parent=nil;self.Destroyed=true end
 return item
end
Instance={new=function(class)local item=instance(class);created[#created+1]=item;return item end}
workspace=instance('Workspace','Workspace')
local cars=instance('Folder','Cars',workspace)
Players=instance('Folder','Players')
player=instance('Player','Local',Players);player.UserId=1
local owner=instance('Player','TestOwner',Players);owner.UserId=42
local char=instance('Model','LocalRig',workspace);player.Character=char
local h=instance('Humanoid','Humanoid',char)
Enum={HumanoidStateType={Seated='Seated',GettingUp='GettingUp'}}
h.Seated=signal();h.SeatedEnabled=true;h.State='Running'
function h:GetStateEnabled()return self.SeatedEnabled end
function h:SetStateEnabled(_,enabled)self.SeatedEnabled=enabled end
function h:GetState()return self.State end
function h:ChangeState(state)self.State=state end
local root=instance('Part','HumanoidRootPart',char);root.CFrame=CFrame.new(10,5,0)
root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
local torso=instance('Part','UpperTorso',char);torso.TorsoRoot=root
RunService={Heartbeat=signal(),PreSimulation=signal(),PostSimulation=signal()}
local authorized=true
ExperimentalFlingCore={IsAuthorized=function()return authorized end}
local function beat(dt)
 now=now+dt
 if NoMotos2Core then RunService.PreSimulation:Fire(dt);RunService.PostSimulation:Fire(dt)end
 RunService.Heartbeat:Fire(dt)
end
local function moto(name,id,occupied,animation)
 local vehicle=instance('Part',name)
 vehicle.attributes.VehicleOwner=id;vehicle.attributes.Animation=animation or 'rbxassetid://13112445577'
 local mover=instance('Model','MoverModel',vehicle)
 local body=instance('Part','Body',mover);body.CFrame=CFrame.new(50,10,0);body.AssemblyRootPart=body
 local seat=instance('Seat','Seat',body);seat.Occupant=occupied and {}or nil
 return vehicle,body,seat
end
local function spawn(vehicle)
 vehicle.Parent=cars;cars.items[#cars.items+1]=vehicle;cars.ChildAdded:Fire(vehicle)
end
assert(load(source))()(_G)
local core=NoMotosCore
local checkpoint=root.CFrame
authorized=false;assert(not core:Start(owner));authorized=true
assert(not core:Start(nil),'must choose owner')
root.Anchored=true;assert(not core:Start(owner));root.Anchored=false
h.Sit=true
assert(core:Start(owner))
assert(not h.Sit,'stale Sit without seat or external weld must not require respawn')
assert(h.SeatedEnabled==false,'disable sitting before any contact')
h.Sit=true;h.State='Seated';h.Seated:Fire(true)
assert(not h.Sit and h.State=='GettingUp','respond immediately to seated event')
h.Sit=true;RunService.PreSimulation:Fire()
assert(not h.Sit,'prevent sitting before simulation')
local foreign=moto('SameName',99);spawn(foreign)
local occupied=moto('Occupied',42,true);spawn(occupied)
local car=moto('NotMotorcycle',42,false,'rbxassetid://123');spawn(car)
beat(.06)
assert(core.Phase=='HOME'and #created==0,'ignore occupied, foreign and unconfirmed vehicle types')
torso.CanCollide=false
local vehicle,body,seat=moto('ReusedName',42);spawn(vehicle);beat(.06)
assert(core.Phase=='CONTACT'and #created==1)
local spinner=created[1]
assert(root.AssemblyAngularVelocity.X==0 and root.AssemblyAngularVelocity.Y==60 and root.AssemblyAngularVelocity.Z==0)
assert(spinner.ClassName=='BodyAngularVelocity'and spinner.AngularVelocity.Y==60 and spinner.MaxTorque.X==0 and spinner.MaxTorque.Z==0)
assert(not h.AutoRotate)
assert(torso.Position.Y==body.Position.Y and torso.Position.X==body.Position.X,'align torso with Body face height')
assert(math.abs(torso.Position.Z-(body.Position.Z-body.Size.Z*0.5-torso.Size.Z*0.5+0.1))<0.001,'align torso surface with front/rear Body face')
assert(torso.CanCollide,'enable physical torso collision only during contact')
local contactX=torso.Position.X
local contactFrame=root.CFrame
body.CFrame=CFrame.new(55,10,0);beat(.01)
assert(torso.Position.X==contactX,'contact must not chase the moving vehicle')
assert(root.CFrame==contactFrame,'do not rewrite orientation/position during physical spin')
beat(.2);assert(core.Phase=='CONTACT','sustain contact beyond old 0.05 second timeout')
local oldVelocity=root.AssemblyLinearVelocity
RunService.PreSimulation:Fire()
assert(root.AssemblyLinearVelocity.Z==500 and root.AssemblyLinearVelocity.X==0 and root.AssemblyLinearVelocity.Y==0,'one directed pulse into Body, not diagonal')
RunService.PostSimulation:Fire()
assert(root.AssemblyLinearVelocity==oldVelocity,'do not overwrite natural linear velocity after physics')
RunService.PreSimulation:Fire()
assert(root.AssemblyLinearVelocity==oldVelocity,'do not repeat pulse every frame')
body.CFrame=CFrame.new(80,10,0);RunService.PostSimulation:Fire()
assert(core.Phase=='HOME'and core.Completed==1 and core.Records[vehicle].Done)
assert(root.CFrame==checkpoint and root.AssemblyLinearVelocity.Magnitude==0)
assert(spinner.Destroyed and h.AutoRotate,'remove spin actuator and restore AutoRotate at home')
assert(torso.CanCollide==false,'restore exact original torso collision setting')
-- Occupancy arising during contact cancels the attempt, without touching its joints.
local second,secondBody,secondSeat=moto('Second',42);spawn(second);beat(.06)
assert(core.Phase=='CONTACT')
secondSeat.Occupant={};beat(.01)
assert(core.Phase=='HOME'and created[#created].Destroyed and secondSeat.Occupant)
-- Ownership references must agree; delayed vehicle completion is rescanned.
local disputed=moto('Disputed',99)
local reference=instance('ObjectValue','VehicleOwner',disputed);reference.Value=owner;spawn(disputed)
beat(.3);assert(not core.Records[disputed])
secondSeat.Occupant=nil
beat(.06);assert(core.Phase=='CONTACT')
core:Stop();assert(core.Stopping and not core.Running and root.Anchored)
assert(h.SeatedEnabled==true,'restore original seated setting on stop')
beat(2.1);assert(not core.Stopping and not root.Anchored and root.CFrame==checkpoint)
assert(root.AssemblyLinearVelocity.Magnitude==0 and h.AutoRotate==true and h.PlatformStand==false)
-- A newly connected character/vehicle must not be teleported home as an assembly.
h.SeatedEnabled=false
assert(core:Start(owner));beat(.06)
local extra=instance('Part','External',workspace);root.ConnectedParts={extra}
local before=root.CFrame
beat(.01)
assert(core.Running and core.Phase=='WAIT_RELEASE'and root.CFrame==before and not root.Anchored)
root.ConnectedParts={}
beat(.01);assert(core.Running and core.Phase=='HOME','resume monitoring after external connection clears')
-- A new instance with exactly the same name is independently eligible.
vehicle.Parent=nil
local replacement,replacementBody=moto('ReusedName',42);spawn(replacement)
assert(core.Records[replacement]and not core.Records[replacement].Done)
-- A regenerated Body inside the same vehicle must not inherit Done.
core.Records[replacement].Done=true
local mover=replacement:FindFirstChild('MoverModel')
replacementBody.Parent=nil
local regenerated=instance('Part','Body',mover)
regenerated.CFrame=CFrame.new(50,10,0);regenerated.AssemblyRootPart=regenerated
instance('Seat','Seat',regenerated)
cars.DescendantAdded:Fire(regenerated)
assert(core.Records[replacement].Body==regenerated and not core.Records[replacement].Done)
-- Removing/reinserting the same root instance also rearms it.
core.Records[replacement].Done=true
replacement.Parent=nil;replacement.Parent=cars;cars.ChildAdded:Fire(replacement)
assert(not core.Records[replacement].Done)
assert(core:GetDiagnosticReport():find('NO MOTOS V3 DIRECTED CONTACT',1,true))
core:Destroy()
assert(h.SeatedEnabled==false,'preserve previously disabled seated state on stop')
-- Re-enabling without respawning starts a fresh pass, even for an existing bike.
local staleSeat=instance('Seat','OldSeat',workspace)
h.SeatPart=staleSeat
h.Sit=true;h.State='Seated'
local started,reason=core:Start(owner)
assert(started and not h.Sit and h.State=='GettingUp','stale SeatPart must not block activation')
beat(.01)
assert(core.Running and core.Phase~='WAIT_RELEASE','stale reference must not stall runtime either')
core:Destroy()
local actualWeld=instance('Weld','SeatWeld',staleSeat)
actualWeld.Part0=staleSeat;actualWeld.Part1=root
started,reason=core:Start(owner)
assert(not started and reason:find('SeatWeld',1,true),'still block a real seat weld to our character')
actualWeld:Destroy()
h.SeatPart=nil
root.ConnectedParts={extra}
started,reason=core:Start(owner)
assert(not started and reason:find('Workspace.External',1,true),'name the actual connected part')
root.ConnectedParts={};h.Sit=true
assert(core:Start(owner)and not h.Sit)
assert(core.Records[replacement]and not core.Records[replacement].Done,'existing bike rearmed after toggle')
core:Destroy()
if source2 then
 assert(load(source2))()(_G)
 local c2=NoMotos2Core
 assert(not c2:Start(owner),'No motos 2 requires own source vehicle')
 local own,ownBody=moto('OurCar',player.UserId,false,'rbxassetid://123');spawn(own)
 CarFling={Running=false,GetCar=function()return own end}
 local homeFrame=ownBody.CFrame
 authorized=false;assert(not c2:Start(owner));authorized=true
 AnchorCore={AnclaEnabled=true,TestEnabled=true,AntiSeatEnabled=true,HeartbeatEnabled=true}
 AutoAnchorCore={Mode='NORMAL',Busy=true}
 MobileAnchorCore={Running=true};MobileAnchorV11Core={Running=true}
 StaticPassThroughAnchorCore={Running=true};VerticalControlController={Running=true}
 DeploymentAnchorMotorCore={Running=true};EmergencyAnchorController={Running=true}
 root.Anchored=true
 local anchoredCharacterFrame=root.CFrame
 assert(c2:Start(owner))
 assert(not core:Start(owner),'mutual exclusion with original No motos')
 beat(.06)
 assert(c2.Phase=='CONTACT','sustained contact starts without a far phase')
 local force=created[#created]
 assert(force.ClassName=='BodyVelocity'and force.Name=='NoMotos2CarFlinger'and force.Parent==ownBody)
 assert(force.Velocity.X==900000000 and force.Velocity.Y==900000000 and force.Velocity.Z==900000000 and force.MaxForce.X==math.huge and force.P==1250)
 assert(ownBody.AssemblyAngularVelocity.X==900000000 and ownBody.AssemblyAngularVelocity.Y==900000000 and ownBody.AssemblyAngularVelocity.Z==900000000)
 assert(ownBody.AssemblyLinearVelocity.Y==-900000000,'original alternating vertical speed')
 local targetBody=c2.TargetBody
 assert(ownBody.Position.Y==targetBody.Position.Y,'No motos 2 must not offset contact vertically')
 local separation=ownBody.Position-targetBody.Position
 assert(separation.Magnitude<0.001,'center contact without lateral exterior-face spacing')
 local entryFrame=ownBody.CFrame
 local firstDirection=ownBody.AssemblyLinearVelocity.Y
 beat(.01);assert(ownBody.AssemblyLinearVelocity.Y==-firstDirection,'alternate vertical velocity each contact step')
 beat(1);beat(1)
 assert(c2.Phase=='CONTACT'and (ownBody.Position-entryFrame.Position).Magnitude<0.001,'sustained contact without far travel')
 local priorPosition=ownBody.Position
 targetBody.CFrame=CFrame.new(targetBody.Position+Vector3.new(0,0,1));beat(.01)
 assert((ownBody.Position-priorPosition).Magnitude>0.5,'maintain live face contact with the original car contact writes')
 local lastForce=created[#created]
 assert(lastForce.Parent==ownBody and lastForce.Name=='NoMotos2CarFlinger','never put forces on target bike')
 assert(c2:Stop()and ownBody.CFrame==homeFrame and lastForce.Destroyed)
 assert(force.Destroyed,'remove force on stop')
 assert(ownBody.AssemblyLinearVelocity.Magnitude==0 and ownBody.AssemblyAngularVelocity.Magnitude==0)
 assert(root.Anchored and root.CFrame==anchoredCharacterFrame and AnchorCore.AnclaEnabled and MobileAnchorCore.Running,'do not disable or move independent anchored character')
 ownBody.ConnectedParts={root}
 assert(not c2:Start(owner),'block an actual connection from car to anchored local character')
 root.Anchored=false
 assert(not c2:Start(owner),'also block local connection to character controlled by an active non-Anchored anchor')
 ownBody.ConnectedParts={}
 AnchorCore=nil;AutoAnchorCore=nil;MobileAnchorCore=nil;MobileAnchorV11Core=nil
 StaticPassThroughAnchorCore=nil;VerticalControlController=nil;DeploymentAnchorMotorCore=nil;EmergencyAnchorController=nil
 ownBody.CanCollide=false
 assert(not c2:Start(owner),'reject a source without collidable parts instead of targeting a non-collidable root')
 ownBody.CanCollide=true
 assert(c2:Start(owner),'restart and rescan existing motorcycles')
 local other=instance('Part','SomeoneElse',workspace);ownBody.ConnectedParts={other}
 local before=ownBody.CFrame;beat(.01)
 assert(not c2.Running and ownBody.CFrame==before,'do not teleport assembly joined to outsiders')
 ownBody.ConnectedParts={}
 local occupant=instance('Humanoid','OtherHumanoid',owner)
 own:FindFirstChild('MoverModel'):FindFirstChild('Body'):FindFirstChild('Seat').Occupant=occupant
 assert(not c2:Start(owner),'reject own vehicle carrying another person')
 own:FindFirstChild('MoverModel'):FindFirstChild('Body'):FindFirstChild('Seat').Occupant=nil
 for _,v in ipairs(cars:GetChildren())do
  local ref=v:FindFirstChild('VehicleOwner')
  if v.attributes.VehicleOwner==owner.UserId or (ref and ref.Value==owner)then v.Parent=nil end
 end
 local testBike,testBody,testSeat=moto('OccupiedTest',owner.UserId);spawn(testBike)
 testSeat.Occupant=occupant
 local selected=nil
 CarFling.GetCar=function()return selected end
 own.Parent=nil
 assert(c2:SetAutoEnabled(true,owner))
 beat(.3);assert(not c2.Running,'automatic mode waits for an owned spawned source')
 own.Parent=cars;beat(.3)
 assert(c2.Running and c2.TargetBody==testBody,'spawning a source starts automatically without other-panel selection')
 testBody.Anchored=true;beat(.01)
 assert(c2.Running,'occupied-target test continues observing anchored target')
 local report=c2:GetDiagnosticReport()
 assert(report:find('Body.Anchored=true',1,true)and report:find('occupants=TestOwner',1,true),'record occupancy and anchoring transitions')
 local respawnedBike,respawnedBody=moto('OccupiedTest',owner.UserId);spawn(respawnedBike)
 beat(.01)
 assert(c2.TargetBody==respawnedBody,'switch to new spawn while previous target still exists')
 -- Respawn can arrive while the old contact is active, at a different position.
 respawnedBike.Parent=nil;respawnedBike.Parent=cars;cars.ChildAdded:Fire(respawnedBike)
 respawnedBody.CFrame=CFrame.new(respawnedBody.Position+Vector3.new(40,0,0));beat(.01)
 assert(c2.TargetBody==respawnedBody and c2.Phase=='CONTACT','do not mark a fresh generation completed using the previous origin')
 local reusedSpawnFrame=respawnedBody.CFrame
 respawnedBody.CFrame=CFrame.new(respawnedBody.Position+Vector3.new(30,0,0));beat(.01)
 assert(c2.TargetBody~=respawnedBody,'do not keep pursuing displaced vehicle')
 respawnedBody.CFrame=reusedSpawnFrame;beat(.3)
 assert(c2.TargetBody==respawnedBody and c2.Phase=='CONTACT','rearm same Part returned to its spawn without ChildAdded')
 respawnedBike.Parent=nil;respawnedBike.Parent=cars;cars.ChildAdded:Fire(respawnedBike);beat(.01)
 assert(c2.TargetBody==respawnedBody and c2.Phase=='CONTACT','reinserted same Body must not remain permanently completed')
 local regenMover=respawnedBike:FindFirstChild('MoverModel');respawnedBody.Parent=nil
 local regenBody=instance('Part','Body',regenMover);regenBody.AssemblyRootPart=regenBody;regenBody.CFrame=CFrame.new(50,10,0)
 instance('Seat','Seat',regenBody);cars.DescendantAdded:Fire(regenBody);beat(.01)
 assert(c2.TargetBody==regenBody,'resolve regenerated physical Body in reused vehicle container')
 own.Parent=nil;beat(.3)
 assert(not c2.Running,'removing source stops the automatic run')
 own.Parent=cars;beat(.3);assert(c2.Running,'automatic mode reactivates on source respawn')
 local newOwn,newOwnBody=moto('OurCar',player.UserId,false,'rbxassetid://123');spawn(newOwn)
 beat(.3);beat(.01)
 assert(c2.Running and created[#created].Parent==newOwnBody,'same model name/new instance replaces source automatically')
 assert(selected==nil,'do not modify original car fling selection')
 c2:SetAutoEnabled(false)
 assert(not c2.Running and not c2.AutoEnabled,'disable auto also stops active flow')
 newOwn.Parent=nil
 testBody.Anchored=false;c2.TestOccupiedTargets=false
 respawnedBike.Parent=nil
 assert(c2:Start(owner))
 assert(c2.Phase=='WAIT_MOTORCYCLE','switch restores previous occupied-target exclusion')
 c2:Destroy()
 -- Generic targets: no motorcycle IDs, no MoverModel/Body path, no seats.
 local generic=instance('Part','UnrecognizedModel');generic.attributes.VehicleOwner=owner.UserId
 generic.CanCollide=false;spawn(generic)
 assert(c2:Start(owner));beat(.3)
 assert(c2.Phase=='WAIT_MOTORCYCLE','wait for physical components instead of permanently excluding incomplete spawn')
 local structure=instance('Model','DifferentStructure',generic)
 local physicalRoot=instance('Part','Meshes/moto_metal',structure)
 physicalRoot.AssemblyRootPart=physicalRoot;physicalRoot.CanCollide=false
 local colliderA=instance('Part','Collider',structure)
 colliderA.Size=Vector3.new(4,4,4);colliderA.AssemblyRootPart=physicalRoot
 local colliderB=instance('Part','Collider',structure)
 colliderB.Size=Vector3.new(2,2,2);colliderB.AssemblyRootPart=physicalRoot
 local filler=instance('Part','OilFiller',structure)
 filler.Size=Vector3.new(.4,.4,.4);filler.AssemblyRootPart=physicalRoot
 local unrelatedWheel=instance('Part','Wheel',structure)
 unrelatedWheel.AssemblyRootPart=unrelatedWheel;unrelatedWheel.Size=Vector3.new(10,10,10)
 cars.DescendantAdded:Fire(colliderA);beat(.01)
 assert(c2.TargetBody==colliderA and c2.Phase=='CONTACT','choose largest collidable part of main assembly, not independent wheel or noncollidable root')
 assert(c2:GetDiagnosticReport():find('CONTACT_PART=',1,true),'report chosen target collision part')
 c2:Destroy()
 -- Non-collidable conventional Body is also valid when its assembly has colliders.
 generic.Parent=nil
 local conventional,noncollidingBody=moto('AnotherModel',owner.UserId,false,'rbxassetid://999')
 noncollidingBody.CanCollide=false
 local conventionalCollider=instance('Part','Collider',noncollidingBody)
 conventionalCollider.AssemblyRootPart=noncollidingBody
 spawn(conventional)
 assert(c2:Start(owner));beat(.01)
 assert(c2.TargetBody==conventionalCollider,'do not reject a vehicle simply because Body.CanCollide is false')
 c2:Destroy()
 -- Source discovery must be generic too, not only the target resolver.
 for _,v in ipairs(cars:GetChildren())do if v.attributes.VehicleOwner==player.UserId then v.Parent=nil end end
 local genericOwn=instance('Part','DifferentOwnCar');genericOwn.attributes.VehicleOwner=player.UserId;genericOwn.CanCollide=false;spawn(genericOwn)
 assert(c2:SetAutoEnabled(true,owner));beat(.3)
 assert(not c2.Running and c2.AutoStatus:find('esperando ensamblaje',1,true),'show why an incomplete owned source cannot start')
 local ownStructure=instance('Model','CustomPhysics',genericOwn)
 local ownPhysicalRoot=instance('Part','MetalRoot',ownStructure);ownPhysicalRoot.CanCollide=false;ownPhysicalRoot.AssemblyRootPart=ownPhysicalRoot
 local ownCollider=instance('Part','Collider',ownStructure);ownCollider.AssemblyRootPart=ownPhysicalRoot;ownCollider.PoseRoot=ownPhysicalRoot
 cars.DescendantAdded:Fire(ownCollider);beat(.3);beat(.01)
 assert(c2.Running and created[#created].Parent==ownPhysicalRoot,'auto detects source lacking MoverModel.Body and a collidable top-level root')
 local anotherOwner=instance('Player','AnotherOwner',Players);anotherOwner.UserId=77
 local anotherVehicle,anotherBody=moto('OtherUsersVehicle',anotherOwner.UserId,false,'rbxassetid://456');spawn(anotherVehicle)
 local previousForce=created[#created]
 assert(c2:SetTargetOwner(anotherOwner))
 assert(c2.AutoEnabled and not c2.Running and previousForce.Destroyed,'retarget keeps auto enabled and removes previous contact forces')
 beat(.3);beat(.01)
 assert(c2.Running and c2.Owner==anotherOwner and c2.AutoOwnerId==77 and c2.TargetBody==anotherBody,'automatic flow uses newly selected owner, not original account')
 assert(c2:SetAutoEnabled(true,owner));beat(.3);beat(.01)
 assert(c2.Running and c2.Owner==owner and c2.TargetBody==conventionalCollider,'re-enabling auto for another owner also replaces active target')
 c2:SetAutoEnabled(false)
 assert(c2:Start(anotherOwner,genericOwn));beat(.01)
 assert(c2:Start(owner));beat(.01)
 assert(c2.Owner==owner and c2.TargetBody==conventionalCollider,'manual active start must not silently retain old owner either')
 c2:Destroy()
 -- Spawn priority must survive delayed ownership and delayed physical components.
 assert(c2:Start(owner,genericOwn))
 local older,olderBody=moto('OlderSpawn',owner.UserId);spawn(older);beat(.001)
 assert(c2.TargetBody==olderBody)
 local lateOwner,lateOwnerBody=moto('OwnerReplicatesLater',nil);spawn(lateOwner);beat(.001)
 assert(c2.TargetBody==olderBody,'keep valid contact while newer spawn lacks ownership evidence')
 lateOwner.attributes.VehicleOwner=owner.UserId;lateOwner:GetAttributeChangedSignal('VehicleOwner'):Fire()
 beat(.001)
 assert(c2.TargetBody==lateOwnerBody,'newer spawn wins as soon as delayed owner attribute arrives, without 0.25s wait')
 local partial=instance('Part','PhysicsReplicatesLater');partial.CanCollide=false;partial.attributes.VehicleOwner=owner.UserId;spawn(partial);beat(.001)
 assert(c2.TargetBody==lateOwnerBody)
 local partialCollider=instance('Part','AnyColliderName',partial);partialCollider.AssemblyRootPart=partialCollider
 cars.DescendantAdded:Fire(partialCollider);beat(.001)
 assert(c2.TargetBody==partialCollider,'newer spawn takes priority as soon as its collider becomes ready')
 local lateReference,lateReferenceBody=moto('OwnerObjectValueLater',nil)
 local reference=instance('ObjectValue','VehicleOwner',lateReference);spawn(lateReference);beat(.001)
 reference.Value=owner;reference:GetPropertyChangedSignal('Value'):Fire();beat(.001)
 assert(c2.TargetBody==lateReferenceBody,'ObjectValue ownership changes trigger immediate reevaluation too')
 -- Check placement after physics, and correct next step rather than waiting/relaunching.
 RunService.PreSimulation:Fire(.001)
 ownPhysicalRoot.CFrame=CFrame.new(ownPhysicalRoot.Position+Vector3.new(5,0,0))
 RunService.PostSimulation:Fire(.001)
 assert(c2.Phase=='RECOVERING'and not c2.LastArrivalObserved and c2.LastContactError>4)
 RunService.Heartbeat:Fire(.001);RunService.PostSimulation:Fire(.001)
 assert(c2.Phase=='CONTACT'and c2.LastArrivalObserved,'correct drift on the restored Heartbeat path, with no delay or far travel')
 local directVehicle,directBody=moto('DirectOwnerReference',999)
 local directRef=instance('ObjectValue','VehicleOwner',directVehicle);directRef.Value=owner
 spawn(directVehicle);beat(.001)
 assert(c2.TargetBody==directBody,'actual target Player reference takes precedence over stale owner attribute')
 directRef.Value=anotherOwner;directRef:GetPropertyChangedSignal('Value'):Fire()
 directVehicle.attributes.VehicleOwner=owner.UserId;beat(.001)
 assert(c2.TargetBody~=directBody,'never target another Player reference just because attribute matches')
 local ownerTrace=c2:GetDiagnosticReport()
 assert(ownerTrace:find('RAW OWNERSHIP SNAPSHOT:',1,true)and ownerTrace:find('matchesTARGET=',1,true))
 assert(ownerTrace:find('OwnerValue=Players.AnotherOwner class=Player UserId=77',1,true),'raw trace includes actual Player owner ID, not only filtered vehicles')
 c2:Destroy()
 print('no_motos2_spec OK: authorization, own source vehicle, mutual exclusion, motorcycle targeting, car phases, cleanup and external assembly guard')
end
for _,s in ipairs(signals)do assert(s:Count()==0,'No motos leaked an event connection')end
print('no_motos_spec OK: owner-only, selected owner, free motorcycle scope, torso alignment, efficient force defaults, cleanup and occupancy cancellation')
