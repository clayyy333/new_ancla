local playerSource,uiSource=...
setfenv=function()end
local function signal()return {Connect=function()return {Disconnect=function()end}end}end
local created={}
Instance={new=function(class,parent)
 local o={ClassName=class,Parent=parent,Activated=signal(),FocusLost=signal(),Destroying=signal()}
 function o:GetChildren()local result={};for _,child in ipairs(created)do if child.Parent==self then result[#result+1]=child end end;return result end
 function o:IsA(kind)return self.ClassName==kind end
 function o:GetPropertyChangedSignal()return signal()end
 function o:Destroy()self.Parent=nil end
 created[#created+1]=o;return o
end}
UDim2={new=function(...)return {...}end,fromScale=function(...)return {...}end}
UDim={new=function(...)return {...}end};Vector2={new=function(...)return {...}end}
Color3={new=function(...)return {...}end}
Enum={AutomaticSize={Y=1},Font={GothamBold=1,GothamMedium=2},TextXAlignment={Left=1,Center=2}}
currentTheme={secondary='s',tertiary='t',text='text',textDim='dim',accent='accent'}
RegisterTheme=function()end;content={};titleH=30;game={GameId=4540138978}
Core={State='DETENIDO',Allowed=true,Running=false,AntiEnabled=false,AntiDetected=0,AntiRemoved=0,AntiFailures=0,ReceptionBlocked=false,ReceptionBusy=false,Items={},Item='Babycar_a'}
function Core:GetSelectedCount()return 0 end
function Core:GetPlayers()return {}end
function Core:OnChanged()end
local a=assert(playerSource:find('local stateNamesEN=',1,true))
local b=assert(playerSource:find('local nextRecipientIndex=',a,true))
assert(load(playerSource:sub(a,b-1)))()
GiftDeliveryCore=Core
isES=false
assert(load(uiSource))()(_G)
local function has(text)
 for _,o in ipairs(created)do if o.Text==text then return true end end
 return false
end
assert(has('Recipients')and has('Item')and has('CONTINUOUS DELIVERY: OFF'))
assert(has('Block Gifts ( Only blocks gifts sent by this script )'))
local expected={DETENIDO='STOPPED',OBTENIENDO='OBTAINING ITEM',['ESPERANDO JUGADORES']='WAITING FOR PLAYERS',['ENVIANDO CONTINUO']='SENDING GIFTS CONTINUOUSLY',['ESPERANDO SIGUIENTE OBJETO']='WAITING FOR NEXT ITEM',INICIANDO='STARTING'}
for original,translated in pairs(expected)do
 Core.State=original;UpdateGiftDeliveryPanel()
 assert(Core:GetStateText()==translated)
 assert(has('Status: '..translated..' · 0 recipient(s)'),'state not translated in actual panel')
end
Core.ReceptionBusy=true;UpdateGiftDeliveryPanel();assert(has('Applying block...'))
Core.ReceptionBusy=false;Core.ReceptionBlocked=true;UpdateGiftDeliveryPanel();assert(has('Blocked for this session'))
Core.Running=true;UpdateGiftDeliveryPanel();assert(has('CONTINUOUS DELIVERY: ON'))
Core.Allowed=false;UpdateGiftDeliveryPanel();assert(has('Disabled by administrator'))
-- Preserve the requested Spanish wording and original state identifiers.
isES=true;created={};Core.Allowed=true;Core.State='DETENIDO'
assert(load(uiSource))()(_G)
assert(has('Bloquear Regalos ( Solo  desactiva envios de este mismo script )'))
assert(Core:GetStateText()=='DETENIDO'and Core.State=='DETENIDO')
print('gift_translation_spec OK: English controls, all delivery states, block status, admin message and unchanged Spanish wording')
