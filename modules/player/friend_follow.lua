-- Backend synchronization is opt-in through the Amigos selection button only.
return function(context)
 setfenv(1,context)
 local target,ownedTrack,playbackKey,pending
 local disposed=false
 local selectionVersion=0
 local elapsed,retryAt=0,0
 local status="Selecciona a un amigo del servidor."
 local connections={}
 local basePlay,baseStop=PlayEmote,StopEmote
 local follow={}
 LocalEmoteFollow=follow
 local function stopPlayback()
  if pending or(ownedTrack and currentAnimTrack==ownedTrack)then
   _genv().lastVexroEmote=nil;baseStop(false)
  end
  pending=false;ownedTrack=nil;playbackKey=nil
 end
 function follow.Stop()
  selectionVersion=selectionVersion+1
  target=nil
  if EmoteSyncTransport then EmoteSyncTransport:Stop()end
  stopPlayback();status="Sincronización detenida."
 end
 function follow.GetTarget()return target end
 function follow.GetStatus()return status end
 function follow.IsReady()return target~=nil and ownedTrack~=nil and currentAnimTrack==ownedTrack and ownedTrack.IsPlaying==true end
 function follow.Start(friend)
  if AreFeaturesBlocked and AreFeaturesBlocked()then return false end
  if disposed or not friend or friend==player or friend.Parent~=Players then return false end
  selectionVersion=selectionVersion+1;local version=selectionVersion
  local ok,isFriend=pcall(function()return player:IsFriendsWith(friend.UserId)end)
  if version~=selectionVersion then return false end
  if disposed or not ok or not isFriend or friend.Parent~=Players then status="No se pudo confirmar la amistad de Roblox.";return false end
  if AreFeaturesBlocked and AreFeaturesBlocked()then return false end
  follow.Stop()
  if not EmoteSyncTransport or not EmoteSyncTransport:Follow(friend.UserId)then status="Backend no conectado. Reintenta en unos segundos.";return false end
  target=friend;retryAt=0;status="Esperando sincronización con "..friend.DisplayName.."...";return true
 end
 local function update()
  if disposed or not target then return end
  if target.Parent~=Players then follow.Stop();status="Tu amigo salió del servidor.";return end
  if AreFeaturesBlocked and AreFeaturesBlocked()then follow.Stop();return end
  local sample=EmoteSyncTransport:GetState()
  if not sample then
   stopPlayback();status=EmoteSyncTransport.Status;return
  end
  local state=sample.State
  if not state.active then stopPlayback();status="Tu amigo no está reproduciendo un emote.";return end
  local id=tonumber(state.emote_id)
  if not id then return end
  local key=tostring(sample.Session)..":"..tostring(state.playback_key)
  if playbackKey~=key then stopPlayback();playbackKey=key;retryAt=0 end
  if not ownedTrack and not pending and os.clock()>=retryAt then
   baseStop(false);pending=true;retryAt=os.clock()+3
   local ok=pcall(basePlay,id,tostring(state.name or("Emote "..id)),true)
   if not ok then pending=false end
  end
  if pending then
   local active=_genv().lastVexroEmote
   if currentAnimTrack and currentAnimTrack.IsPlaying and active and tonumber(active.id)==id then
    ownedTrack=currentAnimTrack;pending=false
   elseif os.clock()>=retryAt then pending=false;status="Reintentando cargar el emote...";return end
  end
  if not ownedTrack or currentAnimTrack~=ownedTrack then return end
  if not ownedTrack.IsPlaying then return end
  local speed=tonumber(state.speed)or 1
  local position=(tonumber(state.position)or 0)+math.max(0,workspace:GetServerTimeNow()-(tonumber(state.sample_time)or 0))*speed
  ownedTrack.Looped=state.looped==true
  if ownedTrack.Length>0 then
   local length=ownedTrack.Length
   if ownedTrack.Looped then position=position%length else position=math.clamp(position,0,length)end
   local delta=position-ownedTrack.TimePosition
   if ownedTrack.Looped then delta=(delta+length/2)%length-length/2 end
   if math.abs(delta)>.6 or(speed==0 and math.abs(delta)>.03)then
    ownedTrack.TimePosition=position;ownedTrack:AdjustSpeed(speed)
   else ownedTrack:AdjustSpeed(speed==0 and 0 or speed+math.clamp(delta*.3,-.12,.12))end
  else ownedTrack:AdjustSpeed(speed)end
  status="Sincronizado con "..target.DisplayName.." (backend)"
 end
 -- Existing manual controls retain priority and cancel this opt-in selection.
 PlayEmote=function(...)follow.Stop();return basePlay(...)end
 StopEmote=function(...)follow.Stop();return baseStop(...)end
 local basePack,baseCombo=EquipAnimationPack,StartCombo
 EquipAnimationPack=function(...)follow.Stop();return basePack(...)end
 StartCombo=function(...)follow.Stop();return baseCombo(...)end
 connections[#connections+1]=RunService.Heartbeat:Connect(function(dt)
  elapsed=elapsed+dt;if elapsed<.15 then return end;elapsed=0
  local ok=pcall(update);if not ok then status="No se pudo actualizar el emote sincronizado."end
 end)
 connections[#connections+1]=player.CharacterRemoving:Connect(follow.Stop)
 connections[#connections+1]=Players.PlayerRemoving:Connect(function(leaving)if leaving==target then follow.Stop()end end)
 function follow.Destroy()
  if disposed then return end
  follow.Stop();disposed=true
  for _,connection in ipairs(connections)do connection:Disconnect()end
 end
 connections[#connections+1]=gui.Destroying:Connect(follow.Destroy)
 return true
end
