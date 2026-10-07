-- Presentacion de marca previa a la interfaz principal.
return function(context)
	setfenv(1,context)

	local previous=gui:FindFirstChild("PsychoBrandIntro")
	if previous then previous:Destroy() end

	local overlay=Instance.new("Frame")
	overlay.Name="PsychoBrandIntro"
	overlay.Size=UDim2.fromScale(1,1)
	overlay.BackgroundColor3=Color3.fromRGB(12,13,17)
	overlay.BackgroundTransparency=1
	overlay.BorderSizePixel=0
	overlay.Active=true
	overlay.ZIndex=5000
	overlay.Parent=gui

	local shadow=Instance.new("Frame")
	shadow.Name="CardShadow"
	shadow.AnchorPoint=Vector2.new(.5,.5)
	shadow.Position=UDim2.new(.5,0,.5,7)
	shadow.Size=UDim2.new(0,isMobile and 250 or 286,0,isMobile and 92 or 104)
	shadow.BackgroundColor3=Color3.fromRGB(0,0,0)
	shadow.BackgroundTransparency=1
	shadow.BorderSizePixel=0
	shadow.ZIndex=5001
	shadow.Parent=overlay
	Instance.new("UICorner",shadow).CornerRadius=UDim.new(0,18)

	local card=Instance.new("Frame")
	card.Name="BrandCard"
	card.AnchorPoint=Vector2.new(.5,.5)
	card.Position=UDim2.fromScale(.5,.5)
	card.Size=shadow.Size
	card.BackgroundColor3=Color3.fromRGB(24,25,31)
	card.BackgroundTransparency=1
	card.BorderSizePixel=0
	card.ZIndex=5002
	card.Parent=overlay
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,18)
	local scale=Instance.new("UIScale")
	scale.Scale=.92
	scale.Parent=card
	local cardGradient=Instance.new("UIGradient")
	cardGradient.Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,Color3.fromRGB(31,32,39)),
		ColorSequenceKeypoint.new(1,Color3.fromRGB(19,20,25)),
	})
	cardGradient.Rotation=115
	cardGradient.Parent=card
	local stroke=Instance.new("UIStroke")
	stroke.Color=Color3.fromRGB(88,91,104)
	stroke.Thickness=1
	stroke.Transparency=1
	stroke.Parent=card

	local eyebrow=Instance.new("TextLabel")
	eyebrow.AnchorPoint=Vector2.new(.5,.5)
	eyebrow.Position=UDim2.fromScale(.5,.36)
	eyebrow.Size=UDim2.new(1,-32,0,16)
	eyebrow.BackgroundTransparency=1
	eyebrow.Text="POWERED BY"
	eyebrow.TextColor3=Color3.fromRGB(150,153,164)
	eyebrow.TextTransparency=1
	eyebrow.Font=Enum.Font.GothamMedium
	eyebrow.TextSize=isMobile and 9 or 10
	eyebrow.ZIndex=5003
	eyebrow.Parent=card

	local name=Instance.new("TextLabel")
	name.AnchorPoint=Vector2.new(.5,.5)
	name.Position=UDim2.fromScale(.5,.58)
	name.Size=UDim2.new(1,-32,0,28)
	name.BackgroundTransparency=1
	name.Text="psychoo"
	name.TextColor3=Color3.fromRGB(242,243,247)
	name.TextTransparency=1
	name.Font=Enum.Font.GothamSemibold
	name.TextSize=isMobile and 17 or 20
	name.ZIndex=5003
	name.Parent=card

	local accent=Instance.new("Frame")
	accent.AnchorPoint=Vector2.new(.5,.5)
	accent.Position=UDim2.fromScale(.5,.79)
	accent.Size=UDim2.new(0,0,0,2)
	accent.BackgroundColor3=Color3.fromRGB(128,136,164)
	accent.BackgroundTransparency=1
	accent.BorderSizePixel=0
	accent.ZIndex=5003
	accent.Parent=card
	Instance.new("UICorner",accent).CornerRadius=UDim.new(1,0)
	local accentGradient=Instance.new("UIGradient")
	accentGradient.Transparency=NumberSequence.new({
		NumberSequenceKeypoint.new(0,1),
		NumberSequenceKeypoint.new(.5,0),
		NumberSequenceKeypoint.new(1,1),
	})
	accentGradient.Parent=accent

	TweenService:Create(overlay,TweenInfo.new(.52,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{BackgroundTransparency=.06}):Play()
	TweenService:Create(shadow,TweenInfo.new(.64,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=.56}):Play()
	TweenService:Create(card,TweenInfo.new(.72,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=0}):Play()
	TweenService:Create(scale,TweenInfo.new(.78,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Scale=1}):Play()
	TweenService:Create(stroke,TweenInfo.new(.68,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Transparency=.48}):Play()
	TweenService:Create(eyebrow,TweenInfo.new(.62,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
	TweenService:Create(name,TweenInfo.new(.76,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
	TweenService:Create(accent,TweenInfo.new(.82,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,isMobile and 72 or 86,0,2),BackgroundTransparency=.18}):Play()

	task.wait(2.35)
	if not overlay.Parent then return true end
	TweenService:Create(eyebrow,TweenInfo.new(.52,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{TextTransparency=1}):Play()
	TweenService:Create(name,TweenInfo.new(.62,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{TextTransparency=1,Position=UDim2.fromScale(.5,.54)}):Play()
	TweenService:Create(accent,TweenInfo.new(.52,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Size=UDim2.new(0,0,0,2),BackgroundTransparency=1}):Play()
	TweenService:Create(stroke,TweenInfo.new(.58,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency=1}):Play()
	TweenService:Create(scale,TweenInfo.new(.68,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{Scale=.97}):Play()
	TweenService:Create(card,TweenInfo.new(.68,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{BackgroundTransparency=1}):Play()
	TweenService:Create(shadow,TweenInfo.new(.58,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{BackgroundTransparency=1}):Play()
	task.wait(.72)

	-- La pantalla oscura permanece arriba mientras se termina de construir la
	-- interfaz. initialize.lua enlaza su desvanecimiento con la aparición del panel.
	brandRevealScreen=overlay
	brandRevealCard=card
	return true
end