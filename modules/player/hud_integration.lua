-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

_origPlayEmote = PlayEmote
PlayEmote = function(id, name, silent, syncStartTime)
	if tostring(id):find("anim_") then
		for _, pack in ipairs(AnimationPacks) do
			if pack.id == id then
				EquipAnimationPack(pack)
				break
			end
		end
		return
	end
	_origPlayEmote(id, name, silent, syncStartTime)
	local myToken = _hudHideToken + 1
	_hudHideToken = myToken
	task.defer(function()
		if _hudHideToken ~= myToken then return end
		if currentAnimTrack then
			ShowEmoteHUD(id, name)
			local tracked = currentAnimTrack
			tracked.Stopped:Connect(function()
				if (currentAnimTrack == tracked or not currentAnimTrack)
				and not isComboActive then
					HideEmoteHUD()
				end
			end)
		end
	end)
end

_origStopEmote = StopEmote
StopEmote = function(showNotif)
	_origStopEmote(showNotif)
	isComboActive = false
	ComboQueue    = {}
	HideEmoteHUD()
end

-- ----------------------------------------------------------------
-- BOLUM 5 - COMBO SIRASI
-- ----------------------------------------------------------------

	return true
end
