-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

local removeAnimationButton
local animationPicker
local animationStateLabels={
	{"Idle","Inactividad","Idle"},{"Walk","Caminar","Walk"},
	{"Run","Correr","Run"},{"Jump","Saltar","Jump"},
	{"Fall","Caer","Fall"},{"Climb","Trepar","Climb"},
	{"Swim","Nadar","Swim"}
}

local function ShowAnimationPackOptions(pack)
	if animationPicker then animationPicker:Destroy() end
	local overlay=Instance.new("TextButton")
	overlay.Name="AnimationPackOptions"
	overlay.Size=UDim2.fromScale(1,1)
	overlay.BackgroundColor3=Color3.new(0,0,0)
	overlay.BackgroundTransparency=0.35
	overlay.Text=""
	overlay.AutoButtonColor=false
	overlay.ZIndex=70
	overlay.Parent=gui
	animationPicker=overlay
	local width=math.min(440,workspace.CurrentCamera.ViewportSize.X-24)
	local height=math.min(470,workspace.CurrentCamera.ViewportSize.Y-32)
	local panel=Instance.new("Frame")
	panel.Size=UDim2.fromOffset(width,height)
	panel.Position=UDim2.fromScale(0.5,0.5)
	panel.AnchorPoint=Vector2.new(0.5,0.5)
	panel.BackgroundColor3=currentTheme.primary
	panel.ZIndex=71
	panel.Active=true
	panel.Parent=overlay
	Instance.new("UICorner",panel).CornerRadius=UDim.new(0,16)
	local border=Instance.new("UIStroke")
	border.Color=currentTheme.accent
	border.Thickness=1.5
	border.Parent=panel
	local titleLabel=Instance.new("TextLabel")
	titleLabel.Size=UDim2.new(1,-70,0,44)
	titleLabel.Position=UDim2.fromOffset(16,8)
	titleLabel.BackgroundTransparency=1
	titleLabel.Text=pack.name
	titleLabel.TextColor3=currentTheme.text
	titleLabel.Font=Enum.Font.GothamBold
	titleLabel.TextSize=18
	titleLabel.TextXAlignment=Enum.TextXAlignment.Left
	titleLabel.TextTruncate=Enum.TextTruncate.AtEnd
	titleLabel.ZIndex=72
	titleLabel.Parent=panel
	local close=Instance.new("TextButton")
	close.Size=UDim2.fromOffset(36,36)
	close.Position=UDim2.new(1,-46,0,12)
	close.BackgroundColor3=currentTheme.tertiary
	close.Text="×"
	close.TextColor3=currentTheme.text
	close.Font=Enum.Font.GothamBold
	close.TextSize=24
	close.ZIndex=73
	close.Parent=panel
	Instance.new("UICorner",close).CornerRadius=UDim.new(0,10)
	local function dismiss()
		if animationPicker==overlay then animationPicker=nil end
		overlay:Destroy()
	end
	close.Activated:Connect(dismiss)
	overlay.Activated:Connect(dismiss)
	local function addButton(parent,label,top,callback)
		local button=Instance.new("TextButton")
		button.Size=UDim2.new(1,-24,0,42)
		button.Position=UDim2.fromOffset(12,top)
		button.BackgroundColor3=currentTheme.tertiary
		button.Text=label
		button.TextColor3=currentTheme.text
		button.Font=Enum.Font.GothamMedium
		button.TextSize=14
		button.ZIndex=73
		button.Parent=parent
		Instance.new("UICorner",button).CornerRadius=UDim.new(0,10)
		button.Activated:Connect(function()
			callback()
			dismiss()
		end)
		return button
	end
	local all=addButton(panel,isES and "Equipar todo" or "Equip all",60,function()
		EquipAnimationPack(pack)
	end)
	all.BackgroundColor3=currentTheme.accent
	local subTitle=Instance.new("TextLabel")
	subTitle.Size=UDim2.new(1,-24,0,28)
	subTitle.Position=UDim2.fromOffset(12,111)
	subTitle.BackgroundTransparency=1
	subTitle.Text=isES and "O equipar solo una parte" or "Or equip one part"
	subTitle.TextColor3=currentTheme.textDim
	subTitle.Font=Enum.Font.GothamMedium
	subTitle.TextSize=13
	subTitle.TextXAlignment=Enum.TextXAlignment.Left
	subTitle.ZIndex=72
	subTitle.Parent=panel
	local list=Instance.new("ScrollingFrame")
	list.Size=UDim2.new(1,-20,1,-153)
	list.Position=UDim2.fromOffset(10,143)
	list.BackgroundTransparency=1
	list.ScrollBarThickness=4
	list.CanvasSize=UDim2.new(0,0,0,0)
	list.ZIndex=72
	list.Parent=panel
	local row=0
	for _,option in ipairs(animationStateLabels) do
		local state=option[1]
		if pack[state] then
			addButton(list,isES and option[2] or option[3],row*48,function()
				EquipAnimationPart(pack,state)
			end)
			row=row+1
		end
	end
	list.CanvasSize=UDim2.new(0,0,0,row*48)
end
function MakeCard(emote, ci, animate)
	local CARD = currentCardSize
	local PAD = isMobile and 4 or 6
	local INSET = isMobile and 2 or 3
	local IMAGE_H = CARD - (INSET * 2)

	local NAME_H = math.clamp(CARD * 0.35, 18, 28)
	local FAV_H = math.clamp(CARD * 0.3, 18, 24)
	local KB_H = ((not isMobile) or _isPlaylistMode) and math.clamp(CARD * 0.45, 30, 40) or 0
	local CARD_TOTAL_H = KB_H + CARD + NAME_H + FAV_H

	local cardContainer = Instance.new("Frame")
	cardContainer.Size = UDim2.new(0, CARD, 0, CARD_TOTAL_H)
	cardContainer.BackgroundColor3 = currentTheme.secondary
	cardContainer.BackgroundTransparency = 0.35
	cardContainer.ZIndex = 2
	cardContainer.Parent = scroll
	Instance.new("UICorner", cardContainer).CornerRadius = UDim.new(0, 10)
	RegisterTheme(cardContainer, "BackgroundColor3", "secondary")
	
	local col = ci % cols
	local row = math.floor(ci / cols)
	
	local targetX = col * (CARD + PAD)
	local targetY = PAD + row * (CARD_TOTAL_H + PAD)
	
	if animate then
		cardContainer.Position = UDim2.new(0, targetX, 0, targetY + 30)
		cardContainer.BackgroundColor3 = currentTheme.secondary
		cardContainer.BackgroundTransparency = 0.35
		
		task.delay(ci * 0.02, function()
			if cardContainer.Parent then
				TweenService:Create(cardContainer, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
					Position = UDim2.new(0, targetX, 0, targetY)
				}):Play()
			end
		end)
	else
		cardContainer.Position = UDim2.new(0, targetX, 0, targetY)
	end
	
	local card = Instance.new("ImageButton")
	card.Size = UDim2.new(1, -(INSET * 2), 0, IMAGE_H)
	card.Position = UDim2.new(0, INSET, 0, KB_H + INSET)
	card.BackgroundColor3 = currentTheme.tertiary
	card.ScaleType = Enum.ScaleType.Fit
	card.AutoButtonColor = false
	card.ZIndex = 3
	card.Parent = cardContainer
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
	
	if emote.isAnimationPack then
		local packId = tostring(emote.id):gsub("anim_", "")
		card.Image = "rbxthumb://type=BundleThumbnail&id=" .. packId .. "&w=420&h=420"
	else
		card.Image = "rbxthumb://type=Asset&id=" .. emote.id .. "&w=420&h=420"
	end
	card.BackgroundColor3 = currentTheme.tertiary

	if not emote.isAnimationPack then
		task.spawn(function()
			local _done = false
			local function _onResult(_, status)
				if _done then return end
				_done = true
				if status == Enum.AssetFetchStatus.Failure then
					task.defer(function()
						if cardContainer and cardContainer.Parent then cardContainer:Destroy() end
						_MarkBadEmote(emote.id)
					end)
				end
			end
			task.delay(15, function() _onResult(nil, Enum.AssetFetchStatus.Failure) end)
			pcall(function()
				game:GetService("ContentProvider"):PreloadAsync({card}, _onResult)
			end)
		end)
	end
	
	if animate then
		card.ImageTransparency = 1
		task.delay(ci * 0.02, function()
			if card.Parent then
				TweenService:Create(card, TweenInfo.new(0.25), {ImageTransparency = 0}):Play()
			end
		end)
	end
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = currentTheme.accent
	stroke.Thickness = 1
	stroke.Transparency = 0.72
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = card
	
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -4, 0, NAME_H - 2) 
	nameLbl.Position = UDim2.new(0, 2, 0, KB_H + CARD)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = #emote.name > 20 and emote.name:sub(1, 19) .. "…" or emote.name
	nameLbl.TextColor3 = currentTheme.text
	nameLbl.Font = Enum.Font.GothamMedium
	nameLbl.TextScaled = true
	nameLbl.TextWrapped = true 
	nameLbl.Active = true 
	nameLbl.ZIndex = 3
	nameLbl.Parent = cardContainer
	Instance.new("UICorner", nameLbl).CornerRadius = UDim.new(0, 4)
	
	
	local isFav = IsFavorite(emote.id)
	local favBtn = Instance.new("TextButton")
	favBtn.Size = UDim2.new(1, 0, 0, FAV_H)
	favBtn.Position = UDim2.new(0, 0, 0, KB_H + CARD + NAME_H)
	favBtn.BackgroundColor3 = currentTheme.accent
	favBtn.BackgroundTransparency = 0.92
	favBtn.Text = ""
	favBtn.ZIndex = 4
	favBtn.Parent = cardContainer
	Instance.new("UICorner", favBtn).CornerRadius = UDim.new(0, 4)

	local favIcon = Instance.new("TextLabel")
	local iconSize = isMobile and 22 or 26
	favIcon.Size = UDim2.new(0, iconSize, 0, iconSize)
	favIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	favIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	favIcon.BackgroundTransparency = 1
	favIcon.Text = isFav and SafeUtf8Char(0x2605) or SafeUtf8Char(0x2606)
	favIcon.TextColor3 = isFav and Color3.fromRGB(255, 215, 0) or currentTheme.accent
	favIcon.Font = Enum.Font.SourceSansLight
	favIcon.TextSize = isMobile and 22 or 26
	favIcon.TextScaled = false
	favIcon.ZIndex = 50
	favIcon.Parent = favBtn
	
	favBtn.MouseEnter:Connect(function()
		TweenService:Create(favBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
			BackgroundColor3 = isFav and currentTheme.tertiary or currentTheme.accent,
			Size = UDim2.new(1, 0, 0, FAV_H),
			Rotation = 0
		}):Play()
	end)
	favBtn.MouseLeave:Connect(function()
		TweenService:Create(favBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			BackgroundColor3 = isFav and currentTheme.tertiary or currentTheme.stroke,
			Size = UDim2.new(1, 0, 0, FAV_H),
			Rotation = 0
		}):Play()
	end)
	
	favBtn.MouseButton1Click:Connect(function()
		isFav = ToggleFavorite(emote.id)
		
		if isFav then
			favIcon.Text = SafeUtf8Char(0x2605)
			favIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
		else
			favIcon.Text = SafeUtf8Char(0x2606)
			favIcon.TextColor3 = currentTheme.accent
		end
		
		TweenService:Create(favBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = isFav and currentTheme.tertiary or currentTheme.stroke
		}):Play()
		
		if isFav then
			favIcon.Size = UDim2.new(0, 0, 0, 0)
			TweenService:Create(favIcon, TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, iconSize + 6, 0, iconSize + 6)
			}):Play()
			task.delay(0.2, function()
				TweenService:Create(favIcon, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
					Size = UDim2.new(0, iconSize, 0, iconSize)
				}):Play()
			end)
			
			local ripple = Instance.new("Frame")
			ripple.Size = UDim2.new(0, 0, 0, 0)
			ripple.Position = UDim2.fromScale(0.5, 0.5)
			ripple.AnchorPoint = Vector2.new(0.5, 0.5)
			ripple.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
			ripple.BackgroundTransparency = 0.3
			ripple.ZIndex = 4
			ripple.Parent = favBtn
			Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)
			
			TweenService:Create(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(2, 0, 2, 0),
				BackgroundTransparency = 1
			}):Play()
			task.delay(0.4, function() if ripple then ripple:Destroy() end end)
		else
			TweenService:Create(favIcon, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = UDim2.new(0, iconSize - 4, 0, iconSize - 4)
			}):Play()
			task.delay(0.2, function()
				TweenService:Create(favIcon, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, iconSize, 0, iconSize)
				}):Play()
			end)
		end
		
		if currentTab == "favorites" then
			task.delay(0.4, function()
				if currentTab == "favorites" then UpdateTabData() end
			end)
		end
	end)

	local kbHasBinding = GetKeybind(emote.id) ~= nil
	if (not isMobile) or _isPlaylistMode then
		local kbBtn = Instance.new("TextButton")
		kbBtn.Size = UDim2.new(1, 0, 0, KB_H)
		kbBtn.Position = UDim2.new(0, 0, 0, 0)
		kbBtn.BackgroundColor3 = _isPlaylistMode and Color3.fromRGB(0, 120, 255) or currentTheme.accent
		kbBtn.BackgroundTransparency = _isPlaylistMode and 0 or 1
		kbBtn.Text = _isPlaylistMode and L.selectEmote or ""
		kbBtn.TextColor3 = Color3.new(1,1,1)
		kbBtn.Font = Enum.Font.GothamBold
		kbBtn.TextSize = 12
		kbBtn.ZIndex = 4
		if _isPlaylistMode then
			kbBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
		end
		kbBtn.ClipsDescendants = true
		kbBtn.Parent = cardContainer
		Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 4)

		local kbIcon = Instance.new("ImageLabel")
		kbIcon.Size = UDim2.new(0.95, 0, 0.95, 0)
		kbIcon.Position = UDim2.fromScale(0.5, 0.5)
		kbIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		kbIcon.BackgroundTransparency = 1
		kbIcon.ScaleType = Enum.ScaleType.Fit
		if _isPlaylistMode then
			kbIcon.Image = ""
		else
			kbIcon.Image = ResolveAssetImage(kbHasBinding and Icons.KeybindActive or Icons.Keybind)
		end
		kbIcon.ImageColor3 = kbHasBinding and currentTheme.accent or currentTheme.textDim
		kbIcon.ZIndex = 5
		kbIcon.Active = false
		kbIcon.Visible = not _isPlaylistMode
		kbIcon.Parent = kbBtn

		kbBtn.MouseEnter:Connect(function()
			local isSel = _selectedEmotesForPlaylist and _selectedEmotesForPlaylist[tostring(emote.id)]
			local targetCol
			if _isPlaylistMode then
				if isSel then
					targetCol = Color3.fromRGB(40, 180, 100)
				else
					targetCol = Color3.fromRGB(0, 150, 255)
				end
			else
				targetCol = kbHasBinding and currentTheme.tertiary or currentTheme.accent
			end
			TweenService:Create(kbBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
				BackgroundColor3 = targetCol,
				BackgroundTransparency = _isPlaylistMode and 0 or 1,
				Size = UDim2.new(1, 6, 0, KB_H + 6),
				Rotation = 0
			}):Play()
		end)
		kbBtn.MouseLeave:Connect(function()
			local isSel = _selectedEmotesForPlaylist and _selectedEmotesForPlaylist[tostring(emote.id)]
			local targetCol
			if _isPlaylistMode then
				if isSel then
					targetCol = Color3.fromRGB(46, 204, 113)
				else
					targetCol = Color3.fromRGB(0, 120, 255)
				end
			else
				targetCol = currentTheme.stroke
			end
			TweenService:Create(kbBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
				BackgroundColor3 = targetCol,
				BackgroundTransparency = _isPlaylistMode and 0 or 1,
				Size = UDim2.new(1, 0, 0, KB_H),
				Rotation = 0
			}):Play()
		end)

		local function _UpdateSelectState()
		local isSel = _selectedEmotesForPlaylist[tostring(emote.id)]
		print("[Emotes] _UpdateSelectState: " .. tostring(emote.name) .. " isSel=" .. tostring(isSel))
		kbBtn.Text = isSel and "" or L.selectEmote
		kbIcon.Image = isSel and "rbxthumb://type=Asset&id=120391439283611&w=150&h=150" or ""
		if _isPlaylistMode then
			kbIcon.Visible = isSel
			kbIcon.ImageColor3 = Color3.new(1, 1, 1)
			if isSel then
				kbBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
				kbBtn.BackgroundTransparency = 0
			else
				kbBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
				kbBtn.BackgroundTransparency = 0
			end
		else
			kbIcon.Visible = true
		end
	end
	if _isPlaylistMode then _UpdateSelectState() end

	kbBtn.MouseButton1Click:Connect(function()
		print("[Emotes] kbBtn clicked: " .. tostring(emote.name) .. " isPlaylistMode=" .. tostring(_isPlaylistMode))
		if _isPlaylistMode then
			local k = tostring(emote.id)
			_selectedEmotesForPlaylist[k] = not _selectedEmotesForPlaylist[k]
			_UpdateSelectState()
			return
		end

			ShowKeybindDialog(emote.id, emote, kbHasBinding)
		end)

		local longPressTimer = nil
		local longPressOverlay = nil

		local function ShowRemoveOverlay()
			if not GetKeybind(emote.id) then return end
			if longPressOverlay then return end
			longPressOverlay = Instance.new("Frame")
			longPressOverlay.Size = UDim2.new(1, 0, 0, 0)
			longPressOverlay.Position = UDim2.new(0, 0, 1, 0)
			longPressOverlay.AnchorPoint = Vector2.new(0, 1)
			longPressOverlay.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
			longPressOverlay.BackgroundTransparency = 0.2
			longPressOverlay.ZIndex = 15
			longPressOverlay.ClipsDescendants = true
			longPressOverlay.Parent = card
			Instance.new("UICorner", longPressOverlay).CornerRadius = UDim.new(0, 8)
			TweenService:Create(longPressOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0)
			}):Play()
			local removeIcon = Instance.new("ImageButton")
			removeIcon.Size = UDim2.new(0, 42, 0, 42)
			removeIcon.Position = UDim2.fromScale(0.5, 0.5)
			removeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
			removeIcon.BackgroundTransparency = 1
			removeIcon.Image = ResolveAssetImage(Icons.KeybindRemove)
			removeIcon.ImageColor3 = Color3.new(1, 1, 1)
			removeIcon.ZIndex = 16
			removeIcon.Parent = longPressOverlay
			removeIcon.MouseButton1Click:Connect(function()
				RemoveKeybind(emote.id)
				kbHasBinding = false
				kbIcon.Image = ResolveAssetImage(Icons.Keybind)
				kbIcon.ImageColor3 = currentTheme.textDim
				if longPressOverlay then longPressOverlay:Destroy(); longPressOverlay = nil end
			end)
			task.delay(2.5, function()
				if longPressOverlay then
					TweenService:Create(longPressOverlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
					task.delay(0.2, function()
						if longPressOverlay then longPressOverlay:Destroy(); longPressOverlay = nil end
					end)
				end
			end)
		end

		local pressStart = 0
		card.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				pressStart = tick()
				longPressTimer = task.delay(0.6, ShowRemoveOverlay)
			end
		end)
		card.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				if longPressTimer then task.cancel(longPressTimer); longPressTimer = nil end
				if tick() - pressStart < 0.4 and longPressOverlay then
					longPressOverlay:Destroy(); longPressOverlay = nil
				end
			end
		end)
	end

	card.MouseEnter:Connect(function()
		local hoverColor = currentTheme.strokeHover or currentTheme.accent
		TweenService:Create(card, TweenInfo.new(0.18), {
			BackgroundColor3 = currentTheme.secondary,
			ImageTransparency = 0.04
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.18), {
			Transparency = 0.08,
			Thickness = 1.25,
			Color = hoverColor
		}):Play()
	end)

	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.18), {
			BackgroundColor3 = currentTheme.tertiary,
			ImageTransparency = 0
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.18), {
			Transparency = 0.72,
			Thickness = 1,
			Color = currentTheme.accent
		}):Play()
	end)
	card.MouseButton1Click:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.1), {ImageTransparency = 0.16}):Play()
		task.delay(0.15, function()
			if card.Parent then
				TweenService:Create(card, TweenInfo.new(0.15), {ImageTransparency = 0}):Play()
			end
		end)
		TweenService:Create(stroke, TweenInfo.new(0.1), {Color = Color3.fromRGB(80, 220, 120)}):Play()
		task.delay(0.3, function()
			if card.Parent then
				TweenService:Create(stroke, TweenInfo.new(0.2), {Color = currentTheme.accent}):Play()
			end
		end)
		
		if emote.isAnimationPack then ShowAnimationPackOptions(emote); return end
		if FriendData and FriendData.currentSyncPartner then
			FriendData.currentSyncPartner = nil
		end
		PlayEmote(emote.id, emote.name)
	end)

	return cardContainer
end

function UpdateCards(animate)
	if removeAnimationButton then removeAnimationButton:Destroy();removeAnimationButton=nil end
	ClearCards()
	
	local startIdx = (page - 1) * perPage + 1
	local endIdx = math.min(page * perPage, #filtered)
	
	local ci = 0
	for i = startIdx, endIdx do
		if filtered[i] then
			cards[i] = MakeCard(filtered[i], ci, animate)
			ci = ci + 1
		end
	end
	
	local CARD = currentCardSize
	local PAD = isMobile and 4 or 6
	local NAME_H = math.clamp(CARD * 0.35, 18, 28)
	local FAV_H = math.clamp(CARD * 0.3, 18, 24)
	local KB_H = ((not isMobile) or _isPlaylistMode) and math.clamp(CARD * 0.45, 30, 40) or 0
	local CARD_TOTAL_H = KB_H + CARD + NAME_H + FAV_H
	
	local rows = math.ceil(ci / math.max(cols, 1))
	scroll.CanvasSize = UDim2.new(0, 0, 0, rows * (CARD_TOTAL_H + PAD) + PAD)
	scroll.CanvasPosition = Vector2.zero

	if currentTab == "animations" then
		removeAnimationButton=Instance.new("TextButton")
		removeAnimationButton.Name="RemoveAnimations"
		removeAnimationButton.Size=UDim2.new(1,-16,0,40)
		removeAnimationButton.Position=UDim2.fromOffset(8,rows*(CARD_TOTAL_H+PAD)+PAD)
		removeAnimationButton.BackgroundColor3=currentTheme.tertiary
		removeAnimationButton.Text=isES and "Quitar animaciones" or "Remove animations"
		removeAnimationButton.TextColor3=currentTheme.text
		removeAnimationButton.Font=Enum.Font.GothamBold
		removeAnimationButton.TextSize=14
		removeAnimationButton.ZIndex=3
		removeAnimationButton.Parent=scroll
		Instance.new("UICorner",removeAnimationButton).CornerRadius=UDim.new(0,10)
		removeAnimationButton.Activated:Connect(function() RemoveAnimationPacks() end)
		scroll.CanvasSize=UDim2.new(0,0,0,rows*(CARD_TOTAL_H+PAD)+PAD+52)
	end


	local _npStart = page * perPage + 1
	local _npEnd   = math.min((page + 1) * perPage, #filtered)
	if _npStart <= _npEnd then
		task.spawn(function()
			local _imgs = {}
			for _i = _npStart, _npEnd do
				local _fe = filtered[_i]
				if _fe and not _badEmotes[tostring(_fe.id)] then
					local _img = Instance.new("ImageLabel")
					_img.Image = "rbxthumb://type=Asset&id=" .. _fe.id .. "&w=420&h=420"
					_imgs[#_imgs + 1] = _img
				end
			end
			if #_imgs > 0 then
				pcall(function() game:GetService("ContentProvider"):PreloadAsync(_imgs) end)
				for _, _img in ipairs(_imgs) do _img:Destroy() end
			end
		end)
	end
end

function Refresh(animate)
	CalcLayout()
	UpdatePageUI()
	UpdateCards(animate ~= false)
end

prevBtn.MouseButton1Click:Connect(function()
	if pages <= 1 then return end
	if page > 1 then 
		page = page - 1
	else 
		page = pages
	end
	Refresh(true)
end)
nextBtn.MouseButton1Click:Connect(function()
	if pages <= 1 then return end
	if page < pages then 
		page = page + 1
	else 
		page = 1
	end
	Refresh(true)
end)

-- ===============================================================

	return true
end
