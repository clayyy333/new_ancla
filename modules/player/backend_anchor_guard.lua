-- Vigilancia cooperativa silenciosa entre clientes del mismo servidor.
return function(context)
	setfenv(1,context)
	local Config=BackendAnchorConfig or {}
	local Guard={Running=false,Connected=false,Generation=0,SessionToken=nil}
	local targetStates={}
	local requestFn

	local function isMetroLife()
		return Config.Enabled==true
			and game.GameId==Config.GameId
			and game.PlaceId==Config.PlaceId
	end

	local function resolveRequest()
		local environment=_genv and _genv() or {}
		local candidates={
			environment.request,
			environment.http_request,
			environment.httprequest,
			environment.syn and environment.syn.request,
			environment.http and environment.http.request,
		}
		for _,candidate in ipairs(candidates) do
			if type(candidate)=="function" then return candidate end
		end
		return nil
	end

	local function jsonDecode(body)
		if type(body)~="string" or body=="" then return {} end
		local ok,value=pcall(function() return HttpService:JSONDecode(body) end)
		return ok and type(value)=="table" and value or nil
	end

	local function call(method,path,body,token)
		if not requestFn then return nil,"request_unavailable" end
		local headers={
			["Accept"]="application/json",
			["Content-Type"]="application/json",
			["X-Client-Key"]=Config.ClientKey,
		}
		if token then headers.Authorization="Bearer "..token end
		local options={
			Url=Config.BaseUrl..path,
			Method=method,
			Headers=headers,
			Timeout=8,
		}
		if body~=nil then options.Body=HttpService:JSONEncode(body) end
		local ok,response=pcall(requestFn,options)
		if not ok or type(response)~="table" then return nil,"request_failed" end
		local status=tonumber(response.StatusCode or response.Status or response.status_code) or 0
		local decoded=jsonDecode(response.Body or response.body or "")
		if status<200 or status>=300 then return nil,"http_"..tostring(status),status end
		return decoded or {},nil,status
	end

	local function anchorState()
		if not AnchorCore then return false,"" end
		if AnchorCore.TestEnabled and AnchorCore.TestCheckpoint then return true,"test" end
		if AnchorCore.AnclaEnabled and AnchorCore.Checkpoint then
			local automatic=AutoAnchorCore and AutoAnchorCore.Mode
			return true,automatic and ("automatic_"..tostring(automatic)) or "normal"
		end
		return false,""
	end

	local function executorName()
		local environment=_genv and _genv() or {}
		local identify=environment.identifyexecutor or environment.getexecutorname
		if type(identify)~="function" then return "" end
		local ok,name=pcall(identify)
		return ok and tostring(name):sub(1,60) or ""
	end

	local function startSession()
		local response=call("POST","/api/v1/sessions/start",{
			user_id=player.UserId,
			username=player.Name,
			display_name=player.DisplayName,
			game_id=game.GameId,
			place_id=game.PlaceId,
			job_id=game.JobId,
			game_name="Metro Life",
			executor=executorName(),
			script_version="anchor-guard-1",
		})
		if not response or response.anchor_guard_enabled~=true or type(response.session_token)~="string" then
			return false
		end
		Guard.SessionToken=response.session_token
		Guard.Connected=true
		return true
	end

	local function heartbeat(anchored,mode)
		local response,_,status=call("POST","/api/v1/sessions/heartbeat",{
			anchored=anchored,
			anchor_mode=mode,
		},Guard.SessionToken)
		if status==401 or status==403 then
			Guard.Connected=false
			Guard.SessionToken=nil
		end
		return response~=nil
	end

	local function playerRoot(userId)
		local target=Players:GetPlayerByUserId(userId)
		local character=target and target.Character
		return character and character:FindFirstChild("HumanoidRootPart")
	end

	local function report(targetUserId,distance)
		call("POST","/api/v1/anchor/observe",{
			target_user_id=targetUserId,
			distance=distance,
		},Guard.SessionToken)
	end

	local function inspectTargets()
		local response=call("GET","/api/v1/anchor/targets",nil,Guard.SessionToken)
		if not response or type(response.targets)~="table" then return end
		local timestamp=os.clock()
		local present={}
		for _,target in ipairs(response.targets) do
			local userId=tonumber(target.user_id)
			if userId and userId~=player.UserId then
				present[userId]=true
				local root=playerRoot(userId)
				if root then
					local state=targetStates[userId]
					if not state then
						targetStates[userId]={
							Baseline=root.Position,
							ArmedAt=timestamp+1.5,
							Strikes=0,
							LastReport=0,
						}
					elseif timestamp>=state.ArmedAt then
						local distance=(root.Position-state.Baseline).Magnitude
						if distance>=4 then
							state.Strikes+=1
							if state.Strikes>=2 and timestamp-state.LastReport>=3 then
								state.LastReport=timestamp
								state.Strikes=0
								task.spawn(report,userId,distance)
							end
						else
							state.Strikes=0
							if distance<1.5 then
								state.Baseline=state.Baseline:Lerp(root.Position,0.15)
							end
						end
					end
				end
			end
		end
		for userId in pairs(targetStates) do
			if not present[userId] then targetStates[userId]=nil end
		end
	end

	local function acknowledge(commandId,result)
		call("POST","/api/v1/anchor/commands/"..commandId.."/ack",{
			result=result,
		},Guard.SessionToken)
	end

	local function executeCommands()
		local response=call("GET","/api/v1/anchor/commands",nil,Guard.SessionToken)
		if not response or type(response.commands)~="table" then return end
		for _,command in ipairs(response.commands) do
			if type(command.id)=="string" and command.type=="force_local_checkpoint_return" then
				local anchored=anchorState()
				if not anchored then
					task.spawn(acknowledge,command.id,"anchor_disabled")
				elseif AnchorForceReturn then
					local ok,started=pcall(function()
						return AnchorForceReturn:Force(2,true)
					end)
					task.spawn(acknowledge,command.id,(ok and started) and "returned" or "failed")
				else
					task.spawn(acknowledge,command.id,"failed")
				end
			end
		end
	end

	function Guard:Start()
		if self.Running or not isMetroLife() then return false end
		if type(Config.ClientKey)~="string" or Config.ClientKey=="" then return false end
		requestFn=resolveRequest()
		if not requestFn then return false end
		self.Generation+=1
		local generation=self.Generation
		self.Running=true
		task.spawn(function()
			local retryAt=0
			local heartbeatAt=0
			local targetsAt=0
			local commandsAt=0
			local lastAnchored,lastMode=nil,nil
			while Guard.Running and Guard.Generation==generation do
				local timestamp=os.clock()
				if not Guard.Connected then
					if timestamp>=retryAt then
						retryAt=timestamp+15
						startSession()
					end
				else
					local anchored,mode=anchorState()
					if timestamp>=heartbeatAt or anchored~=lastAnchored or mode~=lastMode then
						heartbeatAt=timestamp+(tonumber(Config.HeartbeatSeconds) or 30)
						lastAnchored,lastMode=anchored,mode
						heartbeat(anchored,mode)
					end
					if Guard.Connected and timestamp>=targetsAt then
						targetsAt=timestamp+(tonumber(Config.TargetPollSeconds) or 2.5)
						inspectTargets()
					end
					if Guard.Connected and anchored and timestamp>=commandsAt then
						commandsAt=timestamp+(tonumber(Config.CommandPollSeconds) or 1)
						executeCommands()
					end
				end
				task.wait(0.25)
			end
		end)
		return true
	end

	function Guard:Destroy()
		if not self.Running then return end
		self.Running=false
		self.Generation+=1
		local token=self.SessionToken
		self.SessionToken=nil
		self.Connected=false
		table.clear(targetStates)
		if token and requestFn then
			task.spawn(function() call("POST","/api/v1/sessions/end",nil,token) end)
		end
	end

	BackendAnchorGuard=Guard
	task.spawn(function() Guard:Start() end)
	return true
end
