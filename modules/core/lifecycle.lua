-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

-- CHARACTER RESPAWN & AUTO-RELOAD
-- ===============================================================

_genv().autoReloadEnabled_Vexro = Settings.loopEmote

_charAddedConn = player.CharacterAdded:Connect(function(newChar)
	local newHum = newChar:WaitForChild("Humanoid", 5)
	if not newHum then return end
	
	if newHum.RigType == Enum.HumanoidRigType.R6 then
		Notify(SafeUtf8Char(0x274C), L.r6Msg)
		task.wait(2)
		gui:Destroy()
		return
	end
	
	if ReapplyAnimationSelection then
		task.wait(0.5)
		local newAnimate = newChar:WaitForChild("Animate", 5)
		if newAnimate then
			pcall(ReapplyAnimationSelection)
		end
	end
	
	if _genv().lastVexroEmote and _genv().autoReloadEnabled_Vexro then
		task.wait(1)
		PlayEmote(_genv().lastVexroEmote.id, _genv().lastVexroEmote.name, true)
		Notify("[R]", L.ready or "Emote reapplied")
	end
end)

-- ===============================================================

	return true
end
