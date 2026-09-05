-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)
	topNav = Instance.new("Frame")
	topNav.Name = "TopNavigation"
	topNav.Size = UDim2.new(1, 0, 0, topNavH)
	topNav.BackgroundColor3 = currentTheme.sidebar
	topNav.ClipsDescendants = true
	topNav.ZIndex = 20
	topNav.Parent = main
	Instance.new("UICorner", topNav).CornerRadius = UDim.new(0, 14)
	RegisterTheme(topNav, "BackgroundColor3", "sidebar")
	local navPad, rowH = isMobile and 5 or 7, isMobile and 31 or 35
	mainNav = Instance.new("Frame")
	mainNav.Size = UDim2.new(1, -(navPad * 2), 0, rowH)
	mainNav.Position = UDim2.new(0, navPad, 0, navPad)
	mainNav.BackgroundTransparency = 1
	mainNav.ZIndex = 21
	mainNav.Parent = topNav
	local mainLayout = Instance.new("UIListLayout")
	mainLayout.FillDirection = Enum.FillDirection.Horizontal
	mainLayout.Padding = UDim.new(0, isMobile and 4 or 6)
	mainLayout.Parent = mainNav
	movementNav = Instance.new("Frame")
	movementNav.Size = UDim2.new(1, -(navPad * 2), 0, rowH)
	movementNav.Position = UDim2.new(0, navPad, 0, navPad + rowH + 3)
	movementNav.BackgroundColor3 = currentTheme.secondary
	movementNav.ZIndex = 21
	movementNav.Parent = topNav
	Instance.new("UICorner", movementNav).CornerRadius = UDim.new(0, 9)
	RegisterTheme(movementNav, "BackgroundColor3", "secondary")
	local movementPad = Instance.new("UIPadding")
	movementPad.PaddingLeft = UDim.new(0, 4)
	movementPad.Parent = movementNav
	local movementLayout = Instance.new("UIListLayout")
	movementLayout.FillDirection = Enum.FillDirection.Horizontal
	movementLayout.Padding = UDim.new(0, 4)
	movementLayout.Parent = movementNav
	mainNavBtns, tabBtns = {}, {}
	local function CreateTextNavButton(parent, text, name, width, height)
		local btn = Instance.new("TextButton")
		btn.Name = name .. "Button"
		btn.Size = UDim2.new(0, width, 0, height)
		btn.BackgroundColor3 = currentTheme.tertiary
		btn.BackgroundTransparency = 1
		btn.AutoButtonColor = false
		btn.Text = text
		btn.TextColor3 = currentTheme.textDim
		btn.TextSize = isMobile and 11 or 13
		btn.Font = Enum.Font.GothamBold
		btn.ZIndex = 22
		btn.Parent = parent
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		RegisterTheme(btn, "BackgroundColor3", "tertiary")
		RegisterTheme(btn, "TextColor3", "textDim")
		return btn
	end
	local mainLabels = {{"movements", L.movements}, {"friends", L.friendTab}, {"keybinds", L.keybinds}, {"settings", L.settings}}
	for _, item in ipairs(mainLabels) do
		if item[1] ~= "keybinds" or not isMobile then
			local width = isMobile and (item[1] == "movements" and 94 or 72) or (item[1] == "movements" and 122 or 94)
			mainNavBtns[item[1]] = CreateTextNavButton(mainNav, item[2], item[1], width, rowH)
		end
	end
	local movementLabels = {{"emotes", L.emotes}, {"animations", L.animations}, {"favorites", L.favorites}, {"recent", L.recent}}
	for _, item in ipairs(movementLabels) do
		local btn = CreateTextNavButton(movementNav, item[2], item[1], isMobile and 76 or 105, rowH - 6)
		tabBtns[item[1]] = {btn = btn, stroke = {Transparency = 1}, isMovement = true}
	end
	for _, name in ipairs({"friends", "keybinds", "settings"}) do
		if mainNavBtns[name] then tabBtns[name] = {btn = mainNavBtns[name], stroke = {Transparency = 1}, isMain = true} end
	end
	return true
end