-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

isMobile = UserInputService.TouchEnabled

_resolvedCache = {}
function ResolveAssetImage(assetIdOrUrl)
	if not assetIdOrUrl then return "" end
	local str = tostring(assetIdOrUrl)
	local rawId = str:gsub("rbxassetid://", ""):gsub("[^%d]", "")
	if rawId == "" then return str end
	if _resolvedCache[rawId] then return _resolvedCache[rawId] end
	local resolved = nil
	pcall(function()
		local objects = game:GetObjects("rbxassetid://" .. rawId)
		if objects and #objects > 0 then
			local obj = objects[1]
			if obj:IsA("Decal") or obj:IsA("Texture") then
				resolved = obj.Texture
			elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
				resolved = obj.Image
			end
		end
	end)
	if not resolved or resolved == "" then
		resolved = "rbxthumb://type=Asset&id=" .. rawId .. "&w=420&h=420"
	end
	_resolvedCache[rawId] = resolved
	return resolved
end

UTF8_FALLBACK = {
	[0x2605] = "*",
	[0x2606] = "-",
	[0x2705] = "[OK]",
	[0x274C] = "[X]",
}

function SafeUtf8Char(code)
	if utf8 and type(utf8.char) == "function" then
		local ok, value = pcall(utf8.char, code)
		if ok and value then return value end
	end
	return UTF8_FALLBACK[code] or ""
end

logo = [[

                                                                                  
                                                                               ▄▄ 
██  ██ ██████ ██  ██ █████▄  ▄████▄   ▄████▄ ███  ██   ██████ ▄████▄ █████▄    ██ 
██▄▄██ ██▄▄    ████  ██▄▄██▄ ██  ██   ██  ██ ██ ▀▄██     ██   ██  ██ ██▄▄█▀    ██ 
 ▀██▀  ██▄▄▄▄ ██  ██ ██   ██ ▀████▀   ▀████▀ ██   ██     ██   ▀████▀ ██        ▄▄ 
                                                                                                                                                                                                            
]]

print(logo)

-- ===============================================================
-- THEMES
-- ===============================================================

	return true
end
