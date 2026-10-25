-- Run with the module source as the first argument under a Lua runtime.
local source=...
setfenv=function()end
local function event()
	local e={listeners={}}
	function e:Connect(f)local c={active=true};function c:Disconnect()self.active=false end;self.listeners[#self.listeners+1]={c,f};return c end
	function e:Fire(...)for _,v in ipairs(self.listeners)do if v[1].active then v[2](...)end end end
	return e
end
local vm={}
local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},vm)end
vm.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vm.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__mul=function(a,b)return vec(a.X*b,a.Y*b,a.Z*b)end
vm.__index=function(a,k)if k=="Magnitude"then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)elseif k=="Unit"then local m=a.Magnitude;return vec(a.X/m,a.Y/m,a.Z/m)end end
Vector3={new=vec,zero=vec(0,0,0)}
local fm={}
local function frame(p)return setmetatable({Position=p,RightVector=vec(1,0,0),LookVector=vec(0,0,-1)},fm)end
fm.__index=function(a,k)if k=="Rotation"then return a end;return function(_,v)return v end end
fm.__mul=function(a)return a end
CFrame={new=frame}
Enum={HumanoidStateType={Seated="Seated"}}
table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
math.clamp=math.clamp or function(v,a,b)return math.max(a,math.min(v,b))end
Instance={new=function(class)local o={ClassName=class};function o:Destroy()self.Parent=nil;self.destroyed=true end;function o:IsA(c)return c==self.ClassName end;return o end}
local now=0;os.clock=function()return now end
local authorized=true
ExperimentalFlingCore={IsAuthorized=function()return authorized end}
Players={};RunService={PreSimulation=event()}
local char={DescendantAdded=event()}
local hum={Health=100,PlatformStand=false,AutoRotate=true,Died=event(),SeatedEnabled=true}
function hum:GetStateEnabled()return self.SeatedEnabled end
function hum:SetStateEnabled(_,v)self.SeatedEnabled=v end
hum.Parent=char
local initial=frame(vec(0,3,0))
local root={Parent=char,CFrame=initial,Position=vec(0,3,0),Anchored=false,CanCollide=false,Connected={}}
function root:IsA(c)return c=="BasePart"end
function root:GetConnectedParts()return self.Connected end
local limb={Parent=char,CanCollide=true,IsA=root.IsA}
function char:FindFirstChild()return root end
function char:FindFirstChildOfClass()return hum end
function char:GetDescendants()return {root,limb}end
player={Character=char,GetNetworkPing=function()return .05 end}
local tr={Position=vec(10,3,0),CFrame=frame(vec(10,3,0)),AssemblyLinearVelocity=vec(0,0,0)}
local th={Health=100}
local tc={FindFirstChild=function()return tr end,FindFirstChildOfClass=function()return th end}
local target={Parent=Players,Character=tc}
UpdateExperimentalFlingPanel=function()end
assert(load(source))()(_G)
local c=HybridFlingCore
authorized=false;assert(not c:Start(target));authorized=true
assert(not c:SetParameter("DiagonalSpeed",0/0));assert(not c:SetParameter("ContactTime",0))
assert(not c:SetParameter("LaunchDistance",0));assert(c:SetParameter("LaunchDistance",1000))
assert(c:SetParameter("Spin",20000))
root.Connected={{Name="ExternalAttachment",Anchored=true}}
root.Anchored=true;root.AssemblyRootPart={Anchored=true};hum.SeatPart={}
assert(c:Start(target));assert(c.Running and not limb.CanCollide and not hum.SeatedEnabled)
RunService.PreSimulation:Fire();assert(c.Running and c.Phase=="CONTACT")
assert((root.CFrame.Position-tr.Position).Magnitude==.5)
assert(root.AssemblyLinearVelocity.X==9000,"Classic velocity must also run during contact")
now=.21;RunService.PreSimulation:Fire();assert(c.Phase=="LAUNCH")
assert(root.AssemblyLinearVelocity.X==9000 and root.AssemblyLinearVelocity.Y==9000 and root.AssemblyLinearVelocity.Z==9000)
local airborne=frame(vec(100,100,100));root.CFrame=airborne
tr.Position=vec(20,3,0)
now=.25;RunService.PreSimulation:Fire();assert(root.CFrame==airborne,"Launch must not reposition the HRP")
root.Position=vec(1010.5,3,0)
now=.26;RunService.PreSimulation:Fire();assert(c.Phase=="CONTACT","Distance must trigger return before timeout")
assert((root.CFrame.Position-tr.Position).Magnitude==.5 and root.AssemblyLinearVelocity.X==9000)
now=.47;RunService.PreSimulation:Fire();assert(c.Phase=="LAUNCH")
root.Position=root.CFrame.Position
now=.58;RunService.PreSimulation:Fire();assert(c.Phase=="CONTACT","Timeout must return a stalled launch")
tr.AssemblyLinearVelocity=vec(1000,0,0)
RunService.PreSimulation:Fire()
assert(math.abs(root.CFrame.Position.X-tr.Position.X-6.5)<.001,"Predictive lead must be bounded to six studs")
tr.AssemblyLinearVelocity=Vector3.zero
target.Character=nil;RunService.PreSimulation:Fire();assert(c.Running and c.Phase=="WAIT_TARGET"and root.CFrame==initial)
target.Character=tc;RunService.PreSimulation:Fire();assert(c.Phase=="CONTACT")
assert(c:Stop());assert(not c.Running and limb.CanCollide and root.CanCollide==false)
assert(hum.AutoRotate and not hum.PlatformStand and hum.SeatedEnabled and root.CFrame==initial)
assert(c:Start(target));authorized=false;RunService.PreSimulation:Fire();assert(not c.Running);authorized=true
AnchorCore={Running=true};assert(c:Start(target));RunService.PreSimulation:Fire();assert(c.Running);c:Stop();AnchorCore=nil
assert(c:Start(target));player.Character={};RunService.PreSimulation:Fire();assert(not c.Running)
print("hybrid OK: owner authorization, parameters, phases, target respawn, restoration, no anchor/seat/external blockers and character replacement")
