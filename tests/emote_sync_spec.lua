local transportSource,followSource=...
setfenv=function()end
math.clamp=math.clamp or function(v,a,b)return math.max(a,math.min(b,v))end
local now=100;os.clock=function()return now end
workspace={GetServerTimeNow=function()return now end}
local queued={}
task={spawn=function(fn)queued[#queued+1]=fn end}
local function flush()local old=queued;queued={};for _,fn in ipairs(old)do fn()end end
local environment={}
_genv=function()return environment end
local guid=0;HttpService={GenerateGUID=function()guid=guid+1;return 'key'..guid end}
local calls={}
local response={ready=true,source_session_id='source',state={active=true,emote_id=123,playback_key='a',name='Wave',position=1,speed=1,looped=true,sample_time=99}}
BackendAnchorGuard={Running=true,Connected=true,SessionToken='session'}
function BackendAnchorGuard:RemoteCall(method,path,body)
 calls[#calls+1]={Method=method,Path=path,Body=body}
 if method=='GET'then return response elseif method=='PUT'then return {requested=false}else return {ok=true}end
end
assert(load(transportSource))()(_G)
local transport=EmoteSyncTransport
transport:Tick();flush();assert(#calls==0,'idle transport makes no emote requests')
assert(transport:Follow(20));transport:Tick();flush()
assert(#calls==2 and calls[1].Method=='POST'and calls[2].Method=='GET')
assert(transport:GetState().State.emote_id==123)
transport:Stop();assert(not transport.Target and not transport:GetState());flush()
assert(calls[#calls].Method=='DELETE'and calls[#calls].Body.sequence==2)
local count=#calls;now=101;transport:Tick();flush();assert(#calls==count,'no polling after stop')
currentAnimTrack={IsPlaying=true,TimePosition=2,Speed=0,Looped=true}
environment.lastVexroEmote={id=123,name='Wave'}
BackendAnchorGuard.EmoteSyncRequested=true;transport:Tick();flush()
assert(calls[#calls].Method=='PUT'and calls[#calls].Body.speed==0 and calls[#calls].Body.active)
assert(not BackendAnchorGuard.EmoteSyncRequested,'publication stops when backend reports no subscribers')
count=#calls;now=102;transport:Tick();flush();assert(#calls==count)
transport:Destroy()
-- Test real follower playback logic with the actual opt-in transport.
assert(load(transportSource))()(_G);transport=EmoteSyncTransport
local allSignals={}
local function signal()
 local handlers={};local s={}
 function s:Connect(fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;handlers[#handlers+1]={fn,c};return c end
 function s:Fire(...)for _,h in ipairs(handlers)do if h[2].Connected then h[1](...)end end end
 function s:Count()local n=0;for _,h in ipairs(handlers)do if h[2].Connected then n=n+1 end end;return n end
 allSignals[#allSignals+1]=s;return s
end
Players={PlayerRemoving=signal()};RunService={Heartbeat=signal()};gui={Destroying=signal()}
player={CharacterRemoving=signal(),IsFriendsWith=function()return true end}
local friend={UserId=20,DisplayName='Friend',Parent=Players}
local plays=0
PlayEmote=function(id,name)
 plays=plays+1
 environment.lastVexroEmote={id=id,name=name}
 currentAnimTrack={IsPlaying=true,TimePosition=0,Length=10,Speed=1,Looped=true,AdjustSpeed=function(self,speed)self.Speed=speed end}
end
StopEmote=function()if currentAnimTrack then currentAnimTrack.IsPlaying=false end;currentAnimTrack=nil;environment.lastVexroEmote=nil end
EquipAnimationPack=function()end;StartCombo=function()end
assert(load(followSource))()(_G)
local follow=LocalEmoteFollow
count=#calls;RunService.Heartbeat:Fire(.2);transport:Tick();flush();assert(#calls==count,'opening Amigos alone cannot synchronize')
now=100;assert(follow.Start(friend));transport:Tick();flush();RunService.Heartbeat:Fire(.2)
assert(plays==1 and currentAnimTrack.TimePosition==2 and currentAnimTrack.Speed==1,'elapsed server time compensates transport delay')
currentAnimTrack.TimePosition=2.1;now=100.2;RunService.Heartbeat:Fire(.2)
assert(plays==1 and currentAnimTrack.Speed>1 and currentAnimTrack.Speed<1.12,'small drift uses speed correction without restart')
response.state.speed=0;response.state.position=3
now=100.6;transport:Tick();flush();RunService.Heartbeat:Fire(.2)
assert(currentAnimTrack.Speed==0 and currentAnimTrack.TimePosition==3,'pause and position applied')
response.state.playback_key='b';response.state.speed=1;response.state.position=1;response.state.sample_time=now
now=101.2;transport:Tick();flush();RunService.Heartbeat:Fire(.2)
assert(plays==2,'same emote restarted only for new playback key')
response.state.active=false;now=101.8;transport:Tick();flush();RunService.Heartbeat:Fire(.2)
assert(not currentAnimTrack and follow.GetTarget()==friend,'source stop clears playback but keeps explicit selection')
PlayEmote(999,'manual');assert(not follow.GetTarget()and not transport.Target and environment.lastVexroEmote.id==999,'manual playback cancels following')
flush()
assert(follow.Start(friend));Players.PlayerRemoving:Fire(friend);assert(not follow.GetTarget())
flush()
follow.Destroy();transport:Destroy()
for _,s in ipairs(allSignals)do assert(s:Count()==0,'follower signal leaked')end
print('emote_sync_spec OK: no idle requests, opt-in polling/publication, stop cleanup, timestamp compensation, smooth drift, pause, restart identity and manual priority')
