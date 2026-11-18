-- Lightweight appearance helpers, independent from the Settings panel.
return function(context)
 setfenv(1,context)
-- Transparencia visual de superficies; no altera textos, imágenes ni bordes.
ApplyGUITransparencyElement = function(element)
	if not element or not element:IsA("GuiObject") then return end
	local base = element:GetAttribute("VexroBaseBackgroundTransparency")
	if type(base) ~= "number" then
		base = element.BackgroundTransparency
		element:SetAttribute("VexroBaseBackgroundTransparency", base)
	end
	element.BackgroundTransparency = math.max(base, math.clamp(tonumber(Settings.guiTransparency) or 0, 0, 0.8))
end

ApplyGUITransparency = function()
	local visited = {}
	for _,entry in ipairs(themeElements) do
		if entry.prop == "BackgroundColor3" and entry.el and entry.el.Parent and not visited[entry.el] then
			visited[entry.el] = true
			ApplyGUITransparencyElement(entry.el)
		end
	end
	if main and main.Parent then
		local glass = Settings.theme == "FrostedGlass" or Settings.theme == "GTAMode"
		main:SetAttribute("VexroBaseBackgroundTransparency", glass and 0.18 or 0)
		ApplyGUITransparencyElement(main)
		local gradient = main:FindFirstChild("VexroGradFrame")
		if gradient and gradient:IsA("GuiObject") then
			gradient:SetAttribute("VexroBaseBackgroundTransparency", glass and 0.45 or 0)
			ApplyGUITransparencyElement(gradient)
		end
	end
end

 return true
end
