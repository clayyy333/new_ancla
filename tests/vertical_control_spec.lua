-- Mocked local offset test; execute with vertical_control.lua source as argument.
local source=...
setfenv=function()end
table.clear=table.clear or function(t)for key in pairs(t)do t[key]=nil end end
local vmt={}
Vector3={new=function(x,y,z)return setmetatable({X=x,Y=y,Z=z},vmt)end}
Vector3.zero=Vector3.new(0,0,0)
vmt.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
local fmt={}
CFrame={new=function(x,y,z)
 if type(x)=='table' then x,y,z=x.X,x.Y,x.Z end
 return setmetatable({Position=Vector3.new(x or 0,y or 0,z or 0)},fmt)
end}
fmt.__index={VectorToObjectSpace=function(_,v)return v end}
fmt.__mul=function(a,b)return CFrame.new(a.Position+b.Position)end
local joint={Parent=true,C0=CFrame.new(0,2,0),C1=CFrame.new(0,1,0)}
function joint:IsA(class)return class=='Motor6D'end
local root={CFrame=CFrame.new(10,60,20),CanCollide=true}
function root:IsA(class)return class=='BasePart'end
function root:FindFirstChild(name)if name=='RootJoint' then return joint end end
local torso={}
joint.Part0=root;joint.Part1=torso
local humanoid={Health=100,Sit=false}
local character={}
function character:FindFirstChildOfClass(class)if class=='Humanoid' then return humanoid end end
function character:FindFirstChild(name)if name=='HumanoidRootPart' then return root end end
function character:GetDescendants()return {root}end
local function event()
 local callbacks={}
 return {Connect=function(_,fn)callbacks[#callbacks+1]=fn;local index=#callbacks;return {Disconnect=function()callbacks[index]=false end}end,
 Fire=function(_,...)for _,fn in ipairs(callbacks)do if fn then fn(...)end end end}
end
player={Character=character,CharacterRemoving=event(),CharacterAdded=event()}
AnchorCore={AnclaEnabled=true}
assert(load(source))()(_G)
local core=VerticalControlController
local origin=root.CFrame
core.Running=true;core.Checkpoint=origin;core.Offset=-5
assert(core:Apply())
assert(root.CFrame==origin and AnchorCore.Checkpoint==origin,'physical anchor must stay above')
assert(joint.C0.Position.Y==-3,'body offset must be applied relative to saved C0')
core:SetOffset(-9)
assert(root.CFrame==origin and joint.C0.Position.Y==-7,'offset changes must not accumulate')
core:RestoreVisualOffset()
assert(joint.C0.Position.Y==2 and joint.C1.Position.Y==1)
joint.Part0=torso;joint.Part1=root
assert(core:Apply())
assert(joint.C1.Position.Y==-8,'reversed root joint must offset the body through C1')
core:RestoreVisualOffset()
assert(joint.C1.Position.Y==1)
-- Respawn: relocate the HRP before the Humanoid/Animator finish loading.
local queue={}
task={spawn=function(fn)queue[#queue+1]=fn end,wait=function()end}
local animator={tracks={}}
function animator:GetPlayingAnimationTracks()return self.tracks end
local newHumanoid={Health=100,Sit=false}
function newHumanoid:FindFirstChildOfClass(name)if name=='Animator'then return animator end end
function newHumanoid:WaitForChild(name)assert(name=='Animator');return animator end
local newRoot={CFrame=CFrame.new(200,10,300),CanCollide=true}
function newRoot:IsA(name)return name=='BasePart'end
local newJoint={Parent=true,C0=CFrame.new(),C1=CFrame.new(),Part0=newRoot,Part1={}}
newJoint.IsA=joint.IsA
function newRoot:FindFirstChild(name)if name=='RootJoint'then return newJoint end end
local ready=false
local newCharacter={ChildAdded=event()}
function newCharacter:FindFirstChild(name)if name=='HumanoidRootPart'then return newRoot end end
function newCharacter:FindFirstChildOfClass(name)if name=='Humanoid'and ready then return newHumanoid end end
function newCharacter:GetDescendants()return {newRoot}end
function newCharacter:WaitForChild(name)
 if name=='HumanoidRootPart'then return newRoot end
 assert(name=='Humanoid','must not wait for R15-only torso');ready=true;return newHumanoid
end
function AnchorCore:SetAncla(enabled)self.AnclaEnabled=enabled;return true end
function AnchorCore:SetAntiSeat()end
function AnchorCore:SetHeartbeat()end
local playCount=0
PlayEmote=function(id)
 playCount=playCount+1
 currentAnimTrack={IsPlaying=true,Animation={AnimationId='rbxassetid://'..id}}
 animator.tracks={currentAnimTrack}
end
currentAnimTrack={IsPlaying=true,Animation={AnimationId='rbxassetid://131900540866459'}}
player.CharacterRemoving:Fire(character)
player.Character=newCharacter
player.CharacterAdded:Fire(newCharacter)
assert(newRoot.CFrame==origin,'return immediately, before humanoid readiness')
assert(not core:IsInvisibleEmotePlaying(),'old-character track is not a restored emote')
queue[1]()
assert(playCount==1 and core:IsInvisibleEmotePlaying(),'reload emote on the new Animator')
assert(newRoot.CFrame==origin and newJoint.C0.Position.Y==-9)
assert(AnchorCore.Checkpoint==origin,'respawn must not capture the game spawn as checkpoint')
print('Vertical offset mock OK: local offset, immediate respawn return and new-Animator emote restoration')
