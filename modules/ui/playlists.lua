-- Panel container constructed on its first category visit.
return function(context)
 setfenv(1,context)
playlistsPanel = Instance.new("ScrollingFrame")
playlistsPanel.Size = UDim2.new(1, -16, 1, -(titleH + bottomBarH + 20))
playlistsPanel.Position = UDim2.new(0, 8, 0, titleH + 8)
playlistsPanel.BackgroundTransparency = 1
playlistsPanel.ScrollBarThickness = isMobile and 6 or 4
playlistsPanel.AutomaticCanvasSize = Enum.AutomaticSize.None
playlistsPanel.CanvasSize = UDim2.new(0,0,0,0)
playlistsPanel.Visible = false
playlistsPanel.ZIndex = 5
playlistsPanel.ZIndex = 5
playlistsPanel.Parent = content

playlistsLayout = Instance.new("UIListLayout")
playlistsLayout.SortOrder = Enum.SortOrder.LayoutOrder
playlistsLayout.Padding = UDim.new(0, 6)
playlistsLayout.Parent = playlistsPanel

playlistTopBar = Instance.new("Frame")
playlistTopBar.Size = UDim2.new(1, 0, 0, 40)
playlistTopBar.BackgroundTransparency = 1
playlistTopBar.LayoutOrder = -1
playlistTopBar.ZIndex = 6
playlistTopBar.Parent = playlistsPanel

playlistSearchBox = Instance.new("Frame")
playlistSearchBox.Size = UDim2.new(1, -50, 1, 0)
playlistSearchBox.BackgroundColor3 = currentTheme.secondary
playlistSearchBox.ZIndex = 7
playlistSearchBox.Parent = playlistTopBar
Instance.new("UICorner", playlistSearchBox).CornerRadius = UDim.new(0, 10)
RegisterTheme(playlistSearchBox, "BackgroundColor3", "secondary")

playlistListSearch = Instance.new("TextBox")
playlistListSearch.Size = UDim2.new(1, -20, 1, 0)
playlistListSearch.Position = UDim2.new(0, 10, 0, 0)
playlistListSearch.BackgroundTransparency = 1
playlistListSearch.Text = ""
playlistListSearch.PlaceholderText = L.searchPlaylists
playlistListSearch.TextColor3 = currentTheme.text
playlistListSearch.PlaceholderColor3 = currentTheme.text
playlistListSearch.Font = Enum.Font.Gotham
playlistListSearch.TextSize = 14
playlistListSearch.TextXAlignment = Enum.TextXAlignment.Left
playlistListSearch.ZIndex = 8
playlistListSearch.Parent = playlistSearchBox
RegisterTheme(playlistListSearch, "TextColor3", "text")
RegisterTheme(playlistListSearch, "PlaceholderColor3", "text")
playlistListSearch:GetPropertyChangedSignal("Text"):Connect(function()
	if RefreshPlaylistsList then RefreshPlaylistsList() end
end)

playlistAddBtn = Instance.new("TextButton")
playlistAddBtn.Size = UDim2.new(0, 40, 0, 40)
playlistAddBtn.Position = UDim2.new(1, -40, 0, 0)
playlistAddBtn.BackgroundColor3 = currentTheme.accent
playlistAddBtn.Text = "+"
playlistAddBtn.TextColor3 = Color3.new(1,1,1)
playlistAddBtn.Font = Enum.Font.GothamBold
playlistAddBtn.TextSize = 24
playlistAddBtn.ZIndex = 7
playlistAddBtn.Parent = playlistTopBar
Instance.new("UICorner", playlistAddBtn).CornerRadius = UDim.new(0, 10)
RegisterTheme(playlistAddBtn, "BackgroundColor3", "accent")

playlistAddBtn.MouseButton1Click:Connect(function()
	_isPlaylistMode = true
	_selectedEmotesForPlaylist = {}
	currentTab = "emotes"
	search.Text = ""
	UpdateTabData()
end)


 return true
end
