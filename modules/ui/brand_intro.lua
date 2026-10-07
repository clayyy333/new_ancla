-- Presentacion de marca previa a la interfaz principal.
return function(context)
	setfenv(1,context)

	local previous=gui:FindFirstChild("PsychoBrandIntro")
	if previous then previous:Destroy() end

	local overlay=Instance.new("Frame")
	overlay.Name="PsychoBrandIntro"
	overlay.Size=UDim2.fromScale(1,1)
	overlay.BackgroundColor3=Color3.fromRGB(14,15,18)
	overlay.BackgroundTransparency=0
	overlay.BorderSizePixel=0
	overlay.Active=true
	overlay.ZIndex=5000
	overlay.Parent=gui

	local cardSize=UDim2.new(0,isMobile and 224 or 258,0,isMobile and 78 or 88)
	local shadow=Instance.new("Frame")
	shadow.Name="CardShadow"
	shadow.AnchorPoint=Vector2.new(.5,.5)
	shadow.Position=UDim2.new(.5,0,.5,5)
	shadow.Size=cardSize
	shadow.BackgroundColor3=Color3.fromRGB(0,0,0)
	shadow.BackgroundTransparency=1
	shadow.BorderSizePixel=0
	shadow.ZIndex=5001
	shadow.Parent=overlay
	Instance.new("UICorner",shadow).CornerRadius=UDim.new(0,11)

	local card=Instance.new("Frame")
	card.Name="BrandCard"
	card.AnchorPoint=Vector2.new(.5,.5)
	card.Position=UDim2.fromScale(.5,.5)
	card.Size=cardSize
	card.BackgroundColor3=Color3.fromRGB(18,19,23)
	card.BackgroundTransparency=1
	card.BorderSizePixel=0
	card.ZIndex=5002
	card.Parent=overlay
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,10)
	local scale=Instance.new("UIScale")
	scale.Scale=.95
	scale.Parent=card
	local cardGradient=Instance.new("UIGradient")
	cardGradient.Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.fromRGB(24,25,30)),
		ColorSequenceKeypoint.new(1,Color3.fromRGB(15,16,20)),
	})
	cardGradient.Rotation=110
	cardGradient.Parent=card
	local stroke=Instance.new("UIStroke")
	stroke.Color=Color3.fromRGB(31,33,39)
	stroke.Thickness=1
	stroke.Transparency=.12
	stroke.Parent=card

	local title=Instance.new("TextLabel")
	title.AnchorPoint=Vector2.new(.5,.5)
	title.Position=UDim2.fromScale(.5,.47)
	title.Size=UDim2.new(1,-28,0,isMobile and 40 or 46)
	title.BackgroundTransparency=1
	title.RichText=true
	title.Text=isMobile
		and '<font face="GothamMedium" size="9" color="#92949D">POWERED BY</font>\n<font face="GothamBold" size="17" color="#ECEEF2">psychoo</font>'
		or '<font face="GothamMedium" size="10" color="#92949D">POWERED BY</font>\n<font face="GothamBold" size="19" color="#ECEEF2">psychoo</font>'
	title.TextColor3=Color3.fromRGB(236,238,242)
	title.TextTransparency=1
	title.Font=Enum.Font.Gotham
	title.TextSize=isMobile and 17 or 19
	title.TextWrapped=true
	title.ZIndex=5003
	title.Parent=card

	local accent=Instance.new("Frame")
	accent.AnchorPoint=Vector2.new(.5,.5)
	accent.Position=UDim2.fromScale(.5,.80)
	accent.Size=UDim2.new(0,0,0,1)
	accent.BackgroundColor3=Color3.fromRGB(91,96,111)
	accent.BackgroundTransparency=1
	accent.BorderSizePixel=0
	accent.ZIndex=5003
	accent.Parent=card
	Instance.new("UICorner",accent).CornerRadius=UDim.new(1,0)
	local accentGradient=Instance.new("UIGradient")
	accentGradient.Transparency=NumberSequence.new({
		NumberSequenceKeypoint.new(0,1),
		NumberSequenceKeypoint.new(.5,.05),
		NumberSequenceKeypoint.new(1,1),
	})
	accentGradient.Parent=accent

	-- Calcula toda la ventana detrás de una cubierta opaca. Esto evita que el
	-- primer layout pesado ocurra durante el crossfade final.
	if main and main.Parent then
		main.Size=GetDefaultSize()
		main.BackgroundTransparency=0
		if mainStroke then mainStroke.Transparency=0 end
	end
	RunService.Heartbeat:Wait()
	if not overlay.Parent then return true end

	TweenService:Create(shadow,TweenInfo.new(.64,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{BackgroundTransparency=.66}):Play()
	TweenService:Create(card,TweenInfo.new(.72,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{BackgroundTransparency=0}):Play()
	TweenService:Create(scale,TweenInfo.new(.76,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Scale=1}):Play()
	TweenService:Create(title,TweenInfo.new(.68,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
	TweenService:Create(accent,TweenInfo.new(.78,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,isMobile and 62 or 72,0,1),BackgroundTransparency=.2}):Play()

	task.wait(2.35)
	if not overlay.Parent then return true end
	TweenService:Create(title,TweenInfo.new(.58,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{TextTransparency=1,Position=UDim2.fromScale(.5,.44)}):Play()
	TweenService:Create(accent,TweenInfo.new(.54,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Size=UDim2.new(0,0,0,1),BackgroundTransparency=1}):Play()
	TweenService:Create(scale,TweenInfo.new(.66,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{Scale=.975}):Play()
	TweenService:Create(card,TweenInfo.new(.66,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=1}):Play()
	TweenService:Create(shadow,TweenInfo.new(.58,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=1}):Play()
	task.wait(.70)

	-- La pantalla oscura permanece arriba mientras se termina de construir la
	-- interfaz. initialize.lua enlaza su desvanecimiento con la aparición del panel.
	brandRevealScreen=overlay
	brandRevealCard=card
	return true
end