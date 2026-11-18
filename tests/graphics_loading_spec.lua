local loaderSource,controlSource,fpsSource,manifestSource=...
setfenv=function()end
table.clear=table.clear or function(t)for k in pairs(t)do t[k]=nil end end
local queued={}
task={spawn=function(fn)queued[#queued+1]=fn end,wait=function()end}
local function flush()local old=queued;queued={};for _,fn in ipairs(old)do fn()end end
local paths={['player/fps_booster']='FPSBoosterCore',['player/night_shader']='NightShaderCore',['player/sky_fireworks']='SkyFireworksCore'}
local reads,inits,prepares,registered,destroyed=0,0,0,0,0
local mode='normal'
loadstring=load
function AreFeaturesBlocked()return mode=='blocked'end
function RegisterFeatureController()registered=registered+1 end
function loadModule(path)
 reads=reads+1
 if mode=='request_error'then error('network failed')end
 if mode=='cancel'then GraphicsFeatureLoader:Destroy()end
 if mode=='raw'then return 'return function(c)c.NightShaderCore={Destroy=function()end}end'end
 return function(context)
  inits=inits+1
  local instance={Destroy=function()destroyed=destroyed+1 end}
  if path=='player/fps_booster'then instance.Prepare=function(_,progress)prepares=prepares+1;progress(.85,'scan');return true end end
  context[paths[path]]=instance
 end
end
assert(load(loaderSource))()(_G)
local service=GraphicsFeatureLoader
assert(reads==0 and inits==0 and #queued==0,'no graphics sources or controllers loaded at startup')
assert(service:Load('FPSBooster'));assert(not service:Load('FPSBooster')and not service:Load('NightShader'))
assert(reads==0);flush()
assert(reads==1 and inits==1 and prepares==1 and registered==1 and service.States.FPSBooster.Loaded)
assert(not service.States.NightShader.Loaded and not service.States.SkyFireworks.Loaded,'each load is independent')
assert(not service:Load('FPSBooster'))
mode='request_error';assert(service:Load('SkyFireworks'));flush()
assert(service.States.SkyFireworks.Error and not service.States.SkyFireworks.Loaded and not service.Active)
mode='normal';assert(service:Load('SkyFireworks'));flush();assert(service.States.SkyFireworks.Loaded)
mode='raw';assert(service:Load('NightShader'));flush();assert(service.States.NightShader.Loaded)
service:Destroy();assert(not service:Load('FPSBooster'))
assert(load(loaderSource))()(_G);mode='blocked';assert(not GraphicsFeatureLoader:Load('NightShader'))
mode='cancel';assert(GraphicsFeatureLoader:Load('NightShader'));local prior=inits;flush();assert(inits==prior and not GraphicsFeatureLoader.States.NightShader.Loaded)
-- The real FPS controller must not scan Workspace during construction.
local scans=0
local function signal()return {Connect=function()return {Disconnect=function()end}end}end
local workspaceMock={GetDescendants=function()scans=scans+1;return {}end,DescendantAdded=signal()}
local lighting={DescendantAdded=signal()}
game={GameId=1,GetService=function(_,name)if name=='Workspace'then return workspaceMock elseif name=='Lighting'then return lighting else return {LocalPlayer={}}end end}
assert(load(fpsSource))()(_G)
assert(scans==0,'FPS constructor cannot scan the map')
assert(FPSBoosterCore:Prepare(function()end));assert(scans==1)
assert(FPSBoosterCore:Prepare(function()end));assert(scans==1,'LOD cache initialized once')
FPSBoosterCore:Destroy();queued={}
-- UI load card starts idle; progress callbacks do not initialize other features.
mode='normal';assert(load(loaderSource))()(_G)
local created={}
Instance={new=function(class)local o={ClassName=class,Activated={Connect=function(self,fn)self.Fire=fn end}};created[#created+1]=o;return o end}
UDim2={new=function(...)return {...}end,fromOffset=function(...)return {...}end,fromScale=function(...)return {...}end}
UDim={new=function(...)return {...}end}
Enum={Font={GothamBold='bold',Gotham='normal'}}
currentTheme={secondary='secondary',tertiary='tertiary',text='text',textDim='dim',accent='accent'}
RegisterTheme=function()end;isES=true
assert(load(controlSource))()(_G)
local ready=false
local card=CreateGraphicsLoadControl({},'FPSBooster','FPS Booster',0,function(loaded)ready=loaded end)
local button;for _,item in ipairs(created)do if item.ClassName=='TextButton'then button=item end end
assert(card.Visible and not ready and button.Text=='Cargar FPS Booster')
button.Activated.Fire();assert(not button.Active);flush()
assert(ready and not card.Visible and not GraphicsFeatureLoader.States.NightShader.Loaded)
GraphicsFeatureLoader:Destroy()
local manifest=assert(load(manifestSource))()
local ids={};for _,id in ipairs(manifest.order)do ids[id]=true end
assert(ids['player/graphics_feature_loader']and not ids['player/fps_booster']and not ids['player/night_shader']and not ids['player/sky_fireworks'],'heavy modules excluded from startup manifest')
print('graphics_loading_spec OK: no startup download/scan, independent buttons, preparation progress, permissions registration, retries, cancellation and UI states')
