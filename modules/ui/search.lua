-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

-- Trending Dropdown UI
trendingDropdown = Instance.new("Frame")
trendingDropdown.Name = "VexroTrendingDropdown"
trendingDropdown.Size = UDim2.new(1, -16, 0, 0)
trendingDropdown.Position = UDim2.new(0, 8, 0, titleH + 6 + searchH + 2)
trendingDropdown.BackgroundColor3 = currentTheme.secondary
trendingDropdown.ZIndex = 250
trendingDropdown.Visible = false
trendingDropdown.ClipsDescendants = true
trendingDropdown.Parent = content
Instance.new("UICorner", trendingDropdown).CornerRadius = UDim.new(0, 8)
dropdownStroke = Instance.new("UIStroke")
dropdownStroke.Color = currentTheme.accent
dropdownStroke.Thickness = 1.5
dropdownStroke.Transparency = 0.4
dropdownStroke.Parent = trendingDropdown
RegisterTheme(trendingDropdown, "BackgroundColor3", "secondary")
RegisterTheme(dropdownStroke, "Color", "accent")

dropdownLayout = Instance.new("UIListLayout")
dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropdownLayout.Padding = UDim.new(0, 2)
dropdownLayout.Parent = trendingDropdown

_cachedTrending = {"TikTok", "Chill", "Korobeiniki", "Dance", "Catalog"}
_lastRecordedQuery = ""
_lastRecordedAt = 0

function canShowTrendingDropdown()
	return currentTab ~= "settings"
		and currentTab ~= "friends"
		and currentTab ~= "keybinds"
		and currentTab ~= "favorites"
		and currentTab ~= "recent"
end

function hideTrendingDropdown()
	if not trendingDropdown then return end
	trendingDropdown.Visible = false
	trendingDropdown.Size = UDim2.new(1, -16, 0, 0)
	for _, child in ipairs(trendingDropdown:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

function populateTrendingDropdown(trendingItems)
	if not canShowTrendingDropdown() then
		hideTrendingDropdown()
		return
	end

	for _, child in ipairs(trendingDropdown:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	if not trendingItems or #trendingItems == 0 then
		trendingItems = _cachedTrending
	else
		_cachedTrending = trendingItems
	end

	local itemH = 30
	trendingDropdown.Size = UDim2.new(1, -16, 0, #trendingItems * (itemH + 2) + 4)

	for _, query in ipairs(trendingItems) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -8, 0, itemH)
		btn.Position = UDim2.new(0, 4, 0, 0)
		btn.BackgroundColor3 = currentTheme.tertiary
		btn.BackgroundTransparency = 1
		btn.Text = "        " .. query
		btn.TextColor3 = currentTheme.text
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 13
		btn.ZIndex = 251
		btn.Parent = trendingDropdown
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		RegisterTheme(btn, "TextColor3", "text")

		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, 16, 0, 16)
		icon.Position = UDim2.new(0, 8, 0.5, -8)
		icon.BackgroundTransparency = 1
		icon.Image = "rbxthumb://type=Asset&id=129818530869054&w=150&h=150"
		icon.ImageColor3 = currentTheme.accent
		icon.ZIndex = 252
		icon.Parent = btn
		RegisterTheme(icon, "ImageColor3", "accent")

		btn.MouseEnter:Connect(function()
			btn.BackgroundTransparency = 0.5
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundTransparency = 1
		end)

		btn.MouseButton1Click:Connect(function()
			search.Text = query
			trendingDropdown.Visible = false
		end)
	end
end

function refreshTrendingDropdown()
	if not canShowTrendingDropdown() then
		hideTrendingDropdown()
		return
	end

	-- Show cached/fallback immediately so throttle never blanks the dropdown
	populateTrendingDropdown(_cachedTrending)

	if Settings.searchHistory and #Settings.searchHistory > 0 then
		populateTrendingDropdown(Settings.searchHistory)
	end
end

function recordSearchQuery(raw)
	local q = string.match(tostring(raw or ""), "^%s*(.-)%s*$") or ""
	if q == "" or #q < 2 then return end
	if q == _lastRecordedQuery and (tick() - _lastRecordedAt) < 8 then return end
	_lastRecordedQuery = q
	_lastRecordedAt = tick()
	Settings.searchHistory = Settings.searchHistory or {}
	for i = #Settings.searchHistory, 1, -1 do
		if Settings.searchHistory[i] == q then table.remove(Settings.searchHistory, i) end
	end
	table.insert(Settings.searchHistory, 1, q)
	while #Settings.searchHistory > 8 do table.remove(Settings.searchHistory) end
	SaveData()
end

search.Focused:Connect(function()
	if not canShowTrendingDropdown() then return end
	if not search.Visible then return end
	trendingDropdown.Visible = true
	task.spawn(refreshTrendingDropdown)
end)

search.FocusLost:Connect(function(enterPressed)
	task.delay(0.18, function()
		if trendingDropdown and not search:IsFocused() then
			hideTrendingDropdown()
		end
	end)
end)

pageH = isMobile and 30 or 36
pageBar = Instance.new("Frame")
pageBar.Size = UDim2.new(1, -16, 0, pageH)
pageBar.Position = UDim2.new(0, 8, 1, -(pageH + bottomBarH + 8))
pageBar.BackgroundColor3 = currentTheme.secondary
pageBar.ZIndex = 5
pageBar.Parent = content
Instance.new("UICorner", pageBar).CornerRadius = UDim.new(0, 10)
RegisterTheme(pageBar, "BackgroundColor3", "secondary")

pageBtnW = isMobile and 45 or 60

prevBtn = Instance.new("TextButton")
prevBtn.Size = UDim2.new(0, pageBtnW, 1, -4)
prevBtn.Position = UDim2.new(0, 2, 0, 2)
prevBtn.BackgroundColor3 = currentTheme.accent
prevBtn.Text = ""
prevBtn.ZIndex = 6
prevBtn.Parent = pageBar
Instance.new("UICorner", prevBtn).CornerRadius = UDim.new(0, 8)
RegisterTheme(prevBtn, "BackgroundColor3", "accent")

function CreateChevron(parent, isNext)
	local container = Instance.new("Frame")
	container.Name = "ChevronIcon"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.ZIndex = 7
	container.Parent = parent
	
	local effScale = math.min(ICON_SCALE, 1.4)
	local len = math.floor(14 * effScale)
	local thick = math.floor(1.6 * math.max(1, effScale))
	local offset = math.floor(len * 0.353)
	
	local tipX = isNext and offset or -offset
	local dx = isNext and -offset or offset
	
	local topL = Instance.new("Frame")
	topL.BorderSizePixel = 0
	topL.Size = UDim2.new(0, len, 0, thick)
	topL.AnchorPoint = Vector2.new(0.5, 0.5)
	topL.Position = UDim2.new(0.5, tipX + dx, 0.5, -offset)
	topL.Rotation = isNext and 45 or -45
	topL.BackgroundColor3 = Color3.new(1, 1, 1)
	topL.ZIndex = 7
	topL.Parent = container
	Instance.new("UICorner", topL).CornerRadius = UDim.new(0, 2)
	
	local botL = Instance.new("Frame")
	botL.BorderSizePixel = 0
	botL.Size = UDim2.new(0, len, 0, thick)
	botL.AnchorPoint = Vector2.new(0.5, 0.5)
	botL.Position = UDim2.new(0.5, tipX + dx, 0.5, offset)
	botL.Rotation = isNext and -45 or 45
	botL.BackgroundColor3 = Color3.new(1, 1, 1)
	botL.ZIndex = 7
	botL.Parent = container
	Instance.new("UICorner", botL).CornerRadius = UDim.new(0, 2)
end

nextBtn = prevBtn:Clone()
nextBtn.Position = UDim2.new(1, -(pageBtnW + 2), 0, 2)
nextBtn.Parent = pageBar

CreateChevron(prevBtn, false)
CreateChevron(nextBtn, true)
RegisterTheme(nextBtn, "BackgroundColor3", "accent")

pageNum = Instance.new("TextLabel")
pageNum.Size = UDim2.new(1, -(pageBtnW*2 + 16), 1, 0)
pageNum.Position = UDim2.new(0, pageBtnW + 8, 0, 0)
pageNum.BackgroundTransparency = 1
pageNum.Text = "1/1"
pageNum.TextColor3 = currentTheme.textDim
pageNum.Font = Enum.Font.GothamBold
pageNum.TextScaled = true
pageNum.ZIndex = 6
pageNum.Parent = pageBar
RegisterTheme(pageNum, "TextColor3", "textDim")

MockPlaylists = Playlists

emptyLbl = Instance.new("TextLabel")
emptyLbl.Size = UDim2.new(1, -20, 0, 50)
emptyLbl.Position = UDim2.fromScale(0.5, 0.45)
emptyLbl.AnchorPoint = Vector2.new(0.5, 0.5)
emptyLbl.BackgroundTransparency = 1
emptyLbl.Text = ""
emptyLbl.TextColor3 = currentTheme.textDim
emptyLbl.Font = Enum.Font.GothamBold
emptyLbl.TextScaled = true
emptyLbl.Visible = false
emptyLbl.ZIndex = 5
emptyLbl.Parent = content
RegisterTheme(emptyLbl, "TextColor3", "textDim")

-- ===============================================================

	return true
end
