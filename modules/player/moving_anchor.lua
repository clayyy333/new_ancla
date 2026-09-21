-- Ancla con movimiento: corrige impulsos sin anclar ni cambiar el estado del Humanoid.
return function(context)
	setfenv(1,context)
	local Core={Enabled=false,SafeCFrame=nil,LastPosition=nil,LastVelocity=nil,LastAngularVelocity=nil,LastRoot=nil,Corrections=0}
	local beforePhysics,afterPhysics
	local function rig()
		local character=player.Character
		return character and character:FindFirstChild("HumanoidRootPart"),character and character:FindFirstChildOfClass("Humanoid")
	end
	local function reset(self)
		self.SafeCFrame=nil;self.LastPosition=nil;self.LastVelocity=nil;self.LastAngularVelocity=nil;self.LastRoot=nil
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
			self.SafeCFrame=root.CFrame
			self.LastPosition=position;self.LastVelocity=velocity;self.LastAngularVelocity=angular
			return
		end
		local step=(position-(self.LastPosition or position)).Magnitude
		local change=velocity-(self.LastVelocity or velocity)
		local angularChange=(angular-(self.LastAngularVelocity or angular)).Magnitude
		local hit=velocity.Magnitude>90 or (change.Magnitude>70 and velocity.Magnitude>55)
			or (angular.Magnitude>16 and angularChange>10)
		if hit then
			-- Rebote breve: nunca bloquea el movimiento durante varios frames.
			local horizontal=Vector3.new(change.X,0,change.Z)
			local rebound=horizontal.Magnitude>1 and -horizontal.Unit*math.min(horizontal.Magnitude*0.14,12) or Vector3.zero
			root.AssemblyLinearVelocity=rebound+Vector3.new(0,velocity.Y>0 and 7 or 2,0)
			root.AssemblyAngularVelocity=angular*0.1
			if step>6 and self.SafeCFrame then root.CFrame=self.SafeCFrame end
			self.Corrections=self.Corrections+1
			self.LastPosition=root.Position
			self.LastVelocity=root.AssemblyLinearVelocity
			self.LastAngularVelocity=root.AssemblyAngularVelocity
			return
		end
		if step<=6 and velocity.Magnitude<45 and angular.Magnitude<8 then
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