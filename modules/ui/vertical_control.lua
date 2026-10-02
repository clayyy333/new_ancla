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
	label(isES and"Altura vertical (-10 a 10)"or"Vertical height (-10 to 10)",0)
	local down=button("−",26);down.Size=UDim2.new(.2,-4,0,44);down.Position=UDim2.new(0,0,0,26)
	local offsetValue=button("-5",26);offsetValue.Size=UDim2.new(.6,-8,0,44);offsetValue.Position=UDim2.new(.2,4,0,26);offsetValue.Active=false
	local up=button("+",26);up.Size=UDim2.new(.2,-4,0,44);up.Position=UDim2.new(.8,4,0,26)
	local toggle=button(isES and"Activar desplazamiento"or"Activate displacement",82)
	local restore=button(isES and"Regresar al punto inicial"or"Return to starting point",134)
	local status=label("",188,44)
	UpdateVerticalControlPanel=function(message)
		local active=VerticalControlController:IsRunning()
		toggle.Text=active and(isES and"Desactivar desplazamiento"or"Disable displacement")or(isES and"Activar desplazamiento"or"Activate displacement")
		toggle.BackgroundColor3=active and currentTheme.accent or currentTheme.tertiary
		offsetValue.Text=tostring(VerticalControlController:GetOffset()).." studs"
		status.Text=message or VerticalControlController.Status or(isES and"Al activar usa Ancla, AntiSeat, Heartbeat y el emote Invisible."or"Enabling uses Anchor, AntiSeat, Heartbeat, and the Invisible emote.")
	end
	toggle.Activated:Connect(function()
		local ok,message
		if VerticalControlController:IsRunning()then ok,message=VerticalControlController:Stop(true)else ok,message=VerticalControlController:Start(VerticalControlController:GetOffset())end
		UpdateVerticalControlPanel(message)
	end)
	restore.Activated:Connect(function()local _,message=VerticalControlController:Stop(true);UpdateVerticalControlPanel(message)end)
	down.Activated:Connect(function()
		local ok,result=VerticalControlController:SetOffset(VerticalControlController:GetOffset()-1)
		UpdateVerticalControlPanel(ok and (isES and"Altura reducida a "or"Height lowered to ")..tostring(result) or result)
	end)
	up.Activated:Connect(function()
		local ok,result=VerticalControlController:SetOffset(VerticalControlController:GetOffset()+1)
		UpdateVerticalControlPanel(ok and (isES and"Altura aumentada a "or"Height raised to ")..tostring(result) or result)
	end)
	UpdateVerticalControlPanel()
	return true
end
