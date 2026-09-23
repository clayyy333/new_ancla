-- Resolución opcional de objetivos lejanos para flings con objetivo.
return function(context)
	setfenv(1,context)
	local Workspace=game:GetService("Workspace")
	local Resolver={Timeout=1}

	function Resolver:GetRoot(target)
		local character=target and target.Character
		if not character then return nil end
		local humanoid=character:FindFirstChildOfClass("Humanoid")
		local root=character:FindFirstChild("HumanoidRootPart")
		return humanoid and humanoid.Health>0 and root or nil
	end

	function Resolver:Resolve(target,timeout)
		local root=self:GetRoot(target)
		if root then return root end
		if not target or not target.Parent then return nil end
		local deadline=os.clock()+(tonumber(timeout) or self.Timeout)
		repeat
			local character=target.Character or Workspace:FindFirstChild(target.Name)
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