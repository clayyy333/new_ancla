-- Panel del Fling personalizable independiente.
return function(context)
	setfenv(1,context)
	customFlingPanel=Instance.new("ScrollingFrame")
	customFlingPanel.Name="CustomFlingPanel";customFlingPanel.Size=UDim2.new(1,-16,1,-(titleH+20));customFlingPanel.Position=UDim2.new(0,8,0,titleH+8);customFlingPanel.BackgroundTransparency=1;customFlingPanel.BorderSizePixel=0;customFlingPanel.ScrollBarThickness=3;customFlingPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;customFlingPanel.CanvasSize=UDim2.new();customFlingPanel.Visible=false;customFlingPanel.ZIndex=6;customFlingPanel.Parent=content
	local layout=Instance.new("UIListLayout",customFlingPanel);layout.Padding=UDim.new(0,6)
	CustomFlingUsageActive=false
	local function markCustomFlingUsage()
		if customFlingPanel.Visible then CustomFlingUsageActive=true end
	end
	customFlingPanel:GetPropertyChangedSignal("Visible"):Connect(function()
		if not customFlingPanel.Visible then CustomFlingUsageActive=false end
	end)
	local function button(parent,text,size,pos)
		local b=Instance.new("TextButton");b.Size=size;b.Position=pos;b.BackgroundColor3=currentTheme.tertiary;b.Text=text;b.TextColor3=currentTheme.text;b.Font=Enum.Font.GothamBold;b.TextSize=isMobile and 10 or 11;b.AutoButtonColor=false;b.ZIndex=8;b.Parent=parent;Instance.new("UICorner",b).CornerRadius=UDim.new(0,8);RegisterTheme(b,"BackgroundColor3","tertiary");RegisterTheme(b,"TextColor3","text");return b
	end
	local infoDescriptions={
		VERTICAL_DISTANCE=isES and "Define la altura de nuestro HRP respecto al target durante el contacto. Un valor bajo lo mantiene casi a la misma altura; uno alto lo coloca más arriba. Ejemplo: 0.1 produce un contacto muy cercano y 1.5 deja mayor separación vertical." or "Sets our HRP height relative to the target during contact. A low value keeps it nearly level; a high value places it farther above. Example: 0.1 gives very close contact, while 1.5 adds more vertical separation.",
		LINEAR_SPEED=isES and "Controla la rapidez del movimiento de subida y bajada de nuestro HRP cerca del target. No es la velocidad normal al caminar. Ejemplo: un valor bajo genera un movimiento suave; uno alto cambia de posición mucho más rápido." or "Controls how quickly our HRP moves up and down near the target. This is not normal walking speed. Example: a low value creates gentler movement, while a high value changes position much faster.",
		ANGULAR_SPEED=isES and "Controla qué tan rápido gira nuestro HRP durante el contacto. Ese giro intenta transmitir impulso al target. Ejemplo: un valor bajo gira lentamente; uno alto hace que el giro sea mucho más rápido." or "Controls how fast our HRP spins during contact. That spin attempts to transfer momentum to the target. Example: a low value spins slowly, while a high value spins much faster.",
		FLINGER_SPEED=isES and "Define la velocidad física principal aplicada a nuestro HRP mientras hace contacto. Influye en la intensidad del impulso. Ejemplo: un valor bajo produce contacto moderado; uno alto lo vuelve más intenso." or "Sets the main physical speed applied to our HRP during contact. It affects momentum intensity. Example: a low value gives moderate contact, while a high value makes it more intense.",
		P=isES and "Controla con qué rapidez la fuerza lleva nuestro HRP hasta la velocidad elegida. No aumenta por sí sola la velocidad máxima. Ejemplo: un valor bajo responde de forma gradual; uno alto alcanza la velocidad configurada con mayor rapidez." or "Controls how quickly the force drives our HRP toward the selected speed. It does not increase the maximum speed by itself. Example: a low value responds gradually, while a high value reaches the configured speed faster.",
		RECOVERY_DISTANCE=isES and "Define cuánto se mueve nuestro HRP hacia un lado cuando el regreso al target falla y debe reintentarse. Ejemplo: 1 hace una corrección corta; 80 realiza un rodeo lateral mucho mayor antes de regresar." or "Sets how far our HRP moves sideways when returning to the target fails and must be retried. Example: 1 makes a short correction, while 80 takes a much wider sideways route before returning.",
		NEAR_DISTANCE=isES and "Define la distancia máxima para considerar que nuestro HRP regresó correctamente junto al target. Un valor menor exige más precisión. Ejemplo: 0.5 requiere quedar muy cerca; 6 acepta el regreso desde una separación mayor." or "Sets the maximum distance used to consider that our HRP returned correctly beside the target. A lower value requires more precision. Example: 0.5 requires very close placement, while 6 accepts a wider separation.",
		CONTACT_TIME=isES and "Define cuánto tiempo permanece nuestro HRP junto al target en cada contacto. Ejemplo: 0.05 segundos es un contacto breve y 0.30 segundos es más prolongado. Si está desactivado, se conserva el tiempo automático original de 0.040 a 0.085 segundos." or "Sets how long our HRP remains beside the target during each contact. Example: 0.05 seconds is brief, while 0.30 seconds is longer. When disabled, the original automatic timing of 0.040 to 0.085 seconds is preserved.",
		FRONT_FLIP_SPEED=isES and "Controla la rapidez de la voltereta hacia adelante de nuestro personaje durante el contacto. Ejemplo: 1 produce un giro lento; 60 genera una voltereta mucho más rápida." or "Controls how quickly our character performs the forward flip during contact. Example: 1 creates a slow rotation, while 60 produces a much faster flip.",
		DISPLACEMENT_DISTANCE=isES and "Define cuánto se aleja nuestro HRP antes de volver a la posición actual del target. Solo desplaza nuestro personaje. Ejemplo: un valor pequeño crea un recorrido corto; uno alto lo envía mucho más lejos antes del regreso." or "Sets how far our HRP travels before returning to the target's current position. It only moves our character. Example: a small value creates a short trip, while a high value sends it much farther away before returning.",
		AUTO_RETRY=isES and "Si el objetivo muere o reinicia su personaje, el flujo se mantiene activo, limpia temporalmente las fuerzas y espera su nuevo HumanoidRootPart. Cuando reaparece, reinicia el ciclo sobre el nuevo personaje." or "If the target dies or resets, the flow stays active, temporarily clears forces, and waits for the new HumanoidRootPart. When it appears, the cycle restarts on the new character.",
		MAX_CHASE_DISTANCE=isES and "Limita cuánto puede alejarse el objetivo desde el lugar donde activaste el fling. Si supera esta distancia, vuelves al punto inicial y la persecución queda en pausa hasta que regrese al rango." or "Limits how far the target may move from where you enabled the fling. Beyond this distance, you return to the starting point and pursuit pauses until the target returns within range.",
	}

	local infoOverlay=Instance.new("TextButton")
	infoOverlay.Name="CustomFlingInfoOverlay";infoOverlay.Size=customFlingPanel.Size;infoOverlay.Position=customFlingPanel.Position;infoOverlay.BackgroundColor3=Color3.new(0,0,0);infoOverlay.BackgroundTransparency=.3;infoOverlay.Text="";infoOverlay.AutoButtonColor=false;infoOverlay.Visible=false;infoOverlay.ZIndex=80;infoOverlay.Parent=content
	local infoCard=Instance.new("Frame")
	infoCard.Size=UDim2.new(.86,0,0,isMobile and 250 or 220);infoCard.AnchorPoint=Vector2.new(.5,.5);infoCard.Position=UDim2.new(.5,0,.5,0);infoCard.BackgroundColor3=currentTheme.secondary;infoCard.BorderSizePixel=0;infoCard.Active=true;infoCard.ZIndex=81;infoCard.Parent=infoOverlay;Instance.new("UICorner",infoCard).CornerRadius=UDim.new(0,12);RegisterTheme(infoCard,"BackgroundColor3","secondary")
	local infoTitle=Instance.new("TextLabel")
	infoTitle.Size=UDim2.new(1,-56,0,42);infoTitle.Position=UDim2.new(0,16,0,8);infoTitle.BackgroundTransparency=1;infoTitle.TextColor3=currentTheme.accent;infoTitle.Font=Enum.Font.GothamBold;infoTitle.TextSize=isMobile and 13 or 15;infoTitle.TextXAlignment=Enum.TextXAlignment.Left;infoTitle.ZIndex=82;infoTitle.Parent=infoCard;RegisterTheme(infoTitle,"TextColor3","accent")
	local infoBody=Instance.new("TextLabel")
	infoBody.Size=UDim2.new(1,-32,1,-62);infoBody.Position=UDim2.new(0,16,0,52);infoBody.BackgroundTransparency=1;infoBody.TextColor3=currentTheme.text;infoBody.Font=Enum.Font.Gotham;infoBody.TextSize=isMobile and 11 or 13;infoBody.TextWrapped=true;infoBody.TextXAlignment=Enum.TextXAlignment.Left;infoBody.TextYAlignment=Enum.TextYAlignment.Top;infoBody.ZIndex=82;infoBody.Parent=infoCard;RegisterTheme(infoBody,"TextColor3","text")
	local infoClose=button(infoCard,"×",UDim2.new(0,34,0,34),UDim2.new(1,-42,0,8));infoClose.TextSize=20;infoClose.ZIndex=83
	infoClose.Activated:Connect(function() infoOverlay.Visible=false end)
	infoOverlay.Activated:Connect(function() infoOverlay.Visible=false end)
	customFlingPanel:GetPropertyChangedSignal("Visible"):Connect(function() if not customFlingPanel.Visible then infoOverlay.Visible=false end end)
	local function showInfo(key,label)
		infoTitle.Text=label..(isES and " - Información" or " - Information")
		infoBody.Text=infoDescriptions[key] or (isES and "Sin información disponible." or "No information available.")
		infoOverlay.Visible=true
	end
	local header=Instance.new("Frame");header.Size=UDim2.new(1,-4,0,190);header.BackgroundColor3=currentTheme.secondary;header.BorderSizePixel=0;header.ZIndex=7;header.Parent=customFlingPanel;Instance.new("UICorner",header).CornerRadius=UDim.new(0,12);RegisterTheme(header,"BackgroundColor3","secondary")
	local targetButton=button(header,isES and "Seleccionar jugador" or "Select player",UDim2.new(1,-24,0,38),UDim2.new(0,12,0,10))
	local toggleButton=button(header,isES and "Activar Fling personalizable" or "Enable Custom Fling",UDim2.new(.62,-15,0,38),UDim2.new(0,12,0,54))
	local returnButton=button(header,isES and "Forzar regreso" or "Force return",UDim2.new(.38,-15,0,38),UDim2.new(.62,3,0,54))
	local stepButton=button(header,isES and "Aumentar o disminuir ajustes en: 1" or "Increase or decrease settings by: 1",UDim2.new(1,-24,0,38),UDim2.new(0,12,0,98))
	local minimumButton=button(header,isES and "Valores mínimos" or "Minimum values",UDim2.new(.333,-12,0,34),UDim2.new(0,12,0,142))
	local mediumButton=button(header,isES and "Valores medios" or "Medium values",UDim2.new(.334,-12,0,34),UDim2.new(.333,6,0,142))
	local maximumButton=button(header,isES and "Valores máximos" or "Maximum values",UDim2.new(.333,-12,0,34),UDim2.new(.667,0,0,142))
	local definitions={
		{"VERTICAL_DISTANCE",isES and "Altura del contacto" or "Contact height",0.1},
		{"LINEAR_SPEED",isES and "Rapidez de subida y bajada" or "Up/down speed"},
		{"ANGULAR_SPEED",isES and "Rapidez del giro" or "Spin speed"},
		{"FLINGER_SPEED",isES and "Impulso del contacto" or "Contact momentum"},
		{"P",isES and "Respuesta de la fuerza" or "Force response"},
		{"RECOVERY_DISTANCE",isES and "Distancia del reintento" or "Retry distance"},
		{"NEAR_DISTANCE",isES and "Precisión del regreso" or "Return precision"},
		{"CONTACT_TIME",isES and "Tiempo junto al objetivo" or "Time beside target",0.05,"contact"},
		{"FRONT_FLIP_SPEED",isES and "Rapidez de la voltereta" or "Flip speed"},
		{"DISPLACEMENT_DISTANCE",isES and "Distancia de alejamiento" or "Travel-away distance"},
		{"MAX_CHASE_DISTANCE",isES and "Límite de persecución" or "Pursuit limit",100,"chase"},
	}
	local rows={};local stepOptions={1,100,1000};local stepIndex=1;local targetIndex=0
	for _,definition in ipairs(definitions) do
		local key,label,fixedStep,toggleMode=definition[1],definition[2],definition[3],definition[4]
		local hasToggle=toggleMode~=nil
		local row=Instance.new("Frame");row.Size=UDim2.new(1,-4,0,50);row.BackgroundColor3=currentTheme.secondary;row.BorderSizePixel=0;row.ZIndex=7;row.Parent=customFlingPanel;Instance.new("UICorner",row).CornerRadius=UDim.new(0,10);RegisterTheme(row,"BackgroundColor3","secondary")
		local name=Instance.new("TextLabel");name.Size=UDim2.new(hasToggle and .22 or .28,-12,1,0);name.Position=UDim2.new(0,12,0,0);name.BackgroundTransparency=1;name.Text=label;name.TextColor3=currentTheme.text;name.Font=Enum.Font.Gotham;name.TextSize=isMobile and 9 or 11;name.TextWrapped=true;name.TextXAlignment=Enum.TextXAlignment.Left;name.ZIndex=8;name.Parent=row;RegisterTheme(name,"TextColor3","text")
		local infoButton=button(row,isES and "Información" or "Information",UDim2.new(hasToggle and .14 or .17,-6,0,28),UDim2.new(hasToggle and .22 or .28,0,.5,-14));infoButton.TextSize=isMobile and 8 or 9
		infoButton.Activated:Connect(function() showInfo(key,label) end)
		local controlsX=hasToggle and .55 or .45
		local optionToggle=nil
		if hasToggle then optionToggle=button(row,isES and "Desactivado" or "Disabled",UDim2.new(.19,-6,0,28),UDim2.new(.36,0,.5,-14));optionToggle.TextSize=isMobile and 8 or 9 end
		local minus=button(row,"−",UDim2.new(0,34,0,32),UDim2.new(controlsX,0,.5,-16));local value=button(row,"0",UDim2.new(1-controlsX,-92,0,32),UDim2.new(controlsX,40,.5,-16));value.Active=false;local plus=button(row,"+",UDim2.new(0,34,0,32),UDim2.new(1,-40,.5,-16))
		rows[key]={value=value,minus=minus,plus=plus,fixedStep=fixedStep,toggle=optionToggle,toggleMode=toggleMode}
		local function change(direction)
			if CustomFlingCore.Running or CustomFlingCore.Stopping then return end
			if toggleMode=="contact" and not CustomFlingCore:IsContactTimeEnabled() then return end
			if toggleMode=="chase" and not CustomFlingCore:IsMaxChaseEnabled() then return end
			local values=CustomFlingCore:GetParameters()
			if key=="NEAR_DISTANCE" then
				local nextValue=direction<0 and (values[key]<=1 and 0.5 or values[key]-1) or (values[key]<1 and 1 or values[key]+1)
				CustomFlingCore:SetParameter(key,nextValue);markCustomFlingUsage()
			else
				local amount=fixedStep or stepOptions[stepIndex]
				CustomFlingCore:SetParameter(key,values[key]+amount*direction);markCustomFlingUsage()
			end
			UpdateCustomFlingPanel()
		end
		minus.Activated:Connect(function() change(-1) end);plus.Activated:Connect(function() change(1) end)
		if optionToggle then optionToggle.Activated:Connect(function() local ok=false;if toggleMode=="contact" then ok=CustomFlingCore:SetContactTimeEnabled(not CustomFlingCore:IsContactTimeEnabled()) elseif toggleMode=="chase" then ok=CustomFlingCore:SetMaxChaseEnabled(not CustomFlingCore:IsMaxChaseEnabled()) end;if ok then markCustomFlingUsage();UpdateCustomFlingPanel() end end) end
	end
	local retryRow=Instance.new("Frame");retryRow.Size=UDim2.new(1,-4,0,50);retryRow.BackgroundColor3=currentTheme.secondary;retryRow.BorderSizePixel=0;retryRow.ZIndex=7;retryRow.Parent=customFlingPanel;Instance.new("UICorner",retryRow).CornerRadius=UDim.new(0,10);RegisterTheme(retryRow,"BackgroundColor3","secondary")
	local retryName=Instance.new("TextLabel");retryName.Size=UDim2.new(.38,-12,1,0);retryName.Position=UDim2.new(0,12,0,0);retryName.BackgroundTransparency=1;retryName.Text=isES and "Reintento automático" or "Automatic retry";retryName.TextColor3=currentTheme.text;retryName.Font=Enum.Font.Gotham;retryName.TextSize=isMobile and 9 or 11;retryName.TextWrapped=true;retryName.TextXAlignment=Enum.TextXAlignment.Left;retryName.ZIndex=8;retryName.Parent=retryRow;RegisterTheme(retryName,"TextColor3","text")
	local retryInfo=button(retryRow,isES and "Información" or "Information",UDim2.new(.22,-6,0,28),UDim2.new(.38,0,.5,-14));retryInfo.TextSize=isMobile and 8 or 9;retryInfo.Activated:Connect(function() showInfo("AUTO_RETRY",retryName.Text) end)
	local retryToggle=button(retryRow,isES and "Desactivado" or "Disabled",UDim2.new(.36,-12,0,32),UDim2.new(.62,0,.5,-16))
	retryToggle.Activated:Connect(function() local ok=CustomFlingCore:SetAutoRetryEnabled(not CustomFlingCore:IsAutoRetryEnabled());if ok then markCustomFlingUsage();UpdateCustomFlingPanel() end end)
	rows.AUTO_RETRY={toggle=retryToggle,toggleOnly=true,toggleMode="retry"}
	local saveButton=button(customFlingPanel,isES and "Guardar ajustes" or "Save settings",UDim2.new(1,-4,0,44),UDim2.new())
	saveButton.Activated:Connect(function()
		local profile=CustomFlingCore:ExportSettings()
		Settings.customFlingSettings=profile
		SaveLocalData()
		markCustomFlingUsage()
		saveButton.Text=isES and "Guardado localmente" or "Saved locally"
		if BackendAnchorGuard and BackendAnchorGuard.SaveCustomFlingProfile then
			BackendAnchorGuard:SaveCustomFlingProfile(profile,function(ok)
				saveButton.Text=ok and (isES and "Guardado local y en backend" or "Saved locally and to backend") or (isES and "Guardado local; backend no disponible" or "Saved locally; backend unavailable")
			end)
		else
			saveButton.Text=isES and "Guardado local; backend no disponible" or "Saved locally; backend unavailable"
		end
	end)
	UpdateCustomFlingPanel=function(message)
		local values=CustomFlingCore:GetParameters();local limits=CustomFlingCore:GetParameterLimits();local locked=CustomFlingCore.Running or CustomFlingCore.Stopping
		for key,row in pairs(rows) do
			local optionEnabled=true
			if row.toggleMode=="contact" then optionEnabled=CustomFlingCore:IsContactTimeEnabled()
			elseif row.toggleMode=="chase" then optionEnabled=CustomFlingCore:IsMaxChaseEnabled()
			elseif row.toggleMode=="retry" then optionEnabled=CustomFlingCore:IsAutoRetryEnabled() end
			if not row.toggleOnly then
				row.value.Text=tostring(values[key])
				row.minus.Active=not locked and optionEnabled and values[key]>limits[key].min
				row.plus.Active=not locked and optionEnabled and values[key]<limits[key].max
			end
			if row.toggle then
				row.toggle.Active=not locked
				row.toggle.Text=optionEnabled and (isES and "Activado" or "Enabled") or (isES and "Desactivado" or "Disabled")
				row.toggle.BackgroundColor3=optionEnabled and currentTheme.accent or currentTheme.tertiary
			end
		end
		local target=CustomFlingCore:GetTarget();targetButton.Text=target and (target.DisplayName or target.Name) or (isES and "Seleccionar jugador" or "Select player")
		toggleButton.Text=CustomFlingCore.Running and (isES and "Desactivar Fling personalizable" or "Disable Custom Fling") or (isES and "Activar Fling personalizable" or "Enable Custom Fling")
		stepButton.Text=(isES and "Aumentar o disminuir ajustes en: " or "Increase or decrease settings by: ")..tostring(stepOptions[stepIndex])
		minimumButton.Active=not locked;mediumButton.Active=not locked;maximumButton.Active=not locked
		if message then toggleButton.Text=message end
	end
	targetButton.Activated:Connect(function()
		if CustomFlingCore.Running then return end
		local options=CustomFlingCore.Provider:GetTargetOptions();if #options==0 then CustomFlingCore:SetTarget(nil);UpdateCustomFlingPanel(isES and "No hay jugadores" or "No players");return end
		targetIndex=targetIndex%#options+1;CustomFlingCore:SetTarget(options[targetIndex]);markCustomFlingUsage();UpdateCustomFlingPanel()
	end)
	stepButton.Activated:Connect(function() stepIndex=stepIndex%#stepOptions+1;markCustomFlingUsage();UpdateCustomFlingPanel() end)
	minimumButton.Activated:Connect(function() if CustomFlingCore:ApplyPreset("MINIMUM") then markCustomFlingUsage();UpdateCustomFlingPanel() end end)
	mediumButton.Activated:Connect(function() if CustomFlingCore:ApplyPreset("MEDIUM") then markCustomFlingUsage();UpdateCustomFlingPanel() end end)
	maximumButton.Activated:Connect(function() if CustomFlingCore:ApplyPreset("MAXIMUM") then markCustomFlingUsage();UpdateCustomFlingPanel() end end)
	toggleButton.Activated:Connect(function()
		if CustomFlingCore.Running then CustomFlingCore:Stop();markCustomFlingUsage();UpdateCustomFlingPanel();return end
		if not CustomFlingCore:GetTarget() then UpdateCustomFlingPanel(isES and "Selecciona un jugador" or "Select a player");return end
		local ok,err=CustomFlingCore:Start();if ok then markCustomFlingUsage() end;UpdateCustomFlingPanel(ok and nil or err)
	end)
	returnButton.Activated:Connect(function() local ok,err=CustomFlingCore:ForceReturn();if ok then markCustomFlingUsage() end;UpdateCustomFlingPanel(ok and nil or err) end)
	UpdateCustomFlingPanel();return true
end
