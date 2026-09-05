-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, sideBarW, 1, 0)
sidebar.BackgroundColor3 = currentTheme.sidebar
sidebar.ClipsDescendants = true
sidebar.ZIndex = 8
sidebar.Parent = main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 14)
RegisterTheme(sidebar, "BackgroundColor3", "sidebar")

sideOverlay = Instance.new("Frame")
sideOverlay.Size = UDim2.new(0, 10, 1, 0)
sideOverlay.Position = UDim2.new(1, -10, 0, 0)
sideOverlay.BackgroundColor3 = currentTheme.sidebar
sideOverlay.BorderSizePixel = 0
sideOverlay.ZIndex = 7
sideOverlay.Parent = sidebar
RegisterTheme(sideOverlay, "BackgroundColor3", "sidebar")

tabBtns = {}

function CreateTabBtn(icon, tabName, yPos, customScale, rawImage)
	local isUrl = type(icon) == "string" and (string.find(icon, "rbxassetid://") or string.find(icon, "http") or string.find(icon, "rbxthumb://"))
	
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, tabBtnS, 0, tabBtnS)
	btn.Position = UDim2.new(0.5, -tabBtnS/2, 0, yPos)
	btn.BackgroundColor3 = currentTheme.sidebar
	btn.BackgroundTransparency = 0.8
	btn.Text = ""
	btn.TextSize = isMobile and 28 or 34
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = currentTheme.text
	btn.ZIndex = 9
	btn.Parent = sidebar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = currentTheme.sidebar
	stroke.Thickness = 2
	stroke.Transparency = 0.7
	stroke.Parent = btn
	
	local imgElement = nil
	if isUrl then
		local img = Instance.new("ImageLabel")
		local s = customScale or ((tabName == "emotes") and 0.85 or (0.95 * ICON_SCALE))
		img.Size = UDim2.fromScale(s, s)
		img.Position = UDim2.fromScale(0.5, 0.5)
		img.AnchorPoint = Vector2.new(0.5, 0.5)
		img.BackgroundTransparency = 1
		img.Image = rawImage or ResolveAssetImage(icon)
		img.ImageColor3 = currentTheme.text
		img.ZIndex = 110
		img.Parent = btn
		RegisterTheme(img, "ImageColor3", "text")
		imgElement = img
	else
		btn.Text = icon
		RegisterTheme(btn, "TextColor3", "text")
	end

	btn.MouseEnter:Connect(function()
		if currentTab ~= tabName then
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.7, BackgroundColor3 = _isPlaylistMode and Color3.fromRGB(0, 120, 255) or currentTheme.stroke, Size = UDim2.new(0, tabBtnS + 2, 0, tabBtnS + 2)}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, tabBtnS, 0, tabBtnS)
		}):Play()
	end)
	
	local qSize = tabBtnS + 10
	local quatrefoil = Instance.new("ImageLabel")
	quatrefoil.Name = "Quatrefoil"
	quatrefoil.Size = UDim2.new(0, qSize, 0, qSize)
	quatrefoil.Position = UDim2.new(0.5, -qSize/2, 0, yPos + tabBtnS/2 - qSize/2)
	quatrefoil.BackgroundTransparency = 1
	quatrefoil.Image = ResolveAssetImage(Icons.Quatrefoil)
	quatrefoil.ImageColor3 = currentTheme.accent
	quatrefoil.ImageTransparency = 0.3
	quatrefoil.ScaleType = Enum.ScaleType.Fit
	quatrefoil.ZIndex = 9
	quatrefoil.Visible = false
	quatrefoil.Parent = sidebar
	
	tabBtns[tabName] = {btn = btn, stroke = stroke, img = imgElement, quatrefoil = quatrefoil, yPos = yPos}
	return btn
end

CreateTabBtn(Icons.Emote, "emotes", 8)
CreateTabBtn("rbxassetid://75528584354229", "animations", 8 + tabBtnS + 6, 0.85)
CreateTabBtn(Icons.FavoriteFull, "favorites", 8 + (tabBtnS + 6) * 2)
CreateTabBtn(Icons.Recent, "recent", 8 + (tabBtnS + 6) * 3)
CreateTabBtn("rbxassetid://115725480722697", "friends", 8 + (tabBtnS + 6) * 4)
if not isMobile then
	CreateTabBtn(Icons.Keybind, "keybinds", 8 + (tabBtnS + 6) * 5)
	CreateTabBtn(Icons.Settings, "settings", 8 + (tabBtnS + 6) * 6)
else
	CreateTabBtn(Icons.Settings, "settings", 8 + (tabBtnS + 6) * 5)
end

_indS = tabBtnS + 4
_tabIndicator = Instance.new("Frame")
_tabIndicator.Name = "TabIndicator"
_tabIndicator.Size = UDim2.new(0, _indS, 0, _indS)
_tabIndicator.Position = UDim2.new(0.5, -_indS/2, 0, 8 - 2)
_tabIndicator.BackgroundColor3 = Color3.new(1, 1, 1)
_tabIndicator.BackgroundTransparency = 0
_tabIndicator.ZIndex = 8
_tabIndicator.Parent = sidebar
Instance.new("UICorner", _tabIndicator).CornerRadius = UDim.new(0, 12)

_indStroke = Instance.new("UIStroke")
_indStroke.Color = Color3.new(1, 1, 1)
_indStroke.Thickness = 1.5
_indStroke.Transparency = 0.15
_indStroke.Parent = _tabIndicator

_indGrad = Instance.new("UIGradient")
_indGrad.Rotation = 90
_indGrad.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0.25),
	NumberSequenceKeypoint.new(1, 0.72)
}
_indGrad.Parent = _tabIndicator

function _UpdateIndicatorGrad()
	local acc = currentTheme.accent
	local topC = Color3.new(math.min(1, acc.R + 0.18), math.min(1, acc.G + 0.18), math.min(1, acc.B + 0.18))
	local botC = Color3.new(acc.R * 0.25, acc.G * 0.25, acc.B * 0.25)
	_indGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, topC),
		ColorSequenceKeypoint.new(1, botC)
	}
end
_UpdateIndicatorGrad()

-- ===============================================================
-- CONTENT
-- ===============================================================

	return true
end
