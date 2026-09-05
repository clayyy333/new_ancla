-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

-- INITIALIZE
-- ===============================================================

main.Rotation = 0
openSize = GetDefaultSize()
TweenService:Create(main, TweenInfo.new(0.45, Enum.EasingStyle.Back), {Size = openSize, BackgroundTransparency = 0}):Play()
TweenService:Create(mainStroke, TweenInfo.new(0.45), {Transparency = 0}):Play()

task.wait(0.5)

main.ClipsDescendants = true
ApplyTheme(Settings.theme)
UpdateTabStyles()
UpdateTabData()

_keybindInputConn = nil
if not isMobile then
	_keybindInputConn = UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local keyName = inp.KeyCode.Name
		for emoteId, kb in pairs(KeybindsSet) do
			if type(kb) == "table" and kb.key == keyName then
				local emote = EmotesById[emoteId]
				if emote then
					PlayEmote(emote.id, emote.name)
				end
				break
			end
		end
	end)
end

task.wait(0.25)
Notify(SafeUtf8Char(0x2705) .. " " .. L.ready, #Emotes .. " emotes")

-- ================================================================
-- Bölüm 1: Dinamik Tema  |  Bölüm 2: Animation Blending & Combo
-- Bölüm 3: Canlı Emote HUD  |  Bölüm 4: Entegrasyon
-- NOT: do...end bloğu Lua'nın 200 local sınırını aşmamak için
-- ================================================================

-- ----------------------------------------------------------------
-- ----------------------------------------------------------------

	return true
end
