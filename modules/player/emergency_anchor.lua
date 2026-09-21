-- Protección pasiva contra impulsos físicos inesperados; sin GUI propia.
return function(context)
	setfenv(1, context)

	local Core = {Enabled=false, SafeCFrame=nil, LastRoot=nil, LastPosition=nil, LastVelocity=nil, LastAngularVelocity=nil, PendingTeleportAt=nil}
	local heartbeat
	local SPEED_LIMIT = 125
	local ANGULAR_LIMIT = 18
	local STEP_LIMIT = 3
	local TELEPORT_STEP = 12
	local STABLE_SPEED = 55
	local STABLE_ANGULAR = 8
	local TELEPORT_SETTLE_TIME = 0.18

	local function intentionalMovement()
		return (AnchorCore and AnchorCore.AnclaEnabled)
			or (AutoAnchorCore and AutoAnchorCore.Mode)
			or (Fling2Core and (Fling2Core.Running or Fling2Core.Stopping))
			or (Fling2EfficientCore and (Fling2EfficientCore.Running or Fling2EfficientCore.Stopping))
			or (CouplesPositionController and CouplesPositionController:IsMaintaining())
			or (FlightController and FlightController:IsFlying())
	end

	function Core:Reset()
		self.SafeCFrame=nil
		self.LastRoot=nil
		self.LastPosition=nil
		self.LastVelocity=nil
		self.LastAngularVelocity=nil
		self.PendingTeleportAt=nil
	end

	function Core:Check()
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if not root or not humanoid or humanoid.Health<=0 then self:Reset(); return end
		local now=os.clock()
		local position=root.Position
		local velocity=root.AssemblyLinearVelocity
		local angularVelocity=root.AssemblyAngularVelocity
		if root~=self.LastRoot then
			self.LastRoot=root
			self.LastPosition=position
			self.LastVelocity=velocity
			self.LastAngularVelocity=angularVelocity
			self.SafeCFrame=root.CFrame
			return
		end
		local step=(position-(self.LastPosition or position)).Magnitude
		local velocityDelta=(velocity-(self.LastVelocity or velocity)).Magnitude
		local angularDelta=(angularVelocity-(self.LastAngularVelocity or angularVelocity)).Magnitude
		self.LastPosition=position
		self.LastVelocity=velocity
		self.LastAngularVelocity=angularVelocity
		if intentionalMovement() or root.Anchored or humanoid.Sit or humanoid.SeatPart then
			self.SafeCFrame=root.CFrame
			self.PendingTeleportAt=nil
			return
		end
		local speed=velocity.Magnitude
		local angular=angularVelocity.Magnitude
		local jumped=step>TELEPORT_STEP
		-- La variación de velocidad permite reaccionar antes de recorrer varios studs.
		local suddenImpulse=speed>85 and velocityDelta>65
		local suddenSpin=angular>12 and angularDelta>9 and speed>35
		local physicsImpulse=suddenImpulse or suddenSpin
			or (not jumped and speed>SPEED_LIMIT and (step>STEP_LIMIT or angular>ANGULAR_LIMIT))
		if physicsImpulse and self.SafeCFrame then
			local checkpoint=self.SafeCFrame
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
			root.CFrame=checkpoint
			if AnchorCore then
				local anchored=AnchorCore:SetAncla(true)
				if anchored then
					AnchorCore:SetAntiSeat(true)
					AnchorCore:SetHeartbeat(true)
				end
			end
			self.LastPosition=checkpoint.Position
			self.LastVelocity=Vector3.zero
			self.LastAngularVelocity=Vector3.zero
			self.PendingTeleportAt=nil
			return
		end
		if jumped then
			-- Un salto de posición sin impulso se considera TP; no desactiva el detector.
			self.PendingTeleportAt=now
			return
		end
		if self.PendingTeleportAt then
			-- Conservar el punto previo brevemente por si el impulso llega tras el TP.
			if now-self.PendingTeleportAt<TELEPORT_SETTLE_TIME then return end
			self.PendingTeleportAt=nil
		end
		if speed<STABLE_SPEED and angular<STABLE_ANGULAR and step<STEP_LIMIT then
			self.SafeCFrame=root.CFrame
		end
	end

	function Core:SetEnabled(enabled)
		enabled=enabled==true
		if self.Enabled==enabled then return true end
		self.Enabled=enabled
		self:Reset()
		if heartbeat then heartbeat:Disconnect(); heartbeat=nil end
		if enabled then heartbeat=RunService.Heartbeat:Connect(function() self:Check() end) end
		return true
	end

	function Core:Destroy()
		self:SetEnabled(false)
	end

	EmergencyAnchorController=Core
	Core:SetEnabled(Settings.emergencyAnchor==true)
	return true
end