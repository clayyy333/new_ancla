return function(context)
	setfenv(1,context)
	local function tr(es,en)return isES and es or en end
	experimentalFlingPanel=Instance.new("ScrollingFrame")
	local panel=experimentalFlingPanel
	panel.Size=UDim2.new(1,-16,1,-(titleH+20));panel.Position=UDim2.new(0,8,0,titleH+8)
	panel.BackgroundTransparency=1;panel.BorderSizePixel=0;panel.ScrollBarThickness=3;panel.CanvasSize=UDim2.new();panel.AutomaticCanvasSize=Enum.AutomaticSize.Y;panel.Visible=false;panel.ZIndex=6;panel.Parent=content
	if not ExperimentalFlingCore:IsAuthorized() then return true end
	local layout=Instance.new("UIListLayout",panel);layout.Padding=UDim.new(0,8)
	layout.SortOrder=Enum.SortOrder.LayoutOrder
	local function button(label)
		local b=Instance.new("TextButton");b.Size=UDim2.new(1,-4,0,42);b.Text=label;b.Font=Enum.Font.GothamBold;b.TextSize=isMobile and 11 or 13
		b.BackgroundColor3=currentTheme.tertiary;b.TextColor3=currentTheme.text;b.BorderSizePixel=0;b.ZIndex=8;b.Parent=panel
		Instance.new("UICorner",b).CornerRadius=UDim.new(0,10);RegisterTheme(b,"BackgroundColor3","tertiary");RegisterTheme(b,"TextColor3","text");return b
	end
	local selectTarget=button(tr("Seleccionar jugador","Select player"))
	selectTarget.LayoutOrder=1
	local choices=Instance.new("ScrollingFrame");choices.Size=UDim2.new(1,-4,0,150);choices.BackgroundTransparency=1;choices.BorderSizePixel=0;choices.ScrollBarThickness=3;choices.CanvasSize=UDim2.new();choices.AutomaticCanvasSize=Enum.AutomaticSize.Y;choices.Visible=false;choices.ZIndex=7;choices.Parent=panel
	Instance.new("UIListLayout",choices).Padding=UDim.new(0,4)
	choices.LayoutOrder=2
	local toggle=button(tr("Activar Fling experimental corto","Enable experimental short Fling"))
	toggle.LayoutOrder=3
	local microToggle=button(tr("Activar contacto sutil 0.5 studs","Enable subtle contact 0.5 studs"))
	microToggle.LayoutOrder=4
	local back=button(tr("Forzar regreso","Force return"))
	back.LayoutOrder=5
	local copyDiagnostic=button(tr("Copiar diagnóstico","Copy diagnostic"))
	copyDiagnostic.LayoutOrder=7
	local report=Instance.new("TextBox")
	report.Size=UDim2.new(1,-12,0,180);report.LayoutOrder=8;report.MultiLine=true;report.ClearTextOnFocus=false
	report.TextEditable=false;report.TextWrapped=false;report.TextSize=11;report.Font=Enum.Font.Code
	report.TextXAlignment=Enum.TextXAlignment.Left;report.TextYAlignment=Enum.TextYAlignment.Top
	report.BackgroundColor3=currentTheme.tertiary;report.TextColor3=currentTheme.text;report.ZIndex=8;report.Visible=false;report.Parent=panel
	RegisterTheme(report,"BackgroundColor3","tertiary");RegisterTheme(report,"TextColor3","text")
	copyDiagnostic.Activated:Connect(function()
		local text=ExperimentalFlingCore:GetDiagnosticReport()
		local copy=setclipboard or toclipboard
		local ok=type(copy)=="function" and pcall(copy,text)
		report.Text=text;report.Visible=not ok
		if not ok then report:CaptureFocus();report.SelectionStart=1;report.CursorPosition=#text+1 end
		UpdateExperimentalFlingPanel(ok and tr("Diagnóstico copiado.","Diagnostic copied.") or tr("Selecciona y copia el reporte de abajo.","Select and copy the report below."))
	end)
	local status=Instance.new("TextLabel");status.Size=UDim2.new(1,-12,0,68);status.TextWrapped=true;status.BackgroundTransparency=1;status.Font=Enum.Font.Gotham;status.TextSize=12;status.TextColor3=currentTheme.textDim;status.ZIndex=8;status.Parent=panel;RegisterTheme(status,"TextColor3","textDim")
	UpdateExperimentalFlingPanel=function(message)
		local c=ExperimentalFlingCore
		toggle.Text=c.Stopping and tr("Estabilizando…","Stabilizing…") or (c.Running and not c.MicroMovementEnabled and tr("Desactivar Fling experimental corto","Disable experimental short Fling") or tr("Activar Fling experimental corto","Enable experimental short Fling"))
		toggle.BackgroundColor3=c.Running and not c.MicroMovementEnabled and currentTheme.critical or currentTheme.tertiary
		microToggle.Text=c.Stopping and tr("Estabilizando…","Stabilizing…") or (c.Running and c.MicroMovementEnabled and tr("Desactivar contacto sutil 0.5 studs","Disable subtle contact 0.5 studs") or tr("Activar contacto sutil 0.5 studs","Enable subtle contact 0.5 studs"))
		microToggle.BackgroundColor3=c.Running and c.MicroMovementEnabled and currentTheme.critical or currentTheme.tertiary
		status.Text=message or tr("Copia del eficiente: contacto hasta confirmar a dayzero777 en tu moto, alejamiento y regreso. Prueba exclusiva para owners.","Efficient copy: contact until dayzero777 is confirmed in your bike, far travel and return. Owner-only test.")
		if not message and c.PassengerMonitoring then
			local labels={WAIT_VEHICLE=tr("Esperando tu moto; no se eligen vehículos ambiguos.","Waiting for your bike; ambiguous vehicles are not selected."),WAIT_SEAT=tr("Moto identificada; esperando asiento.","Bike identified; waiting for seat."),WAIT_PASSENGER=tr("Esperando a dayzero777 en el copiloto.","Waiting for dayzero777 in passenger seat."),OCCUPIED=tr("dayzero777 detectado; esperando SeatWeld.","dayzero777 detected; waiting for SeatWeld."),CONFIRMED=tr("dayzero777: ocupación y conexión al HRP confirmadas localmente.","dayzero777: occupancy and HRP connection confirmed locally."),OTHER_PASSENGER=tr("Otro ocupante; no es la cuenta de prueba.","Other occupant; not the test account.")}
			status.Text=labels[c.PassengerState] or "…"
		end
		if not message and c.Running and c.MicroMovementEnabled then status.Text=tr("Contacto: arriba, abajo, delante y detrás a 0.5 studs. Sin alejamiento; no requiere moto. Velocidades extremas: estabilidad no garantizada.","Contact: up, down, front and back at 0.5 studs. No far travel; no bike required. Extreme velocities: stability not guaranteed.") end
	end
	status.LayoutOrder=6
	selectTarget.Activated:Connect(function()
		if ExperimentalFlingCore.Running or ExperimentalFlingCore.Stopping then return end
		choices.Visible=not choices.Visible
		for _,b in ipairs(choices:GetChildren())do if b:IsA("GuiButton") then b:Destroy() end end
		local players=Players:GetPlayers();table.sort(players,function(a,b)return a.Name:lower()<b.Name:lower()end)
		for _,p in ipairs(players)do if p~=player then
			local b=button(p.DisplayName.." (@"..p.Name..")");b.Parent=choices;b.Size=UDim2.new(1,-4,0,36)
			b.Activated:Connect(function()if ExperimentalFlingCore:SetTarget(p) then selectTarget.Text=p.DisplayName;choices.Visible=false end end)
		end end
	end)
	toggle.Activated:Connect(function()
		choices.Visible=false
		local c=ExperimentalFlingCore
		if c.Stopping then return end
		if c.Running then c:Stop()
		else c.MicroMovementEnabled=false;local ok,err=c:Start();UpdateExperimentalFlingPanel(ok and nil or err) end
	end)
	microToggle.Activated:Connect(function()
		choices.Visible=false
		local c=ExperimentalFlingCore
		if c.Stopping then return end
		if c.Running then c:Stop()
		else c.MicroMovementEnabled=true;local ok,err=c:Start();UpdateExperimentalFlingPanel(ok and nil or err) end
	end)
	back.Activated:Connect(function()local ok,err=ExperimentalFlingCore:ForceReturn();UpdateExperimentalFlingPanel(ok and tr("Regreso completado.","Return complete.") or err)end)
	gui.Destroying:Connect(function()
		local c=ExperimentalFlingCore
		c:StopPassengerMonitor();c:Stop()
		if c.PlayerRemovingConnection then c.PlayerRemovingConnection:Disconnect() end
		if c.CharacterAddedConnection then c.CharacterAddedConnection:Disconnect() end
		if c.DiagnosticConnection then c.DiagnosticConnection:Disconnect() end
		if c.DiagnosticPreConnection then c.DiagnosticPreConnection:Disconnect() end
		if c.DiagnosticPostConnection then c.DiagnosticPostConnection:Disconnect() end
		if c.CharacterRemovingDiagnosticConnection then c.CharacterRemovingDiagnosticConnection:Disconnect() end
		if c.CharacterAddedDiagnosticConnection then c.CharacterAddedDiagnosticConnection:Disconnect() end
	end)
	UpdateExperimentalFlingPanel()
	return true
end
