-- Ancla con movimiento: corrige impulsos sin anclar ni cambiar el estado del Humanoid.
return function(context)
	setfenv(1,context)
	local Core={Enabled=false,SafeCFrame=nil,LastPosition=nil,LastVelocity=nil,LastRoot=nil,HoldUntil=0,Corrections=0}
	local beforePhysics,afterPhysics
	local MAX_SPEED=75
	local MAX_ANGULAR=12
	local MAX_STEP=3.5
	local HOLD_TIME=0.22
	local function rig()
		local character=player.Character
		return character and character:FindFirstChild("HumanoidRootPart"),character and character:FindFirstChildOfClass("Humanoid")
	end
	local function reset(self)
		self.SafeCFrame=nil;self.LastPosition=nil;self.LastVelocity=nil;self.LastRoot=nil;self.HoldUntil=0
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
	function Core:Check(dt,advance)
		if not self.Enabled then return end
		if conflicting() then self:SetEnabled(false);return end
		local root,humanoid=rig()
		if not root or not humanoid or humanoid.Health<=0 then reset(self);return end
		if root~=self.LastRoot then
			reset(self);self.LastRoot=root;+
	end
	function Core:SetEnabled;self.LastVelocity=root.AssemblyLinearVelocity;self.SafeCFrame=root.CFrame
			return
		end
		if root.Anchored or humanoid.Sit or humanoid.SeatPart or intentional() then
			self.SafeCFrame=root.CFrame;+
	end
	function Core:SetEnabled;self.LastVelocity=root.AssemblyLinearVelocity;self.HoldUntil=0
			return
		end
		local position=root.Position
		local velocity=root.AssemblyLinearVelocity
		local angular=root.AssemblyAngularVelocity
		local step=(position-(self.LastPosition or position)).Magnitude
		local speed=velocity.Magnitude
		local change=velocity-(self.LastVelocity or velocity)
		local horizontalChange=Vector3.new(change.X,0,change.Z).Magnitude
		local horizontalSpeed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
		local impulse=speed>MAX_SPEED or angular.Magnitude>MAX_ANGULAR or (step>MAX_STEP and speed>35) or (horizontalSpeed>45 and horizontalChange>35)
		local now=os.clock()
		if impulse and self.SafeCFrame then self.HoldUntil=math.max(self.HoldUntil,now+HOLD_TIME) end
		if now<self.HoldUntil and self.SafeCFrame then
			humanoid.PlatformStand=false
			if humanoid:GetState()==Enum.HumanoidStateType.FallingDown or humanoid:GetState()==Enum.HumanoidStateType.Ragdoll then
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
			local walking=Vector3.new(humanoid.MoveDirection.X,0,humanoid.MoveDirection.Z)
			if advance and walking.Magnitude>0.01 then
				local move=walking.Unit*math.min(humanoid.WalkSpeed,28)*math.min(dt,1/30)
				local params=RaycastParams.new()
				params.FilterType=Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances={humanoid.Parent}
				if not workspace:Raycast(self.SafeCFrame.Position,move,params) then
					self.SafeCFrame=self.SafeCFrame+move
				end
			end
			root.CFrame=self.SafeCFrame
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
			self.LastPosition=self.SafeCFrame.Position
			self.LastVelocity=Vector3.zero
			if impulse then self.Corrections=self.Corrections+1 end
			return
		end
		-- Un salto sin velocidad física se considera TP intencional.
		if (step>MAX_STEP and speed<=35) or (humanoid.FloorMaterial~=Enum.Material.Air and speed<=MAX_SPEED and angular.Magnitude<=MAX_ANGULAR) then
			self.SafeCFrame=root.CFrame
		end
		+
	end
	function Core:SetEnabled
	end
	function Core:SetEnabled(enabled)
		enabled=enabled==true
		if enabled==self.Enabled then return true end
		if enabled and conflicting() then return false,isES and "Desactiva primero Ancla o Ancla automática." or "Disable Anchor or Automatic Anchor first." end
		self.Enabled=enabled;reset(self)
		if beforePhysics then beforePhysics:Disconnect();beforePhysics=nil end
		if afterPhysics then afterPhysics:Disconnect();afterPhysics=nil end
		if enabled then
			beforePhysics=RunService.PreSimulation:Connect(function(dt) self:Check(dt,true) end)
			afterPhysics=RunService.PostSimulation:Connect(function(dt) self:Check(dt,false) end)
		end
		refresh()
		return true
	end
	function Core:Destroy() self:SetEnabled(false) end
	MovingAnchorController=Core
	return true
end