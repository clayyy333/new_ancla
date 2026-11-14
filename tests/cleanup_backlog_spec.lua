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

local deferred={}
task={defer=function(fn)deferred[#deferred+1]=fn end}
local function flush()
 local jobs=deferred;deferred={}
 for _,fn in ipairs(jobs)do fn()end
end
CleanupAttachmentDetector={IsAttached=function(_,o,ch)
 local w=o:FindFirstChild("weld2target")
 return w and w.Part0 and w.Part0:IsDescendantOf(ch)or false
end}
local drains=0
function FoldingCleanupCore:DrainPending()drains=drains+1 end
assert(load(source))()(_G)
local core=CleanupBacklogCore
FoldingCleanupCore.Enabled=true
local first=object('Lamp',42,true);move(first,folder);beat();flush()
assert(drains==0 and core.Overlaps==0,'single-object flow untouched')
local second=object('Other',42,true);move(second,folder);flush()
assert(drains==1 and core.Pending==2 and core.Overlaps==1,'simultaneous backlog wakes existing cleaners')
move(second,nil);move(first,nil);beat();flush()
assert(core.Pending==0)
local token=CleanupToolGate:Acquire({})
local third=object('Lamp',42,true);move(third,folder);flush()
assert(drains==1,'never interrupt an in-flight clear')
assert(core.Overlaps==2,'arrival during earlier removal activates companion')
CleanupToolGate:Release(token);flush()
assert(drains==2,'gate release resumes backlog immediately')
local unrelated=object('Other',42,false);move(unrelated,folder);beat();flush()
assert(core.Pending==1,'only local attachments count')
FoldingCleanupCore.Enabled=false;beat();local previous=drains;flush()
assert(not core.Enabled and drains==previous and core.Pending==0)
FoldingCleanupCore.Enabled=true;beat();flush()
player.Character=instance('Model','Respawn');beat();flush()
assert(core.Pending==0,'old character links invalidated')
core:Destroy()
for _,s in ipairs(allSignals)do assert(s:Count()==0,'companion connections leaked')end
print('cleanup_backlog_spec OK: single flow, overlap, mid-clear arrival, gate wake, opt-out, respawn, cleanup')
