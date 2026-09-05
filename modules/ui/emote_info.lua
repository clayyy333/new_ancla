-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

infoPanel = Instance.new("Frame")
infoPanel.Name                   = "VexroInfoPanel"
infoPanel.Size                   = UDim2.new(0, 270, 0, 260)
infoPanel.Position               = UDim2.new(0, -290, 1, -285)
infoPanel.BackgroundColor3       = Color3.fromRGB(10, 10, 18)
infoPanel.BackgroundTransparency = 0.08
infoPanel.BorderSizePixel        = 0
infoPanel.Visible                = false
infoPanel.ZIndex                 = 700
infoPanel.Parent                 = gui
Instance.new("UICorner", infoPanel).CornerRadius = UDim.new(0, 14)

infoPanelStroke = Instance.new("UIStroke")
infoPanelStroke.Color       = currentTheme.accent
infoPanelStroke.Thickness   = 1.5
infoPanelStroke.Transparency = 0.30
infoPanelStroke.Parent      = infoPanel

infoPanelTitle = Instance.new("Frame")
infoPanelTitle.Size             = UDim2.new(1, 0, 0, 36)
infoPanelTitle.BackgroundColor3 = currentTheme.accent
infoPanelTitle.BackgroundTransparency = 0.55
infoPanelTitle.ZIndex           = 701
infoPanelTitle.Active           = true
infoPanelTitle.Parent           = infoPanel
Instance.new("UICorner", infoPanelTitle).CornerRadius = UDim.new(0, 14)
infoPanelTitleOverlay = Instance.new("Frame")
infoPanelTitleOverlay.Size             = UDim2.new(1, 0, 0, 14)
infoPanelTitleOverlay.Position         = UDim2.new(0, 0, 1, -14)
infoPanelTitleOverlay.BackgroundColor3 = currentTheme.accent
infoPanelTitleOverlay.BackgroundTransparency = 0.55
infoPanelTitleOverlay.BorderSizePixel  = 0
infoPanelTitleOverlay.ZIndex           = 701
infoPanelTitleOverlay.Parent           = infoPanelTitle

infoPanelTitleIcon = Instance.new("ImageLabel")
infoPanelTitleIcon.Size             = UDim2.new(0, 20, 0, 20)
infoPanelTitleIcon.Position         = UDim2.new(0, 10, 0.5, -10)
infoPanelTitleIcon.BackgroundTransparency = 1
infoPanelTitleIcon.Image            = ResolveAssetImage(Icons.Info)
infoPanelTitleIcon.ImageColor3      = Color3.new(1, 1, 1)
infoPanelTitleIcon.ZIndex           = 702
infoPanelTitleIcon.Parent           = infoPanelTitle

infoPanelTitleLbl = Instance.new("TextLabel")
infoPanelTitleLbl.Size                   = UDim2.new(1, -62, 1, 0)
infoPanelTitleLbl.Position               = UDim2.new(0, 36, 0, 0)
infoPanelTitleLbl.BackgroundTransparency = 1
infoPanelTitleLbl.Text                   = L.infoTitle
infoPanelTitleLbl.TextColor3             = Color3.new(1, 1, 1)
infoPanelTitleLbl.Font                   = Enum.Font.GothamBold
infoPanelTitleLbl.TextSize               = 14
infoPanelTitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
infoPanelTitleLbl.ZIndex                 = 702
infoPanelTitleLbl.Parent                 = infoPanelTitle

infoPanelClose = Instance.new("TextButton")
infoPanelClose.Size             = UDim2.new(0, 24, 0, 24)
infoPanelClose.Position         = UDim2.new(1, -30, 0.5, -12)
infoPanelClose.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
infoPanelClose.BackgroundTransparency = 0.30
infoPanelClose.Text             = ""
infoPanelClose.ZIndex           = 703
infoPanelClose.Parent           = infoPanelTitle
Instance.new("UICorner", infoPanelClose).CornerRadius = UDim.new(1, 0)

do
	local thick = 2
	local lineLen = 10
	local cl1 = Instance.new("Frame")
	cl1.BorderSizePixel = 0
	cl1.Size       = UDim2.new(0, lineLen, 0, thick)
	cl1.AnchorPoint = Vector2.new(0.5, 0.5)
	cl1.Position   = UDim2.fromScale(0.5, 0.5)
	cl1.Rotation   = 45
	cl1.BackgroundColor3 = Color3.new(1, 1, 1)
	cl1.ZIndex     = 704
	cl1.Parent     = infoPanelClose
	Instance.new("UICorner", cl1).CornerRadius = UDim.new(0, 2)
	local cl2 = cl1:Clone()
	cl2.Rotation  = -45
	cl2.Parent    = infoPanelClose
end

infoPanelBody = Instance.new("Frame")
infoPanelBody.Size                   = UDim2.new(1, -24, 1, -46)
infoPanelBody.Position               = UDim2.new(0, 12, 0, 42)
infoPanelBody.BackgroundTransparency = 1
infoPanelBody.ZIndex                 = 701
infoPanelBody.Parent                 = infoPanel

infoEmoteName = Instance.new("TextLabel")
infoEmoteName.Size                   = UDim2.new(1, 0, 0, 22)
infoEmoteName.Position               = UDim2.new(0, 0, 0, 0)
infoEmoteName.BackgroundTransparency = 1
infoEmoteName.Text                   = "—"
infoEmoteName.TextColor3             = Color3.new(1, 1, 1)
infoEmoteName.Font                   = Enum.Font.GothamBold
infoEmoteName.TextSize               = 16
infoEmoteName.TextXAlignment         = Enum.TextXAlignment.Left
infoEmoteName.TextTruncate           = Enum.TextTruncate.AtEnd
infoEmoteName.ZIndex                 = 702
infoEmoteName.Parent                 = infoPanelBody

infoDescLbl = Instance.new("TextLabel")
infoDescLbl.Size                   = UDim2.new(1, 0, 0, 28)
infoDescLbl.Position               = UDim2.new(0, 0, 0, 24)
infoDescLbl.BackgroundTransparency = 1
infoDescLbl.Text                   = "—"
infoDescLbl.TextColor3             = Color3.fromRGB(140, 140, 165)
infoDescLbl.Font                   = Enum.Font.Gotham
infoDescLbl.TextSize               = 11
infoDescLbl.TextXAlignment         = Enum.TextXAlignment.Left
infoDescLbl.TextYAlignment         = Enum.TextYAlignment.Top
infoDescLbl.TextWrapped            = true
infoDescLbl.ZIndex                 = 702
infoDescLbl.Parent                 = infoPanelBody

infoDivider = Instance.new("Frame")
infoDivider.Size             = UDim2.new(1, 0, 0, 1)
infoDivider.Position         = UDim2.new(0, 0, 0, 56)
infoDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
infoDivider.BorderSizePixel  = 0
infoDivider.ZIndex           = 702
infoDivider.Parent           = infoPanelBody

do
	local ic = Instance.new("ImageLabel")
	ic.Size = UDim2.new(0, 13, 0, 13); ic.Position = UDim2.new(0, 0, 0, 63)
	ic.BackgroundTransparency = 1; ic.Image = Icons.Crown; ic.ZIndex = 702
	ic.Parent = infoPanelBody
end
infoCreatorLbl = Instance.new("TextLabel")
infoCreatorLbl.Size                   = UDim2.new(1, -18, 0, 16)
infoCreatorLbl.Position               = UDim2.new(0, 18, 0, 61)
infoCreatorLbl.BackgroundTransparency = 1
infoCreatorLbl.Text                   = "—"
infoCreatorLbl.TextColor3             = Color3.fromRGB(140, 200, 255)
infoCreatorLbl.Font                   = Enum.Font.Gotham
infoCreatorLbl.TextSize               = 12
infoCreatorLbl.TextXAlignment         = Enum.TextXAlignment.Left
infoCreatorLbl.ZIndex                 = 702
infoCreatorLbl.Parent                 = infoPanelBody

do
	local ic = Instance.new("ImageLabel")
	ic.Size = UDim2.new(0, 13, 0, 13); ic.Position = UDim2.new(0, 0, 0, 83)
	ic.BackgroundTransparency = 1; ic.Image = Icons.Emote; ic.ZIndex = 702
	ic.Parent = infoPanelBody
end
infoSpeedLbl = Instance.new("TextLabel")
infoSpeedLbl.Size                   = UDim2.new(1, -18, 0, 16)
infoSpeedLbl.Position               = UDim2.new(0, 18, 0, 81)
infoSpeedLbl.BackgroundTransparency = 1
infoSpeedLbl.Text                   = L.speed .. ": 1x"
infoSpeedLbl.TextColor3             = Color3.fromRGB(160, 160, 185)
infoSpeedLbl.Font                   = Enum.Font.Gotham
infoSpeedLbl.TextSize               = 12
infoSpeedLbl.TextXAlignment         = Enum.TextXAlignment.Left
infoSpeedLbl.ZIndex                 = 702
infoSpeedLbl.Parent                 = infoPanelBody

_onSpeedChanged = function()
	RefreshHUDSpeedBtns()
	if infoSpeedLbl then
		infoSpeedLbl.Text = L.speed .. ": " .. tostring(Settings.speed) .. "x"
	end
end

infoPriceLbl = Instance.new("TextLabel")
infoPriceLbl.Size                   = UDim2.new(1, 0, 0, 16)
infoPriceLbl.Position               = UDim2.new(0, 0, 0, 101)
infoPriceLbl.BackgroundTransparency = 1
infoPriceLbl.Text                   = "—"
infoPriceLbl.TextColor3             = Color3.fromRGB(160, 160, 185)
infoPriceLbl.Font                   = Enum.Font.GothamBold
infoPriceLbl.TextSize               = 12
infoPriceLbl.TextXAlignment         = Enum.TextXAlignment.Left
infoPriceLbl.ZIndex                 = 702
infoPriceLbl.Parent                 = infoPanelBody

infoFavLbl = Instance.new("TextLabel")
infoFavLbl.Size                   = UDim2.new(1, 0, 0, 16)
infoFavLbl.Position               = UDim2.new(0, 0, 0, 120)
infoFavLbl.BackgroundTransparency = 1
infoFavLbl.Text                   = "—"
infoFavLbl.TextColor3             = Color3.fromRGB(160, 160, 185)
infoFavLbl.Font                   = Enum.Font.Gotham
infoFavLbl.TextSize               = 12
infoFavLbl.TextXAlignment         = Enum.TextXAlignment.Left
infoFavLbl.ZIndex                 = 702
infoFavLbl.Parent                 = infoPanelBody

do
	local ic = Instance.new("ImageLabel")
	ic.Size = UDim2.new(0, 13, 0, 13); ic.Position = UDim2.new(0, 0, 0, 141)
	ic.BackgroundTransparency = 1; ic.Image = Icons.Recent; ic.ZIndex = 702
	ic.Parent = infoPanelBody
end
infoDateLbl = Instance.new("TextLabel")
infoDateLbl.Size                   = UDim2.new(1, -18, 0, 16)
infoDateLbl.Position               = UDim2.new(0, 18, 0, 139)
infoDateLbl.BackgroundTransparency = 1
infoDateLbl.Text                   = "—"
infoDateLbl.TextColor3             = Color3.fromRGB(130, 130, 155)
infoDateLbl.Font                   = Enum.Font.Gotham
infoDateLbl.TextSize               = 11
infoDateLbl.TextXAlignment         = Enum.TextXAlignment.Left
infoDateLbl.ZIndex                 = 702
infoDateLbl.Parent                 = infoPanelBody





copyIdBtn = Instance.new("TextButton")
copyIdBtn.Size             = UDim2.new(0.52, -2, 0, 26)
copyIdBtn.Position         = UDim2.new(0.48, 2, 0, 161)
copyIdBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
copyIdBtn.Text             = L.copyId
copyIdBtn.TextColor3       = Color3.fromRGB(180, 180, 210)
copyIdBtn.Font             = Enum.Font.GothamBold
copyIdBtn.TextSize         = 12
copyIdBtn.ZIndex           = 703
copyIdBtn.Parent           = infoPanelBody
Instance.new("UICorner", copyIdBtn).CornerRadius = UDim.new(0, 8)
copyIdStroke = Instance.new("UIStroke")
copyIdStroke.Color       = Color3.fromRGB(70, 70, 100)
copyIdStroke.Thickness   = 1
copyIdStroke.Parent      = copyIdBtn

infoIdLbl = nil

infoPanelOpen = false
INFO_OPEN_POS  = UDim2.new(0, 10, 1, -285)
INFO_CLOSE_POS = UDim2.new(0, -290, 1, -285)

_copyIdTarget = 0

function _applyMetaToInfoPanel(meta)
	infoCreatorLbl.Text = (meta.creatorName and meta.creatorName ~= "") and meta.creatorName or "—"
	infoDescLbl.Text    = (meta.description and meta.description ~= "") and meta.description or L.noDesc
	if meta.priceStatus == "Free" or meta.price == 0 then
		infoPriceLbl.Text       = L.freePrice
		infoPriceLbl.TextColor3 = Color3.fromRGB(100, 220, 130)
	elseif meta.price and meta.price > 0 then
		infoPriceLbl.Text       = tostring(meta.price) .. " R$"
		infoPriceLbl.TextColor3 = Color3.fromRGB(255, 200, 80)
	else
		infoPriceLbl.Text       = (meta.priceStatus and meta.priceStatus ~= "") and meta.priceStatus or "—"
		infoPriceLbl.TextColor3 = Color3.fromRGB(160, 160, 185)
	end
	infoFavLbl.Text = meta.favoriteCount
		and ("♥ " .. tostring(meta.favoriteCount))
		or "—"
	if meta.createdUtc and meta.createdUtc ~= "" then
		infoDateLbl.Text = meta.createdUtc:sub(1, 10)
	else
		infoDateLbl.Text = "—"
	end
	hudCreator.Text = (meta.creatorName and meta.creatorName ~= "") and meta.creatorName or "Emotes"
end

function _fetchAndCacheMeta(numId, targetId)
	local ok, info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(numId)
	end)
	if not ok or not info then return end

	local price      = info.PriceInRobux
	local isFree     = info.IsPublicDomain or (price and price == 0)
	local isNotSale  = info.IsForSale == false and not isFree

	local meta = {
		creatorName   = tostring((info.Creator and info.Creator.Name) or ""),
		description   = tostring(info.Description or ""),
		price         = isFree and 0 or price,
		priceStatus   = isFree and "Free" or (isNotSale and "Not for sale" or ""),
		favoriteCount = nil,
		createdUtc    = "",
	}

	_emoteMetaCache[numId] = meta

	local eData = EmotesById[numId]
	if eData then
		eData.creatorName   = meta.creatorName
		eData.description   = meta.description
		eData.price         = meta.price
		eData.priceStatus   = meta.priceStatus
		eData.favoriteCount = meta.favoriteCount
		eData.createdUtc    = meta.createdUtc
	end

	if infoPanelOpen and _copyIdTarget == numId then
		_applyMetaToInfoPanel(meta)
	end
end

function OpenInfoPanel(emoteId, emoteName)
	infoEmoteName.Text  = emoteName or "—"
	infoSpeedLbl.Text   = L.speed .. ": " .. tostring(Settings.speed) .. "x"
	infoPanelStroke.Color           = currentTheme.accent
	infoPanelTitle.BackgroundColor3 = currentTheme.accent
	_copyIdTarget = tonumber(emoteId) or 0

	local numId = tonumber(emoteId)

	local meta = _emoteMetaCache[numId]
	if not meta then
		local eData = EmotesById[numId]
		if eData and eData.creatorName ~= "" then
			meta = eData
		end
	end

	if meta then
		_applyMetaToInfoPanel(meta)
	else
		infoCreatorLbl.Text = "…"
		infoDescLbl.Text    = "…"
		infoPriceLbl.Text   = "…"
		infoPriceLbl.TextColor3 = Color3.fromRGB(160, 160, 185)
		infoFavLbl.Text     = "…"
		infoDateLbl.Text    = "…"
		hudCreator.Text     = "Emotes"
		if numId and numId > 0 then
			task.spawn(_fetchAndCacheMeta, numId, numId)
		end
	end

	copyIdBtn.Text = L.copyId .. ": " .. tostring(numId)

	infoPanel.Position = INFO_CLOSE_POS
	infoPanel.Visible  = true
	infoPanelOpen      = true
	TweenService:Create(infoPanel,
		TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = INFO_OPEN_POS}
	):Play()
	TweenService:Create(hudInfoBtn, TweenInfo.new(0.15),
		{BackgroundTransparency = 0.05}):Play()
end

copyIdBtn.MouseButton1Click:Connect(function()
	pcall(function()
		if setclipboard then
			setclipboard(tostring(_copyIdTarget))
		end
	end)
	local orig = copyIdBtn.Text
	copyIdBtn.Text            = L.copied
	copyIdBtn.TextColor3      = Color3.fromRGB(100, 220, 130)
	task.delay(1.5, function()
		copyIdBtn.Text       = orig
		copyIdBtn.TextColor3 = Color3.fromRGB(180, 180, 210)
	end)
end)

function CloseInfoPanel()
	infoPanelOpen = false
	local curX = infoPanel.AbsolutePosition.X
	local curY = infoPanel.AbsolutePosition.Y
	local exitPos = UDim2.new(0, curX - 300, 0, curY)
	TweenService:Create(infoPanel,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Position = exitPos}
	):Play()
	TweenService:Create(hudInfoBtn, TweenInfo.new(0.15),
		{BackgroundTransparency = 0.40}):Play()
	task.delay(0.22, function()
		if not infoPanelOpen then infoPanel.Visible = false end
	end)
end

hudInfoBtn.MouseButton1Click:Connect(function()
	if infoPanelOpen then
		CloseInfoPanel()
	else
		OpenInfoPanel(_currentInfoId or 0, _currentInfoName or "Emote")
	end
end)
infoPanelClose.MouseButton1Click:Connect(CloseInfoPanel)

_ipDragActive     = false
_ipDragMouseStart = Vector2.zero
_ipDragPanelStart = Vector2.zero

infoPanelTitle.InputBegan:Connect(function(inp)
	if inp.UserInputType ~= Enum.UserInputType.MouseButton1
	and inp.UserInputType ~= Enum.UserInputType.Touch then return end
	_ipDragActive     = true
	_ipDragMouseStart = Vector2.new(inp.Position.X, inp.Position.Y)
	_ipDragPanelStart = Vector2.new(
		infoPanel.AbsolutePosition.X,
		infoPanel.AbsolutePosition.Y
	)
end)

UserInputService.InputChanged:Connect(function(inp)
	if not _ipDragActive then return end
	if inp.UserInputType ~= Enum.UserInputType.MouseMovement
	and inp.UserInputType ~= Enum.UserInputType.Touch then return end
	local delta = Vector2.new(inp.Position.X, inp.Position.Y) - _ipDragMouseStart
	infoPanel.Position = UDim2.new(0, _ipDragPanelStart.X + delta.X,
	                               0, _ipDragPanelStart.Y + delta.Y)
end)

UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1
	or inp.UserInputType == Enum.UserInputType.Touch then
		_ipDragActive = false
	end
end)

	return true
end
