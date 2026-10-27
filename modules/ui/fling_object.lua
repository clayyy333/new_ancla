-- Vista Object Fling integrada en la categoria Fling 2.
return function(context)
	setfenv(1, context)

	objectFlingPanel=Instance.new("ScrollingFrame");objectFlingPanel.BorderSizePixel=0;objectFlingPanel.ScrollBarThickness=3;objectFlingPanel.ScrollingDirection=Enum.ScrollingDirection.Y;objectFlingPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;objectFlingPanel.CanvasSize=UDim2.new();objectFlingPanel.Active=true
	objectFlingPanel.Name = "ObjectFlingPanel"
	objectFlingPanel.Size = UDim2.new(1, -16, 1, -(titleH + 20))
	objectFlingPanel.Position = UDim2.new(0, 8, 0, titleH + 8)
	objectFlingPanel.BackgroundTransparency = 1
	objectFlingPanel.Visible = false
	objectFlingPanel.ZIndex = 6
	objectFlingPanel.Parent = content

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 960)
	card.BackgroundColor3 = currentTheme.secondary
	card.ZIndex = 7
	card.Parent = objectFlingPanel
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
	RegisterTheme(card, "BackgroundColor3", "secondary")
	local pad = Instance.new("UIPadding", card)
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop = UDim.new(0,14), UDim.new(0,14), UDim.new(0,14)

	local function makeLabel(text, y)
		local label = Instance.new("TextLabel")
		label.Size, label.Position = UDim2.new(1,0,0,18), UDim2.new(0,0,0,y)
		label.BackgroundTransparency, label.Text = 1, text
		label.TextColor3, label.Font, label.TextSize = currentTheme.textDim, Enum.Font.GothamMedium, isMobile and 11 or 12
		label.TextXAlignment, label.ZIndex, label.Parent = Enum.TextXAlignment.Left, 8, card
		RegisterTheme(label, "TextColor3", "textDim")
		return label
	end
	local function makeSelector(text, y)
		local button = Instance.new("TextButton")
		button.Size, button.Position = UDim2.new(1,0,0,38), UDim2.new(0,0,0,y)
		button.BackgroundColor3, button.Text = currentTheme.tertiary, text
		button.TextColor3, button.Font, button.TextSize = currentTheme.text, Enum.Font.GothamMedium, isMobile and 11 or 13
		button.TextXAlignment, button.AutoButtonColor, button.ZIndex, button.Parent = Enum.TextXAlignment.Left, false, 10, card
		Instance.new("UICorner", button).CornerRadius = UDim.new(0,10)
		Instance.new("UIPadding", button).PaddingLeft = UDim.new(0,12)
		RegisterTheme(button, "BackgroundColor3", "tertiary"); RegisterTheme(button, "TextColor3", "text")
		return button
	end
	local function makeList(y)
		local list = Instance.new("ScrollingFrame")
		list.Size, list.Position = UDim2.new(1,0,0,108), UDim2.new(0,0,0,y)
		list.BackgroundColor3, list.ScrollBarThickness = currentTheme.tertiary, 4
		list.AutomaticCanvasSize, list.CanvasSize, list.Visible = Enum.AutomaticSize.Y, UDim2.new(), false
		list.ZIndex, list.Parent = 30, card
		Instance.new("UICorner", list).CornerRadius = UDim.new(0,10)
		Instance.new("UIListLayout", list).Padding = UDim.new(0,3)
		RegisterTheme(list, "BackgroundColor3", "tertiary")
		return list
	end
	local function makeOption(list, text, callback)
		local option = Instance.new("TextButton")
		option.Size, option.BackgroundColor3 = UDim2.new(1,-4,0,32), currentTheme.secondary
		option.Text, option.TextColor3, option.Font = text, currentTheme.text, Enum.Font.GothamMedium
		option.TextSize, option.ZIndex, option.Parent = isMobile and 10 or 12, 31, list
		Instance.new("UICorner", option).CornerRadius = UDim.new(0,8)
		RegisterTheme(option, "BackgroundColor3", "secondary"); RegisterTheme(option, "TextColor3", "text")
		option.MouseButton1Click:Connect(callback)
	end

	local core=ObjectV8FlingCore
	local target
	local inputService=game:GetService("UserInputService")
	local connections={}
	local fields={}
	local dragging,dragInput
	local title=makeLabel("V8 persistente · sin giro",0)
	local playerButton=makeSelector(L.selectPlayer,26)
	local playerList=makeList(68)
	local action=makeSelector("Activar V8 persistente",76)
	action.TextXAlignment=Enum.TextXAlignment.Center
	local status=makeLabel("",124);status.Size=UDim2.new(1,0,0,38);status.TextWrapped=true
	local settings={
		{"ContactSpeed","Pulso al cruzar: velocidad total",0,1000000000,true},
		{"Speed","Velocidad lineal",0,1000000000,true},
		{"Distance","Alejamiento (studs)",.5,2000000000,true},
		{"Azimuth","Angulo: 0 delante / 180 detras",-360,360,false},
		{"Elevation","Elevacion: -90 abajo / 90 arriba",-90,90,false},
		{"ContactTime","Preparacion alejado (s)",.01,10,false},
		{"LaunchTime","Margen de llegada (s)",.01,10,false},
	}
	local function ratio(entry,value)
		if entry[5]then return math.log(1+value-entry[3])/math.log(1+entry[4]-entry[3])end
		return (value-entry[3])/(entry[4]-entry[3])
	end
	local function paint(field)
		local value=core.Config[field.Entry[1]]
		field.Box.Text=string.format("%.6g",value)
		local t=math.clamp(ratio(field.Entry,value),0,1)
		field.Fill.Size=UDim2.new(t,0,1,0);field.Knob.Position=UDim2.new(t,-7,.5,-7)
	end
	for index,entry in ipairs(settings)do
		local y=172+(index-1)*108
		makeLabel(entry[2],y)
		local box=Instance.new("TextBox")
		box.Size=UDim2.new(1,0,0,36);box.Position=UDim2.new(0,0,0,y+23)
		box.BackgroundColor3=currentTheme.tertiary;box.TextColor3=currentTheme.text
		box.Font=Enum.Font.GothamMedium;box.TextSize=13;box.ClearTextOnFocus=false;box.ZIndex=8;box.Parent=card
		Instance.new("UICorner",box).CornerRadius=UDim.new(0,10)
		RegisterTheme(box,"BackgroundColor3","tertiary");RegisterTheme(box,"TextColor3","text")
		local hit=Instance.new("TextButton");hit.Text="";hit.AutoButtonColor=false
		hit.Size=UDim2.new(1,0,0,28);hit.Position=UDim2.new(0,0,0,y+65);hit.BackgroundTransparency=1;hit.ZIndex=9;hit.Parent=card
		local track=Instance.new("Frame");track.Size=UDim2.new(1,-16,0,6);track.Position=UDim2.new(0,8,.5,-3)
		track.BackgroundColor3=currentTheme.tertiary;track.BorderSizePixel=0;track.ZIndex=9;track.Parent=hit
		Instance.new("UICorner",track).CornerRadius=UDim.new(1,0);RegisterTheme(track,"BackgroundColor3","tertiary")
		local fill=Instance.new("Frame");fill.BorderSizePixel=0;fill.BackgroundColor3=currentTheme.accent;fill.ZIndex=10;fill.Parent=track
		Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0);RegisterTheme(fill,"BackgroundColor3","accent")
		local knob=Instance.new("Frame");knob.Size=UDim2.fromOffset(14,14);knob.BackgroundColor3=currentTheme.text;knob.ZIndex=11;knob.Parent=track
		Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0);RegisterTheme(knob,"BackgroundColor3","text")
		local field={Entry=entry,Box=box,Track=track,Fill=fill,Knob=knob};fields[#fields+1]=field
		box.FocusLost:Connect(function()
			local value=tonumber((box.Text:gsub(",",".")))
			if not value or not core:SetParameter(entry[1],value)then status.Text="Valor invalido o fuera de rango."end
			paint(field)
		end)
		hit.InputBegan:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
				dragging=field;dragInput=input
				local t=math.clamp((input.Position.X-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
				local value=entry[5]and entry[3]+math.exp(t*math.log(1+entry[4]-entry[3]))-1 or entry[3]+t*(entry[4]-entry[3])
				if core:SetParameter(entry[1],math.clamp(value,entry[3],entry[4]))then paint(field)end
			end
		end)
		paint(field)
	end
	connections[#connections+1]=inputService.InputChanged:Connect(function(input)
		if not dragging or not objectFlingPanel.Visible then return end
		if input~=dragInput and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
		local field=dragging;local entry=field.Entry
		local t=math.clamp((input.Position.X-field.Track.AbsolutePosition.X)/math.max(1,field.Track.AbsoluteSize.X),0,1)
		local value=entry[5]and entry[3]+math.exp(t*math.log(1+entry[4]-entry[3]))-1 or entry[3]+t*(entry[4]-entry[3])
		if core:SetParameter(entry[1],math.clamp(value,entry[3],entry[4]))then paint(field)end
	end)
	connections[#connections+1]=inputService.InputEnded:Connect(function(input)
		if input==dragInput then dragging=nil;dragInput=nil end
	end)
	UpdateObjectFlingPanel=function(message)
		target=core:GetTarget()
		playerButton.Text=target and (target.DisplayName.." (@"..target.Name..")")or L.selectPlayer
		action.Text=core.Running and "Desactivar V8 persistente"or "Activar V8 persistente"
		action.BackgroundColor3=core.Running and currentTheme.critical or currentTheme.tertiary
		status.Text=message or (core:IsAuthorized()and ("Estado: "..core.Phase)or "Disponible solo para owners.")
	end
	playerButton.Activated:Connect(function()
		playerList.Visible=not playerList.Visible
		if not playerList.Visible then return end
		for _,child in ipairs(playerList:GetChildren())do if child:IsA("TextButton")then child:Destroy()end end
		for _,p in ipairs(Players:GetPlayers())do if p~=player then
			makeOption(playerList,p.DisplayName.." (@"..p.Name..")",function()
				if core:SetTarget(p)then target=p end
				playerList.Visible=false;UpdateObjectFlingPanel()
			end)
		end end
	end)
	action.Activated:Connect(function()
		if core.Running then core:Stop();return end
		local ok,err=core:Start(target);UpdateObjectFlingPanel(ok and nil or err)
	end)
	local lastRefresh=0
	connections[#connections+1]=RunService.Heartbeat:Connect(function()
		if objectFlingPanel.Visible and core.Running and os.clock()-lastRefresh>=.15 then lastRefresh=os.clock();UpdateObjectFlingPanel()end
	end)
	_objectFlingUiConn={Disconnect=function()
		dragging=nil;dragInput=nil
		for _,connection in ipairs(connections)do connection:Disconnect()end;table.clear(connections)
	end}
	UpdateObjectFlingPanel()
	return true
end
