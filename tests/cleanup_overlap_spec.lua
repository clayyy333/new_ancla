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
local function flush()local jobs=deferred;deferred={};for _,fn in ipairs(jobs)do fn()end end
CleanupAttachmentDetector={IsAttached=function(_,o,ch)
 local w=o:FindFirstChild("weld2target")
 return o.Parent==folder and w and w.Part0 and w.Part0:IsDescendantOf(ch)or false
end}
function FoldingCleanupCore:DrainPending()end
assert(load(source))()(_G)
local core=CleanupBacklogCore
FoldingCleanupCore.Enabled=true
local first=object('FoldingTable',42,true);move(first,folder);beat();flush()
assert(pickups==0,'single object keeps original flow')
assert(CleanupToolGate:TrackPickup(first))
local primaryToken=CleanupToolGate:Acquire({})
local second=object('FoldingTable',55,true);move(second,folder)
assert(pickups==1 and lastObject==second,'same model, distinct creator picked up while prior clear owns gate')
assert(CleanupToolGate:IsReservedObject(second)and not CleanupToolGate:TrackPickup(second),'original cleaners must not duplicate companion pickup')
local received=tool('FoldingTable',55,backpack)
assert(CleanupToolGate:IsSupplementTool(received),'companion owns fresh received tool')
local unrelated=tool('FoldingTable',99,backpack)
assert(not CleanupToolGate:IsSupplementTool(unrelated),'unrelated tool excluded')
move(second,nil);beat();flush();assert(clears==0,'clear still exclusive')
CleanupToolGate:Release(primaryToken);beat();flush();beat()
assert(clears==1 and not received.Parent and unrelated.Parent==backpack and core.Completed==1)
assert(core.Pickups==1 and CleanupToolGate.Owner==nil)
lastCleared=nil
-- Same-model/same-creator overlap is attempted, not rejected in advance.
local third=object('FoldingTable',42,true);move(third,folder);beat();flush()
assert(not core.QueueOnly and core.Fallbacks==0 and pickups==2,'identical identity still attempts overlap')
local primaryReceived=tool('FoldingTable',42,backpack)
assert(not CleanupToolGate:IsSupplementTool(primaryReceived),'oldest primary request reserves first fresh Tool')
local secondaryReceived=tool('FoldingTable',42,backpack)
assert(CleanupToolGate:IsSupplementTool(secondaryReceived),'second Tool instance belongs to companion')
assert(not CleanupToolGate:IsSupplementTool(primaryReceived),'Tool instance ownership is stable')
move(third,nil);beat();flush();beat()
assert(not secondaryReceived.Parent and primaryReceived.Parent==backpack and core.Completed==2,'identical models tracked as separate instances')
move(primaryReceived,nil);move(first,nil);beat();flush()
lastCleared=nil
FoldingCleanupCore.Enabled=false;beat();flush()
assert(not core.QueueOnly and not core.Enabled)
-- Two identical companion jobs must not share the same received Tool.
FoldingCleanupCore.Enabled=true;beat();flush()
local groupPrimary=object('Lamp',70,true);move(groupPrimary,folder);beat();flush()
CleanupToolGate:TrackPickup(groupPrimary)
local groupA=object('Lamp',70,true);move(groupA,folder)
local groupB=object('Lamp',70,true);move(groupB,folder)
assert(core:IsReserved(groupA)and core:IsReserved(groupB)and not core.QueueOnly)
local originalTool=tool('Lamp',70,backpack)
assert(not CleanupToolGate:IsSupplementTool(originalTool))
local toolA=tool('Lamp',70,backpack)
local toolB=tool('Lamp',70,backpack)
assert(CleanupToolGate:IsSupplementTool(toolA)and CleanupToolGate:IsSupplementTool(toolB))
move(groupA,nil);move(groupB,nil)
for _=1,4 do lastCleared=nil;beat();flush()end
assert(not toolA.Parent and not toolB.Parent and originalTool.Parent==backpack,'identical tools are each cleared once')
move(originalTool,nil);move(groupPrimary,nil);beat();flush()
FoldingCleanupCore.Enabled=false;beat();flush()
lastCleared=nil
-- Request error releases reservation and returns object to original queue.
FoldingCleanupCore.Enabled=true;beat();flush()
move(first,nil);move(third,nil);beat();flush()
local primary=object('Lamp',1,true);move(primary,folder);beat();flush()
CleanupToolGate:TrackPickup(primary)
local originalRelease=release.FireServer
release.FireServer=function()error('request failed')end
local failed=object('Lamp',2,true);move(failed,folder);flush()
assert(core.QueueOnly and not core:IsReserved(failed)and core.LastError:find('request failed',1,true))
release.FireServer=originalRelease
-- Timeout returns a still-attached object to the ordinary cleaners.
FoldingCleanupCore.Enabled=false;beat();flush()
move(primary,nil);move(failed,nil)
FoldingCleanupCore.Enabled=true;beat();flush()
local anchor=object('Lamp',3,true);move(anchor,folder);beat();flush()
CleanupToolGate:TrackPickup(anchor)
local timed=object('Other',4,true);move(timed,folder);flush()
assert(core:IsReserved(timed))
beat(2.6);flush()
assert(core.QueueOnly and not core:IsReserved(timed),'pickup timeout hands back to queue')
core:Destroy();flush()
assert(not CleanupToolGate.Owner)
for _,signal in ipairs(allSignals)do assert(signal:Count()==0,'event leaked')end
print('cleanup_overlap_spec OK: overlapping pickup, same model, exclusive clear, duplicate suppression, unrelated inventory, identical identities, unique Tool ownership and error fallback')
