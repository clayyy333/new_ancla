-- Posicionamiento de parejas integrado; no crea una GUI independiente.
return function(context)
	setfenv(1, context)

	local Controller = {
		Target = nil,
		Distance = 3,
		Height = 0,
		Angle = 0,
		SelfAngle = 0,
		HeightInitialized = false,
		HasPositioned = false,
	}
	local connections = {}

	local function getRig(targetPlayer)
		local character = targetPlayer and targetPlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or humanoid.Health <= 0 or not root then return nil, nil end
		return humanoid, root
	end

	function Controller:GetTargetOptions()
		local options = {}
		for _, candidate in ipairs(Players:GetPlayers()) do
			if candidate ~= player then options[#options + 1] = candidate end
		end
		table.sort(options, function(a, b)
			return a.DisplayName:lower() < b.DisplayName:lower()
		end)
		return options
	end

	function Controller:SetTarget(target)
		if typeof(target) ~= "Instance" or not target:IsA("Player") or target == player then return false end
		self.Target = target
		self.HasPositioned = false
		self.HeightInitialized = false
		return true
	end

	function Controller:GetTarget() return self.Target end
	function Controller:GetDistance() return self.Distance end
	function Controller:GetHeight() return self.Height end
	function Controller:GetAngle() return self.Angle end
	function Controller:GetSelfAngle() return self.SelfAngle end

	function Controller:SetDistance(value)
		self.Distance = math.clamp(tonumber(value) or self.Distance, 1.5, 15)
	end
	function Controller:SetHeight(value)
		self.Height = math.clamp(tonumber(value) or self.Height, -8, 8)
		self.HeightInitialized = true
	end
	function Controller:SetAngle(value)
		self.Angle = ((tonumber(value) or self.Angle) + 180) % 360 - 180
	end

	function Controller:SetSelfAngle(value)
		self.SelfAngle = ((tonumber(value) or self.SelfAngle) + 180) % 360 - 180
	end

	function Controller:Position()
		if not self.Target or self.Target == player then
			return false, isES and "Selecciona otro jugador." or "Select another player."
		end
		local localHumanoid, localRoot = getRig(player)
		local _, targetRoot = getRig(self.Target)
		if not localRoot then
			return false, isES and "Tu personaje no está disponible." or "Your character is unavailable."
		end
		if not targetRoot then
			return false, isES and "El personaje objetivo no está disponible." or "The target character is unavailable."
		end

		if localHumanoid.Sit then localHumanoid.Sit = false end
		if not self.HeightInitialized then
			self.Height = math.clamp(localRoot.Position.Y - targetRoot.Position.Y, -8, 8)
			self.HeightInitialized = true
		end
		local orbit = targetRoot.CFrame * CFrame.Angles(0, math.rad(self.Angle), 0)
		local position = (orbit * CFrame.new(0, self.Height, -self.Distance)).Position
		local lookTarget = Vector3.new(targetRoot.Position.X, position.Y, targetRoot.Position.Z)
		localRoot.AssemblyLinearVelocity = Vector3.zero
		localRoot.AssemblyAngularVelocity = Vector3.zero
		localRoot.CFrame = CFrame.lookAt(position, lookTarget) * CFrame.Angles(0, math.rad(self.SelfAngle), 0)
		self.HasPositioned = true
		return true, isES and "Posición aplicada." or "Position applied."
	end

	function Controller:AdjustDistance(delta)
		self:SetDistance(self.Distance + delta)
		if self.HasPositioned then return self:Position() end
		return true
	end
	function Controller:AdjustHeight(delta)
		self:SetHeight(self.Height + delta)
		if self.HasPositioned then return self:Position() end
		return true
	end
	function Controller:AdjustSelfAngle(delta)
		self:SetSelfAngle(self.SelfAngle + delta)
		if self.HasPositioned then return self:Position() end
		return true
	end
	function Controller:AdjustAngle(delta)
		self:SetAngle(self.Angle + delta)
		if self.HasPositioned then return self:Position() end
		return true
	end
	function Controller:Reset()
		self.Distance, self.Height, self.Angle, self.SelfAngle, self.HeightInitialized = 3, 0, 0, 0, false
		if self.HasPositioned then return self:Position() end
		return true
	end

	connections[#connections + 1] = Players.PlayerRemoving:Connect(function(leaving)
		if Controller.Target == leaving then
			Controller.Target = nil
			Controller.HasPositioned = false
			if UpdateCouplesPanel then UpdateCouplesPanel(isES and "El jugador salió." or "The player left.") end
		end
	end)
	connections[#connections + 1] = player.CharacterAdded:Connect(function()
		Controller.HasPositioned = false
	end)

	function Controller:Destroy()
		for _, connection in ipairs(connections) do connection:Disconnect() end
		table.clear(connections)
		self.Target = nil
		self.HasPositioned = false
	end

	CouplesPositionController = Controller
	return true
end