-- Presentacion visual ligera antes de mostrar la interfaz principal.
return function(context)
	setfenv(1,context)

	local previous=gui:FindFirstChild("PsychoBrandIntro")
	if previous then previous:Destroy() end

	local overlay=Instance.new("Frame")
	overlay.Name="PsychoBrandIntro"
	overlay.Size=UDim2.fromScale(1,1)
	overlay.BackgroundColor3=Color3.fromRGB(7,8,12)
	overlay.BackgroundTransparency=1
	overlay.BorderSizePixel=0
	overlay.Active=true
	overlay.ZIndex=5000
	overlay.Parent=gui

	local glow=Instance.new("Frame")
	glow.Name="SoftGlow"
	glow.AnchorPoint=Vector2.new(.5,.5)
	glow.Position=UDim2.fromScale(.5,.5)
	glow.Size=UDim2.new(0,isMobile and 250 or 330,0,isMobile and 82 or 96)
	glow.BackgroundColor3=currentTheme.secondary
	glow.BackgroundTransparency=1
	glow.BorderSizePixel=0
	glow.ZIndex=5001
	glow.Parent=overlay
	Instance.new("UICorner",glow).CornerRadius=UDim.new(0,18)
	local glowStroke=Instance.new("UIStroke")
	glowStroke.Color=currentTheme.accent
	glowStroke.Thickness=1
	glowStroke.Transparency=1
	glowStroke.Parent=glow

	local title=Instance.new("TextLabel")
	title.AnchorPoint=Vector2.new(.5,.5)
	title.Position=UDim2.fromScale(.5,.43)
	title.Size=UDim2.new(1,-28,0,isMobile and 25 or 30)
	title.BackgroundTransparency=1
	title.Text="Powered by psychoo"
	title.TextColor3=currentTheme.text
	title.TextTransparency=1
	title.Font=Enum.Font.GothamMedium
	title.TextSize=isMobile and 16 or 19
	title.TextXAlignment=Enum.TextXAlignment.Center
	title.ZIndex=5002
	title.Parent=glow

	local line=Instance.new("Frame")
	line.AnchorPoint=Vector2.new(.5,.5)
	line.Position=UDim2.fromScale(.5,.72)
	line.Size=UDim2.new(0,0,0,2)
	line.BackgroundColor3=currentTheme.accent
	line.BackgroundTransparency=1
	line.BorderSizePixel=0
	line.ZIndex=5002
	line.Parent=glow
	Instance.new("UICorner",line).CornerRadius=UDim.new(1,0)
	local lineGradient=Instance.new("UIGradient")
	lineGradient.Color=ColorSequence.new({
		ColorSequenceKeypoint.new(0,currentTheme.stroke),
		ColorSequenceKeypoint.new(.5,currentTheme.accent),
		ColorSequenceKeypoint.new(1,currentTheme.stroke),
	})
	lineGradient.Parent=line

	task.spawn(function()
		if not overlay.Parent then return end
		TweenService:Create(overlay,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=.08}):Play()
		TweenService:Create(glow,TweenInfo.new(.4,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=.18}):Play()
		TweenService:Create(glowStroke,TweenInfo.new(.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Transparency=.55}):Play()
		TweenService:Create(title,TweenInfo.new(.42,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{TextTransparency=0}):Play()
		TweenService:Create(line,TweenInfo.new(.48,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,isMobile and 92 or 118,0,2),BackgroundTransparency=.1}):Play()
		task.wait(1.25)
		if not overlay.Parent then return end
		TweenService:Create(title,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{TextTransparency=1}):Play()
		TweenService:Create(line,TweenInfo.new(.28,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,0,0,2),BackgroundTransparency=1}):Play()
		TweenService:Create(glowStroke,TweenInfo.new(.3),{Transparency=1}):Play()
		TweenService:Create(glow,TweenInfo.new(.34,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()
		TweenService:Create(overlay,TweenInfo.new(.38,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{BackgroundTransparency=1}):Play()
		task.wait(.4)
		if overlay.Parent then overlay:Destroy() end
	end)

	return true
end