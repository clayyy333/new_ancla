-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

-- INITIALIZE
-- ===============================================================

main.Rotation = 0
openSize = GetDefaultSize()
if brandRevealScreen and brandRevealScreen.Parent then
	if languageRevealScreen and languageRevealScreen.Parent then
		languageRevealScreen:Destroy()
		languageRevealScreen=nil
		languageRevealLine=nil
	end
	-- La GUI ya fue calculada detrás de la presentación. Solo revelamos el
	-- resultado terminado para no recalcular el layout durante la transición.
	main.Size=openSize
	main.BackgroundTransparency=0
	mainStroke.Transparency=0
	main.Visible=true
	TweenService:Create(brandRevealScreen,TweenInfo.new(.82,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=1}):Play()
	task.wait(.84)
	if brandRevealRoot and brandRevealRoot.Parent then
		brandRevealRoot:Destroy()
	elseif brandRevealScreen and brandRevealScreen.Parent then
		brandRevealScreen:Destroy()
	end
	brandRevealRoot=nil
	brandRevealScreen=nil
	brandRevealCard=nil
elseif languageRevealScreen and languageRevealScreen.Parent then
	main.Size = UDim2.new(openSize.X.Scale * 0.96, math.floor(openSize.X.Offset * 0.96), openSize.Y.Scale * 0.96, math.floor(openSize.Y.Offset * 0.96))
	main.BackgroundTransparency = 1
	mainStroke.Transparency = 1
	TweenService:Create(main, TweenInfo.new(0.58, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = openSize, BackgroundTransparency = 0}):Play()
	TweenService:Create(mainStroke, TweenInfo.new(0.48, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0}):Play()
	TweenService:Create(languageRevealScreen, TweenInfo.new(0.62, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	if languageRevealLine and languageRevealLine.Parent then
		TweenService:Create(languageRevealLine, TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Size = UDim2.new(0.9, 0, 0, 1),
			BackgroundTransparency = 1
		}):Play()
	end
	task.wait(0.64)
	languageRevealScreen:Destroy()
	languageRevealScreen = nil
	languageRevealLine = nil
else
	TweenService:Create(main, TweenInfo.new(0.45, Enum.EasingStyle.Back), {Size = openSize, BackgroundTransparency = 0}):Play()
	TweenService:Create(mainStroke, TweenInfo.new(0.45), {Transparency = 0}):Play()
	task.wait(0.5)
end

main.ClipsDescendants = true
ApplyTheme(Settings.theme)
UpdateTabStyles()
UpdateTabData()

_keybindInputConn = nil
if not isMobile then
	_keybindInputConn = UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local keyName = inp.KeyCode.Name
		for emoteId, kb in pairs(KeybindsSet) do
			if type(kb) == "table" and kb.key == keyName then
				local emote = EmotesById[emoteId]
				if emote then
					PlayEmote(emote.id, emote.name)
				end
				break
			end
		end
	end)
end

task.wait(0.25)
Notify(SafeUtf8Char(0x2705) .. " " .. L.ready, #Emotes .. " emotes")

-- ================================================================
-- Bölüm 1: Dinamik Tema  |  Bölüm 2: Animation Blending & Combo
-- Bölüm 3: Canlı Emote HUD  |  Bölüm 4: Entegrasyon
-- NOT: do...end bloğu Lua'nın 200 local sınırını aşmamak için
-- ================================================================

-- ----------------------------------------------------------------
-- ----------------------------------------------------------------

	return true
end
