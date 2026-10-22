local source,gateSource=...
setfenv=function()end
table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
local now=1;os.clock=function()return now end
local allSignals={}
local function signal()
 local entries={};local s={}
 function s:Connect(fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;entries[#entries+1]={c,fn};return c end
 function s:Fire(...)local copy={};for i,e in ipairs(entries)do copy[i]=e end;for _,e in ipairs(copy)do if e[1].Connected then e[2](...)end end end
 function s:Count()local n=0;for _,e in ipairs(entries)do if e[1].Connected then n=n+1 end end;return n end
 allSignals[#allSignals+1]=s;return s
end
local function instance(class,name,parent)
 local o={ClassName=class,Name=name,Parent=parent,items={},attributes={},signals={},ChildAdded=signal(),ChildRemoved=signal(),DescendantAdded=signal(),DescendantRemoving=signal()}
 if parent then parent.items[#parent.items+1]=o end
 function o:IsA(kind)return kind==self.ClassName or (kind=='JointInstance'and self.ClassName=='Weld')end
 function o:GetChildren()return self.items end
 function o:GetDescendants()local result={};local function add(node)for _,child in ipairs(node.items)do result[#result+1]=child;add(child)end end;add(self);return result end
 function o:FindFirstChild(key)for _,child in ipairs(self.items)do if child.Name==key then return child end end end
 function o:FindFirstChildOfClass(key)for _,child in ipairs(self.items)do if child:IsA(key)then return child end end end
 function o:GetAttribute(key)return self.attributes[key]end
 function o:GetPropertyChangedSignal(key)self.signals[key]=self.signals[key]or signal();return self.signals[key]end
 function o:GetAttributeChangedSignal(key)return self:GetPropertyChangedSignal('attribute:'..key)end
 function o:IsDescendantOf(ancestor)local p=self.Parent;while type(p)=='table'do if p==ancestor then return true end;p=p.Parent end;return false end
 return o
end
local function move(item,parent)
 local old=item.Parent
 if old then for i,child in ipairs(old.items)do if child==item then table.remove(old.items,i);break end end end
 item.Parent=parent
 if parent then parent.items[#parent.items+1]=item end
 if old then old.ChildRemoved:Fire(item)end
 if parent then parent.ChildAdded:Fire(item);local p=parent;while p do p.DescendantAdded:Fire(item);p=p.Parent end end
end
local heartbeat=signal()
local character=instance('Model','LocalRig')
local humanoid=instance('Humanoid','Humanoid',character);humanoid.Health=100
local backpack=instance('Backpack','Backpack')
function humanoid:EquipTool(tool)
 for i=#character.items,1,-1 do local child=character.items[i];if child:IsA('Tool')then move(child,backpack)end end
 move(tool,character)
end
local accessory=instance('Accessory','Hat',character)
local handle=instance('Part','Handle',accessory)
local folder=instance('Folder','ObjectPlaceFolder')
workspace={FindFirstChild=function(_,name)if name=='ObjectPlaceFolder'then return folder end end}
local player={Character=character,FindFirstChildOfClass=function(_,name)if name=='Backpack'then return backpack end end}
local pickups,clears=0,0
local lastObject,lastCleared
local release=instance('RemoteEvent','ReleaseObjectRE')
function release:FireServer(action,data)assert(action=='InteractWithObject');pickups=pickups+1;lastObject=data.object end
local clear=instance('RemoteEvent','ClearToolRE')
function clear:FireServer(value)
 assert(value==true)
 for _,child in ipairs(character:GetChildren())do if child:IsA('Tool')then assert(not lastCleared);lastCleared=child;break end end
 assert(lastCleared);clears=clears+1;move(lastCleared,nil)
end
local remotes=instance('Folder','Remotes');move(release,remotes);move(clear,remotes)
local services={Players={LocalPlayer=player},RunService={Heartbeat=heartbeat},ReplicatedStorage={FindFirstChild=function(_,name)if name=='Remotes'then return remotes end end}}
game={GameId=4540138978,PlaceId=12985361032,GetService=function(_,name)return services[name]end}
FoldingCleanupCore={Enabled=false,Busy=false}
assert(load(gateSource))()(_G)
local function object(id,creator,attached,reference)
 local o=instance('Part','VariableName');o.attributes.ToolId=id;o.attributes.CreatedPlayer=creator
 if reference then local ref=instance('ObjectValue','AttachParentObject',o);ref.Value=attached and handle or nil
 else local link=instance('Weld','weld2target',o);link.Part0=attached and handle or nil;link.Part1=o end
 return o
end
local function tool(id,creator,parent)
 local t=instance('Tool',id);t.attributes.CreatedBy=creator;move(t,parent);return t
end
local function beat(dt)now=now+(dt or .06);heartbeat:Fire(dt or .06)end
local loose=object('Lamp',42,false);move(loose,folder)
local noCreator=object('Lamp',nil,true);move(noCreator,folder)
local first=object('Lamp',42,true);move(first,folder)
local preexisting=tool('Lamp',42,backpack)
assert(load(source))()(_G)
local core=GenericAttachedCleanupCore
beat();assert(not core.Enabled and pickups==0,'default off')
FoldingCleanupCore.Enabled=true;beat()
assert(core.Enabled and pickups==1 and lastObject==first and CleanupToolGate.Owner.Owner==core)
backpack.ChildAdded:Fire(preexisting);assert(clears==0,'never clear existing inventory')
local wrongCreator=tool('Lamp',99,backpack);assert(clears==0)
local acquired=tool('Lamp',42,backpack)
assert(clears==0,'new Tool is not enough while object remains attached')
move(first,nil);beat()
assert(clears==1 and lastCleared==acquired and core.Completed==1)
assert(preexisting.Parent==backpack and wrongCreator.Parent==backpack and CleanupToolGate.Owner==nil)
lastCleared=nil
-- A nested object reference is accepted; two fresh matching Tools are ambiguous.
local second=object('NewDecoration',55,true,true);move(second,folder)
assert(pickups==2 and lastObject==second)
local a=tool('NewDecoration',55,backpack)
local b=tool('NewDecoration',55,backpack)
move(second,nil);beat()
assert(clears==1 and a.Parent==backpack and b.Parent==backpack and CleanupToolGate.Owner==nil)
assert(core.LastError:find('ambigua',1,true))
-- Known IDs stay with original cleaners; they also get pickup priority.
local known=object('FoldingTable',42,true);move(known,folder)
local third=object('OtherTool',77,true);move(third,folder)
beat();assert(pickups==2,'do not pick up known objects or interrupt their cleaner')
local competing=CleanupToolGate:Acquire({})
move(known,nil)
beat();assert(pickups==2,'generic pickup must respect existing tool operation')
CleanupToolGate:Release(competing);beat()
assert(pickups==3 and lastObject==third)
beat(3);assert(clears==1 and CleanupToolGate.Owner==nil,'timeout releases gate without deleting an arbitrary Tool')
-- Opt-out cancels pending operations; respawn cancels stale tool correlation.
beat(1.1);assert(CleanupToolGate.Owner)
FoldingCleanupCore.Enabled=false;beat();assert(not core.Enabled and CleanupToolGate.Owner==nil)
FoldingCleanupCore.Enabled=true;beat();beat(1.1)
local newCharacter=instance('Model','Respawn')
player.Character=newCharacter;beat()
assert(CleanupToolGate.Owner==nil and clears==1,'respawn invalidates pending pickup')
core:Destroy();beat();assert(not core.Enabled and CleanupToolGate.Owner==nil)
for _,s in ipairs(allSignals)do assert(s:Count()==0,'generic event connection leaked')end
game.GameId=0;game.PlaceId=0;assert(not core:SetEnabled(true),'Metro Life only')
print('attached_object_cleanup_spec OK: attachment-only, strict fresh-tool matching, ambiguity, gate priority, timeout, opt-out and respawn')
