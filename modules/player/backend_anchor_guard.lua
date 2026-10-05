-- Vigilancia cooperativa silenciosa entre clientes del mismo servidor.
return function(context)
	setfenv(1,context)
	local Config=BackendAnchorConfig or {}
	local LocalizationService=game:GetService("LocalizationService")
	local Guard={Running=false,Connected=false,AnchorGuardEnabled=false,Generation=0,SessionToken=nil}
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
		if not AnchorCore then return false,"",nil end
		if AnchorCore.TestEnabled and AnchorCore.TestCheckpoint then
			return true,"test",AnchorCore.TestCheckpoint.Position
		end
		if AnchorCore.AnclaEnabled and AnchorCore.Checkpoint then
			local automatic=AutoAnchorCore and AutoAnchorCore.Mode
			return true,automatic and ("automatic_"..tostring(automatic)) or "normal",AnchorCore.Checkpoint.Position
		end
		return false,"",nil
	end

	local function executorName()
		local environment=_genv and _genv() or {}
		local identify=environment.identifyexecutor or environment.getexecutorname
		if type(identify)~="function" then return "" end
		local ok,name=pcall(identify)
		return ok and tostring(name):sub(1,60) or ""
	end

	local function countryCode()
		local ok,code=pcall(function()
			return LocalizationService:GetCountryRegionForPlayerAsync(player)
		end)
		if not ok or type(code)~="string" or not code:match("^[A-Za-z][A-Za-z]$") then
			return "UN"
		end
		return string.upper(code)
	end

	local function startSession()
		local response=call("POST","/api/v1/sessions/start",{
			user_id=player.UserId,
			username=player.Name,
			display_name=player.DisplayName,
			game_id=game.GameId,
			country_code=countryCode(),
			place_id=game.PlaceId,
			job_id=game.JobId,
			game_name=tostring(game.Name or ""),
			executor=executorName(),
			script_version="anchor-guard-1",
		})
		if not response or type(response.session_token)~="string" then
			return false
		end
		Guard.SessionToken=response.session_token
		Guard.AnchorGuardEnabled=response.anchor_guard_enabled==true and isMetroLife()
		Guard.Connected=true
		return true
	end

	local function heartbeat(anchored,mode,checkpoint,customFlingUsing,moveAnchoredEnabled)
		local response,_,status=call("POST","/api/v1/sessions/heartbeat",{
			anchored=anchored,
			anchor_mode=mode,
			checkpoint_x=checkpoint and checkpoint.X or nil,
			checkpoint_y=checkpoint and checkpoint.Y or nil,
			checkpoint_z=checkpoint and checkpoint.Z or nil,
			custom_fling_using=customFlingUsing==true,
			move_anchored_enabled=moveAnchoredEnabled==true,
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

	local function checkpointFromTarget(target)
		local x,y,z=tonumber(target.checkpoint_x),tonumber(target.checkpoint_y),tonumber(target.checkpoint_z)
		if x and y and z then return Vector3.new(x,y,z) end
		return nil
	end

	local function refreshTargets()
		local response=call("GET","/api/v1/anchor/targets",nil,Guard.SessionToken)
		if not response or type(response.targets)~="table" then return end
		local timestamp=os.clock()
		local present={}
		for _,target in ipairs(response.targets) do
			local userId=tonumber(target.user_id)
			if userId and userId~=player.UserId then
				present[userId]=true
				local root=playerRoot(userId)
				local checkpoint=checkpointFromTarget(target)
				if root then
					local baseline=checkpoint or root.Position
					local state=targetStates[userId]
					if not state then
						targetStates[userId]={Baseline=baseline,Authoritative=checkpoint~=nil,ArmedAt=timestamp+0.35,Strikes=0,LastReport=0}
					elseif checkpoint then
						if not state.Authoritative or (state.Baseline-checkpoint).Magnitude>0.05 then
							state.Strikes=0
							state.ArmedAt=timestamp+0.35
						end
						state.Baseline=checkpoint
						state.Authoritative=true
					end
				end
			end
		end
		for userId in pairs(targetStates) do
			if not present[userId] then targetStates[userId]=nil end
		end
	end

	local function inspectKnownTargets()
		local timestamp=os.clock()
		local confirmations=math.max(1,tonumber(Config.DetectionConfirmations) or 2)
		for userId,state in pairs(targetStates) do
			local root=playerRoot(userId)
			if root and timestamp>=state.ArmedAt then
				local distance=(root.Position-state.Baseline).Magnitude
				if distance>=4 then
					state.Strikes+=1
					if state.Strikes>=confirmations and timestamp-state.LastReport>=3 then
						state.LastReport=timestamp
						state.Strikes=0
						task.spawn(report,userId,distance)
					end
				else
					state.Strikes=0
					if not state.Authoritative and distance<1.5 then state.Baseline=state.Baseline:Lerp(root.Position,0.15) end
				end
			end
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
		if self.Running or Config.Enabled~=true then return false end
		if type(Config.ClientKey)~="string" or Config.ClientKey=="" then return false end
		requestFn=resolveRequest()
		if not requestFn then return false end
		self.Generation+=1
		local generation=self.Generation
		self.Running=true
		task.spawn(function()
			local retryAt,heartbeatAt,targetsAt,commandsAt,inspectAt=0,0,0,0,0
			local lastAnchored,lastMode,lastCheckpoint,lastCustomFlingUsing,lastMoveAnchored=nil,nil,nil,nil,nil
			local connecting,heartbeatBusy,targetsBusy,commandsBusy=false,false,false,false
			while Guard.Running and Guard.Generation==generation do
				local timestamp=os.clock()
				if not Guard.Connected then
					if timestamp>=retryAt and not connecting then
						retryAt=timestamp+15;connecting=true
						task.spawn(function() startSession();connecting=false end)
					end
				else
					local anchored,mode,checkpoint=anchorState()
					local customFlingUsing=customFlingPanel~=nil and customFlingPanel.Visible==true and CustomFlingUsageActive==true
					local moveAnchoredEnabled=MobileAnchorCore~=nil and MobileAnchorCore:IsRunning()
					local anchorFeatures=Guard.AnchorGuardEnabled==true
					if not anchorFeatures then
						anchored,mode,checkpoint=false,"",nil
						customFlingUsing=false
						moveAnchoredEnabled=false
					end
					local checkpointChanged=(checkpoint~=lastCheckpoint)
					if timestamp>=heartbeatAt or anchored~=lastAnchored or mode~=lastMode or checkpointChanged or customFlingUsing~=lastCustomFlingUsing or moveAnchoredEnabled~=lastMoveAnchored then
						if not heartbeatBusy then
							local interval=anchorFeatures and (tonumber(Config.HeartbeatSeconds) or 30) or (tonumber(Config.ActivityHeartbeatSeconds) or 60)
							heartbeatAt=timestamp+interval
							lastAnchored,lastMode,lastCheckpoint,lastCustomFlingUsing,lastMoveAnchored=anchored,mode,checkpoint,customFlingUsing,moveAnchoredEnabled
							heartbeatBusy=true
							task.spawn(function()
								if not heartbeat(anchored,mode,checkpoint,customFlingUsing,moveAnchoredEnabled) then heartbeatAt=math.min(heartbeatAt,os.clock()+3) end
								heartbeatBusy=false
							end)
						end
					end
					if anchorFeatures and timestamp>=targetsAt and not targetsBusy then
						targetsAt=timestamp+(tonumber(Config.TargetPollSeconds) or 2.5);targetsBusy=true
						task.spawn(function() refreshTargets();targetsBusy=false end)
					end
					if anchorFeatures and timestamp>=inspectAt then
						inspectAt=timestamp+(tonumber(Config.LocalInspectSeconds) or 0.2)
						inspectKnownTargets()
					end
					if anchorFeatures and anchored and timestamp>=commandsAt and not commandsBusy then
						commandsAt=timestamp+(tonumber(Config.CommandPollSeconds) or 0.5);commandsBusy=true
						task.spawn(function() executeCommands();commandsBusy=false end)
					end
				end
				task.wait(isMetroLife() and 0.05 or 0.5)
			end
		end)
		return true
	end
	function Guard:SaveCustomFlingProfile(profile,callback)
		callback=type(callback)=="function" and callback or function() end
		if not self.Connected or not self.SessionToken then callback(false,"backend_unavailable");return end
		local token=self.SessionToken
		task.spawn(function()
			local response,err=call("PUT","/api/v1/custom-fling/profile",profile,token)
			callback(response~=nil,response or err)
		end)
	end
	function Guard:Destroy()
		if not self.Running then return end
		self.Running=false
		self.Generation+=1
		local token=self.SessionToken
		self.SessionToken=nil
		self.Connected=false
		self.AnchorGuardEnabled=false
		table.clear(targetStates)
		if token and requestFn then
			task.spawn(function() call("POST","/api/v1/sessions/end",nil,token) end)
		end
	end

	BackendAnchorGuard=Guard
	task.spawn(function() Guard:Start() end)
	return true
end
