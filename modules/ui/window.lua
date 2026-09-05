-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

TARGET_PC_CARD = 75
TARGET_MOBILE_CARD = 55

function GetDefaultSize()
	local PAD = isMobile and 4 or 6
	local targetCard = isMobile and TARGET_MOBILE_CARD or TARGET_PC_CARD
	
	local perfectWidth = (targetCard * 7) + (PAD * 6) + sideBarW + 20
	
	local vp = workspace.CurrentCamera.ViewportSize
	local finalW = math.clamp(perfectWidth * 1.12, math.min(400, vp.X * 0.95), vp.X * 0.95)
	
	local cardH = targetCard + (targetCard * 0.3 * 2) + PAD
	local perfectHeight = (cardH * 2) + 60 + bottomBarH + 20
	
	local tabCount = not isMobile and 7 or 6
	local minH = 8 + (tabBtnS + 6) * (tabCount - 1) + tabBtnS + 16
	local finalH = math.min(math.max(perfectHeight, minH) * 1.12, vp.Y * 0.95)
	
	return UDim2.new(0, finalW, 0, finalH)
end

main = Instance.new("Frame")
main.Name = "MainMenu"
main.Size = UDim2.new(0, 0, 0, 0)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = currentTheme.primary
main.BackgroundTransparency = 0
main.ClipsDescendants = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 20)
RegisterTheme(main, "BackgroundColor3", "primary")

ThemeGradients = {
	Dark        = {Color3.fromRGB(22, 22, 30),  Color3.fromRGB(10, 10, 14),  135},
	Purple      = {Color3.fromRGB(28, 18, 48),  Color3.fromRGB(10, 6, 18),   135},
	Blue        = {Color3.fromRGB(18, 28, 52),  Color3.fromRGB(6, 10, 20),   135},
	Green       = {Color3.fromRGB(16, 32, 22),  Color3.fromRGB(6, 12, 8),    135},
	Red         = {Color3.fromRGB(48, 16, 18),  Color3.fromRGB(18, 6, 8),    135},
	Light       = {Color3.fromRGB(255, 255, 255), Color3.fromRGB(228, 228, 238), 135},
	MaterialYou = {Color3.fromRGB(30, 34, 50),  Color3.fromRGB(12, 14, 20),  135},
	FrostedGlass= {Color3.fromRGB(230, 238, 255), Color3.fromRGB(190, 205, 235), 135},
	DarkGlass   = {Color3.fromRGB(24, 24, 34),  Color3.fromRGB(8, 8, 12),    135},
}

VexroAcrylic = (function()
	local api = {}
	local folder, body, mesh, dof
	local conns = {}

	local function disconnectAll()
		for _, conn in ipairs(conns) do
			pcall(function() conn:Disconnect() end)
		end
		conns = {}
	end

	function api.Stop()
		disconnectAll()
		if body then pcall(function() body:Destroy() end) end
		if folder then pcall(function() folder:Destroy() end) end
		if dof then pcall(function() dof:Destroy() end) end
		body, mesh, folder, dof = nil, nil, nil, nil
	end

	local function viewportPointToWorld(point, distance)
		local camera = workspace.CurrentCamera
		if not camera then return Vector3.new() end
		return camera:ViewportPointToRay(point.X, point.Y, distance).Origin
	end

	local function getViewportOffset()
		if gui.IgnoreGuiInset then
			local ok, inset = pcall(function()
				return game:GetService("GuiService"):GetGuiInset()
			end)
			if ok and inset then return inset end
		end
		return Vector2.new()
	end

	local function createBody()
		local part = Instance.new("Part")
		part.Name = "VexroGlassBody"
		part.Color = Color3.new(0, 0, 0)
		part.Material = Enum.Material.Glass
		part.Size = Vector3.new(1, 1, 0)
		part.Anchored = true
		part.CanCollide = false
		part.Locked = true
		part.CastShadow = false
		part.Transparency = 0.985

		local partMesh = Instance.new("SpecialMesh")
		partMesh.MeshType = Enum.MeshType.Brick
		partMesh.Offset = Vector3.new(0, 0, -0.000001)
		partMesh.Parent = part

		return part, partMesh
	end

	function api.Start(themeName)
		if isMobile then return end
		if body and body.Parent then
			if dof then
				dof.InFocusRadius = themeName == "FrostedGlass" and 0.08 or 0.12
				dof.NearIntensity = themeName == "FrostedGlass" and 0.85 or 1
			end
			body.Transparency = themeName == "FrostedGlass" and 0.985 or 0.99
			return
		end

		api.Stop()

		folder = Instance.new("Folder")
		folder.Name = "VexroGlassBlurFolder"
		folder.Parent = workspace

		body, mesh = createBody()
		body.Parent = folder

		dof = Instance.new("DepthOfFieldEffect")
		dof.Name = "VexroGlassBlur"
		dof.FarIntensity = 0
		dof.InFocusRadius = themeName == "FrostedGlass" and 0.08 or 0.12
		dof.NearIntensity = themeName == "FrostedGlass" and 0.85 or 1
		dof.Parent = game:GetService("Lighting")

		local positions = {
			topLeft = Vector2.new(),
			topRight = Vector2.new(),
			bottomRight = Vector2.new(),
		}

		local function updatePositions()
			local size = main.AbsoluteSize
			local inset = getViewportOffset()
			local pad = math.clamp(math.min(size.X, size.Y) * 0.035, 10, 18)
			local pos = main.AbsolutePosition + inset + Vector2.new(pad, pad)
			local clippedSize = Vector2.new(math.max(size.X - pad * 2, 1), math.max(size.Y - pad * 2, 1))
			positions.topLeft = pos
			positions.topRight = pos + Vector2.new(clippedSize.X, 0)
			positions.bottomRight = pos + clippedSize
		end

		local function render()
			if not body or not mesh or not main or not main.Parent then return end
			local camera = workspace.CurrentCamera
			if not camera then return end

			local size = main.AbsoluteSize
			if not gui.Enabled or not main.Visible or size.X <= 2 or size.Y <= 2 then
				body.Transparency = 1
				return
			end

			body.Transparency = themeName == "FrostedGlass" and 0.985 or 0.99
			updatePositions()

			local distance = 0.002
			local topLeft3D = viewportPointToWorld(positions.topLeft, distance)
			local topRight3D = viewportPointToWorld(positions.topRight, distance)
			local bottomRight3D = viewportPointToWorld(positions.bottomRight, distance)
			local width = (topRight3D - topLeft3D).Magnitude
			local height = (topRight3D - bottomRight3D).Magnitude

			body.CFrame = CFrame.fromMatrix(
				(topLeft3D + bottomRight3D) / 2,
				camera.CFrame.XVector,
				camera.CFrame.YVector,
				camera.CFrame.ZVector
			)
			mesh.Scale = Vector3.new(width, height, 0)
		end

		table.insert(conns, main:GetPropertyChangedSignal("AbsolutePosition"):Connect(render))
		table.insert(conns, main:GetPropertyChangedSignal("AbsoluteSize"):Connect(render))
		table.insert(conns, main:GetPropertyChangedSignal("Visible"):Connect(render))
		table.insert(conns, gui:GetPropertyChangedSignal("Enabled"):Connect(render))
		table.insert(conns, RunService.RenderStepped:Connect(render))
		table.insert(conns, main.Destroying:Connect(api.Stop))

		render()
	end

	return api
end)()

_glassApplyBase = ApplyTheme
ApplyTheme = function(name)
	_glassApplyBase(name)
	local isGlass = name == "FrostedGlass" or name == "DarkGlass"
	if isGlass then
		VexroAcrylic.Start(name)
	else
		VexroAcrylic.Stop()
	end
	TweenService:Create(main, TweenInfo.new(0.3), {BackgroundTransparency = isGlass and 0.18 or 0}):Play()
	local noiseOverlay = main:FindFirstChild("VexroGlassNoise")
	if isGlass then
		if not noiseOverlay then
			noiseOverlay = Instance.new("ImageLabel")
			noiseOverlay.Name = "VexroGlassNoise"
			noiseOverlay.Size = UDim2.new(1, 0, 1, 0)
			noiseOverlay.BackgroundTransparency = 1
			noiseOverlay.Image = "rbxassetid://9968344672"
			noiseOverlay.ScaleType = Enum.ScaleType.Tile
			noiseOverlay.TileSize = UDim2.new(0, 64, 0, 64)
			noiseOverlay.ZIndex = 1
			noiseOverlay.Parent = main
		end
		noiseOverlay.ImageTransparency = name == "FrostedGlass" and 0.82 or 0.88
	elseif noiseOverlay then
		noiseOverlay:Destroy()
	end
	local gradFrame = main:FindFirstChild("VexroGradFrame")
	if not gradFrame then
		gradFrame = Instance.new("Frame")
		gradFrame.Name = "VexroGradFrame"
		gradFrame.Size = UDim2.new(1, 0, 1, 0)
		gradFrame.BackgroundColor3 = Color3.new(1, 1, 1)
		gradFrame.BackgroundTransparency = 0
		gradFrame.BorderSizePixel = 0
		gradFrame.ZIndex = 1
		gradFrame.Parent = main
		Instance.new("UICorner", gradFrame).CornerRadius = UDim.new(0, 20)
		local grad = Instance.new("UIGradient")
		grad.Name = "VexroMainGrad"
		grad.Parent = gradFrame
	end
	TweenService:Create(gradFrame, TweenInfo.new(0.3), {BackgroundTransparency = isGlass and 0.45 or 0}):Play()
	local grad = gradFrame:FindFirstChild("VexroMainGrad")
	if grad then
		local g = ThemeGradients[name] or ThemeGradients.Dark
		grad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, g[1]),
			ColorSequenceKeypoint.new(1, g[2]),
		}
		grad.Rotation = g[3]
	end
end

mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.new(1, 1, 1)
mainStroke.Thickness = 3
mainStroke.Transparency = 0
mainStroke.Parent = main

mainStrokeGrad = Instance.new("UIGradient")
mainStrokeGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, currentTheme.stroke),
	ColorSequenceKeypoint.new(0.33, currentTheme.accent),
	ColorSequenceKeypoint.new(0.66, currentTheme.stroke),
	ColorSequenceKeypoint.new(1, currentTheme.accent)
}
mainStrokeGrad.Parent = mainStroke

task.spawn(function()
	local rot = 0
	while mainStroke.Parent do
		rot = rot + 360
		TweenService:Create(mainStrokeGrad, TweenInfo.new(6, Enum.EasingStyle.Linear), {Rotation = rot}):Play()
		task.wait(6)
	end
end)

bgParticles = Instance.new("Frame")
bgParticles.Name = "BgParticles"
bgParticles.Size = UDim2.new(1, 0, 1, 0)
bgParticles.BackgroundTransparency = 1
bgParticles.ZIndex = 1
bgParticles.Parent = main

for i = 1, 20 do
	local particle = Instance.new("Frame")
	local s = math.random(5, 12)
	particle.Size = UDim2.new(0, s, 0, s)
	particle.Position = UDim2.new(math.random(), 0, math.random(), 0)
	particle.BackgroundColor3 = currentTheme.accent
	particle.BackgroundTransparency = math.random(4, 8) / 10
	particle.ZIndex = 1
	particle.Parent = bgParticles
	Instance.new("UICorner", particle).CornerRadius = UDim.new(1, 0)
	
	RegisterTheme(particle, "BackgroundColor3", "accent")
	
	task.spawn(function()
		while particle.Parent do
			TweenService:Create(particle, TweenInfo.new(math.random(4, 8), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = UDim2.new(math.random(), 0, math.random(), 0)
			}):Play()
			task.wait(math.random(4, 8))
		end
	end)
end

-- ===============================================================
-- SIDEBAR
-- ===============================================================

	return true
end
