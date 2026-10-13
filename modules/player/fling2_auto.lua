-- Recorrido automático de jugadores usando el flujo de Fling 2 eficiente.
return function(context)
	setfenv(1,context)

	local controller={Running=false,CurrentTarget=nil,Cycle=0,Cursor=0}

	local function validTarget(target)
		if not target or target==player or not target.Parent then return false end
		local character=target.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		return humanoid~=nil and humanoid.Health>0 and root~=nil
	end

	local function options()
		local result={}
		for _,target in ipairs(Fling2EfficientCore.Provider:GetTargetOptions()) do
			if target~=player then result[#result+1]=target end
		end
		table.sort(result,function(a,b) return a.UserId<b.UserId end)
		return result
	end

	local function nextTarget(self)
		local available=options()
		if #available==0 then return nil end
		for _,target in ipairs(available) do
			if target.UserId>self.Cursor and validTarget(target) then self.Cursor=target.UserId;return target end
		end
		for _,target in ipairs(available) do
			if validTarget(target) then self.Cursor=target.UserId;return target end
		end
		return nil
	end

	local function show(message)
		if UpdateFling2Panel then UpdateFling2Panel(message) end
	end

	function controller:Start()
		if self.Running then return true end
		self.Cursor=0
		local target=nextTarget(self)
		if not target then return false,isES and "No hay jugadores disponibles." or "No players are available." end
		if Fling2Core and Fling2Core.Running then Fling2Core:Stop() end
		if Fling2EfficientCore.Running then Fling2EfficientCore:Stop() end

		self.Running=true
		self.Cycle=self.Cycle+1
		self.CurrentTarget=target
		Fling2EfficientCore:SetTarget(target)
		Fling2EfficientCore:SetShortDisplacementEnabled(true)
		local ok,err=Fling2EfficientCore:Start()
		if not ok then
			self.Running=false
			self.CurrentTarget=nil
			return false,err
		end
		show((isES and "Objetivo automático: " or "Automatic target: ")..target.DisplayName)

		return true
	end

	function controller:OnReturned()
		if not self.Running then return end
		self.CurrentTarget=nextTarget(self)
		Fling2EfficientCore:SetTarget(self.CurrentTarget)
		self.RetryAt=os.clock()+.2
		show(self.CurrentTarget and ((isES and "Objetivo automático: " or "Automatic target: ")..self.CurrentTarget.DisplayName) or (isES and "Esperando jugadores…" or "Waiting for players…"))
	end
	function controller:CheckTarget()
		if not self.Running or validTarget(self.CurrentTarget) then return end
		if not self.CurrentTarget and os.clock()<(self.RetryAt or 0) then return end
		local core=Fling2EfficientCore
		core:DestroyFlinger();core:DestroyFrontFlip();core.ShortTravel=nil
		local c=player.Character;local root=c and c:FindFirstChild("HumanoidRootPart")
		if root then core:HoldShortHome(root,nil) end
		core.EfficientPhase="HOME";core.HomeUntil=os.clock()+core.ShortHomeInterval
		self:OnReturned()
	end

	function controller:Stop()
		local wasRunning=self.Running
		self.Running=false
		self.Cycle=self.Cycle+1
		self.CurrentTarget=nil
		if Fling2EfficientCore.Running or Fling2EfficientCore.Stopping then
			Fling2EfficientCore:Stop()
		end
		Fling2EfficientCore:SetTarget(nil)
		show()
		return wasRunning
	end

	function controller:ForceReturn()
		if self.Running or Fling2EfficientCore.Running then
			return false,isES and "Desactiva el fling automático antes de forzar el regreso." or "Disable automatic fling before forcing the return."
		end
		return Fling2EfficientCore:ForceReturn()
	end

	function controller:SkipMissing(target)
		if self.Running and self.CurrentTarget==target then
			self.CurrentTarget=nil
			self.RetryAt=0
			Fling2EfficientCore:SetTarget(nil)
		end
	end

	Fling2AutoController=controller
	return true
end
