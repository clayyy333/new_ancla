-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

currentAnimTrack = nil
lastEmoteTime = 0

function GetAnimator()
	local character = player.Character
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

function StopAllTracks()
	local animator = GetAnimator()
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			pcall(function() 
				track:Stop(0.1)
			end)
		end
	end
	currentAnimTrack = nil
end

function ApplySpeedToAllTracks()
	local animator = GetAnimator()
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			pcall(function() track:AdjustSpeed(Settings.speed) end)
		end
	end
end


function StopEmote(showNotif)
	StopAllTracks()
	if showNotif then Notify(L.stopped, "", 113416463749658) end
	if FriendData.currentSyncPartner then
		pcall(function()
			SaveData()
		end)
		FriendData.currentSyncPartner = nil
	end
	if _genv().VexroBroadcastStop then
		pcall(_genv().VexroBroadcastStop)
	end
end

_heartbeatConn = RunService.Heartbeat:Connect(function()
	if Settings.stopOnWalk and currentAnimTrack and currentAnimTrack.IsPlaying then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.MoveDirection.Magnitude > 0 then
				StopEmote(false)
			end
		end
		
		-- Instant sync partner walk & emote change detection
		if FriendData.currentSyncPartner then
			local partnerPlayer = Players:GetPlayerByUserId(tonumber(FriendData.currentSyncPartner))
			if partnerPlayer and partnerPlayer.Character then
				local partnerHumanoid = partnerPlayer.Character:FindFirstChildOfClass("Humanoid")
				if partnerHumanoid then
					if partnerHumanoid.MoveDirection.Magnitude > 0 then
						StopEmote(false)
					else
						local partnerAnimator = partnerHumanoid:FindFirstChildOfClass("Animator")
						if partnerAnimator then
							local tracks = partnerAnimator:GetPlayingAnimationTracks()
							for _, pt in ipairs(tracks) do
								if pt.Priority == Enum.AnimationPriority.Action4 and pt.IsPlaying and pt.Animation then
									local animIdStr = pt.Animation.AnimationId:match("%d+")
									if animIdStr then
										local animId = tonumber(animIdStr)
										if animId and _genv().lastVexroEmote and _genv().lastVexroEmote.id ~= animId then
											if EmotesById and EmotesById[animId] then
												local spd = Settings.speed > 0 and Settings.speed or 1
												local calcStartTime = workspace:GetServerTimeNow() - (pt.TimePosition / spd)
												PlayEmote(animId, EmotesById[animId].name, true, calcStartTime)
												break
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end)

_animCache = {}

function PlayEmote(id, name, silent, syncStartTime)
	local animator = GetAnimator()
	if not animator then return end
	
	StopAllTracks()
	
	_genv().lastVexroEmote = {id = id, name = name}
	
	task.spawn(function()
		local anim = _animCache[id]
		
		if not anim then
			local successObj, objects = pcall(function()
				return game:GetObjects("rbxassetid://" .. id)
			end)
			
			if successObj and objects and #objects > 0 then
				local item = objects[1]
				if item:IsA("Animation") then
					anim = item
				else
					anim = item:FindFirstChildWhichIsA("Animation", true)
				end
			end
			
			if not anim then
				anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. id
			end
			
			_animCache[id] = anim
		end
		
		if _genv().lastVexroEmote and _genv().lastVexroEmote.id == id then
			local success, err = pcall(function()
				local track = animator:LoadAnimation(anim)
				track.Priority = Enum.AnimationPriority.Action4
				track.Looped = Settings.loopEmote
				track:Play(0.1)
				
				if syncStartTime then
					task.spawn(function()
						local waitTime = 0
						while track.Length <= 0 and waitTime < 3 do
							waitTime = waitTime + task.wait()
						end
						
						if track.Length > 0 then
							local tNow = workspace:GetServerTimeNow()
							local offset = tNow - tonumber(syncStartTime)
							if offset > 0 then
								pcall(function()
									track.TimePosition = (offset * Settings.speed) % track.Length
								end)
							end
						end
					end)
				end
				
				task.delay(0.05, function()
					track:AdjustSpeed(Settings.speed)
				end)
				
				currentAnimTrack = track
				AddToRecent(id)
			end)
			
			if success then
				if not silent then
					local speedTxt = Settings.speed ~= 1 and " (" .. Settings.speed .. "x)" or ""
					Notify(L.playing .. speedTxt, name, 129338178452237)
				end
				lastEmoteTime = tick()
				if _genv().VexroBroadcastSync and FriendData.syncEmote and not silent then
					pcall(_genv().VexroBroadcastSync, id, name, workspace:GetServerTimeNow())
				end
			else
				Notify(SafeUtf8Char(0x274C), L.emoteLoadFail)
			end
		end
	end)
end

-- ===============================================================
-- MAIN MENU
-- ===============================================================

	return true
end
