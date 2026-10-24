local source=...
setfenv=function()end
isES=true
local vm={}
Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},vm)end}
Vector3.zero=Vector3.new(0,0,0)
vm.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vm.__index=function(a,k)if k=='Magnitude'then return math.sqrt(a.X^2+a.Y^2+a.Z^2)end end
local fm={}
CFrame={new=function(x,y,z)return setmetatable({Position=type(x)=='table'and x or Vector3.new(x or 0,y or 0,z or 0)},fm)end}
fm.__mul=function(a,b)return CFrame.new(a.Position+b.Position)end
local signals={}
local function signal()
 local entries={};local s={}
 function s:Connect(fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;entries[#entries+1]={c,fn};return c end
 function s:Fire(...)for _,e in ipairs(entries)do if e[1].Connected then e[2](...)end end end
 function s:Count()local n=0;for _,e in ipairs(entries)do if e[1].Connected then n=n+1 end end;return n end
 signals[#signals+1]=s;return s
end
local objects={}
local function instance(class,name,parent)
 local values={Name=name,Parent=parent,ClassName=class,Anchored=false,Health=100,Sit=false,Disabled=false,CFrame=CFrame.new()}
 local o=setmetatable({}, {__index=function(_,k)if k=='Position'and (class=='Part'or class=='Seat'or class=='VehicleSeat')then return values.CFrame.Position end;return values[k]end,__newindex=function(_,k,v)values[k]=v end})
 function o:IsA(c)return c==class or(c=='JointInstance'and class=='Weld')end
 function o:IsDescendantOf(a)local p=self.Parent;while p do if p==a then return true end;p=p.Parent end;return false end
 function o:GetDescendants()local list={};for _,v in ipairs(objects)do if v:IsDescendantOf(self)then list[#list+1]=v end end;return list end
 function o:FindFirstChild(n)for _,v in ipairs(objects)do if v.Parent==self and v.Name==n then return v end end end
 function o:FindFirstChildOfClass(c)for _,v in ipairs(objects)do if v.Parent==self and v:IsA(c)then return v end end end
 function o:GetFullName()return self.Parent and self.Parent:GetFullName()..'.'..self.Name or self.Name end
 function o:Destroy()self.Parent=nil;self.Destroyed=true end
 objects[#objects+1]=o;return o
end
Instance={new=function(class)return instance(class,class)end}
workspace=instance('Workspace','Workspace')
local character=instance('Model','LocalCharacter',workspace)
local root=instance('Part','HumanoidRootPart',character)
root.CFrame=CFrame.new(100,5,0)
local home=root.CFrame
local humanoid=instance('Humanoid','Humanoid',character)
player={Character=character}
Enum={HumanoidStateType={GettingUp='GettingUp'},PositionAlignmentMode={OneAttachment='OneAttachment'},OrientationAlignmentMode={OneAttachment='OneAttachment'}}
function humanoid:ChangeState(state)
 self.State=state
 if self.SeatPart then
  local s=self.SeatPart;s.Occupant=nil
  local w=s:FindFirstChild('SeatWeld');if w then w.Parent=nil end
 end
 self.SeatPart=nil
end
RunService={PreSimulation=signal(),PostSimulation=signal()}
local scans=0
local originalScan=workspace.GetDescendants
function workspace:GetDescendants()scans=scans+1;return originalScan(self)end
local far=instance('Seat','AAA',workspace);far.CFrame=CFrame.new(200,5,0)
local near=instance('Seat','ZZZ',workspace);near.CFrame=CFrame.new(104,5,0)
local authorized=true
ExperimentalFlingCore={IsAuthorized=function()return authorized end}
local noSit=false
local calls=0
local function sit(s,h)
 calls=calls+1
 if noSit then return end
 s.Occupant=h;h.SeatPart=s;h.Sit=true
 local w=instance('Weld','SeatWeld',s);w.Part0=s;w.Part1=root
end
far.Sit=sit;near.Sit=sit
local context=_G
assert(load(source))()(context)
local c=SeatAnchorLabCore
authorized=false;assert(not c:Start('trip'));authorized=true
local beforeRefresh=root.CFrame
local vehicleSeat=instance('VehicleSeat','000VehicleSeat',workspace)
assert(c:RefreshSeat()and c.Seat==far and #c.Seats==2 and c.SelectedIndex==1,'original Seat-only alphabetic list excludes VehicleSeat')
assert(root.CFrame==beforeRefresh and not c.Running and calls==0,'refresh only detects; never moves, anchors or sits')
assert(c:SelectSeat(1)and c.Seat==near and c.SeatDistance==4)
assert(c:SelectSeat(1)and c.Seat==far,'next wraps around')
assert(c:SelectSeat(-1)and c.Seat==near,'previous wraps around')
near.Disabled=true
assert(c:RefreshSeat()and c.Seat==far,'refresh resets selector to first alphabetical Seat')
assert(c:SelectSeat(1)and c.Seat==near,'selector preserves original list even when selected seat is disabled')
assert(c:Start('trip')and near.Disabled,'Disabled flag does not preempt original round trip or get modified')
c:Stop()
near.Disabled=false
assert(c:RefreshSeat()and c:SelectSeat(1)and c.Seat==near)
local farFrame=far.CFrame
far.CFrame=CFrame.new(101,5,0)
local scansAfterSelection=scans
AnchorCore={AnclaEnabled=true};assert(not c:Start('anchor'));assert(AnchorCore.AnclaEnabled);AnchorCore=nil
assert(c:Start('trip'));assert(c.Seat==near and calls==0,'choose distance rather than alphabetical path')
assert(scans==scansAfterSelection,'Start must use refreshed selection, not rescan for a different nearest seat')
far.CFrame=farFrame
assert(not c:RefreshSeat(),'cannot replace the seat of an active test')
assert(not c:SelectSeat(-1),'cannot navigate away from active test seat')
assert(root.CFrame.Position.X==104 and not root.Anchored)
RunService.PreSimulation:Fire(.12);assert(c.Phase=='SIT_WAIT'and calls==1)
assert(not humanoid.Jump,'clear previous release jump before calling Sit')
RunService.PreSimulation:Fire(.12);assert(c.Phase=='SIT_HOLD'and c.OccupantMatches and c.SeatPartMatches and c.WeldMatches)
RunService.PreSimulation:Fire(.25)
assert(not c.Running and root.CFrame==home and not root.Anchored and not humanoid.Sit,'one round trip automatically releases and returns')
assert(c.TripCheckpoint==home,'retain the location where round trip was activated')
local before=scans
root.CFrame=near.CFrame
assert(c:Start('anchor'));assert(not root.Anchored and root.CFrame==near.CFrame and not humanoid.Jump,'physical hold does not teleport or inherit release jump')
assert(c.Checkpoint==home,'do not recapture a checkpoint at the seat after the player was pulled there')
local positionHold=root:FindFirstChild('SeatLabHoldPosition')
local orientationHold=root:FindFirstChild('SeatLabHoldOrientation')
assert(positionHold.Position==home.Position and orientationHold.CFrame==home,'constraints target original round-trip checkpoint')
assert(positionHold.MaxForce==1000000 and positionHold.MaxVelocity==150 and not positionHold.RigidityEnabled)
RunService.PreSimulation:Fire(.01);assert(c.Phase=='SEATED_RETURNING'and c.WeldMatches,'seated far from checkpoint is not reported as already held')
local weld=near:FindFirstChild('SeatWeld')
local displacedFrame=CFrame.new(999,999,999)
root.CFrame=displacedFrame;RunService.PostSimulation:Fire()
assert(root.CFrame==displacedFrame and positionHold.Position==home.Position and humanoid.Sit and weld.Parent==near,'physical hold preserves weld without locally teleporting back')
root.CFrame=home -- Mock a physics arrival; no claim of real engine convergence.
for i=1,20 do RunService.PreSimulation:Fire(.01);RunService.PostSimulation:Fire()end
assert(c.Phase=='HOLD'and c.LocalCheckpointError==0)
assert(scans==before,'restarting with selected seat needs no extra scan, and frame callbacks never scan')
assert(c:Stop()and not root.Anchored and not humanoid.Sit)
assert(positionHold.Destroyed and orientationHold.Destroyed and not root:FindFirstChild('SeatLabHoldAttachment'),'destroy only lab constraints when stopping')
assert(c:Start('anchor'));RunService.PreSimulation:Fire(.01)
near:FindFirstChild('SeatWeld').Parent=nil
RunService.PreSimulation:Fire(.01);assert(c.Running and not root.Anchored and humanoid.Sit and c.Phase=='HOLD_SEAT_UNCONFIRMED','missing weld evidence must not automatically stand player up')
c:Stop()
noSit=true;assert(c:Start('anchor'))
RunService.PreSimulation:Fire(2.5);assert(c.Running and not root.Anchored and c.Phase=='WAIT_SEAT','unconfirmed seat attempt keeps physical hold without claiming sitting success')
c:Stop()
noSit=false
sit(near,humanoid)
local callsBeforeSeated=calls
root.CFrame=near.CFrame
assert(c:Start('anchor'),'existing selected-seat occupant can activate anchor')
RunService.PreSimulation:Fire(.01)
assert(c.Phase=='SEATED_RETURNING'and calls==callsBeforeSeated and humanoid.Sit and root.CFrame==near.CFrame and root:FindFirstChild('SeatLabHoldPosition').Position==home.Position,'already seated anchor preserves weld and targets round-trip checkpoint without requesting Sit again')
c:Stop()
assert(c:Start('trip'));near.Parent=nil
RunService.PreSimulation:Fire(.01);assert(not c.Running and root.CFrame==home,'seat removal cancels and returns')
near.Parent=workspace
near.Parent=nil
local beforeInvalid=root.CFrame
assert(not c:Start('trip')and root.CFrame==beforeInvalid and c.Seat==near,'unavailable selection must not switch silently to another seat')
near.Parent=workspace
near.Occupant=instance('Humanoid','OtherOccupant',workspace)
assert(not c:Start('trip')and c.Seat==near,'occupied selection must not switch to a free alternative')
assert(c:RefreshSeat()and c.Seat==far,'explicit refresh restores original first-seat selection')
assert(not c:Start('anchor'),'a different seat must not silently reuse the checkpoint associated with the old seat')
near.Occupant=nil
assert(c:SelectSeat(1)and c.Seat==near,'explicit selection restores chosen Seat')
assert(c:Start('anchor'))
local replacement=instance('Model','NewCharacter',workspace);player.Character=replacement
local replacementRoot=instance('Part','HumanoidRootPart',replacement);replacementRoot.CFrame=CFrame.new(1,2,3)
local replacementFrame=replacementRoot.CFrame
RunService.PreSimulation:Fire(.01)
assert(not c.Running and replacementRoot.CFrame==replacementFrame and not root.Anchored,'respawn stops without writing to replacement character')
player.Character=character
assert(c:Start('anchor'));humanoid.Health=0;RunService.PreSimulation:Fire(.01)
assert(not c.Running and not root.Anchored,'death restores anchoring and disconnects')
humanoid.Health=100;humanoid.Sit=false;humanoid.SeatPart=nil;near.Occupant=nil
assert(c:Start('trip'));c:Destroy();c:Destroy()
for _,s in ipairs(signals)do assert(s:Count()==0,'frame connections must not leak')end
for _,o in ipairs(objects)do
 if o.Name:match('^SeatLabHold')then assert(o.Parent==nil,'constraints must not leak after stop, death, respawn or destroy')end
end
print('seat_anchor_lab_spec OK: owner authorization, original seat list, selector persistence, one-shot, seat-compatible hold, delayed evidence, death, respawn and cleanup')
