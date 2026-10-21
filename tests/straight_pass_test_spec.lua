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
 local h={Health=100,PlatformStand=false,AutoRotate=true}
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
local function launch()
 tick(1/60)
 assert(math.abs(r.AssemblyLinearVelocity.Magnitude-900000000)<1,'full velocity on first step from A')
 assert(r.Position.Magnitude==0 and r.CFrame==checkpoint,'no approach movement or outgoing teleport before velocity launch')
end
local function recover()
 local before=core.Returns
 local cycles=core.Cycles
 for i=1,12 do
  render();tick(1/60)
  if core.Returns>before then break end
 end
 assert(core.Returns==before+1 and r.CFrame==checkpoint,'return after outgoing hold and renders')
 assert(r.AssemblyLinearVelocity.Magnitude==0,'return is separated from next launch')
 render();tick(1/60)
 assert(core.Cycles==cycles,'origin must be rendered before relaunch')
end
assert(core:Start())
launch()
assert(core:GetDiagnosticReport():find('LAUNCH_FROM_A',1,true))
tick(1/60)
assert(r.AssemblyLinearVelocity.Magnitude==900000000,'full velocity maintained along outgoing leg')
assert(tr.AssemblyLinearVelocity.Magnitude==0,'never modify target')
r.Position=r.Position+r.AssemblyLinearVelocity*(1/60)
assert(r.Position.X>=15000000,'overshoot remains observable')
post()
assert(core.Returns==0 and r.AssemblyLinearVelocity.Magnitude==0)
render()
assert(core.MaxRenderDistance>=15000000,'outgoing position is sampled at render')
tick(1/60)
assert(core.Returns==0,'one outgoing frame must not trigger return')
recover()
launch()
assert(core.Cycles==2,'relaunch at full speed from original A')
core:Stop('Manual')
assert(not core.Running and tick==nil and post==nil and render==nil and r.CFrame==checkpoint)
assert(h.PlatformStand==false and h.AutoRotate==true,'restore ordinary Humanoid controls')
local report=core:GetDiagnosticReport()
assert(report:find('LAUNCH DIAGNOSTIC V5',1,true) and report:find('RETURN_ORIGIN_AFTER_RENDER',1,true))
assert(report:find('RENDER_HOME_LOCAL',1,true))
assert(not report:find('CROSS_BEGIN',1,true) and not report:find('CROSS_GEOMETRIC_CONFIRMED',1,true),'no slow crossing stages remain')
-- Preserve a straight direction per outgoing leg, recalculate on next launch.
assert(core:Start())
launch()
local initialVelocity=r.AssemblyLinearVelocity
tr.Position=Vector3.new(30,5,0)
tick(1/60)
assert(r.AssemblyLinearVelocity.X==initialVelocity.X and r.AssemblyLinearVelocity.Y==initialVelocity.Y,'do not curve an outgoing leg')
core:Stop('Manual');tr.Position=Vector3.new(30,0,0)
-- No movement despite velocity must time out, not hang indefinitely.
assert(core:Start())
for i=1,50 do if tick then tick(1/60);if post then post()end end end
assert(not core.Running and core:GetDiagnosticReport():find('No alcanzo el umbral',1,true))
-- Missing render cancels safely after a successful departure.
assert(core:Start());launch();r.Position=Vector3.new(2000000,0,0);post()
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
assert(core:Start());launch()
assert(math.abs(r.AssemblyLinearVelocity.X-540000000)<1 and math.abs(r.AssemblyLinearVelocity.Y-720000000)<1)
core:Stop('Manual');tr.Position=Vector3.new(30,0,0)
assert(core:Start())
for i=1,150 do
 launch();r.Position=Vector3.new(2000000,0,0);post();recover()
end
assert(core.Cycles==150 and #core.Samples==120 and #core.FirstSamples==24)
core:Stop('Manual')
assert(core:Start())
local replacement,_,replacementRoot=rig(70)
player.Character=replacement
local replacementFrame=replacementRoot.CFrame
tick(1/60)
assert(not core.Running and replacementRoot.CFrame==replacementFrame)
print('straight_pass_test_spec OK: full velocity from A, fixed outgoing direction, repeat, recovery and diagnostics')
