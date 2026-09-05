-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

	-- Categoria principal.
	topNav = Instance.new("Frame")
	topNav.Name = "TopNavigation"
	topNav.Size = UDim2.new(1, 0, 0, topNavH)
	topNav.BackgroundColor3 = currentTheme.sidebar
	topNav.ZIndex = 20
	topNav.Parent = main
	Instance.new("UICorner", topNav).CornerRadius = UDim.new(0, 14)
	RegisterTheme(topNav, "BackgroundColor3", "sidebar")

	mainNav = Instance.new("Frame")
	mainNav.Size = UDim2.new(1, -16, 1, -12)
	mainNav.Position = UDim2.new(0, 8, 0, 6)
	mainNav.BackgroundTransparency = 1
	mainNav.ZIndex = 21
	mainNav.Parent = topNav

	-- Navegacion interna de Movimientos.
	movementNav = Instance.new("Frame")
	movementNav.Name = "MovementNavigation"
	movementNav.Size = UDim2.new(0, sideBarW, 1, -topNavH)
	movementNav.Position = UDim2.new(0, 0, 0, topNavH)
	movementNav.BackgroundColor3 = currentTheme.sidebar
	movementNav.ClipsDescendants = true
	movementNav.ZIndex = 18
	movementNav.Parent = main
	Instance.new("UICorner", movementNav).CornerRadius = UDim.new(0, 14)
	RegisterTheme(movementNav, "BackgroundColor3", "sidebar")

	local sideOverlay = Instance.new("Frame")
	sideOverlay.Size = UDim2.new(0, 10, 1, 0)
	sideOverlay.Position = UDim2.new(1, -10, 0, 0)
	sideOverlay.BackgroundColor3 = currentTheme.sidebar
	sideOverlay.BorderSizePixel = 0
	sideOverlay.ZIndex = 17
	sideOverlay.Parent = movementNav
	RegisterTheme(sideOverlay, "BackgroundColor3", "sidebar")

	mainNavBtns, tabBtns = {}, {}

	local function CreateTextButton(parent, text, name, size, position)
		local btn = Instance.new("TextButton")
		btn.Name = name .. "Button"
		btn.Size = size
		btn.Position = position
		btn.BackgroundColor3 = currentTheme.sidebar
		btn.BackgroundTransparency = 1
		btn.AutoButtonColor = false
		btn.Text = text
		btn.TextColor3 = currentTheme.text
		btn.TextSize = isMobile and 12 or 14
		btn.TextWrapped = true
		btn.Font = Enum.Font.GothamMedium
		btn.ZIndex = 20
		btn.Parent = parent
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
		if parent == movementNav then
			btn.TextXAlignment = Enum.TextXAlignment.Left
			local textPadding = Instance.new("UIPadding")
			textPadding.PaddingLeft = UDim.new(0, isMobile and 10 or 14)
			textPadding.Parent = btn
		end

		local stroke = Instance.new("UIStroke")
		stroke.Color = currentTheme.stroke
		stroke.Thickness = 1.5
		stroke.Transparency = 1
		stroke.Parent = btn

		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Enabled = false
		gradient.Parent = btn
		RegisterTheme(btn, "TextColor3", "text")
		btn.MouseEnter:Connect(function()
			if name ~= "movements" and currentTab ~= name then
				TweenService:Create(btn, TweenInfo.new(0.15), {
					BackgroundTransparency = 0.55,
					BackgroundColor3 = currentTheme.tertiary
				}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if UpdateTabStyles then UpdateTabStyles() end
		end)
		return btn, stroke, gradient
	end

	local topBtn, topStroke, topGradient = CreateTextButton(
		mainNav, L.movements, "movements",
		UDim2.new(0, isMobile and 118 or 150, 1, 0),
		UDim2.new(0, 0, 0, 0)
	)
	topBtn.Font = Enum.Font.GothamBold
	topBtn.TextSize = isMobile and 14 or 16
	mainNavBtns.movements = topBtn
	mainNavButtonStyle = {btn = topBtn, stroke = topStroke, gradient = topGradient}

	local labels = {
		{"emotes", L.emotes},
		{"animations", L.animations},
		{"favorites", L.favorites},
		{"recent", L.recent},
		{"friends", L.friendTab},
	}
	if not isMobile then table.insert(labels, {"keybinds", L.keybinds}) end
	table.insert(labels, {"settings", L.settings})

	local pad = isMobile and 5 or 7
	local gap = isMobile and 4 or 6
	local buttonH = isMobile and 34 or 40
	for index, item in ipairs(labels) do
		local btn, stroke, gradient = CreateTextButton(
			movementNav, item[2], item[1],
			UDim2.new(1, -(pad * 2), 0, buttonH),
			UDim2.new(0, pad, 0, pad + (index - 1) * (buttonH + gap))
		)
		tabBtns[item[1]] = {btn = btn, stroke = stroke, gradient = gradient}
	end

	return true
end