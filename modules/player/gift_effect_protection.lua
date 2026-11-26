return function(context)
 setfenv(1,context)
 if game.GameId~=4540138978 then return true end
 local Players=game:GetService("Players")
 local RunService=game:GetService("RunService")
 local Workspace=game:GetService("Workspace")
 local player=Players.LocalPlayer
 local GIFT_SOUND="6691605753"
 local GIFT_ANIMATION="15149069792"
 local WHISTLE_ANIMATION="12950737918"
 local WHISTLE_SOUND="7205271810"
 local WINDOW=3
 local Core={GiftEffectsEnabled=false,WhistleAnimationEnabled=false,WhistleSoundEnabled=false,WhistleScope="SELF",Alive=true,_changed=Instance.new("BindableEvent")}
 local connections={}
 local characterConnections={}
 local toolConnections={}
 local giftSounds={}
 local pendingSounds={}
 local playerStates={}
 local animator,animationConnection,heartbeat,deadline,backpackConnection
 local function id(value)return tostring(value):match("%d+")or""end
 local function connect(signal,callback,bucket)
  local connection=signal:Connect(function(...)if Core.Alive then callback(...)end end)
  connections[connection]=true
  if bucket then bucket[#bucket+1]=connection end
  return connection
 end
 local function disconnect(connection)
  if connection then pcall(function()connection:Disconnect()end);connections[connection]=nil end
 end
 local function clear(bucket)
  for _,connection in ipairs(bucket)do disconnect(connection)end
  table.clear(bucket)
 end
 local function changed()Core._changed:Fire()end
 local function restoreVolume(sound,state)
  if not state or not state.muted then return end
  state.muted=false;state.changing=true
  pcall(function()sound.Volume=state.originalVolume end)
  state.changing=false
 end
 local function muteVolume(sound,state)
  if state.changing then return end
  if not state.muted then state.originalVolume=sound.Volume;state.muted=true end
  if sound.Volume~=0 then state.changing=true;pcall(function()sound.Volume=0 end);state.changing=false end
 end
 local function releaseGift(sound,restore)
  local state=giftSounds[sound];if not state then return end
  giftSounds[sound]=nil;clear(state.connections)
  if restore then restoreVolume(sound,state)end
 end
 local function applyGift(sound,state)
  if Core.GiftEffectsEnabled and id(sound.SoundId)==GIFT_SOUND then muteVolume(sound,state)end
 end
 local function watchGift(sound)
  if giftSounds[sound]then return end
  local state={originalVolume=sound.Volume,muted=false,changing=false,connections={}}
  giftSounds[sound]=state
  connect(sound:GetPropertyChangedSignal("Volume"),function()
   if not state.changing and sound.Volume~=0 then state.originalVolume=sound.Volume end
   applyGift(sound,state)
  end,state.connections)
  connect(sound:GetPropertyChangedSignal("SoundId"),function()if id(sound.SoundId)~=GIFT_SOUND then releaseGift(sound,true)end end,state.connections)
  connect(sound.Played,function()applyGift(sound,state)end,state.connections)
  connect(sound.Destroying,function()releaseGift(sound,false)end,state.connections)
  applyGift(sound,state)
 end
 local function clearPending(sound)disconnect(pendingSounds[sound]);pendingSounds[sound]=nil end
 local function inspectGift(object)
  if not object:IsA("Sound")then return end
  local soundId=id(object.SoundId)
  if soundId==GIFT_SOUND then watchGift(object);return end
  if soundId~=""and object.Name~=GIFT_SOUND then return end
  if pendingSounds[object]then return end
  local connection
  connection=connect(object:GetPropertyChangedSignal("SoundId"),function()
   local value=id(object.SoundId)
   if value==GIFT_SOUND then clearPending(object);watchGift(object)elseif value~=""and object.Name~=GIFT_SOUND then clearPending(object)end
  end)
  pendingSounds[object]=connection
  task.delay(1,function()if Core.Alive and pendingSounds[object]==connection then clearPending(object)end end)
 end
 local function blockTrack(track)
  local animation=track.Animation;if not animation then return end
  local animationId=id(animation.AnimationId)
  if animationId==GIFT_ANIMATION and Core.GiftEffectsEnabled then pcall(function()track:Stop(0)end)
  elseif animationId==WHISTLE_ANIMATION and Core.WhistleAnimationEnabled then pcall(function()track:Stop(0)end)end
 end
 local function checkAnimations()
  if not animator or not animator.Parent then return end
  for _,track in ipairs(animator:GetPlayingAnimationTracks())do if track.IsPlaying then blockTrack(track)end end
 end
 local function stopHeartbeat()disconnect(heartbeat);heartbeat=nil end
 local function armHeartbeat()
  if not Core.WhistleAnimationEnabled then return end
  deadline=os.clock()+WINDOW
  if heartbeat then return end
  heartbeat=connect(RunService.Heartbeat,function()
   if not Core.WhistleAnimationEnabled or os.clock()>=deadline then stopHeartbeat()else checkAnimations()end
  end)
 end
 local function inspectTool(object)if object:IsA("Tool")and object.Name=="Whistle"then armHeartbeat()end end
 local function bindAnimator(value)
  disconnect(animationConnection);animationConnection=nil;animator=value
  if not animator then return end
  animationConnection=connect(animator.AnimationPlayed,function(track)
   if track.Animation and id(track.Animation.AnimationId)==WHISTLE_ANIMATION then armHeartbeat()end
   blockTrack(track)
  end)
  checkAnimations()
 end
 local function bindCharacter(character)
  clear(characterConnections);clear(toolConnections);stopHeartbeat();bindAnimator(nil)
  if not character then return end
  connect(character.DescendantAdded,function(object)if object:IsA("Animator")and object.Parent==character:FindFirstChildOfClass("Humanoid")then bindAnimator(object)end end,characterConnections)
  connect(character.ChildAdded,inspectTool,toolConnections)
  local humanoid=character:FindFirstChildOfClass("Humanoid")
  if humanoid then bindAnimator(humanoid:FindFirstChildOfClass("Animator"))end
 end
 local function playerKey(account)return account==player and"SELF"or"ALL"end
 local function shouldWatch(account)return Core.WhistleSoundEnabled and(Core.WhistleScope=="ALL"or account==player)end
 local function releaseWhistle(state)
  clear(state.soundConnections)
  if state.sound and state.soundState then restoreVolume(state.sound,state.soundState)end
  state.sound=nil;state.soundState=nil
 end
 local function watchWhistle(account,state,sound)
  if not sound:IsA("Sound")or sound.Name~="RefereeWhistle"or state.sound==sound then return end
  releaseWhistle(state)
  local soundState={originalVolume=sound.Volume,muted=false,changing=false}
  state.sound=sound;state.soundState=soundState
  local function apply()
   if shouldWatch(account)and(id(sound.SoundId)==""or id(sound.SoundId)==WHISTLE_SOUND)then muteVolume(sound,soundState)else restoreVolume(sound,soundState)end
  end
  connect(sound:GetPropertyChangedSignal("Volume"),function()if not soundState.changing and sound.Volume~=0 then soundState.originalVolume=sound.Volume end;apply()end,state.soundConnections)
  connect(sound:GetPropertyChangedSignal("SoundId"),apply,state.soundConnections)
  connect(sound.Played,apply,state.soundConnections)
  connect(sound.Destroying,function()releaseWhistle(state)end,state.soundConnections)
  apply()
 end
 local function bindHRP(account,state,root)
  clear(state.hrpConnections);releaseWhistle(state);state.root=root
  if not root then return end
  connect(root.ChildAdded,function(object)if object.Name=="RefereeWhistle"then watchWhistle(account,state,object)end end,state.hrpConnections)
  connect(root.ChildRemoved,function(object)if object==state.sound then releaseWhistle(state)end end,state.hrpConnections)
  local sound=root:FindFirstChild("RefereeWhistle");if sound then watchWhistle(account,state,sound)end
 end
 local function bindPlayerCharacter(account,state,character)
  clear(state.characterConnections);bindHRP(account,state,nil)
  if not character then return end
  connect(character.ChildAdded,function(object)if object.Name=="HumanoidRootPart"then bindHRP(account,state,object)end end,state.characterConnections)
  connect(character.ChildRemoved,function(object)if object==state.root then bindHRP(account,state,nil)end end,state.characterConnections)
  bindHRP(account,state,character:FindFirstChild("HumanoidRootPart"))
 end
 local function unwatchPlayer(account)
  local state=playerStates[account];if not state then return end
  playerStates[account]=nil;clear(state.playerConnections);clear(state.characterConnections);clear(state.hrpConnections);releaseWhistle(state)
 end
 local function watchPlayer(account)
  if not shouldWatch(account)or playerStates[account]then return end
  local state={playerConnections={},characterConnections={},hrpConnections={},soundConnections={}}
  playerStates[account]=state
  connect(account.CharacterAdded,function(character)bindPlayerCharacter(account,state,character)end,state.playerConnections)
  connect(account.CharacterRemoving,function()bindPlayerCharacter(account,state,nil)end,state.playerConnections)
  if account.Character then bindPlayerCharacter(account,state,account.Character)end
 end
 local function refreshPlayers()
  for account in pairs(playerStates)do if not shouldWatch(account)then unwatchPlayer(account)end end
  for _,account in ipairs(Players:GetPlayers())do watchPlayer(account)end
 end
 local function bindBackpack(backpack)
  disconnect(backpackConnection);backpackConnection=nil
  if backpack then backpackConnection=connect(backpack.ChildAdded,inspectTool)end
 end
 function Core:SetGiftEffectsEnabled(enabled)
  self.GiftEffectsEnabled=enabled==true
  for sound,state in pairs(giftSounds)do if self.GiftEffectsEnabled then applyGift(sound,state)else restoreVolume(sound,state)end end
  if self.GiftEffectsEnabled then checkAnimations()end
  changed();return self.GiftEffectsEnabled
 end
 function Core:SetWhistleAnimationEnabled(enabled)
  self.WhistleAnimationEnabled=enabled==true
  if enabled then checkAnimations();local character=player.Character;local backpack=player:FindFirstChildOfClass("Backpack");if(character and character:FindFirstChild("Whistle"))or(backpack and backpack:FindFirstChild("Whistle"))then armHeartbeat()end else stopHeartbeat()end
  changed();return self.WhistleAnimationEnabled
 end
 function Core:SetWhistleSoundEnabled(enabled)self.WhistleSoundEnabled=enabled==true;refreshPlayers();changed();return self.WhistleSoundEnabled end
 function Core:SetWhistleScope(scope)self.WhistleScope=scope=="ALL"and"ALL"or"SELF";refreshPlayers();changed();return self.WhistleScope end
 function Core:OnChanged(callback)return self._changed.Event:Connect(callback)end
 function Core:Destroy()
  if not self.Alive then return end
  self.Alive=false;self.GiftEffectsEnabled=false;self.WhistleAnimationEnabled=false;self.WhistleSoundEnabled=false
  stopHeartbeat();bindAnimator(nil);clear(characterConnections);clear(toolConnections);disconnect(backpackConnection)
  for sound,state in pairs(giftSounds)do restoreVolume(sound,state)end
  for account in pairs(playerStates)do unwatchPlayer(account)end
  for connection in pairs(connections)do disconnect(connection)end
  table.clear(giftSounds);table.clear(pendingSounds);self._changed:Destroy()
 end
 connect(Workspace.DescendantAdded,inspectGift)
 connect(Workspace.DescendantRemoving,function(object)if giftSounds[object]then releaseGift(object,true)end;if pendingSounds[object]then clearPending(object)end end)
 connect(player.CharacterAdded,bindCharacter);connect(player.CharacterRemoving,function()bindCharacter(nil)end)
 connect(player.ChildAdded,function(object)if object:IsA("Backpack")then bindBackpack(object)end end)
 connect(player.ChildRemoved,function(object)if object:IsA("Backpack")then bindBackpack(player:FindFirstChildOfClass("Backpack"))end end)
 connect(Players.PlayerAdded,watchPlayer);connect(Players.PlayerRemoving,unwatchPlayer)
 if player.Character then bindCharacter(player.Character)end
 bindBackpack(player:FindFirstChildOfClass("Backpack"))
 GiftEffectProtectionCore=Core
 return true
end
