return function(context)
	setfenv(1,context)
	bodyControlPanel=Instance.new("ScrollingFrame");bodyControlPanel.Size=UDim2.new(1,-16,1,-(titleH+20));bodyControlPanel.Position=UDim2.new(0,8,0,titleH+8);bodyControlPanel.BackgroundTransparency=1;bodyControlPanel.BorderSizePixel=0;bodyControlPanel.ScrollBarThickness=3;bodyControlPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;bodyControlPanel.CanvasSize=UDim2.new();bodyControlPanel.Visible=false;bodyControlPanel.Parent=content
	local card=Instance.new("Frame");card.Size=UDim2.new(1,-4,0,700);card.BackgroundColor3=currentTheme.secondary;card.Parent=bodyControlPanel;Instance.new("UICorner",card).CornerRadius=UDim.new(0,14);RegisterTheme(card,"BackgroundColor3","secondary")
	local pad=Instance.new("UIPadding",card);pad.PaddingLeft=UDim.new(0,14);pad.PaddingRight=UDim.new(0,14);pad.PaddingTop=UDim.new(0,14);pad.PaddingBottom=UDim.new(0,14)
	local function button(text,y,x,w)local b=Instance.new("TextButton");b.Size=UDim2.new(w or 1,0,0,38);b.Position=UDim2.new(x or 0,0,0,y);b.BackgroundColor3=currentTheme.tertiary;b.Text=text;b.TextColor3=currentTheme.text;b.Font=Enum.Font.GothamBold;b.TextSize=isMobile and 10 or 12;b.Parent=card;Instance.new("UICorner",b).CornerRadius=UDim.new(0,9);RegisterTheme(b,"BackgroundColor3","tertiary");RegisterTheme(b,"TextColor3","text");return b end
	local function label(text,y)local l=Instance.new("TextLabel");l.Size=UDim2.new(1,0,0,17);l.Position=UDim2.new(0,0,0,y);l.BackgroundTransparency=1;l.Text=text;l.TextColor3=currentTheme.textDim;l.Font=Enum.Font.GothamMedium;l.TextSize=isMobile and 10 or 12;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=card;RegisterTheme(l,"TextColor3","textDim");return l end
	local toggle=button("",0);local reset=button(isES and"Restablecer cuerpo"or"Reset body",46)
	local definitions={{"RightArmOpen",isES and"Abrir / cerrar brazo derecho"or"Right arm open / close"},{"RightArmLift",isES and"Levantar / bajar brazo derecho"or"Right arm lift / lower"},{"RightForearm",isES and"Flexionar antebrazo derecho"or"Right forearm bend"},{"LeftArmOpen",isES and"Abrir / cerrar brazo izquierdo"or"Left arm open / close"},{"LeftArmLift",isES and"Levantar / bajar brazo izquierdo"or"Left arm lift / lower"},{"LeftForearm",isES and"Flexionar antebrazo izquierdo"or"Left forearm bend"},{"LegsOpen",isES and"Abrir / cerrar piernas"or"Legs open / close"},{"RightLegLift",isES and"Levantar / bajar pierna derecha"or"Right leg lift / lower"},{"LeftLegLift",isES and"Levantar / bajar pierna izquierda"or"Left leg lift / lower"},{"Lean",isES and"Inclinación del cuerpo"or"Body lean"}}
	local displays={}
	for index,item in ipairs(definitions)do
		local y=94+(index-1)*55;label(item[2],y);local minus=button("−",y+19,0,.20);local value=button("",y+19,.22,.56);local plus=button("+",y+19,.80,.20);displays[item[1]]=value
		minus.MouseButton1Click:Connect(function()BodyPoseController:Change(item[1],-5);UpdateBodyControlPanel()end)
		plus.MouseButton1Click:Connect(function()BodyPoseController:Change(item[1],5);UpdateBodyControlPanel()end)
	end
	local status=label(isES and"Experimental: R15 ofrece control completo; R6 no tiene antebrazos separados."or"Experimental: R15 has full control; R6 has no separate forearms.",650)
	UpdateBodyControlPanel=function(message)
		toggle.Text=BodyPoseController:IsActive()and(isES and"Desactivar control corporal"or"Disable body control")or(isES and"Activar control corporal"or"Enable body control")
		toggle.BackgroundColor3=BodyPoseController:IsActive()and currentTheme.critical or currentTheme.tertiary
		for key,value in pairs(displays)do value.Text=tostring(BodyPoseController:Get(key)).."°"end
		if message then status.Text=message end
	end
	toggle.MouseButton1Click:Connect(function()local _,message;if BodyPoseController:IsActive()then _,message=BodyPoseController:Stop()else _,message=BodyPoseController:Start()end;UpdateBodyControlPanel(message)end)
	reset.MouseButton1Click:Connect(function()BodyPoseController:Reset();UpdateBodyControlPanel(isES and"Cuerpo restablecido."or"Body reset.")end)
	UpdateBodyControlPanel();return true
end