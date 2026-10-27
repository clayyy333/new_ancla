-- Standalone mocked lifecycle test; pass the module source as the first argument.
local source=...
game={GameId=4540138978,PlaceId=12985361032}
table.clear=table.clear or function(value)for key in pairs(value)do value[key]=nil end end
local function signal()
 local callbacks={}
 return {Connect=function(_,callback)
  local connection={Connected=true}
  function connection:Disconnect()self.Connected=false end
  callbacks[#callbacks+1]={connection,callback};return connection
 end,Fire=function(_,...)
  for _,item in ipairs(callbacks) do if item[1].Connected then item[2](...) end end
 end}
end
local vector={};vector.__index=vector
function vector.__sub(a,b)return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vector.__index=function(v,key)if key=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end;return vector[key]end
Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},vector)end};Vector3.zero=Vector3.new(0,0,0)
CFrame={lookAt=function(position,target)return {Position=position,Target=target}end}
Random={new=function()return {NextInteger=function(_,minimum)return minimum end}end}
Enum={HumanoidRigType={R6='R6'},RaycastFilterType={Exclude='Exclude'}}
RaycastParams={new=function()return {}end}
task={defer=function(callback)callback()end}
setfenv=function()end
local root={Name='HumanoidRootPart',Position=Vector3.new(0,3,0),Size=Vector3.new(2,2,1),Parent=true}
function root:IsA(class)return class=='BasePart'end
function root:GetPropertyChangedSignal()return signal()end
local human={Health=100,HipHeight=2,RigType='R15'}
function human:IsA(class)return class=='Humanoid'end
function human:GetPropertyChangedSignal()return signal()end
local character={ChildAdded=signal()}
function character:FindFirstChild(name)if name=='HumanoidRootPart' then return root end end
function character:FindFirstChildOfClass(class)if class=='Humanoid' then return human end end
function character:GetChildren()return {root,human}end
function character:GetDescendants()return {root}end
player={UserId=1,Character=character,CharacterAdded=signal()}
local otherRoot={Position=Vector3.new(-224,3,495)}
local other={UserId=2,Character={FindFirstChild=function()return otherRoot end}}
Players={GetPlayers=function()return {player,other}end,GetPlayerByUserId=function(_,id)if id==2 then return other end end}
local folder={ChildAdded=signal(),ChildRemoved=signal(),objects={}}
function folder:GetChildren()return self.objects end
workspace={ChildAdded=signal(),ChildRemoved=signal()}
function workspace:FindFirstChild(name)if name=='ObjectPlaceFolder' then return folder end end
function workspace:Raycast()return {Position=Vector3.zero}end
RunService={Heartbeat=signal()}
local static={Running=false,PhaseEnabled=false}
function static:IsRunning()return self.Running end
function static:Start()self.Running=true;return true end
function static:Stop()self.Running=false end
function static:Destroy()self:Stop()end
function static:SetPhase(value)self.PhaseEnabled=value end
function static:RelocateForDeployment(target)self.Target=target;root.Position=target.Position;return true end
DeploymentAnchorMotorCore=static
BabyVehicleAnchorCore=static
local owner=true
ExperimentalFlingCore={IsAuthorized=function()return owner end}
StaticPassThroughAnchorCore={Running=false,IsRunning=function(self)return self.Running end}
local mobile={Running=false,SafeHistory={{}}}
function mobile:IsRunning()return self.Running end
MobileAnchorCore=mobile
local humanoidHeight=3
assert(load(source))()(_G)
local safety=DeploymentSafetyCore
owner=false;assert(not safety:Start());owner=true
assert(safety:Start())
assert(not StaticPassThroughAnchorCore.Running,'deployment must not start the original anchor')
assert(#safety.Destinations==0,'static Babycar flow must not prepare old relocation points')
safety:Stop();assert(not static.Running)
mobile.Running=true;safety:SetMobileEnabled(true)
assert(#safety.Destinations==24 and not static.PhaseEnabled)
assert(safety.Destinations[1].Position.X==-226.8972)
assert(safety.Destinations[1].Position.Y==humanoidHeight)
local accessory={IsDescendantOf=function(_,rig)return rig==character end}
local handle={IsDescendantOf=function(_,rig)return rig==character end,FindFirstAncestorOfClass=function()return accessory end}
local object={Parent=folder,attributes={ToolId='FoldingTable'},attributeSignals={},ChildAdded=signal()}
local link={Name='weld2target',Part0=handle,Part1=object,IsA=function(_,class)return class=='Weld'end,GetPropertyChangedSignal=function()return signal()end}
link.IsA=function(_,class)return class=='JointInstance'end
function object:GetAttribute(name)return self.attributes[name]end
function object:GetAttributeChangedSignal(name)
 self.attributeSignals[name]=self.attributeSignals[name] or signal()
 return self.attributeSignals[name]
end
function object:FindFirstChild(name)if name=='weld2target' then return link end end
function object:GetChildren()return {link}end
folder.objects={object};folder.ChildAdded:Fire(object)
assert(mobile.SafeCFrame and safety.LastCreatorId==nil,'mobile attached chair must trigger before creator replication')
local initialEscape=mobile.SafeCFrame
root.Position=initialEscape.Position -- mocked CFrame writes do not update Position automatically
otherRoot.Position=initialEscape.Position
object.attributes.CreatedPlayer=2;object.attributes.CreatedPlayerName='other'
object:GetAttributeChangedSignal('CreatedPlayer'):Fire()
assert(safety.LastCreatorId==2 and mobile.SafeCFrame)
assert((mobile.SafeCFrame.Position-otherRoot.Position).Magnitude>18)
assert(mobile.SafeCFrame~=initialEscape,'late nearby creator must trigger distance correction')
local previous=mobile.SafeCFrame
object:GetAttributeChangedSignal('CreatedPlayerName'):Fire()
folder.ChildAdded:Fire(object)
assert(previous==mobile.SafeCFrame,'duplicate object must not relocate twice')
safety:Stop();assert(not static.Running)
mobile.Running=true;safety:SetMobileEnabled(true)
-- Re-enabling after stopping recreates object observers and applies mobile opt-in.
assert(mobile.SafeCFrame and #mobile.SafeHistory==0)
safety:SetMobileEnabled(false)
local saved=mobile.SafeCFrame
RunService.Heartbeat:Fire()
assert(mobile.SafeCFrame==saved and mobile.Running,'disabled safety must not alter locomotion')
safety:Destroy()
game.GameId=1;game.PlaceId=2
assert(not safety:IsAvailable())
assert(not safety:Start(),'deployment anchor must be unavailable outside Metro Life')
assert(not safety:SetMobileEnabled(true),'mobile deployment safety must be unavailable outside Metro Life')
print('Deployment safety mock: static/mobile, 24 prepared points, owner distance, dedup and cleanup OK')
