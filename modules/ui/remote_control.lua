-- Preauthorized personal account only. Fast polling requires a live owner selection.
return function(context)
	setfenv(1,context)
	if player.UserId~=11773278300 or string.lower(player.Name)~="dayzero777" then return true end
	local allowed,enabled,alive=false,false,true
	local ownedAnchor,ownedFling=false,false
	local completed={}
	local consentSession=nil
	local function stopOwned()
		if ownedAnchor and StaticPassThroughAnchorCore then StaticPassThroughAnchorCore:Stop() end
		if ownedFling and Fling2EfficientCore then Fling2EfficientCore:Stop() end
		ownedAnchor=false;ownedFling=false
	end
	local function execute(c)
		if c.game_id~=game.GameId or c.place_id~=game.PlaceId or c.job_id~=game.JobId or (tonumber(c.expires_at) or 0)<=os.time() then return "rejected" end
		local anchor=StaticPassThroughAnchorCore;local fling=Fling2EfficientCore
		if c.action=="stop_remote" then stopOwned();return "applied" end
		if c.action=="anchor_phase_on" or c.action=="anchor_on" then
			if not anchor or (fling and fling.Running) then return "rejected" end
			if anchor:IsRunning() and not ownedAnchor then return "rejected" end
			if not anchor:Start() then return "failed" end
			ownedAnchor=true
			if c.action=="anchor_phase_on" then anchor:SetPhase(true) end
			return "applied"
		elseif c.action=="anchor_phase_off" or c.action=="anchor_off" then
			if anchor and ownedAnchor then anchor:Stop();ownedAnchor=false;return "applied" end
			return "rejected"
		elseif c.action=="short_fling_on" then
			if not fling or fling.Running or (anchor and anchor:IsRunning()) then return "rejected" end
			local target=Players:GetPlayerByUserId(tonumber(c.target_user_id) or 0)
			if not target or target==player then return "rejected" end
			fling:SetShortDisplacementEnabled(true)
			if not fling:SetTarget(target) then return "failed" end
			if not fling:Start() then return "failed" end
			ownedFling=true;return "applied"
		elseif c.action=="short_fling_off" then
			if fling and ownedFling then fling:Stop();ownedFling=false;return "applied" end
			return "rejected"
		end
		return "rejected"
	end
	gui.Destroying:Connect(function() alive=false;allowed=false;enabled=false;stopOwned() end)
	task.spawn(function()
		local nextPoll,failures=0,0
		while alive and gui.Parent do
			local g=BackendAnchorGuard
			if g and g.Connected and g.Running and consentSession~=g.SessionId and os.clock()>=nextPoll then
				stopOwned();allowed=false;enabled=false;completed={}
				local sid=g.SessionId
				local response=g:RemoteCall("PUT","/api/v1/remote/consent",{allowed=true})
				if alive and response and g.SessionId==sid then allowed=true;consentSession=sid end
				nextPoll=os.clock()+(allowed and 0 or 30)
			end
			if g and g.Connected and allowed and consentSession==g.SessionId and os.clock()>=nextPoll then
				local sid=g.SessionId
				local response=g:RemoteCall("GET",enabled and "/api/v1/remote/commands" or "/api/v1/remote/status")
				if not alive then return end
				if allowed and g.SessionId==sid then
					if response then
						failures=0;enabled=response.enabled==true
						if not enabled then stopOwned() end
						for _,c in ipairs(response.commands or {}) do
							if not allowed or not alive or not g.Running then break end
							local result=completed[c.id]
							if not result then local ok,value=pcall(execute,c);result=ok and value or "failed";completed[c.id]=result end
							g:RemoteCall("POST","/api/v1/remote/commands/"..c.id.."/ack",{result=result})
						end
					else failures=failures+1;if failures>=3 then enabled=false;stopOwned() end end
				end
				nextPoll=os.clock()+(enabled and 1 or (tonumber(BackendAnchorConfig.HeartbeatSeconds) or 30))
			elseif consentSession and (not g or not g.Running or g.SessionId~=consentSession) then
				allowed=false;enabled=false;consentSession=nil;completed={};stopOwned()
			end
			task.wait(.2)
		end
	end)
	return true
end
