local source=...
table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
local function signal()
 local listeners={};local s={}
 function s:Connect(fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;listeners[#listeners+1]={fn,c};return c end
 function s:Fire(...)for _,v in ipairs(listeners)do if v[2].Connected then v[1](...)end end end
 return s
end
local function container(class)
 local c={ClassName=class,children={},ChildAdded=signal()}
 function c:IsA(k)return self.ClassName==k end
 function c:GetChildren()local t={};for i,v in ipairs(self.children)do t[i]=v end;return t end
 return c
end
local backpack=container('Backpack');local char=container('Model');local hum={Health=100}
local function move(tool,parent)
 if tool.Parent then for i,v in ipairs(tool.Parent.children)do if v==tool then table.remove(tool.Parent.children,i)break end end end
 tool.Parent=parent;if parent then parent.children[#parent.children+1]=tool;parent.ChildAdded:Fire(tool)end
end
function hum:EquipTool(tool)for _,v in ipairs(char:GetChildren())do if v:IsA('Tool')and v~=tool then move(v,backpack)end end;move(tool,char)end
function char:FindFirstChildOfClass(k)if k=='Humanoid'then return hum end end
player={UserId=123,Character=char,CharacterAdded=signal(),ChildAdded=signal()}
function player:FindFirstChildOfClass(k)if k=='Backpack'then return backpack end end
local function tool(name,gift)
 local t=container('Tool');t.Name=name;t.gift=gift;t.attribute=signal()
 function t:GetAttribute(k)if k=='IsGift'then return self.gift elseif k=='CreatedBy'then return self.creator end end
 function t:GetAttributeChangedSignal()return self.attribute end
 return t
end
Core={Alive=true,AntiEnabled=false,AntiDetected=0,AntiRemoved=0,AntiFailures=0}
local now=100;os.clock=function()return now end
local jobs={};task={};function task.defer(f,...)jobs[#jobs+1]={f,{...}}end;task.spawn=task.defer
local function flush()local limit=0;while #jobs>0 do limit=limit+1;assert(limit<100);local j=table.remove(jobs,1);j[1](table.unpack(j[2]))end end
RunService={Heartbeat=signal()};function RunService.Heartbeat:Wait()error('unexpected wait')end
local gate={};function gate:Acquire()if self.Owner then return end;self.Owner={};return self.Owner end;function gate:Release(t)assert(self.Owner==t);self.Owner=nil end
local context=setmetatable({},{__index={CleanupToolGate=gate}})
local clear={fail=false};function clear:IsA(k)return k=='RemoteEvent'end
function clear:FireServer(value)assert(value==true);if self.fail then error('test failure')end;local found;for _,t in ipairs(char.children)do if t:IsA('Tool')then assert(not found);found=t end end;assert(found);move(found,nil)end
local ClearRE=clear;local Remotes={};isES=false
local function changed()end
local function connect(s,f,list)local c=s:Connect(f);list[#list+1]=c end
local function disconnect(list)for _,c in ipairs(list)do c:Disconnect()end;table.clear(list)end
local function containers()return {backpack,char}end
local a=assert(source:find('local antiEpoch=0;',1,true));local b=assert(source:find('function Core:Destroy()',a,true))
local code=source:sub(a,b-1)
local prefix='return function(Core,player,context,ClearRE,Remotes,changed,connect,disconnect,containers) '
assert(load(prefix..code..' end'))()(Core,player,context,ClearRE,Remotes,changed,connect,disconnect,containers)
local existing=tool('Babycar_a',true);move(existing,backpack)
Core:SetAntiEnabled(true)
local normal=tool('Whistle',false);move(normal,backpack);flush();assert(normal.Parent==backpack)
local incoming=tool('Babycar_a',true);move(incoming,backpack);flush();assert(incoming.Parent==nil and existing.Parent==backpack and Core.AntiRemoved==1)
local delayed=tool('Whistle',false);move(delayed,backpack);flush();delayed.gift=true;delayed.attribute:Fire();flush();assert(delayed.Parent==nil)
gate.Owner={};local waiting=tool('Babycar_a',true);move(waiting,backpack);flush();assert(waiting.Parent==backpack and Core.AntiFailures==0)
gate.Owner=nil;now=now+1;RunService.Heartbeat:Fire(.05);flush();assert(waiting.Parent==nil,'retry after inherited shared gate releases')
clear.fail=true;local retry=tool('Babycar_a',true);move(retry,backpack);flush();assert(gate.Owner==nil and Core.AntiFailures==1)
clear.fail=false;now=now+1;RunService.Heartbeat:Fire(.05);flush();assert(retry.Parent==nil and Core.AntiRemoved==4)
clear.fail=true;local bounded=tool('Babycar_a',true);move(bounded,backpack);flush();for i=1,5 do now=now+1;RunService.Heartbeat:Fire(.05);flush()end;assert(Core.AntiFailures==4 and gate.Owner==nil,'bounded failures release lock')
clear.fail=false
local arbitrary=tool('AnyOtherModel',false);arbitrary.creator=456;move(arbitrary,backpack);flush();assert(arbitrary.Parent==nil,'foreign tool without IsGift is removed regardless of model')
local own=tool('MyNewObject',false);own.creator=player.UserId;move(own,backpack);flush();assert(own.Parent==backpack,'own acquisitions remain')
local markedLater=tool('AnotherModel',false);move(markedLater,backpack);flush();assert(markedLater.Parent==backpack);markedLater.creator='456';markedLater.attribute:Fire();flush();assert(markedLater.Parent==nil,'delayed creator attribution')
Core:SetAntiEnabled(false);local disabled=tool('Babycar_a',true);move(disabled,backpack);flush();assert(disabled.Parent==backpack)
print('gift_cleanup_spec OK: same-model gifts, inventory protection, delayed marking, gate contention, retry, bounded errors, disable')
