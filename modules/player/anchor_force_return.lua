-- Regreso manual al checkpoint. No modifica los modos de Ancla existentes.
return function(context)
	setfenv(1,context)
	local Core={Busy=false,Generation=0}
	local function checkpoint()
		if not AnchorCore then return nil end
		if AnchorCore.TestEnabled and AnchorCore.TestCheckpoint then return AnchorCore.TestCheckpoint end
		if AnchorCore.AnclaEnabled and AnchorCore.Checkpoint then return AnchorCore.Checkpoint end
		return nil
	end
	local function enforce(target)
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if not character or not root then return end
		pcall(function() character:PivotTo(target) end)
		root.CFrame=target
		for _,part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.AssemblyLinearVelocity=Vector3.zero
				part.AssemblyAngularVelocity=Vector3.zero
				part.Velocity=Vector3.zero
				part.RotVelocity=Vector3.zero
			end
		end
	end
	function Core:Force(duration)
		local target=checkpoint()
		if not target then return false,isES and "Activa primero Ancla o Ancla test." or "Enable Anchor or Test Anchor first." end
		self.Generation+=1
		local generation=self.Generation
		self.Busy=true
		enforce(target)
		task.spawn(function()
			local connections={}
			local function bind(signal)
				if signal then connections[#connections+1]=signal:Connect(function()
					if Core.Generation==generation then enforce(target) end
				end) end
			end
			bind(RunService.Stepped)
			bind(RunService.Heartbeat)
			bind(RunService.RenderStepped)
			local ok,signal=pcall(function() return RunService.PreSimulation end)
			if ok then bind(signal) end
			ok,signal=pcall(function() return RunService.PostSimulation end)
			if ok then bind(signal) end
			local deadline=os.clock()+(tonumber(duration) or 2)
			while Core.Generation==generation and os.clock()<deadline do task.wait() end
			for _,connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
			if Core.Generation==generation then
				enforce(target)
				Core.Busy=false
				if UpdateAnchorPanel then UpdateAnchorPanel(isES and "Regreso forzado completado." or "Forced return completed.") end
			end
		end)
		return true,isES and "Forzando regreso al checkpoint..." or "Forcing return to checkpoint..."
	end
	function Core:Destroy()
		self.Generation+=1
		self.Busy=false
	end
	AnchorForceReturn=Core
	return true
end