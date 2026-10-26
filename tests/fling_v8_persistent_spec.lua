local source=...
setfenv=function()end
local function signal()
	local callbacks={};local s={}
	function s:Connect(f)local c={Active=true};function c:Disconnect()self.Active=false end;callbacks[#callbacks+1]={c,f};return c end
	function s:Fire()for _,v in ipairs(callbacks)do if v[1].Active then v[2]()end end end
	function s:Count()local n=0;for _,v in ipairs(callbacks)do if v[1].Active then n=n+1 end end;return n end
	return s
end
local vm={}
local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},vm)end
vm.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vm.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__mul=function(a,n)return vec(a.X*n,a.Y*n,a.Z*n)end
vm.__index=function(v,k)
	if k=='Magnitude'then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end
	if k=='Unit'then return v*(1/v.Magnitude)end
end
Vector3={new=vec,zero=vec(0,0,0)}
local fm={};fm.__index=function(f,k)if k=='Rotation'then return f elseif k=='LookVector'then return vec(0,0,-1)end end
fm.__mul=function(f)return f end
CFrame={new=function(v)return setmetatable({Position=v},fm)end}
local now=0;os.clock=function()return now end
local authorized=true
ExperimentalFlingCore={IsAuthorized=function()return authorized end}
UpdateExperimentalFlingPanel=function()end
Players={};RunService={Heartbeat=signal(),PostSimulation=signal(),RenderStepped=signal()}
local cars={}
workspace={FindFirstChild=function()return cars end}
local connected={}
local function rig(x)
	local c={}
	local r={Parent=c,Position=vec(x,3,0),CFrame=CFrame.new(vec(x,3,0)),CanCollide=false}
	function r:GetConnectedParts()return connected end
	local h={Parent=c,Health=100,AutoRotate=true}
	function c:FindFirstChild()return r end
	function c:FindFirstChildOfClass()return h end
	return c,h,r
end
local c,h,r=rig(0);player={Character=c,UserId=123}
local tc,th,tr=rig(10);local target={Parent=Players,Character=tc}
assert(load(source))()(_G)
local core=V8PersistentFlingCore
local function tick(dt)now=now+dt;RunService.Heartbeat:Fire()end
authorized=false;assert(not core:Start(target));authorized=true
assert(not core:SetParameter('Speed',0/0));assert(core:SetParameter('Distance',1000))
assert(not core:SetParameter('AngularSpeed',32768),'V8 must not expose a spin setting')

local home=r.CFrame
assert(core:Start(target));assert(core.Phase=='PREPARE')
-- Simulate observed physics positions separately from CFrame writes.
for i=1,6 do
 r.Position=r.CFrame.Position
 assert(math.abs((r.Position-tr.Position).Magnitude-1000)<.001)
 tick(.21);assert(core.Phase=='INBOUND')
 local v=r.AssemblyLinearVelocity
 assert(math.abs(v.Magnitude-core.Config.Speed)<.001)
 assert(math.abs(v.X)<.001 and math.abs(v.Y)<.001 and v.Z>0,'front departure points back toward target without alternating')
 local frame=r.CFrame
 r.Position=tr.Position+v.Unit*.2
 tick(.001);assert(core.Phase=='PASS_THROUGH')
 assert(r.CFrame==frame,'crossing must not teleport to target')
 assert((r.AssemblyLinearVelocity-v).Magnitude<.001,'keep heading beyond HRP')
 assert(r.AssemblyAngularVelocity.Magnitude==0)
 r.Position=tr.Position+v.Unit*.51
 tick(.001);assert(core.Phase=='PREPARE'and core.Cycles==i+1,'repeat at 0.5 studs past HRP without timed hold')
end
-- A connected vehicle without a passenger must not block departure.
function r:GetConnectedParts()error('vehicle checks must not run')end
r.Position=r.CFrame.Position;tick(.21);assert(core.Phase=='INBOUND')
-- Pulses follow the inbound heading and restore without lateral motion.
local inbound=r.AssemblyLinearVelocity
assert(core:SetParameter('ContactSpeed',300000))
r.Position=tr.Position-inbound.Unit*.1
RunService.PostSimulation:Fire()
assert(math.abs(r.AssemblyLinearVelocity.Magnitude-300000)<.001)
assert((r.AssemblyLinearVelocity.Unit-inbound.Unit).Magnitude<.001)
RunService.RenderStepped:Fire();assert(r.AssemblyLinearVelocity==inbound)
-- Missed arrival retries rather than inventing a successful crossing.
r.Position=vec(900,100,0);tick(2);assert(core.Phase=='PREPARE'and core.Recoveries>0)
th.Health=0;tick(.01);assert(core.Phase=='WAIT_TARGET')
tc,th,tr=rig(50);target.Character=tc;tick(.01);assert(core.Phase=='PREPARE')
local lookup=tc.FindFirstChild
tc.FindFirstChild=function()error('transient')end
tick(.01);assert(core.Phase=='RECOVERING')
tc.FindFirstChild=lookup;tick(.11);assert(core.Phase=='PREPARE')
player.Character=nil;tick(.01);assert(core.Phase=='WAIT_LOCAL')
c,h,r=rig(0);player.Character=c;tick(.01);assert(core.Phase=='PREPARE')
core:Stop();assert(r.CFrame==home and RunService.Heartbeat:Count()==0)
assert(RunService.PostSimulation:Count()==0 and RunService.RenderStepped:Count()==0)
assert(core:Start(target));target.Parent=nil;tick(.01);assert(not core.Running)
target.Parent=Players
for _,case in ipairs({{10,0,0,vec(0,0,-1)},{100,180,0,vec(0,0,1)},{1000,90,0,vec(1,0,0)},{100,0,90,vec(0,1,0)}})do
 assert(core:SetParameter('Distance',case[1]))
 assert(core:SetParameter('Azimuth',case[2]))
 assert(core:SetParameter('Elevation',case[3]))
 assert(core:Start(target))
 local offset=r.CFrame.Position-tr.Position
 assert((offset-case[4]*case[1]).Magnitude<.001,'configured distance/angle must determine CFrame departure')
 assert(core.Config.Speed==174463.14492872442,'departure settings must not change speed')
 core:Stop()
end
core:Destroy()
print('V8 reverse flow OK: six passes, no vehicle dependency, heading preserved, pulse cleanup, timeout, respawn and error recovery')
