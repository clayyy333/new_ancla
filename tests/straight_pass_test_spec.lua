local source=...
setfenv=function()end
local mt={}
Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},mt)end}
Vector3.zero=Vector3.new(0,0,0)
mt.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
mt.__sub=function(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
mt.__mul=function(a,b)return Vector3.new(a.X*b,a.Y*b,a.Z*b)end
mt.__index=function(a,key)
 local length=math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z)
 if key=='Magnitude'then return length end
 if key=='Unit'then return Vector3.new(a.X/length,a.Y/length,a.Z/length)end
end
local fmt={}
CFrame={new=function(p)return setmetatable({Position=p},fmt)end}
fmt.__add=function(frame,offset)return CFrame.new(frame.Position+offset)end
local function rig(x)
 local h={Health=100,PlatformStand=false,AutoRotate=true}
 local values={Position=Vector3.new(x,0,0),AssemblyLinearVelocity=Vector3.zero,AssemblyAngularVelocity=Vector3.zero,Parent=true,Anchored=false}
 values.CFrame=CFrame.new(values.Position)
 local r=setmetatable({}, {__index=values,__newindex=function(_,key,value)
  values[key]=value
  if key=='CFrame'then values.Position=value.Position end
 end})
 return {FindFirstChild=function(_,name)if name=='HumanoidRootPart'then return r end end,FindFirstChildOfClass=function()return h end},h,r
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
local function finish()
 for i=1,40 do
  if not core.Running then break end
  if render then render()end
  if tick then tick(1/60)end
  if post then post()end
 end
 assert(not core.Running,'single shot must complete and disconnect')
 assert(r.CFrame==checkpoint and r.AssemblyLinearVelocity.Magnitude==0,'restore activation checkpoint and clear speed')
 assert(not tick and not post and not render,'no callbacks or automatic relaunch after completion')
end
assert(core:Start());tick(1/60)
assert(core.Cycles==1 and r.AssemblyLinearVelocity.Magnitude==900000000)
assert(r.CFrame==checkpoint and r.Position.X==0,'no teleport or wait at target before launch')
r.Position=r.Position+r.AssemblyLinearVelocity*(1/60);post()
assert(r.Position.X==15000000 and core.Returns==0,'observe physical overshoot before return')
assert(r.AssemblyLinearVelocity.Magnitude==0)
finish()
assert(core.Cycles==1 and core.Returns==1,'one shot, one return, no loop')
assert(h.PlatformStand==false and h.AutoRotate==true)
local report=core:GetDiagnosticReport()
assert(report:find('LAUNCH DIAGNOSTIC V9',1,true))
assert(report:find('HOME_VERIFIED_SINGLE_SHOT_COMPLETE',1,true))
assert(not report:find('TARGET_WAYPOINT_REACHED',1,true),'no stop at HRP waypoint')
-- Manual deactivation uses this activation checkpoint, not any previous one.
r.CFrame=CFrame.new(Vector3.new(10,5,0));checkpoint=r.CFrame
assert(core:Start());tick(1/60)
r.Position=Vector3.new(400,20,0);core:Stop('Manual')
assert(r.CFrame==checkpoint and r.AssemblyLinearVelocity.Magnitude==0)
-- Fixed aim during a single outgoing shot.
assert(core:Start());tick(1/60)
local velocity=r.AssemblyLinearVelocity
tr.Position=Vector3.new(30,30,0);tick(1/60)
assert(r.AssemblyLinearVelocity.X==velocity.X and r.AssemblyLinearVelocity.Y==velocity.Y)
core:Stop('Manual');tr.Position=Vector3.new(30,0,0)
-- No movement or a slow frame must return and finish, never relaunch.
assert(core:Start())
for i=1,50 do if tick then tick(1/60)end;if post then post()end;if render then render()end end
finish();assert(core.Cycles==1)
assert(core:GetDiagnosticReport():find('FLIGHT_TIMEOUT_RETURN',1,true))
assert(core:Start());tick(.2);finish();assert(core.Recoveries==1 and core.Cycles==0)
-- Outgoing rendering can fail: still cleanly return to A.
assert(core:Start());tick(1/60);r.Position=Vector3.new(2000000,0,0);post()
for i=1,30 do if tick then tick(1/60)end end
assert(not core.Running and r.CFrame==checkpoint)
-- Safety guards.
r.Anchored=true;assert(not core:Start());r.Anchored=false
ExperimentalFlingCore.Running=true;assert(not core:Start());ExperimentalFlingCore.Running=false
assert(core:Start());th.Health=0;tick(1/60);assert(not core.Running);th.Health=100
assert(core:Start());core:Destroy();assert(not core.Running and not tick)
-- Bounded diagnostics during many fine-grained steps.
assert(core:Start())
for i=1,200 do tick(.0001);post()end
assert(#core.Samples==120 and #core.FirstSamples==24)
core:Stop('Manual')
assert(core:Start());tick(1/60)
local replacement,_,replacementRoot=rig(70)
player.Character=replacement
local replacementFrame=replacementRoot.CFrame
post()
assert(not core.Running and replacementRoot.CFrame==replacementFrame)
print('straight_pass_test_spec OK: single physical shot from activation point, automatic/manual return and no loop')
