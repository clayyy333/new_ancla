-- Vista de Ancla automatica integrada.
return function(context)
	setfenv(1,context)
	autoAnchorPanel=Instance.new("ScrollingFrame");autoAnchorPanel.BorderSizePixel=0;autoAnchorPanel.ScrollBarThickness=3;autoAnchorPanel.ScrollingDirection=Enum.ScrollingDirection.Y;autoAnchorPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;autoAnchorPanel.CanvasSize=UDim2.new();autoAnchorPanel.Active=true
	autoAnchorPanel.Name="AutoAnchorPanel"
	autoAnchorPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
	autoAnchorPanel.Position=UDim2.new(0,8,0,titleH+8)
	autoAnchorPanel.BackgroundTransparency=1
	autoAnchorPanel.Visible=false
	autoAnchorPanel.ZIndex=6
	autoAnchorPanel.Parent=content
	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,0,0,isMobile and 220 or 238)
	card.BackgroundColor3=currentTheme.secondary
	card.ZIndex=7
	card.Parent=autoAnchorPanel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
	RegisterTheme(card,"BackgroundColor3","secondary")
	local padding=Instance.new("UIPadding")
	padding.PaddingLeft,padding.PaddingRight=UDim.new(0,14),UDim.new(0,14)
	padding.PaddingTop,padding.PaddingBottom=UDim.new(0,14),UDim.new(0,14)
	padding.Parent=card
	local description=Instance.new("TextLabel")
	description.Size=UDim2.new(1,0,0,38)
	description.BackgroundTransparency=1
	description.Text=isES and "Activa las tres protecciones y mantiene automáticamente tu patín." or "Enables all three protections and automatically maintains your skateboard."
	description.TextColor3=currentTheme.textDim
	description.Font=Enum.Font.GothamMedium
	description.TextSize=isMobile and 10 or 12
	description.TextWrapped=true
	description.TextXAlignment=Enum.TextXAlignment.Left
	description.ZIndex=8
	description.Parent=card
	RegisterTheme(description,"TextColor3","textDim")
	local function makeButton(y)
		local button=Instance.new("TextButton")
		button.Size=UDim2.new(1,0,0,46)
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
	local deltaButton=makeButton(48)
	local xenoButton=makeButton(102)
	local status=Instance.new("TextLabel")
	status.Size=UDim2.new(1,0,0,44)
	status.Position=UDim2.new(0,0,0,158)
	status.BackgroundTransparency=1
	status.TextColor3=currentTheme.textDim
	status.Font=Enum.Font.GothamMedium
	status.TextSize=isMobile and 10 or 12
	status.TextWrapped=true
	status.TextXAlignment=Enum.TextXAlignment.Left
	status.ZIndex=8
	status.Parent=card
	RegisterTheme(status,"TextColor3","textDim")
	UpdateAutoAnchorPanel=function(message)
		local mode=AutoAnchorCore.Mode
		deltaButton.Text=mode=="delta" and (isES and "Desactivar Ancla con asiento Delta" or "Disable Delta Seat Anchor") or (isES and "Activar Ancla con asiento Delta" or "Enable Delta Seat Anchor")
		xenoButton.Text=mode=="xeno" and (isES and "Desactivar Ancla con asiento Xeno" or "Disable Xeno Seat Anchor") or (isES and "Activar Ancla con asiento Xeno" or "Enable Xeno Seat Anchor")
		deltaButton.BackgroundColor3=mode=="delta" and currentTheme.critical or currentTheme.tertiary
		xenoButton.BackgroundColor3=mode=="xeno" and currentTheme.critical or currentTheme.tertiary
		local mobileBusy=(MobileAnchorCore and MobileAnchorCore:IsRunning()) or (MobileAnchorV11Core and MobileAnchorV11Core:IsRunning())
		deltaButton.Active=not AutoAnchorCore.Busy and not mobileBusy
		xenoButton.Active=not AutoAnchorCore.Busy and not mobileBusy
		local engineStatus=mode=="delta" and AutoSkateDelta.Status or mode=="xeno" and AutoSkateXeno.Status or nil
		status.Text=message or engineStatus or AutoAnchorCore.Status
	end
	local function toggle(mode)
		if SeatAnchorLabCore and SeatAnchorLabCore.Running then
			UpdateAutoAnchorPanel(isES and "Deten primero la prueba de asiento."or "Stop the seat experiment first.")
			return
		end
		if AutoAnchorCore.Busy then return end
		task.spawn(function()
			local ok,err=AutoAnchorCore:Toggle(mode)
			UpdateAutoAnchorPanel(ok and nil or err)
			if UpdateAnchorPanel then UpdateAnchorPanel() end
		end)
	end
	deltaButton.MouseButton1Click:Connect(function() toggle("delta") end)
	xenoButton.MouseButton1Click:Connect(function() toggle("xeno") end)
	if FoldingCleanupCore:IsAvailable() then description.Size=UDim2.new(0.75,-8,0,38) end
	FoldingCleanupControls:Create(card,UDim2.new(0.75,4,0,0),UDim2.new(0.25,-4,0,30))
	if SeatAnchorLabCore and SeatAnchorLabCore:IsAuthorized()then
		card.Size=UDim2.new(1,0,0,510)
		local trip=makeButton(214)
		trip.Name="SeatLabRoundTrip"
		local anchored=makeButton(334)
		anchored.Name="SeatLabAnchorSit"
		local refreshSeat=makeButton(388)
		refreshSeat.Name="SeatLabRefreshSeat"
		refreshSeat.Position=UDim2.new(.18,4,0,388)
		refreshSeat.Size=UDim2.new(.64,-8,0,30)
		refreshSeat.Text=isES and "Actualizar asientos"or "Refresh seats"
		local previousSeat=makeButton(388)
		previousSeat.Name="SeatLabPreviousSeat";previousSeat.Size=UDim2.new(.18,0,0,30);previousSeat.Text="<"
		local nextSeat=makeButton(388)
		nextSeat.Name="SeatLabNextSeat";nextSeat.Position=UDim2.new(.82,4,0,388);nextSeat.Size=UDim2.new(.18,-4,0,30);nextSeat.Text=">"
		local selection=Instance.new("TextLabel")
		selection.Position=UDim2.fromOffset(0,426);selection.Size=UDim2.new(1,0,0,42)
		selection.BackgroundTransparency=1;selection.TextColor3=currentTheme.text
		selection.Font=Enum.Font.GothamMedium;selection.TextSize=isMobile and 10 or 12
		selection.TextWrapped=true;selection.TextXAlignment=Enum.TextXAlignment.Left
		selection.ZIndex=8;selection.Parent=card
		RegisterTheme(selection,"TextColor3","text")
		local labStatus=Instance.new("TextLabel")
		labStatus.Position=UDim2.fromOffset(0,266);labStatus.Size=UDim2.new(1,0,0,60)
		labStatus.BackgroundTransparency=1;labStatus.TextColor3=currentTheme.textDim
		labStatus.Font=Enum.Font.GothamMedium;labStatus.TextSize=isMobile and 10 or 12
		labStatus.TextWrapped=true;labStatus.TextXAlignment=Enum.TextXAlignment.Left
		labStatus.ZIndex=8;labStatus.Parent=card
		RegisterTheme(labStatus,"TextColor3","textDim")
		UpdateSeatAnchorLabPanel=function(message)
			if not card.Parent then return end
			local core=SeatAnchorLabCore
			trip.Text=core.Mode=="trip"and (isES and "Cancelar ida y regreso"or "Cancel round trip")or (isES and "Prueba de asiento: ida y regreso"or "Seat test: round trip")
			anchored.Text=core.Mode=="anchor"and (isES and "Desactivar ancla con asiento (prueba)"or "Disable seat anchor (test)")or (isES and "Anclar en punto de prueba y sentarse"or "Anchor at test checkpoint and attempt sitting")
			trip.BackgroundColor3=core.Mode=="trip"and currentTheme.critical or currentTheme.tertiary
			anchored.BackgroundColor3=core.Mode=="anchor"and currentTheme.critical or currentTheme.tertiary
			selection.Text=core.Seat and ((isES and "Asiento "or "Seat ")..core.SelectedIndex.."/"..#core.Seats.."\n"..core.Seat:GetFullName())or (isES and "Pulsa Actualizar asientos y elige con < >."or "Refresh seats and select with < >.")
			labStatus.Text=message or (core.Status~=""and core.Status)or (isES and "Pruebas owners: elige el mismo asiento que en AUTO SIT LAB. Una sola ida y regreso. Evidencia solo local."or "Owner tests: select the same seat as AUTO SIT LAB. Single round trip. Local evidence only.")
		end
		local function run(mode)
			if SeatAnchorLabCore.Running then SeatAnchorLabCore:Stop();return end
			local called,ok,err=xpcall(function()return SeatAnchorLabCore:Start(mode)end,debug.traceback)
			if not called then
				err=tostring(ok);ok=false
				SeatAnchorLabCore:Stop(err)
			end
			if not ok then
				err=err or (isES and "No se pudo iniciar la prueba."or "Could not start the test.")
				SeatAnchorLabCore.Status=err
				UpdateSeatAnchorLabPanel(err)
				-- Reveal the actual start rejection even when the panel is scrolled.
				autoAnchorPanel.CanvasPosition=Vector2.new(0,math.max(0,labStatus.AbsolutePosition.Y-autoAnchorPanel.AbsolutePosition.Y+autoAnchorPanel.CanvasPosition.Y-12))
			end
		end
		trip.Activated:Connect(function()run("trip")end)
		anchored.Activated:Connect(function()run("anchor")end)
		refreshSeat.Activated:Connect(function()
			local ok,err=SeatAnchorLabCore:RefreshSeat()
			if not ok then UpdateSeatAnchorLabPanel(err)end
		end)
		previousSeat.Activated:Connect(function()
			local ok,err=SeatAnchorLabCore:SelectSeat(-1)
			if not ok then UpdateSeatAnchorLabPanel(err)end
		end)
		nextSeat.Activated:Connect(function()
			local ok,err=SeatAnchorLabCore:SelectSeat(1)
			if not ok then UpdateSeatAnchorLabPanel(err)end
		end)
		gui.Destroying:Connect(function()SeatAnchorLabCore:Destroy()end)
		UpdateSeatAnchorLabPanel()
	end
	UpdateAutoAnchorPanel()
	return true
end
