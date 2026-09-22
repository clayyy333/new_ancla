-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

char = player.Character or player.CharacterAdded:Wait()
hum = char:WaitForChild("Humanoid", 5)
if not hum or hum.RigType == Enum.HumanoidRigType.R6 then
	Notify(SafeUtf8Char(0x274C), L.r6Msg)
	gui:Destroy()
	return
end

Emotes = {}

function LoadEmotes()
	debugLog("LoadEmotes starting")
	local success, result = pcall(function()
		local response = loadModule("data/emotes")
		return HttpService:JSONDecode(response)
	end)
	debugLog("LoadEmotes JSON loaded. success=" .. tostring(success) .. " resultType=" .. type(result))
	
	if success and result then
		local data = type(result) == "table" and (result.data or result)
		local _seenIds = {}
		for _, emote in ipairs(data) do
			if emote.id and emote.name then
				local numId = tonumber(emote.id)
				if numId and not _seenIds[numId] then
					_seenIds[numId] = true
					Emotes[#Emotes + 1] = {
						name          = tostring(emote.name),
						id            = numId,
						creatorName   = tostring(emote.creatorName      or ""),
						description   = tostring(emote.description      or ""),
						price         = emote.price,
						priceStatus   = tostring(emote.priceStatus      or ""),
						favoriteCount = emote.favoriteCount,
						createdUtc    = tostring(emote.itemCreatedUtc   or ""),
					}
				end
			end
		end
	end
	
	if #Emotes == 0 then
		Emotes = {
			{name = "Wave", id = 3576686446},
			{name = "Point", id = 3576823880},
			{name = "Dance", id = 3576720708},
			{name = "Laugh", id = 3576777185},
			{name = "Cheer", id = 3576738018}
		}
	end
	debugLog("LoadEmotes finished. Emotes count=" .. tostring(#Emotes))
end

AnimationPacks = {}
function LoadAnimations()
	local success, result = pcall(function()
		local response = loadModule("data/animations")
		return HttpService:JSONDecode(response)
	end)
	
	if success and result then
		local data = type(result) == "table" and (result.data or result)
		for _, pack in ipairs(data) do
			if pack.id and pack.name and pack.bundledItems then
				table.insert(AnimationPacks, {
					id = "anim_" .. tostring(pack.id),
					bundleId = tonumber(pack.id),
					bundledItems = pack.bundledItems,
					name = tostring(pack.name),
					isAnimationPack = true
				})
			end
		end
	end
	
	if #AnimationPacks == 0 then
		AnimationPacks = {
			{
				id = "anim_ninja",
				name = "Ninja Pack",
				isAnimationPack = true,
				Idle = 658832408,
				Walk = 658831143,
				Run = 658830056,
				Jump = 658832070,
				Fall = 658831500,
				Swim = 658832807,
				Climb = 658833139
			},
			{
				id = "anim_mage",
				name = "Mage Pack",
				isAnimationPack = true,
				Idle = 707742142,
				Walk = 707897309,
				Run = 707861613,
				Jump = 707853694,
				Fall = 707829716,
				Swim = 707876443,
				Climb = 707826056
			}
		}
	end
end

	return true
end
