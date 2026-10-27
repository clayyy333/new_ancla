local source=...
table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
local function signal()
 local callbacks={};local s={}
 function s:Connect(f)local c={f=f};callbacks[#callbacks+1]=c;function c:Disconnect()self.f=nil end;return c end
 function s:Fire(...)for _,c in ipairs(callbacks)do if c.f then c.f(...)end end end
 return s
end
local function obj(class,parent)
 local p={ClassName=class,Parent=parent,Name=class,CanCollide=true,children={},Touched=signal()}
 function p:IsA(c)return c==self.ClassName or c=='BasePart'and(self.ClassName=='Part'or self.ClassName=='Seat')or c=='JointInstance'and self.ClassName=='Weld'end
 function p:IsDescendantOf(a)local n=self.Parent;while n do if n==a then return true end;n=n.Parent end;return false end
 function p:FindFirstAncestorOfClass(c)local n=self.Parent;while n do if n.ClassName==c then return n end;n=n.Parent end end
 function p:GetChildren()local t={};for _,v in ipairs(self.children)do if v.Parent==self then t[#t+1]=v end end;return t end
 function p:GetJoints()return {}end
 function p:FindFirstChildOfClass(c)for _,v in ipairs(self.children)do if v.Parent==self and v:IsA(c)then return v end end end
 function p:GetDescendants()local t={};for _,v in ipairs(self:GetChildren())do t[#t+1]=v;for _,d in ipairs(v:GetDescendants())do t[#t+1]=d end end;return t end
 function p:Destroy()self.Parent=nil;self.Destroyed=true end
 if parent then parent.children[#parent.children+1]=p end
 return p
end
local world=obj('Workspace');world.DescendantAdded=signal()
function world:GetDescendants()error('Workspace enumeration forbidden')end
local char=obj('Model',world);char.DescendantAdded=signal()
local root=obj('Part',char);root.Name='HumanoidRootPart';root.CFrame={Position={Y=5},Rotation={}};root.Position={X=0,Y=5,Z=0}
local accessory=obj('Part',char);accessory.CanCollide=false
local tool=obj('Tool',char);local handle=obj('Part',tool)
local hum={Parent=char,Health=100,AutoRotate=true,PlatformStand=false,WalkSpeed=21,JumpPower=47,Sit=false,SeatedState=true,State='Running',props={Sit=signal(),SeatPart=signal()},StateChanged=signal(),Seated=signal(),Died=signal()}
function hum:GetStateEnabled()return self.SeatedState end
function hum:SetStateEnabled(_,v)self.SeatedState=v end
function hum:GetState()return self.State end
function hum:ChangeState(s)self.State=s end
function hum:GetPropertyChangedSignal(p)return self.props[p]end
function char:FindFirstChildOfClass()return hum end
function char:FindFirstChild()return root end
function char:GetDescendants()return {root,accessory,tool,handle}end
local player={Character=char,CharacterRemoving=signal()}
local run={PreSimulation=signal(),PostSimulation=signal()}
local env=setmetatable({Players={GetPlayers=function()return {player}end},player=player,workspace=world,RunService=run,Vector3={zero={}},Enum={HumanoidStateType={Seated='Seated',GettingUp='GettingUp',Ragdoll='Ragdoll',FallingDown='FallingDown'}}},{__index=_G})
-- Install the module's Lua 5.1 environment through its _ENV upvalue.
env.setfenv=function(_,e)debug.setupvalue(debug.getinfo(2,'f').func,1,e)end
assert(load(source,nil,'t',env))()(env)
local c=env.StaticNoclipAnchorCore
assert(not c:Start(),"non-owner denied")
assert(not c:SetConstantReturn(true),"non-owner setting denied")
env.ExperimentalFlingCore={IsAuthorized=function()return true end}
assert(c:Start());assert(not root.CanCollide and handle.CanCollide,'body only noclip')
assert(hum.PlatformStand and hum.WalkSpeed==0 and hum.JumpPower==0,'static humanoid posture applied immediately')
local home=c.Checkpoint
local seat=obj('Seat',world);local weld=obj('Weld',seat);weld.Part0=seat;weld.Part1=root
hum.SeatPart=seat;hum.Sit=true;hum.props.SeatPart:Fire()
assert(weld.Destroyed and not hum.Sit and root.CFrame==home,'external seat released and event returns home')
local foreign=obj('Part',world);local foreignJoint=obj('Weld',seat);foreignJoint.Part0=seat;foreignJoint.Part1=foreign
world.DescendantAdded:Fire(foreignJoint);assert(not foreignJoint.Destroyed,'foreign occupants preserved')
hum.SeatPart=nil;hum.State='Running'
c:SetConstantReturn(true);root.CFrame={};run.PreSimulation:Fire();assert(root.CFrame==home,'constant return')
root.CFrame={};accessory.AssemblyLinearVelocity={};accessory.AssemblyAngularVelocity={}
run.PostSimulation:Fire()
assert(root.CFrame==home and accessory.AssemblyLinearVelocity==env.Vector3.zero and accessory.AssemblyAngularVelocity==env.Vector3.zero,'post-physics correction clears independent body motion')
local vehicle=obj('Model',world);local vehicleSeat=obj('Seat',vehicle);local vehicleBody=obj('Part',vehicle)
root.Touched:Fire(vehicleBody)
assert(not vehicleBody.CanCollide and not vehicleSeat.CanCollide,'contact isolates the specific seat-bearing model')
-- Known seats work even when the spatial query cannot return them.
local function position(x)return setmetatable({X=x,Y=5,Z=0},{__sub=function(a,b)return {Magnitude=math.abs(a.X-b.X)}end})end
root.Position=position(0)
local stroller=obj('Tool',world);stroller.Name='Babycar_c'
local knownSeat=obj('Seat',stroller);knownSeat.Position=position(10);knownSeat.Disabled=false;knownSeat.CanTouch=true
local unknownSeat=obj('Seat',world);unknownSeat.Position=position(12);unknownSeat.Disabled=true;unknownSeat.CanTouch=true
local foreignQueries=0
function world:GetPartBoundsInRadius()foreignQueries=foreignQueries+1;return {unknownSeat}end
env.OverlapParams={new=function()return {}end};env.Enum.RaycastFilterType={Exclude='Exclude'}
world.DescendantAdded:Fire(knownSeat)
assert(not c.SeatPrevention and knownSeat.CanTouch,'prevention defaults OFF')
assert(c:SetSeatPrevention(true));run.PreSimulation:Fire()
assert(knownSeat.Disabled and not knownSeat.CanTouch,'known object seat protected without query visibility')
assert(unknownSeat.Disabled and not unknownSeat.CanTouch and foreignQueries==1,'generic nearby query fallback')
knownSeat.Position=position(20);run.PreSimulation:Fire()
assert(not knownSeat.Disabled and knownSeat.CanTouch,'leaving radius restores original values')
c:SetSeatPrevention(false)
assert(unknownSeat.Disabled and unknownSeat.CanTouch,'OFF restores original true Disabled too')
c:Stop();assert(root.CanCollide and not accessory.CanCollide and hum.AutoRotate and hum.SeatedState,'original properties restored')
assert(not hum.PlatformStand and hum.WalkSpeed==21 and hum.JumpPower==47,'exact original humanoid properties restored')
assert(vehicleBody.CanCollide and vehicleSeat.CanCollide,'contact vehicle collisions restored')
root.CFrame={};run.PostSimulation:Fire();assert(root.CFrame~=home,'post-physics handler disconnected on stop')
assert(not c.Running)
print('Static anchor OK: body noclip, tool preservation, seat release, event/constant return, foreign joints, restoration; no Workspace enumeration')
