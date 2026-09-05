-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

-- La ventana se mueve desde el encabezado o la navegacion superior.
do
	local dragging, dragStart, startPos = false, nil, nil

	local function StartDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
		end
	end

	titleBar.InputBegan:Connect(StartDrag)
	topNav.InputBegan:Connect(StartDrag)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- Control de redimensionamiento en la esquina inferior derecha.
do
	local handleSize = isMobile and 36 or 30
	local resizeHandle = Instance.new("TextButton")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.new(0, handleSize, 0, handleSize)
	resizeHandle.Position = UDim2.new(1, -handleSize - 3, 1, -handleSize - 3)
	resizeHandle.BackgroundColor3 = currentTheme.tertiary
	resizeHandle.BackgroundTransparency = 0.72
	resizeHandle.AutoButtonColor = false
	resizeHandle.Text = ""
	resizeHandle.ZIndex = 100
	resizeHandle.Parent = main
	Instance.new("UICorner", resizeHandle).CornerRadius = UDim.new(0, 8)
	RegisterTheme(resizeHandle, "BackgroundColor3", "tertiary")

	for i = 0, 2 do
		local line = Instance.new("Frame")
		local length = 7 + (i * 5)
		line.Size = UDim2.new(0, length, 0, 2)
		line.AnchorPoint = Vector2.new(1, 0.5)
		line.Position = UDim2.new(1, -5, 1, -(6 + i * 4))
		line.Rotation = -45
		line.BorderSizePixel = 0
		line.BackgroundColor3 = currentTheme.textDim
		line.ZIndex = 101
		line.Parent = resizeHandle
		Instance.new("UICorner", line).CornerRadius = UDim.new(1, 0)
		RegisterTheme(line, "BackgroundColor3", "textDim")
	end

	resizeHandle.MouseEnter:Connect(function()
		TweenService:Create(resizeHandle, TweenInfo.new(0.15), {
			BackgroundTransparency = 0.3,
			BackgroundColor3 = currentTheme.secondary
		}):Play()
	end)
	resizeHandle.MouseLeave:Connect(function()
		TweenService:Create(resizeHandle, TweenInfo.new(0.15), {
			BackgroundTransparency = 0.72,
			BackgroundColor3 = currentTheme.tertiary
		}):Play()
	end)

	local resizing = false
	local resizeStart = nil
	local sizeStart = nil
	local lastRefreshAt = 0

	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			resizeStart = input.Position
			sizeStart = main.AbsoluteSize
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not resizing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then return end

		local delta = input.Position - resizeStart
		local minHeight = topNavH + (isMobile and 245 or 330)
		main.Size = UDim2.new(
			0, math.clamp(sizeStart.X + delta.X, 400, 1200),
			0, math.clamp(sizeStart.Y + delta.Y, minHeight, 800)
		)

		local now = tick()
		if now - lastRefreshAt >= 0.1 then
			lastRefreshAt = now
			if currentTab ~= "settings" then Refresh(false) end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not resizing then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false
			if currentTab ~= "settings" then Refresh(false) end
		end
	end)
end
	return true
end