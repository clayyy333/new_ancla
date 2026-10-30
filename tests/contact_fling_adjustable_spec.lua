local source=...
local now=100;os.clock=function()return now end
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
assert(core:IsAuthorized(),'adjustable contact is public')
assert(not core:SetPulseParameter('Duration',.05),'advanced timing is owner only')
owner=true
assert(core:Start()and stopped==1 and not root.CanCollide)
assert(not core:SetIntensity(0/0)and not core:SetIntensity(math.huge)and not core:SetIntensity(99999)and not core:SetIntensity(1000000000001))
assert(core:SetIntensity(1000000000000),'expanded maximum accepted')
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
core:Start();owner=false;rs.PostSimulation:Fire()
assert(core.Running,'non-owner remains active')
assert(core:SetAxis('Y',0)and core:SetAxis('X',-2000000)and core:SetAxis('Z',3000000))
rs.PostSimulation:Fire()
assert(root.Velocity.X==-2000000 and root.Velocity.Y==0 and root.Velocity.Z==3000000,'axes independently configurable')
for _,f in pairs(binds)do f()end
assert(root.Velocity==walking,'axis pulse restores walking')
for _,axis in ipairs({'X','Y','Z'})do assert(core:SetAxis(axis,0))end
rs.PostSimulation:Fire();for _,f in pairs(binds)do f()end
assert(root.Velocity==walking,'zero pulse must also restore walking')
assert(not core:SetAxis('Y',math.huge)and not core:SetAxis('W',1))
owner=true
assert(core:SetIntensity(500000)and core:SetPulseParameter('Duration',.05))
assert(core:SetPulseParameter('BurstOn',.1)and core:SetPulseParameter('BurstOff',.1))
assert(not core:SetPulseParameter('Duration',.26)and not core:SetPulseParameter('BurstOn',0)and not core:SetPulseParameter('BurstOff',math.huge))
rs.PostSimulation:Fire();for _,f in pairs(binds)do f()end
assert(root.Velocity.X==500000,'owner duration holds pulse beyond render')
now=100.06;for _,f in pairs(binds)do f()end
assert(root.Velocity==walking,'duration expiry restores original walking velocity')
now=100.12;rs.PostSimulation:Fire()
assert(root.Velocity==walking,'burst pause emits no pulse')
now=100.21;rs.PostSimulation:Fire()
assert(root.Velocity.X==500000,'next burst resumes')
owner=false;for _,f in pairs(binds)do f()end
assert(root.Velocity==walking,'loss of owner access immediately releases held pulse on render')
rs.PostSimulation:Fire();for _,f in pairs(binds)do f()end
assert(core.Pulse.Duration==0 and core.Pulse.BurstOff==0 and root.Velocity==walking,'public mode resets advanced timing')
core:Destroy();assert(next(binds)==nil,'render binding removed')
rs.PostSimulation:Fire();assert(root.Velocity==walking,'destroy disconnects simulation callback')
print('Adjustable contact OK: intensity, live changes, pulse restoration, original mode exclusion, respawn and cleanup')
