local source=...
setfenv=function()end
local function signal()
 local callbacks={};local s={}
 function s:Connect(fn)local c={Active=true};function c:Disconnect()self.Active=false end;callbacks[#callbacks+1]={c,fn};return c end
 function s:Fire()for _,item in ipairs(callbacks)do if item[1].Active then item[2]()end end end
 function s:Count()local n=0;for _,item in ipairs(callbacks)do if item[1].Active then n=n+1 end end;return n end
 return s
end
local vm={}
local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},vm)end
vm.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vm.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__mul=function(a,n)return vec(a.X*n,a.Y*n,a.Z*n)end
vm.__index=function(v,k)if k=='Magnitude'then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)elseif k=='Unit'then return v*(1/v.Magnitude)end end
Vector3={new=vec,zero=vec(0,0,0)}
local fm={};fm.__index=function(f,k)if k=='Rotation'then return f elseif k=='LookVector'then return vec(0,0,-1)end end
fm.__mul=function(a,b)return setmetatable({Position=a.Position+b.Position},fm)end
CFrame={new=function(x,y,z)return setmetatable({Position=type(x)=='table'and x or vec(x,y,z)},fm)end,Angles=function()return setmetatable({Position=vec(0,0,0)},fm)end}
Enum={HumanoidStateType={Seated=1,GettingUp=2,Dead=3}}
local clock=0;os.clock=function()return clock end
local authorized=false
ExperimentalFlingCore={IsAuthorized=function()return authorized end}
Players={};RunService={Heartbeat=signal(),PostSimulation=signal(),RenderStepped=signal()}
UpdateObjectFlingPanel=function()end
local hidden={}
sethiddenproperty=function(object,key,value)hidden[object]=hidden[object]or{};hidden[object][key]=value end
local function rig(x)
 local c={};local r={Parent=c,Position=vec(x,3,0),CFrame=CFrame.new(vec(x,3,0)),CanCollide=false,Massless=false}
 local body={Parent=c,Position=vec(x,3,0),CFrame=r.CFrame,CanCollide=true,Massless=true}
 function r:IsA(kind)return kind=='BasePart'end;body.IsA=r.IsA
 local h={Parent=c,Health=100,AutoRotate=true,PlatformStand=false,Sit=false}
 function h:Move(v)self.LastMove=v end
 function h:ChangeState(v)self.State=v end
 function h:TakeDamage(v)self.LastDamage=v end
 function c:GetDescendants()return {r,body}end
 function c:FindFirstChild()return r end
 function c:FindFirstChildOfClass()return h end
 return c,h,r,body
end
local c,h,r,body=rig(0);player={Character=c,UserId=123}
local tc,th,tr=rig(10);local target={Parent=Players,Character=tc}
assert(load(source))()(_G)
local core=ObjectV8FlingCore
local function tick(dt)clock=clock+dt;RunService.Heartbeat:Fire()end
assert(not core:Start(target)and not core:SetTarget(target),'non-owners cannot activate or select')
authorized=true
assert(core:SetTarget(target)and core:SetParameter('Azimuth',0))
assert(not core:SetParameter('Speed',0/0)and not core:SetParameter('ContactSpeed',100),'old pulse setting removed')
assert(not core:SetMode('unknown'))
local home=r.CFrame
assert(core:Start(target)and core.Phase=='PREPARE')
assert(RunService.Heartbeat:Count()==1 and RunService.PostSimulation:Count()==0 and RunService.RenderStepped:Count()==0,'one writer; no legacy contact pulses')
for _,mode in ipairs({'CINTURA','ROTACION','CLASICO'})do
 assert(core:SetMode(mode))
 r.Position=r.CFrame.Position;tick(.21);assert(core.Phase=='INBOUND')
 assert(math.abs(r.AssemblyLinearVelocity.Magnitude-core.Config.Speed)<.01)
 local direction=r.AssemblyLinearVelocity.Unit;r.Position=tr.Position+direction*.2
 tick(.001);assert(core.Phase=='HIT'and h.PlatformStand and r.CanCollide and r.Massless)
 if mode=='ROTACION'then assert(r.AssemblyAngularVelocity.Y>=100000)
 else assert(r.AssemblyLinearVelocity.X~=r.AssemblyLinearVelocity.X,'selected NaN modes retain original local write attempt')end
 tick(1.51);assert(core.Phase=='PREPARE'and not h.PlatformStand and r.AssemblyLinearVelocity.Magnitude==0,'hit finishes before departure resumes')
 assert(not r.CanCollide and not r.Massless and body.CanCollide and body.Massless,'phase boundary restores original part properties')
end
th.Health=0;tick(.01);assert(core.Phase~='WAIT_TARGET','local health alone cannot invalidate target')
local good=tr.Position;tr.Position=vec(0/0,3,0);tick(.01);assert(core.Phase=='WAIT_TARGET')
tr.Position=vec(math.huge,3,0);tick(.01);assert(core.Phase=='WAIT_TARGET')
tr.Position=good;tick(.01);assert(core.Phase=='PREPARE')
target.Character=nil;tick(.01);assert(core.Phase=='WAIT_TARGET')
tc,th,tr=rig(30);target.Character=tc;tick(.01);assert(core.Phase=='PREPARE','new character is reacquired')
assert(core:SetSitKillEnabled(true))
r.Position=r.CFrame.Position;tick(.21);r.Position=tr.Position;tick(.001);assert(core.Phase=='HIT')
tick(.01);assert(th.Health==100,'first scheduled step does not claim death')
tick(.01);assert(th.Health==0 and th.LastDamage==999999,'optional local attempt acts only on selected rig')
core:Stop();assert(r.CFrame==home and not r.CanCollide and not r.Massless and h.AutoRotate and not h.PlatformStand)
assert(RunService.Heartbeat:Count()==0,'stop disconnects the only writer')
assert(core:Start(target));player.Character=nil;tick(.01);assert(core.Phase=='WAIT_LOCAL')
c,h,r,body=rig(0);player.Character=c;tick(.01);assert(core.Phase=='PREPARE')
local otherC,otherH,otherR=rig(100);local other={Parent=Players,Character=otherC}
assert(core:SetTarget(other));tick(.01);assert(core:GetTarget()==other and core.Phase=='PREPARE')
authorized=false;tick(.01);assert(not core.Running and RunService.Heartbeat:Count()==0,'revoked access stops the controller')
core:Destroy()
print('Fling test owner integration OK: modes, exclusive phases, selected target only, local health, invalid coordinates, respawn, restoration and cleanup')
