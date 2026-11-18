-- Heavy graphics controllers are requested only by their own load buttons.
return function(context)
 setfenv(1,context)
 local definitions={
  FPSBooster={Path="player/fps_booster",Name="FPSBoosterCore"},
  NightShader={Path="player/night_shader",Name="NightShaderCore"},
  SkyFireworks={Path="player/sky_fireworks",Name="SkyFireworksCore"},
 }
 local Core={Alive=true,Active=nil,States={}}
 local listeners={}
 for kind in pairs(definitions)do Core.States[kind]={Loaded=false,Loading=false,Progress=0}end
 GraphicsFeatureLoader=Core
 local function notify(kind)
  for _,fn in ipairs(listeners[kind]or{})do pcall(fn)end
 end
 function Core:OnChanged(kind,fn)
  listeners[kind]=listeners[kind]or{};table.insert(listeners[kind],fn)
 end
 function Core:Load(kind)
  local definition,state=definitions[kind],self.States[kind]
  if not self.Alive or not definition or state.Loaded or self.Active then return false end
  if AreFeaturesBlocked and AreFeaturesBlocked()then return false end
  self.Active=kind;state.Loading=true;state.Error=nil;state.Progress=.02;state.Stage="download"
  for name in pairs(definitions)do notify(name)end
  task.spawn(function()
   local instance
   local function report(value,stage)
    if not Core.Alive then error("Graphics loading cancelled")end
    state.Progress=math.max(state.Progress,math.min(value,.99));state.Stage=stage;notify(kind)
   end
   local ok,err=xpcall(function()
    report(.08,"download");task.wait()
    local initializer=loadModule(definition.Path)
    report(.35,"compile");task.wait()
    -- The project loader normally returns the module's initializer. Also accept raw source.
    if type(initializer)=="string"then
     local compile=loadstring or load
     local chunk,message=compile(initializer,"="..definition.Path)
     assert(chunk,message);initializer=chunk()
    end
    assert(type(initializer)=="function","Invalid graphics module initializer")
    report(.50,"initialize");task.wait()
    initializer(context)
    instance=context[definition.Name]
    assert(type(instance)=="table","Graphics controller was not published")
    state.Instance=instance
    report(.60,"prepare")
    if instance.Prepare then assert(instance:Prepare(report)~=false,"Graphics preparation failed")end
    report(.99,"prepare")
    if RegisterFeatureController then RegisterFeatureController(instance)end
    state.Loaded=true;state.Progress=1;state.Stage="done"
   end,debug.traceback)
   state.Loading=false;Core.Active=nil
   if not ok then
    state.Error=tostring(err);state.Loaded=false
    if instance and instance.Destroy then pcall(instance.Destroy,instance)end
    if context[definition.Name]==instance then context[definition.Name]=nil end
    state.Instance=nil
   end
   if Core.Alive then for name in pairs(definitions)do notify(name)end end
  end)
  return true
 end
 function Core:Destroy()
  if not self.Alive then return end
  self.Alive=false
  for _,state in pairs(self.States)do
   if state.Instance and state.Instance.Destroy then pcall(state.Instance.Destroy,state.Instance)end
  end
  table.clear(listeners)
 end
 return true
end
