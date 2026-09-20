-- Poses predeterminadas aisladas del reproductor normal.
return function(context)
	setfenv(1,context)
	local C={Role=nil,Mode="solo",Target=nil,Speed=1,Track=nil,Animation=nil,Active=false,Paused=false,PendingResume=false,PartnerTrack=nil,PartnerLastPosition=nil,PositionOwned=false,StartTime=0,PendingPose=nil,SyncSuspended=false,SignalToken=0,Status="Selecciona una pose."}
	local connections,resolvedIds={},{}
	local signalSpeeds={Pose1=2.71,Pose2=2.72,Pose3=2.73,Pose4=2.74}
	local poses={
		Pose1={girl={id=78272860047654,name="Hold Onto",distance=1.4,height=1.6,orbit=30,rotation=0,tilt=0,start=0},boy={id=84288917893504,name="WILL BYERS DONT HIDE",start=0}},
		Pose2={girl={id=78272860047654,name="Hold Onto",distance=1.3,height=1.4,orbit=30,rotation=0,tilt=-5,start=0},boy={id=74006637928491,name="Michael Myers Bounce",start=8.5,finish=9}},
		Pose3={girl={id=130478349245054,name="Sweet hug",distance=0.5,height=5.5,orbit=0,rotation=0,tilt=9,start=3,finish=5.7,speed=2},boy={id=129305096889843,name="Sitting..",start=0,speed=1,lockedPaused=true},girlControlsSpeed=true},
		Pose4={girl={id=130478349245054,name="Sweet hug",distance=3.8,height=4.3,orbit=0,rotation=-180,tilt=-30,start=3,finish=5.7,speed=3},boy={id=129305096889843,name="Sitting..",start=0,speed=1,lockedPaused=true},girlControlsSpeed=true}
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
	function C:IsPaused()return self.Paused end
	function C:IsResumePending()return self.PendingResume end
	function C:IsPauseLocked()local definition=self.Role and poses[self.Selected][self.Role];return definition and definition.lockedPaused==true or false end
	function C:GetStatus()return self.Status end
	function C:GetPendingPose()return self.PendingPose end
	function C:GetActiveEmoteName()
		if not self.Role then return displayName(self.Selected) end
		local definition=poses[self.Selected][self.Role]
		return definition.name or displayName(self.Selected)
	end
	function C:Select(name)
		if not poses[name]then return false end;if self.Active then self:Stop()end
		self.Selected=name;self.Speed=(self.Role and poses[name][self.Role].speed)or 1;self.PendingPose=nil;applyGirlDefaults(self);self.Status=(isES and"Seleccionada "or"Selected ")..displayName(name);return true
	end
	function C:ChangePose(name)
		if not poses[name]then return false end;if name==self.Selected then return true end
		if not self.Active or self.Mode~="sync"or not self.Track then return self:Select(name)end
		self.SignalToken+=1;local token=self.SignalToken;self.SyncSuspended=true;self.PendingPose=nil
		pcall(function()self.Track:AdjustSpeed(signalSpeeds[name])end);self.Status=(isES and"Anunciando cambio a "or"Announcing change to ")..displayName(name).."..."
		task.delay(.8,function()if C.SignalToken~=token then return end;C:Stop(true);C.Selected=name;C.Speed=(C.Role and poses[name][C.Role].speed)or 1;applyGirlDefaults(C);C:Start();if UpdatePresetPosePanel then UpdatePresetPosePanel()end end);return true
	end
	function C:_ReceivePoseChange(name)
		if not poses[name]or name==self.Selected or self.PendingPose==name then return end
		self.PendingPose=name;self.SyncSuspended=true;self.Status=(isES and"Tu compañero cambió a "or"Your partner changed to ")..displayName(name).."."
		if ShowPresetPoseChange then ShowPresetPoseChange(name)end;if UpdatePresetPosePanel then UpdatePresetPosePanel()end
	end
	function C:AcceptPendingPose()
		local name=self.PendingPose;if not name then return false end;self.PendingPose=nil;if HidePresetPoseChange then HidePresetPoseChange()end
		self:Stop(true);self.Selected=name;self.Speed=(self.Role and poses[name][self.Role].speed)or 1;applyGirlDefaults(self);return self:Start()
	end
	function C:CancelPendingPose()self.PendingPose=nil;if HidePresetPoseChange then HidePresetPoseChange()end;return self:Stop(false)end
	function C:SetRole(role)if role~="boy"and role~="girl"then return false end;if self.Active then self:Stop()end;self.Role=role;self.Speed=poses[self.Selected][role].speed or 1;applyGirlDefaults(self);self.Status=role=="girl"and(isES and"Rol Chica seleccionado."or"Girl role selected.")or(isES and"Rol Chico seleccionado."or"Boy role selected.");return true end
	function C:SetMode(mode)if mode~="solo"and mode~="sync"then return false end;self.Mode=mode;return true end
	function C:SetTarget(target)if typeof(target)~="Instance"or not target:IsA("Player")or target==player then return false end;self.Target=target;local height=CouplesPositionController:GetHeight();CouplesPositionController:SetTarget(target);CouplesPositionController:SetHeight(height);return true end
	function C:GetFriendOptions()local result={};for _,candidate in ipairs(Players:GetPlayers())do if candidate~=player then local ok,value=pcall(function()return player:IsFriendsWith(candidate.UserId)end);if ok and value then result[#result+1]=candidate end end end;table.sort(result,function(a,b)return a.DisplayName:lower()<b.DisplayName:lower()end);return result end
	function C:SetSpeed(value,localEdit)if self.Mode=="sync"and self.Role=="girl"and localEdit and not poses[self.Selected].girlControlsSpeed then self.Status=isES and"En sincronización, el Chico controla la velocidad."or"In sync mode, the Boy controls speed.";return false end;self.Speed=math.round(math.clamp(tonumber(value)or self.Speed,.1,4)*10)/10;if self.Track and self.Track.IsPlaying and not self.Paused then pcall(function()self.Track:AdjustSpeed(self.Speed)end)end;return true end
	function C:AdjustSpeed(delta)return self:SetSpeed(self.Speed+delta,true)end
	function C:SetPaused(paused)
		if not self.Active or not self.Track then return false,isES and"Inicia primero una pose."or"Start a pose first."end
		if self:IsPauseLocked()then return false,isES and"Este rol permanece pausado."or"This role remains paused."end
		if paused then
			self.Paused=true;self.PendingResume=false;pcall(function()self.Track:AdjustSpeed(0)end);self.Status=isES and"Pose pausada solo para ti."or"Pose paused only for you."
		elseif self.Mode=="sync"and self.Target and self.Target.Parent==Players and not poses[self.Selected][opposite(self.Role)].lockedPaused then
			self.Paused=true;self.PendingResume=true;pcall(function()self.Track:AdjustSpeed(.001)end);self.Status=isES and"Esperando el final del bucle del compañero..."or"Waiting for the partner loop to finish..."
		else
			self.Paused=false;self.PendingResume=false;pcall(function()self.Track.TimePosition=self.StartTime;self.Track:AdjustSpeed(self.Speed)end);self.Status=isES and"Pose reanudada."or"Pose resumed."
		end
		return true,self.Status
	end
	function C:TogglePaused()return self:SetPaused(not self.Paused,false)end
	function C:Start()
		if not self.Role then return false,isES and"Elige Chico o Chica."or"Choose Boy or Girl."end;if self.Mode=="sync"and(not self.Target or self.Target.Parent~=Players)then return false,isES and"Selecciona un amigo del servidor."or"Select a friend in the server."end
		self:Stop(true);self.SyncSuspended=false;applyGirlDefaults(self)
		local animator=animatorFor(player);if not animator then return false,isES and"Tu personaje no está disponible."or"Your character is unavailable."end
		local definition=poses[self.Selected][self.Role];local animation=loadAnimation(definition.id);local ok,track=pcall(function()return animator:LoadAnimation(animation)end)
		if not ok or not track then animation:Destroy();return false,isES and"No se pudo cargar el emote de la pose."or"Could not load the pose emote."end
		self.Animation,self.Track=animation,track;self.Paused=definition.lockedPaused==true;self.PendingResume=false;self.PartnerTrack=nil;self.PartnerLastPosition=nil;self.StartTime=definition.start or 0;track.Priority=Enum.AnimationPriority.Action4;track.Looped=true;track:Play(.1);track:AdjustSpeed(self.Paused and 0 or self.Speed);self.Active=true
		if self.StartTime>0 then pcall(function()track.TimePosition=self.StartTime end);task.spawn(function()local waited=0;while C.Track==track and track.Length<=0 and waited<5 do waited+=task.wait(.1)end;if C.Track==track then pcall(function()track.TimePosition=C.StartTime end)end end)end
		if self.Mode=="sync"and self.Role=="girl"then local height=definition.height;CouplesPositionController:SetTarget(self.Target);CouplesPositionController:SetHeight(height);local positioned=CouplesPositionController:Position();self.PositionOwned=positioned==true end
		self.Status=self.Mode=="sync"and(isES and"Pose activa; esperando el emote complementario."or"Pose active; waiting for the matching emote.")or(isES and"Pose individual activa."or"Solo pose active.");return true,self.Status
	end
	function C:Stop(quiet)
		self.SignalToken+=1;self.Active=false;self.Paused=false;self.PendingResume=false;self.PartnerTrack=nil;self.PartnerLastPosition=nil;self.SyncSuspended=false;if self.Track then pcall(function()self.Track:Stop(.1)end)end;self.Track=nil;if self.Animation then pcall(function()self.Animation:Destroy()end)end;self.Animation=nil
		if self.PositionOwned then CouplesPositionController:Release();self.PositionOwned=false end;if not quiet then self.Status=isES and"Pose cancelada."or"Pose cancelled."end;return true,self.Status
	end
	local elapsed=0
	connections[#connections+1]=RunService.Heartbeat:Connect(function(dt)
		if not C.Active or not C.Track then return end
		if not C.Track.IsPlaying then C.Active=false;if C.Animation then pcall(function()C.Animation:Destroy()end);C.Animation=nil end;C.Track=nil;if C.PositionOwned then CouplesPositionController:Release();C.PositionOwned=false end;return end
		elapsed+=dt;if elapsed<.1 then return end;elapsed=0
		if C.StartTime>0 and C.Track.IsPlaying and C.Track.TimePosition<C.StartTime-.05 then pcall(function()C.Track.TimePosition=C.StartTime end)end
		local ownDefinition=poses[C.Selected][C.Role]
		local ownEnd=ownDefinition and C.Track.Length>0 and math.min(ownDefinition.finish or C.Track.Length,C.Track.Length)or 0
		if ownEnd>C.StartTime and C.Track.TimePosition>=ownEnd then pcall(function()C.Track.TimePosition=C.StartTime end)end
		if C.Mode~="sync"or not C.Target or not C.Role then return end
		local targetAnimator=animatorFor(C.Target)
		if targetAnimator then for _,candidate in ipairs(targetAnimator:GetPlayingAnimationTracks())do local announced=nil;for poseName,code in pairs(signalSpeeds)do if math.abs(candidate.Speed-code)<.008 then announced=poseName;break end end;if announced then C:_ReceivePoseChange(announced)elseif C.Role=="girl"then local candidateId=trackId(candidate);local matched,count=nil,0;for poseName,pose in pairs(poses)do if candidateId==resolvedCatalog(pose[opposite(C.Role)].id)then matched=poseName;count+=1 end end;if count==1 and matched~=C.Selected then C:_ReceivePoseChange(matched)end end end end
		if C.SyncSuspended then return end
		local partnerDefinition=poses[C.Selected][opposite(C.Role)];local other=partnerTrack(C.Target,resolvedCatalog(partnerDefinition.id))
		if not other then C.Status=isES and"Esperando que el amigo inicie el rol opuesto."or"Waiting for your friend to start the opposite role.";if UpdatePresetPosePanel then UpdatePresetPosePanel()end;return end
		local nowPosition=other.TimePosition;local previousPosition=C.PartnerTrack==other and C.PartnerLastPosition or nil;C.PartnerTrack=other;C.PartnerLastPosition=nowPosition;local partnerPending=other.Speed>0 and other.Speed<.01;local crossedLoop=previousPosition and nowPosition<previousPosition-.05;if C.PendingResume then if partnerPending or crossedLoop then C.Paused=false;C.PendingResume=false;pcall(function()C.Track.TimePosition=C.StartTime;C.Track:AdjustSpeed(C.Speed)end);C.Status=isES and"Pose reanudada junto al compañero."or"Pose resumed with partner." else C.Status=isES and"Esperando el final del bucle del compañero..."or"Waiting for the partner loop to finish...";if UpdatePresetPosePanel then UpdatePresetPosePanel()end;return end elseif C.Paused then return end;if other.Speed<.01 then C.Status=isES and"El compañero está en pausa."or"Partner is paused.";if UpdatePresetPosePanel then UpdatePresetPosePanel()end;return end
		local girlControls=poses[C.Selected].girlControlsSpeed==true;local followsGirl=girlControls and C.Role=="boy";local followsBoy=not girlControls and C.Role=="girl";if followsGirl or followsBoy then C:SetSpeed(other.Speed,false)end;if followsGirl or followsBoy then if other.Length>0 and C.Track.Length>0 then local otherStart=partnerDefinition.start or 0;local ownStart=ownDefinition.start or 0;local otherEnd=math.min(partnerDefinition.finish or other.Length,other.Length);local ownSyncEnd=math.min(ownDefinition.finish or C.Track.Length,C.Track.Length);local otherDuration=math.max(.01,otherEnd-otherStart);local ownDuration=math.max(.01,ownSyncEnd-ownStart);local phase=((other.TimePosition-otherStart)/otherDuration)%1;local desired=ownStart+phase*ownDuration;if math.abs(C.Track.TimePosition-desired)>math.max(.12,C.Track.Length*.025)then pcall(function()C.Track.TimePosition=desired end)end end end
		C.Status=isES and"Pose sincronizada con "..C.Target.DisplayName.."."or"Pose synced with "..C.Target.DisplayName..".";if UpdatePresetPosePanel then UpdatePresetPosePanel()end
	end)
	connections[#connections+1]=Players.PlayerRemoving:Connect(function(leaving)if leaving==C.Target then C:Stop();C.Target=nil end end);connections[#connections+1]=player.CharacterRemoving:Connect(function()C:Stop(true)end)
	function C:Destroy()self:Stop(true);for _,connection in ipairs(connections)do connection:Disconnect()end end
	PresetPoseController=C;return true
end