-- Vigilancia aislada del retorno posterior a Fling 2.
-- No modifica el recorrido ni la fuerza: solamente observa el HRP despues de Stop().
return function(context)
	setfenv(1, context)

	local Guard = {Generation=0, Connection=nil, CharacterConnection=nil, Watching=false, Destroyed=false}
	local WATCH_SECONDS, GRACE_SECONDS = 6, 0.18
	local REQUIRED_SAMPLES, SPEED_LIMIT, STEP_LIMIT = 2, 145, 18
	local SEVERE_SPEED, SEVERE_STEP, MAX_RETURNS = 420, 65, 2

	local function disconnectWatch()
		if Guard.Connection then Guard.Connection:Disconnect(); Guard.Connection=nil end
		Guard.Watching=false
	end
	function Guard:Cancel()
		self.Generation+=1
		disconnectWatch()
	end
	local function getRoot()
		local character=player.Character
		return character and character:FindFirstChild("HumanoidRootPart")
	end
	function Guard:Arm(core)
		if self.Destroyed then return end
		self:Cancel()
		if not core or core.Running or core.Stopping then return end
		local root=getRoot()
		if not root then return end
		local generation=self.Generation
		local startedAt=os.clock()
		local lastAt=startedAt
		local lastPosition=root.Position
		local suspiciousSamples,returns=0,0
		local returning=false
		self.Watching=true
		self.Connection=RunService.Heartbeat:Connect(function()
			if generation~=self.Generation then return end
			if core.Running or core.Stopping then self:Cancel(); return end
			local now=os.clock()
			if now-startedAt>WATCH_SECONDS then self:Cancel(); return end
			local currentRoot=getRoot()
			if currentRoot~=root or not root.Parent then self:Cancel(); return end
			local position=root.Position
			local dt=math.max(now-lastAt,1/240)
			local displacement=(position-lastPosition).Magnitude
			local measuredSpeed=displacement/dt
			local physicsSpeed=root.AssemblyLinearVelocity.Magnitude
			lastAt,lastPosition=now,position
			if returning or now-startedAt<GRACE_SECONDS or root.Anchored then
				suspiciousSamples=0
				return
			end
			local severe=displacement>=SEVERE_STEP or measuredSpeed>=SEVERE_SPEED
			local suspicious=severe or displacement>=STEP_LIMIT
				or measuredSpeed>=SPEED_LIMIT or physicsSpeed>=SPEED_LIMIT
			if suspicious then suspiciousSamples+=1 else suspiciousSamples=0 end
			if not severe and suspiciousSamples<REQUIRED_SAMPLES then return end
			if returns>=MAX_RETURNS then self:Cancel(); return end
			returning=true
			returns+=1
			suspiciousSamples=0
			task.spawn(function()
				if generation~=self.Generation or core.Running then returning=false; return end
				pcall(function() core:ForceReturn() end)
				if generation~=self.Generation then return end
				root=getRoot()
				if not root then self:Cancel(); return end
				lastPosition,lastAt=root.Position,os.clock()
				returning=false
			end)
		end)
	end
	local function attach(core)
		if not core or core._returnGuardAttached then return end
		core._returnGuardAttached=true
		local originalStart,originalStop=core.Start,core.Stop
		function core:Start(...)
			Guard:Cancel()
			return originalStart(self,...)
		end
		function core:Stop(...)
			local wasRunning=self.Running
			local results=table.pack(originalStop(self,...))
			if wasRunning and not self.Running and not self.Stopping then Guard:Arm(self) end
			return table.unpack(results,1,results.n)
		end
	end
	attach(Fling2Core)
	attach(Fling2EfficientCore)
	Guard.CharacterConnection=player.CharacterAdded:Connect(function() Guard:Cancel() end)
	function Guard:Destroy()
		self.Destroyed=true
		self:Cancel()
		if self.CharacterConnection then self.CharacterConnection:Disconnect(); self.CharacterConnection=nil end
	end
	FlingReturnGuard=Guard
	return true
end
