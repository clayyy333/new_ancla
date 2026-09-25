-- Desplazamiento vertical persistente compatible con el emote seleccionado.
return function(context)
	setfenv(1,context)
	local Core={Running=false,Offset=-100,Checkpoint=nil,SelectedEmoteId=nil,SelectedEmoteName=nil,Connection=nil,CharacterConnection=nil,CharacterAddedConnection=nil,EmoteClock=0,CameraAnchor=nil,SavedCameraType=nil,SavedCameraSubject=nil,Status=nil,LastAppliedCFrame=nil,VisualJoint=nil,VisualC0=nil,VisualC1=nil,SavedCollisions={}}
	local function rig()
		local character=player.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		return character,humanoid,root
	end
	local function finite(value)
		value=tonumber(value)
		return value and value==value and math.abs(value)<math.huge and value or nil
	end
	function Core:IsRunning()return self.Running end
	function Core:GetOffset()return self.Offset end
	function Core:SetOffset(value)
		value=finite(value)
		if not value then return false,isES and"Escribe una ubicacion vertical valida."or"Enter a valid vertical location."end
		self.Offset=value
		if self.Running then self:Apply()end
		return true,value
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
			for _,candidate in ipairs(character:GetDescendants())do
				if candidate:IsA("Motor6D")and(candidate.Part0==root or candidate.Part1==root)then joint=candidate;break end
			end
			if not joint then return false end
			self.VisualJoint=joint
			self.VisualC0=joint.C0
			self.VisualC1=joint.C1
		end
		local shift=CFrame.new(0,self.Offset,0)
		if joint.Part0==root then
			joint.C0=self.VisualC0*shift
		else
			joint.C1=self.VisualC1*shift:Inverse()
		end
		return true
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
		local selected=_genv().lastVexroEmote
		if type(selected)=="table" and selected.id then
			self.SelectedEmoteId=selected.id
			self.SelectedEmoteName=selected.name or tostring(selected.id)
			return true
		end
		return self.SelectedEmoteId~=nil
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
		if InverseVerticalController and InverseVerticalController:IsRunning() then InverseVerticalController:Stop(true) end
		local valid,message=self:SetOffset(value)
		if not valid then return false,message end
		local _,humanoid,root=rig()
		if not humanoid or humanoid.Health<=0 or not root then return false,isES and"Tu personaje no esta disponible."or"Your character is unavailable."end
		self.Checkpoint=root.CFrame
		self:SetCharacterCollisions(true)
		self.Running=true
		self:LockCamera()
		self:CaptureSelectedEmote()
		self:Apply()
		self.EmoteClock=0
		self.Connection=RunService.Heartbeat:Connect(function(dt)
			if not self.Running then return end
			if not self:Apply(dt)then return end
			self.EmoteClock=self.EmoteClock+(tonumber(dt)or 0)
			if self.EmoteClock>=0.15 then
				self.EmoteClock=0
				self:CaptureSelectedEmote()
			end
		end)
		self.Status=isES and"Desplazamiento vertical activo."or"Vertical displacement active."
		return true,self.Status
	end
	function Core:Stop(restore)
		local wasRunning=self.Running
		self.Running=false
		if self.Connection then self.Connection:Disconnect();self.Connection=nil end
		self:RestoreVisualOffset()
		self:SetCharacterCollisions(false)
		self:RestoreCamera()
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
		Core:RestoreVisualOffset()
		table.clear(Core.SavedCollisions)
		Core.Status=isES and"Reiniciando desplazamiento vertical..."or"Restarting vertical displacement..."
	end)
	Core.CharacterAddedConnection=player.CharacterAdded:Connect(function(character)
		if not Core.Running then return end
		task.spawn(function()
			local root=character:WaitForChild("HumanoidRootPart",8)
			if not Core.Running or not root or not Core.Checkpoint then return end
			local restored=Core.LastAppliedCFrame or (Core.Checkpoint*CFrame.new(0,Core.Offset,0))
			root.CFrame=Core:IsAnchorHolding(root) and Core.Checkpoint or restored
			root.AssemblyLinearVelocity=Vector3.zero
			root.AssemblyAngularVelocity=Vector3.zero
			local humanoid=character:WaitForChild("Humanoid",8)
			if not Core.Running or not humanoid then return end
			humanoid:WaitForChild("Animator",4)
			Core:SetCharacterCollisions(true)
			Core:Apply(0)
			for _=1,5 do
				if not Core.Running then return end
				if Core:RestoreSelectedEmote() then break end
				task.wait(.35)
			end
			Core:Apply(0)
			Core.Status=isES and"Desplazamiento vertical restaurado."or"Vertical displacement restored."
			if UpdateVerticalControlPanel then UpdateVerticalControlPanel(Core.Status) end
		end)
	end)
	VerticalControlController=Core
	return true
end
