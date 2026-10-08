-- Vista Ancla integrada en la GUI principal.
return function(context)
	setfenv(1,context)
	anchorPanel=Instance.new("ScrollingFrame");anchorPanel.BorderSizePixel=0;anchorPanel.ScrollBarThickness=3;anchorPanel.ScrollingDirection=Enum.ScrollingDirection.Y;anchorPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;anchorPanel.CanvasSize=UDim2.new();anchorPanel.Active=true
	anchorPanel.Name="AnchorPanel"
	anchorPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
	anchorPanel.Position=UDim2.new(0,8,0,titleH+8)
	anchorPanel.BackgroundTransparency=1
	anchorPanel.Visible=false
	anchorPanel.ZIndex=6
	anchorPanel.Parent=content

	local experimentalOwners={[11739864999]="psychoo778",[11743514302]="ksablanca0",[11747901934]="psycho777oo"}
	local expectedOwnerName=experimentalOwners[player.UserId]
	local canUseExperimentalAnchor=expectedOwnerName~=nil and string.lower(player.Name)==expectedOwnerName

	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,0,0,canUseExperimentalAnchor and (isMobile and 522 or 538) or (isMobile and 266 or 282))
	card.BackgroundColor3=currentTheme.secondary
	card.ZIndex=7
	card.Parent=anchorPanel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
	RegisterTheme(card,"BackgroundColor3","secondary")
	local padding=Instance.new("UIPadding")
	padding.PaddingLeft,padding.PaddingRight=UDim.new(0,14),UDim.new(0,14)
	padding.PaddingTop,padding.PaddingBottom=UDim.new(0,14),UDim.new(0,14)
	padding.Parent=card

	local description=Instance.new("TextLabel")
	description.Size=UDim2.new(1,-132,0,30)
	description.BackgroundTransparency=1
	description.Text=isES and "Controles de estabilidad del personaje" or "Character stability controls"
	description.TextColor3=currentTheme.textDim
	description.Font=Enum.Font.GothamMedium
	description.TextSize=isMobile and 11 or 13
	description.TextXAlignment=Enum.TextXAlignment.Left
	description.ZIndex=8
	description.Parent=card
	RegisterTheme(description,"TextColor3","textDim")
	local forceReturnButton=Instance.new("TextButton")
	forceReturnButton.Size=UDim2.new(0,124,0,30)
	forceReturnButton.Position=UDim2.new(1,-124,0,0)
	forceReturnButton.BackgroundColor3=currentTheme.tertiary
	forceReturnButton.TextColor3=currentTheme.text
	forceReturnButton.Text=isES and "Forzar regreso" or "Force return"
	forceReturnButton.Font=Enum.Font.GothamBold
	forceReturnButton.TextSize=isMobile and 10 or 12
	forceReturnButton.AutoButtonColor=false
	forceReturnButton.ZIndex=8
	forceReturnButton.Parent=card
	Instance.new("UICorner",forceReturnButton).CornerRadius=UDim.new(0,9)
	RegisterTheme(forceReturnButton,"BackgroundColor3","tertiary")
	RegisterTheme(forceReturnButton,"TextColor3","text")

	local function makeButton(y)
		local button=Instance.new("TextButton")
		button.Size=UDim2.new(1,0,0,44)
		button.Position=UDim2.new(0,0,0,y)
		button.BackgroundColor3=currentTheme.tertiary
		button.TextColor3=currentTheme.text
		button.Font=Enum.Font.GothamBold
		button.TextSize=isMobile and 12 or 14
		button.AutoButtonColor=false
		button.ZIndex=8
		button.Parent=card
		Instance.new("UICorner",button).CornerRadius=UDim.new(0,10)
		RegisterTheme(button,"BackgroundColor3","tertiary")
		RegisterTheme(button,"TextColor3","text")
		return button
	end
	local anchorButton=makeButton(38)
	local antiSeatButton=makeButton(90)
	local heartbeatButton=makeButton(142)
	local testButton=makeButton(194)
	local combinedButton=makeButton(246)

	combinedButton.Visible=canUseExperimentalAnchor
	combinedButton.Size=UDim2.new(0.5,-4,0,44)
	local phaseButton=makeButton(246)
	phaseButton.Size=UDim2.new(0.5,-4,0,44)
	phaseButton.Position=UDim2.new(0.5,4,0,246)
	phaseButton.Visible=canUseExperimentalAnchor
	phaseButton.Activated:Connect(function()
		if canUseExperimentalAnchor and StaticPassThroughAnchorCore then
			StaticPassThroughAnchorCore:SetPhase(not StaticPassThroughAnchorCore.PhaseEnabled)
		end
	end)
	for index,entry in ipairs({{"Left",isES and "Izquierda" or "Left"},{"Right",isES and "Derecha" or "Right"},{"Up",isES and "Arriba" or "Up"},{"Interval",isES and "Intervalo (menos = rapido)" or "Interval (less = faster)"}}) do
		local y=298+(index-1)*48
		local label=Instance.new("TextLabel")
		label.Size=UDim2.new(0.4,0,0,40);label.Position=UDim2.new(0,0,0,y)
		label.BackgroundTransparency=1;label.Text=entry[2];label.TextColor3=currentTheme.text
		label.Font=Enum.Font.GothamMedium;label.TextSize=13;label.ZIndex=8;label.Parent=card
		label.Visible=canUseExperimentalAnchor
		RegisterTheme(label,"TextColor3","text")
		local minus=makeButton(y);minus.Size=UDim2.new(0.15,-4,0,40);minus.Position=UDim2.new(0.4,0,0,y);minus.Text="-"
		local value=makeButton(y);value.Size=UDim2.new(0.3,-4,0,40);value.Position=UDim2.new(0.55,0,0,y);value.Text="4 studs"
		local plus=makeButton(y);plus.Size=UDim2.new(0.15,0,0,40);plus.Position=UDim2.new(0.85,0,0,y);plus.Text="+"
		minus.Visible=canUseExperimentalAnchor;value.Visible=canUseExperimentalAnchor;plus.Visible=canUseExperimentalAnchor
		if entry[1]=="Interval" then value.Text="0.25 s";label.TextSize=11;label.TextWrapped=true end
		local function change(delta)
			if not canUseExperimentalAnchor or not StaticPassThroughAnchorCore then return end
			local core=StaticPassThroughAnchorCore
			if entry[1]=="Interval" then
				core:SetInterval(core.ShiftInterval+delta*0.05)
				value.Text=string.format("%.2f s",core.ShiftInterval)
			else
				core:SetDistance(entry[1],core.Distances[entry[1]]+delta)
				value.Text=tostring(core.Distances[entry[1]]).." studs"
			end
		end
		minus.Activated:Connect(function() change(-1) end)
		plus.Activated:Connect(function() change(1) end)
	end

	UpdateAnchorPanel=function(message)
		phaseButton.Text=StaticPassThroughAnchorCore.PhaseEnabled and (isES and "Desactivar Desfase" or "Disable Shift") or (isES and "Desfase" or "Shift")
		phaseButton.Active=canUseExperimentalAnchor and StaticPassThroughAnchorCore:IsRunning()
		phaseButton.BackgroundColor3=StaticPassThroughAnchorCore.PhaseEnabled and currentTheme.accent or currentTheme.tertiary
		anchorButton.Text=AnchorCore.AnclaEnabled and (isES and "Desactivar Ancla" or "Disable Anchor") or (isES and "Activar Ancla" or "Enable Anchor")
		antiSeatButton.Text=AnchorCore.AntiSeatEnabled and (isES and "Desactivar AntiSeat" or "Disable AntiSeat") or (isES and "Activar AntiSeat" or "Enable AntiSeat")
		heartbeatButton.Text=AnchorCore.HeartbeatEnabled and (isES and "Desactivar Heartbeat" or "Disable Heartbeat") or (isES and "Activar Heartbeat" or "Enable Heartbeat")
		testButton.Text=AnchorCore.TestEnabled and (isES and "Desactivar Ancla test" or "Disable Test Anchor") or (isES and "Activar Ancla test" or "Enable Test Anchor")
		combinedButton.Text=StaticPassThroughAnchorCore and StaticPassThroughAnchorCore:IsRunning()
			and (isES and "Desactivar Ancla" or "Disable Anchor")
			or (isES and "Activar Ancla" or "Enable Anchor")
		anchorButton.BackgroundColor3=AnchorCore.AnclaEnabled and currentTheme.accent or currentTheme.tertiary
		antiSeatButton.BackgroundColor3=AnchorCore.AntiSeatEnabled and currentTheme.accent or currentTheme.tertiary
		heartbeatButton.BackgroundColor3=AnchorCore.HeartbeatEnabled and currentTheme.accent or currentTheme.tertiary
		testButton.BackgroundColor3=AnchorCore.TestEnabled and currentTheme.accent or currentTheme.tertiary
		combinedButton.BackgroundColor3=StaticPassThroughAnchorCore and StaticPassThroughAnchorCore:IsRunning() and currentTheme.accent or currentTheme.tertiary
		local automaticBusy=AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)
		local mobileBusy=(MobileAnchorCore and MobileAnchorCore:IsRunning()) or (MobileAnchorV11Core and MobileAnchorV11Core:IsRunning())
		local combinedBusy=StaticPassThroughAnchorCore and StaticPassThroughAnchorCore:IsRunning()
		local manualEnabled=not automaticBusy and not AnchorCore.TestEnabled and not mobileBusy and not combinedBusy
		anchorButton.Active=manualEnabled
		antiSeatButton.Active=manualEnabled
		heartbeatButton.Active=manualEnabled
		testButton.Active=not automaticBusy and not mobileBusy and not combinedBusy
		combinedButton.Active=canUseExperimentalAnchor and not automaticBusy and not mobileBusy
		description.Text=message or (combinedBusy and StaticPassThroughAnchorCore.PhaseStatus) or (AnchorCore.TestEnabled
			and (isES and "Ancla activa" or "Anchor active")
			or (AnchorCore.HeartbeatEnabled and not AnchorCore.AnclaEnabled
			and (isES and "Heartbeat está preparado; se aplicará al activar Ancla." or "Heartbeat is ready; it applies when Anchor is enabled.")
			or (isES and "Controles de estabilidad del personaje" or "Character stability controls")))
	end
	anchorButton.MouseButton1Click:Connect(function()
		if AnchorCore.TestEnabled then return end
		local ok,err=AnchorCore:ToggleAncla()
		UpdateAnchorPanel(ok and nil or err)
	end)
	antiSeatButton.MouseButton1Click:Connect(function()
		if AnchorCore.TestEnabled then return end
		AnchorCore:ToggleAntiSeat()
		UpdateAnchorPanel()
	end)
	heartbeatButton.MouseButton1Click:Connect(function()
		if AnchorCore.TestEnabled then return end
		AnchorCore:ToggleHeartbeat()
		UpdateAnchorPanel()
	end)
	testButton.MouseButton1Click:Connect(function()
		local ok,err=AnchorCore:ToggleTest()
		UpdateAnchorPanel(ok and nil or err)
	end)
	combinedButton.MouseButton1Click:Connect(function()
		if not canUseExperimentalAnchor or not StaticPassThroughAnchorCore then return end
		local _,message=StaticPassThroughAnchorCore:Toggle()
		UpdateAnchorPanel(message)
	end)
	forceReturnButton.MouseButton1Click:Connect(function()
		if not AnchorForceReturn or AnchorForceReturn.Busy then return end
		local ok,message=AnchorForceReturn:Force(2)
		UpdateAnchorPanel(message)
		forceReturnButton.BackgroundColor3=ok and currentTheme.accent or currentTheme.tertiary
		task.delay(0.4,function()
			if forceReturnButton.Parent then forceReturnButton.BackgroundColor3=currentTheme.tertiary end
		end)
	end)
	UpdateAnchorPanel()
	return true
end
