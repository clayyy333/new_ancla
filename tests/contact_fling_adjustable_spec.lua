local source=...
setfenv=function()end
table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
local function signal()
 local callbacks={};local s={}
 function s:Connect(f)local c={f=f};function c:Disconnect()self.f=nil end;callbacks[#callbacks+1]=c;return c end
 function s:Fire()for _,c in ipairs(callbacks)do if c.f then c.f()end end end
 return s
end
local function vector(x,y,z)return {X=x,Y=y,Z=z,Magnitude=math.sqrt(x*x+y*y+z*z)}end
Vector3={new=vector}
local walking=vector(16,0,0)
local root={Parent=true,CanCollide=true,Velocity=walking,AssemblyLinearVelocity=walking}
local character={FindFirstChild=function()return root end}
local lp={Character=character,CharacterAdded=signal()}
local rs={PostSimulation=signal()}
local binds={}
function rs:UnbindFromRenderStep(name)binds[name]=nil end
function rs:BindToRenderStep(name,priority,f)binds[name]=f end
local env={}
getgenv=function()return env end
game={GetService=function(_,name)if name=='Players'then return {LocalPlayer=lp}else return rs end end}
local stopped=0
local owner=false
ExperimentalFlingCore={IsAuthorized=function()return owner end}
ContactFlingController={Running=true,Stop=function(self)self.Running=false;stopped=stopped+1 end}
assert(load(source))()(_G)
local core=AdjustableContactFlingController
assert(core.Intensity==100000)
assert(not core:Start()and not core:SetIntensity(500000)and stopped==0,'non-owner cannot activate or configure the owner mode')
owner=true
assert(core:Start()and stopped==1 and not root.CanCollide)
assert(not core:SetIntensity(0/0)and not core:SetIntensity(math.huge)and not core:SetIntensity(99999)and not core:SetIntensity(1000000001))
assert(core:SetIntensity(500000))
rs.PostSimulation:Fire()
assert(root.Velocity.X==500000 and root.Velocity.Y==500000 and root.AssemblyLinearVelocity.Z==500000,'configured pulse applies on all axes')
for _,f in pairs(binds)do f()end
assert(root.Velocity==walking and root.AssemblyLinearVelocity==walking,'walking velocity restored on render')
rs.PostSimulation:Fire();assert(core:SetIntensity(800000))
assert(root.Velocity==walking,'live adjustment restores pending old pulse')
rs.PostSimulation:Fire();core:Stop()
assert(root.CanCollide and root.Velocity==walking and root.AssemblyLinearVelocity==walking,'stop restores pending pulse and collisions')
core:Start();rs.PostSimulation:Fire();lp.CharacterAdded:Fire()
assert(not core.Running and root.Velocity==walking,'respawn cancels pulse')
core:Start();rs.PostSimulation:Fire();owner=false;rs.PostSimulation:Fire()
assert(not core.Running and root.Velocity==walking and root.CanCollide,'owner access loss restores pending pulse and stops')
core:Destroy();assert(next(binds)==nil,'render binding removed')
rs.PostSimulation:Fire();assert(root.Velocity==walking,'destroy disconnects simulation callback')
print('Adjustable contact OK: intensity, live changes, pulse restoration, original mode exclusion, respawn and cleanup')
