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
