local source=...
setfenv=function()end
local mt={}
Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end}
Vector3.zero=Vector3.new(0,0,0)
mt.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
mt.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
mt.__mul=function(a,b)return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
mt.__index=function(a,k)
	local length=math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)
	if k=="Magnitude" then return length end
	if k=="Unit" then return Vector3.new(a.X/length,a.Y/length,a.Z/length)end
	if k=="Dot" then return function(v,b)return v.X*b.X+v.Y*b.Y+v.Z*b.Z end end
end
local cfmt={}
CFrame={new=function(position)return setmetatable({Position=position,Rotation={}},cfmt)end}
cfmt.__mul=function(frame,rotation)frame.Rotation=rotation;return frame end
local function rig(x)
	local h={Health=100}
	local r={Position=Vector3.new(x,0,0),AssemblyLinearVelocity=Vector3.zero,AssemblyAngularVelocity=Vector3.zero,Parent=true,Anchored=false}
	r.CFrame=CFrame.new(r.Position)
	local c={FindFirstChild=function(_,name)if name=="HumanoidRootPart"then return r end end,FindFirstChildOfClass=function()return h end}
	return c,h,r
end
local c,h,r=rig(0)
local tc,th,tr=rig(30)
player={UserId=1,Character=c}
local target={UserId=11773278300,Character=tc}
Players={GetPlayerByUserId=function(_,id)assert(id==target.UserId);return target end}
target.Parent=Players
workspace={FindFirstChild=function()return nil end}
ExperimentalFlingCore={IsAuthorized=function()return true end,Running=false}
local tick,post,render
RunService={PreSimulation={Connect=function(_,fn)tick=fn;return {Disconnect=function()tick=nil end}end},
 PostSimulation={Connect=function(_,fn)post=fn;return {Disconnect=function()post=nil end}end},
 RenderStepped={Connect=function(_,fn)render=fn;return {Disconnect=function()render=nil end}end}}
local context={ExperimentalFlingCore=ExperimentalFlingCore}
assert(load(source))()(context)
local core=StraightPassTestCore
local checkpoint=r.CFrame
assert(core:Start())
tick(1/60)
assert(r.AssemblyLinearVelocity.Magnitude==900000000)
assert(tr.AssemblyLinearVelocity.Magnitude==0,"target must not be modified")
assert(r.CFrame==checkpoint,'launch uses velocity, not an outgoing teleport')
r.Position=r.Position+r.AssemblyLinearVelocity*(1/60)
assert(r.Position.X==15000000,'physics step can exceed one million')
post()
assert(core.Running and r.AssemblyLinearVelocity.Magnitude==0)
assert(core.Returns==0,'post simulation must not immediately return')
assert(core:GetDiagnosticReport():find('observedDistance=15000000.00',1,true),'record observed overshoot')
assert(not core:GetDiagnosticReport():find('RETURN_TARGET',1,true),'no target return phase')
render()
local liveReport=core:GetDiagnosticReport()
assert(liveReport:find('LAUNCH DIAGNOSTIC V2',1,true))
assert(liveReport:find('PRE_BEFORE_WRITE',1,true) and liveReport:find('PRE_AFTER_WRITE',1,true))
assert(liveReport:find('POST_PHYSICS',1,true) and liveReport:find('WAIT_OUTGOING_RENDER',1,true))
assert(liveReport:find('RENDER_OUTGOING_LOCAL',1,true))
assert(liveReport:find('maxPostDistance=15000000.000',1,true) and liveReport:find('maxRenderDistance=15000000.000',1,true),'render sees outgoing position before return')
tick(1/60)
assert(core.Returns==1 and r.CFrame==checkpoint,'return after render on next simulation step')
assert(core.Cycles==1 and r.AssemblyLinearVelocity.Magnitude==0,'do not relaunch during return step')
r.Position=checkpoint.Position
tick(1/60)
assert(core.Cycles==2 and r.AssemblyLinearVelocity.Magnitude==900000000,'automatically launch next cycle')
core:Stop('Manual')
assert(not core.Running and r.AssemblyLinearVelocity.Magnitude==0 and tick==nil and post==nil and render==nil)
assert(core:GetDiagnosticReport():find('maxPostDistance=15000000.000',1,true),'stopped report keeps measurements')
tr.Position=Vector3.new(30,0,0)
r.Position=Vector3.new(0,0,0);r.Anchored=true
assert(not core:Start());r.Anchored=false
assert(core:GetDiagnosticReport():find('LAST START REJECTED',1,true))
ExperimentalFlingCore.Running=true;assert(not core:Start());ExperimentalFlingCore.Running=false
assert(core:Start());th.Health=0;tick(1/60)
assert(not core.Running and r.AssemblyLinearVelocity.Magnitude==0)
th.Health=100
assert(core:Start());tick(.2);assert(not core.Running,"cancel on long physics frame")
assert(core:Start());core:Destroy();assert(not core.Running and tick==nil and post==nil)
tr.Position=Vector3.new(228,0,0)
assert(core:Start(),'extended target range must be available')
tick(1/60);r.Position=Vector3.new(1000000,0,0);post()
assert(core.Running and r.AssemblyLinearVelocity.Magnitude==0,'return without disabling the repeated test')
assert(core.Returns==0)
tick(1/60);post()
assert(core.Returns==0 and r.AssemblyLinearVelocity.Magnitude==0,'extra physics before render must hold, not relaunch')
render();tick(1/60)
assert(core.Returns==1)
core:Stop('Manual')
r.Position=Vector3.new(0,0,0)
tr.Position=Vector3.new(229,0,0)
assert(not core:Start(),'reject targets beyond extended travel range')
tr.Position=Vector3.new(30,40,0)
assert(core:Start());tick(1/60)
assert(math.abs(r.AssemblyLinearVelocity.X-540000000)<0.001 and math.abs(r.AssemblyLinearVelocity.Y-720000000)<0.001,'3D velocity points through HRP height')
core:Stop('Manual')
tr.Position=Vector3.new(30,0,0)
assert(core:Start());r.CFrame={};core:Stop("Manual")
assert(r.CFrame==checkpoint,"manual cancellation restores checkpoint")
assert(core:Start());local deadFrame={};r.CFrame=deadFrame;h.Health=0;tick(1/60)
assert(r.CFrame==deadFrame,"do not teleport dead character");h.Health=100
r.CFrame=checkpoint
-- Missing render must cancel rather than leaving the character far indefinitely.
assert(core:Start());tick(1/60);r.Position=Vector3.new(2000000,0,0);post()
for i=1,20 do if tick then tick(1/60) end end
assert(not core.Running and core:GetDiagnosticReport():find('No hubo render local',1,true))
r.Position=checkpoint.Position
-- Cancel if the engine keeps us below the distance threshold for too long.
assert(core:Start())
for i=1,50 do if tick then tick(1/60);if post then post()end end end
assert(not core.Running and r.AssemblyLinearVelocity.Magnitude==0)
-- Diagnostic storage must remain bounded during a repeated run.
assert(core:Start())
for i=1,150 do
 r.Position=checkpoint.Position;tick(1/60)
 r.Position=Vector3.new(2000000,0,0);post()
 render();tick(1/60)
end
assert(core.Cycles==150 and #core.Samples==120)
assert(#core.FirstSamples==24 and core.FirstSamples[1]:find('phase=START',1,true),'preserve startup evidence')
core:Stop('Manual');r.Position=checkpoint.Position
assert(core:Start())
local replacement,_,replacementRoot=rig(70)
player.Character=replacement
local replacementFrame=replacementRoot.CFrame
tick(1/60)
assert(not core.Running and replacementRoot.CFrame==replacementFrame,"do not move replacement character")
print("straight_pass_test_spec OK")
