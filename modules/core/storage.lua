-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

DATA_FILE = "VexroEmotes_Data_" .. tostring(player.UserId) .. ".json"
Settings = {theme = "Dark", speed = 1, notifications = true, loopEmote = true, language = nil, stopOnWalk = true, showHUD = true, ambientSound = true, antiAFK = false}

FriendData = {
	friends        = {},
	autoReject     = false,
	acceptRequests = true,
	playFriendEmote = true,
	syncEmote      = true,
	addModeActive  = false,
	currentSyncPartner = nil,
}
_friendConns = {}
RefreshFriendList = nil
Playlists = {}
PlaylistFavorites = {}
RefreshPlaylistsList = nil
trendingDropdown = nil
ShowSavePlaylistDialog = nil
ShowFriendRequestPanel = nil
Favorites = {}
FavoritesSet = {}
Keybinds = {}
KeybindsSet = {}
RecentEmotes = {}
_onSpeedChanged = nil
_onPauseStateChanged = nil
MAX_RECENT = 20

function SaveLocalData()
	local ok, err = pcall(function()
		if not writefile then
			warn("[Emotes] Local storage is unavailable; changes will only last for this session.")
			return
		end
		writefile(DATA_FILE, HttpService:JSONEncode({
			favorites = Favorites,
			recent = RecentEmotes,
			settings = Settings,
			friendSettings = {
				autoReject = FriendData.autoReject,
				acceptRequests = FriendData.acceptRequests,
				playFriendEmote = FriendData.playFriendEmote,
				syncEmote = FriendData.syncEmote
			},
			keybinds = Keybinds,
			playlists = Playlists
		}))
	end)
	if not ok then warn("[Emotes] Local save failed: " .. tostring(err)) end
end

function SaveData()
	SaveLocalData()
end

function LoadData()
	debugLog("LoadData starting")
	_genv().VexroServerAccessible = false
	pcall(function()
		-- 1. Load local backup
		if readfile and isfile and isfile(DATA_FILE) then
			local data = HttpService:JSONDecode(readfile(DATA_FILE))
			if data then
				Playlists = {}
				if data.playlists then
					Playlists = data.playlists
				end
				MockPlaylists = Playlists

				Favorites = {}
				if data.favorites then
					for _, v in pairs(data.favorites) do
						table.insert(Favorites, tonumber(v)) 
					end
				end
				RecentEmotes = {}
				if data.recent then
					for _, v in pairs(data.recent) do
						table.insert(RecentEmotes, tonumber(v))
					end
				end
				if data.settings then
					Settings.theme = data.settings.theme or "Dark"
					Settings.speed = data.settings.speed or 1
					Settings.notifications = data.settings.notifications ~= false
					Settings.loopEmote = data.settings.loopEmote ~= false
					Settings.language = data.settings.language or nil
					Settings.stopOnWalk = data.settings.stopOnWalk ~= false
					Settings.showHUD = data.settings.showHUD ~= false
					Settings.ambientSound = data.settings.ambientSound ~= false
					Settings.antiAFK = data.settings.antiAFK == true
					Settings.searchHistory = data.settings.searchHistory or {}
				end
				if data.friendSettings then
					FriendData.autoReject = data.friendSettings.autoReject == true
					FriendData.acceptRequests = data.friendSettings.acceptRequests ~= false
					FriendData.playFriendEmote = data.friendSettings.playFriendEmote ~= false
					FriendData.syncEmote = data.friendSettings.syncEmote ~= false
				end
				Keybinds = {}
				if data.keybinds then
					for k, v in pairs(data.keybinds) do
						Keybinds[tostring(k)] = v
					end
				end
			end
		end

	end)
	
	-- Post-process Favorites and Keybinds
	FavoritesSet = {}
	for _, v in ipairs(Favorites) do FavoritesSet[v] = true end

	KeybindsSet = {}
	for k, v in pairs(Keybinds) do
		local num = tonumber(k)
		if num then
			KeybindsSet[num] = v
		else
			KeybindsSet[k] = v
		end
	end
end


function GetKeybind(emoteId) return KeybindsSet[emoteId] end
function SetKeybind(emoteId, name, keyStr)
	KeybindsSet[emoteId] = {name = name, key = keyStr}
	Keybinds[tostring(emoteId)] = {name = name, key = keyStr}
	SaveData()
end
function RemoveKeybind(emoteId)
	KeybindsSet[emoteId] = nil
	Keybinds[tostring(emoteId)] = nil
	SaveData()
end

EmotesById = {}

_emoteMetaCache = {}

-- ===============================================================
-- UTILITIES
-- ===============================================================

    -- Recuperar ajustes y favoritos antes de mostrar el selector de idioma.
    LoadData()

	return true
end
