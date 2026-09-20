-- Reproductor aislado para los bucles de Parejas.
return function(context)
	setfenv(1, context)

	local C = {
		Selected = nil,
		Speed = 1,
		StartTime = 0,
		EndTime = 5,
		Looping = false,
		Track = nil,
		Animation = nil,
		ActivePoseIndex = nil,
		PosePositionOwned = false,
	}
	Settings.coupleLoops = type(Settings.coupleLoops) == "table" and Settings.coupleLoops or {}
	Settings.couplePoses = type(Settings.couplePoses) == "table" and Settings.couplePoses or {}
	local connections = {}

	local function roundHalf(value)
		return math.floor((tonumber(value) or 0) * 2 + 0.5) / 2
	end

	local function roundTenth(value)
		return math.floor((tonumber(value) or 0) * 10 + 0.5) / 10
	end

	function C:Find(query)
		local raw = tostring(query or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if raw == "" then self.Selected = nil; return nil end
		local requestedId = tonumber(raw) or tonumber(raw:match("%((%d+)%)")) or tonumber(raw:match("(%d%d%d%d%d+)"))
		if requestedId then
			for _, emote in ipairs(Emotes) do
				if tonumber(emote.id) == requestedId then self.Selected = emote; return emote end
			end
			self.Selected = {id = requestedId, name = "ID " .. tostring(requestedId)}
			return self.Selected
		end
		local normalized = raw:lower()
		local partial
		for _, emote in ipairs(Emotes) do
			local name = tostring(emote.name):lower()
			if name == normalized then self.Selected = emote; return emote end
			if not partial and name:find(normalized, 1, true) then partial = emote end
		end
		self.Selected = partial
		return partial
	end
	function C:GetSelected() return self.Selected end
	function C:GetTrack() return self.Track end

	function C:SetSpeed(value)
		self.Speed = math.clamp(roundHalf(value), 0.5, 3)
		if self.Track and self.Track.IsPlaying then
			pcall(function() self.Track:AdjustSpeed(self.Speed) end)
		end
	end

	function C:SetStart(value)
		self.StartTime = math.max(0, roundTenth(value))
		if self.EndTime <= self.StartTime then self.EndTime = self.StartTime + 0.1 end
		if self.Track and self.Track.Length > 0 then
			self.StartTime = math.min(self.StartTime, math.max(0, self.Track.Length - 0.1))
		end
	end

	function C:SetEnd(value)
		local maximum = self.Track and self.Track.Length > 0 and self.Track.Length or 999
		self.EndTime = math.clamp(roundTenth(value), self.StartTime + 0.1, maximum)
	end

	function C:StopLoop(fadeTime)
		self.Looping = false
		self.ActivePoseIndex = nil
		if self.PosePositionOwned then CouplesPositionController:Release();self.PosePositionOwned=false end
		if self.Track then pcall(function() self.Track:Stop(fadeTime or 0.1) end) end
		self.Track = nil
		if self.Animation then pcall(function() self.Animation:Destroy() end) end
		self.Animation = nil
	end

	function C:Preview()
		if not self.Selected then
			return false, isES and "Busca un emote por nombre o ID." or "Find an emote by name or ID."
		end
		self:StopLoop(0.05)
		local animator = GetAnimator()
		if not animator then
			return false, isES and "Tu personaje no está disponible." or "Your character is unavailable."
		end

		local animation
		local cached = _animCache and _animCache[self.Selected.id]
		if cached and cached:IsA("Animation") then
			animation = cached:Clone()
		else
			local loadedOk, objects = pcall(function()
				return game:GetObjects("rbxassetid://" .. tostring(self.Selected.id))
			end)
			if loadedOk and objects and #objects > 0 then
				local item = objects[1]
				local source = item:IsA("Animation") and item or item:FindFirstChildWhichIsA("Animation", true)
				if source then animation = source:Clone() end
				for _, object in ipairs(objects) do pcall(function() object:Destroy() end) end
			end
		end
		if not animation then
			animation = Instance.new("Animation")
			animation.AnimationId = "rbxassetid://" .. tostring(self.Selected.id)
		end
		animation.Name = "VexroCoupleLoop"
		local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
		if not ok or not track then
			animation:Destroy()
			return false, isES and "No se pudo cargar el emote." or "Could not load the emote."
		end

		self.Animation = animation
		self.Track = track
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = true
		track:Play(0.1)

		local waited = 0
		while track.Length <= 0 and waited < 8 and self.Track == track do
			waited = waited + task.wait(0.1)
		end
		if self.Track ~= track then return false end
		if track.Length > 0 then
			self.StartTime = math.clamp(self.StartTime, 0, math.max(0, track.Length - 0.1))
			self.EndTime = math.clamp(self.EndTime, self.StartTime + 0.1, track.Length)
		else
			self.StartTime = math.max(0, self.StartTime)
			self.EndTime = math.max(self.StartTime + 0.1, self.EndTime)
		end
		track.TimePosition = self.StartTime
		track:AdjustSpeed(self.Speed)
		self.Looping = true
		return true, isES and "Bucle activo." or "Loop active."
	end

	function C:SaveLoop()
		if not self.Selected then return false end
		local item = {name = self.Selected.name, id = self.Selected.id, speed = self.Speed, start = self.StartTime, finish = self.EndTime}
		Settings.coupleLoops[#Settings.coupleLoops + 1] = item
		SaveLocalData()
		return true, item
	end

	function C:SavePose(loopIndex)
		local loop = Settings.coupleLoops[loopIndex]
		if not loop then return false end
		local pose = {
			name = loop.name, id = loop.id, speed = loop.speed, start = loop.start, finish = loop.finish,
			distance = CouplesPositionController:GetDistance(), height = CouplesPositionController:GetHeight(),
			orbit = CouplesPositionController:GetAngle(), rotation = CouplesPositionController:GetSelfAngle(), tilt = CouplesPositionController:GetTilt(),
		}
		Settings.couplePoses[#Settings.couplePoses + 1] = pose
		SaveLocalData()
		return true
	end

	function C:UseSavedPose(index)
		local pose=Settings.couplePoses[tonumber(index)or 0]
		if not pose then return false,isES and"Pose no encontrada."or"Pose not found."end
		local target=CouplesPositionController:GetTarget()
		if not target or target.Parent~=Players then return false,isES and"Selecciona primero un jugador en Ubicación de cuerpo."or"Select a player in Body location first."end
		self.Selected={id=pose.id,name=pose.name};self.Speed=math.clamp(tonumber(pose.speed)or 1,.1,3);self.StartTime=tonumber(pose.start)or 0;self.EndTime=tonumber(pose.finish)or(self.StartTime+.5)
		local ok,message=self:Preview();if not ok then return false,message end
		CouplesPositionController:SetDistance(tonumber(pose.distance)or 3);CouplesPositionController:SetHeight(tonumber(pose.height)or 0);CouplesPositionController:SetAngle(tonumber(pose.orbit)or 0);CouplesPositionController:SetSelfAngle(tonumber(pose.rotation)or 0);CouplesPositionController:SetTilt(tonumber(pose.tilt)or 0)
		local positioned,positionMessage=CouplesPositionController:Position();if not positioned then self:StopLoop(.05);return false,positionMessage end
		self.ActivePoseIndex=index;self.PosePositionOwned=true
		return true,isES and"Pose activa: "..pose.name or"Pose active: "..pose.name
	end
	function C:RenameSavedPose(index,name)
		local pose=Settings.couplePoses[tonumber(index)or 0];local clean=tostring(name or""):gsub("^%s+",""):gsub("%s+$","")
		if not pose or clean==""then return false end;pose.name=clean;if self.ActivePoseIndex==index and self.Selected then self.Selected.name=clean end;SaveLocalData();return true
	end
	function C:SetSavedPoseSpeed(index,value)
		local pose=Settings.couplePoses[tonumber(index)or 0];if not pose then return false end
		pose.speed=math.round(math.clamp(tonumber(value)or tonumber(pose.speed)or 1,.1,3)*10)/10
		if self.ActivePoseIndex==index then self.Speed=pose.speed;if self.Track and self.Track.IsPlaying then pcall(function()self.Track:AdjustSpeed(self.Speed)end)end end
		SaveLocalData();return true
	end
	function C:DeleteSavedPose(index)
		index=tonumber(index);if not index or not Settings.couplePoses[index]then return false end
		if self.ActivePoseIndex==index then self:StopLoop(.05)elseif self.ActivePoseIndex and self.ActivePoseIndex>index then self.ActivePoseIndex-=1 end
		table.remove(Settings.couplePoses,index);SaveLocalData();return true
	end
	function C:StopSavedPose()self:StopLoop(.1);return true,isES and"Pose detenida."or"Pose stopped."end
	connections[#connections + 1] = RunService.Heartbeat:Connect(function()
		local track = C.Track
		if not C.Looping or not track then return end
		if not track.IsPlaying then
			C.Looping=false;C.ActivePoseIndex=nil;C.Track=nil
			if C.Animation then pcall(function()C.Animation:Destroy()end);C.Animation=nil end
			if C.PosePositionOwned then CouplesPositionController:Release();C.PosePositionOwned=false end
			return
		end
		if math.abs(track.Speed - C.Speed) > 0.001 then pcall(function() track:AdjustSpeed(C.Speed) end) end
		if track.Length > 0 and C.EndTime > track.Length then
			C.StartTime = math.min(C.StartTime, math.max(0, track.Length - 0.1))
			C.EndTime = math.max(C.StartTime + 0.1, math.floor(track.Length * 10) / 10)
		end
		local position = track.TimePosition
		if position >= C.EndTime or position < C.StartTime - 0.05 then
			pcall(function()
				track.TimePosition = C.StartTime
				track:AdjustSpeed(C.Speed)
			end)
		end
	end)
	connections[#connections + 1] = player.CharacterAdded:Connect(function()
		C:StopLoop(0)
	end)

	function C:Destroy()
		self:StopLoop(0)
		for _, connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections)
	end

	CoupleMovementController = C
	return true
end