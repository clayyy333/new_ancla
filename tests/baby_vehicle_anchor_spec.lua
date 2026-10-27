local source=...
setfenv=function()end
table.clear=function(t)for k in pairs(t)do t[k]=nil end end
local function signal()
 local s={callbacks={}}
 function s:Connect(fn)local c={live=true};function c:Disconnect()self.live=false end;self.callbacks[#self.callbacks+1]={c,fn};return c end
 function s:Fire(...)for _,v in ipairs(self.callbacks)do if v[1].live then v[2](...)end end end
 return s
end
local objects={}
local function obj(class,name,parent)
 local o={ClassName=class,Name=name,Parent=parent,Enabled=true,ChildAdded=signal(),AncestryChanged=signal(),props={}}
 objects[#objects+1]=o
 function o:IsA(c)return c==class or (c=='JointInstance'and class=='Weld')or(c=='BasePart'and(class=='Part'or class=='Seat'))end
 function o:IsDescendantOf(p)local n=self.Parent;while n do if n==p then return true end;n=n.Parent end;return false end
 function o:FindFirstChild(n)for _,v in ipairs(objects)do if v.Parent==self and v.Name==n then return v end end end
 function o:FindFirstChildOfClass(c)for _,v in ipairs(objects)do if v.Parent==self and v:IsA(c)then return v end end end
 function o:FindFirstAncestorOfClass(c)local n=self.Parent;while n do if n:IsA(c)then return n end;n=n.Parent end end
 function o:GetDescendants()local r={};for _,v in ipairs(objects)do if v:IsDescendantOf(self)then r[#r+1]=v end end;return r end
 function o:GetPropertyChangedSignal(p)self.props[p]=self.props[p]or signal();return self.props[p]end
 function o:Destroy()self.Parent=nil;self.AncestryChanged:Fire()end
 return o
end
local vm={};local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},vm)end
vm.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vm.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__index=function(a,k)if k=='Magnitude'then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)end end
Vector3={new=vec,zero=vec(0,0,0)}
local fm={};local function frame(v)return setmetatable({Position=v},fm)end
fm.__mul=function(a,b)return frame(a.Position+b.Position)end
CFrame={new=function(x,y,z)return frame(vec(x,y,z))end,lookAt=function(p)return frame(p)end}
Enum={HumanoidStateType={Seated='Seated'},RaycastFilterType={Exclude='Exclude'}}
OverlapParams={new=function()return {}end}
local now=0;os.clock=function()return now end
local tasks={};task={spawn=function(fn)tasks[#tasks+1]=fn end}
local function flush()local q=tasks;tasks={};for _,fn in ipairs(q)do fn()end end
workspace=obj('Workspace','Workspace');workspace.DescendantAdded=signal()
local queries=0;function workspace:GetPartBoundsInRadius()queries=queries+1;return {}end
Players=obj('Players','Players')
player=obj('Player','Local',Players);player.CharacterRemoving=signal()
local char=obj('Model','Local',workspace);player.Character=char
local h=obj('Humanoid','Humanoid',char);h.Health=100;h.Died=signal()
function h:SetStateEnabled(_,value)self.seatedEnabled=value end
local root=obj('Part','HumanoidRootPart',char);root.Position=vec(0,3,0);root.CFrame=frame(root.Position)
local backpack=obj('Backpack','Backpack',player)
local target=obj('Player','Target',Players);target.Character=obj('Model','Target',workspace)
local tr=obj('Part','HumanoidRootPart',target.Character);tr.Position=vec(10,3,0);tr.CFrame=frame(tr.Position)
function Players:GetPlayerFromCharacter(c)if c==char then return player elseif c==target.Character then return target end end
local cars=obj('Folder','Cars',workspace);local car=obj('Part','Car',cars);local seat=obj('Seat','Seat',car)
local motoWeld=obj('Weld','SeatWeld',seat);motoWeld.Part0=seat;motoWeld.Part1=tr
local rs=obj('Folder','ReplicatedStorage');local remotes=obj('Folder','Remotes',rs)
local equip=obj('RemoteFunction','EquipToolRF',remotes);local clear=obj('RemoteEvent','ClearToolRE',remotes)
game={GetService=function()return rs end}
local tool,babySeat,requests,clears=nil,nil,0,0
function equip:InvokeServer(name)
 assert(name=='Babycar_a');requests=requests+1
 tool=obj('Tool','Babycar_a',backpack);babySeat=obj('Seat','Seat',tool)
 backpack.ChildAdded:Fire(tool)
end
function clear:FireServer(value)assert(value);clears=clears+1 end
function h:EquipTool(t)assert(self.seatedEnabled==false,'protect before equip');t.Parent=char;char.ChildAdded:Fire(t)end
RunService={Heartbeat=signal()}
local owner=true
ExperimentalFlingCore={IsAuthorized=function()return owner end}
DeploymentSafetyCore={IsAvailable=function()return true end}
local relocations={}
DeploymentAnchorMotorCore={Running=false}
function DeploymentAnchorMotorCore:IsRunning()return self.Running end
function DeploymentAnchorMotorCore:Start()self.Running=true;return true end
function DeploymentAnchorMotorCore:Stop()self.Running=false end
function DeploymentAnchorMotorCore:RelocateForDeployment(cf)assert(self.Running);relocations[#relocations+1]=cf;root.CFrame=cf;root.Position=cf.Position end
Settings={deploymentTPOffsets={TPHeight=-2,TPSeparation=5}}
local saves=0;SaveLocalData=function()saves=saves+1 end
assert(load(source))()(_G)
local core=BabyVehicleAnchorCore
assert(core.TPHeight==-2 and core.TPSeparation==5,'saved offsets restored at initialization')
assert(core:SetTPOffset('TPHeight',0)and core:SetTPOffset('TPSeparation',3.5))
assert(saves==2 and Settings.deploymentTPOffsets.TPHeight==0 and Settings.deploymentTPOffsets.TPSeparation==3.5,'offset changes saved locally')
local function tick(dt)now=now+dt;RunService.Heartbeat:Fire()end
owner=false;assert(not core:Start());owner=true
local home=root.CFrame
assert(core:Start());assert(core.State=='PREPARING');flush();assert(core.State=='WAITING')
tick(.16);assert(core.State=='FOLLOWING'and #relocations==1)
assert(queries==0,'first TP must not wait for lateral spatial queries')
assert(root.Position.X==13.5,'relocate anchor directly to configured lateral')
assert(not core:SetTPOffset('TPSeparation',-1)and not core:SetTPOffset('TPHeight',0/0),'invalid offsets rejected')
assert(core:SetTPOffset('TPSeparation',6)and core:SetTPOffset('TPHeight',2))
tick(.01)
assert(root.Position.X==16 and root.Position.Y==5,'live TP offsets apply to following')
assert(core:SetTPOffset('TPSeparation',3.5)and core:SetTPOffset('TPHeight',0))
local ownLink=obj('WeldConstraint','WeldConstraint',tool);ownLink.Part0=root;ownLink.Part1=babySeat
workspace.DescendantAdded:Fire(ownLink);assert(ownLink.Parent,'preserve local tool connection')
local attack=obj('Weld','SeatWeld',seat);attack.Part0=seat;attack.Part1=root
workspace.DescendantAdded:Fire(attack);assert(not attack.Parent,'release local player from foreign seat')
local passenger=obj('Weld','SeatWeld',babySeat);passenger.Part0=babySeat;passenger.Part1=tr
workspace.DescendantAdded:Fire(passenger);assert(core.State=='CLEARING'and clears==1)
tick(.1);assert(core.State=='CLEARING'and requests==1,'remote success is not removal confirmation')
local old=tool;old:Destroy();tick(.1);assert(core.State=='REARMING')
assert(root.CFrame~=home,'do not return until reinvocation is observed')
flush();assert(core.State=='WAITING'and requests==2 and root.CFrame==home,'confirmed cycle returns anchored')
core:Stop();assert(not core.Running and not DeploymentAnchorMotorCore.Running)
assert(core:Start());core:Stop();flush();assert(not core.Running,'late invoke result cannot restart stopped flow')
core:Destroy()
print('baby_vehicle_anchor OK: owner gate, immediate anchored TP, seat protection, own tool preservation, confirmed clear/rearm/return, cancellation')
