-- Independent bounded-contact experiment; no FAR/void phase and no permanent forces.
return function(context)
	setfenv(1,context)
	local Core={Running=false,Stopping=false,Target=nil,Checkpoint=nil,Phase="IDLE",Connection=nil,Serial=0}
	local function text(es,en) return isES and es or en end
	local function refresh(message) if UpdateExperimentalFlingPanel then UpdateExperimentalFlingPanel(message) end end
	local function parts(p)
		local c=p and p.Character
		local h=c and c:FindFirstChildOfClass("Humanoid")
		local r=c and c:FindFirstChild("HumanoidRootPart")
		if h and h.Health>0 and r then return h,r end
	end
	local function zero(root)
		root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
	end
	local function conflict()
		for _,name in ipairs({"Fling2Core","Fling2EfficientCore","Fling2AutoController","CustomFlingCore","ContactFlingController","CarFling","CarFlingXeno","CarFling2Delta","CarFling2Xeno","ObjectFling2Delta","ObjectFling2Xeno","MotoFlingCore","MotoFlingXenoCore","MobileAnchorCore","MobileAnchorV11Core","StaticPassThroughAnchorCore","VerticalControlController"}) do
			local c=context[name];if c and c.Running then return true end
		end
		return (AnchorCore and (AnchorCore.AnclaEnabled or AnchorCore.TestEnabled)) or (AutoAnchorCore and AutoAnchorCore.Mode)
	end
	function Core:SetTarget(target)
		if self.Running or self.Stopping then return false end
		if not target or target==player or not target:IsA("Player") then return false end
		self.Target=target;return true
	end
	function Core:Start()
		if self.Running then return true end
		if self.Stopping then return false,text("Espera la estabilización.","Wait for stabilization.") end
		if conflict() then return false,text("Desactiva otras anclas y flings primero.","Disable other anchors and flings first.") end
		local h,root=parts(player);local _,target=parts(self.Target)
		if not root or root.Anchored then return false,text("Tu personaje no está disponible o está anclado.","Your character is unavailable or anchored.") end
		if not target then return false,text("Selecciona un objetivo cargado.","Select a loaded target.") end
		self.Checkpoint=root.CFrame;self.LastCheckpoint=self.Checkpoint
		self.PreviousAutoRotate=h.AutoRotate;self.Humanoid=h;self.Root=root
		self.Running=true;self.Phase="SEPARATE";self.Deadline=0;self.Serial=self.Serial+1
		local floor=-400
		pcall(function() floor=workspace.FallenPartsDestroyHeight+30 end)
		self.Connection=RunService.Heartbeat:Connect(function()
			if not self.Running then return end
			local currentHumanoid,currentRoot=parts(player)
			local _,targetRoot=parts(self.Target)
			if not currentRoot or currentRoot~=self.Root or conflict() then self:Stop();return end
			local now=os.clock()
			if not targetRoot or targetRoot.Position.Y<floor then
				zero(currentRoot);currentRoot.CFrame=self.Checkpoint
				self.Phase="SEPARATE";self.Deadline=now+.1;return
			end
			local side=targetRoot.CFrame.RightVector
			local home=CFrame.new(targetRoot.Position+side*5+Vector3.new(0,1.5,0))*self.Checkpoint.Rotation
			if self.Phase=="SEPARATE" then
				zero(currentRoot);currentRoot.CFrame=home
				if now<self.Deadline then return end
				currentRoot.CFrame=CFrame.new(targetRoot.Position+side*1.5)*self.Checkpoint.Rotation
				local direction=targetRoot.Position-currentRoot.Position
				-- One bounded impulse per contact, not a sustained 900-million velocity.
				if direction.Magnitude>.001 then currentRoot:ApplyImpulse((direction.Unit*120+Vector3.new(0,35,0))*currentRoot.AssemblyMass) end
				self.Phase="CONTACT";self.Deadline=now+.12
			elseif now>=self.Deadline or currentRoot.AssemblyLinearVelocity.Magnitude>220 or (currentRoot.Position-targetRoot.Position).Magnitude>12 then
				zero(currentRoot);currentRoot.CFrame=home
				self.Phase="SEPARATE";self.Deadline=now+.1
			end
		end)
		refresh();return true
	end
	function Core:Stop()
		if self.Stopping or not self.Running then return false end
		self.Running=false;self.Stopping=true;self.Phase="IDLE";self.Serial=self.Serial+1
		if self.Connection then self.Connection:Disconnect();self.Connection=nil end
		local serial=self.Serial;local root=self.Root;local checkpoint=self.Checkpoint
		refresh()
		task.spawn(function()
			local anchored=root and root.Parent and root.Anchored
			if root and root.Parent then zero(root);root.CFrame=checkpoint;root.Anchored=true end
			local untilTime=os.clock()+2
			while serial==self.Serial and root and root.Parent and os.clock()<untilTime do
				zero(root);root.CFrame=checkpoint;RunService.Heartbeat:Wait()
			end
			if root and root.Parent then zero(root);root.Anchored=anchored end
			if self.Humanoid and self.Humanoid.Parent then
				self.Humanoid.AutoRotate=self.PreviousAutoRotate
				pcall(function() self.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
			end
			self.Stopping=false;self.Root=nil;refresh()
		end)
		return true
	end
	function Core:ForceReturn()
		if self.Running or self.Stopping then return false,text("Desactiva y espera la estabilización.","Disable and wait for stabilization.") end
		local _,root=parts(player)
		if not root or not self.LastCheckpoint then return false,text("No hay un regreso disponible.","No return checkpoint available.") end
		zero(root);root.CFrame=self.LastCheckpoint;zero(root);return true
	end
	ExperimentalFlingCore=Core
	return true
end
