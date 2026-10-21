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
	selectTarget.Font=Enum.Font.GothamMedium;selectTarget.TextXAlignment=Enum.TextXAlignment.Left
	Instance.new("UIPadding",selectTarget).PaddingLeft=UDim.new(0,12)
	selectTarget.LayoutOrder=1
	local choices=Instance.new("ScrollingFrame");choices.Size=UDim2.new(1,-4,0,150);choices.BackgroundTransparency=1;choices.BorderSizePixel=0;choices.ScrollBarThickness=3;choices.CanvasSize=UDim2.new();choices.AutomaticCanvasSize=Enum.AutomaticSize.Y;choices.Visible=false;choices.ZIndex=7;choices.Parent=panel
	Instance.new("UIListLayout",choices).Padding=UDim.new(0,4)
	choices.LayoutOrder=2
	choices.BackgroundTransparency=0;choices.BackgroundColor3=currentTheme.tertiary;choices.Active=true
	choices.ScrollingDirection=Enum.ScrollingDirection.Y;choices.ScrollBarThickness=4;choices.ZIndex=30
	Instance.new("UICorner",choices).CornerRadius=UDim.new(0,10)
	RegisterTheme(choices,"BackgroundColor3","tertiary")
	local toggle=button(tr("Activar Fling experimental corto","Enable experimental short Fling"))
	toggle.LayoutOrder=3
	local microToggle=button(tr("Activar contacto sutil 0.5 studs","Enable subtle contact 0.5 studs"))
	microToggle.LayoutOrder=4
	local passToggle=button(tr("Probar paso recto · dayzero777 · 300 studs/s","Test straight pass · dayzero777 · 300 studs/s"))
	passToggle.LayoutOrder=5
	local back=button(tr("Forzar regreso","Force return"))
	back.LayoutOrder=6
	local copyPass=button(tr("Copiar diagnostico de paso recto","Copy straight pass diagnostic"))
	copyPass.LayoutOrder=9
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
		local passing=StraightPassTestCore and StraightPassTestCore.Running
		passToggle.Text=passing and tr("Detener prueba recta","Stop straight pass test") or tr("Probar paso recto · dayzero777 · 300 studs/s","Test straight pass · dayzero777 · 300 studs/s")
		passToggle.BackgroundColor3=passing and currentTheme.critical or currentTheme.tertiary
		local c=ExperimentalFlingCore
		local target=c:GetTarget()
		selectTarget.Text=target and (target.DisplayName.."  (@"..target.Name..")") or tr("Seleccionar jugador","Select player")
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
	status.LayoutOrder=7
	copyDiagnostic.LayoutOrder=8;report.LayoutOrder=10
	passToggle.Activated:Connect(function()
		choices.Visible=false
		if StraightPassTestCore.Running then StraightPassTestCore:Stop("Prueba cancelada manualmente.")
		else local ok,err=StraightPassTestCore:Start();if not ok then UpdateExperimentalFlingPanel(err) end end
	end)
	copyPass.Activated:Connect(function()
		local text=StraightPassTestCore:GetDiagnosticReport()
		local copy=setclipboard or toclipboard
		if type(copy)~="function" or not pcall(copy,text) then report.Text=text;report.Visible=true end
	end)
	local function refreshTargets()
		for _,b in ipairs(choices:GetChildren())do if b:IsA("GuiButton") or b:IsA("TextLabel") then b:Destroy() end end
		local players=Players:GetPlayers();table.sort(players,function(a,b)return a.Name:lower()<b.Name:lower()end)
		local count=0
		for _,p in ipairs(players)do if p~=player then
			count=count+1
			local b=button(p.DisplayName.."  (@"..p.Name..")");b.Parent=choices;b.Size=UDim2.new(1,-8,0,36)
			b.ZIndex=31;b.LayoutOrder=count;b.Font=Enum.Font.GothamMedium;b.TextXAlignment=Enum.TextXAlignment.Left
			b.AutoButtonColor=false
			Instance.new("UIPadding",b).PaddingLeft=UDim.new(0,12)
			b.Activated:Connect(function()
				if p.Parent==Players and ExperimentalFlingCore:SetTarget(p) then choices.Visible=false;UpdateExperimentalFlingPanel() end
			end)
		end end
		if count==0 then
			local empty=Instance.new("TextLabel");empty.Size=UDim2.new(1,-8,0,36);empty.BackgroundTransparency=1
			empty.Text=tr("No hay otros usuarios en este servidor","No other players in this server")
			empty.TextColor3=currentTheme.textDim;empty.Font=Enum.Font.Gotham;empty.TextSize=12;empty.ZIndex=31;empty.Parent=choices
		end
		choices.CanvasPosition=Vector2.zero
	end
	selectTarget.Activated:Connect(function()
		if ExperimentalFlingCore.Running or ExperimentalFlingCore.Stopping then return end
		choices.Visible=not choices.Visible
		if choices.Visible then refreshTargets() end
	end)
	local targetAdded=Players.PlayerAdded:Connect(function()if choices.Visible then refreshTargets() end end)
	local targetRemoved=Players.PlayerRemoving:Connect(function(leaving)
		if ExperimentalFlingCore:GetTarget()==leaving then
			if ExperimentalFlingCore.Running then ExperimentalFlingCore:Stop() end
			ExperimentalFlingCore:SetTarget(nil)
			selectTarget.Text=tr("Seleccionar jugador","Select player")
		end
		if choices.Visible then task.defer(function()if gui.Parent then refreshTargets() end end) end
	end)
	toggle.Activated:Connect(function()
		if StraightPassTestCore.Running then StraightPassTestCore:Stop("Cambio de flujo.") end
		choices.Visible=false
		local c=ExperimentalFlingCore
		if c.Stopping then return end
		if c.Running then c:Stop()
		else c.MicroMovementEnabled=false;local ok,err=c:Start();UpdateExperimentalFlingPanel(ok and nil or err) end
	end)
	microToggle.Activated:Connect(function()
		if StraightPassTestCore.Running then StraightPassTestCore:Stop("Cambio de flujo.") end
		choices.Visible=false
		local c=ExperimentalFlingCore
		if c.Stopping then return end
		if c.Running then c:Stop()
		else c.MicroMovementEnabled=true;local ok,err=c:Start();UpdateExperimentalFlingPanel(ok and nil or err) end
	end)
	back.Activated:Connect(function()
		if StraightPassTestCore.Running then StraightPassTestCore:Stop("Regreso solicitado.");return end
		local ok,err=ExperimentalFlingCore:ForceReturn();UpdateExperimentalFlingPanel(ok and tr("Regreso completado.","Return complete.") or err)
	end)
	gui.Destroying:Connect(function()
		StraightPassTestCore:Destroy()
		targetAdded:Disconnect();targetRemoved:Disconnect()
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
