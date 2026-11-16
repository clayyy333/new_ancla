local giftSource,guardSource=...
table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
local function extract(source,first,last)
 local a=assert(source:find(first,1,true));local b=assert(source:find(last,a+#first,true))
 return source:sub(a,b-1)
end
local now=100;os.clock=function()return now end
Core={Alive=true,ReceptionBlocked=false,ReceptionBusy=false,SelectedOrder={1,2,3,4},Selected={[1]=true,[2]=true,[3]=true,[4]=true},Item="Babycar_a"}
function Core:IsOwnerRecipient()return false end
isES=true
local changes=0
function changed()changes=changes+1 end
local requests=0
local resultCallback
BackendAnchorGuard={BlockGiftReception=function(_,callback)requests=requests+1;resultCallback=callback end}
local methods=extract(giftSource,'function Core:SetReceptionBlocked(value)','function Core:OnChanged(fn)')
assert(load(methods))()
Core:BlockReception();assert(requests==1 and Core.ReceptionBusy,'no PIN/access flag needed')
Core:BlockReception();assert(requests==1,'pending request not duplicated')
resultCallback(true);assert(Core.ReceptionBlocked and not Core.ReceptionBusy)
Core:BlockReception();assert(requests==1,'only one successful block per session')
Core:SetReceptionBlocked(false);Core:BlockReception();assert(requests==2,'new session can block again')
resultCallback(false);assert(not Core.ReceptionBlocked and not Core.ReceptionBusy and Core.ReceptionMessage)
local deadlines={[2]=110,[4]=110}
BackendAnchorGuard={IsGiftRecipientBlocked=function(_,id)return deadlines[id]and now<deadlines[id]or false end}
Players={GetPlayerByUserId=function(_,id)return {UserId=id,Name='p'..id}end}
local choose=extract(giftSource,'local function chooseRecipient()','local function obtain(')
local reception=methods:sub((assert(methods:find('local function receptionBlocked',1,true))))
local chooseRecipient=assert(load('local nextRecipientIndex=1;local recipientReadyAt={}\n'..reception..choose..'\nreturn chooseRecipient'))()
assert(chooseRecipient().id==1);assert(chooseRecipient().id==3);assert(chooseRecipient().id==1,'blocked IDs skipped immediately')
now=111;assert(chooseRecipient().id==2,'expired cache does not block indefinitely')
local roundSource=extract(giftSource,'local function runRound(token)','local function runLoop(token)')
local prefix=[[local monitors,MAX_MONITORS=0,8
local MIN_REQUEST_GAP=.15
local RECIPIENT_COOLDOWN=4.25
local lastSendAt=-math.huge
local lastRecipientId
local recipientReadyAt={}
local BOX='GiftBox5'
local recipient={id=2,player={Name='two'}}
local function chooseRecipient()return recipient end
Players.GetPlayerByUserId=function()return recipient.player end
local blocked=false
local function receptionBlocked()return blocked end
local function ensureStock()blocked=blockDuringStock;return true end
local function waitControlled()error('unexpected added wait')end
local function valid()return true end
local function snapshot()return {}end
local function changed()end
local function observeAsync()end
GiftRE={FireServer=function()sends=sends+1 end}
]]
sends=0;blockDuringStock=true
local round=assert(load(prefix..roundSource..'\nreturn runRound'))()
assert(round(1)=='skipped'and sends==0,'recheck after obtaining object, before gift remote')
blockDuringStock=false
round=assert(load(prefix..roundSource..'\nreturn runRound'))()
assert(round(1)=='complete'and sends==1,'unblocked delivery keeps original path')
-- Cache lookup performs no HTTP and expires using local monotonic time.
local cacheMethod=extract(guardSource,'function Guard:IsGiftRecipientBlocked(userId)','local function refreshGiftReceptionBlocks()')
Guard={GiftRecipientBlocks={[2]=120}}
assert(load(cacheMethod))()
assert(Guard:IsGiftRecipientBlocked(2));now=121;assert(not Guard:IsGiftRecipientBlocked(2))
print('gift_reception_spec OK: PIN-free one-way session action, retries, cached skipping, expiration, pre-send recheck and unchanged unblocked path')
