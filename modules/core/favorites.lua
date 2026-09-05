-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

function IsFavorite(id)
	return FavoritesSet[tonumber(id)] == true
end

MAX_FAVORITES = 25

function ToggleFavorite(id)
	id = tonumber(id)
	if not id then return false end
	if FavoritesSet[id] then
		-- Remove local favorite
		FavoritesSet[id] = nil
		for i = #Favorites, 1, -1 do
			if Favorites[i] == id then
				table.remove(Favorites, i)
				break
			end
		end
		SaveLocalData()
		return false
	end
	
	if #Favorites >= MAX_FAVORITES then
		Notify("⭐ " .. L.favLimit, "")
		return false
	end
	
	-- Add local favorite
	FavoritesSet[id] = true
	Favorites[#Favorites + 1] = id
	SaveLocalData()
	return true
end

function AddToRecent(id)
	id = tonumber(id)
	if not id then return end
	for i = #RecentEmotes, 1, -1 do
		if tonumber(RecentEmotes[i]) == id then table.remove(RecentEmotes, i) end
	end
	table.insert(RecentEmotes, 1, id)
	while #RecentEmotes > MAX_RECENT do table.remove(RecentEmotes) end
	SaveData()
	if currentTab == "recent" and UpdateTabData then UpdateTabData() end
end

-- ===============================================================
-- EMOTE & SPEED SYSTEM
-- ===============================================================

	return true
end
