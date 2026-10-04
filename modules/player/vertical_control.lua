-- Desplazamiento vertical anclado y persistente con emote Invisible.
return function(context)
	setfenv(1,context)
	local Core={Running=false,Offset=-5,Checkpoint=nil,SelectedEmoteId=nil,SelectedEmoteName=nil,Connection=nil,VisualConnection=nil,CharacterConnection=nil,CharacterAddedConnection=nil,EmoteClock=0,CameraAnchor=nil,SavedCameraType=nil,SavedCameraSubject=nil,Status=nil,LastAppliedCFrame=nil,VisualJoint=nil,VisualC0=nil,VisualC1=nil,SavedCollisions={},RespawnToken=0,RespawnVisibility=nil,RespawnVisibilityConnection=nil}
	local function rig()
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		return character,humanoid,root
	end
	local INVISIBLE_EMOTE_ID=131900540866459
	local INVISIBLE_EMOTE_NAME="Invisible"
	local function finite(value)
		value=tonumber(value)
		return value and value==value and math.abs(value)<math.huge and value or nil
	end
	function Core:IsRunning()return self.Running end
	function Core:GetOffset()return self.Offset end
	function Core:SetOffset(value)
		value=finite(value)
		if not value then return false,isES and"Escribe una ubicación vertical válida."or"Enter a valid vertical location."end
		self.Offset=math.clamp(value,-10,10)
		if self.Running then self:Apply()end
		return true,self.Offset
	end
	function Core:SetCharacterCollisions(disabled)
		local character=player.Character
		if disabled then
			table.clear(self.SavedCollisions)
			if character then
				for _,part in ipairs(character:GetDescendants())do
					if part:IsA("BasePart")then self.SavedCollisions[part]=part.CanCollide;part.CanCollide=false end
				end
			end
		else
			for part,canCollide in pairs(self.SavedCollisions)do
				if part.Parent then part.CanCollide=canCollide end
			end
			table.clear(self.SavedCollisions)
		end
	end
	function Core:HideRespawnTransition(character)
		self:ShowRespawnTransition()
		local saved={}
		self.RespawnVisibility=saved
		local function hide(object)
			if object:IsA("BasePart")and saved[object]==nil then
				saved[object]=object.LocalTransparencyModifier
				object.LocalTransparencyModifier=1
			end
		end
		for _,object in ipairs(character:GetDescendants())do hide(object)end
		self.RespawnVisibilityConnection=character.DescendantAdded:Connect(hide)
	end
	function Core:ShowRespawnTransition()
		if self.RespawnVisibilityConnection then self.RespawnVisibilityConnection:Disconnect();self.RespawnVisibilityConnection=nil end
		for object,value in pairs(self.RespawnVisibility or {})do
			if object and object.Parent then pcall(function()object.LocalTransparencyModifier=value end)end
		end
		self.RespawnVisibility=nil
	end
	function Core:IsAnchorHolding(root)
		return (root and root.Anchored)
			or (AnchorCore and (AnchorCore.AnclaEnabled or AnchorCore.TestEnabled))
			or (AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy))
	end
	function Core:RestoreVisualOffset()
		local joint=self.VisualJoint
		if joint and joint.Parent then
			if self.VisualC0 then joint.C0=self.VisualC0 end
			if self.VisualC1 then joint.C1=self.VisualC1 end
		end
		self.VisualJoint=nil
		self.VisualC0=nil
		self.VisualC1=nil
	end
	function Core:ApplyVisualOffset(character,root)
		local joint=self.VisualJoint
		if not joint or not joint.Parent or (joint.Part0~=root and joint.Part1~=root) then
			self:RestoreVisualOffset()
			joint=root:FindFirstChild("RootJoint")
			if not joint or not joint:IsA("Motor6D") then
				joint=nil
				for _,candidate in ipairs(character:GetDescendants())do
					if candidate:IsA("Motor6D")and candidate.Name=="RootJoint"and(candidate.Part0==root or candidate.Part1==root)then joint=candidate;break end
				end
			end
			if not joint then
			for _,candidate in ipairs(character:GetDescendants())do
				if candidate:IsA("Motor6D")and(candidate.Part0==root or candidate.Part1==root)then joint=candidate;break end
			end
			end
			if not joint then return false end
			self.VisualJoint=joint
			self.VisualC0=joint.C0
			self.VisualC1=joint.C1
		end
		-- Convertimos el desplazamiento mundial a espacio local del HRP antes
		-- de la rotacion base del RootJoint. En R15, aplicar el shift despues
		-- de C0 puede transformar una bajada vertical en movimiento lateral.
		local localOffset=root.CFrame:VectorToObjectSpace(Vector3.new(0,self.Offset,0))
		local shift=CFrame.new(localOffset)
		if joint.Part0==root then
			joint.C0=shift*self.VisualC0
		else
			joint.C1=shift*self.VisualC1
		end
		return true
	end
	function Core:ReapplyVisualOffset()
		if not self.Running then return end
		local character,humanoid,root=rig()
		if not character or not humanoid or humanoid.Health<=0 or not root then return end
		if self:IsAnchorHolding(root) then self:ApplyVisualOffset(character,root) end
	end
	function Core:Apply(dt)
		if not self.Running or not self.Checkpoint then return false end
		local character,humanoid,root=rig()
		if not humanoid or humanoid.Health<=0 or not root then return false end
		if humanoid.Sit then humanoid.Sit=false end
		for _,part in ipairs(character:GetDescendants())do if part:IsA("BasePart")then if self.SavedCollisions[part]==nil then self.SavedCollisions[part]=part.CanCollide end;part.CanCollide=false end end

		if self:IsAnchorHolding(root) then
			-- El HRP y la burbuja permanecen arriba; solo el cuerpo visual baja.
			self:ApplyVisualOffset(character,root)
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
			self.LastAppliedCFrame=root.CFrame
		else
			self:RestoreVisualOffset()
			local currentFrame=root.CFrame
			local direction=humanoid.MoveDirection
			local step=direction.Magnitude>.01 and direction.Unit*humanoid.WalkSpeed*math.min(tonumber(dt)or 0,.1)or Vector3.zero
			local targetY=self.Checkpoint.Position.Y+self.Offset
			root.CFrame=CFrame.new(currentFrame.Position.X+step.X,targetY,currentFrame.Position.Z+step.Z)*currentFrame.Rotation
			self.LastAppliedCFrame=root.CFrame
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
		end

		if self.CameraAnchor and self.CameraAnchor.Parent then
			self.CameraAnchor.CFrame=CFrame.new(root.Position.X,self.Checkpoint.Position.Y+2,root.Position.Z)*root.CFrame.Rotation
		end
		return true
	end
	function Core:LockCamera()
		local camera=workspace.CurrentCamera
		if not camera or not self.Checkpoint then return end
		self.SavedCameraType=camera.CameraType
		self.SavedCameraSubject=camera.CameraSubject
		local anchor=Instance.new("Part")
		anchor.Name="VerticalCameraAnchor"
		anchor.Size=Vector3.new(1,1,1)
		anchor.Transparency=1
		anchor.Anchored=true
		anchor.CanCollide=false
		anchor.CanTouch=false
		anchor.CanQuery=false
		anchor.CFrame=self.Checkpoint*CFrame.new(0,2,0)
		anchor.Parent=workspace
		self.CameraAnchor=anchor
		camera.CameraType=Enum.CameraType.Custom
		camera.CameraSubject=anchor
	end
	function Core:RestoreCamera()
		local camera=workspace.CurrentCamera
		if camera then
			camera.CameraType=self.SavedCameraType or Enum.CameraType.Custom
			if self.SavedCameraSubject and self.SavedCameraSubject.Parent then
				camera.CameraSubject=self.SavedCameraSubject
			else
				local _,humanoid=rig()
				if humanoid then camera.CameraSubject=humanoid end
			end
		end
		if self.CameraAnchor then self.CameraAnchor:Destroy();self.CameraAnchor=nil end
		self.SavedCameraType=nil;self.SavedCameraSubject=nil
	end
	function Core:CaptureSelectedEmote()
		self.SelectedEmoteId=INVISIBLE_EMOTE_ID
		self.SelectedEmoteName=INVISIBLE_EMOTE_NAME
		return true
	end
	function Core:IsInvisibleEmotePlaying()
		local track=currentAnimTrack
		if not track or not track.IsPlaying then return false end
		local animation=track.Animation
		local animationId=animation and tostring(animation.AnimationId):match("%d+")
		return animationId==tostring(INVISIBLE_EMOTE_ID)
	end
	function Core:RestoreSelectedEmote()
		self:CaptureSelectedEmote()
		if not self.SelectedEmoteId or type(PlayEmote)~="function" then return false end
		local ok=pcall(function()
			PlayEmote(self.SelectedEmoteId,self.SelectedEmoteName or tostring(self.SelectedEmoteId),true)
		end)
		return ok
	end
	function Core:Start(value)
		if self.Running then return true end
		local valid,message=self:SetOffset(value)
		if not valid then return false,message end
		local _,humanoid,root=rig()
		if not humanoid or humanoid.Health<=0 or not root then return false,isES and"Tu personaje no esta disponible."or"Your character is unavailable."end
		if not AnchorCore then return false,isES and"El controlador de Ancla no está disponible."or"Anchor controller is unavailable."end
		if AutoAnchorCore and AutoAnchorCore.Busy then return false,isES and"El Ancla automática está ocupada."or"Automatic Anchor is busy."end
		if AutoAnchorCore and AutoAnchorCore.Mode then AutoAnchorCore:Stop() end
		if AnchorCore.TestEnabled then AnchorCore:SetTest(false) end
		if AnchorCore.AnclaEnabled then AnchorCore:SetAncla(false) end
		AnchorCore:SetAntiSeat(false)
		AnchorCore:SetHeartbeat(false)
		self.Checkpoint=root.CFrame
		self:SetCharacterCollisions(true)
		self.Running=true
		local anchored,anchorMessage=AnchorCore:SetAncla(true)
		if not anchored then self.Running=false;self:SetCharacterCollisions(false);return false,anchorMessage end
		AnchorCore.Checkpoint=self.Checkpoint
		AnchorCore:SetAntiSeat(true)
		AnchorCore:SetHeartbeat(true)
		self:LockCamera()
		self:CaptureSelectedEmote()
		self:RestoreSelectedEmote()
		self:Apply()
		self.EmoteClock=0
		self.Connection=RunService.Heartbeat:Connect(function(dt)
			if not self.Running then return end
			if not self:Apply(dt)then return end
			self.EmoteClock=self.EmoteClock+(tonumber(dt)or 0)
			if self.EmoteClock>=0.75 then
				self.EmoteClock=0
				if not self:IsInvisibleEmotePlaying() then self:RestoreSelectedEmote() end
			end
		end)
		self.VisualConnection=RunService.RenderStepped:Connect(function()
			self:ReapplyVisualOffset()
		end)
		self.Status=isES and"Desplazamiento vertical activo."or"Vertical displacement active."
		return true,self.Status
	end
	function Core:Stop(restore)
		local wasRunning=self.Running
		self.Running=false
		if self.Connection then self.Connection:Disconnect();self.Connection=nil end
		if self.VisualConnection then self.VisualConnection:Disconnect();self.VisualConnection=nil end
		self:RestoreVisualOffset()
		self:ShowRespawnTransition()
		self:SetCharacterCollisions(false)
		self:RestoreCamera()
		if type(StopEmote)=="function" then pcall(function() StopEmote(false) end) end
		if AnchorCore then
			AnchorCore:SetHeartbeat(false)
			AnchorCore:SetAntiSeat(false)
			if AnchorCore.AnclaEnabled then AnchorCore:SetAncla(false) end
		end
		local checkpoint=self.Checkpoint
		self.Checkpoint=nil
		self.LastAppliedCFrame=nil
		if restore~=false and checkpoint then
			local _,humanoid,root=rig()
			if root then
				root.CFrame=checkpoint
				root.AssemblyLinearVelocity=Vector3.zero
				root.AssemblyAngularVelocity=Vector3.zero
			end
			if humanoid then humanoid.AutoRotate=true end
		end
		self.Status=isES and"Personaje restaurado."or"Character restored."
		return wasRunning,self.Status
	end
	function Core:Destroy()
		self:Stop(true)
		if self.CharacterConnection then self.CharacterConnection:Disconnect();self.CharacterConnection=nil end
		if self.CharacterAddedConnection then self.CharacterAddedConnection:Disconnect();self.CharacterAddedConnection=nil end
	end
	Core.CharacterConnection=player.CharacterRemoving:Connect(function()
		if not Core.Running then return end
		Core.RespawnToken+=1
		Core:ShowRespawnTransition()
		Core:RestoreVisualOffset()
		table.clear(Core.SavedCollisions)
		Core.Status=isES and"Reiniciando desplazamiento vertical..."or"Restarting vertical displacement..."
	end)
	Core.CharacterAddedConnection=player.CharacterAdded:Connect(function(character)
		if not Core.Running then return end
		Core.RespawnToken+=1
		local token=Core.RespawnToken
		Core:HideRespawnTransition(character)
		task.spawn(function()
			local root=character:WaitForChild("HumanoidRootPart",8)
			local humanoid=character:WaitForChild("Humanoid",8)
			if not Core.Running or token~=Core.RespawnToken or not root or not humanoid or not Core.Checkpoint then Core:ShowRespawnTransition();return end

			-- El HRP vuelve primero al punto superior original. Nunca aplicamos el
			-- offset físico al spawn: los studs se aplican al cuerpo visual después.
			root.CFrame=Core.Checkpoint
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
			if AnchorCore then
				if AnchorCore.AnclaEnabled then AnchorCore:SetAncla(false) end
				AnchorCore:SetAntiSeat(false)
				AnchorCore:SetHeartbeat(false)
				root.CFrame=Core.Checkpoint
				local anchored=AnchorCore:SetAncla(true)
				if anchored then
					AnchorCore.Checkpoint=Core.Checkpoint
					AnchorCore:SetAntiSeat(true)
					AnchorCore:SetHeartbeat(true)
				end
			end
			Core:SetCharacterCollisions(true)
			humanoid:WaitForChild("Animator",4)
			character:WaitForChild("LowerTorso",4)

			-- Esperamos a que Roblox termine de construir el RootJoint.
			local jointDeadline=os.clock()+2
			repeat
				if not Core.Running or token~=Core.RespawnToken then Core:ShowRespawnTransition();return end
				root.CFrame=Core.Checkpoint
				Core:RestoreVisualOffset()
				Core:ApplyVisualOffset(character,root)
				task.wait(.05)
			until Core.VisualJoint or os.clock()>=jointDeadline

			Core.EmoteClock=0
			local nextEmoteAttempt=0
			local emoteRebased=false
			local stabilizeUntil=os.clock()+1.35
			while Core.Running and token==Core.RespawnToken and os.clock()<stabilizeUntil do
				root.CFrame=Core.Checkpoint
				root.AssemblyLinearVelocity=Vector3.zero
				root.AssemblyAngularVelocity=Vector3.zero
				if not Core:IsInvisibleEmotePlaying()and os.clock()>=nextEmoteAttempt then
					Core:RestoreSelectedEmote()
					nextEmoteAttempt=os.clock()+.35
				elseif Core:IsInvisibleEmotePlaying()and not emoteRebased then
					-- La pista ya tomó control del rig: capturamos ahora el RootJoint
					-- definitivo y aplicamos nuevamente exactamente los studs guardados.
					Core:RestoreVisualOffset()
					Core:ApplyVisualOffset(character,root)
					emoteRebased=true
				end
				Core:ApplyVisualOffset(character,root)
				task.wait(.05)
			end
			if not Core.Running or token~=Core.RespawnToken then Core:ShowRespawnTransition();return end
			Core:ApplyVisualOffset(character,root)
			Core:ShowRespawnTransition()
			Core.Status=isES and"Desplazamiento vertical restaurado."or"Vertical displacement restored."
			if UpdateVerticalControlPanel then UpdateVerticalControlPanel(Core.Status) end
		end)
	end)
	VerticalControlController=Core
	return true
end
