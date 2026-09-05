-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

LoadData()
LoadEmotes()
LoadAnimations()

for _, emote in ipairs(Emotes) do
	EmotesById[emote.id] = emote
	emote._lname = emote.name:lower()
end
MakeRow, MakeSectionHeader, MakePillToggle = nil, nil, nil

-- ===============================================================
-- UI SIZE SETTINGS
-- ===============================================================

	return true
end
