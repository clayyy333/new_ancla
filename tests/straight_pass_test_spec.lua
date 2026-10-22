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
local frameMT={}
CFrame={new=function(position)return setmetatable({Position=position},frameMT)end}
frameMT.__add=function(frame,offset)return CFrame.new(frame.Position+offset)end
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
 assert(r.AssemblyLinearVelocity.Magnitude==0,'physical velocity must not override CFrame route')
 assert((r.Position-tr.Position).Magnitude<0.001,'mandatory HRP waypoint reached before B')
 render();tick(1/60)
 assert(math.abs(r.AssemblyLinearVelocity.Magnitude-900000000)<1,'physical pulse starts at target waypoint')
 r.Position=r.Position+r.AssemblyLinearVelocity*(1/60)
 local observedContactPosition=r.Position
 post()
 assert(r.Position==observedContactPosition,'post simulation must not snap or clear during contact')
 assert(math.abs(r.AssemblyLinearVelocity.Magnitude-900000000)<1,'contact velocity must survive post simulation')
 for i=1,30 do
  tick(1/60)
  if r.AssemblyLinearVelocity.Magnitude>0 then r.Position=r.Position+r.AssemblyLinearVelocity*(1/60)end
  post()
  if math.abs(r.Position.Magnitude-1000000)<0.001 and r.AssemblyLinearVelocity.Magnitude==0 then break end
 end
 assert(math.abs(r.Position.Magnitude-1000000)<0.001,'B is fixed one million from A')
 assert(core.ContactPulses==core.Cycles,'one contact pulse per cycle')
 post()
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
 post();render();tick(1/60);post();render();tick(1/60)
 assert(core.Cycles==cycles,'origin must be rendered before relaunch')
end
assert(core:Start())
launch()
assert(core:GetDiagnosticReport():find('LAUNCH_FROM_A',1,true))
tick(1/60)
assert(r.AssemblyLinearVelocity.Magnitude==0,'route does not depend on physical launch')
assert(tr.AssemblyLinearVelocity.Magnitude==0,'never modify target')
r.Position=Vector3.new(1200000,500,0)
post()
assert(core.Returns==0 and r.AssemblyLinearVelocity.Magnitude==0)
assert(r.Position.X==1000000 and r.Position.Y==0,'post-physics drift does not change route')
render()
assert(core.MaxRenderDistance==1000000,'outgoing position is sampled at render')
tick(1/60)
assert(core.Returns==0,'one outgoing frame must not trigger return')
recover()
launch()
assert(core.Cycles==2,'relaunch route from original A')
core:Stop('Manual')
assert(not core.Running and tick==nil and post==nil and render==nil and r.CFrame==checkpoint)
assert(h.PlatformStand==false and h.AutoRotate==true,'restore ordinary Humanoid controls')
local report=core:GetDiagnosticReport()
assert(report:find('LAUNCH DIAGNOSTIC V8',1,true) and report:find('RETURN_ORIGIN_AFTER_RENDER',1,true))
assert(report:find('HOME_VERIFY_STABLE',1,true),'home position is verified after physics before relaunch')
assert(report:find('CONTACT_BEGIN',1,true) and report:find('CONTACT_POST_PHYSICS',1,true) and report:find('CONTACT_END',1,true),'contact lifecycle is diagnosed')
assert(report:find('RENDER_HOME_LOCAL',1,true))
assert(report:find('TARGET_WAYPOINT_REACHED',1,true) and report:find('RENDER_TARGET_WAYPOINT',1,true))
-- Preserve a straight direction per outgoing leg, recalculate on next launch.
assert(core:Start())
tick(1/60)
local targetPoint=r.Position
tr.Position=Vector3.new(30,5,0)
tick(1/60)
assert((r.Position-targetPoint).Magnitude==0,'wait at snapshot waypoint for its render')
core:Stop('Manual');tr.Position=Vector3.new(30,0,0)
-- A missing target-waypoint render must time out, not skip that point.
assert(core:Start())
for i=1,50 do if tick then tick(1/60);if post then post()end end end
assert(not core.Running and core:GetDiagnosticReport():find('Tiempo del recorrido',1,true))
-- Missing render cancels safely after a successful departure.
assert(core:Start());launch()
for i=1,20 do if tick then tick(1/60)end end
assert(not core.Running and core:GetDiagnosticReport():find('No hubo render local',1,true))
-- Safety guards and clean destruction.
r.Anchored=true;assert(not core:Start());r.Anchored=false
assert(core:GetDiagnosticReport():find('LAST START REJECTED',1,true))
ExperimentalFlingCore.Running=true;assert(not core:Start());ExperimentalFlingCore.Running=false
assert(core:Start());th.Health=0;tick(1/60);assert(not core.Running);th.Health=100
assert(core:Start());tick(1/60);render();tick(1/60)
assert(r.AssemblyLinearVelocity.Magnitude==900000000)
th.Health=0;post();assert(not core.Running and r.AssemblyLinearVelocity.Magnitude==0,'death during physical contact must cancel and clean up');th.Health=100
assert(core:Start());tick(.2)
assert(core.Running and core.Recoveries==1 and r.CFrame==checkpoint,'long frames recover at A instead of killing repetition')
-- External drift during return must reset verification, not permit relaunch.
r.Position=Vector3.new(5,0,0);post()
assert(r.CFrame==checkpoint and r.Position.Magnitude==0)
render();tick(1/60)
assert(core.Cycles==0,'do not launch before two stable post-physics observations')
post();render();tick(1/60)
assert(core.Cycles==0)
post();render();tick(1/60)
assert(core.Cycles==0)
tick(1/60)
assert(core.Cycles==1 and (r.Position-tr.Position).Magnitude<0.001,'resume after stable return')
core:Stop('Manual')
-- Very large contact overshoot must be placed at B directly on contact completion.
assert(core:Start());tick(1/60);render();tick(1/60)
r.Position=Vector3.new(500000000,0,0);post()
for i=1,2 do tick(1/60);post()end
tick(1/60);post()
assert(core.Running and math.abs(r.Position.X-1000000)<0.001,'contact overshoot cannot turn into a long second trip')
assert(core:GetDiagnosticReport():find('B_FIXED_AFTER_CONTACT',1,true))
core:Stop('Manual')
assert(core:Start());core:Destroy();assert(not core.Running and render==nil)
tr.Position=Vector3.new(229,0,0);assert(not core:Start());tr.Position=Vector3.new(30,0,0)
-- Signed 3D aiming, bounded diagnostics and no replacement-character teleport.
tr.Position=Vector3.new(30,40,0)
assert(core:Start());launch()
assert(math.abs(r.Position.X-600000)<1 and math.abs(r.Position.Y-800000)<1,'B follows 3D ray through target')
core:Stop('Manual');tr.Position=Vector3.new(30,0,0)
assert(core:Start())
for i=1,150 do
 launch();recover()
end
assert(core.Cycles==150 and #core.Samples==120 and #core.FirstSamples==24)
core:Stop('Manual')
assert(core:Start())
local replacement,_,replacementRoot=rig(70)
player.Character=replacement
local replacementFrame=replacementRoot.CFrame
tick(1/60)
assert(not core.Running and replacementRoot.CFrame==replacementFrame)
print('straight_pass_test_spec OK: target waypoint, physical contact pulse without post cleanup, fixed B and recovery')
