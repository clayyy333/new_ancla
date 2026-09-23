-- Control local de velocidad, salto y teletransporte.
return function(context)
	setfenv(1,context)

	local controller={Target=nil,WalkSpeedEnabled=false,DesiredWalkSpeed=nil}
	local savedHumanoid=nil
	local defaults=nil
	local Workspace=game:GetService("Workspace")
	local RunService=game:GetService("RunService")

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
		self.DesiredWalkSpeed=value
		self.WalkSpeedEnabled=true
		current.WalkSpeed=value
		return true,value
	end

	function controller:RestoreWalkSpeed()
		local current=capture(humanoid())
		if not current or not defaults then return false,"Personaje no disponible" end
		self.WalkSpeedEnabled=false
		self.DesiredWalkSpeed=nil
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

	local function findCharacterRoot(character)
		if not character then return nil end
		for _,name in ipairs({"HumanoidRootPart","LowerTorso","Torso","UpperTorso"}) do
			local part=character:FindFirstChild(name)
			if part and part:IsA("BasePart") then return part end
		end
		return character.PrimaryPart
	end

	local function getCharacterPivot(character)
		if not character or not character.Parent then return nil end
		local ok,pivot=pcall(function() return character:GetPivot() end)
		if not ok or typeof(pivot)~="CFrame" then return nil end
		local position=pivot.Position
		if position.X~=position.X or position.Y~=position.Y or position.Z~=position.Z then return nil end
		return pivot
	end

	local function resolveTargetFrame(target)
		local deadline=os.clock()+1
		local fallback=nil
		repeat
			local targetCharacter=target.Character or Workspace:FindFirstChild(target.Name)
			local targetRoot=findCharacterRoot(targetCharacter)
			if targetRoot then return targetRoot.CFrame,targetRoot end
			fallback=getCharacterPivot(targetCharacter) or fallback
			if fallback then
				pcall(function() Workspace:RequestStreamAroundAsync(fallback.Position,0.25) end)
			end
			task.wait(0.1)
		until os.clock()>=deadline or not target.Parent
		return fallback,nil
	end

	function controller:Teleport()
		local target=self.Target
		if not target or not target.Parent then return false,"Selecciona un jugador" end
		local character=player.Character
		local root=findCharacterRoot(character)
		if not root then return false,"Tu HumanoidRootPart no está disponible" end
		local targetFrame,targetRoot=resolveTargetFrame(target)
		if not targetFrame then return false,"El servidor no replicó la ubicación del jugador" end
		character:PivotTo(targetFrame)
		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
		pcall(function() Workspace:RequestStreamAroundAsync(targetFrame.Position,1) end)
		for _=1,4 do
			RunService.Heartbeat:Wait()
			local latestRoot=findCharacterRoot(target.Character)
			if latestRoot then
				targetRoot=latestRoot
				character:PivotTo(targetRoot.CFrame)
				root.AssemblyLinearVelocity=Vector3.zero
				root.AssemblyAngularVelocity=Vector3.zero
			end
		end
		return true,"Teletransporte completado"
	end

	function controller:GetDefaults()
		capture(humanoid())
		return defaults
	end

	local speedConnection=RunService.Heartbeat:Connect(function()
		if not controller.WalkSpeedEnabled or controller.DesiredWalkSpeed==nil then return end
		local current=humanoid()
		if current and current.WalkSpeed~=controller.DesiredWalkSpeed then
			current.WalkSpeed=controller.DesiredWalkSpeed
		end
	end)

	function controller:Destroy()
		self.WalkSpeedEnabled=false
		self.DesiredWalkSpeed=nil
		if speedConnection then speedConnection:Disconnect();speedConnection=nil end
	end

	player.CharacterAdded:Connect(function(character)
		savedHumanoid=nil
		defaults=nil
		task.defer(function()
			local current=character:WaitForChild("Humanoid",5)
			if current then
				capture(current)
				if controller.WalkSpeedEnabled and controller.DesiredWalkSpeed~=nil then
					current.WalkSpeed=controller.DesiredWalkSpeed
				end
			end
		end)
	end)
	capture(humanoid())
	MovementControlController=controller
	return true
end