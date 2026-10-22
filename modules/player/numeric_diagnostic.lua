-- Read-only numeric monitoring. Synthetic invalid values exist only in a Lua table.
return function(context)
	setfenv(1,context)
	local core={Running=false,Lines={},LocalTest="No ejecutada."}
	NumericDiagnosticCore=core
	local function append(message)
		core.Lines[#core.Lines+1]=message
		if #core.Lines>100 then table.remove(core.Lines,1) end
	end
	function core:Classify(value)
		if type(value)~="number" then return "NOT_NUMBER" end
		if value~=value then return "NaN" end
		if value==math.huge or value==-math.huge then return "INFINITY" end
		return "FINITE"
	end
	function core:RunLocalTest()
		if not ExperimentalFlingCore:IsAuthorized() then return false,"Solo owners." end
		-- Never assign these values to an Instance, Vector3, CFrame or remote payload.
		local isolated={finite=900000000,nan=0/0,positiveInfinity=math.huge,negativeInfinity=-math.huge}
		local results={"LOCAL NUMERIC SELF-TEST | Lua data only; no engine physics writes"}
		for _,key in ipairs({"finite","nan","positiveInfinity","negativeInfinity"}) do
			results[#results+1]=key.."="..self:Classify(isolated[key])
		end
		self.LocalTest=table.concat(results,"\n")
		return true,self.LocalTest
	end
	function core:Sample()
		for _,p in ipairs({player,Players:GetPlayerByUserId(11773278300)}) do
			local character=p.Character
			local root=character and character:FindFirstChild("HumanoidRootPart")
			local signature={}
			if root then
				for _,property in ipairs({"Position","AssemblyLinearVelocity","AssemblyAngularVelocity"}) do
					local value=root[property]
					for _,axis in ipairs({"X","Y","Z"}) do
						local category=self:Classify(value[axis])
						if category~="FINITE" then signature[#signature+1]=property.."."..axis.."="..category end
					end
				end
				local ok,components=pcall(function()return {root.CFrame:GetComponents()}end)
				if ok then for index,value in ipairs(components) do
					local category=self:Classify(value)
					if category~="FINITE" then signature[#signature+1]="CFrame["..index.."]="..category end
				end end
				if #signature==0 then signature[1]="ALL_SAMPLED_VALUES_FINITE" end
			else signature[1]="HRP_UNAVAILABLE" end
			local text=table.concat(signature,"; ")
			local previous=self.Previous[p.UserId]
			if not previous or previous.Root~=root or previous.Signature~=text then
				self.Previous[p.UserId]={Root=root,Signature=text}
				append(string.format("t=%.3f %s UserId=%s %s",os.clock()-self.Started,p.Name,tostring(p.UserId),text))
			end
		end
	end
	function core:Start()
		if self.Running then return true end
		if not ExperimentalFlingCore:IsAuthorized() then return false,"Solo owners." end
		self.Lines={};self.Previous={};self.Started=os.clock();self.Running=true
		local ok,err=pcall(function()self:Sample()end)
		if not ok then self:Stop();append("START_ERROR="..tostring(err));return false,tostring(err)end
		local elapsed=0
		self.Connection=RunService.Heartbeat:Connect(function(dt)
			elapsed=elapsed+dt
			if elapsed<0.1 then return end
			elapsed=0
			local ok,err=pcall(function()self:Sample()end)
			if not ok then append("SAMPLE_ERROR="..tostring(err)) end
		end)
		return true
	end
	function core:Stop()
		self.Running=false
		if self.Connection then self.Connection:Disconnect();self.Connection=nil end
		self.Previous={}
	end
	function core:GetReport()
		return "NUMERIC OBSERVER V1 | local replicated observations; sampled, not exhaustive\nRunning="..tostring(self.Running)
			.."\n900 million is finite, not NaN. No invalid values are sent to physics.\n"..self.LocalTest.."\n"..table.concat(self.Lines,"\n")
	end
	function core:Destroy()self:Stop()end
	return true
end
