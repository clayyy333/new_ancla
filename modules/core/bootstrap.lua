-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)



pcall(function()
	local b = game:GetService("Lighting"):FindFirstChild("VexroGlassBlur")
	if b then b:Destroy() end
end)
pcall(function()
	local f = workspace:FindFirstChild("VexroGlassBlurFolder")
	if f then f:Destroy() end
end)
_genv = (type(getgenv) == "function") and getgenv or function() return {} end
if _genv().VexroEmotesCleanup then
	pcall(_genv().VexroEmotesCleanup)
	_genv().VexroEmotesCleanup = nil
end

Players = game:GetService("Players")
TweenService = game:GetService("TweenService")
UserInputService = game:GetService("UserInputService")
HttpService = game:GetService("HttpService")
RunService = game:GetService("RunService")

player = Players.LocalPlayer
playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then return end

function debugLog(msg) end

-- ===============================================================
-- ===============================================================
mySessionToken = HttpService:GenerateGUID(false)
_genv().VexroSessionToken = mySessionToken
_genv().VexroBroadcastSync = nil
_genv().VexroBroadcastStop = nil

old = playerGui:FindFirstChild("VexroEmotes")
if old then old:Destroy() end

-- ===============================================================
-- DATA SYSTEM
-- ===============================================================

	return true
end
