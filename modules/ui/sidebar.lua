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

	mainNav = Instance.new("ScrollingFrame")
	mainNav.Name = "TopNavigationTabs"
	mainNav.Size = UDim2.new(1, -(isMobile and 96 or 112), 1, -12)
	mainNav.Position = UDim2.new(0, 8, 0, 6)
	mainNav.BackgroundTransparency = 1
	mainNav.BorderSizePixel = 0
	mainNav.ScrollBarThickness = 0
	mainNav.Active = true
	mainNav.ScrollingDirection = Enum.ScrollingDirection.X
	mainNav.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
	mainNav.CanvasSize = UDim2.new(0, isMobile and 488 or 602, 0, 0)
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

	fling2Nav = Instance.new("Frame")
	fling2Nav.Name = "Fling2Navigation"
	fling2Nav.Size = UDim2.new(0, sideBarW, 1, -topNavH)
	fling2Nav.Position = UDim2.new(0, 0, 0, topNavH)
	fling2Nav.BackgroundColor3 = currentTheme.sidebar
	fling2Nav.ClipsDescendants = true
	fling2Nav.Visible = false
	fling2Nav.ZIndex = 18
	fling2Nav.Parent = main
	Instance.new("UICorner", fling2Nav).CornerRadius = UDim.new(0, 14)
	RegisterTheme(fling2Nav, "BackgroundColor3", "sidebar")
	local fling2Overlay = Instance.new("Frame")
	fling2Overlay.Size = UDim2.new(0, 10, 1, 0)
	fling2Overlay.Position = UDim2.new(1, -10, 0, 0)
	fling2Overlay.BackgroundColor3 = currentTheme.sidebar
	fling2Overlay.BorderSizePixel = 0
	fling2Overlay.ZIndex = 17
	fling2Overlay.Parent = fling2Nav
	RegisterTheme(fling2Overlay, "BackgroundColor3", "sidebar")

	anchorNav = Instance.new("Frame")
	anchorNav.Name = "AnchorNavigation"
	anchorNav.Size = UDim2.new(0, sideBarW, 1, -topNavH)
	anchorNav.Position = UDim2.new(0, 0, 0, topNavH)
	anchorNav.BackgroundColor3 = currentTheme.sidebar
	anchorNav.ClipsDescendants = true
	anchorNav.Visible = false
	anchorNav.ZIndex = 18
	anchorNav.Parent = main
	Instance.new("UICorner", anchorNav).CornerRadius = UDim.new(0, 14)
	RegisterTheme(anchorNav, "BackgroundColor3", "sidebar")
	local anchorOverlay = Instance.new("Frame")
	anchorOverlay.Size = UDim2.new(0, 10, 1, 0)
	anchorOverlay.Position = UDim2.new(1, -10, 0, 0)
	anchorOverlay.BackgroundColor3 = currentTheme.sidebar
	anchorOverlay.BorderSizePixel = 0
	anchorOverlay.ZIndex = 17
	anchorOverlay.Parent = anchorNav
	RegisterTheme(anchorOverlay, "BackgroundColor3", "sidebar")

	controlNav = Instance.new("Frame")
	controlNav.Name = "ControlNavigation"
	controlNav.Size = UDim2.new(0, sideBarW, 1, -topNavH)
	controlNav.Position = UDim2.new(0, 0, 0, topNavH)
	controlNav.BackgroundColor3 = currentTheme.sidebar
	controlNav.ClipsDescendants = true
	controlNav.Visible = false
	controlNav.ZIndex = 18
	controlNav.Parent = main
	Instance.new("UICorner", controlNav).CornerRadius = UDim.new(0, 14)
	RegisterTheme(controlNav, "BackgroundColor3", "sidebar")
	local controlOverlay = Instance.new("Frame")
	controlOverlay.Size = UDim2.new(0, 10, 1, 0)
	controlOverlay.Position = UDim2.new(1, -10, 0, 0)
	controlOverlay.BackgroundColor3 = currentTheme.sidebar
	controlOverlay.BorderSizePixel = 0
	controlOverlay.ZIndex = 17
	controlOverlay.Parent = controlNav
	RegisterTheme(controlOverlay, "BackgroundColor3", "sidebar")

	couplesNav=controlNav:Clone();couplesNav.Name="CouplesNavigation";couplesNav.Visible=false;couplesNav.Parent=main;for _,v in ipairs(couplesNav:GetChildren()) do v:Destroy() end
	Instance.new("UICorner",couplesNav).CornerRadius=UDim.new(0,14);RegisterTheme(couplesNav,"BackgroundColor3","sidebar")

	mainNavBtns, tabBtns, fling2TabBtns, anchorTabBtns, controlTabBtns, couplesTabBtns = {}, {}, {}, {}, {}, {}

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
		if parent == movementNav or parent == fling2Nav or parent == anchorNav or parent == controlNav or parent == couplesNav then
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

	local fling2Btn, fling2Stroke, fling2Gradient = CreateTextButton(
		mainNav, "Fling 2", "fling2",
		UDim2.new(0, isMobile and 86 or 105, 1, 0),
		UDim2.new(0, isMobile and 126 or 158, 0, 0)
	)
	fling2Btn.Font = Enum.Font.GothamBold
	fling2Btn.TextSize = isMobile and 14 or 16
	mainNavBtns.fling2 = fling2Btn
	fling2NavButtonStyle = {btn = fling2Btn, stroke = fling2Stroke, gradient = fling2Gradient}

	local anchorBtn, anchorStroke, anchorGradient = CreateTextButton(
		mainNav, isES and "Ancla" or "Anchor", "anchor",
		UDim2.new(0, isMobile and 86 or 105, 1, 0),
		UDim2.new(0, isMobile and 218 or 271, 0, 0)
	)
	anchorBtn.Font = Enum.Font.GothamBold
	anchorBtn.TextSize = isMobile and 14 or 16
	mainNavBtns.anchor = anchorBtn
	anchorNavButtonStyle = {btn = anchorBtn, stroke = anchorStroke, gradient = anchorGradient}

	local controlBtn, controlStroke, controlGradient = CreateTextButton(
		mainNav, isES and "Control" or "Control", "control",
		UDim2.new(0, isMobile and 86 or 105, 1, 0),
		UDim2.new(0, isMobile and 310 or 384, 0, 0)
	)
	controlBtn.Font = Enum.Font.GothamBold
	controlBtn.TextSize = isMobile and 14 or 16
	mainNavBtns.control = controlBtn
	controlNavButtonStyle = {btn = controlBtn, stroke = controlStroke, gradient = controlGradient}

	local couplesBtn, couplesStroke, couplesGradient = CreateTextButton(
		mainNav, isES and "Parejas" or "Couples", "couples",
		UDim2.new(0, isMobile and 86 or 105, 1, 0),
		UDim2.new(0, isMobile and 402 or 497, 0, 0)
	)
	couplesBtn.Font = Enum.Font.GothamBold
	couplesBtn.TextSize = isMobile and 14 or 16
	mainNavBtns.couples = couplesBtn
	couplesNavButtonStyle = {btn = couplesBtn, stroke = couplesStroke, gradient = couplesGradient}

	-- El tacto usa el desplazamiento nativo; en PC se puede arrastrar con el mouse.
	mainNavDragSuppressUntil = 0
	local dragStartX, dragStartCanvas, dragInput, dragged
	local function beginTabDrag(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		dragStartX = input.Position.X
		dragStartCanvas = mainNav.CanvasPosition.X
		dragInput = input
		dragged = false
	end
	mainNav.InputBegan:Connect(beginTabDrag)
	for _, button in pairs(mainNavBtns) do button.InputBegan:Connect(beginTabDrag) end
	UserInputService.InputChanged:Connect(function(input)
		if not dragInput or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local delta = input.Position.X - dragStartX
		if math.abs(delta) > 5 and mainNav.AbsoluteCanvasSize.X > mainNav.AbsoluteSize.X then dragged = true end
		if dragged then
			local maxScroll = math.max(0, mainNav.AbsoluteCanvasSize.X - mainNav.AbsoluteSize.X)
			mainNav.CanvasPosition = Vector2.new(math.clamp(dragStartCanvas - delta, 0, maxScroll), 0)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if dragInput and input.UserInputType == Enum.UserInputType.MouseButton1 then
			if dragged then mainNavDragSuppressUntil = os.clock() + 0.15 end
			dragInput = nil
		end
	end)

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

	local flingLabels = {
		{"fling2", "Fling"},
		{"contact_fling", isES and "Fling por contacto" or "Contact Fling"},
		{"fling_car", isES and "Fling con vehículo" or "Fling with Car"},
		{"fling_car2", isES and "Fling con vehículo 2" or "Fling with Car 2"},
		{"fling_object", isES and "Fling con objeto" or "Object Fling"},
		{"fling_moto", isES and "Fling con moto Delta" or "Delta Motorcycle Fling"},
		{"fling_moto_xeno", isES and "Fling con moto Xeno" or "Xeno Motorcycle Fling"},
	}
	for index, item in ipairs(flingLabels) do
		local btn, stroke, gradient = CreateTextButton(
			fling2Nav, item[2], item[1],
			UDim2.new(1, -(pad * 2), 0, buttonH),
			UDim2.new(0, pad, 0, pad + (index - 1) * (buttonH + gap))
		)
		fling2TabBtns[item[1]] = {btn = btn, stroke = stroke, gradient = gradient}
	end

	local anchorLabels = {
		{"anchor", isES and "Ancla" or "Anchor"},
		{"anchor_auto", isES and "Ancla automática" or "Automatic Anchor"},
	}
	for index, item in ipairs(anchorLabels) do
		local btn, stroke, gradient = CreateTextButton(
			anchorNav, item[2], item[1],
			UDim2.new(1, -(pad * 2), 0, buttonH),
			UDim2.new(0, pad, 0, pad + (index - 1) * (buttonH + gap))
		)
		anchorTabBtns[item[1]] = {btn = btn, stroke = stroke, gradient = gradient}
	end

	local controlLabels = {
		{"camera_control", isES and "Perspectiva Cámara" or "Camera Perspective"},
		{"flight_control", isES and "Control de vuelo" or "Flight Control"},
		{"car_control", isES and "Control de auto" or "Car Control"},
		{"free_car_control", isES and "Control de auto libre" or "Free Car Control"},
		{"movement_control", isES and "Control de velocidad" or "Speed Control"},
		{"vertical_control", isES and "Desplazamiento vertical" or "Vertical Displacement"},
	}
	for index, item in ipairs(controlLabels) do
		local btn, stroke, gradient = CreateTextButton(
			controlNav, item[2], item[1],
			UDim2.new(1, -(pad * 2), 0, buttonH),
			UDim2.new(0, pad, 0, pad + (index - 1) * (buttonH + gap))
		)
		controlTabBtns[item[1]] = {btn = btn, stroke = stroke, gradient = gradient}
	end

	local coupleLabels={{"preset_poses",isES and "Poses predeterminadas" or "Preset poses"},{"couples",isES and "Ubicación de cuerpo" or "Body location"},{"couple_movement",isES and "Control de movimiento" or "Movement control"},{"poses","Poses"}}
	for index,item in ipairs(coupleLabels)do local btn,stroke,gradient=CreateTextButton(couplesNav,item[2],item[1],UDim2.new(1,-(pad*2),0,buttonH),UDim2.new(0,pad,0,pad+(index-1)*(buttonH+gap)));couplesTabBtns[item[1]]={btn=btn,stroke=stroke,gradient=gradient}end

	return true
end
