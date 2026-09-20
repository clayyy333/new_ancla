-- Poses predeterminadas aisladas del reproductor normal.
return function(context)
	setfenv(1,context)
	local C={Role=nil,Mode="solo",Target=nil,Speed=1,Track=nil,Animation=nil,Active=false,PositionOwned=false,LocalSpeedUntil=0,Status="Selecciona Pose 1."}
	local connections={}
	local resolvedIds={}
	local poses={Pose1={girl={id=78272860047654,distance=1.4,height=1.6,orbit=30,rotation=0},boy={id=84288917893504}}}
	C.Selected="Pose1"
	local function opposite(role)return role=="boy"and"girl"or"boy"end
	local function animatorFor(p)
		local character=p and p.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		return humanoid and(humanoid:FindFirstChildOfClass("Animator")or humanoid:WaitForChild("Animator",2))
	end
	local function loadAnimation(id)
		local cached=_animCache and _animCache[id]
		if cached and cached:IsA("Animation")then return cached:Clone()end
		local animation
		local ok,objects=pcall(function()return game:GetObjects("rbxassetid://"..id)end)
		if ok and objects and #objects>0 then
			local item=objects[1];local source=item:IsA("Animation")and item or item:FindFirstChildWhichIsA("Animation",true)
			if source then animation=source:Clone()end
			for _,object in ipairs(objects)do pcall(function()object:Destroy()end)end
		end
		if not animation then animation=Instance.new("Animation");animation.AnimationId="rbxassetid://"..id end
		animation.Name="VexroPresetPose";resolvedIds[id]=tonumber(animation.AnimationId:match("%d+"))or id;return animation
	end
	local function partnerTrack(target,id)
		local animator=animatorFor(target);if not animator then return nil end
		for _,track in ipairs(animator:GetPlayingAnimationTracks())do
			local animationId=track.Animation and tonumber(track.Animation.AnimationId:match("%d+"))
			if animationId==id and track.IsPlaying then return track end
		end
	end
	function C:GetPose()return poses[self.Selected]end
	function C:GetRole()return self.Role end
	function C:GetMode()return self.Mode end
	function C:GetTarget()return self.Target end
	function C:GetSpeed()return self.Speed end
	function C:IsActive()return self.Active end
	function C:GetStatus()return self.Status end
	function C:SetRole(role)
		if role~="boy"and role~="girl"then return false end
		if self.Active then self:Stop()end
		self.Role=role
		if role=="girl"then
			local d=poses.Pose1.girl;CouplesPositionController:SetDistance(d.distance);CouplesPositionController:SetHeight(d.height);CouplesPositionController:SetAngle(d.orbit);CouplesPositionController:SetSelfAngle(d.rotation)
		end
		self.Status=role=="girl"and(isES and"Rol Chica seleccionado."or"Girl role selected.")or(isES and"Rol Chico seleccionado."or"Boy role selected.")
		return true
	end
	function C:SetMode(mode)if mode~="solo"and mode~="sync"then return false end;self.Mode=mode;return true end
	function C:SetTarget(target)
		if typeof(target)~="Instance"or not target:IsA("Player")or target==player then return false end
		self.Target=target;local height=CouplesPositionController:GetHeight();CouplesPositionController:SetTarget(target);CouplesPositionController:SetHeight(height);return true
	end
	function C:GetFriendOptions()
		local result={}
		for _,candidate in ipairs(Players:GetPlayers())do
			if candidate~=player then local ok,value=pcall(function()return player:IsFriendsWith(candidate.UserId)end);if ok and value then result[#result+1]=candidate end end
		end
		table.sort(result,function(a,b)return a.DisplayName:lower()<b.DisplayName:lower()end);return result
	end
	function C:SetSpeed(value,localEdit)
		if self.Mode=="sync"and self.Role=="girl"and localEdit then self.Status=isES and"En sincronización, el Chico controla la velocidad."or"In sync mode, the Boy controls speed.";return false end
		self.Speed=math.round(math.clamp(tonumber(value)or self.Speed,0.1,3)*10)/10
		if localEdit then self.LocalSpeedUntil=os.clock()+1 end
		if self.Track and self.Track.IsPlaying then pcall(function()self.Track:AdjustSpeed(self.Speed)end)end
		return true
	end
	function C:AdjustSpeed(delta)return self:SetSpeed(self.Speed+delta,true)end
	function C:Start()
		if not self.Role then return false,isES and"Elige Chico o Chica."or"Choose Boy or Girl."end
		if self.Mode=="sync"and(not self.Target or self.Target.Parent~=Players)then return false,isES and"Selecciona un amigo del servidor."or"Select a friend in the server."end
		self:Stop(true)
		local animator=animatorFor(player);if not animator then return false,isES and"Tu personaje no está disponible."or"Your character is unavailable."end
		local definition=poses[self.Selected][self.Role];local animation=loadAnimation(definition.id)
		local ok,track=pcall(function()return animator:LoadAnimation(animation)end)
		if not ok or not track then animation:Destroy();return false,isES and"No se pudo cargar el emote de la pose."or"Could not load the pose emote."end
		self.Animation,self.Track=animation,track;track.Priority=Enum.AnimationPriority.Action4;track.Looped=true;track:Play(.1);track:AdjustSpeed(self.Speed);self.Active=true
		if self.Mode=="sync"and self.Role=="girl"then
			CouplesPositionController:SetDistance(definition.distance)
			CouplesPositionController:SetHeight(definition.height)
			CouplesPositionController:SetAngle(definition.orbit)
			CouplesPositionController:SetSelfAngle(definition.rotation)
			local height=definition.height
			CouplesPositionController:SetTarget(self.Target)
			CouplesPositionController:SetHeight(height)
			local positioned=CouplesPositionController:Position();self.PositionOwned=positioned==true
		end
		self.Status=self.Mode=="sync"and(isES and"Pose activa; esperando el emote complementario."or"Pose active; waiting for the matching emote.")or(isES and"Pose individual activa."or"Solo pose active.")
		return true,self.Status
	end
	function C:Stop(quiet)
		self.Active=false
		if self.Track then pcall(function()self.Track:Stop(.1)end)end;self.Track=nil
		if self.Animation then pcall(function()self.Animation:Destroy()end)end;self.Animation=nil
		if self.PositionOwned then CouplesPositionController:Release();self.PositionOwned=false end
		if not quiet then self.Status=isES and"Pose cancelada."or"Pose cancelled."end
		return true,self.Status
	end
	local elapsed=0
	connections[#connections+1]=RunService.Heartbeat:Connect(function(dt)
		if not C.Active or C.Mode~="sync"or not C.Target or not C.Role or not C.Track then return end
		elapsed+=dt;if elapsed<.1 then return end;elapsed=0
		local expectedCatalog=poses[C.Selected][opposite(C.Role)].id
		local expected=resolvedIds[expectedCatalog]
		if not expected then local probe=loadAnimation(expectedCatalog);expected=resolvedIds[expectedCatalog]or expectedCatalog;probe:Destroy()end
		local other=partnerTrack(C.Target,expected)
		if not other then C.Status=isES and"Esperando que el amigo inicie el rol opuesto."or"Waiting for your friend to start the opposite role.";if UpdatePresetPosePanel then UpdatePresetPosePanel()end;return end
		if C.Role=="girl"then
			if os.clock()>=C.LocalSpeedUntil and math.abs(C.Speed-other.Speed)>.02 then C:SetSpeed(other.Speed,false)end
			if other.Length>0 and C.Track.Length>0 then
				local phase=(other.TimePosition/other.Length)%1;local desired=phase*C.Track.Length;local error=math.abs(C.Track.TimePosition-desired)
				if error>math.max(.12,C.Track.Length*.025)then pcall(function()C.Track.TimePosition=desired end)end
			end
		end
		C.Status=isES and"Pose sincronizada con "..C.Target.DisplayName.."."or"Pose synced with "..C.Target.DisplayName.."."
		if UpdatePresetPosePanel then UpdatePresetPosePanel()end
	end)
	connections[#connections+1]=Players.PlayerRemoving:Connect(function(leaving)if leaving==C.Target then C:Stop();C.Target=nil end end)
	connections[#connections+1]=player.CharacterRemoving:Connect(function()C:Stop(true)end)
	function C:Destroy()self:Stop(true);for _,connection in ipairs(connections)do connection:Disconnect()end end
	PresetPoseController=C
	return true
end