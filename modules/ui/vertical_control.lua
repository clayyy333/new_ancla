-- Interfaz del desplazamiento vertical experimental.
return function(context)
	setfenv(1,context)
	verticalControlPanel=Instance.new("ScrollingFrame")
	verticalControlPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
	verticalControlPanel.Position=UDim2.new(0,8,0,titleH+8)
	verticalControlPanel.BackgroundTransparency=1
	verticalControlPanel.BorderSizePixel=0
	verticalControlPanel.ScrollBarThickness=3
	verticalControlPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y
	verticalControlPanel.CanvasSize=UDim2.new()
	verticalControlPanel.Visible=false
	verticalControlPanel.ZIndex=6
	verticalControlPanel.Parent=content
	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,-4,0,250)
	card.BackgroundColor3=currentTheme.secondary
	card.ZIndex=7;card.Parent=verticalControlPanel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
	RegisterTheme(card,"BackgroundColor3","secondary")
	local padding=Instance.new("UIPadding",card);padding.PaddingLeft=UDim.new(0,14);padding.PaddingRight=UDim.new(0,14);padding.PaddingTop=UDim.new(0,14)
	local function label(text,y,height)
		local item=Instance.new("TextLabel");item.Size=UDim2.new(1,0,0,height or 20);item.Position=UDim2.new(0,0,0,y);item.BackgroundTransparency=1;item.Text=text;item.TextWrapped=true;item.TextColor3=currentTheme.textDim;item.Font=Enum.Font.GothamMedium;item.TextSize=isMobile and 10 or 12;item.TextXAlignment=Enum.TextXAlignment.Left;item.ZIndex=8;item.Parent=card;RegisterTheme(item,"TextColor3","textDim");return item
	end
	local function button(text,y)
		local item=Instance.new("TextButton");item.Size=UDim2.new(1,0,0,44);item.Position=UDim2.new(0,0,0,y);item.BackgroundColor3=currentTheme.tertiary;item.Text=text;item.TextColor3=currentTheme.text;item.Font=Enum.Font.GothamBold;item.TextSize=isMobile and 11 or 13;item.AutoButtonColor=false;item.ZIndex=9;item.Parent=card;Instance.new("UICorner",item).CornerRadius=UDim.new(0,10);RegisterTheme(item,"BackgroundColor3","tertiary");RegisterTheme(item,"TextColor3","text");return item
	end
	label(isES and"Ubicación vertical relativa"or"Relative vertical location",0)
	local input=Instance.new("TextBox");input.Size=UDim2.new(1,0,0,44);input.Position=UDim2.new(0,0,0,26);input.BackgroundColor3=currentTheme.tertiary;input.Text="";input.PlaceholderText="-100";input.ClearTextOnFocus=true;input.TextColor3=currentTheme.text;input.PlaceholderColor3=currentTheme.textDim;input.Font=Enum.Font.GothamMedium;input.TextSize=isMobile and 11 or 13;input.ZIndex=9;input.Parent=card;Instance.new("UICorner",input).CornerRadius=UDim.new(0,10);local inset=Instance.new("UIPadding",input);inset.PaddingLeft=UDim.new(0,12);RegisterTheme(input,"BackgroundColor3","tertiary");RegisterTheme(input,"TextColor3","text");RegisterTheme(input,"PlaceholderColor3","textDim")
	local toggle=button(isES and"Activar desplazamiento"or"Activate displacement",82)
	local restore=button(isES and"Regresar al punto inicial"or"Return to starting point",134)
	local status=label("",188,44)
	UpdateVerticalControlPanel=function(message)
		local active=VerticalControlController:IsRunning()
		toggle.Text=active and(isES and"Desactivar desplazamiento"or"Disable displacement")or(isES and"Activar desplazamiento"or"Activate displacement")
		toggle.BackgroundColor3=active and currentTheme.accent or currentTheme.tertiary
		if input.Text==""then input.PlaceholderText=tostring(VerticalControlController:GetOffset())end
		status.Text=message or VerticalControlController.Status or(isES and"Usa valores negativos para bajar y positivos para subir."or"Use negative values to descend and positive values to rise.")
	end
	toggle.Activated:Connect(function()
		local ok,message
		if VerticalControlController:IsRunning()then ok,message=VerticalControlController:Stop(true)else ok,message=VerticalControlController:Start(input.Text~=""and input.Text or VerticalControlController:GetOffset())end
		UpdateVerticalControlPanel(message)
	end)
	restore.Activated:Connect(function()local _,message=VerticalControlController:Stop(true);UpdateVerticalControlPanel(message)end)
	input.FocusLost:Connect(function(enterPressed)
		if not enterPressed then return end
		local ok,result=VerticalControlController:SetOffset(input.Text)
		if ok then input.Text=tostring(result);UpdateVerticalControlPanel(isES and"Ubicación actualizada."or"Location updated.")else UpdateVerticalControlPanel(result)end
	end)
	UpdateVerticalControlPanel()
	return true
end
