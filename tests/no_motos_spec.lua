local source=...
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
local created={}
local function instance(class,name,parent)
 local data={ClassName=class,Name=name or class,Parent=parent,items={},attributes={},ChildAdded=signal(),DescendantAdded=signal(),Position=Vector3.zero,CFrame=CFrame.new(),CanCollide=true,Anchored=false,Health=100,AutoRotate=true,PlatformStand=false}
 local item=setmetatable({}, {__index=function(_,key)
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
local root=instance('Part','HumanoidRootPart',char);root.CFrame=CFrame.new(10,5,0)
root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
local torso=instance('Part','UpperTorso',char);torso.TorsoRoot=root
RunService={Heartbeat=signal()}
local authorized=true
ExperimentalFlingCore={IsAuthorized=function()return authorized end}
local function beat(dt)now=now+dt;RunService.Heartbeat:Fire(dt)end
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
assert(core:Start(owner))
local foreign=moto('SameName',99);spawn(foreign)
local occupied=moto('Occupied',42,true);spawn(occupied)
local car=moto('NotMotorcycle',42,false,'rbxassetid://123');spawn(car)
beat(.06)
assert(core.Phase=='HOME'and #created==0,'ignore occupied, foreign and unconfirmed vehicle types')
local vehicle,body,seat=moto('ReusedName',42);spawn(vehicle);beat(.06)
assert(core.Phase=='CONTACT'and #created==1)
local flinger=created[1]
assert(flinger.ClassName=='BodyVelocity'and flinger.P==1250 and flinger.Velocity.X==900000000)
assert(flinger.MaxForce.X==math.huge and root.AssemblyAngularVelocity.X==900000000)
assert(math.abs(torso.Position.Y-(body.Position.Y-1.5))<0.001 and torso.Position.X==body.Position.X,'align torso, not HRP, with Body offset')
body.CFrame=CFrame.new(80,10,0);beat(.06)
assert(core.Phase=='HOME'and core.Completed==1 and core.Records[vehicle].Done)
assert(root.CFrame==checkpoint and flinger.Destroyed and root.AssemblyLinearVelocity.Magnitude==0)
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
beat(2.1);assert(not core.Stopping and not root.Anchored and root.CFrame==checkpoint)
assert(root.AssemblyLinearVelocity.Magnitude==0 and h.AutoRotate==true and h.PlatformStand==false)
-- A newly connected character/vehicle must not be teleported home as an assembly.
assert(core:Start(owner));beat(.06)
local extra=instance('Part','External',workspace);root.ConnectedParts={extra}
local before=root.CFrame
beat(.01)
assert(not core.Running and not core.Stopping and root.CFrame==before and not root.Anchored)
root.ConnectedParts={}
assert(core:GetDiagnosticReport():find('NO MOTOS V1',1,true))
core:Destroy()
for _,s in ipairs(signals)do assert(s:Count()==0,'No motos leaked an event connection')end
print('no_motos_spec OK: owner-only, selected owner, free motorcycle scope, torso alignment, efficient force defaults, cleanup and occupancy cancellation')
