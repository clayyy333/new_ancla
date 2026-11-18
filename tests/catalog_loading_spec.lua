local catalogSource,stateSource,animationSource,uiSource=...
setfenv=function()end
local callbacks={};local waits,downloads,restores,refreshes=0,0,0,0
local queued={}
task={wait=function()waits=waits+1 end,spawn=function(fn)queued[#queued+1]=fn end,defer=function(fn)queued[#queued+1]=fn end}
local function flush()local old=queued;queued={};for _,fn in ipairs(old)do fn()end end
local data={}
for i=1,301 do data[#data+1]={id=i,name='Emote '..i}end
data[#data+1]={id=1,name='Duplicate'}
local responses={emotes={data=data},animations={data={{id=7,name='Pack',bundledItems={Idle={1}}}}}}
local mode='normal'
function loadModule(path)
 downloads=downloads+1
 if mode=='cancel'then CatalogLoadState:Destroy()end
 if mode=='error'then error('network unavailable')end
 return path:match('data/(.+)')
end
HttpService={JSONDecode=function(_,key)return responses[key]end}
debugLog=function()end
Enum={HumanoidRigType={R6='R6'}}
player={Character={WaitForChild=function()return {RigType='R15'}end}}
EmotesById={}
CatalogLoadPanel={Refresh=function()callbacks[#callbacks+1]=true end}
UpdateTabData=function()refreshes=refreshes+1 end
RestoreSavedAnimationSelection=function()restores=restores+1 end
local function init()
 assert(load(catalogSource))()(_G)
 assert(load(stateSource))()(_G)
end
init()
local core=CatalogLoadState
assert(downloads==0 and #Emotes==0 and #AnimationPacks==0 and #queued==0,'startup must not fetch catalogs')
assert(core:IsPending('emotes')and core:IsPending('animations'))
assert(core:IsPending('favorites')and core:IsPending('playlists'),'dependent views request explicit emote load')
assert(not core:IsPending('anchor')and not core:IsPending('gift_delivery'))
assert(core:Load('Emotes'))
assert(downloads==0 and core.Emotes.Loading and not core.Emotes.Loaded,'button schedules async work')
assert(not core:Load('Emotes')and not core:Load('Animations'),'duplicate and concurrent large loads suppressed')
flush()
assert(downloads==1 and #Emotes==301 and EmotesById[301]._lname=='emote 301','deduplicated/indexed emotes')
assert(core.Emotes.Loaded and core.Emotes.Progress==1 and not core.Emotes.Loading)
assert(not core.Animations.Loaded and #AnimationPacks==0 and restores==0,'emote load does not fetch/apply animations')
assert(waits>=5 and #callbacks>=5,'preparation yields and reports progress')
assert(not core:Load('Emotes'),'already loaded catalog not fetched again')
assert(core:Load('Animations'));flush()
assert(downloads==2 and core.Animations.Loaded and #AnimationPacks==1 and restores==1)
assert(not core:Load('Animations'))
-- Cancellation during the network request must not commit or refresh a closed GUI.
mode='cancel';init();local cancelled=CatalogLoadState
local before=refreshes
assert(cancelled:Load('Emotes'));flush()
assert(not cancelled.Emotes.Loaded and #Emotes==0 and refreshes==before)
-- Preserve existing fallback catalog behavior when the remote data is unavailable.
mode='error';init();assert(CatalogLoadState:Load('Emotes'));flush()
assert(CatalogLoadState.Emotes.Loaded and CatalogLoadState.Emotes.Fallback and #Emotes==5)
-- Unexpected preparation errors remain retryable, with no partial ID index.
mode='normal';responses.emotes={data='malformed'};init();assert(CatalogLoadState:Load('Emotes'));flush()
assert(not CatalogLoadState.Emotes.Loaded and CatalogLoadState.Emotes.Error and not CatalogLoadState.Active)
responses.emotes={data=data};assert(CatalogLoadState:Load('Emotes'));flush()
assert(CatalogLoadState.Emotes.Loaded and #Emotes==301)
-- Loading animation runtime definitions must not schedule restoration at startup.
local characterSignal={Connect=function()return {}end}
player.CharacterAdded=characterSignal
Settings={animationPackSelection={Idle={id=123,name='saved'}}}
Enum.AnimationPriority={}
local beforeJobs=#queued
assert(load(animationSource))()(_G)
assert(#queued==beforeJobs,'saved animation assets must not be applied at initialization')
print('catalog_loading_spec OK: startup idle, independent explicit loads, progress/yields, deduplication, cancellation, fallback, retry and deferred saved animations')

-- Verify section-local button visibility and progress updates without downloading.
local created={}
Instance={new=function(class)
 local item={ClassName=class,Activated={Connect=function(self,fn)self.Fire=fn end}}
 created[#created+1]=item;return item
end}
UDim2={new=function(...)return {...}end,fromOffset=function(...)return {...}end,fromScale=function(...)return {...}end}
UDim={new=function(...)return {...}end}
Enum.Font={GothamMedium='medium',GothamBold='bold'}
currentTheme={secondary='secondary',tertiary='tertiary',accent='accent',text='text'}
function RegisterTheme()end
content={};titleH=30;isES=true;L={emotes='Emotes',animations='Animaciones'}
scroll={Visible=true};search={Visible=true};pageBar={Visible=true};emptyLbl={Visible=true};playlistsPanel={Visible=true};keybindsPanel={Visible=true}
local pressed
CatalogLoadState={Emotes={Loaded=false,Loading=false,Progress=0},Animations={Loaded=false,Loading=false,Progress=0}}
function CatalogLoadState:ForTab(tab)if tab=='emotes'then return 'Emotes'elseif tab=='animations'then return 'Animations'end end
function CatalogLoadState:IsPending(tab)local kind=self:ForTab(tab);return kind and not self[kind].Loaded or false end
function CatalogLoadState:Load(kind)pressed=kind end
assert(load(uiSource))()(_G)
assert(CatalogLoadPanel:SetTab('emotes')and not scroll.Visible and not search.Visible)
local button
for _,item in ipairs(created)do if item.ClassName=='TextButton'then button=item end end
assert(button and button.Text=='Cargar emotes');button.Activated.Fire();assert(pressed=='Emotes')
assert(CatalogLoadPanel:SetTab('animations'));assert(button.Text=='Cargar animaciones')
CatalogLoadState.Animations.Loading=true;CatalogLoadState.Animations.Progress=.5;CatalogLoadState.Animations.Stage='prepare';CatalogLoadState.Active='Animations';CatalogLoadPanel:Refresh()
assert(not button.Active and button.Text=='Cargando...')
CatalogLoadState.Animations.Loaded=true
assert(not CatalogLoadPanel:SetTab('animations')and not CatalogLoadPanel.Panel.Visible)
assert(not CatalogLoadPanel:SetTab('anchor'),'loader is confined to catalog sections')
print('catalog loader UI OK: separate buttons, loading state and unrelated sections unaffected')
