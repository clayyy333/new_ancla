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
 if k=='Magnitude'then return length end
 if k=='Unit'then return Vector3.new(a.X/length,a.Y/length,a.Z/length)end
 if k=='Dot'then return function(v,b)return v.X*b.X+v.Y*b.Y+v.Z*b.Z end end
end
CFrame={new=function(position)return {Position=position}end}
local function rig(x)
 local h={Health=100}
 local values={Position=Vector3.new(x,0,0),AssemblyLinearVelocity=Vector3.zero,AssemblyAngularVelocity=Vector3.zero,Parent=true,Anchored=false}
 values.CFrame=CFrame.new(values.Position)
 local r=setmetatable({}, {__index=values,__newindex=function(_,key,value)
  values[key]=value
  if key=='CFrame'then values.Position=value.Position end
 end})
 local c={FindFirstChild=function(_,name)if name=='HumanoidRootPart'then return r end end,FindFirstChildOfClass=function()return h end}
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
assert(load(source))()({ExperimentalFlingCore=ExperimentalFlingCore})
local core=StraightPassTestCore
local checkpoint=r.CFrame
local function nearCross()
 local previous=core.Crossings
 for i=1,300 do
  assert(core.Running,'test stopped before geometric crossing')
  tick(1/60)
  assert(r.AssemblyLinearVelocity.Magnitude<=120.001,'near leg must not use far velocity')
  assert(r.CFrame==checkpoint,'no outgoing teleport')
  r.Position=r.Position+r.AssemblyLinearVelocity*(1/60)
  post()
  if core.Crossings>previous then return end
 end
 error('crossing was not detected')
end
assert(core:Start())
nearCross()
assert(r.Position.X>=32 and core.Crossings==1)
assert(core:GetDiagnosticReport():find('CROSS_GEOMETRIC_CONFIRMED',1,true))
tick(1/60)
assert(r.AssemblyLinearVelocity.Magnitude==900000000,'far velocity only after crossing')
assert(tr.AssemblyLinearVelocity.Magnitude==0,'never modify target')
r.Position=r.Position+r.AssemblyLinearVelocity*(1/60)
assert(r.Position.X>15000000,'overshoot remains observable')
post()
assert(core.Returns==0 and r.AssemblyLinearVelocity.Magnitude==0)
render()
assert(core.MaxRenderDistance>15000000,'outgoing position is sampled at render')
tick(1/60)
assert(core.Returns==1 and r.CFrame==checkpoint)
assert(r.AssemblyLinearVelocity.Magnitude==0,'do not relaunch on return step')
nearCross()
assert(core.Cycles==2 and core.Crossings==2,'each repeated cycle crosses before accelerating')
core:Stop('Manual')
assert(not core.Running and tick==nil and post==nil and render==nil and r.CFrame==checkpoint)
local report=core:GetDiagnosticReport()
assert(report:find('LAUNCH DIAGNOSTIC V3',1,true) and report:find('RETURN_ORIGIN_AFTER_RENDER',1,true))
-- A target that moves during crossing must be reacquired, not blindly accelerated at.
assert(core:Start())
for i=1,13 do tick(1/60);r.Position=r.Position+r.AssemblyLinearVelocity*(1/60);post()end
tr.Position=Vector3.new(30,5,0)
tick(1/60);r.Position=r.Position+r.AssemblyLinearVelocity*(1/60);post()
assert(core.Crossings==0 and core:GetDiagnosticReport():find('CROSS_TARGET_MOVED',1,true))
core:Stop('Manual');tr.Position=Vector3.new(30,0,0)
-- Near-phase blocking must cancel without ever engaging far velocity.
assert(core:Start())
for i=1,310 do if tick then tick(1/60);assert(r.AssemblyLinearVelocity.Magnitude<900000000);if post then post()end end end
assert(not core.Running and core:GetDiagnosticReport():find('Cruce cercano no confirmado',1,true))
-- Missing render cancels safely after a successful departure.
assert(core:Start());nearCross();tick(1/60);r.Position=Vector3.new(2000000,0,0);post()
for i=1,20 do if tick then tick(1/60)end end
assert(not core.Running and core:GetDiagnosticReport():find('No hubo render local',1,true))
-- Safety guards and clean destruction.
r.Anchored=true;assert(not core:Start());r.Anchored=false
assert(core:GetDiagnosticReport():find('LAST START REJECTED',1,true))
ExperimentalFlingCore.Running=true;assert(not core:Start());ExperimentalFlingCore.Running=false
assert(core:Start());th.Health=0;tick(1/60);assert(not core.Running);th.Health=100
assert(core:Start());tick(.2);assert(not core.Running)
assert(core:Start());core:Destroy();assert(not core.Running and render==nil)
tr.Position=Vector3.new(229,0,0);assert(not core:Start());tr.Position=Vector3.new(30,0,0)
-- Signed 3D aiming, bounded diagnostics and no replacement-character teleport.
tr.Position=Vector3.new(30,40,0)
assert(core:Start());nearCross();tick(1/60)
assert(math.abs(r.AssemblyLinearVelocity.X-540000000)<1 and math.abs(r.AssemblyLinearVelocity.Y-720000000)<1)
core:Stop('Manual');tr.Position=Vector3.new(30,0,0)
assert(core:Start())
for i=1,6 do
 nearCross();tick(1/60);r.Position=Vector3.new(2000000,0,0);post();render();tick(1/60)
end
assert(core.Cycles==6 and #core.Samples==120 and #core.FirstSamples==24)
core:Stop('Manual')
assert(core:Start())
local replacement,_,replacementRoot=rig(70)
player.Character=replacement
local replacementFrame=replacementRoot.CFrame
tick(1/60)
assert(not core.Running and replacementRoot.CFrame==replacementFrame)
print('straight_pass_test_spec OK: controlled crossing before far acceleration, repeat, recovery and diagnostics')
