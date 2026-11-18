-- Idle by default. Follow requests come only from Amigos; publication needs a live subscriber.
return function(context)
 setfenv(1,context)
 local Core={Alive=true,Target=nil,Sequence=0,Sample=nil,Status="",NextPoll=0,NextPublish=0}
 EmoteSyncTransport=Core
 local busyFollow,busyPublish=false,false
 local subscribed=false
 local authToken
 local sampledTrack,playbackKey
 local function guard()return BackendAnchorGuard end
 local function usable(g)return g and g.Running and g.Connected and g.SessionToken end
 local function clearRemote(g,sequence,token)
  -- Captures the session before yielding; sequence makes a delayed stop harmless.
  if usable(g)and g.SessionToken==token then g:RemoteCall("DELETE","/api/v1/emote-sync/follow",{sequence=sequence})end
 end
 function Core:Stop()
  if not self.Target then return end
  self.Sequence=self.Sequence+1;self.Target=nil;self.Sample=nil;subscribed=false
  local sequence,g=self.Sequence,guard()
  local token=g and g.SessionToken
  if usable(g)then task.spawn(function()clearRemote(g,sequence,token)end)end
 end
 function Core:Follow(userId)
  local g=guard()
  if not self.Alive or not usable(g)then self.Status="Backend no conectado. Reintenta en unos segundos.";return false end
  self.Sequence=self.Sequence+1;self.Target=tonumber(userId);self.Sample=nil;subscribed=false;self.NextPoll=0
  self.Status="Conectando sincronización..."
  return self.Target~=nil
 end
 function Core:GetState()
  if self.Sample and os.clock()-self.Sample.Received<=3 then return self.Sample end
 end
 local function publish(g)
  local track=currentAnimTrack
  local active=_genv().lastVexroEmote
  if track~=sampledTrack then sampledTrack=track;playbackKey=HttpService:GenerateGUID(false)end
  local playing=track and track.IsPlaying and active and tonumber(active.id)
  local payload={active=playing and true or false}
  if playing then
   payload.emote_id=tonumber(active.id);payload.name=tostring(active.name or "")
   local last=math.min(#payload.name,160)
   while last<#payload.name and payload.name:byte(last+1)>=128 and payload.name:byte(last+1)<=191 do last=last-1 end
   payload.name=payload.name:sub(1,last)
   payload.playback_key=playbackKey or "";payload.position=math.max(0,track.TimePosition)
   payload.speed=track.Speed;payload.looped=track.Looped;payload.sample_time=workspace:GetServerTimeNow()
  end
  local response=g:RemoteCall("PUT","/api/v1/emote-sync/state",payload)
  if response and response.requested==false then g.EmoteSyncRequested=false end
 end
 function Core:Tick()
  if not self.Alive then return end
  local g=guard()
  if not usable(g)then self.Sample=nil;return end
  if authToken~=g.SessionToken then
   authToken=g.SessionToken;subscribed=false;self.Sample=nil;self.NextPoll=0
  end
  local now=os.clock()
  if g.EmoteSyncRequested and not busyPublish and now>=self.NextPublish then
   self.NextPublish=now+.5;busyPublish=true
   local token=g.SessionToken
   task.spawn(function()
    if Core.Alive and g.SessionToken==token then pcall(publish,g)end
    busyPublish=false
   end)
  end
  if not self.Target or busyFollow or now<self.NextPoll then return end
  self.NextPoll=now+.5;busyFollow=true
  local sequence,target,token=self.Sequence,self.Target,g.SessionToken
  task.spawn(function()
   local function valid()return Core.Alive and Core.Target==target and Core.Sequence==sequence and g.SessionToken==token end
   local ok,err=pcall(function()
    if not subscribed then
     local response=g:RemoteCall("POST","/api/v1/emote-sync/follow",{target_user_id=target,sequence=sequence})
     if not valid()then return end
     if not response then Core.Status="Tu amigo debe tener el script conectado. Reintentando...";Core.NextPoll=os.clock()+2;return end
     subscribed=true
    end
    if not valid()then return end
    local response=g:RemoteCall("GET","/api/v1/emote-sync/state")
    if not valid()then return end
    if response and response.ready and type(response.state)=="table"then
     Core.Sample={State=response.state,Session=response.source_session_id,Received=os.clock()}
     Core.Status="Sincronización por backend activa."
    elseif response then
     Core.Sample=nil
     if response.reason=="not_following"then subscribed=false end
     Core.Status="Esperando el estado del emote de tu amigo..."
    else
     -- A missed request does not restart playback; the last sample expires locally.
     Core.Status="Esperando conexión con la sincronización..."
    end
   end)
   if not ok and valid()then Core.Status="No se pudo actualizar la sincronización.";Core.Sample=nil end
   busyFollow=false
  end)
 end
 function Core:Destroy()self:Stop();self.Alive=false end
 return true
end
