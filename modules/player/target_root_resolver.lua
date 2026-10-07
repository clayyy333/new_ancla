-- Resolución opcional de objetivos lejanos para flings con objetivo.
return function(context)
	setfenv(1,context)
	local Workspace=game:GetService("Workspace")
	local Resolver={Timeout=1}

	function Resolver:GetCharacter(target)
		if not target then return nil end
		if target:IsA("Model") then return target.Parent and target or nil end
		if not target:IsA("Player") then return nil end
		local character=target.Character
		if character and character.Parent then return character end
		local fallback=Workspace:FindFirstChild(target.Name)
		return fallback and fallback:IsA("Model") and fallback or nil
	end

	function Resolver:GetRoot(target)
		local character=self:GetCharacter(target)
		if not character then return nil end
		local humanoid=character:FindFirstChildOfClass("Humanoid")
		local root=character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
		return humanoid and humanoid.Health>0 and root and root:IsA("BasePart") and root or nil
	end

	function Resolver:Resolve(target,timeout)
		local root=self:GetRoot(target)
		if root then return root end
		if not target or not target.Parent then return nil end
		local deadline=os.clock()+(tonumber(timeout) or self.Timeout)
		repeat
			local character=self:GetCharacter(target)
			root=self:GetRoot(target)
			if root then return root end
			if character and character.Parent then
				local ok,pivot=pcall(function() return character:GetPivot() end)
				if ok and typeof(pivot)=="CFrame" then
					pcall(function() Workspace:RequestStreamAroundAsync(pivot.Position,0.2) end)
				end
			end
			task.wait(0.05)
		until os.clock()>=deadline or not target.Parent
		return self:GetRoot(target)
	end

	TargetRootResolver=Resolver
	return true
end