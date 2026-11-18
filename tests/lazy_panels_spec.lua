local source,manifestSource,tabsSource=...
setfenv=function()end
table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
local function signal()
 local handlers={};local s={}
 function s:Connect(fn)local c={Connected=true};function c:Disconnect()self.Connected=false end;handlers[#handlers+1]={fn,c};return c end
 function s:Fire(...)for _,h in ipairs(handlers)do if h[2].Connected then h[1](...)end end end
 return s
end
local pending={}
task={spawn=function(fn)pending[#pending+1]=fn end,defer=function(fn)pending[#pending+1]=fn end,wait=function()end}
local function flush(limit)
 for _=1,limit or 20 do
  if #pending==0 then return end
  local old=pending;pending={};for _,fn in ipairs(old)do fn()end
 end
 assert(#pending==0,'unbounded retry loop')
end
local function widget()
 local o={Visible=false,MouseButton1Click=signal(),Activated=signal(),Destroying=signal()}
 function o:Destroy()self.Destroying:Fire();self.Parent=nil end
 function o:GetPropertyChangedSignal()return signal()end
 return o
end
Instance={new=function()return widget()end}
UDim2={new=function(...)return {...}end,fromOffset=function(...)return {...}end}
UDim={new=function(...)return {...}end}
Enum={Font={GothamMedium=1,GothamBold=2}}
content={};currentTheme={text='text'};titleH=30;isES=true
RegisterTheme=function()end;warn=function()end
scroll=widget();search=widget();pageBar=widget();emptyLbl=widget()
gui={DescendantAdded=signal()}
game={GameId=4540138978}
local counts,read={},{}
local failure
local function panel(name)
 local o=widget();o.Parent=content;_G[name]=o;gui.DescendantAdded:Fire(o);return o
end
function loadModule(path)
 read[path]=(read[path]or 0)+1
 if failure=='network'then error('network failed')end
 if failure=='cancel'then LazyPanels:Destroy()end
 return function()
  counts[path]=(counts[path]or 0)+1
  if path=='ui/anchor'then panel('anchorPanel')
  elseif path=='ui/settings'then panel('settingsPanel');MakeRow=function()end
  elseif path=='ui/friends'then panel('friendsPanel')
  elseif path=='ui/keybinds_panel'then panel('keybindsPanel')
  elseif path=='ui/playlists'then panel('playlistsPanel')
  elseif path=='player/friend_follow'then LocalEmoteFollow={}
  end
  if failure=='constructor'then error('constructor failed')end
 end
end
local registered=0
RegisterFeatureController=function()registered=registered+1 end
local renders=0
UpdateTabData=function(retry)
 renders=renders+1
 if LazyPanels:Ensure(currentTab,retry~=false)then LazyPanels:Show(currentTab,false)else LazyPanels:Show(currentTab,true)end
end
assert(load(source))()(_G)
local core=LazyPanels
assert(next(read)==nil and next(counts)==nil and #pending==0,'startup must not request any category UI')
assert(core:Ensure('emotes',true),'normal catalog view needs no extra panel')
currentTab='anchor';assert(not core:Ensure('anchor',true));assert(not core:Ensure('anchor',true));flush()
assert(core.States.anchor.Loaded and counts['ui/anchor']==1 and read['ui/anchor']==1)
assert(core:Ensure('anchor',true));flush();assert(counts['ui/anchor']==1,'category cached after opening')
currentTab='friends';assert(not core:Ensure('settings',true));assert(not core:Ensure('friends',true));flush()
assert(counts['ui/settings']==1 and counts['ui/admin_panel']==1 and counts['ui/combo_queue']==1)
assert(counts['ui/friends']==1 and counts['player/friend_follow']==1 and counts['ui/friend_follow']==1 and registered>0)
assert(friendsPanel.Parent==content and core.States.friends.Loaded)
currentTab='keybinds';failure='network';assert(not core:Ensure(currentTab,true));flush()
assert(core.States.keybinds.Error and not core.States.keybinds.Loaded and #pending==0,'failure must not loop automatically')
failure=nil;assert(not core:Ensure('keybinds',true));flush();assert(core.States.keybinds.Loaded)
currentTab='playlists';failure='constructor';assert(not core:Ensure(currentTab,true));flush()
assert(core.States.playlists.Error and playlistsPanel==nil,'failed constructor rolls back panel references')
failure=nil;assert(not core:Ensure('playlists',true));flush();assert(core.States.playlists.Loaded)
game.GameId=1;assert(not core:Ensure('gift_delivery',true));assert(not read['ui/gift_delivery'],'Metro-only access preserved')
currentTab='shaders';failure='cancel';assert(not core:Ensure(currentTab,true));flush()
assert(not counts['ui/shaders']and not core.Alive,'closing during request prevents construction')
local manifest=assert(load(manifestSource))()
local startup={};for _,id in ipairs(manifest.order)do startup[id]=true end
assert(startup['ui/lazy_panels']and startup['ui/gui_transparency'])
for _,id in ipairs({'ui/anchor','ui/settings','ui/admin_panel','ui/gift_delivery','ui/graphics','ui/shaders','ui/friend_follow','player/friend_follow','ui/clothing_scan','ui/fling2','ui/camera_control'})do assert(not startup[id],'heavy category still in startup: '..id)end
print('lazy_panels_spec OK: idle startup, caching, dependency order, queued navigation, retry, rollback, Metro-only gifts and close cancellation')
-- Run the real tab router with ALL deferred panel references absent.
Color3={fromRGB=function(...)return {...}end,new=function(...)return {...}end}
Enum.TextXAlignment={Left=1,Center=2};Enum.TextYAlignment={Top=1}
UDim2.fromScale=UDim2.new

for _,name in ipairs({'anchorPanel','settingsPanel','friendsPanel','keybindsPanel','playlistsPanel'})do _G[name]=nil end
local function nav(ids)local out={};for _,id in ipairs(ids)do out[id]={btn=widget()}end;return out end
mainNavBtns={};for _,id in ipairs({'fling2','anchor','control','graphics','clothing_scan','couples','movements'})do mainNavBtns[id]=widget()end
couplesTabBtns=nav({'couples','couple_movement','poses','preset_poses'})
controlTabBtns=nav({'cinematic_camera','camera_control','gift_delivery','flight_control','car_control','free_car_control','movement_control','vertical_control'})
graphicsTabBtns=nav({'fps_booster','shaders'});anchorTabBtns=nav({'anchor','move_anchored','anchor_auto'})
fling2TabBtns=nav({'fling2','contact_fling','fling_custom','fling_car','fling_car2','fling_object','fling_moto','fling_moto_xeno','fling_experimental'})
tabBtns=nav({'emotes','favorites','recent','animations','friends','settings','playlists','keybinds'})
search=widget();title=widget();L=setmetatable({},{__index=function(_,key)return key end})
TweenService={Create=function()return {Play=function()end}end}
currentTab='emotes';_badEmotes={};Emotes={};EmotesById={};Favorites={};RecentEmotes={};Playlists={};AnimationPacks={}
hideTrendingDropdown=function()end
local refreshed=0;Refresh=function()refreshed=refreshed+1 end
local requested
LazyPanels={Ensure=function(_,tab)requested=tab;return tab=='emotes'end,Show=function()end}
CatalogLoadPanel={SetTab=function()return false end}
assert(load(tabsSource))()(_G)
UpdateTabStyles=function()end
local keybindRefresh=0;RefreshKeybindsPanel=function()keybindRefresh=keybindRefresh+1;assert(keybindsPanel)end
for _,tab in ipairs({'settings','friends','keybinds','playlists','anchor','camera_control','shaders'})do currentTab=tab;UpdateTabData();assert(requested==tab)end
assert(keybindRefresh==0 and refreshed==0,'unprepared panels must not be rendered')
currentTab='emotes';UpdateTabData();assert(refreshed==1)
print('lazy tab router OK: absent panels are safe; keybind/playlist render waits for readiness')
