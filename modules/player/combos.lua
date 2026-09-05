-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

HUD, infoPanel, infoSpeedLbl, comboSlots, comboQueue_UI = nil, nil, nil, nil, nil
_currentInfoId, _currentInfoName = nil, nil
_comboLoopEnabled = false
_comboLoopList    = {}


-- ----------------------------------------------------------------
-- BÖLÜM 2 — ANİMASYON BLENDING & SEQUENCING (Combo Sistemi)
-- AnimationTrack:Play(0.3) ile 0.3s fade-in/out harmanlama,
-- Stopped sinyali ile otomatik sıralama, max 3 emote combo.
-- ----------------------------------------------------------------

ShowEmoteHUD, HideEmoteHUD = nil, nil

ComboQueue    = {}
isComboActive = false

function PlayComboStep(emoteId, emoteName)
	local animator = GetAnimator()
	if not animator then return end

	if currentAnimTrack and currentAnimTrack.IsPlaying then
		currentAnimTrack:Stop(0.3)
		task.wait(0.08)
	end

	local anim = _animCache[emoteId]
	if not anim then
		pcall(function()
			local ok, objects = pcall(function()
				return game:GetObjects("rbxassetid://" .. emoteId)
			end)
			if ok and objects and #objects > 0 then
				local item = objects[1]
				anim = item:IsA("Animation") and item
					or item:FindFirstChildWhichIsA("Animation", true)
			end
			if not anim then
				anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. emoteId
			end
			_animCache[emoteId] = anim
		end)
	end
	if not anim then return end

	pcall(function()
		local track = animator:LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped   = false

		track:Play(0.3)
		task.delay(0.05, function()
			if track.IsPlaying then
				track:AdjustSpeed(Settings.speed)
			end
		end)

		currentAnimTrack = track
		_genv().lastVexroEmote = {id = emoteId, name = emoteName}
		AddToRecent(emoteId)

		task.defer(function()
			if ShowEmoteHUD then ShowEmoteHUD(emoteId, emoteName) end
		end)

		track.Stopped:Connect(function()
			if not isComboActive then return end
			if #ComboQueue > 0 then
				local nxt = table.remove(ComboQueue, 1)
				PlayComboStep(nxt.id, nxt.name)
			else
				if _comboLoopEnabled and #_comboLoopList > 0 then
					ComboQueue = {}
					for i = 2, #_comboLoopList do
						ComboQueue[#ComboQueue + 1] = _comboLoopList[i]
					end
					PlayComboStep(_comboLoopList[1].id, _comboLoopList[1].name)
				else
					isComboActive = false
					task.defer(function()
						if HideEmoteHUD then HideEmoteHUD() end
					end)
					task.defer(function()
						if comboQueue_UI then comboQueue_UI = {} end
						if comboSlots then
							for j = 1, 3 do
								if comboSlots[j] then
									comboSlots[j].Text = L.slotLabel .. " " .. j
									TweenService:Create(comboSlots[j], TweenInfo.new(0.15), {
										BackgroundColor3 = Color3.fromRGB(30, 30, 46)
									}):Play()
								end
							end
						end
					end)
				end
			end
		end)
	end)
end

function StartCombo(emoteList)
	if #emoteList == 0 then return end
	isComboActive = true
	_comboLoopList = {}
	for _, e in ipairs(emoteList) do
		_comboLoopList[#_comboLoopList + 1] = {id = e.id, name = e.name}
	end
	ComboQueue = {}
	for i = 2, #emoteList do
		ComboQueue[#ComboQueue + 1] = emoteList[i]
	end
	PlayComboStep(emoteList[1].id, emoteList[1].name)
end

-- ----------------------------------------------------------------
-- BÖLÜM 3 — CANLI EMOTE HUD (Alt-Orta Şeffaf Panel)
-- RenderStepped canlı slider, hız butonları (0.1x–2x),
-- bilgi popup, sürüklenebilir knob, Disconnect ile FPS koruması.
-- ----------------------------------------------------------------

	return true
end
