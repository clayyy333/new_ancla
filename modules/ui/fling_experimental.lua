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
	local motoToggle=button(tr("Activar No motos","Enable No motorcycles"))
	motoToggle.LayoutOrder=5
	local moto2Toggle=button(tr("Activar No motos 2","Enable No motorcycles 2"))
	moto2Toggle.LayoutOrder=6
	local moto2Auto=button(tr("Activacion automatica No motos 2: OFF","No motorcycles 2 automatic activation: OFF"))
	moto2Auto.LayoutOrder=7
	local motoFeedback=Instance.new("TextLabel")
	motoFeedback.Size=UDim2.new(1,-12,0,52);motoFeedback.LayoutOrder=8
	motoFeedback.BackgroundTransparency=1;motoFeedback.TextWrapped=true
	motoFeedback.Font=Enum.Font.Gotham;motoFeedback.TextSize=12
	motoFeedback.TextColor3=currentTheme.textDim;motoFeedback.ZIndex=8;motoFeedback.Parent=panel
	motoFeedback.Text=tr("Selecciona arriba al propietario de la moto antes de activar.","Select the motorcycle owner above before enabling.")
	RegisterTheme(motoFeedback,"TextColor3","textDim")
	local lastMode
	local back=button(tr("Forzar regreso","Force return"))
	back.LayoutOrder=9
	local copyMotos=button(tr("Copiar reporte de No motos","Copy No motorcycles report"))
	copyMotos.LayoutOrder=9
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
		local motos=NoMotosCore.Running
		local motos2=NoMotos2Core.Running
		moto2Auto.Text=NoMotos2Core.AutoEnabled and tr("Activacion automatica No motos 2: ON","No motorcycles 2 automatic activation: ON")or tr("Activacion automatica No motos 2: OFF","No motorcycles 2 automatic activation: OFF")
		moto2Auto.BackgroundColor3=NoMotos2Core.AutoEnabled and currentTheme.critical or currentTheme.tertiary
		moto2Toggle.Text=motos2 and tr("Desactivar No motos 2","Disable No motorcycles 2")or tr("Activar No motos 2","Enable No motorcycles 2")
		moto2Toggle.BackgroundColor3=motos2 and currentTheme.critical or currentTheme.tertiary
		motoToggle.Text=NoMotosCore.Stopping and tr("Estabilizando No motos...","Stabilizing No motorcycles...") or (motos and tr("Desactivar No motos","Disable No motorcycles") or tr("Activar No motos","Enable No motorcycles"))
		motoToggle.BackgroundColor3=motos and currentTheme.critical or currentTheme.tertiary
		local c=ExperimentalFlingCore
		local target=c:GetTarget()
		if message then motoFeedback.Text=tostring(message)
		elseif motos then motoFeedback.Text=tr("Vigilando motos de @","Monitoring motorcycles owned by @")..NoMotosCore.Owner.Name
		elseif motos2 then motoFeedback.Text=tr("No motos 2: vehiculo propio contra vehiculos de @","No motorcycles 2: own vehicle against vehicles of @")..NoMotos2Core.Owner.Name
		elseif not target then motoFeedback.Text=tr("Falta seleccionar al propietario de la moto en la lista superior.","Select the motorcycle owner in the list above.")end
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
		if not message and motos then status.Text=tr("No motos: vigilando motos libres de ","No motorcycles: monitoring unoccupied bikes owned by ")..NoMotosCore.Owner.Name..". "..tr("Contacto en Body; regreso al checkpoint. No garantiza desplazamiento.","Body contact; returns to checkpoint. Displacement is not guaranteed.") end
		if not message and motos2 then status.Text=tr("No motos 2: vehiculos del propietario seleccionado, sin filtro de modelo. Contacto por ensamblaje; incluye ocupados durante la prueba.","No motorcycles 2: selected owner's vehicles, no model filter. Assembly-based contact; includes occupied vehicles during the test.")end
	end
	status.LayoutOrder=10
	copyDiagnostic.LayoutOrder=11;copyMotos.LayoutOrder=12;report.LayoutOrder=13
	moto2Auto.Activated:Connect(function()
		local ok,err=NoMotos2Core:SetAutoEnabled(not NoMotos2Core.AutoEnabled,ExperimentalFlingCore:GetTarget())
		if ok and NoMotos2Core.AutoEnabled then lastMode="motos2"end
		if not ok then UpdateExperimentalFlingPanel(err)end
	end)
	moto2Toggle.Activated:Connect(function()
		choices.Visible=false
		if NoMotos2Core.AutoEnabled then NoMotos2Core:SetAutoEnabled(false);return end
		if NoMotos2Core.Running then NoMotos2Core:Stop();return end
		local called,ok,err=xpcall(function()return NoMotos2Core:Start(ExperimentalFlingCore:GetTarget())end,debug.traceback)
		if not called then
			pcall(function()NoMotos2Core:Stop()end)
			report.Text=tostring(ok);report.Visible=true;UpdateExperimentalFlingPanel(tostring(ok))
		elseif not ok then UpdateExperimentalFlingPanel(err)
		else lastMode="motos2"end
	end)
	motoToggle.Activated:Connect(function()
		choices.Visible=false
		if NoMotosCore.Stopping then
			UpdateExperimentalFlingPanel(tr("Espera a que termine la estabilizacion.","Wait for stabilization to finish."));return
		end
		if NoMotosCore.Running then NoMotosCore:Stop()
		else
			local target=ExperimentalFlingCore:GetTarget()
			if not target then
				UpdateExperimentalFlingPanel(tr("No motos necesita que selecciones arriba al propietario de esa moto.","Select that motorcycle's owner above before enabling No motorcycles."))
				panel.CanvasPosition=Vector2.zero
				return
			end
			local called,ok,err=xpcall(function()return NoMotosCore:Start(target)end,debug.traceback)
			if not called then
				local failure=tostring(ok)
				pcall(function()NoMotosCore:Stop("Error al activar No motos.")end)
				report.Text=failure;report.Visible=true
				UpdateExperimentalFlingPanel(tr("Error al activar No motos; detalle en el reporte inferior: ","Could not enable No motorcycles; details below: ")..failure)
			elseif ok then lastMode="motos"else UpdateExperimentalFlingPanel(err)end
		end
	end)
	copyMotos.Activated:Connect(function()
		local text=lastMode=="motos2"and NoMotos2Core:GetDiagnosticReport()or NoMotosCore:GetDiagnosticReport()
		local copy=setclipboard or toclipboard
		local ok=type(copy)=="function" and pcall(copy,text)
		report.Text=text;report.Visible=not ok
		if not ok then report:CaptureFocus();report.SelectionStart=1;report.CursorPosition=#text+1 end
		UpdateExperimentalFlingPanel(ok and tr("Reporte de No motos copiado.","No motorcycles report copied.") or tr("Selecciona y copia el reporte mostrado abajo.","Select and copy the report below."))
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
				if p.Parent==Players and ExperimentalFlingCore:SetTarget(p) then
					choices.Visible=false
					if NoMotos2Core.AutoEnabled then NoMotos2Core:SetAutoEnabled(true,p)else UpdateExperimentalFlingPanel()end
				end
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
		if NoMotos2Core.Running then return end
		if ExperimentalFlingCore.Running or ExperimentalFlingCore.Stopping or NoMotosCore.Running or NoMotosCore.Stopping then return end
		choices.Visible=not choices.Visible
		if choices.Visible then refreshTargets() end
	end)
	local targetAdded=Players.PlayerAdded:Connect(function()if choices.Visible then refreshTargets() end end)
	local targetRemoved=Players.PlayerRemoving:Connect(function(leaving)
		if NoMotos2Core.AutoEnabled and ExperimentalFlingCore:GetTarget()==leaving then NoMotos2Core:SetAutoEnabled(false)end
		if NoMotos2Core.Running and NoMotos2Core.Owner==leaving then NoMotos2Core:Stop("El propietario seleccionado salio.")end
		if NoMotosCore.Running and NoMotosCore.Owner==leaving then NoMotosCore:Stop("El propietario seleccionado salio.")end
		if ExperimentalFlingCore:GetTarget()==leaving then
			if ExperimentalFlingCore.Running then ExperimentalFlingCore:Stop() end
			ExperimentalFlingCore:SetTarget(nil)
			selectTarget.Text=tr("Seleccionar jugador","Select player")
		end
		if choices.Visible then task.defer(function()if gui.Parent then refreshTargets() end end) end
	end)
	toggle.Activated:Connect(function()
		if NoMotos2Core.AutoEnabled then NoMotos2Core:SetAutoEnabled(false);return end
		if NoMotos2Core.Running then NoMotos2Core:Stop("Cambio de flujo.");return end
		if NoMotosCore.Running then NoMotosCore:Stop("Cambio de flujo.");return end
		if NoMotosCore.Stopping then return end
		lastMode=nil
		choices.Visible=false
		local c=ExperimentalFlingCore
		if c.Stopping then return end
		if c.Running then c:Stop()
		else c.MicroMovementEnabled=false;local ok,err=c:Start();UpdateExperimentalFlingPanel(ok and nil or err) end
	end)
	microToggle.Activated:Connect(function()
		if NoMotos2Core.AutoEnabled then NoMotos2Core:SetAutoEnabled(false);return end
		if NoMotos2Core.Running then NoMotos2Core:Stop("Cambio de flujo.");return end
		if NoMotosCore.Running then NoMotosCore:Stop("Cambio de flujo.");return end
		if NoMotosCore.Stopping then return end
		lastMode=nil
		choices.Visible=false
		local c=ExperimentalFlingCore
		if c.Stopping then return end
		if c.Running then c:Stop()
		else c.MicroMovementEnabled=true;local ok,err=c:Start();UpdateExperimentalFlingPanel(ok and nil or err) end
	end)
	back.Activated:Connect(function()
		if lastMode=="motos2"then
			if NoMotos2Core.AutoEnabled then NoMotos2Core:SetAutoEnabled(false);return end
			local ok,err=NoMotos2Core:ForceReturn();UpdateExperimentalFlingPanel(ok and tr("Regreso de No motos 2 solicitado.","No motorcycles 2 return requested.")or err);return
		end
		if lastMode=="motos"then
			local ok,err=NoMotosCore:ForceReturn();UpdateExperimentalFlingPanel(ok and tr("Regreso de No motos solicitado.","No motorcycles return requested.")or err);return
		end
		local ok,err=ExperimentalFlingCore:ForceReturn();UpdateExperimentalFlingPanel(ok and tr("Regreso completado.","Return complete.") or err)
	end)
	gui.Destroying:Connect(function()
		NoMotos2Core:Destroy()
		NoMotosCore:Destroy()
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
