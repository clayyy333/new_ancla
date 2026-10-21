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
local function rig(x)
	local h={Health=100}
	local r={Position=Vector3.new(x,0,0),AssemblyLinearVelocity=Vector3.zero,AssemblyAngularVelocity=Vector3.zero,Parent=true,Anchored=false}
	r.CFrame={Position=r.Position}
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
local tick
RunService={PreSimulation={Connect=function(_,fn)tick=fn;return {Disconnect=function()tick=nil end}end}}
local context={ExperimentalFlingCore=ExperimentalFlingCore}
assert(load(source))()(context)
local core=StraightPassTestCore
local checkpoint=r.CFrame
assert(core:Start())
tick(1/60)
assert(r.AssemblyLinearVelocity.Magnitude==300)
assert(tr.AssemblyLinearVelocity.Magnitude==0,"target must not be modified")
r.Position=Vector3.new(42,0,0)
r.CFrame={Position=r.Position}
tick(1/60)
assert(not core.Running and r.AssemblyLinearVelocity.Magnitude==0)
assert(r.CFrame==checkpoint,"completion restores activation CFrame")
assert(core:GetDiagnosticReport():find("Recorrido terminado",1,true))
r.Position=Vector3.new(0,0,0);r.Anchored=true
assert(not core:Start());r.Anchored=false
ExperimentalFlingCore.Running=true;assert(not core:Start());ExperimentalFlingCore.Running=false
assert(core:Start());th.Health=0;tick(1/60)
assert(not core.Running and r.AssemblyLinearVelocity.Magnitude==0)
th.Health=100
assert(core:Start());tick(.2);assert(not core.Running,"cancel on long physics frame")
assert(core:Start());core:Destroy();assert(not core.Running and tick==nil)
assert(core:Start());r.CFrame={};core:Stop("Manual")
assert(r.CFrame==checkpoint,"manual cancellation restores checkpoint")
assert(core:Start());local deadFrame={};r.CFrame=deadFrame;h.Health=0;tick(1/60)
assert(r.CFrame==deadFrame,"do not teleport dead character");h.Health=100
r.CFrame=checkpoint
assert(core:Start())
local replacement,_,replacementRoot=rig(70)
player.Character=replacement
local replacementFrame=replacementRoot.CFrame
tick(1/60)
assert(not core.Running and replacementRoot.CFrame==replacementFrame,"do not move replacement character")
print("straight_pass_test_spec OK")
