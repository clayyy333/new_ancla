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
	}
	Settings.coupleLoops = type(Settings.coupleLoops) == "table" and Settings.coupleLoops or {}
	Settings.couplePoses = type(Settings.couplePoses) == "table" and Settings.couplePoses or {}
	local connections = {}

	local function roundHalf(value)
		return math.floor((tonumber(value) or 0) * 2 + 0.5) / 2
	end

	function C:Find(query)
		query = tostring(query or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
		local requestedId = tonumber(query)
		for _, emote in ipairs(Emotes) do
			if (requestedId and tonumber(emote.id) == requestedId) or tostring(emote.name):lower() == query then
				self.Selected = emote
				return emote
			end
		end
		return nil
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
		self.StartTime = math.max(0, roundHalf(value))
		if self.EndTime <= self.StartTime then self.EndTime = self.StartTime + 0.5 end
		if self.Track and self.Track.Length > 0 then
			self.StartTime = math.min(self.StartTime, math.max(0, self.Track.Length - 0.5))
		end
	end

	function C:SetEnd(value)
		local maximum = self.Track and self.Track.Length > 0 and self.Track.Length or 999
		self.EndTime = math.clamp(roundHalf(value), self.StartTime + 0.5, maximum)
	end

	function C:StopLoop(fadeTime)
		self.Looping = false
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

		local animation = Instance.new("Animation")
		animation.Name = "VexroCoupleLoop"
		animation.AnimationId = "rbxassetid://" .. tostring(self.Selected.id)
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
		while track.Length <= 0 and waited < 3 and self.Track == track do
			waited = waited + task.wait()
		end
		if self.Track ~= track then return false end
		if track.Length <= 0 then
			self:StopLoop(0)
			return false, isES and "No se pudo obtener la duración del emote." or "Could not read the emote duration."
		end

		self.StartTime = math.clamp(self.StartTime, 0, math.max(0, track.Length - 0.5))
		self.EndTime = math.clamp(self.EndTime, self.StartTime + 0.5, track.Length)
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
			orbit = CouplesPositionController:GetAngle(), rotation = CouplesPositionController:GetSelfAngle(),
		}
		Settings.couplePoses[#Settings.couplePoses + 1] = pose
		SaveLocalData()
		return true
	end

	connections[#connections + 1] = RunService.Heartbeat:Connect(function()
		local track = C.Track
		if not C.Looping or not track or not track.IsPlaying then return end
		if math.abs(track.Speed - C.Speed) > 0.001 then pcall(function() track:AdjustSpeed(C.Speed) end) end
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