-- Execute with module source as the first argument; no real remotes are used.
local source,gateSource=...
setfenv=function()end
table.clear=table.clear or function(t)for key in pairs(t)do t[key]=nil end end
local function signal()
 local callbacks={}
 return {Connect=function(_,callback)
  local c={Connected=true};function c:Disconnect()self.Connected=false end
  callbacks[#callbacks+1]={c,callback};return c
 end,Fire=function(_,...)
  for _,item in ipairs(callbacks)do if item[1].Connected then item[2](...)end end
 end}
end
task={spawn=function(callback)callback()end,defer=function(callback,...)callback(...)end}
local heartbeat=signal()
function heartbeat:Wait()error('Unexpected wait in immediate-success test')end
local backpack={ChildAdded=signal(),items={}}
function backpack:GetChildren()return self.items end
local character={ChildAdded=signal(),items={}}
local human={}
function human:EquipTool(tool)tool.Parent=character;character.items={tool};backpack.items={}end
function character:GetChildren()return self.items end
function character:FindFirstChildOfClass(class)if class=='Humanoid' then return human end end
local localPlayer={Character=character}
function localPlayer:FindFirstChildOfClass(class)if class=='Backpack' then return backpack end end
local folder={ChildAdded=signal(),items={}}
function folder:GetChildren()return self.items end
workspace={FindFirstChild=function(_,name)if name=='ObjectPlaceFolder' then return folder end end}
local pickups,clears=0,0
local release={IsA=function(_,class)return class=='RemoteEvent'end}
function release:FireServer(action,data)
 assert(action=='InteractWithObject' and data.object==folder.items[2]);pickups=pickups+1
end
local clear={IsA=release.IsA}
function clear:FireServer(value)
 assert(value==true and character.items[1]);clears=clears+1
 character.items[1].Parent=nil;character.items={}
end
local remotes={FindFirstChild=function(_,name)if name=='ReleaseObjectRE' then return release elseif name=='ClearToolRE' then return clear end end}
local services={Players={LocalPlayer=localPlayer},ReplicatedStorage={FindFirstChild=function()return remotes end},RunService={Heartbeat=heartbeat}}
game={GameId=4540138978,PlaceId=12985361032,GetService=function(_,name)return services[name]end}
AnchorCore={AnclaEnabled=false}
assert(load(gateSource))()(_G)
assert(load(source))()(_G)
local core=FoldingCleanupCore
local object={Parent=folder,GetAttribute=function(_,name)if name=='ToolId' then return 'FoldingTable' elseif name=='CreatedPlayer' then return 42 end end}
local accessory={IsDescendantOf=function(_,rig)return rig==character end}
local handle={IsDescendantOf=function(_,rig)return rig==character end,FindFirstAncestorOfClass=function()return accessory end}
local link={Part0=handle,Part1=object,IsA=function(_,class)return class=='JointInstance'end}
function object:FindFirstChild(name)if name=='weld2target' then return link end end
local floorTable={Parent=folder,GetAttribute=object.GetAttribute,FindFirstChild=function()return nil end}
folder.items={floorTable,object}
local preexisting={Name='FoldingTable',Parent=backpack,IsA=function(_,class)return class=='Tool'end,GetAttribute=function()return 42 end}
backpack.items={preexisting}
heartbeat:Fire(.1);assert(pickups==0 and not core.Enabled)
core:SetEnabled(true);assert(pickups==1,'opt-in must work without any active anchor')
heartbeat:Fire(.1);assert(pickups==1)
backpack.ChildAdded:Fire(preexisting);assert(clears==0,'preexisting table from the same creator must not be cleared')
local tool={Name='FoldingTable',Parent=backpack,IsA=function(_,class)return class=='Tool'end,GetAttribute=function()return 42 end}
local competingToken=CleanupToolGate:Acquire({})
backpack.items={tool};backpack.ChildAdded:Fire(tool)
assert(clears==0,'table clearing must not run while balloon clearing owns the gate')
CleanupToolGate:Release(competingToken);heartbeat:Fire(.1)
assert(clears==1 and core.Cycles==1 and tool.Parent==nil)
local unrelated={Name='FoldingTable',Parent=backpack,IsA=tool.IsA,GetAttribute=function()return 99 end}
backpack.items={unrelated};backpack.ChildAdded:Fire(unrelated)
assert(clears==1,'must not clear an unrelated inventory tool')
core:SetEnabled(false);local before=pickups;heartbeat:Fire(.2);assert(pickups==before and clears==1)
core:Destroy();heartbeat:Fire(.2);assert(pickups==before)
game.GameId=1;game.PlaceId=2
assert(not core:IsAvailable() and not core:SetEnabled(true),'cleanup must not enable outside Metro Life')
print('Folding cleanup mock OK: any creator, local accessory attachment only, floor tables and preexisting tools excluded, default off, no anchor needed')
