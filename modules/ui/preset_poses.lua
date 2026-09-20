-- Interfaz de poses predeterminadas.
return function(context)
	setfenv(1,context)
	presetPosePanel=Instance.new("ScrollingFrame");presetPosePanel.Size=UDim2.new(1,-16,1,-(titleH+20));presetPosePanel.Position=UDim2.new(0,8,0,titleH+8);presetPosePanel.BackgroundTransparency=1;presetPosePanel.BorderSizePixel=0;presetPosePanel.ScrollBarThickness=3;presetPosePanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;presetPosePanel.CanvasSize=UDim2.new();presetPosePanel.Visible=false;presetPosePanel.Parent=content
	local card=Instance.new("Frame");card.Size=UDim2.new(1,-4,0,770);card.BackgroundColor3=currentTheme.secondary;card.Parent=presetPosePanel;Instance.new("UICorner",card).CornerRadius=UDim.new(0,14);RegisterTheme(card,"BackgroundColor3","secondary")
	local pad=Instance.new("UIPadding",card);pad.PaddingLeft=UDim.new(0,14);pad.PaddingRight=UDim.new(0,14);pad.PaddingTop=UDim.new(0,14);pad.PaddingBottom=UDim.new(0,14)
	local function label(text,y)local l=Instance.new("TextLabel");l.Size=UDim2.new(1,0,0,18);l.Position=UDim2.new(0,0,0,y);l.BackgroundTransparency=1;l.Text=text;l.TextColor3=currentTheme.textDim;l.Font=Enum.Font.GothamMedium;l.TextSize=isMobile and 10 or 12;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=card;RegisterTheme(l,"TextColor3","textDim");return l end
	local function button(text,y,x,w)local b=Instance.new("TextButton");b.Size=UDim2.new(w or 1,0,0,40);b.Position=UDim2.new(x or 0,0,0,y);b.BackgroundColor3=currentTheme.tertiary;b.Text=text;b.TextColor3=currentTheme.text;b.Font=Enum.Font.GothamBold;b.TextSize=isMobile and 10 or 12;b.AutoButtonColor=false;b.Parent=card;Instance.new("UICorner",b).CornerRadius=UDim.new(0,10);RegisterTheme(b,"BackgroundColor3","tertiary");RegisterTheme(b,"TextColor3","text");return b end
	local function row(name,y)local l=label(name,y);local minus=button("−",y+20,0,.20);local value=button("",y+20,.22,.56);local plus=button("+",y+20,.80,.20);return minus,value,plus,l end
	local pose1Button=button("Pose 1",0,0,.32);local pose2Button=button("Pose 2",0,.34,.32);local pose3Button=button("Pose 3",0,.68,.32)
	label(isES and"Elige un rol"or"Choose a role",50)
	local boy=button(isES and"Chico"or"Boy",70,0,.49);local girl=button(isES and"Chica"or"Girl",70,.51,.49)
	label(isES and"Modo"or"Mode",120)
	local solo=button(isES and"Hacer pose solo"or"Solo pose",140,0,.49);local sync=button(isES and"Sincronizar"or"Synchronize",140,.51,.49)
	label(isES and"Amigo seleccionado"or"Selected friend",190)
	local target=button(isES and"Seleccionar amigo"or"Select friend",210)
	local list=Instance.new("ScrollingFrame");list.Size=UDim2.new(1,0,0,110);list.Position=UDim2.new(0,0,0,252);list.BackgroundColor3=currentTheme.tertiary;list.BorderSizePixel=0;list.ScrollBarThickness=3;list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.CanvasSize=UDim2.new();list.Visible=false;list.ZIndex=30;list.Parent=card;Instance.new("UICorner",list).CornerRadius=UDim.new(0,10);local layout=Instance.new("UIListLayout",list);layout.Padding=UDim.new(0,3);RegisterTheme(list,"BackgroundColor3","tertiary")
	local speedMinus,speedValue,speedPlus=row(isES and"Velocidad del emote"or"Emote speed",270)
	local distanceMinus,distanceValue,distancePlus=row(isES and"Distancia"or"Distance",330)
	local heightMinus,heightValue,heightPlus=row(isES and"Altura"or"Height",390)
	local orbitMinus,orbitValue,orbitPlus=row(isES and"Giro alrededor"or"Orbit rotation",450);orbitMinus.Text="↶";orbitPlus.Text="↷"
	local rotationMinus,rotationValue,rotationPlus=row(isES and"Giro sobre su eje"or"Own-axis rotation",510);rotationMinus.Text="↶";rotationPlus.Text="↷"
	local tiltMinus,tiltValue,tiltPlus=row(isES and"Girar adelante o atrás"or"Forward / backward tilt",570)
	local start=button(isES and"Iniciar Pose 1"or"Start Pose 1",634,0,.46);local pause=button(isES and"Pausar"or"Pause",634,.48,.24);local cancel=button(isES and"Cancelar"or"Cancel",634,.74,.26)
	local status=label(isES and"Selecciona Pose 1 y un rol."or"Select Pose 1 and a role.",686);status.TextWrapped=true;status.Size=UDim2.new(1,0,0,48)
	local poseHud=Instance.new("Frame");poseHud.Name="CouplesPosePlayback";poseHud.Size=isMobile and UDim2.new(0,330,0,62)or UDim2.new(0,470,0,66);poseHud.Position=UDim2.new(.5,0,1,-122);poseHud.AnchorPoint=Vector2.new(.5,1);poseHud.BackgroundColor3=currentTheme.secondary;poseHud.BackgroundTransparency=.08;poseHud.BorderSizePixel=0;poseHud.Visible=false;poseHud.ZIndex=520;poseHud.Parent=gui;Instance.new("UICorner",poseHud).CornerRadius=UDim.new(0,14);RegisterTheme(poseHud,"BackgroundColor3","secondary")
	local poseHudStroke=Instance.new("UIStroke",poseHud);poseHudStroke.Thickness=1.5;poseHudStroke.Transparency=.25;poseHudStroke.Color=currentTheme.accent;RegisterTheme(poseHudStroke,"Color","accent")
	local poseHudName=Instance.new("TextLabel");poseHudName.Size=UDim2.new(.42,-12,1,0);poseHudName.Position=UDim2.new(0,12,0,0);poseHudName.BackgroundTransparency=1;poseHudName.TextColor3=currentTheme.text;poseHudName.Font=Enum.Font.GothamBold;poseHudName.TextSize=isMobile and 11 or 13;poseHudName.TextXAlignment=Enum.TextXAlignment.Left;poseHudName.TextTruncate=Enum.TextTruncate.AtEnd;poseHudName.ZIndex=521;poseHudName.Parent=poseHud;RegisterTheme(poseHudName,"TextColor3","text")
	local function hudButton(text,x,w)local b=Instance.new("TextButton");b.Size=UDim2.new(w,-4,0,38);b.Position=UDim2.new(x,2,.5,-19);b.BackgroundColor3=currentTheme.tertiary;b.Text=text;b.TextColor3=currentTheme.text;b.Font=Enum.Font.GothamBold;b.TextSize=isMobile and 11 or 13;b.AutoButtonColor=false;b.ZIndex=521;b.Parent=poseHud;Instance.new("UICorner",b).CornerRadius=UDim.new(0,10);RegisterTheme(b,"BackgroundColor3","tertiary");RegisterTheme(b,"TextColor3","text");return b end
	local hudSpeedMinus=hudButton("−",.43,.09);local hudSpeed=hudButton("1.0x",.52,.16);local hudSpeedPlus=hudButton("+",.68,.09);local hudPause=hudButton(isES and"Pausar"or"Pause",.78,.21)
	local changeNotice=Instance.new("Frame");changeNotice.Size=UDim2.new(.72,0,0,168);changeNotice.Position=UDim2.fromScale(.5,.5);changeNotice.AnchorPoint=Vector2.new(.5,.5);changeNotice.BackgroundColor3=currentTheme.secondary;changeNotice.Visible=false;changeNotice.ZIndex=210;changeNotice.Parent=main;Instance.new("UICorner",changeNotice).CornerRadius=UDim.new(0,14);RegisterTheme(changeNotice,"BackgroundColor3","secondary")
	local noticeStroke=Instance.new("UIStroke",changeNotice);noticeStroke.Color=currentTheme.accent;noticeStroke.Thickness=2;RegisterTheme(noticeStroke,"Color","accent")
	local noticeText=Instance.new("TextLabel");noticeText.Size=UDim2.new(1,-24,0,72);noticeText.Position=UDim2.new(0,12,0,12);noticeText.BackgroundTransparency=1;noticeText.TextWrapped=true;noticeText.TextColor3=currentTheme.text;noticeText.Font=Enum.Font.GothamBold;noticeText.TextSize=isMobile and 12 or 14;noticeText.ZIndex=211;noticeText.Parent=changeNotice;RegisterTheme(noticeText,"TextColor3","text")
	local acceptChange=button(isES and"Sincronizar nueva pose"or"Sync new pose",0);acceptChange.Parent=changeNotice;acceptChange.Size=UDim2.new(1,-24,0,38);acceptChange.Position=UDim2.new(0,12,0,86);acceptChange.ZIndex=211
	local cancelChange=button(isES and"Cancelar pose"or"Cancel pose",0);cancelChange.Parent=changeNotice;cancelChange.Size=UDim2.new(1,-24,0,30);cancelChange.Position=UDim2.new(0,12,0,128);cancelChange.ZIndex=211;cancelChange.BackgroundColor3=currentTheme.critical;RegisterTheme(cancelChange,"BackgroundColor3","critical")
	ShowPresetPoseChange=function(name)noticeText.Text=(isES and"Tu compañero cambió a "or"Your partner changed to ")..name:gsub("Pose","Pose ")..".";changeNotice.Visible=true end
	HidePresetPoseChange=function()changeNotice.Visible=false end
	acceptChange.MouseButton1Click:Connect(function()local _,message=PresetPoseController:AcceptPendingPose();HidePresetPoseChange();UpdatePresetPosePanel(message)end)
	cancelChange.MouseButton1Click:Connect(function()local _,message=PresetPoseController:CancelPendingPose();HidePresetPoseChange();UpdatePresetPosePanel(message)end)
	local function active(buttonValue,value)buttonValue.BackgroundColor3=value and currentTheme.accent or currentTheme.tertiary end
	UpdatePresetPosePanel=function(message)
		local role=PresetPoseController:GetRole();local mode=PresetPoseController:GetMode();local friend=PresetPoseController:GetTarget();local selected=PresetPoseController:GetSelected()
		active(pose1Button,selected=="Pose1");active(pose2Button,selected=="Pose2");active(pose3Button,selected=="Pose3");active(boy,role=="boy");active(girl,role=="girl");active(solo,mode=="solo");active(sync,mode=="sync")
		target.Visible=mode=="sync";target.Text=friend and(friend.DisplayName.."  (@"..friend.Name..")")or(isES and"Seleccionar amigo"or"Select friend")
		speedValue.Text=string.format("%.1fx",PresetPoseController:GetSpeed());distanceValue.Text=string.format("%.1f studs",CouplesPositionController:GetDistance());heightValue.Text=string.format("%+.1f",CouplesPositionController:GetHeight());orbitValue.Text=math.floor(CouplesPositionController:GetAngle()).."°";rotationValue.Text=math.floor(CouplesPositionController:GetSelfAngle()).."°";tiltValue.Text=math.floor(CouplesPositionController:GetTilt()).."°"
		start.Text=(isES and"Iniciar "or"Start ")..selected:gsub("Pose","Pose ");pause.Text=PresetPoseController:IsPaused()and(isES and"Reanudar"or"Resume")or(isES and"Pausar"or"Pause");pause.BackgroundColor3=PresetPoseController:IsPaused()and currentTheme.accent or currentTheme.tertiary;cancel.BackgroundColor3=PresetPoseController:IsActive()and currentTheme.critical or currentTheme.tertiary
		status.Text=message or PresetPoseController:GetStatus();poseHud.Visible=PresetPoseController:IsActive();poseHudName.Text=PresetPoseController:GetActiveEmoteName();hudSpeed.Text=string.format("%.1fx",PresetPoseController:GetSpeed());hudPause.Text=PresetPoseController:IsPaused()and(isES and"Reanudar"or"Resume")or(isES and"Pausar"or"Pause");hudPause.BackgroundColor3=PresetPoseController:IsPaused()and currentTheme.accent or currentTheme.tertiary
	end
	pose1Button.MouseButton1Click:Connect(function()PresetPoseController:ChangePose("Pose1");UpdatePresetPosePanel(isES and"Pose 1 seleccionada."or"Pose 1 selected.")end)
	pose2Button.MouseButton1Click:Connect(function()PresetPoseController:ChangePose("Pose2");UpdatePresetPosePanel(isES and"Pose 2 seleccionada."or"Pose 2 selected.")end)
	pose3Button.MouseButton1Click:Connect(function()PresetPoseController:ChangePose("Pose3");UpdatePresetPosePanel(isES and"Pose 3 seleccionada."or"Pose 3 selected.")end)
	boy.MouseButton1Click:Connect(function()PresetPoseController:SetRole("boy");UpdatePresetPosePanel()end);girl.MouseButton1Click:Connect(function()PresetPoseController:SetRole("girl");UpdatePresetPosePanel()end)
	solo.MouseButton1Click:Connect(function()PresetPoseController:SetMode("solo");list.Visible=false;UpdatePresetPosePanel()end);sync.MouseButton1Click:Connect(function()PresetPoseController:SetMode("sync");UpdatePresetPosePanel()end)
	target.MouseButton1Click:Connect(function()
		list.Visible=not list.Visible;if not list.Visible then return end
		for _,child in ipairs(list:GetChildren())do if child~=layout then child:Destroy()end end
		local friends=PresetPoseController:GetFriendOptions()
		if #friends==0 then local l=label(isES and"No hay amigos en este servidor."or"No friends in this server.",0);l.Parent=list;l.Size=UDim2.new(1,-8,0,36)end
		for _,friend in ipairs(friends)do local option=button(friend.DisplayName.."  (@"..friend.Name..")",0);option.Parent=list;option.Size=UDim2.new(1,-4,0,36);option.Position=UDim2.new();option.ZIndex=31;option.MouseButton1Click:Connect(function()PresetPoseController:SetTarget(friend);list.Visible=false;UpdatePresetPosePanel()end)end
	end)
	local function adjust(method,delta)local ok=method(PresetPoseController,delta);UpdatePresetPosePanel(ok and nil or PresetPoseController:GetStatus())end
	speedMinus.MouseButton1Click:Connect(function()adjust(PresetPoseController.AdjustSpeed,-.1)end);speedPlus.MouseButton1Click:Connect(function()adjust(PresetPoseController.AdjustSpeed,.1)end)
	local function location(method,delta)method(CouplesPositionController,delta);UpdatePresetPosePanel()end
	distanceMinus.MouseButton1Click:Connect(function()location(CouplesPositionController.AdjustDistance,-.1)end);distancePlus.MouseButton1Click:Connect(function()location(CouplesPositionController.AdjustDistance,.1)end)
	heightMinus.MouseButton1Click:Connect(function()location(CouplesPositionController.AdjustHeight,-.1)end);heightPlus.MouseButton1Click:Connect(function()location(CouplesPositionController.AdjustHeight,.1)end)
	orbitMinus.MouseButton1Click:Connect(function()location(CouplesPositionController.AdjustAngle,-5)end);orbitPlus.MouseButton1Click:Connect(function()location(CouplesPositionController.AdjustAngle,5)end)
	rotationMinus.MouseButton1Click:Connect(function()location(CouplesPositionController.AdjustSelfAngle,-5)end);rotationPlus.MouseButton1Click:Connect(function()location(CouplesPositionController.AdjustSelfAngle,5)end)
	tiltMinus.MouseButton1Click:Connect(function()location(CouplesPositionController.AdjustTilt,-1)end);tiltPlus.MouseButton1Click:Connect(function()location(CouplesPositionController.AdjustTilt,1)end)
	start.MouseButton1Click:Connect(function()local _,message=PresetPoseController:Start();UpdatePresetPosePanel(message)end);pause.MouseButton1Click:Connect(function()local _,message=PresetPoseController:TogglePaused();UpdatePresetPosePanel(message)end);cancel.MouseButton1Click:Connect(function()local _,message=PresetPoseController:Stop();UpdatePresetPosePanel(message)end)
	hudSpeedMinus.MouseButton1Click:Connect(function()local ok=PresetPoseController:AdjustSpeed(-.1);UpdatePresetPosePanel(ok and nil or PresetPoseController:GetStatus())end)
	hudSpeedPlus.MouseButton1Click:Connect(function()local ok=PresetPoseController:AdjustSpeed(.1);UpdatePresetPosePanel(ok and nil or PresetPoseController:GetStatus())end)
	hudPause.MouseButton1Click:Connect(function()local _,message=PresetPoseController:TogglePaused();UpdatePresetPosePanel(message)end)
	UpdatePresetPosePanel();return true
end