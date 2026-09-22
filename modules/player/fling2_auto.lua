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
			if validTarget(target) then result[#result+1]=target end
		end
		return result
	end

	local function nextTarget(self)
		local available=options()
		if #available==0 then return nil end
		self.Cursor=(self.Cursor%#available)+1
		return available[self.Cursor]
	end

	local function show(message)
		if UpdateFling2Panel then UpdateFling2Panel(message) end
	end

	function controller:Start()
		if self.Running then return true end
		local target=nextTarget(self)
		if not target then return false,isES and "No hay jugadores disponibles." or "No players are available." end
		if Fling2Core and Fling2Core.Running then Fling2Core:Stop() end
		if Fling2EfficientCore.Running then Fling2EfficientCore:Stop() end

		self.Running=true
		self.Cycle=self.Cycle+1
		local cycle=self.Cycle
		self.CurrentTarget=target
		Fling2EfficientCore:SetTarget(target)
		local ok,err=Fling2EfficientCore:Start()
		if not ok then
			self.Running=false
			self.CurrentTarget=nil
			return false,err
		end
		show((isES and "Objetivo automático: " or "Automatic target: ")..target.DisplayName)

		task.spawn(function()
			while self.Running and self.Cycle==cycle do
				local started=os.clock()
				while self.Running and self.Cycle==cycle and os.clock()-started<3 do
					if not validTarget(self.CurrentTarget) then break end
					task.wait(0.1)
				end
				if not self.Running or self.Cycle~=cycle then break end

				local following=nextTarget(self)
				if following then
					self.CurrentTarget=following
					Fling2EfficientCore:SetTarget(following)
					if not Fling2EfficientCore.Running then
						local restarted,restartErr=Fling2EfficientCore:Start()
						if not restarted then
							self.Running=false
							show(restartErr)
							break
						end
					end
					show((isES and "Objetivo automático: " or "Automatic target: ")..following.DisplayName)
				else
					-- No esperar tres segundos si no hay un objetivo válido.
					task.wait(0.1)
				end
			end
		end)
		return true
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
			Fling2EfficientCore:SetTarget(nil)
		end
	end

	Fling2AutoController=controller
	return true
end