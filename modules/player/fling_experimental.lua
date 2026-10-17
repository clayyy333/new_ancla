-- Independent sustained rotating-contact experiment. No FAR/void phase.
return function(context)
	setfenv(1,context)
	local Core={Running=false,Stopping=false,Target=nil,Checkpoint=nil,Phase="IDLE",Connection=nil,Serial=0}
	local CONFIG={Speed=900000000,Spin=60,ContactTime=.20,ReleaseTime=.08,Radius=.65,Height=.6,OrbitSpeed=32,Separation=5}
	function Core:ClearForce()
		if self.Force then self.Force:Destroy();self.Force=nil end
	end
	function Core:EnsureForce(root)
		if self.Force and self.Force.Parent==root then return end
		self:ClearForce()
		local force=Instance.new("BodyVelocity")
		force.Name="ExperimentalContactForce";force.MaxForce=Vector3.new(math.huge,math.huge,math.huge);force.P=1250
		force.Velocity=Vector3.zero;force.Parent=root;self.Force=force
	end
	local owners={[11739864999]="psychoo778",[11743514302]="ksablanca0",[11747901934]="psycho777oo",[11797966007]="psychoop77"}
	function Core:IsAuthorized()
		return owners[player.UserId]~=nil and owners[player.UserId]==string.lower(player.Name)
	end
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
		if not self:IsAuthorized() then return false,text("Prueba exclusiva para owners.","Owner-only experiment.") end
		if self.Running then return true end
		if self.Stopping then return false,text("Espera la estabilización.","Wait for stabilization.") end
		if conflict() then return false,text("Desactiva otras anclas y flings primero.","Disable other anchors and flings first.") end
		local h,root=parts(player);local _,target=parts(self.Target)
		if not root or root.Anchored then return false,text("Tu personaje no está disponible o está anclado.","Your character is unavailable or anchored.") end
		if not target then return false,text("Selecciona un objetivo cargado.","Select a loaded target.") end
		self.Checkpoint=root.CFrame;self.LastCheckpoint=self.Checkpoint
		self.PreviousAutoRotate=h.AutoRotate;self.Humanoid=h;self.Root=root
		self:ClearForce();self.Angle=0
		self.Running=true;self.Phase="SEPARATE";self.Deadline=0;self.Serial=self.Serial+1
		local floor=-400
		pcall(function() floor=workspace.FallenPartsDestroyHeight+30 end)
		self.Connection=RunService.Heartbeat:Connect(function(dt)
			if not self.Running then return end
			local ok,err=xpcall(function()
			local currentHumanoid,currentRoot=parts(player)
			local _,targetRoot=parts(self.Target)
			if not currentRoot or currentRoot~=self.Root or conflict() then self:Stop();return end
			local now=os.clock()
			if not targetRoot or targetRoot.Position.Y<floor then
				self:ClearForce()
				zero(currentRoot);currentRoot.CFrame=self.Checkpoint
				self.Phase="SEPARATE";self.Deadline=now+.1;return
			end
			local side=targetRoot.CFrame.RightVector
			local home=CFrame.new(targetRoot.Position+side*CONFIG.Separation+Vector3.new(0,1.5,0))*self.Checkpoint.Rotation
			if self.Phase=="SEPARATE" then
				self:ClearForce()
				zero(currentRoot);currentRoot.CFrame=home
				if now<self.Deadline then return end
				self.Phase="CONTACT";self.Deadline=now+CONFIG.ContactTime
			end
			if now>=self.Deadline or currentRoot.Position.Y<floor then
				self:ClearForce()
				zero(currentRoot);currentRoot.CFrame=home
				self.Phase="SEPARATE";self.Deadline=now+CONFIG.ReleaseTime
				return
			end
			-- Follow the live target throughout contact, not a one-off impulse.
			self.Angle=(self.Angle+CONFIG.OrbitSpeed*math.min(dt or 1/60,.05))%(math.pi*2)
			local radial=Vector3.new(math.cos(self.Angle),0,math.sin(self.Angle))
			local vertical=math.sin(self.Angle*2)
			currentRoot.CFrame=CFrame.new(targetRoot.Position+radial*CONFIG.Radius+Vector3.new(0,vertical*CONFIG.Height,0))*self.Checkpoint.Rotation
			self:EnsureForce(currentRoot)
			local velocity=(-radial+Vector3.new(0,vertical,0))*CONFIG.Speed
			self.Force.Velocity=velocity
			currentRoot.AssemblyLinearVelocity=velocity
			currentRoot.AssemblyAngularVelocity=Vector3.new(CONFIG.Spin,CONFIG.Spin,CONFIG.Spin)
			end,debug.traceback)
			if not ok then self:Stop();refresh(text("Error del experimento: ","Experiment error: ")..tostring(err)) end
		end)
		refresh();return true
	end
	function Core:Stop()
		if self.Stopping or not self.Running then return false end
		self.Running=false;self.Stopping=true;self.Phase="IDLE";self.Serial=self.Serial+1
		if self.Connection then self.Connection:Disconnect();self.Connection=nil end
		self:ClearForce()
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
