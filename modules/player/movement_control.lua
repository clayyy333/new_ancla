-- Control local de velocidad, salto y teletransporte.
return function(context)
	setfenv(1,context)

	local controller={Target=nil}
	local savedHumanoid=nil
	local defaults=nil

	local function humanoid()
		local character=player.Character
		return character and character:FindFirstChildOfClass("Humanoid")
	end

	local function capture(current)
		if current and savedHumanoid~=current then
			savedHumanoid=current
			defaults={
				WalkSpeed=current.WalkSpeed,
				UseJumpPower=current.UseJumpPower,
				JumpPower=current.JumpPower,
				JumpHeight=current.JumpHeight
			}
		end
		return current
	end

	function controller:SetWalkSpeed(value)
		local current=capture(humanoid())
		value=math.clamp(tonumber(value) or 0,0,99999)
		if not current then return false,"Personaje no disponible" end
		current.WalkSpeed=value
		return true,value
	end

	function controller:RestoreWalkSpeed()
		local current=capture(humanoid())
		if not current or not defaults then return false,"Personaje no disponible" end
		current.WalkSpeed=defaults.WalkSpeed
		return true,defaults.WalkSpeed
	end

	function controller:SetJump(value)
		local current=capture(humanoid())
		value=math.clamp(tonumber(value) or 0,0,99999)
		if not current then return false,"Personaje no disponible" end
		current.UseJumpPower=true
		current.JumpPower=value
		return true,value
	end

	function controller:RestoreJump()
		local current=capture(humanoid())
		if not current or not defaults then return false,"Personaje no disponible" end
		current.UseJumpPower=defaults.UseJumpPower
		current.JumpPower=defaults.JumpPower
		current.JumpHeight=defaults.JumpHeight
		return true,defaults.UseJumpPower and defaults.JumpPower or defaults.JumpHeight
	end

	function controller:SetTarget(target)
		if target==player then target=nil end
		self.Target=target
	end

	function controller:Teleport()
		local target=self.Target
		if not target or not target.Parent then return false,"Selecciona un jugador" end
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local targetCharacter=target.Character
		local targetRoot=targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
		if not root or not targetRoot then return false,"HumanoidRootPart no disponible" end
		character:PivotTo(targetRoot.CFrame)
		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
		return true,"Teletransporte completado"
	end

	function controller:GetDefaults()
		capture(humanoid())
		return defaults
	end

	player.CharacterAdded:Connect(function(character)
		savedHumanoid=nil
		defaults=nil
		task.defer(function()
			local current=character:WaitForChild("Humanoid",5)
			if current then capture(current) end
		end)
	end)
	capture(humanoid())
	MovementControlController=controller
	return true
end