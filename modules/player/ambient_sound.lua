-- Control no destructivo del ambiente de dia y noche.
return function(context)
	setfenv(1, context)

	local SOUND_NAMES = {
		Environment_City_Night = true,
		Environment_City_New = true,
	}

	AmbientSoundController = {
		Enabled = Settings.ambientSound ~= false,
		_originalVolumes = {},
		_soundConnections = {},
		_connections = {},
		_applying = false,
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
		self.Enabled = true
		for sound in pairs(self._originalVolumes) do self:_ApplySound(sound) end
		for _, connection in ipairs(self._connections) do connection:Disconnect() end
		for _, connection in pairs(self._soundConnections) do connection:Disconnect() end
		table.clear(self._connections)
		table.clear(self._soundConnections)
	end

	local audios = workspace:FindFirstChild("Audios")
	if audios then AmbientSoundController:_BindAudios(audios) end
	table.insert(AmbientSoundController._connections, workspace.ChildAdded:Connect(function(child)
		if child.Name == "Audios" then AmbientSoundController:_BindAudios(child) end
	end))

	return true
end