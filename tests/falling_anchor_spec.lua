local source=...
setfenv=function()end
table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
local order,queued={},{}
local now=1;os.clock=function()return now end
local function note(s)order[#order+1]=s end
local function signal()
 local list={};local s={}
 function s:Connect(f)local c={Connected=true};function c:Disconnect()self.Connected=false end;list[#list+1]={c,f};return c end
 function s:Fire(...)for _,e in ipairs(list)do if e[1].Connected then e[2](...)end end end
 function s:Count()local n=0;for _,e in ipairs(list)do if e[1].Connected then n=n+1 end end;return n end
 return s
end
Vector3={zero={}}
Enum={HumanoidStateType={Dead='Dead',FallingDown='FallingDown',GettingUp='GettingUp'},AnimationPriority={Action4=4}}
local loadedIds={}
local function rig()
 local h={Parent=true,Health=100,MaxHealth=100,BreakJointsOnDeath=true,State='GettingUp',StateChanged=signal(),SeatSignal=signal()}
 function h:GetStateEnabled()return true end
 function h:SetStateEnabled(_,v)note(v and 'defense_off' or 'defense_on')end
 function h:GetState()return self.State end
 function h:ChangeState(s)local old=self.State;self.State=s;note(s=='FallingDown'and 'fall_on'or 'fall_off');if old~=s then self.StateChanged:Fire(old,s)end end
 function h:GetPropertyChangedSignal()return self.SeatSignal end
 local animator={LoadAnimation=function(_,a)
  loadedIds[#loadedIds+1]=a.AnimationId
  return {Play=function()note('play')end,Stop=function()note('stop_emote')end,Destroy=function()end}
 end}
 function h:FindFirstChildOfClass()return animator end
 local position=setmetatable({}, {__sub=function()return {Magnitude=0}end})
 local r={Parent=true,Anchored=false,CFrame={},Position=position}
 local c={}
 function c:WaitForChild(k)return k=='Humanoid'and h or r end
 return c,h,r
end
local character,h,r=rig()
local player={Character=character,CharacterAdded=signal()}
local service={Heartbeat=signal(),PreSimulation=signal()}
game={GetService=function(_,s)return s=='Players'and{LocalPlayer=player}or service end,GetObjects=function()return {}end}
Instance={new=function()return {Destroy=function()end}end}
task={spawn=function(f)queued[#queued+1]=f end}
local function run()while #queued>0 do table.remove(queued,1)()end end
assert(load(source))()(_G)
local core=AssemblyRootGuardCore
assert(core:Start());assert(core.Starting and #order==0)
run()
assert(core.Running and table.concat(order,',')=='play,defense_on,fall_on')
assert(service.PreSimulation:Count()==1 and h.StateChanged:Count()==1)
order={};core:ReplaceEmote(123);run()
assert(table.concat(order,',')=='stop_emote,play','replacement must not restart defenses')
assert(loadedIds[#loadedIds]=='rbxassetid://123')
order={};h.State='GettingUp';now=now+.02;h.StateChanged:Fire('FallingDown','GettingUp')
assert(h.State=='FallingDown','StateChanged restores persistent falling state')
order={};core:Stop()
assert(table.concat(order,',')=='fall_off,defense_off,stop_emote')
assert(not r.Anchored and h.MaxHealth==100)
core:Start();run();assert(loadedIds[#loadedIds]=='rbxassetid://116197008542581','temporary replacement must reset')
local nextCharacter,nextH=rig();player.Character=nextCharacter;player.CharacterAdded:Fire(nextCharacter);run()
assert(core.Running and nextH.State=='FallingDown'and not nextH.Sit and loadedIds[#loadedIds]=='rbxassetid://116197008542581','respawn reapplies default emote and falling defense')
local count=core.StateEscapes
nextH.State='GettingUp';now=now+.02;nextH.StateChanged:Fire('FallingDown','GettingUp')
service.Heartbeat:Fire(.25)
assert(core.StateEscapes==count+1 and nextH.State=='FallingDown','state escape is counted and corrected')
core:Stop();order={};core:Start();core:Stop();order={};run()
assert(#order==0 and not core.Running,'cancelled loading cannot activate later')
core:Destroy()
assert(service.PreSimulation:Count()==0 and service.Heartbeat:Count()==0 and player.CharacterAdded:Count()==0)
print('falling_anchor_spec OK: independent fall state, emote replacement, respawn, counters and cleanup')
