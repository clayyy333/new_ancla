return function(context)
	setfenv(1,context)
	local function tr(es,en)return isES and es or en end
	experimentalFlingPanel=Instance.new("ScrollingFrame")
	local panel=experimentalFlingPanel
	panel.Size=UDim2.new(1,-16,1,-(titleH+20));panel.Position=UDim2.new(0,8,0,titleH+8)
	panel.BackgroundTransparency=1;panel.BorderSizePixel=0;panel.ScrollBarThickness=3;panel.CanvasSize=UDim2.new();panel.AutomaticCanvasSize=Enum.AutomaticSize.Y;panel.Visible=false;panel.ZIndex=6;panel.Parent=content
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
	local back=button(tr("Forzar regreso","Force return"))
	back.LayoutOrder=4
	local status=Instance.new("TextLabel");status.Size=UDim2.new(1,-12,0,68);status.TextWrapped=true;status.BackgroundTransparency=1;status.Font=Enum.Font.Gotham;status.TextSize=12;status.TextColor3=currentTheme.textDim;status.ZIndex=8;status.Parent=panel;RegisterTheme(status,"TextColor3","textDim")
	UpdateExperimentalFlingPanel=function(message)
		local c=ExperimentalFlingCore
		toggle.Text=c.Stopping and tr("Estabilizando…","Stabilizing…") or (c.Running and tr("Desactivar Fling experimental corto","Disable experimental short Fling") or tr("Activar Fling experimental corto","Enable experimental short Fling"))
		toggle.BackgroundColor3=c.Running and currentTheme.critical or currentTheme.tertiary
		status.Text=message or (c.Running and tr("Prueba activa: contacto breve y separación de 5 studs.","Test active: brief contact and 5-stud separation.") or tr("Experimental. Sin salida al void; no garantiza mayor efecto.","Experimental. No void travel; stronger effects are not guaranteed."))
	end
	status.LayoutOrder=5
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
		if ExperimentalFlingCore.Running then ExperimentalFlingCore:Stop()
		else local ok,err=ExperimentalFlingCore:Start();UpdateExperimentalFlingPanel(ok and nil or err) end
	end)
	back.Activated:Connect(function()local ok,err=ExperimentalFlingCore:ForceReturn();UpdateExperimentalFlingPanel(ok and tr("Regreso completado.","Return complete.") or err)end)
	gui.Destroying:Connect(function()ExperimentalFlingCore:Stop()end)
	UpdateExperimentalFlingPanel()
	return true
end
