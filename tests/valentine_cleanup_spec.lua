-- Independent event-path and contention tests; no actual game remotes.
local source,gateSource=...
setfenv=function()end
table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
local time=1;os.clock=function()return time end
local function signal()
 local entries={}
 return {Connect=function(_,fn)
  local c={Connected=true};function c:Disconnect()self.Connected=false end
  entries[#entries+1]={c,fn};return c
 end,Fire=function(_,...)
  for _,e in ipairs(entries)do if e[1].Connected then e[2](...)end end
 end}
end
local function instance(class,name)
 local value={ClassName=class,Name=name,Parent=true,ChildAdded=signal(),ChildRemoved=signal(),items={},attributes={},signals={}}
 function value:IsA(kind)return kind==self.ClassName end
 function value:GetChildren()return self.items end
 function value:FindFirstChild(key)for _,item in ipairs(self.items)do if item.Name==key then return item end end end
 function value:GetAttribute(key)return self.attributes[key]end
 function value:GetPropertyChangedSignal(key)self.signals[key]=self.signals[key] or signal();return self.signals[key]end
 function value:GetAttributeChangedSignal(key)return self:GetPropertyChangedSignal('attribute:'..key)end
 return value
end
local heartbeat=signal()
local character=instance('Model','Character')
local backpack=instance('Backpack','Backpack')
local folder=instance('Folder','ObjectPlaceFolder')
local lp={Character=character,CharacterAdded=signal(),ChildAdded=signal()}
function lp:FindFirstChildOfClass(kind)if kind=='Backpack'then return backpack end end
local handle={IsDescendantOf=function(_,ancestor)return ancestor==character end}
local object=instance('Part','AnyBalloonName');object.attributes.ToolId='ValentineBalloon'
local reference=instance('ObjectValue','AttachParentObject');object.items={reference}
local loose=instance('Part','LooseBalloon');loose.attributes.ToolId='ValentineBalloon'
folder.items={loose,object}
local releases,clears=0,0
local release=instance('RemoteEvent','ReleaseObjectRE')
function release:FireServer(action,data)
 assert(action=='InteractWithObject' and data.object==object);releases=releases+1
end
local clear=instance('RemoteEvent','ClearToolRE')
function clear:FireServer(value)
 assert(value==true and character.items[1].Name=='ValentineBalloon')
 clears=clears+1;character.items[1].Parent=nil;character.items={}
end
local remotes=instance('Folder','Remotes');remotes.items={release,clear}
local services={Players={LocalPlayer=lp},RunService={Heartbeat=heartbeat},ReplicatedStorage={FindFirstChild=function()return remotes end}}
game={GameId=4540138978,PlaceId=12985361032,GetService=function(_,key)return services[key]end}
workspace={ChildAdded=signal(),FindFirstChild=function(_,name)if name=='ObjectPlaceFolder'then return folder end end}
assert(load(gateSource))()(_G)
assert(load(source))()(_G)
local core=ValentineCleanupCore
heartbeat:Fire();assert(releases==0 and not core.Enabled)
core:SetEnabled(true);assert(releases==0,'unattached balloons must be ignored')
reference.Value=handle
local blocked=CleanupToolGate:Acquire({})
reference:GetPropertyChangedSignal('Value'):Fire()
assert(releases==0,'pickup must not interrupt another cleanup tool operation')
CleanupToolGate:Release(blocked)
reference:GetPropertyChangedSignal('Value'):Fire()
assert(releases==1,'attachment event must release without waiting for Heartbeat')
reference:GetPropertyChangedSignal('Value'):Fire();assert(releases==1,'respect same-object retry interval')
local tool=instance('Tool','ValentineBalloon');tool.Parent=character;character.items={tool}
blocked=CleanupToolGate:Acquire({})
character.ChildAdded:Fire(tool);assert(clears==0,'concurrent clears must wait')
CleanupToolGate:Release(blocked);time=time+.06;heartbeat:Fire()
assert(clears==1,'clear must resume when gate becomes available')
object.Parent=nil;time=time+.06;heartbeat:Fire()
assert(core.Completed==1 and CleanupToolGate.Owner==nil)
core:SetEnabled(false);time=time+1;heartbeat:Fire();assert(releases==1 and clears==1)
core:Destroy()
game.GameId=0;game.PlaceId=0;assert(not core:SetEnabled(true))
print('Valentine cleanup mock OK: event-triggered release, attachment-only scope, independent default-off toggle, retries, contention, clear and shutdown')
