-- Desplazamiento vertical experimental con emote aislado.
return function(context)
	setfenv(1,context)
	local Core={Running=false,Offset=-100,Checkpoint=nil,Track=nil,Animation=nil,Connection=nil,CharacterConnection=nil,Status=nil}
	local EMOTE_ID=110348711077449
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
		if not value then return false,isES and"Escribe una ubicaci�n vertical v�lida."or"Enter a valid vertical location."end
		self.Offset=value
		if self.Running then self:Apply()end
		return true,value
	end
	function Core:Apply()
		if not self.Running or not self.Checkpoint then return false end
		local _,humanoid,root=rig()
		if not humanoid or humanoid.Health<=0 or not root then return false end
		if humanoid.Sit then humanoid.Sit=false end
		root.AssemblyLinearVelocity=Vector3.zero
		root.AssemblyAngularVelocity=Vector3.zero
		root.CFrame=self.Checkpoint+Vector3.new(0,self.Offset,0)
		return true
	end
	function Core:PlayEmote()
		local _,humanoid=rig()
		if not humanoid then return false end
		local animator=humanoid:FindFirstChildOfClass("Animator")or humanoid:WaitForChild("Animator",2)
		if not animator then return false end
		local animation
		local okObjects,objects=pcall(function()return game:GetObjects("rbxassetid://"..EMOTE_ID)end)
		if okObjects and objects and #objects>0 then
			local source=objects[1]:IsA("Animation")and objects[1]or objects[1]:FindFirstChildWhichIsA("Animation",true)
			if source then animation=source:Clone()end
			for _,object in ipairs(objects)do pcall(function()object:Destroy()end)end
		end
		if not animation then animation=Instance.new("Animation");animation.AnimationId="rbxassetid://"..EMOTE_ID end
		animation.Name="VerticalControlEmote"
		local ok,track=pcall(function()return animator:LoadAnimation(animation)end)
		if not ok or not track then animation:Destroy();return false end
		track.Priority=Enum.AnimationPriority.Action4
		track.Looped=true
		track:Play(.12)
		self.Animation,self.Track=animation,track
		return true
	end
	function Core:Start(value)
		if self.Running then return true end
		local valid,message=self:SetOffset(value)
		if not valid then return false,message end
		local _,humanoid,root=rig()
		if not humanoid or humanoid.Health<=0 or not root then return false,isES and"Tu personaje no est� disponible."or"Your character is unavailable."end
		self.Checkpoint=root.CFrame
		self.Running=true
		self:PlayEmote()
		self:Apply()
		self.Connection=RunService.Heartbeat:Connect(function()
			if not self:Apply()then self:Stop(false)end
		end)
		self.Status=isES and"Desplazamiento vertical activo."or"Vertical displacement active."
		return true,self.Status
	end
	function Core:Stop(restore)
		local wasRunning=self.Running
		self.Running=false
		if self.Connection then self.Connection:Disconnect();self.Connection=nil end
		if self.Track then pcall(function()self.Track:Stop(.12)end);self.Track=nil end
		if self.Animation then self.Animation:Destroy();self.Animation=nil end
		local checkpoint=self.Checkpoint
		self.Checkpoint=nil
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
	function Core:Destroy()self:Stop(true);if self.CharacterConnection then self.CharacterConnection:Disconnect();self.CharacterConnection=nil end end
	Core.CharacterConnection=player.CharacterRemoving:Connect(function()if Core.Running then Core:Stop(false)end end)
	VerticalControlController=Core
	return true
end
