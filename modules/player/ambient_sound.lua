-- Control no destructivo del ambiente de dia y noche.
return function(context)
	setfenv(1, context)

	local SOUND_NAMES = {
		Environment_City_Night = true,
		Environment_City_New = true,
	}
	local IS_METRO_LIFE = game.GameId == 4540138978
	local SoundService = game:GetService("SoundService")
	local AMBIENT_WORDS = {"ambient","ambience","environment","atmosphere","weather","wind","rain","storm","ocean","sea","wave","forest","jungle","bird","cricket","night","nature","waterfall","river","city ambience","city ambient","city environment"}
	local EXCLUDED_WORDS = {"music","song","radio","button","click","interface","ui_","vehicle","engine","motor","footstep","weapon","gun","voice","dialog","emote","notification","alarm"}


	AmbientSoundController = {
		Enabled = Settings.ambientSound ~= false,
		_originalVolumes = {},
		_soundConnections = {},
		_connections = {},
		_applying = false,
		_destroyed = false,
	}

	function AmbientSoundController:_Track(sound)
		if not sound:IsA("Sound") or not SOUND_NAMES[sound.Name] or self._soundConnections[sound] then return end
		self._originalVolumes[sound] = sound.Volume
		self._soundConnections[sound] = sound:GetPropertyChangedSignal("Volume"):Connect(function()
			if self._applying then return end
			if not self.Enabled then
				if sound.Volume > 0 then self._originalVolumes[sound] = sound.Volume end
				self._applying = true
				sound.Volume = 0
				self._applying = false
			else
				self._originalVolumes[sound] = sound.Volume
			end
		end)
		self:_ApplySound(sound)
	end
	function AmbientSoundController:_IsUniversalAmbient(sound)
		if not sound:IsA("Sound") or not sound.Looped then return false end
		if sound:GetAttribute("Ambient") == true or sound:GetAttribute("IsAmbient") == true or sound:GetAttribute("EnvironmentSound") == true then return true end
		local parts={sound.Name}
		if sound.SoundGroup then table.insert(parts,sound.SoundGroup.Name) end
		local ancestor=sound.Parent
		for _=1,5 do
			if not ancestor then break end
			if ancestor:IsA("Tool") or ancestor:IsA("VehicleSeat") or ancestor:IsA("Humanoid") then return false end
			if player.Character and ancestor==player.Character then return false end
			table.insert(parts,ancestor.Name);ancestor=ancestor.Parent
		end
		local identity=string.lower(table.concat(parts," "))
		for _,word in ipairs(EXCLUDED_WORDS) do if string.find(identity,word,1,true) then return false end end
		for _,word in ipairs(AMBIENT_WORDS) do if string.find(identity,word,1,true) then return true end end
		return false
	end
	function AmbientSoundController:_TrackUniversal(sound)
		if self._destroyed or not self:_IsUniversalAmbient(sound) or self._soundConnections[sound] then return end
		self._originalVolumes[sound]=sound.Volume
		self._soundConnections[sound]=sound:GetPropertyChangedSignal("Volume"):Connect(function()
			if self._applying then return end
			if not self.Enabled then
				if sound.Volume>0 then self._originalVolumes[sound]=sound.Volume end
				self._applying=true;sound.Volume=0;self._applying=false
			else self._originalVolumes[sound]=sound.Volume end
		end)
		self:_ApplySound(sound)
	end
	function AmbientSoundController:_BindUniversalRoot(root)
		table.insert(self._connections,root.DescendantAdded:Connect(function(object) if not self._destroyed then self:_TrackUniversal(object) end end))
		task.spawn(function()
			for index,object in ipairs(root:GetDescendants()) do
				self:_TrackUniversal(object)
				if self._destroyed then break end
				if index%250==0 then task.wait() end
			end
		end)
	end


	function AmbientSoundController:_ApplySound(sound)
		if not sound or not sound.Parent then return end
		self._applying = true
		sound.Volume = self.Enabled and (self._originalVolumes[sound] or 1) or 0
		self._applying = false
	end

	function AmbientSoundController:_BindAudios(audios)
		if not audios then return end
		for _, child in ipairs(audios:GetChildren()) do self:_Track(child) end
		table.insert(self._connections, audios.ChildAdded:Connect(function(child)
			self:_Track(child)
		end))
	end

	function AmbientSoundController:SetEnabled(enabled)
		self.Enabled = enabled == true
		for sound in pairs(self._originalVolumes) do self:_ApplySound(sound) end
	end

	function AmbientSoundController:Destroy()
		if self._destroyed then return end
		self._destroyed = true
		self.Enabled = true
		for sound in pairs(self._originalVolumes) do self:_ApplySound(sound) end
		for _, connection in ipairs(self._connections) do connection:Disconnect() end
		for _, connection in pairs(self._soundConnections) do connection:Disconnect() end
		table.clear(self._connections)
		table.clear(self._soundConnections)
	end

	if IS_METRO_LIFE then
		local audios=workspace:FindFirstChild("Audios")
		if audios then AmbientSoundController:_BindAudios(audios) end
		table.insert(AmbientSoundController._connections,workspace.ChildAdded:Connect(function(child)
			if child.Name=="Audios" then AmbientSoundController:_BindAudios(child) end
		end))
	else
		AmbientSoundController:_BindUniversalRoot(SoundService)
		AmbientSoundController:_BindUniversalRoot(workspace)
	end

	return true
end