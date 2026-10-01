-- Panel del Fling personalizable independiente.
return function(context)
	setfenv(1,context)
	customFlingPanel=Instance.new("ScrollingFrame")
	customFlingPanel.Name="CustomFlingPanel";customFlingPanel.Size=UDim2.new(1,-16,1,-(titleH+20));customFlingPanel.Position=UDim2.new(0,8,0,titleH+8);customFlingPanel.BackgroundTransparency=1;customFlingPanel.BorderSizePixel=0;customFlingPanel.ScrollBarThickness=3;customFlingPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;customFlingPanel.CanvasSize=UDim2.new();customFlingPanel.Visible=false;customFlingPanel.ZIndex=6;customFlingPanel.Parent=content
	local layout=Instance.new("UIListLayout",customFlingPanel);layout.Padding=UDim.new(0,6)
	if player.UserId ~= 11739864999 or string.lower(player.Name) ~= "psychoo778" then
		local comingSoon=Instance.new("Frame")
		comingSoon.Name="ComingSoon"
		comingSoon.Size=UDim2.new(1,-4,0,isMobile and 54 or 62)
		comingSoon.BackgroundColor3=currentTheme.secondary
		comingSoon.BorderSizePixel=0
		comingSoon.ZIndex=7
		comingSoon.Parent=customFlingPanel
		Instance.new("UICorner",comingSoon).CornerRadius=UDim.new(0,12)
		RegisterTheme(comingSoon,"BackgroundColor3","secondary")

		local message=Instance.new("TextLabel")
		message.Size=UDim2.new(1,-20,1,0)
		message.Position=UDim2.new(0,10,0,0)
		message.BackgroundTransparency=1
		message.Text=isES and "Disponible Próximamente..." or "Coming Soon..."
		message.TextColor3=currentTheme.accent
		message.Font=Enum.Font.GothamBold
		message.TextSize=isMobile and 12 or 14
		message.ZIndex=8
		message.Parent=comingSoon
		RegisterTheme(message,"TextColor3","accent")
		return true
	end
	local function button(parent,text,size,pos)
		local b=Instance.new("TextButton");b.Size=size;b.Position=pos;b.BackgroundColor3=currentTheme.tertiary;b.Text=text;b.TextColor3=currentTheme.text;b.Font=Enum.Font.GothamBold;b.TextSize=isMobile and 10 or 11;b.AutoButtonColor=false;b.ZIndex=8;b.Parent=parent;Instance.new("UICorner",b).CornerRadius=UDim.new(0,8);RegisterTheme(b,"BackgroundColor3","tertiary");RegisterTheme(b,"TextColor3","text");return b
	end
	local infoDescriptions={
		VERTICAL_DISTANCE=isES and "Mueve nuestro HumanoidRootPart un poco arriba y abajo del HRP actual del target. No cambia el HRP del target." or "Moves our HumanoidRootPart slightly above and below the target's current HRP. It does not change the target's HRP.",
		LINEAR_SPEED=isES and "Ajusta la velocidad lineal vertical de nuestro HRP durante la fase cercana. No aplica velocidad al target." or "Adjusts our HRP's vertical linear velocity during the close phase. It does not apply velocity to the target.",
		ANGULAR_SPEED=isES and "Ajusta la velocidad de rotación de nuestro HRP durante el contacto cercano. No rota directamente al target." or "Adjusts our HRP's rotational velocity during close contact. It does not directly rotate the target.",
		FLINGER_SPEED=isES and "Controla la velocidad física aplicada por BodyVelocity a nuestro HRP durante el Fling y el desplazamiento lejano." or "Controls the physical velocity applied by BodyVelocity to our HRP during the fling and long-distance movement.",
		P=isES and "Controla la respuesta o potencia de BodyVelocity sobre nuestro HRP. Un valor mayor intenta alcanzar la velocidad configurada con más fuerza." or "Controls BodyVelocity responsiveness on our HRP. A higher value tries to reach the configured velocity with more force.",
		RECOVERY_DISTANCE=isES and "Define la separación lateral usada por nuestro HRP cuando el regreso directo al target necesita un intento de recuperación." or "Defines the lateral offset used by our HRP when the direct return to the target requires a recovery attempt.",
		NEAR_DISTANCE=isES and "Define a cuántos studs del HRP del target se considera que nuestro HRP regresó correctamente." or "Defines how many studs from the target's HRP are considered a successful return for our HRP.",
		FRONT_FLIP_SPEED=isES and "Controla la velocidad del giro frontal aplicado a nuestro HRP mientras el Fling está activo." or "Controls the front-flip speed applied to our HRP while the fling is active.",
		DISPLACEMENT_DISTANCE=isES and "Define cuántos studs se aleja nuestro HRP antes de regresar al HRP actual del target. No teletransporta al target." or "Defines how many studs our HRP travels away before returning to the target's current HRP. It does not teleport the target.",
	}

	local infoOverlay=Instance.new("TextButton")
	infoOverlay.Name="CustomFlingInfoOverlay";infoOverlay.Size=customFlingPanel.Size;infoOverlay.Position=customFlingPanel.Position;infoOverlay.BackgroundColor3=Color3.new(0,0,0);infoOverlay.BackgroundTransparency=.3;infoOverlay.Text="";infoOverlay.AutoButtonColor=false;infoOverlay.Visible=false;infoOverlay.ZIndex=80;infoOverlay.Parent=content
	local infoCard=Instance.new("Frame")
	infoCard.Size=UDim2.new(.86,0,0,isMobile and 190 or 170);infoCard.AnchorPoint=Vector2.new(.5,.5);infoCard.Position=UDim2.new(.5,0,.5,0);infoCard.BackgroundColor3=currentTheme.secondary;infoCard.BorderSizePixel=0;infoCard.Active=true;infoCard.ZIndex=81;infoCard.Parent=infoOverlay;Instance.new("UICorner",infoCard).CornerRadius=UDim.new(0,12);RegisterTheme(infoCard,"BackgroundColor3","secondary")
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
		{"VERTICAL_DISTANCE",isES and "Distancia vertical" or "Vertical distance",0.1},
		{"LINEAR_SPEED",isES and "Velocidad normal" or "Normal speed"},
		{"ANGULAR_SPEED",isES and "Velocidad angular" or "Angular speed"},
		{"FLINGER_SPEED",isES and "Velocidad física" or "Physics speed"},
		{"P",isES and "Potencia física" or "Physics power"},
		{"RECOVERY_DISTANCE",isES and "Distancia de recuperación" or "Recovery distance"},
		{"NEAR_DISTANCE",isES and "Distancia cercana" or "Near distance"},
		{"FRONT_FLIP_SPEED",isES and "Velocidad de giro" or "Flip speed"},
		{"DISPLACEMENT_DISTANCE",isES and "Distancia de desplazamiento" or "Displacement distance"},
	}
	local rows={};local stepOptions={1,100,1000};local stepIndex=1;local targetIndex=0
	for _,definition in ipairs(definitions) do
		local key,label,fixedStep=definition[1],definition[2],definition[3]
		local row=Instance.new("Frame");row.Size=UDim2.new(1,-4,0,50);row.BackgroundColor3=currentTheme.secondary;row.BorderSizePixel=0;row.ZIndex=7;row.Parent=customFlingPanel;Instance.new("UICorner",row).CornerRadius=UDim.new(0,10);RegisterTheme(row,"BackgroundColor3","secondary")
		local name=Instance.new("TextLabel");name.Size=UDim2.new(.28,-12,1,0);name.Position=UDim2.new(0,12,0,0);name.BackgroundTransparency=1;name.Text=label;name.TextColor3=currentTheme.text;name.Font=Enum.Font.Gotham;name.TextSize=isMobile and 9 or 11;name.TextWrapped=true;name.TextXAlignment=Enum.TextXAlignment.Left;name.ZIndex=8;name.Parent=row;RegisterTheme(name,"TextColor3","text")
		local infoButton=button(row,isES and "Información" or "Information",UDim2.new(.17,-6,0,28),UDim2.new(.28,0,.5,-14));infoButton.TextSize=isMobile and 8 or 9
		infoButton.Activated:Connect(function() showInfo(key,label) end)
		local minus=button(row,"−",UDim2.new(0,34,0,32),UDim2.new(.45,0,.5,-16));local value=button(row,"0",UDim2.new(.55,-92,0,32),UDim2.new(.45,40,.5,-16));value.Active=false;local plus=button(row,"+",UDim2.new(0,34,0,32),UDim2.new(1,-40,.5,-16))
		rows[key]={value=value,minus=minus,plus=plus,fixedStep=fixedStep}
		local function change(direction)
			if CustomFlingCore.Running or CustomFlingCore.Stopping then return end
			local values=CustomFlingCore:GetParameters();local amount=fixedStep or stepOptions[stepIndex]
			CustomFlingCore:SetParameter(key,values[key]+amount*direction);UpdateCustomFlingPanel()
		end
		minus.Activated:Connect(function() change(-1) end);plus.Activated:Connect(function() change(1) end)
	end
	UpdateCustomFlingPanel=function(message)
		local values=CustomFlingCore:GetParameters();local limits=CustomFlingCore:GetParameterLimits();local locked=CustomFlingCore.Running or CustomFlingCore.Stopping
		for key,row in pairs(rows) do row.value.Text=tostring(values[key]);row.minus.Active=not locked and values[key]>limits[key].min;row.plus.Active=not locked and values[key]<limits[key].max end
		local target=CustomFlingCore:GetTarget();targetButton.Text=target and (target.DisplayName or target.Name) or (isES and "Seleccionar jugador" or "Select player")
		toggleButton.Text=CustomFlingCore.Running and (isES and "Desactivar Fling personalizable" or "Disable Custom Fling") or (isES and "Activar Fling personalizable" or "Enable Custom Fling")
		stepButton.Text=(isES and "Aumentar o disminuir ajustes en: " or "Increase or decrease settings by: ")..tostring(stepOptions[stepIndex])
		minimumButton.Active=not locked;mediumButton.Active=not locked;maximumButton.Active=not locked
		if message then toggleButton.Text=message end
	end
	targetButton.Activated:Connect(function()
		if CustomFlingCore.Running then return end
		local options=CustomFlingCore.Provider:GetTargetOptions();if #options==0 then CustomFlingCore:SetTarget(nil);UpdateCustomFlingPanel(isES and "No hay jugadores" or "No players");return end
		targetIndex=targetIndex%#options+1;CustomFlingCore:SetTarget(options[targetIndex]);UpdateCustomFlingPanel()
	end)
	stepButton.Activated:Connect(function() stepIndex=stepIndex%#stepOptions+1;UpdateCustomFlingPanel() end)
	minimumButton.Activated:Connect(function() if CustomFlingCore:ApplyPreset("MINIMUM") then UpdateCustomFlingPanel() end end)
	mediumButton.Activated:Connect(function() if CustomFlingCore:ApplyPreset("MEDIUM") then UpdateCustomFlingPanel() end end)
	maximumButton.Activated:Connect(function() if CustomFlingCore:ApplyPreset("MAXIMUM") then UpdateCustomFlingPanel() end end)
	toggleButton.Activated:Connect(function()
		if CustomFlingCore.Running then CustomFlingCore:Stop();UpdateCustomFlingPanel();return end
		if not CustomFlingCore:GetTarget() then UpdateCustomFlingPanel(isES and "Selecciona un jugador" or "Select a player");return end
		local ok,err=CustomFlingCore:Start();UpdateCustomFlingPanel(ok and nil or err)
	end)
	returnButton.Activated:Connect(function() local ok,err=CustomFlingCore:ForceReturn();UpdateCustomFlingPanel(ok and nil or err) end)
	UpdateCustomFlingPanel();return true
end
