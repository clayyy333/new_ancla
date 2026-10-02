-- Vista integrada de Shaders. La logica vive en NightShaderCore.
return function(context)
	setfenv(1,context)
	shaderPanel=Instance.new("ScrollingFrame")
	shaderPanel.Name="ShaderPanel";shaderPanel.Size=UDim2.new(1,-16,1,-(titleH+20));shaderPanel.Position=UDim2.new(0,8,0,titleH+8)
	shaderPanel.BackgroundTransparency=1;shaderPanel.BorderSizePixel=0;shaderPanel.ScrollBarThickness=3;shaderPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;shaderPanel.CanvasSize=UDim2.new();shaderPanel.Visible=false;shaderPanel.ZIndex=6;shaderPanel.Parent=content
	Instance.new("UIListLayout",shaderPanel).Padding=UDim.new(0,8);Instance.new("UIPadding",shaderPanel).PaddingBottom=UDim.new(0,8)
	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,-4,0,isMobile and 260 or 238);card.BackgroundColor3=currentTheme.secondary;card.BorderSizePixel=0;card.ZIndex=7;card.Parent=shaderPanel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,12);RegisterTheme(card,"BackgroundColor3","secondary")
	local heading=Instance.new("TextLabel")
	heading.Size=UDim2.new(1,-24,0,28);heading.Position=UDim2.new(0,12,0,10);heading.BackgroundTransparency=1;heading.Text=isES and "Shaders nocturnos" or "Night shaders";heading.TextColor3=currentTheme.text;heading.Font=Enum.Font.GothamBold;heading.TextSize=isMobile and 14 or 16;heading.TextXAlignment=Enum.TextXAlignment.Left;heading.ZIndex=8;heading.Parent=card;RegisterTheme(heading,"TextColor3","text")
	local description=Instance.new("TextLabel")
	description.Size=UDim2.new(1,-24,0,38);description.Position=UDim2.new(0,12,0,38);description.BackgroundTransparency=1;description.Text=isES and "Efectos visuales locales. No modifican la hora del juego." or "Local visual effects. They do not change game time.";description.TextColor3=currentTheme.textDim;description.Font=Enum.Font.Gotham;description.TextSize=isMobile and 10 or 11;description.TextWrapped=true;description.TextXAlignment=Enum.TextXAlignment.Left;description.ZIndex=8;description.Parent=card;RegisterTheme(description,"TextColor3","textDim")
	local function makeButton(text,y)
		local button=Instance.new("TextButton")
		button.Size=UDim2.new(1,-24,0,38);button.Position=UDim2.new(0,12,0,y);button.BackgroundColor3=currentTheme.tertiary;button.Text=text;button.TextColor3=currentTheme.text;button.Font=Enum.Font.GothamBold;button.TextSize=isMobile and 11 or 12;button.AutoButtonColor=false;button.ZIndex=8;button.Parent=card
		Instance.new("UICorner",button).CornerRadius=UDim.new(0,9);RegisterTheme(button,"BackgroundColor3","tertiary");RegisterTheme(button,"TextColor3","text");return button
	end
	local night4Button=makeButton("Noche 4",82)
	local horrorButton=makeButton(isES and "Noche de Halloween" or "Halloween Night",126)
	local disableButton=makeButton(isES and "Desactivar shader" or "Disable shader",170)
	local status=Instance.new("TextLabel")
	status.Size=UDim2.new(1,-24,0,24);status.Position=UDim2.new(0,12,0,212);status.BackgroundTransparency=1;status.TextColor3=currentTheme.textDim;status.Font=Enum.Font.Gotham;status.TextSize=isMobile and 10 or 11;status.TextXAlignment=Enum.TextXAlignment.Left;status.ZIndex=8;status.Parent=card;RegisterTheme(status,"TextColor3","textDim")
	local fireworksCard=Instance.new("Frame")
	fireworksCard.Size=UDim2.new(1,-4,0,isMobile and 250 or 230);fireworksCard.BackgroundColor3=currentTheme.secondary;fireworksCard.BorderSizePixel=0;fireworksCard.ZIndex=7;fireworksCard.Parent=shaderPanel
	Instance.new("UICorner",fireworksCard).CornerRadius=UDim.new(0,12);RegisterTheme(fireworksCard,"BackgroundColor3","secondary")
	local fireworksHeading=Instance.new("TextLabel")
	fireworksHeading.Size=UDim2.new(1,-24,0,28);fireworksHeading.Position=UDim2.new(0,12,0,10);fireworksHeading.BackgroundTransparency=1;fireworksHeading.Text=isES and "Fuegos Artificiales" or "Fireworks";fireworksHeading.TextColor3=currentTheme.text;fireworksHeading.Font=Enum.Font.GothamBold;fireworksHeading.TextSize=isMobile and 14 or 16;fireworksHeading.TextXAlignment=Enum.TextXAlignment.Left;fireworksHeading.ZIndex=8;fireworksHeading.Parent=fireworksCard;RegisterTheme(fireworksHeading,"TextColor3","text")
	local fireworksDescription=Instance.new("TextLabel")
	fireworksDescription.Size=UDim2.new(1,-24,0,34);fireworksDescription.Position=UDim2.new(0,12,0,38);fireworksDescription.BackgroundTransparency=1;fireworksDescription.Text=isES and "Espectáculo visual local optimizado. Escribe un nombre para mostrarlo en el cielo." or "Optimized local visual show. Enter a name to display it in the sky.";fireworksDescription.TextColor3=currentTheme.textDim;fireworksDescription.Font=Enum.Font.Gotham;fireworksDescription.TextSize=isMobile and 9 or 11;fireworksDescription.TextWrapped=true;fireworksDescription.TextXAlignment=Enum.TextXAlignment.Left;fireworksDescription.ZIndex=8;fireworksDescription.Parent=fireworksCard;RegisterTheme(fireworksDescription,"TextColor3","textDim")
	local fireworksToggle=Instance.new("TextButton")
	fireworksToggle.Size=UDim2.new(1,-24,0,36);fireworksToggle.Position=UDim2.new(0,12,0,77);fireworksToggle.BackgroundColor3=currentTheme.tertiary;fireworksToggle.TextColor3=currentTheme.text;fireworksToggle.Font=Enum.Font.GothamBold;fireworksToggle.TextSize=isMobile and 10 or 12;fireworksToggle.AutoButtonColor=false;fireworksToggle.ZIndex=8;fireworksToggle.Parent=fireworksCard;Instance.new("UICorner",fireworksToggle).CornerRadius=UDim.new(0,9);RegisterTheme(fireworksToggle,"TextColor3","text")
	local nameBox=Instance.new("TextBox")
	nameBox.Size=UDim2.new(.64,-16,0,38);nameBox.Position=UDim2.new(0,12,0,121);nameBox.BackgroundColor3=currentTheme.tertiary;nameBox.Text="";nameBox.PlaceholderText=isES and "Nombre (máximo 12 caracteres)" or "Name (12 characters maximum)";nameBox.ClearTextOnFocus=false;nameBox.TextColor3=currentTheme.text;nameBox.PlaceholderColor3=currentTheme.textDim;nameBox.Font=Enum.Font.Gotham;nameBox.TextSize=isMobile and 10 or 12;nameBox.ZIndex=8;nameBox.Parent=fireworksCard;Instance.new("UICorner",nameBox).CornerRadius=UDim.new(0,9);RegisterTheme(nameBox,"BackgroundColor3","tertiary");RegisterTheme(nameBox,"TextColor3","text");RegisterTheme(nameBox,"PlaceholderColor3","textDim")
	local applyName=Instance.new("TextButton")
	applyName.Size=UDim2.new(.36,-8,0,38);applyName.Position=UDim2.new(.64,0,0,121);applyName.BackgroundColor3=currentTheme.accent;applyName.Text=isES and "Aplicar" or "Apply";applyName.TextColor3=Color3.new(1,1,1);applyName.Font=Enum.Font.GothamBold;applyName.TextSize=isMobile and 10 or 12;applyName.AutoButtonColor=false;applyName.ZIndex=8;applyName.Parent=fireworksCard;Instance.new("UICorner",applyName).CornerRadius=UDim.new(0,9);RegisterTheme(applyName,"BackgroundColor3","accent")
	local fireworksStatus=Instance.new("TextLabel")
	fireworksStatus.Size=UDim2.new(1,-24,0,42);fireworksStatus.Position=UDim2.new(0,12,0,169);fireworksStatus.BackgroundTransparency=1;fireworksStatus.TextColor3=currentTheme.textDim;fireworksStatus.Font=Enum.Font.Gotham;fireworksStatus.TextSize=isMobile and 9 or 11;fireworksStatus.TextWrapped=true;fireworksStatus.TextXAlignment=Enum.TextXAlignment.Left;fireworksStatus.ZIndex=8;fireworksStatus.Parent=fireworksCard;RegisterTheme(fireworksStatus,"TextColor3","textDim")
	local function updateFireworks(message)
		local active=SkyFireworksCore and SkyFireworksCore:IsEnabled()
		fireworksToggle.Text=active and (isES and "Desactivar fuegos" or "Disable fireworks") or (isES and "Activar fuegos" or "Enable fireworks")
		fireworksStatus.Text=message or (active and (isES and "Estado: activado" or "Status: enabled") or (isES and "Estado: desactivado" or "Status: disabled"))
	end
	fireworksToggle.Activated:Connect(function()
		if not SkyFireworksCore then return end
		if SkyFireworksCore:IsEnabled() then SkyFireworksCore:Disable() else SkyFireworksCore:Enable() end
		updateFireworks()
	end)
	applyName.Activated:Connect(function()
		if not SkyFireworksCore then return end
		local text=tostring(nameBox.Text or ""):match("^%s*(.-)%s*$")
		if text=="" then updateFireworks(isES and "Escribe un nombre primero." or "Enter a name first.");return end
		local ok=SkyFireworksCore:ShowName(text)
		updateFireworks(ok and (isES and "El nombre aparecerá en 2 segundos..." or "The name will appear in 2 seconds...") or (isES and "No se pudo mostrar el nombre." or "The name could not be displayed."))
	end)
	updateFireworks()

	local busy=false
	UpdateShaderPanel=function(message)
		local mode=NightShaderCore and NightShaderCore:GetMode()
		local modeText=mode=="NIGHT4" and "Noche 4" or mode=="HORROR" and (isES and "Noche de Halloween" or "Halloween Night") or (isES and "Desactivado" or "Disabled")
		status.Text=message or ((isES and "Estado: " or "Status: ")..modeText)
		local active=not busy and NightShaderCore~=nil;night4Button.Active=active;horrorButton.Active=active;disableButton.Active=active
	end
	local function setMode(mode)
		if busy or not NightShaderCore then return end
		busy=true;UpdateShaderPanel(isES and "Aplicando shader..." or "Applying shader...")
		task.spawn(function()
			local ok=NightShaderCore:SetMode(mode)
			busy=false
			if ok then UpdateShaderPanel()
			else UpdateShaderPanel(isES and "No se pudo aplicar." or "Could not apply.") end
		end)
	end
	night4Button.Activated:Connect(function() setMode("NIGHT4") end)
	horrorButton.Activated:Connect(function() setMode("HORROR") end)
	disableButton.Activated:Connect(function() if not busy and NightShaderCore then NightShaderCore:Disable();UpdateShaderPanel() end end)
	UpdateShaderPanel();return true
end
