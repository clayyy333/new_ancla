-- Ancla con movimiento: corrige impulsos sin anclar ni cambiar el estado del Humanoid.
return function(context)
	setfenv(1,context)
	local Core={Enabled=false,SafeCFrame=nil,LastPosition=nil,LastVelocity=nil,LastAngularVelocity=nil,LastRoot=nil,CushionUntil=0,Corrections=0}
	local beforePhysics,afterPhysics
	local function rig()
		local character=player.Character
		return character and character:FindFirstChild("HumanoidRootPart"),character and character:FindFirstChildOfClass("Humanoid")
	end
	local function reset(self)
		self.SafeCFrame=nil;self.LastPosition=nil;self.LastVelocity=nil;self.LastAngularVelocity=nil;self.LastRoot=nil;self.CushionUntil=0
	end
	local function refresh()
		if UpdateMovingAnchorPanel then UpdateMovingAnchorPanel() end
	end
	local function conflicting()
		return (AnchorCore and AnchorCore.AnclaEnabled) or (AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy))
	end
	local function intentional()
		return (FlightController and FlightController:IsFlying())
			or (Fling2Core and (Fling2Core.Running or Fling2Core.Stopping))
			or (Fling2EfficientCore and (Fling2EfficientCore.Running or Fling2EfficientCore.Stopping))
			or (CouplesPositionController and CouplesPositionController:IsMaintaining())
	end
	function Core:Check()
		if not self.Enabled then return end
		if conflicting() then self:SetEnabled(false);return end
		local root,humanoid=rig()
		if not root or not humanoid or humanoid.Health<=0 then reset(self);return end
		local position=root.Position
		local velocity=root.AssemblyLinearVelocity
		local angular=root.AssemblyAngularVelocity
		if root~=self.LastRoot then
			reset(self);self.LastRoot=root
			self.SafeCFrame=root.CFrame
			self.LastPosition=position;self.LastVelocity=velocity;self.LastAngularVelocity=angular
			return
		end
		if root.Anchored or humanoid.Sit or humanoid.SeatPart or intentional() then
			self.CushionUntil=0
			self.SafeCFrame=root.CFrame
			self.LastPosition=position;self.LastVelocity=velocity;self.LastAngularVelocity=angular
			return
		end
		local step=(position-(self.LastPosition or position)).Magnitude
		local change=velocity-(self.LastVelocity or velocity)
		local horizontal=Vector3.new(velocity.X,0,velocity.Z)
		local horizontalChange=Vector3.new(change.X,0,change.Z).Magnitude
		local angularChange=(angular-(self.LastAngularVelocity or angular)).Magnitude
		local teleport=step>12 and velocity.Magnitude<40
		local hit=not teleport and (horizontal.Magnitude>55 or math.abs(velocity.Y)>100
			or angular.Magnitude>16 or (horizontalChange>35 and horizontal.Magnitude>30)
			or (math.abs(change.Y)>80 and math.abs(velocity.Y)>65)
			or (angularChange>10 and angular.Magnitude>8))
		local now=os.clock()
		if teleport then self.CushionUntil=0 end
		if hit then self.CushionUntil=now+0.45 end
		if now<self.CushionUntil then
			-- Absorbe la fuerza sin fijar CFrame: el jugador puede seguir caminando.
			local maxHorizontal=math.max(humanoid.WalkSpeed*1.3,22)
			local limitedHorizontal=horizontal.Magnitude>maxHorizontal and horizontal.Unit*maxHorizontal or horizontal
			local limitedVertical=math.clamp(velocity.Y,-18,25)
			root.AssemblyLinearVelocity=limitedHorizontal+Vector3.new(0,limitedVertical,0)
			if angular.Magnitude>2.5 then root.AssemblyAngularVelocity=angular.Unit*2.5 end
			if hit then self.Corrections=self.Corrections+1 end
			velocity=root.AssemblyLinearVelocity
			angular=root.AssemblyAngularVelocity
		elseif teleport or (step<=6 and velocity.Magnitude<45 and angular.Magnitude<8) then
			self.SafeCFrame=root.CFrame
		end
		self.LastPosition=position
		self.LastVelocity=velocity
		self.LastAngularVelocity=angular
	end
	function Core:SetEnabled(enabled)
		enabled=enabled==true
		if enabled==self.Enabled then return true end
		if enabled and conflicting() then return false,isES and "Desactiva primero Ancla o Ancla automática." or "Disable Anchor or Automatic Anchor first." end
		self.Enabled=enabled;reset(self)
		if beforePhysics then beforePhysics:Disconnect();beforePhysics=nil end
		if afterPhysics then afterPhysics:Disconnect();afterPhysics=nil end
		if enabled then
			beforePhysics=RunService.PreSimulation:Connect(function() self:Check() end)
			afterPhysics=RunService.PostSimulation:Connect(function() self:Check() end)
		end
		refresh()
		return true
	end
	function Core:Destroy() self:SetEnabled(false) end
	MovingAnchorController=Core
	return true
end