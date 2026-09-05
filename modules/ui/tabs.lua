-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

-- TAB SYSTEM
-- ===============================================================

UpdateTabStyles = function()
	local isM3 = Settings.theme == "MaterialYou"
	for name, data in pairs(tabBtns) do
		local active = currentTab == name
		local targetColor = active and currentTheme.accent or currentTheme.sidebar
		local targetIconColor = active and Color3.new(1, 1, 1) or currentTheme.text
		
		if data.quatrefoil then
			if isM3 and active then
				data.quatrefoil.Visible = true
				data.quatrefoil.ImageColor3 = currentTheme.accent
				local qSize = tabBtnS + 10
				data.quatrefoil.Size = UDim2.new(0, 0, 0, 0)
				TweenService:Create(data.quatrefoil, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, qSize, 0, qSize),
					ImageTransparency = 0.3
				}):Play()
			else
				if data.quatrefoil.Visible then
					local qRef = data.quatrefoil
					TweenService:Create(qRef, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Size = UDim2.new(0, 0, 0, 0),
						ImageTransparency = 1
					}):Play()
					task.delay(0.2, function()
						if qRef and qRef.Parent then qRef.Visible = false end
					end)
				end
			end
		end
		
		TweenService:Create(data.btn, TweenInfo.new(0.2), {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, tabBtnS, 0, tabBtnS)
		}):Play()
		data.stroke.Transparency = 1

		if isM3 then
			if _tabIndicator then _tabIndicator.Visible = false end
		else
			if _tabIndicator then
				_tabIndicator.Visible = true
				if active then
					_UpdateIndicatorGrad()
					local targetY = data.yPos - 2
					TweenService:Create(_tabIndicator, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Position = UDim2.new(0.5, -_indS/2, 0, targetY)
					}):Play()
				end
			end
		end
		
		if data.img then
			TweenService:Create(data.img, TweenInfo.new(0.2), {
				ImageColor3 = targetIconColor
			}):Play()
		else
			TweenService:Create(data.btn, TweenInfo.new(0.2), {
				TextColor3 = targetIconColor
			}):Play()
		end
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

function PrintHierarchy(obj, depth)
	depth = depth or 0
	local indent = string.rep("  ", depth)
	local isGui = obj:IsA("GuiObject")
	local transp = "N/A"
	pcall(function()
		if obj:IsA("Frame") or obj:IsA("ScrollingFrame") or obj:IsA("TextBox") or obj:IsA("TextButton") or obj:IsA("ImageLabel") or obj:IsA("TextLabel") then
			transp = tostring(obj.BackgroundTransparency)
		end
	end)
	print(string.format("[Hierarchy] %s%s (%s): Visible=%s, Size=%s, AbsSize=%s, AbsPos=%s, ZIndex=%s, Transp=%s",
		indent,
		obj.Name,
		obj.ClassName,
		tostring(isGui and obj.Visible or "N/A"),
		tostring(isGui and obj.Size or "N/A"),
		tostring(isGui and obj.AbsoluteSize or "N/A"),
		tostring(isGui and obj.AbsolutePosition or "N/A"),
		tostring(isGui and obj.ZIndex or "N/A"),
		transp
	))
	for _, child in ipairs(obj:GetChildren()) do
		PrintHierarchy(child, depth + 1)
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
	local isAnimations = currentTab == "animations"
	settingsPanel.Visible  = isSettings
	friendsPanel.Visible   = isFriends
	keybindsPanel.Visible  = isKeybinds
	local viewingPlaylist = isPlaylists and (_currentPlaylistId ~= nil)
	
	if isPlaylists and not viewingPlaylist then
		if RefreshPlaylistsList then RefreshPlaylistsList() end
	end
	playlistsPanel.Visible = isPlaylists and not viewingPlaylist
	local hideNormal = isSettings or isFriends or isKeybinds or (isPlaylists and not viewingPlaylist)
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
		task.delay(0.1, function()
		pcall(function()
			if playlistsPanel then
				print("[Emotes] Delayed check: playlistsPanel Parent=" .. tostring(playlistsPanel.Parent and playlistsPanel.Parent.Name or "nil") .. ", Visible=" .. tostring(playlistsPanel.Visible) .. ", Size=" .. tostring(playlistsPanel.Size) .. ", AbsSize=" .. tostring(playlistsPanel.AbsoluteSize) .. ", AbsPos=" .. tostring(playlistsPanel.AbsolutePosition) .. ", ZIndex=" .. tostring(playlistsPanel.ZIndex) .. ", CanvasSize=" .. tostring(playlistsPanel.CanvasSize))
				for _, child in ipairs(playlistsPanel:GetChildren()) do
					print("[Emotes] Delayed child: Name=" .. child.Name .. ", Class=" .. child.ClassName .. ", Size=" .. tostring(child:IsA("GuiObject") and child.Size or "N/A") .. ", AbsSize=" .. tostring(child:IsA("GuiObject") and child.AbsoluteSize or "N/A") .. ", AbsPos=" .. tostring(child:IsA("GuiObject") and child.AbsolutePosition or "N/A") .. ", Visible=" .. tostring(child:IsA("GuiObject") and child.Visible or "N/A"))
					if child.Name == "playlistTopBar" then
						for _, sub in ipairs(child:GetChildren()) do
							print("[Emotes]   Sub-child: Name=" .. sub.Name .. ", Class=" .. sub.ClassName .. ", Size=" .. tostring(sub:IsA("GuiObject") and sub.Size or "N/A") .. ", AbsSize=" .. tostring(sub:IsA("GuiObject") and sub.AbsoluteSize or "N/A") .. ", AbsPos=" .. tostring(sub:IsA("GuiObject") and sub.AbsolutePosition or "N/A") .. ", Visible=" .. tostring(sub:IsA("GuiObject") and sub.Visible or "N/A"))
						end
					end
				end
			else
				print("[Emotes] Delayed check: playlistsPanel is NIL")
			end
			print("[Hierarchy] --- START CONTENT HIERARCHY ---")
			if content then
				PrintHierarchy(content)
			end
			print("[Hierarchy] --- END CONTENT HIERARCHY ---")
		end)
	end)
	
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
		titleIcon.Image = ResolveAssetImage(Icons.Emote)
		titleIcon.ImageColor3 = currentTheme.text
		titleIcon.Visible = true
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
		titleIcon.Image = ResolveAssetImage(Icons.FavoriteFull)
		titleIcon.ImageColor3 = (Settings.theme == "FrostedGlass" or Settings.theme == "DarkGlass") and currentTheme.accent or currentTheme.text
		titleIcon.Visible = true

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
		titleIcon.Image = ResolveAssetImage(Icons.Recent)
		titleIcon.ImageColor3 = (Settings.theme == "FrostedGlass" or Settings.theme == "DarkGlass") and currentTheme.accent or currentTheme.text
		titleIcon.Visible = true
	elseif currentTab == "settings" then
		title.Text = L.settings
		titleIcon.Image = ResolveAssetImage(Icons.Settings)
		titleIcon.ImageColor3 = (Settings.theme == "FrostedGlass" or Settings.theme == "DarkGlass") and currentTheme.accent or currentTheme.text
		titleIcon.Visible = true
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
		titleIcon.Image = ResolveAssetImage("rbxassetid://108973165274475")
		titleIcon.ImageColor3 = (Settings.theme == "FrostedGlass" or Settings.theme == "DarkGlass") and currentTheme.accent or currentTheme.text
		titleIcon.Visible = true
	elseif currentTab == "friends" then
		title.Text = L.friendTab
		titleIcon.Image = ResolveAssetImage("rbxassetid://115725480722697")
		titleIcon.ImageColor3 = (Settings.theme == "FrostedGlass" or Settings.theme == "DarkGlass") and currentTheme.accent or currentTheme.text
		titleIcon.Visible = true
	elseif currentTab == "keybinds" then
		title.Text = L.keybinds
		titleIcon.Image = ResolveAssetImage("rbxassetid://122679509852670")
		titleIcon.ImageColor3 = (Settings.theme == "FrostedGlass" or Settings.theme == "DarkGlass") and currentTheme.accent or currentTheme.text
		titleIcon.Visible = true
	elseif currentTab == "animations" then
		currentData = AnimationPacks
		filtered = AnimationPacks
		title.Text = isTR and "Animasyonlar" or "Animations"
		titleIcon.Image = ResolveAssetImage("rbxassetid://75528584354229")
		titleIcon.ImageColor3 = currentTheme.text
		titleIcon.Visible = true
	end
	
	local baseIconSz = isMobile and 31 or 37
	local tabIconSz = baseIconSz
	if currentTab == "animations" then
		tabIconSz = math.floor(baseIconSz * 0.75)
	elseif currentTab == "emotes" then
		tabIconSz = baseIconSz
	else
		tabIconSz = math.floor(baseIconSz * 1.3)
	end
	titleIcon.Size = UDim2.new(0, tabIconSz, 0, tabIconSz)
	title.Position = UDim2.new(0, titleIcon.Visible and (10 + tabIconSz + 6) or 10, 0, 0)
	
	UpdateTabStyles()
	local shouldRefresh = not isSettings and not isKeybinds and not isFriends and (not isPlaylists or viewingPlaylist)
	if shouldRefresh then Refresh(true) end
end

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
	if currentTab == "settings" then return end
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
