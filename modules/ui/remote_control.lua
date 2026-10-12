-- Explicit opt-in. Fast polling is only enabled by a live owner selection.
return function(context)
	setfenv(1,context)
	local allowed,enabled,alive=false,false,true
	local ownedAnchor,ownedFling=false,false
	local completed={}
	local consentSession=nil
	local function stopOwned()
		if ownedAnchor and StaticPassThroughAnchorCore then StaticPassThroughAnchorCore:Stop() end
		if ownedFling and Fling2EfficientCore then Fling2EfficientCore:Stop() end
		ownedAnchor=false;ownedFling=false
	end
	MakeSectionHeader(isES and "Control remoto" or "Remote control",25)
	local row=MakeRow("",isES and "Permitir control del administrador" or "Allow administrator control",isES and "Solo tu servidor. Puedes revocarlo aquí." or "Your server only. Revoke here anytime.",26)
	local b=Instance.new("TextButton");b.Size=UDim2.new(0,100,0,34);b.Position=UDim2.new(1,-112,.5,-17)
	b.Text=isES and "Permitir" or "Allow";b.Font=Enum.Font.GothamBold;b.TextSize=12;b.BackgroundColor3=currentTheme.tertiary;b.TextColor3=currentTheme.text;b.ZIndex=9;b.Parent=row
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,9);RegisterTheme(b,"BackgroundColor3","tertiary");RegisterTheme(b,"TextColor3","text")
	local busy=false
	b.Activated:Connect(function()
		if busy then return end
		local g=BackendAnchorGuard;if not g or not g.Connected then return end
		local value=not allowed;local session=g.SessionId
		if not value then allowed=false;enabled=false;stopOwned() end
		busy=true
		task.spawn(function()
			local response=g:RemoteCall("PUT","/api/v1/remote/consent",{allowed=value})
			if alive and g.SessionId==session then
				if response then allowed=value;consentSession=session end
				b.Text=allowed and (isES and "Revocar" or "Revoke") or (isES and "Permitir" or "Allow")
			end
			busy=false
		end)
	end)
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
				allowed=false;enabled=false;consentSession=nil;completed={};stopOwned();b.Text=isES and "Permitir" or "Allow"
			end
			task.wait(.2)
		end
	end)
	return true
end
