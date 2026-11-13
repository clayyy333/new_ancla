local source=...
setfenv=function()end
local order={}
local function note(s)order[#order+1]=s end
Vector3={zero={}}
Enum={HumanoidStateType={Dead='Dead',Seated='Seated',GettingUp='GettingUp'},AnimationPriority={Action4=4}}
local h={Parent=true,Health=100,MaxHealth=100,BreakJointsOnDeath=true}
function h:GetStateEnabled()return true end
function h:SetStateEnabled(_,v)note(v and 'defense_off' or 'defense_on')end
function h:ChangeState(s)note(s=='Seated'and 'sit_on'or 'sit_off')end
local playing={Play=function()note('play')end,Stop=function()note('stop_emote')end,Destroy=function()end}
local animator={LoadAnimation=function()return playing end}
function h:FindFirstChildOfClass()return animator end
local r={Parent=true,Anchored=false,CFrame={}}
local character={}
function character:FindFirstChildOfClass()return h end
function character:FindFirstChild()return r end
local player={Character=character}
local disconnected=false
local service={Heartbeat={Connect=function(_,f)return {Disconnect=function()disconnected=true end}end}}
game={GetService=function(_,s)return s=='Players'and{LocalPlayer=player}or service end,
 GetObjects=function()return {}end}
Instance={new=function()return {Destroy=function()end}end}
local queued={}
task={spawn=function(f)queued[#queued+1]=f end}
assert(load(source))()(_G)
local core=NoSitAnchorCore
assert(core:Start());assert(core.Starting and #order==0)
table.remove(queued,1)()
assert(core.Running and table.concat(order,',')=='play,defense_on,sit_on')
order={};core:Stop()
assert(table.concat(order,',')=='sit_off,defense_off,stop_emote')
assert(not r.Anchored and h.MaxHealth==100 and disconnected)
order={};core:Start();core:Stop();order={};table.remove(queued,1)()
assert(#order==0 and not core.Running,'cancelled emote loading must not enable defenses')
print('no_sit_anchor_spec OK: exact start/stop order, restoration and cancellation')
