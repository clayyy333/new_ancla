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
local fm={};fm.__index=function(f,k)if k=='Rotation'then return f end end
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
assert(core:Start(target));assert(core.Phase=='CONTACT'and core.Cycles==1 and r.CanCollide and not h.AutoRotate)
RunService.PostSimulation:Fire();assert(r.AssemblyLinearVelocity.X==100000)
RunService.RenderStepped:Fire();assert(r.AssemblyLinearVelocity.Magnitude==0)
for i=1,6 do
	tick(.21);assert(core.Phase=='LAUNCH')
	local v=r.AssemblyLinearVelocity
	RunService.PostSimulation:Fire();RunService.RenderStepped:Fire()
	assert(r.AssemblyLinearVelocity==v,'contact pulse must not overwrite launch')
	assert(math.abs(v.X)>0 and math.abs(v.Y)>0 and math.abs(v.Z)>0,'every departure must be diagonal on all three axes')
	assert(math.abs(v.Magnitude-core.Config.Speed)<.001,'diagonal must preserve configured total speed')
	assert(r.AssemblyAngularVelocity.Magnitude==0,'launch must not impose spin')
	tick(.26);assert(core.Phase=='RETURN')
	local returning=r.AssemblyLinearVelocity
	assert((returning+v).Magnitude<.001,'return must reverse the same diagonal')
	assert(r.AssemblyAngularVelocity.Magnitude==0,'return must not impose spin')
	tick(.26);assert(core.Phase=='CONTACT'and core.Cycles==i+1)
	assert(r.AssemblyAngularVelocity.Magnitude==0,'contact must not impose spin')
	assert((r.CFrame.Position-tr.Position).Magnitude<.501,'every cycle must reacquire the current target')
end
-- Owned vehicle exists but must be physically connected to enable the gate.
local vehicle={Parent=cars,GetAttribute=function()return 123 end,FindFirstChild=function()return nil end}
local body={Parent=vehicle}
connected={body};th.SeatPart=nil
tick(.21);assert(core.Phase=='CONTACT'and core.WaitingForPassenger)
local cycles=core.Cycles;tick(5);assert(core.Phase=='CONTACT'and core.Cycles==cycles,'passenger wait must not time out')
local weld={Part1={IsDescendantOf=function(_,other)return other==tc end},IsA=function(_,kind)return kind=='JointInstance' end}
local seat={Occupant=th,IsDescendantOf=function(_,other)return other==vehicle end,FindFirstChild=function()return weld end}
weld.Part0=seat;th.SeatPart=seat
tick(.01);assert(core.Phase=='LAUNCH'and not core.WaitingForPassenger)
tick(.26);tick(.26);th.SeatPart=nil
tick(.21);assert(core.Phase=='CONTACT'and core.WaitingForPassenger,'must validate passenger on every launch')
connected={};tick(.01);assert(core.Phase=='LAUNCH','disconnecting vehicle must restore normal V8')
tick(.26);tick(.26)
th.Health=0;tick(.01);assert(core.Running and core.Phase=='WAIT_TARGET')
target.Character=nil;tick(.01);assert(core.Running and core.Phase=='WAIT_TARGET')
tc,th,tr=rig(50);target.Character=tc;tick(.01)
assert(core.Phase=='CONTACT'and(r.CFrame.Position-tr.Position).Magnitude<.501,'target respawn must resume automatically')
-- Replacing only HRP must invalidate the old phase as well.
tick(.21);assert(core.Phase=='LAUNCH')
local old=tr;tr={Parent=tc,Position=vec(80,3,0),CFrame=CFrame.new(vec(80,3,0))}
tc.FindFirstChild=function()return tr end
tick(.01);assert(core.Phase=='CONTACT'and(r.CFrame.Position-tr.Position).Magnitude<.501)
-- A transient engine/read error must not leave the phase frozen.
local lookup=tc.FindFirstChild
tc.FindFirstChild=function()error('transient test error')end
tick(.01);assert(core.Running and core.Phase=='RECOVERING'and core.LastError)
tc.FindFirstChild=lookup;tick(.11);assert(core.Phase=='CONTACT')
tick(5);assert(core.Phase=='CONTACT'and core.Recoveries>=2,'stale phase must restart at the live target')
local oldLocal=c;player.Character=nil;tick(.01);assert(core.Phase=='WAIT_LOCAL'and core.Running)
c,h,r=rig(5);player.Character=c;tick(.01);assert(core.Running and core.Phase=='CONTACT')
assert(core:Stop());assert(r.CFrame==home and not r.CanCollide and h.AutoRotate and RunService.Heartbeat:Count()==0)
assert(core:Start(target));target.Parent=nil;tick(.01);assert(not core.Running and RunService.Heartbeat:Count()==0)
target.Parent=Players;assert(core:Start(target));authorized=false;tick(.01);assert(not core.Running)
core:Destroy()
print('V8 persistent OK: six cycles, target death/respawn, HRP replacement, transient errors, stalled phases, local respawn, restore and owner authorization')
