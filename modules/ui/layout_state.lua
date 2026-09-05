-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

ICON_SCALE = 1.5
BUTTON_SCALE = 1.1
FONT_SCALE = 1.2

-- ===============================================================
-- VARIABLES
-- ===============================================================

EMOTE_ICON = "rbxassetid://120313093991132"
currentData, filtered = Emotes, Emotes
currentTab = "emotes"
page, perPage, pages, cols = 1, 14, 1, 7
cards = {}
lastVexroAnimationPack = nil
sideBarW = math.floor((isMobile and 53 or 63) * BUTTON_SCALE)
tabBtnS = math.floor((isMobile and 43 or 51) * BUTTON_SCALE)
bottomBarH = isMobile and 26 or 22
currentCardSize = 0
_badEmotes = {}
_refreshPending = false

-- ===============================================================
-- FAVORITES & RECENT
-- ===============================================================

	return true
end
