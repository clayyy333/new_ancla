-- Editor corporal experimental mediante offsets Motor6D.
return function(context)
	setfenv(1,context)
	local C={Active=false,Original={},Joints={},Values={RightArmOpen=0,RightArmLift=0,RightForearm=0,LeftArmOpen=0,LeftArmLift=0,LeftForearm=0,LegsOpen=0,RightLegLift=0,LeftLegLift=0,Lean=0}}
	local connection
	local limits={RightArmOpen={-70,100},RightArmLift={-80,140},RightForearm={0,145},LeftArmOpen={-70,100},LeftArmLift={-80,140},LeftForearm={0,145},LegsOpen={-45,60},RightLegLift={-60,100},LeftLegLift={-60,100},Lean={-60,60}}
	local names={RightShoulder={"RightShoulder","Right Shoulder"},LeftShoulder={"LeftShoulder","Left Shoulder"},RightElbow={"RightElbow"},LeftElbow={"LeftElbow"},RightHip={"RightHip","Right Hip"},LeftHip={"LeftHip","Left Hip"},Waist={"Waist","RootJoint","Root Joint"}}
	local function findMotor(character,candidates)
		for _,name in ipairs(candidates)do local motor=character:FindFirstChild(name,true);if motor and motor:IsA("Motor6D")then return motor end end
	end
	function C:_Restore()
		for motor,c0 in pairs(self.Original)do if motor and motor.Parent then pcall(function()motor.C0=c0 end)end end
		table.clear(self.Original);table.clear(self.Joints)
	end
	function C:_Resolve()
		self:_Restore()
		local character=player.Character;if not character then return false end
		for key,candidates in pairs(names)do local motor=findMotor(character,candidates);self.Joints[key]=motor;if motor then self.Original[motor]=motor.C0 end end
		return self.Joints.RightShoulder~=nil or self.Joints.LeftShoulder~=nil
	end
	function C:_Set(key,offset)
		local motor=self.Joints[key];if motor and motor.Parent then motor.C0=self.Original[motor]*offset end
	end
	function C:Apply()
		if not self.Active then return false end
		local v=self.Values
		self:_Set("RightShoulder",CFrame.Angles(math.rad(v.RightArmLift),0,math.rad(-v.RightArmOpen)))
		self:_Set("LeftShoulder",CFrame.Angles(math.rad(v.LeftArmLift),0,math.rad(v.LeftArmOpen)))
		self:_Set("RightElbow",CFrame.Angles(math.rad(-v.RightForearm),0,0))
		self:_Set("LeftElbow",CFrame.Angles(math.rad(-v.LeftForearm),0,0))
		self:_Set("RightHip",CFrame.Angles(math.rad(v.RightLegLift),0,math.rad(-v.LegsOpen)))
		self:_Set("LeftHip",CFrame.Angles(math.rad(v.LeftLegLift),0,math.rad(v.LegsOpen)))
		self:_Set("Waist",CFrame.Angles(math.rad(v.Lean),0,0))
		return true
	end
	function C:Start()
		if self.Active then return true end
		if not self:_Resolve()then return false,isES and"No se encontraron articulaciones compatibles."or"No compatible joints found."end
		self.Active=true;self:Apply();return true,isES and"Control corporal activo."or"Body control active."
	end
	function C:Stop()self.Active=false;self:_Restore();return true,isES and"Control corporal desactivado."or"Body control disabled."end
	function C:IsActive()return self.Active end
	function C:Get(key)return self.Values[key]or 0 end
	function C:Change(key,delta)
		local range=limits[key];if not range then return false end
		self.Values[key]=math.clamp((self.Values[key]or 0)+(tonumber(delta)or 0),range[1],range[2])
		if self.Active then self:Apply()end
		return true
	end
	function C:Reset()
		for key in pairs(self.Values)do self.Values[key]=0 end
		if self.Active then self:Apply()end
		return true
	end
	connection=player.CharacterAdded:Connect(function()local was=C.Active;C.Active=false;C:_Restore();if was then task.wait(.5);C:_Resolve();C.Active=true;C:Apply();if UpdateBodyControlPanel then UpdateBodyControlPanel()end end end)
	function C:Destroy()self:Stop();if connection then connection:Disconnect()end end
	BodyPoseController=C
	return true
end