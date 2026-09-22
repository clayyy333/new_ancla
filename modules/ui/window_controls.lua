-- Estado compartido mediante el contexto privado de la aplicacion.
return function(context)
	setfenv(1, context)

-- MINI ICON
-- ===============================================================

do
local iconS = isMobile and 50 or 60
local miniIcon = Instance.new("TextButton")
miniIcon.Size = UDim2.new(0, iconS, 0, iconS)
miniIcon.Position = UDim2.new(0, 20, 0.5, -iconS/2)
miniIcon.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
miniIcon.Text = "nav"
miniIcon.TextColor3 = Color3.fromRGB(238, 238, 242)
miniIcon.TextSize = isMobile and 15 or 17
miniIcon.Font = Enum.Font.GothamBold
miniIcon.AutoButtonColor = false
miniIcon.Visible = false
miniIcon.ZIndex = 1000
miniIcon.Parent = gui
Instance.new("UICorner", miniIcon).CornerRadius = UDim.new(0, isMobile and 11 or 14)

local miniIconStroke = Instance.new("UIStroke")
miniIconStroke.Color = Color3.new(1, 1, 1)
miniIconStroke.Thickness = 3
miniIconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
miniIconStroke.Parent = miniIcon

miniIconGrad = Instance.new("UIGradient")
miniIconGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, currentTheme.stroke),
	ColorSequenceKeypoint.new(0.33, currentTheme.accent),
	ColorSequenceKeypoint.new(0.66, currentTheme.stroke),
	ColorSequenceKeypoint.new(1, currentTheme.accent)
}
miniIconGrad.Parent = miniIconStroke

task.spawn(function()
	local rot = 0
	while miniIcon.Parent do
		rot = rot + 360
		TweenService:Create(miniIconGrad, TweenInfo.new(8, Enum.EasingStyle.Linear), {Rotation = rot}):Play()
		task.wait(8)
	end
end)


do
local savedPos, savedSize = nil, nil
local iconDragging, iconDragStart, iconStartPos = false, nil, nil

miniIcon.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		iconDragging = true
		iconDragStart = input.Position
		iconStartPos = miniIcon.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if iconDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - iconDragStart
		miniIcon.Position = UDim2.new(iconStartPos.X.Scale, iconStartPos.X.Offset + delta.X, iconStartPos.Y.Scale, iconStartPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if iconDragging then
			local delta = input.Position - iconDragStart
			if math.abs(delta.X) < 5 and math.abs(delta.Y) < 5 then
				miniIcon.Visible = false
				main.Visible = true
				main.ClipsDescendants = true
				main.Size = UDim2.new(0, 0, 0, 0)
				main.BackgroundTransparency = 1
				main.Rotation = 0
				
				local targetSize = savedSize or GetDefaultSize()
				local targetPos = savedPos or UDim2.fromScale(0.5, 0.5)
				main.Position = targetPos
				
				TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = targetSize, BackgroundTransparency = 0}):Play()
				TweenService:Create(mainStroke, TweenInfo.new(0.35), {Transparency = 0}):Play()
				task.delay(0.36, function() if ApplyGUITransparency then ApplyGUITransparency() end end)
				
				task.delay(0.4, function()
					main.ClipsDescendants = true
					if currentTab ~= "settings" then Refresh(true) end
				end)
			end
		end
		iconDragging = false
	end
end)

minBtn.MouseButton1Click:Connect(function()
	main.ClipsDescendants = true
	savedPos = main.Position
	savedSize = main.Size
	
	TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1}):Play()
	TweenService:Create(mainStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
	
	task.delay(0.3, function()
		main.Visible = false
		miniIcon.Visible = true
	end)
end)

local function _CleanupScript()
	pcall(function() if FlightController then FlightController:Destroy() end end)
	pcall(function() if CarControlController then CarControlController:Destroy() end end)
	pcall(function() if FreeCarController then FreeCarController:Destroy() end end)
	pcall(function() if CouplesPositionController then CouplesPositionController:Destroy() end end)
	pcall(function() if CoupleMovementController then CoupleMovementController:Destroy() end end)
	pcall(function() if PresetPoseController then PresetPoseController:Destroy() end end)
	pcall(function() if SpectatorController then SpectatorController:Destroy() end end)
	pcall(function() if AmbientSoundController then AmbientSoundController:Destroy() end end)
	pcall(function() if AntiAFKController then AntiAFKController:Destroy() end end)
	pcall(function() if RemoveAnimationPacks then RemoveAnimationPacks(true) end end)
	pcall(function() if EmergencyAnchorController then EmergencyAnchorController:Destroy() end end)
	pcall(function() if AutoAnchorCore then AutoAnchorCore:Destroy() end end)
	pcall(function() if AnchorCore then AnchorCore:Destroy() end end)
	pcall(function() if Fling2Core then Fling2Core:Stop() end end)
	pcall(function() if MotoFlingCore then MotoFlingCore:Destroy() end end)
	pcall(function() if MotoFlingXenoCore then MotoFlingXenoCore:Destroy() end end)
	pcall(function() if Fling2EfficientCore then Fling2EfficientCore:Stop() end end)
	pcall(function() if _motoFlingPlayerRemovingConn then _motoFlingPlayerRemovingConn:Disconnect() end end)
	pcall(function() if _motoFlingMonitorConn then _motoFlingMonitorConn:Disconnect() end end)
	pcall(function() if _motoFlingXenoPlayerRemovingConn then _motoFlingXenoPlayerRemovingConn:Disconnect() end end)
	pcall(function() if _motoFlingXenoMonitorConn then _motoFlingXenoMonitorConn:Disconnect() end end)
	pcall(function() if CarFling then CarFling:Stop() end end)
	pcall(function() if CarFlingXeno then CarFlingXeno:Stop() end end)
	pcall(function() if CarFling2Delta then CarFling2Delta:Stop() end end)
	pcall(function() if CarFling2Xeno then CarFling2Xeno:Stop() end end)
	pcall(function() if ObjectFling2Delta then ObjectFling2Delta:Stop() end end)
	pcall(function() if ObjectFling2Xeno then ObjectFling2Xeno:Stop() end end)
	pcall(function() if ToolTracker then ToolTracker:Stop() end end)
	pcall(function() if _carFling2DeltaPlayerRemovingConn then _carFling2DeltaPlayerRemovingConn:Disconnect() end end)
	pcall(function() if _carFling2DeltaMonitorConn then _carFling2DeltaMonitorConn:Disconnect() end end)
	pcall(function() if _carFling2XenoPlayerRemovingConn then _carFling2XenoPlayerRemovingConn:Disconnect() end end)
	pcall(function() if _carFling2XenoMonitorConn then _carFling2XenoMonitorConn:Disconnect() end end)
	pcall(function() if _objectFling2DeltaPlayerRemovingConn then _objectFling2DeltaPlayerRemovingConn:Disconnect() end end)
	pcall(function() if _objectFling2DeltaMonitorConn then _objectFling2DeltaMonitorConn:Disconnect() end end)
	pcall(function() if _objectFling2XenoPlayerRemovingConn then _objectFling2XenoPlayerRemovingConn:Disconnect() end end)
	pcall(function() if _objectFling2XenoMonitorConn then _objectFling2XenoMonitorConn:Disconnect() end end)
	pcall(function() if _objectFlingUiConn then _objectFlingUiConn:Disconnect() end end)
	pcall(function() if _carFling2UiConn then _carFling2UiConn:Disconnect() end end)
	pcall(function() if _carFlingXenoPlayerRemovingConn then _carFlingXenoPlayerRemovingConn:Disconnect() end end)
	pcall(function() if _carFlingXenoMonitorConn then _carFlingXenoMonitorConn:Disconnect() end end)
	pcall(function() if _carFlingPlayerRemovingConn then _carFlingPlayerRemovingConn:Disconnect() end end)
	pcall(function() if _carFlingMonitorConn then _carFlingMonitorConn:Disconnect() end end)
	pcall(function() if _carFlingUiConn then _carFlingUiConn:Disconnect() end end)
	pcall(function() if _fling2EfficientPlayerRemovingConn then _fling2EfficientPlayerRemovingConn:Disconnect() end end)
	pcall(function() if _fling2EfficientCharacterAddedConn then _fling2EfficientCharacterAddedConn:Disconnect() end end)
	pcall(function() if _fling2PlayerRemovingConn then _fling2PlayerRemovingConn:Disconnect() end end)
	pcall(function() if _fling2CharacterAddedConn then _fling2CharacterAddedConn:Disconnect() end end)
	pcall(function() _heartbeatConn:Disconnect() end)
	pcall(function() _charAddedConn:Disconnect() end)
	pcall(function() if _keybindInputConn then _keybindInputConn:Disconnect() end end)
	pcall(function() StopHUDTracking() end)
	pcall(function() VexroAcrylic.Stop() end)
	-- Oynanan emote'u durdur
	pcall(function() StopEmote(false) end)
	-- Sunucuya disconnect bildir
	pcall(function()
		SaveData()
	end)
	_genv().VexroEmotesCleanup = nil
	_genv().lastVexroEmote = nil
	_genv().autoReloadEnabled_Vexro = nil
	pcall(function() gui:Destroy() end)
end

_genv().VexroEmotesCleanup = _CleanupScript

local _closing = false
local function _ReleaseAnchorBeforeClose()
	if AutoAnchorCore then
		local deadline = os.clock() + 7
		while AutoAnchorCore.Busy and os.clock() < deadline do task.wait() end
		pcall(function() AutoAnchorCore:Stop() end)
	end
	-- Garantia final para Ancla manual y cualquier operacion automatica interrumpida.
	if AnchorCore then
		pcall(function() AnchorCore:SetHeartbeat(false) end)
		pcall(function() AnchorCore:SetAntiSeat(false) end)
		pcall(function() AnchorCore:SetAncla(false) end)
	end
end

closeBtn.MouseButton1Click:Connect(function()
	if _closing then return end
	_closing = true
	closeBtn.Active = false
	task.spawn(function()
		_ReleaseAnchorBeforeClose()
		gui.Enabled = false
		main.ClipsDescendants = true
		TweenService:Create(main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1
		}):Play()
		task.wait(0.22)
		_CleanupScript()
	end)
end)
end
end

-- ===============================================================

	return true
end
