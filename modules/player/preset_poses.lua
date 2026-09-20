-- Poses predeterminadas aisladas del reproductor normal.
return function(context)
	setfenv(1,context)
	local C={Role=nil,Mode="solo",Target=nil,Speed=1,Track=nil,Animation=nil,Active=false,PositionOwned=false,StartTime=0,PendingPose=nil,SyncSuspended=false,SignalToken=0,Status="Selecciona una pose."}
	local connections,resolvedIds={},{}
	local signalSpeeds={Pose1=2.71,Pose2=2.72}
	local poses={
		Pose1={girl={id=78272860047654,distance=1.4,height=1.6,orbit=30,rotation=0,tilt=0,start=0},boy={id=84288917893504,start=0}},
		Pose2={girl={id=78272860047654,distance=1.3,height=1.4,orbit=30,rotation=0,tilt=-5,start=0},boy={id=74006637928491,start=4,endTrim=1.5}}
	}
	C.Selected="Pose1"
	local function opposite(role)return role=="boy"and"girl"or"boy"end
	local function displayName(name)return name:gsub("Pose","Pose ")end
	local function animatorFor(p)local character=p and p.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid");return humanoid and(humanoid:FindFirstChildOfClass("Animator")or humanoid:WaitForChild("Animator",2))end
	local function loadAnimation(id)
		local cached=_animCache and _animCache[id];if cached and cached:IsA("Animation")then local clone=cached:Clone();resolvedIds[id]=tonumber(clone.AnimationId:match("%d+"))or id;return clone end
		local animation;local ok,objects=pcall(function()return game:GetObjects("rbxassetid://"..id)end)
		if ok and objects and #objects>0 then local item=objects[1];local source=item:IsA("Animation")and item or item:FindFirstChildWhichIsA("Animation",true);if source then animation=source:Clone()end;for _,object in ipairs(objects)do pcall(function()object:Destroy()end)end end
		if not animation then animation=Instance.new("Animation");animation.AnimationId="rbxassetid://"..id end
		animation.Name="VexroPresetPose";resolvedIds[id]=tonumber(animation.AnimationId:match("%d+"))or id;return animation
	end
	local function resolvedCatalog(id)if resolvedIds[id]then return resolvedIds[id]end;local probe=loadAnimation(id);local result=resolvedIds[id]or id;probe:Destroy();return result end
	local function trackId(track)return track.Animation and tonumber(track.Animation.AnimationId:match("%d+"))end
	local function partnerTrack(target,id)local animator=animatorFor(target);if not animator then return nil end;for _,track in ipairs(animator:GetPlayingAnimationTracks())do if trackId(track)==id and track.IsPlaying then return track end end end
	local function applyGirlDefaults(self)if self.Role~="girl"then return end;local d=poses[self.Selected].girl;CouplesPositionController:SetDistance(d.distance);CouplesPositionController:SetHeight(d.height);CouplesPositionController:SetAngle(d.orbit);CouplesPositionController:SetSelfAngle(d.rotation);CouplesPositionController:SetTilt(d.tilt or 0)end
	function C:GetPose()return poses[self.Selected]end
	function C:GetSelected()return self.Selected end
	function C:GetRole()return self.Role end
	function C:GetMode()return self.Mode end
	function C:GetTarget()return self.Target end
	function C:GetSpeed()return self.Speed end
	function C:IsActive()return self.Active end
	function C:GetStatus()return self.Status end
	function C:GetPendingPose()return self.PendingPose end
	function C:Select(name)
		if not poses[name]then return false end;if self.Active then self:Stop()end
		self.Selected=name;self.Speed=1;self.PendingPose=nil;applyGirlDefaults(self);self.Status=(isES and"Seleccionada "or"Selected ")..displayName(name);return true
	end
	function C:ChangePose(name)
		if not poses[name]then return false end;if name==self.Selected then return true end
		if not self.Active or self.Mode~="sync"or not self.Track then return self:Select(name)end
		self.SignalToken+=1;local token=self.SignalToken;self.SyncSuspended=true;self.PendingPose=nil
		pcall(function()self.Track:AdjustSpeed(signalSpeeds[name])end);self.Status=(isES and"Anunciando cambio a "or"Announcing change to ")..displayName(name).."..."
		task.delay(.8,function()if C.SignalToken~=token then return end;C:Stop(true);C.Selected=name;C.Speed=1;applyGirlDefaults(C);C:Start();if UpdatePresetPosePanel then UpdatePresetPosePanel()end end);return true
	end
	function C:_ReceivePoseChange(name)
		if not poses[name]or name==self.Selected or self.PendingPose==name then return end
		self.PendingPose=name;self.SyncSuspended=true;self.Status=(isES and"Tu compañero cambió a "or"Your partner changed to ")..displayName(name).."."
		if ShowPresetPoseChange then ShowPresetPoseChange(name)end;if UpdatePresetPosePanel then UpdatePresetPosePanel()end
	end
	function C:AcceptPendingPose()
		local name=self.PendingPose;if not name then return false end;self.PendingPose=nil;if HidePresetPoseChange then HidePresetPoseChange()end
		self:Stop(true);self.Selected=name;self.Speed=1;applyGirlDefaults(self);return self:Start()
	end
	function C:CancelPendingPose()self.PendingPose=nil;if HidePresetPoseChange then HidePresetPoseChange()end;return self:Stop(false)end
	function C:SetRole(role)if role~="boy"and role~="girl"then return false end;if self.Active then self:Stop()end;self.Role=role;applyGirlDefaults(self);self.Status=role=="girl"and(isES and"Rol Chica seleccionado."or"Girl role selected.")or(isES and"Rol Chico seleccionado."or"Boy role selected.");return true end
	function C:SetMode(mode)if mode~="solo"and mode~="sync"then return false end;self.Mode=mode;return true end
	function C:SetTarget(target)if typeof(target)~="Instance"or not target:IsA("Player")or target==player then return false end;self.Target=target;local height=CouplesPositionController:GetHeight();CouplesPositionController:SetTarget(target);CouplesPositionController:SetHeight(height);return true end
	function C:GetFriendOptions()local result={};for _,candidate in ipairs(Players:GetPlayers())do if candidate~=player then local ok,value=pcall(function()return player:IsFriendsWith(candidate.UserId)end);if ok and value then result[#result+1]=candidate end end end;table.sort(result,function(a,b)return a.DisplayName:lower()<b.DisplayName:lower()end);return result end
	function C:SetSpeed(value,localEdit)if self.Mode=="sync"and self.Role=="girl"and localEdit then self.Status=isES and"En sincronización, el Chico controla la velocidad."or"In sync mode, the Boy controls speed.";return false end;self.Speed=math.round(math.clamp(tonumber(value)or self.Speed,.1,3)*10)/10;if self.Track and self.Track.IsPlaying then pcall(function()self.Track:AdjustSpeed(self.Speed)end)end;return true end
	function C:AdjustSpeed(delta)return self:SetSpeed(self.Speed+delta,true)end
	function C:Start()
		if not self.Role then return false,isES and"Elige Chico o Chica."or"Choose Boy or Girl."end;if self.Mode=="sync"and(not self.Target or self.Target.Parent~=Players)then return false,isES and"Selecciona un amigo del servidor."or"Select a friend in the server."end
		self:Stop(true);self.Speed=1;self.SyncSuspended=false;applyGirlDefaults(self)
		local animator=animatorFor(player);if not animator then return false,isES and"Tu personaje no está disponible."or"Your character is unavailable."end
		local definition=poses[self.Selected][self.Role];local animation=loadAnimation(definition.id);local ok,track=pcall(function()return animator:LoadAnimation(animation)end)
		if not ok or not track then animation:Destroy();return false,isES and"No se pudo cargar el emote de la pose."or"Could not load the pose emote."end
		self.Animation,self.Track=animation,track;self.StartTime=definition.start or 0;track.Priority=Enum.AnimationPriority.Action4;track.Looped=true;track:Play(.1);track:AdjustSpeed(1);self.Active=true
		if self.StartTime>0 then pcall(function()track.TimePosition=self.StartTime end);task.spawn(function()local waited=0;while C.Track==track and track.Length<=0 and waited<5 do waited+=task.wait(.1)end;if C.Track==track then pcall(function()track.TimePosition=C.StartTime end)end end)end
		if self.Mode=="sync"and self.Role=="girl"then local height=definition.height;CouplesPositionController:SetTarget(self.Target);CouplesPositionController:SetHeight(height);local positioned=CouplesPositionController:Position();self.PositionOwned=positioned==true end
		self.Status=self.Mode=="sync"and(isES and"Pose activa; esperando el emote complementario."or"Pose active; waiting for the matching emote.")or(isES and"Pose individual activa."or"Solo pose active.");return true,self.Status
	end
	function C:Stop(quiet)
		self.SignalToken+=1;self.Active=false;self.SyncSuspended=false;if self.Track then pcall(function()self.Track:Stop(.1)end)end;self.Track=nil;if self.Animation then pcall(function()self.Animation:Destroy()end)end;self.Animation=nil
		if self.PositionOwned then CouplesPositionController:Release();self.PositionOwned=false end;if not quiet then self.Status=isES and"Pose cancelada."or"Pose cancelled."end;return true,self.Status
	end
	local elapsed=0
	connections[#connections+1]=RunService.Heartbeat:Connect(function(dt)
		if not C.Active or not C.Track then return end;elapsed+=dt;if elapsed<.1 then return end;elapsed=0
		if C.StartTime>0 and C.Track.IsPlaying and C.Track.TimePosition<C.StartTime-.05 then pcall(function()C.Track.TimePosition=C.StartTime end)end
		local ownDefinition=poses[C.Selected][C.Role]
		local ownEnd=ownDefinition and C.Track.Length>0 and(C.Track.Length-(ownDefinition.endTrim or 0))or 0
		if ownEnd>C.StartTime and C.Track.TimePosition>=ownEnd then pcall(function()C.Track.TimePosition=C.StartTime end)end
		if C.Mode~="sync"or not C.Target or not C.Role then return end
		local targetAnimator=animatorFor(C.Target)
		if targetAnimator then for _,candidate in ipairs(targetAnimator:GetPlayingAnimationTracks())do local candidateId=trackId(candidate);for poseName,pose in pairs(poses)do local partnerDefinition=pose[opposite(C.Role)];if candidateId==resolvedCatalog(partnerDefinition.id)then local code=signalSpeeds[poseName];if math.abs(candidate.Speed-code)<.008 then C:_ReceivePoseChange(poseName)elseif C.Role=="girl"and poseName~=C.Selected then C:_ReceivePoseChange(poseName)end end end end end
		if C.SyncSuspended then return end
		local partnerDefinition=poses[C.Selected][opposite(C.Role)];local other=partnerTrack(C.Target,resolvedCatalog(partnerDefinition.id))
		if not other then C.Status=isES and"Esperando que el amigo inicie el rol opuesto."or"Waiting for your friend to start the opposite role.";if UpdatePresetPosePanel then UpdatePresetPosePanel()end;return end
		if C.Role=="girl"then C:SetSpeed(other.Speed,false);if other.Length>0 and C.Track.Length>0 then local otherStart=partnerDefinition.start or 0;local ownStart=ownDefinition.start or 0;local otherDuration=math.max(.01,other.Length-otherStart-(partnerDefinition.endTrim or 0));local ownDuration=math.max(.01,C.Track.Length-ownStart-(ownDefinition.endTrim or 0));local phase=((other.TimePosition-otherStart)/otherDuration)%1;local desired=ownStart+phase*ownDuration;if math.abs(C.Track.TimePosition-desired)>math.max(.12,C.Track.Length*.025)then pcall(function()C.Track.TimePosition=desired end)end end end
		C.Status=isES and"Pose sincronizada con "..C.Target.DisplayName.."."or"Pose synced with "..C.Target.DisplayName..".";if UpdatePresetPosePanel then UpdatePresetPosePanel()end
	end)
	connections[#connections+1]=Players.PlayerRemoving:Connect(function(leaving)if leaving==C.Target then C:Stop();C.Target=nil end end);connections[#connections+1]=player.CharacterRemoving:Connect(function()C:Stop(true)end)
	function C:Destroy()self:Stop(true);for _,connection in ipairs(connections)do connection:Disconnect()end end
	PresetPoseController=C;return true
end