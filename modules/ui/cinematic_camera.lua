-- Perspectiva cinematica automatica integrada.
return function(context)
	setfenv(1,context)
	cinematicCameraPanel=Instance.new("ScrollingFrame");cinematicCameraPanel.BorderSizePixel=0;cinematicCameraPanel.ScrollBarThickness=3;cinematicCameraPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;cinematicCameraPanel.CanvasSize=UDim2.new();cinematicCameraPanel.Size=UDim2.new(1,-16,1,-(titleH+20));cinematicCameraPanel.Position=UDim2.new(0,8,0,titleH+8);cinematicCameraPanel.BackgroundTransparency=1;cinematicCameraPanel.Visible=false;cinematicCameraPanel.ZIndex=6;cinematicCameraPanel.Parent=content
	local card=Instance.new("Frame");card.Size=UDim2.new(1,0,0,180);card.BackgroundColor3=currentTheme.secondary;card.ZIndex=7;card.Parent=cinematicCameraPanel;Instance.new("UICorner",card).CornerRadius=UDim.new(0,14);RegisterTheme(card,"BackgroundColor3","secondary")
	local function button(parent,text,size,pos,z)
		local b=Instance.new("TextButton");b.Size=size;b.Position=pos;b.BackgroundColor3=currentTheme.tertiary;b.Text=text;b.TextColor3=currentTheme.text;b.Font=Enum.Font.GothamBold;b.TextSize=isMobile and 10 or 12;b.TextWrapped=true;b.AutoButtonColor=false;b.ZIndex=z or 8;b.Parent=parent;Instance.new("UICorner",b).CornerRadius=UDim.new(0,9);RegisterTheme(b,"BackgroundColor3","tertiary");RegisterTheme(b,"TextColor3","text");return b
	end
	local targetButton=button(card,isES and "Seleccionar jugador" or "Select player",UDim2.new(1,-24,0,40),UDim2.new(0,12,0,12))
	local activateButton=button(card,isES and "Activar perspectiva cinemática" or "Enable cinematic perspective",UDim2.new(1,-24,0,42),UDim2.new(0,12,0,60))
	local hint=Instance.new("TextLabel");hint.Size=UDim2.new(1,-24,0,54);hint.Position=UDim2.new(0,12,0,110);hint.BackgroundTransparency=1;hint.Text=isES and "La cámara girará automáticamente alrededor del target seleccionado." or "The camera will automatically orbit the selected target.";hint.TextWrapped=true;hint.TextColor3=currentTheme.textDim;hint.Font=Enum.Font.GothamMedium;hint.TextSize=isMobile and 10 or 12;hint.ZIndex=8;hint.Parent=card;RegisterTheme(hint,"TextColor3","textDim")
	local list=Instance.new("ScrollingFrame");list.Size=UDim2.new(1,-24,0,126);list.Position=UDim2.new(0,12,0,54);list.BackgroundColor3=currentTheme.tertiary;list.ScrollBarThickness=3;list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.CanvasSize=UDim2.new();list.Visible=false;list.ZIndex=30;list.Parent=card;Instance.new("UICorner",list).CornerRadius=UDim.new(0,10);RegisterTheme(list,"BackgroundColor3","tertiary");Instance.new("UIListLayout",list).Padding=UDim.new(0,3)

	local hudWidth=isMobile and 260 or 300
	local hud=Instance.new("Frame");hud.Name="CinematicCameraControls";hud.Size=UDim2.new(0,hudWidth,0,210);hud.AnchorPoint=Vector2.new(1,0);hud.Position=UDim2.new(1,-18,.5,-105);hud.BackgroundColor3=currentTheme.secondary;hud.BorderSizePixel=0;hud.ClipsDescendants=true;hud.Visible=false;hud.ZIndex=900;hud.Parent=gui;Instance.new("UICorner",hud).CornerRadius=UDim.new(0,12);RegisterTheme(hud,"BackgroundColor3","secondary")
	local hudStroke=Instance.new("UIStroke",hud);hudStroke.Color=currentTheme.stroke;hudStroke.Thickness=2;RegisterTheme(hudStroke,"Color","stroke")
	local title=Instance.new("TextLabel");title.Size=UDim2.new(1,-54,0,28);title.Position=UDim2.new(0,10,0,5);title.BackgroundTransparency=1;title.Text=isES and "Perspectiva cinemática" or "Cinematic perspective";title.TextColor3=currentTheme.accent;title.Font=Enum.Font.GothamBold;title.TextSize=isMobile and 11 or 12;title.TextXAlignment=Enum.TextXAlignment.Left;title.ZIndex=901;title.Parent=hud;RegisterTheme(title,"TextColor3","accent")
	local down=button(hud,isES and "Bajar −" or "Lower −",UDim2.new(.3,-8,0,34),UDim2.new(0,10,0,38),901)
	local elevation=button(hud,"20°",UDim2.new(.4,-8,0,34),UDim2.new(.3,4,0,38),901)
	local up=button(hud,isES and "Subir +" or "Raise +",UDim2.new(.3,-8,0,34),UDim2.new(.7,2,0,38),901)
	local closer=button(hud,isES and "Acercar" or "Closer",UDim2.new(.3,-8,0,34),UDim2.new(0,10,0,78),901)
	local zoom=button(hud,"12",UDim2.new(.4,-8,0,34),UDim2.new(.3,4,0,78),901)
	local farther=button(hud,isES and "Alejar" or "Farther",UDim2.new(.3,-8,0,34),UDim2.new(.7,2,0,78),901)
	local slower=button(hud,"−",UDim2.new(.2,-8,0,34),UDim2.new(0,10,0,118),901)
	local speed=button(hud,"20°/s",UDim2.new(.6,-8,0,34),UDim2.new(.2,4,0,118),901)
	local faster=button(hud,"+",UDim2.new(.2,-8,0,34),UDim2.new(.8,2,0,118),901)
	local direction=button(hud,isES and "Giro: derecha" or "Orbit: right",UDim2.new(.34,-10,0,40),UDim2.new(0,10,0,164),901)
	local pause=button(hud,isES and "Pausar" or "Pause",UDim2.new(.36,-8,0,40),UDim2.new(.34,4,0,164),901)
	local stop=button(hud,isES and "Detener" or "Stop",UDim2.new(.3,-10,0,40),UDim2.new(.7,0,0,164),901)
	local collapseSize=isMobile and 26 or 30
	local collapse=Instance.new("TextButton");collapse.Name="Minimize";collapse.Size=UDim2.fromOffset(collapseSize,collapseSize);collapse.Position=UDim2.new(1,-collapseSize-6,0,4);collapse.BackgroundColor3=currentTheme.tertiary;collapse.BorderSizePixel=0;collapse.Text="";collapse.AutoButtonColor=false;collapse.ZIndex=902;collapse.Parent=hud;Instance.new("UICorner",collapse).CornerRadius=UDim.new(.25,0);RegisterTheme(collapse,"BackgroundColor3","tertiary")
	local collapseHorizontal=Instance.new("Frame");collapseHorizontal.AnchorPoint=Vector2.new(.5,.5);collapseHorizontal.Position=UDim2.fromScale(.5,.5);collapseHorizontal.Size=UDim2.new(.4,0,0,2);collapseHorizontal.BorderSizePixel=0;collapseHorizontal.BackgroundColor3=currentTheme.text;collapseHorizontal.ZIndex=903;collapseHorizontal.Parent=collapse;RegisterTheme(collapseHorizontal,"BackgroundColor3","text")
	local collapseVertical=Instance.new("Frame");collapseVertical.AnchorPoint=Vector2.new(.5,.5);collapseVertical.Position=UDim2.fromScale(.5,.5);collapseVertical.Size=UDim2.new(0,2,.4,0);collapseVertical.BorderSizePixel=0;collapseVertical.BackgroundColor3=currentTheme.text;collapseVertical.Visible=false;collapseVertical.ZIndex=903;collapseVertical.Parent=collapse;RegisterTheme(collapseVertical,"BackgroundColor3","text")
	local hudCollapsed=false
	local hudControls={down,elevation,up,closer,zoom,farther,slower,speed,faster,direction,pause,stop}
	local collapseTween=nil
	local function setHudCollapsed(value)
		hudCollapsed=value==true
		if collapseTween then collapseTween:Cancel() end
		collapseVertical.Visible=hudCollapsed
		if not hudCollapsed then for _,control in ipairs(hudControls) do control.Visible=true end end
		collapseTween=TweenService:Create(hud,TweenInfo.new(.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,hudWidth,0,hudCollapsed and 38 or 210)})
		collapseTween:Play()
		if hudCollapsed then task.delay(.25,function() if hudCollapsed then for _,control in ipairs(hudControls) do control.Visible=false end end end) end
	end
	collapse.Activated:Connect(function() setHudCollapsed(not hudCollapsed) end)
	if not isMobile then
		collapse.MouseEnter:Connect(function() TweenService:Create(collapse,TweenInfo.new(.12),{Size=UDim2.fromOffset(collapseSize+4,collapseSize+4),Position=UDim2.new(1,-collapseSize-8,0,2)}):Play() end)
		collapse.MouseLeave:Connect(function() TweenService:Create(collapse,TweenInfo.new(.12),{Size=UDim2.fromOffset(collapseSize,collapseSize),Position=UDim2.new(1,-collapseSize-6,0,4)}):Play() end)
	end
	title.Active=true
	local dragging=false;local dragStart;local startPos
	local function startHudDrag(input)
		if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
		dragging=true
		dragStart=input.Position
		startPos=hud.Position
	end
	title.InputBegan:Connect(startHudDrag)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging or (input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch) then return end
		local delta=input.Position-dragStart
		hud.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=false end
	end)
	local selected=nil
	UpdateCinematicCameraPanel=function(message)
		local active=SpectatorController:IsCinematic()
		targetButton.Text=selected and (selected==player and ((isES and "Yo" or "Me").."  (@"..selected.Name..")") or selected.DisplayName.."  (@"..selected.Name..")") or (isES and "Seleccionar jugador" or "Select player")
		activateButton.Text=active and (isES and "Desactivar perspectiva cinemática" or "Disable cinematic perspective") or (isES and "Activar perspectiva cinemática" or "Enable cinematic perspective")
		elevation.Text=tostring(math.floor(SpectatorController:GetCinematicElevation())).."°";zoom.Text=tostring(math.floor(SpectatorController:GetZoom())).." studs";speed.Text=tostring(math.floor(SpectatorController:GetCinematicSpeed())).."°/s"
		pause.Text=SpectatorController:IsCinematicPaused() and (isES and "Reanudar giro" or "Resume orbit") or (isES and "Pausar giro" or "Pause orbit")
		direction.Text=SpectatorController:GetCinematicDirection()==1 and (isES and "Giro: derecha" or "Orbit: right") or (isES and "Giro: izquierda" or "Orbit: left")
		hud.Visible=active
		if message then hint.Text=message end
	end
	targetButton.Activated:Connect(function()
		list.Visible=not list.Visible
		if list.Visible then
			for _,child in ipairs(list:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
			for _,candidate in ipairs(SpectatorController:GetTargetOptions(true)) do
				local text=candidate==player and ((isES and "Yo" or "Me").."  (@"..candidate.Name..")") or candidate.DisplayName.."  (@"..candidate.Name..")"
				local option=button(list,text,UDim2.new(1,-4,0,34),UDim2.new(),31);option.Activated:Connect(function() selected=candidate;SpectatorController:SetCinematicTarget(candidate);list.Visible=false;UpdateCinematicCameraPanel() end)
			end
		end
	end)
	activateButton.Activated:Connect(function()
		if SpectatorController:IsCinematic() then SpectatorController:Stop();hud.Visible=false;UpdateCinematicCameraPanel();return end
		if not selected then UpdateCinematicCameraPanel(isES and "Selecciona un jugador, incluido tú mismo." or "Select a player, including yourself.");return end
		setHudCollapsed(false);local ok,err=SpectatorController:StartCinematic(selected);UpdateCinematicCameraPanel(ok and nil or err);if ok and MinimizeMainWindow then MinimizeMainWindow() end
	end)
	local function bindElevationControl(control,direction)
		local held=false
		control.InputBegan:Connect(function(input)
			if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
			if held then return end
			held=true
			SpectatorController:AddCinematicElevation(direction);UpdateCinematicCameraPanel()
			local started=os.clock();local previous=os.clock()
			task.spawn(function()
				while held and control.Parent do
					RunService.Heartbeat:Wait();local now=os.clock();local dt=now-previous;previous=now
					if now-started>=.22 then SpectatorController:AddCinematicElevation(direction*30*dt);UpdateCinematicCameraPanel() end
				end
			end)
		end)
		UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then held=false end end)
	end
	bindElevationControl(down,-1);bindElevationControl(up,1)
	local function bindZoomControl(control,direction)
		local held=false
		control.InputBegan:Connect(function(input)
			if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
			if held then return end
			held=true
			SpectatorController:SetZoom(SpectatorController:GetZoom()+direction);UpdateCinematicCameraPanel()
			local started=os.clock();local previous=os.clock()
			task.spawn(function()
				while held and control.Parent do
					RunService.Heartbeat:Wait();local now=os.clock();local dt=now-previous;previous=now
					if now-started>=.22 then SpectatorController:SetZoom(SpectatorController:GetZoom()+direction*14*dt);UpdateCinematicCameraPanel() end
				end
			end)
		end)
		UserInputService.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then held=false end end)
	end
	bindZoomControl(closer,-1);bindZoomControl(farther,1)
	slower.Activated:Connect(function() SpectatorController:AddCinematicSpeed(-5);UpdateCinematicCameraPanel() end);faster.Activated:Connect(function() SpectatorController:AddCinematicSpeed(5);UpdateCinematicCameraPanel() end)
	pause.Activated:Connect(function() SpectatorController:ToggleCinematicPause();UpdateCinematicCameraPanel() end)
	direction.Activated:Connect(function() SpectatorController:ToggleCinematicDirection();UpdateCinematicCameraPanel() end)
	stop.Activated:Connect(function() SpectatorController:Stop();hud.Visible=false;if OpenMainWindow then OpenMainWindow() end;UpdateCinematicCameraPanel() end)
	UpdateCinematicCameraPanel();return true
end
