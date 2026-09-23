return function(context)
	setfenv(1, context)
	local C={Target=nil,Distance=3,Height=0,Angle=0,SelfAngle=0,Tilt=0,HeightInitialized=false,HasPositioned=false,Maintaining=false,SoloMaintaining=false,SoloBaseCFrame=nil,SavedAutoRotate=nil,SavedCollisions={}}
	local connections={}
	local function rig(p)
		local character=p and p.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		local root=character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or humanoid.Health<=0 or not root then return nil,nil end
		return humanoid,root
	end
	local function bodyAnchor(p,root)
		local character=p and p.Character
		return character and(character:FindFirstChild("LowerTorso")or character:FindFirstChild("Torso")or character:FindFirstChild("UpperTorso"))or root
	end
	function C:GetTargetOptions()
		local result={}
		for _,candidate in ipairs(Players:GetPlayers())do if candidate~=player then result[#result+1]=candidate end end
		table.sort(result,function(a,b)return a.DisplayName:lower()<b.DisplayName:lower()end)
		return result
	end
	function C:SetTarget(target)
		if typeof(target)~="Instance"or not target:IsA("Player")or target==player then return false end
		if self.Maintaining or self.SoloMaintaining then self:Release()end
		self.Target=target;self.HasPositioned=false;self.HeightInitialized=false
		return true
	end
	function C:GetTarget()return self.Target end
	function C:GetDistance()return self.Distance end
	function C:GetHeight()return self.Height end
	function C:GetAngle()return self.Angle end
	function C:GetSelfAngle()return self.SelfAngle end
	function C:GetTilt()return self.Tilt end
	function C:IsMaintaining()return self.Maintaining or self.SoloMaintaining end
	function C:SetDistance(v)self.Distance=math.round(math.clamp(tonumber(v)or self.Distance,-15,15)*10)/10 end
	function C:SetHeight(v)self.Height=math.round(math.clamp(tonumber(v)or self.Height,-8,8)*10)/10;self.HeightInitialized=true end
	function C:SetAngle(v)self.Angle=((tonumber(v)or self.Angle)+180)%360-180 end
	function C:SetSelfAngle(v)self.SelfAngle=((tonumber(v)or self.SelfAngle)+180)%360-180 end
	function C:SetTilt(v)self.Tilt=math.clamp(math.round(tonumber(v)or self.Tilt),-60,60)end
	function C:_DisableCollisions()
		local character=player.Character
		if not character then return end
		for _,part in ipairs(character:GetDescendants())do
			if part:IsA("BasePart")then
				if self.SavedCollisions[part]==nil then self.SavedCollisions[part]=part.CanCollide end
				part.CanCollide=false
			end
		end
	end
	function C:_RestoreCollisions()
		for part,original in pairs(self.SavedCollisions)do
			if part and part.Parent then pcall(function()part.CanCollide=original end)end
		end
		table.clear(self.SavedCollisions)
	end
	function C:_Apply()
		local humanoid,root=rig(player);local _,targetRoot=rig(self.Target)
		if not humanoid or not root or not targetRoot then return false end
		local anchor=bodyAnchor(self.Target,targetRoot)
		if humanoid.Sit then humanoid.Sit=false end
		self:_DisableCollisions()
		local forward=Vector3.new(targetRoot.CFrame.LookVector.X,0,targetRoot.CFrame.LookVector.Z)
		if forward.Magnitude<0.001 then forward=Vector3.new(0,0,-1)else forward=forward.Unit end
		local anchorPosition=anchor.Position
		local bodyFrame=CFrame.lookAt(anchorPosition,anchorPosition+forward)
		local orbit=bodyFrame*CFrame.Angles(0,math.rad(self.Angle),0)
		local position=(orbit*CFrame.new(0,self.Height,-self.Distance)).Position
		local look=Vector3.new(targetRoot.Position.X,position.Y,targetRoot.Position.Z)
		if (look-position).Magnitude<0.001 then look=position-forward end
		root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
		root.CFrame=CFrame.lookAt(position,look)*CFrame.Angles(0,math.rad(self.SelfAngle),0)*CFrame.Angles(math.rad(self.Tilt),0,0)
		return true
	end
	function C:_ApplySolo()
		local humanoid,root=rig(player)
		if not humanoid or not root or not self.SoloBaseCFrame then return false end
		if humanoid.Sit then humanoid.Sit=false end
		self:_DisableCollisions()
		local basePosition=self.SoloBaseCFrame.Position
		local forward=Vector3.new(self.SoloBaseCFrame.LookVector.X,0,self.SoloBaseCFrame.LookVector.Z)
		if forward.Magnitude<0.001 then forward=Vector3.new(0,0,-1)else forward=forward.Unit end
		local baseFrame=CFrame.lookAt(basePosition,basePosition+forward)
		local orbit=baseFrame*CFrame.Angles(0,math.rad(self.Angle),0)
		local position=(orbit*CFrame.new(0,self.Height,-self.Distance)).Position
		local look=Vector3.new(basePosition.X,position.Y,basePosition.Z)
		if (look-position).Magnitude<0.001 then look=position-forward end
		root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
		root.CFrame=CFrame.lookAt(position,look)*CFrame.Angles(0,math.rad(self.SelfAngle),0)*CFrame.Angles(math.rad(self.Tilt),0,0)
		return true
	end
	function C:Position()
		if self.SoloMaintaining then self:Release()end
		if not self.Target or self.Target==player then return false,isES and"Selecciona otro jugador."or"Select another player."end
		local humanoid,root=rig(player);local _,targetRoot=rig(self.Target)
		if not root then return false,isES and"Tu personaje no está disponible."or"Your character is unavailable."end
		if not targetRoot then return false,isES and"El personaje objetivo no está disponible."or"The target character is unavailable."end
		local anchor=bodyAnchor(self.Target,targetRoot)
		if not self.HeightInitialized then self.Height=math.clamp(root.Position.Y-anchor.Position.Y,-8,8);self.HeightInitialized=true end
		if self.SavedAutoRotate==nil then self.SavedAutoRotate=humanoid.AutoRotate end
		humanoid.AutoRotate=false;self.Maintaining=true;self.HasPositioned=true;self:_DisableCollisions();self:_Apply()
		return true,isES and"Ubicación mantenida."or"Location maintained."
	end
	function C:PositionSolo()
		local humanoid,root=rig(player)
		if not humanoid or not root then return false,isES and"Tu personaje no esta disponible."or"Your character is unavailable."end
		if self.Maintaining then self:Release()end
		if self.SavedAutoRotate==nil then self.SavedAutoRotate=humanoid.AutoRotate end
		self.SoloBaseCFrame=root.CFrame;self.SoloMaintaining=true;self.HasPositioned=true
		humanoid.AutoRotate=false;self:_DisableCollisions();self:_ApplySolo()
		return true,isES and"Ubicacion individual mantenida."or"Solo location maintained."
	end
	function C:Release()
		self.Maintaining=false;self.SoloMaintaining=false;self.SoloBaseCFrame=nil
		self:_RestoreCollisions()
		local humanoid=rig(player)
		if humanoid and self.SavedAutoRotate~=nil then humanoid.AutoRotate=self.SavedAutoRotate end
		self.SavedAutoRotate=nil
		return true,isES and"Ubicación liberada."or"Location released."
	end
	local function changed(self)
		if self.SoloMaintaining then self:_ApplySolo()elseif self.Maintaining then self:_Apply()end
		return true
	end
	function C:AdjustDistance(v)self:SetDistance(self.Distance+v);return changed(self)end
	function C:AdjustHeight(v)self:SetHeight(self.Height+v);return changed(self)end
	function C:AdjustAngle(v)self:SetAngle(self.Angle+v);return changed(self)end
	function C:AdjustSelfAngle(v)self:SetSelfAngle(self.SelfAngle+v);return changed(self)end
	function C:AdjustTilt(v)self:SetTilt(self.Tilt+v);return changed(self)end
	function C:Reset()self.Distance,self.Height,self.Angle,self.SelfAngle,self.Tilt,self.HeightInitialized=3,0,0,0,0,false;if self.SoloMaintaining then self:_ApplySolo()elseif self.Maintaining then local _,root=rig(player);local _,targetRoot=rig(self.Target);if root and targetRoot then local anchor=bodyAnchor(self.Target,targetRoot);self.Height=math.clamp(root.Position.Y-anchor.Position.Y,-8,8);self.HeightInitialized=true end;self:_Apply()end;return true end
	connections[#connections+1]=RunService.Heartbeat:Connect(function()local ok=true;if C.SoloMaintaining then ok=C:_ApplySolo()elseif C.Maintaining then ok=C:_Apply()end;if not ok then C:Release();if UpdateCouplesPanel then UpdateCouplesPanel(isES and"No se pudo mantener la ubicación."or"Could not maintain location.")end end end)
	connections[#connections+1]=Players.PlayerRemoving:Connect(function(p)if C.Target==p then if C.Maintaining then C:Release()end;C.Target=nil;C.HasPositioned=false;if UpdateCouplesPanel then UpdateCouplesPanel(isES and"El jugador salió."or"The player left.")end end end)
	connections[#connections+1]=player.CharacterAdded:Connect(function()C.Maintaining=false;C.SoloMaintaining=false;C.SoloBaseCFrame=nil;C.SavedAutoRotate=nil;table.clear(C.SavedCollisions);C.HasPositioned=false end)
	function C:Destroy()self:Release();for _,connection in ipairs(connections)do connection:Disconnect()end;table.clear(connections)end
	CouplesPositionController=C
	return true
end