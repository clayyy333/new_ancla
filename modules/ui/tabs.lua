-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

-- TAB SYSTEM
-- ===============================================================

UpdateTabStyles = function()
	local function SetButtonStyle(style, active)
		if not style then return end
		style.gradient.Enabled = false
		style.stroke.Transparency = 1
		style.btn.Font = active and Enum.Font.GothamBold or Enum.Font.GothamMedium
		TweenService:Create(style.btn, TweenInfo.new(0.18), {
			BackgroundTransparency = active and 0.12 or 1,
			BackgroundColor3 = currentTheme.tertiary,
			TextColor3 = active and currentTheme.accent or currentTheme.textDim
		}):Play()
	end

	local isFling2 = currentTab == "fling2"
	local isFlingCar = currentTab == "fling_car"
	local isFlingCar2 = currentTab == "fling_car2"
	local isFlingMoto = currentTab == "fling_moto"
	local isFlingMotoXeno = currentTab == "fling_moto_xeno"
	local isAnchorBasic = currentTab == "anchor"
	local isAnchorAuto = currentTab == "anchor_auto"
	local isAnchor = isAnchorBasic or isAnchorAuto
	local isFling2Category = isFling2 or isFlingCar or isFlingCar2 or isFlingMoto or isFlingMotoXeno
	local isFlingView = isFling2Category or isAnchor
	movementNav.Visible = not isFlingView
	fling2Nav.Visible = isFling2Category
	anchorNav.Visible = isAnchor
	content.Position = UDim2.new(0, sideBarW, 0, topNavH)
	content.Size = UDim2.new(1, -sideBarW, 1, -topNavH)
	SetButtonStyle(mainNavButtonStyle, not isFlingView)
	SetButtonStyle(fling2NavButtonStyle, isFling2Category)
	SetButtonStyle(anchorNavButtonStyle, isAnchor)
	for name, data in pairs(anchorTabBtns) do SetButtonStyle(data, currentTab == name) end
	for name, data in pairs(fling2TabBtns) do SetButtonStyle(data, currentTab == name) end
	for name, data in pairs(tabBtns) do
		SetButtonStyle(data, currentTab == name)
	end
end

playlistBackBtn = Instance.new("TextButton")
playlistBackBtn.Size = UDim2.new(0, 30, 0, 30)
playlistBackBtn.Position = UDim2.new(0, 8, 0, titleH + 6)
playlistBackBtn.BackgroundColor3 = currentTheme.secondary
playlistBackBtn.Text = "<"
playlistBackBtn.TextColor3 = currentTheme.text
playlistBackBtn.Font = Enum.Font.GothamBold
playlistBackBtn.TextSize = 18
playlistBackBtn.Visible = false
playlistBackBtn.ZIndex = 10
playlistBackBtn.Parent = content
Instance.new("UICorner", playlistBackBtn).CornerRadius = UDim.new(0, 8)
RegisterTheme(playlistBackBtn, "BackgroundColor3", "secondary")
RegisterTheme(playlistBackBtn, "TextColor3", "text")
playlistBackBtn.MouseButton1Click:Connect(function()
	_currentPlaylistId = nil
	search.Text = ""
	UpdateTabData()
end)

playlistDoneBtn = Instance.new("TextButton")
playlistDoneBtn.Size = UDim2.new(0, 50, 0, 30)
playlistDoneBtn.Position = UDim2.new(1, -58, 0, titleH + 6)
playlistDoneBtn.BackgroundColor3 = currentTheme.accent
playlistDoneBtn.Text = L.done
playlistDoneBtn.TextColor3 = Color3.new(1,1,1)
playlistDoneBtn.Font = Enum.Font.GothamBold
playlistDoneBtn.TextSize = 14
playlistDoneBtn.Visible = false
playlistDoneBtn.ZIndex = 10
playlistDoneBtn.Parent = content
Instance.new("UICorner", playlistDoneBtn).CornerRadius = UDim.new(0, 8)
RegisterTheme(playlistDoneBtn, "BackgroundColor3", "accent")

ShowSavePlaylistDialog = function(onSave)
	local success, err = pcall(function()
		local existing = main:FindFirstChild("VexroSavePlaylistOverlay")
		if existing then existing:Destroy() end

		local overlay = Instance.new("TextButton")
		overlay.Name = "VexroSavePlaylistOverlay"
		overlay.Size = UDim2.new(1, 0, 1, 0)
		overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		overlay.BackgroundTransparency = 0.5
		overlay.Text = ""
		overlay.AutoButtonColor = false
		overlay.ZIndex = 200
		overlay.Parent = main
		overlay.MouseButton1Click:Connect(function() end)

		local dialog = Instance.new("Frame")
		dialog.Size = UDim2.new(0.85, 0, 0, 180)
		dialog.Position = UDim2.fromScale(0.5, 0.5)
		dialog.AnchorPoint = Vector2.new(0.5, 0.5)
		dialog.BackgroundColor3 = currentTheme.secondary
		dialog.ZIndex = 201
		dialog.Parent = overlay
		Instance.new("UICorner", dialog).CornerRadius = UDim.new(0, 16)
		local dStroke = Instance.new("UIStroke")
		dStroke.Color = currentTheme.accent
		dStroke.Thickness = 2
		dStroke.Transparency = 0.4
		dStroke.Parent = dialog

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -16, 0, 36)
		titleLbl.Position = UDim2.new(0, 8, 0, 8)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = L.createPlaylist
		titleLbl.TextColor3 = currentTheme.text
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextSize = 16
		titleLbl.ZIndex = 202
		titleLbl.Parent = dialog

		local nameLblTitle = Instance.new("TextLabel")
		nameLblTitle.Size = UDim2.new(0, 100, 0, 24)
		nameLblTitle.Position = UDim2.new(0, 12, 0, 52)
		nameLblTitle.BackgroundTransparency = 1
		nameLblTitle.Text = L.playlistName
		nameLblTitle.TextColor3 = currentTheme.textDim
		nameLblTitle.Font = Enum.Font.GothamBold
		nameLblTitle.TextSize = 13
		nameLblTitle.TextXAlignment = Enum.TextXAlignment.Left
		nameLblTitle.ZIndex = 202
		nameLblTitle.Parent = dialog

		local nameBox = Instance.new("TextBox")
		nameBox.Size = UDim2.new(1, -24, 0, 32)
		nameBox.Position = UDim2.new(0, 12, 0, 78)
		nameBox.BackgroundColor3 = currentTheme.tertiary
		nameBox.PlaceholderText = L.playlistNamePlaceholder
		nameBox.Text = ""
		nameBox.TextColor3 = currentTheme.text
		nameBox.PlaceholderColor3 = currentTheme.textDim
		nameBox.Font = Enum.Font.Gotham
		nameBox.TextSize = 13
		nameBox.ClearTextOnFocus = false
		nameBox.ZIndex = 202
		nameBox.Parent = dialog
		Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 8)
		local nbStroke = Instance.new("UIStroke")
		nbStroke.Color = currentTheme.stroke
		nbStroke.Thickness = 1.5
		nbStroke.Parent = nameBox

		local cancelBtn = Instance.new("TextButton")
		cancelBtn.Size = UDim2.new(0.45, -6, 0, 38)
		cancelBtn.Position = UDim2.new(0, 12, 0, 128)
		cancelBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
		cancelBtn.Text = L.kbCancel
		cancelBtn.TextColor3 = Color3.new(1, 1, 1)
		cancelBtn.Font = Enum.Font.GothamBold
		cancelBtn.TextSize = 14
		cancelBtn.ZIndex = 202
		cancelBtn.Parent = dialog
		Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 10)

		local saveBtn = Instance.new("TextButton")
		saveBtn.Size = UDim2.new(0.55, -18, 0, 38)
		saveBtn.Position = UDim2.new(0.45, 6, 0, 128)
		saveBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
		saveBtn.Text = L.kbSave
		saveBtn.TextColor3 = Color3.new(1, 1, 1)
		saveBtn.Font = Enum.Font.GothamBold
		saveBtn.TextSize = 14
		saveBtn.ZIndex = 202
		saveBtn.Parent = dialog
		Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 10)

		cancelBtn.MouseButton1Click:Connect(function()
			overlay:Destroy()
		end)

		saveBtn.MouseButton1Click:Connect(function()
			local plName = nameBox.Text
			if plName == "" then return end
			onSave(plName)
			overlay:Destroy()
		end)
	end)
	if not success then
		warn("[Emotes] ShowSavePlaylistDialog Error: " .. tostring(err))
	end
end

playlistDoneBtn.MouseButton1Click:Connect(function()
	local success, err = pcall(function()
		local emoteIds = {}
		for k, v in pairs(_selectedEmotesForPlaylist) do
			if v then table.insert(emoteIds, tonumber(k)) end
		end
		
		if #emoteIds == 0 then
			_isPlaylistMode = false
			currentTab = "playlists"
			search.Text = ""
			if RefreshPlaylistsList then RefreshPlaylistsList() end
			UpdateTabData()
			return
		end
		
		ShowSavePlaylistDialog(function(plName)
			local newId = tostring(math.random(100000, 999999))
			local newPl = {
				id = newId,
				name = plName,
				creator = player.Name,
				creatorId = player.UserId,
				emotes = emoteIds
			}
			table.insert(Playlists, newPl)
			SaveData()
			
			_isPlaylistMode = false
			currentTab = "playlists"
			search.Text = ""
			if RefreshPlaylistsList then RefreshPlaylistsList() end
			UpdateTabData()
		end)
	end)
	if not success then
		warn("[Emotes] playlistDoneBtn.Click Error: " .. tostring(err))
	end
end)

RefreshPlaylistsList = function()
	local success, err = pcall(function()
		print("[Emotes] RefreshPlaylistsList running. Playlists count: " .. tostring(#Playlists))
		if not playlistsPanel then
			warn("[Emotes] playlistsPanel is NIL inside RefreshPlaylistsList!")
			return
		end
		
		for _, child in ipairs(playlistsPanel:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		
		local query = ""
		if playlistListSearch then
			query = playlistListSearch.Text:lower()
		end
		
		local yOffset = 46
		
		local sortedPlaylists = {}
		for _, pl in ipairs(Playlists) do
			table.insert(sortedPlaylists, pl)
		end
		table.sort(sortedPlaylists, function(a, b)
			local aFav = PlaylistFavorites[tostring(a.id)] and 1 or 0
			local bFav = PlaylistFavorites[tostring(b.id)] and 1 or 0
			if aFav ~= bFav then
				return aFav > bFav
			end
			return a.name:lower() < b.name:lower()
		end)

		for _, pl in ipairs(sortedPlaylists) do
			if query == "" or pl.name:lower():find(query, 1, true) then
				local row = Instance.new("TextButton")
				row.Size = UDim2.new(1, 0, 0, 60)
				row.BackgroundColor3 = currentTheme.secondary
				row.Text = ""
				row.ZIndex = 6
				row.Parent = playlistsPanel
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
				RegisterTheme(row, "BackgroundColor3", "secondary")

				local av = Instance.new("ImageLabel")
				av.Size = UDim2.new(0, 44, 0, 44)
				av.Position = UDim2.new(0, 8, 0.5, -22)
				av.BackgroundTransparency = 1
				av.Image = "rbxthumb://type=AvatarHeadShot&id=" .. pl.creatorId .. "&w=150&h=150"
				av.ZIndex = 7
				av.Parent = row
				Instance.new("UICorner", av).CornerRadius = UDim.new(1, 0)

				-- narrow labels to leave room for delete and favorite buttons
				local isOwner = tostring(pl.creatorId) == tostring(player.UserId)
				local labelRightOffset = isOwner and -142 or -70

				-- Favorite button
				local favBtn = Instance.new("ImageButton")
				favBtn.Size = UDim2.new(0, 38, 0, 38)
				favBtn.Position = isOwner and UDim2.new(1, -92, 0.5, -19) or UDim2.new(1, -46, 0.5, -19)
				favBtn.BackgroundTransparency = 1
				local isFav = PlaylistFavorites[tostring(pl.id)]
				favBtn.Image = isFav and "rbxthumb://type=Asset&id=89982519956696&w=150&h=150" or "rbxthumb://type=Asset&id=116039663994329&w=150&h=150"
				favBtn.ZIndex = 8
				favBtn.Parent = row

				favBtn.MouseButton1Click:Connect(function()
					local plId = tostring(pl.id)
					local isCurrentlyFav = PlaylistFavorites[plId]
					PlaylistFavorites[plId] = not isCurrentlyFav
					
					task.spawn(function()
						SaveData()
					end)
					
					if RefreshPlaylistsList then RefreshPlaylistsList() end
				end)

				local creatorLbl = Instance.new("TextLabel")
				creatorLbl.Size = UDim2.new(1, labelRightOffset, 0, 16)
				creatorLbl.Position = UDim2.new(0, 60, 0, 12)
				creatorLbl.BackgroundTransparency = 1
				creatorLbl.Text = L.createdBy .. pl.creator
				creatorLbl.TextColor3 = currentTheme.text
				creatorLbl.TextTransparency = 0.4
				creatorLbl.Font = Enum.Font.Gotham
				creatorLbl.TextSize = 11
				creatorLbl.TextXAlignment = Enum.TextXAlignment.Left
				creatorLbl.ZIndex = 7
				creatorLbl.Parent = row
				RegisterTheme(creatorLbl, "TextColor3", "text")

				local nameLbl = Instance.new("TextLabel")
				nameLbl.Size = UDim2.new(1, labelRightOffset, 0, 20)
				nameLbl.Position = UDim2.new(0, 60, 0, 28)
				nameLbl.BackgroundTransparency = 1
				nameLbl.Text = pl.name
				nameLbl.TextColor3 = currentTheme.text
				nameLbl.Font = Enum.Font.GothamBold
				nameLbl.TextSize = 16
				nameLbl.TextXAlignment = Enum.TextXAlignment.Left
				nameLbl.ZIndex = 7
				nameLbl.Parent = row
				RegisterTheme(nameLbl, "TextColor3", "text")

				-- Delete button (only for playlists owned by the player)
				if isOwner then
					local delBtn = Instance.new("TextButton")
					delBtn.Size = UDim2.new(0, 38, 0, 38)
					delBtn.Position = UDim2.new(1, -46, 0.5, -19)
					delBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
					delBtn.Text = L.deletePlaylist
					delBtn.TextColor3 = Color3.new(1, 1, 1)
					delBtn.Font = Enum.Font.GothamBold
					delBtn.TextSize = 12
					delBtn.ZIndex = 8
					delBtn.Parent = row
					Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 8)

					local _delConfirm = false
					local _delTimer = nil

					delBtn.MouseButton1Click:Connect(function()
						if not _delConfirm then
							-- First tap: ask for confirmation
							_delConfirm = true
							delBtn.Text = L.deleteConfirm
							delBtn.TextSize = 10
							delBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 20)
							-- Auto reset after 3 seconds if not confirmed
							if _delTimer then _delTimer:Disconnect() end
							_delTimer = task.delay(3, function()
								if delBtn and delBtn.Parent then
									_delConfirm = false
									delBtn.Text = L.deletePlaylist
									delBtn.TextSize = 12
									delBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
								end
							end)
						else
							-- Second tap: actually delete
							_delConfirm = false
							for i, p in ipairs(Playlists) do
								if p.id == pl.id then
									table.remove(Playlists, i)
									break
								end
							end
							task.spawn(function()
								SaveData()
							end)
							SaveData()
							if RefreshPlaylistsList then RefreshPlaylistsList() end
						end
					end)
				end

				row.MouseButton1Click:Connect(function()
					-- Don't open playlist if a delete button exists (handled separately)
					_currentPlaylistId = pl.id
					search.Text = ""
					UpdateTabData()
				end)
				
				yOffset = yOffset + 66
			end
		end
		
		playlistsPanel.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
	end)
	if not success then
		warn("[Emotes] RefreshPlaylistsList Inner Error: " .. tostring(err))
	end
end

UpdateTabData = function()
	hideTrendingDropdown()
	search.Text = ""
	page = 1
	
	local isSettings  = currentTab == "settings"
	local isFriends   = currentTab == "friends"
	local isKeybinds  = currentTab == "keybinds"
	local isPlaylists = currentTab == "playlists"
	local isFling2 = currentTab == "fling2"
	local isFlingCar = currentTab == "fling_car"
	local isFlingCar2 = currentTab == "fling_car2"
	local isFlingMoto = currentTab == "fling_moto"
	local isFlingMotoXeno = currentTab == "fling_moto_xeno"
	local isAnchorBasic = currentTab == "anchor"
	local isAnchorAuto = currentTab == "anchor_auto"
	local isAnchor = isAnchorBasic or isAnchorAuto
	local isFling2Category = isFling2 or isFlingCar or isFlingCar2 or isFlingMoto or isFlingMotoXeno
	local isFlingView = isFling2Category or isAnchor
	settingsPanel.Visible  = isSettings
	friendsPanel.Visible   = isFriends
	keybindsPanel.Visible  = isKeybinds
	fling2Panel.Visible = isFling2
	carFlingPanel.Visible = isFlingCar
	carFling2Panel.Visible = isFlingCar2
	motoFlingPanel.Visible = isFlingMoto
	motoFlingXenoPanel.Visible = isFlingMotoXeno
	anchorPanel.Visible = isAnchorBasic
	autoAnchorPanel.Visible = isAnchorAuto
	local viewingPlaylist = isPlaylists and (_currentPlaylistId ~= nil)
	
	if isPlaylists and not viewingPlaylist then
		if RefreshPlaylistsList then RefreshPlaylistsList() end
	end
	playlistsPanel.Visible = isPlaylists and not viewingPlaylist
	local hideNormal = isSettings or isFriends or isKeybinds or isFlingView or (isPlaylists and not viewingPlaylist)
	scroll.Visible  = not hideNormal
	search.Visible  = not hideNormal
	if playlistBackBtn then
		playlistBackBtn.Visible = viewingPlaylist
		playlistDoneBtn.Visible = _isPlaylistMode
		search.Position = UDim2.new(0, viewingPlaylist and 46 or 8, 0, (titleH + 6))
		if _isPlaylistMode then
			search.Size = UDim2.new(1, -80, 0, searchH)
		else
			search.Size = UDim2.new(1, viewingPlaylist and -54 or -16, 0, searchH)
		end
	end
	pageBar.Visible = not hideNormal
	if hideNormal then
		emptyLbl.Visible = false
	end
	if isKeybinds then
		if RefreshKeybindsPanel then RefreshKeybindsPanel() end
	end
	
	if currentTab == "emotes" then
		currentData = Emotes
		if next(_badEmotes) then
			filtered = {}
			for _, e in ipairs(Emotes) do
				if not _badEmotes[tostring(e.id)] then filtered[#filtered + 1] = e end
			end
		else
			filtered = Emotes
		end
		title.Text = L.emotes
	elseif currentTab == "favorites" then
		currentData = {}
		for i = 1, #Favorites do
			local emote = EmotesById[Favorites[i]]
			if emote then
				currentData[#currentData + 1] = emote
			end
		end
		filtered = currentData
		title.Text = L.favorites

	elseif currentTab == "recent" then
		currentData = {}
		for i = 1, #RecentEmotes do
			local emote = EmotesById[RecentEmotes[i]]
			if emote then
				currentData[#currentData + 1] = emote
			end
		end
		filtered = currentData
		title.Text = L.recent
	elseif currentTab == "settings" then
		title.Text = L.settings
	elseif currentTab == "playlists" then
		if _currentPlaylistId then
			currentData = {}
			if not MockPlaylists then return end
	for _, pl in ipairs(Playlists) do
				if pl.id == _currentPlaylistId then
					for _, eId in ipairs(pl.emotes) do
						local em = EmotesById[eId]
						if em then table.insert(currentData, em) end
					end
					break
				end
			end
			filtered = currentData
		end
		title.Text = L.playlistsTab
	elseif currentTab == "friends" then
		title.Text = L.friendTab
	elseif currentTab == "keybinds" then
		title.Text = L.keybinds
	elseif currentTab == "anchor" then
		title.Text = isES and "Ancla" or "Anchor"
		if UpdateAnchorPanel then UpdateAnchorPanel() end
	elseif currentTab == "anchor_auto" then
		title.Text = isES and "Ancla automática" or "Automatic Anchor"
		if UpdateAutoAnchorPanel then UpdateAutoAnchorPanel() end
	elseif currentTab == "fling2" then
		title.Text = "Fling 2"
		if UpdateFling2Panel then UpdateFling2Panel() end
	elseif currentTab == "fling_car" then
		title.Text = isES and "Fling con vehículo" or "Fling with Car"
		if UpdateCarFlingPanel then UpdateCarFlingPanel() end
	elseif currentTab == "fling_car2" then
		title.Text = isES and "Fling con vehículo 2" or "Fling with Car 2"
		if UpdateCarFling2Panel then UpdateCarFling2Panel() end
	elseif currentTab == "fling_moto" then
		title.Text = isES and "Fling con moto Delta" or "Delta Motorcycle Fling"
		if UpdateMotoFlingPanel then UpdateMotoFlingPanel() end
	elseif currentTab == "fling_moto_xeno" then
		title.Text = isES and "Fling con moto Xeno" or "Xeno Motorcycle Fling"
		if UpdateMotoFlingXenoPanel then UpdateMotoFlingXenoPanel() end
	elseif currentTab == "animations" then
		currentData = AnimationPacks
		filtered = AnimationPacks
		title.Text = L.animations
	end
	title.Position = UDim2.new(0, 12, 0, 0)

	UpdateTabStyles()
	local shouldRefresh = not isSettings and not isKeybinds and not isFriends and not isFlingView and (not isPlaylists or viewingPlaylist)
	if shouldRefresh then Refresh(true) end
end

mainNavBtns["fling2"].MouseButton1Click:Connect(function() currentTab = "fling2"; UpdateTabData() end)
mainNavBtns["anchor"].MouseButton1Click:Connect(function() currentTab = "anchor"; UpdateTabData() end)
anchorTabBtns["anchor"].btn.MouseButton1Click:Connect(function() currentTab = "anchor"; UpdateTabData() end)
anchorTabBtns["anchor_auto"].btn.MouseButton1Click:Connect(function() currentTab = "anchor_auto"; UpdateTabData() end)
fling2TabBtns["fling2"].btn.MouseButton1Click:Connect(function() currentTab = "fling2"; UpdateTabData() end)
fling2TabBtns["fling_car"].btn.MouseButton1Click:Connect(function() currentTab = "fling_car"; UpdateTabData() end)
fling2TabBtns["fling_car2"].btn.MouseButton1Click:Connect(function() currentTab = "fling_car2"; UpdateTabData() end)
fling2TabBtns["fling_moto"].btn.MouseButton1Click:Connect(function() currentTab = "fling_moto"; UpdateTabData() end)
fling2TabBtns["fling_moto_xeno"].btn.MouseButton1Click:Connect(function() currentTab = "fling_moto_xeno"; UpdateTabData() end)
mainNavBtns["movements"].MouseButton1Click:Connect(function() currentTab = "emotes"; UpdateTabData() end)
tabBtns["emotes"].btn.MouseButton1Click:Connect(function() currentTab = "emotes"; UpdateTabData() end)
tabBtns["favorites"].btn.MouseButton1Click:Connect(function() currentTab = "favorites"; UpdateTabData() end)

tabBtns["recent"].btn.MouseButton1Click:Connect(function() currentTab = "recent"; UpdateTabData() end)
tabBtns["animations"].btn.MouseButton1Click:Connect(function() currentTab = "animations"; UpdateTabData() end)
tabBtns["friends"].btn.MouseButton1Click:Connect(function() currentTab = "friends"; UpdateTabData() end)
tabBtns["settings"].btn.MouseButton1Click:Connect(function() currentTab = "settings"; UpdateTabData() end)
if tabBtns["playlists"] then tabBtns["playlists"].btn.MouseButton1Click:Connect(function() currentTab = "playlists"; _currentPlaylistId = nil
_isPlaylistMode = false
_selectedEmotesForPlaylist = {}
if RefreshPlaylistsList then RefreshPlaylistsList() end
; UpdateTabData() end) end
if not isMobile then tabBtns["keybinds"].btn.MouseButton1Click:Connect(function() currentTab = "keybinds"; UpdateTabData() end) end

searchToken = 0
recordToken = 0
search:GetPropertyChangedSignal("Text"):Connect(function()
	if currentTab == "settings" or currentTab == "anchor" or currentTab == "anchor_auto" or currentTab == "fling2" or currentTab == "fling_car" or currentTab == "fling_car2" or currentTab == "fling_moto" or currentTab == "fling_moto_xeno" then return end
	searchToken = searchToken + 1
	local myToken = searchToken
	task.wait(0.08)
	if myToken ~= searchToken then return end
	local q = search.Text:lower()
	if #q >= 2 then
		hideTrendingDropdown()
		-- Record the final query only after 10 seconds of inactivity.
		recordToken = recordToken + 1
		local myRecord = recordToken
		task.delay(10, function()
			if myRecord ~= recordToken then return end
			if not search or search.Text:lower() ~= q then return end
			recordSearchQuery(search.Text)
		end)
	elseif q == "" and search:IsFocused() and search.Visible then
		recordToken = recordToken + 1
		if canShowTrendingDropdown() then
			trendingDropdown.Visible = true
			task.spawn(refreshTrendingDropdown)
		else
			hideTrendingDropdown()
		end
	end
	filtered = {}
	for i = 1, #currentData do
		local e = currentData[i]
		if not _badEmotes[tostring(e.id)] and (q == "" or (#q <= #(e._lname or e.name) and (e._lname or e.name:lower()):find(q, 1, true))) then
			filtered[#filtered + 1] = e
		end
	end
	page = 1
	Refresh(true)
end)

-- ===============================================================

	return true
end
