-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

comboQueue_UI = {}

comboRow = MakeRow("", L.comboTitle, "", 25, 196)
comboRow.Size             = UDim2.new(1, 0, 0, 196)
comboRow.ClipsDescendants = true

comboTitleLbl = comboRow:FindFirstChildWhichIsA("TextLabel")
if comboTitleLbl then
	comboTitleLbl.Size     = UDim2.new(1, -12, 0, 20)
	comboTitleLbl.Position = UDim2.new(0, 10, 0, 5)
	comboTitleLbl.TextSize = 13
end

slotHolder = Instance.new("Frame")
slotHolder.Size             = UDim2.new(1, -12, 0, 36)
slotHolder.Position         = UDim2.new(0, 6, 0, 28)
slotHolder.BackgroundTransparency = 1
slotHolder.ZIndex           = 9
slotHolder.Parent           = comboRow
slotLayout = Instance.new("UIListLayout")
slotLayout.FillDirection    = Enum.FillDirection.Horizontal
slotLayout.Padding          = UDim.new(0, 5)
slotLayout.Parent           = slotHolder

comboSlots = {}
for si = 1, 3 do
	local s = Instance.new("TextButton")
	s.Size             = UDim2.new(0.316, 0, 1, 0)
	s.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
	s.Text             = L.slotLabel .. " " .. si
	s.TextColor3       = Color3.fromRGB(120, 120, 148)
	s.Font             = Enum.Font.Gotham
	s.TextSize         = 11
	s.ZIndex           = 9
	s.Parent           = slotHolder
	Instance.new("UICorner", s).CornerRadius = UDim.new(0, 8)
	comboSlots[si] = s
	s.MouseButton1Click:Connect(function()
		if comboQueue_UI[si] then
			table.remove(comboQueue_UI, si)
			for j = 1, 3 do
				local e = comboQueue_UI[j]
				comboSlots[j].Text = e and e.name:sub(1,9) or ("Slot " .. j)
				TweenService:Create(comboSlots[j], TweenInfo.new(0.15), {
					BackgroundColor3 = e and currentTheme.accent or Color3.fromRGB(30,30,46)
				}):Play()
			end
		end
	end)
end

comboBtnHolder = Instance.new("Frame")
comboBtnHolder.Size             = UDim2.new(1, -12, 0, 30)
comboBtnHolder.Position         = UDim2.new(0, 6, 0, 70)
comboBtnHolder.BackgroundTransparency = 1
comboBtnHolder.ZIndex           = 9
comboBtnHolder.Parent           = comboRow
comboBtnLayout = Instance.new("UIListLayout")
comboBtnLayout.FillDirection    = Enum.FillDirection.Horizontal
comboBtnLayout.Padding          = UDim.new(0, 5)
comboBtnLayout.Parent           = comboBtnHolder

addComboBtn = Instance.new("TextButton")
addComboBtn.Size             = UDim2.new(0.5, -2, 1, 0)
addComboBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 170)
addComboBtn.Text             = L.addEmote
addComboBtn.TextColor3       = Color3.new(1, 1, 1)
addComboBtn.Font             = Enum.Font.GothamBold
addComboBtn.TextSize         = 12
addComboBtn.ZIndex           = 9
addComboBtn.Parent           = comboBtnHolder
Instance.new("UICorner", addComboBtn).CornerRadius = UDim.new(0, 8)

playComboBtn = Instance.new("TextButton")
playComboBtn.Size             = UDim2.new(0.5, -2, 1, 0)
playComboBtn.BackgroundColor3 = Color3.fromRGB(60, 140, 80)
playComboBtn.Text             = L.playCombo
playComboBtn.TextColor3       = Color3.new(1, 1, 1)
playComboBtn.Font             = Enum.Font.GothamBold
playComboBtn.TextSize         = 12
playComboBtn.ZIndex           = 9
playComboBtn.Parent           = comboBtnHolder
Instance.new("UICorner", playComboBtn).CornerRadius = UDim.new(0, 8)

loopComboBtn = Instance.new("TextButton")
loopComboBtn.Size             = UDim2.new(1, -12, 0, 26)
loopComboBtn.Position         = UDim2.new(0, 6, 0, 106)
loopComboBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
loopComboBtn.Text             = L.loopText .. ": " .. L.off
loopComboBtn.TextColor3       = Color3.fromRGB(120, 120, 148)
loopComboBtn.Font             = Enum.Font.GothamBold
loopComboBtn.TextSize         = 12
loopComboBtn.ZIndex           = 9
loopComboBtn.Parent           = comboRow
Instance.new("UICorner", loopComboBtn).CornerRadius = UDim.new(0, 8)
loopStroke = Instance.new("UIStroke")
loopStroke.Color        = Color3.fromRGB(60, 60, 90)
loopStroke.Thickness    = 1
loopStroke.Transparency = 0.5
loopStroke.Parent       = loopComboBtn
loopIcon = Instance.new("ImageLabel")
loopIcon.Size                   = UDim2.new(0, 14, 0, 14)
loopIcon.Position               = UDim2.new(0, 8, 0.5, -7)
loopIcon.BackgroundTransparency = 1
loopIcon.Image                  = ResolveAssetImage(Icons.Refresh)
loopIcon.ImageColor3            = Color3.fromRGB(120, 120, 148)
loopIcon.ZIndex                 = 10
loopIcon.Parent                 = loopComboBtn
loopComboBtn.TextXAlignment = Enum.TextXAlignment.Center

loopComboBtn.MouseButton1Click:Connect(function()
	_comboLoopEnabled = not _comboLoopEnabled
	if _comboLoopEnabled then
		loopComboBtn.Text             = L.loopText .. ": " .. L.on
		loopComboBtn.TextColor3       = Color3.new(1, 1, 1)
		loopIcon.ImageColor3          = Color3.new(1, 1, 1)
		TweenService:Create(loopComboBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = currentTheme.accent
		}):Play()
		loopStroke.Color = currentTheme.accent
	else
		loopComboBtn.Text             = L.loopText .. ": " .. L.off
		loopComboBtn.TextColor3       = Color3.fromRGB(120, 120, 148)
		loopIcon.ImageColor3          = Color3.fromRGB(120, 120, 148)
		TweenService:Create(loopComboBtn, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(30, 30, 46)
		}):Play()
		loopStroke.Color = Color3.fromRGB(60, 60, 90)
	end
end)

clearComboBtn = Instance.new("TextButton")
clearComboBtn.Size             = UDim2.new(1, -12, 0, 26)
clearComboBtn.Position         = UDim2.new(0, 6, 0, 138)
clearComboBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
clearComboBtn.Text             = L.clearCombo
clearComboBtn.TextColor3       = Color3.new(1, 1, 1)
clearComboBtn.Font             = Enum.Font.GothamBold
clearComboBtn.TextSize         = 12
clearComboBtn.ZIndex           = 9
clearComboBtn.Parent           = comboRow
Instance.new("UICorner", clearComboBtn).CornerRadius = UDim.new(0, 8)

addComboBtn.MouseButton1Click:Connect(function()
	if #comboQueue_UI >= 3 then return end
	if not _currentInfoId then
		local origCol = addComboBtn.BackgroundColor3
		addComboBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		addComboBtn.Text = L.selectFirst
		task.delay(0.7, function()
			addComboBtn.BackgroundColor3 = origCol
			addComboBtn.Text = L.addEmote
		end)
		return
	end
	table.insert(comboQueue_UI, {id = _currentInfoId, name = _currentInfoName or "Emote"})
	local idx = #comboQueue_UI
	comboSlots[idx].Text = (comboQueue_UI[idx].name):sub(1, 9)
	TweenService:Create(comboSlots[idx], TweenInfo.new(0.15), {
		BackgroundColor3 = currentTheme.accent
	}):Play()
end)

playComboBtn.MouseButton1Click:Connect(function()
	if #comboQueue_UI == 0 then return end
	local list = {}
	for _, e in ipairs(comboQueue_UI) do
		table.insert(list, {id = e.id, name = e.name})
	end
	StartCombo(list)
end)

clearComboBtn.MouseButton1Click:Connect(function()
	comboQueue_UI    = {}
	isComboActive    = false
	ComboQueue       = {}
	_comboLoopList   = {}
	if _comboLoopEnabled then
		_comboLoopEnabled             = false
		loopComboBtn.Text             = L.loopText .. ": " .. L.off
		loopComboBtn.TextColor3       = Color3.fromRGB(120, 120, 148)
		loopComboBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
		loopStroke.Color              = Color3.fromRGB(60, 60, 90)
		loopIcon.ImageColor3          = Color3.fromRGB(120, 120, 148)
	end
	for j = 1, 3 do
		comboSlots[j].Text = L.slotLabel .. " " .. j
		TweenService:Create(comboSlots[j], TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(30, 30, 46)
		}):Play()
	end
end)

do
	local _prevApply = ApplyTheme
	ApplyTheme = function(name)
		_prevApply(name)
		if _comboLoopEnabled and loopComboBtn and loopComboBtn.Parent then
			pcall(function()
				loopComboBtn.BackgroundColor3 = currentTheme.accent
				loopStroke.Color             = currentTheme.accent
				loopIcon.ImageColor3         = Color3.new(1, 1, 1)
			end)
		end
	end
end

	return true
end
