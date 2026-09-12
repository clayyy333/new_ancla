-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

gui = Instance.new("ScreenGui")
gui.Name = "VexroEmotes"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- ===============================================================
-- LANGUAGE SELECTION
-- ===============================================================

selectedLang = nil

if Settings.language and Settings.language ~= "" then
	selectedLang = Settings.language
end

if not selectedLang then

local langTheme = Themes[Settings.theme] or Themes.Dark
if not Settings.theme or Settings.theme == "" then langTheme = Themes.Dark end

langScreen = Instance.new("Frame")
langScreen.Size = UDim2.fromScale(1, 1)
langScreen.BackgroundColor3 = langTheme.primary
langScreen.ZIndex = 20000
langScreen.Parent = gui

langBox = Instance.new("Frame")
langBox.Size = UDim2.new(0, 0, 0, 0)
langBox.Position = UDim2.fromScale(0.5, 0.5)
langBox.AnchorPoint = Vector2.new(0.5, 0.5)
langBox.BackgroundColor3 = langTheme.secondary
langBox.ZIndex = 20001
langBox.Rotation = -15
langBox.Parent = langScreen
Instance.new("UICorner", langBox).CornerRadius = UDim.new(0, 20)

langBoxStroke = Instance.new("UIStroke")
langBoxStroke.Color = langTheme.stroke
langBoxStroke.Thickness = 2
langBoxStroke.Parent = langBox

langStrokeGrad = Instance.new("UIGradient")
langStrokeGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, langTheme.accent),
	ColorSequenceKeypoint.new(0.5, langTheme.stroke),
	ColorSequenceKeypoint.new(1, langTheme.accent)
}
langStrokeGrad.Parent = langBoxStroke

task.spawn(function()
	local rot = 0
	while langBoxStroke.Parent do
		rot = rot + 360
		TweenService:Create(langStrokeGrad, TweenInfo.new(8, Enum.EasingStyle.Linear), {Rotation = rot}):Play()
		task.wait(8)
	end
end)

langTitle = Instance.new("TextLabel")
langTitle.Size = UDim2.new(1, 0, 0, 45)
langTitle.Position = UDim2.new(0, 0, 0, 20)
langTitle.BackgroundTransparency = 1
langTitle.Text = "Idioma"
langTitle.TextColor3 = Color3.new(1, 1, 1)
langTitle.Font = Enum.Font.GothamBold
langTitle.TextScaled = true
langTitle.ZIndex = 20002
langTitle.Parent = langBox

local function MakeLangBtn(txt, flag, index, lang)
	local col = index <= 4 and 0 or 1
	local row = (index - 1) % 4
	local x = col == 0 and 0.04 or 0.52
	local y = 80 + (row * 65)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.44, 0, 0, 55)
	btn.Position = UDim2.new(x, 0, 0, y)
	btn.BackgroundColor3 = langTheme.tertiary
	btn.Text = txt
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextColor3 = langTheme.text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = isMobile and 14 or 16
	btn.ZIndex = 20003
	btn.Parent = langBox
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

	local textPadding = Instance.new("UIPadding")
	textPadding.PaddingLeft = UDim.new(0, isMobile and 10 or 14)
	textPadding.PaddingRight = UDim.new(0, 44)
	textPadding.Parent = btn

	local flagLabel = Instance.new("TextLabel")
	flagLabel.Size = UDim2.new(0, 36, 1, 0)
	flagLabel.Position = UDim2.new(1, -42, 0, 0)
	flagLabel.BackgroundTransparency = 1
	flagLabel.Text = flag
	flagLabel.TextSize = isMobile and 16 or 18
	flagLabel.ZIndex = 20005
	flagLabel.Parent = btn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = langTheme.stroke
	btnStroke.Transparency = 0.5
	btnStroke.Parent = btn
	
	local shine = Instance.new("Frame")
	shine.Size = UDim2.new(0, 0, 1, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.9
	shine.ZIndex = 20004
	shine.Parent = btn
	Instance.new("UICorner", shine).CornerRadius = UDim.new(0, 12)
	
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = langTheme.accent}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0, Color = langTheme.accent}):Play()
		TweenService:Create(shine, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 1, 0)}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = langTheme.tertiary}):Play()
		TweenService:Create(btnStroke, TweenInfo.new(0.2), {Transparency = 0.5, Color = langTheme.stroke}):Play()
		TweenService:Create(shine, TweenInfo.new(0.3), {Size = UDim2.new(0, 0, 1, 0)}):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		local ripple = Instance.new("Frame")
		ripple.Size = UDim2.new(0, 0, 0, 0)
		ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
		ripple.AnchorPoint = Vector2.new(0.5, 0.5)
		ripple.BackgroundColor3 = langTheme.accent
		ripple.BackgroundTransparency = 0.7
		ripple.ZIndex = 20005
		ripple.Parent = btn
		Instance.new("UICorner", ripple).CornerRadius = UDim.new(1, 0)

		TweenService:Create(ripple, TweenInfo.new(0.4), {Size = UDim2.new(2, 0, 2, 0), BackgroundTransparency = 1}):Play()
		TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = langTheme.accent}):Play()
		task.delay(0.4, function() ripple:Destroy() end)
		task.wait(0.15)
		selectedLang = lang
	end)
end

MakeLangBtn("Türkçe", "🇹🇷", 1, "TR")
MakeLangBtn("English", "🇬🇧", 2, "EN")
MakeLangBtn("Español", "🇪🇸", 3, "ES")
MakeLangBtn("العربية", "🇸🇦", 4, "AR")
MakeLangBtn("Français", "🇫🇷", 5, "FR")
MakeLangBtn("हिन्दी", "🇮🇳", 6, "HI")
MakeLangBtn("Português", "🇵🇹", 7, "PT")
MakeLangBtn("Русский", "🇷🇺", 8, "RU")

local targetSize = isMobile and UDim2.new(0, 380, 0, 350) or UDim2.new(0, 480, 0, 350)
TweenService:Create(langBox, TweenInfo.new(0.6, Enum.EasingStyle.Back), {Size = targetSize, Rotation = 0}):Play()

repeat task.wait(0.1) until selectedLang

Settings.language = selectedLang
SaveData()

local revealLine = Instance.new("Frame")
revealLine.Name = "LanguageRevealLine"
revealLine.Size = UDim2.new(0, 0, 0, isMobile and 2 or 3)
revealLine.Position = UDim2.fromScale(0.5, 0.5)
revealLine.AnchorPoint = Vector2.new(0.5, 0.5)
revealLine.BackgroundColor3 = langTheme.accent
revealLine.BorderSizePixel = 0
revealLine.ZIndex = 20006
revealLine.Parent = langScreen
Instance.new("UICorner", revealLine).CornerRadius = UDim.new(1, 0)

local revealGradient = Instance.new("UIGradient")
revealGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, langTheme.stroke),
	ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
	ColorSequenceKeypoint.new(1, langTheme.accent)
}
revealGradient.Parent = revealLine

for _, object in ipairs(langBox:GetDescendants()) do
	if object:IsA("GuiObject") then
		TweenService:Create(object, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	end
	if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
		TweenService:Create(object, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
	end
	if object:IsA("UIStroke") then
		TweenService:Create(object, TweenInfo.new(0.20), {Transparency = 1}):Play()
	end
end
TweenService:Create(langBox, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
	Position = UDim2.fromScale(0.5, 0.485),
	BackgroundTransparency = 1
}):Play()
TweenService:Create(revealLine, TweenInfo.new(0.46, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
	Size = UDim2.new(0.68, 0, 0, isMobile and 2 or 3)
}):Play()
task.wait(0.46)
langBox.Visible = false
languageRevealScreen = langScreen
languageRevealLine = revealLine

end

-- ===============================================================
-- LANGUAGE
-- ===============================================================

	return true
end
