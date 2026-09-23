-- Selector compacto de jugadores mediante clic o toque sobre su personaje.
return function(context)
	setfenv(1,context)
	local PlayerGui=player:WaitForChild("PlayerGui")
	local Workspace=game:GetService("Workspace")
	local selectedPlayer=nil

	local modal=Instance.new("Frame")
	modal.Name="UserShortcutModal"
	modal.AnchorPoint=Vector2.new(.5,.5)
	modal.Position=UDim2.fromScale(.5,.5)
	modal.Size=UDim2.new(0,isMobile and 310 or 360,0,isMobile and 390 or 430)
	modal.BackgroundColor3=currentTheme.primary
	modal.BorderSizePixel=0
	modal.Visible=false
	modal.Active=true
	modal.ZIndex=1200
	modal.Parent=gui
	Instance.new("UICorner",modal).CornerRadius=UDim.new(0,16)
	RegisterTheme(modal,"BackgroundColor3","primary")
	local stroke=Instance.new("UIStroke",modal)
	stroke.Thickness=2
	stroke.Color=currentTheme.accent
	RegisterTheme(stroke,"Color","accent")
	local strokeGradient=Instance.new("UIGradient",stroke)
	strokeGradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,currentTheme.stroke),ColorSequenceKeypoint.new(.5,currentTheme.accent),ColorSequenceKeypoint.new(1,currentTheme.stroke)})
	task.spawn(function()
		local rotation=0
		while modal.Parent do
			rotation+=360
			TweenService:Create(strokeGradient,TweenInfo.new(8,Enum.EasingStyle.Linear),{Rotation=rotation}):Play()
			task.wait(8)
		end
	end)

	local title=Instance.new("TextLabel")
	title.Size=UDim2.new(1,-56,0,28);title.Position=UDim2.new(0,18,0,14);title.BackgroundTransparency=1
	title.Text=isES and "Atajo de usuario" or "User shortcut";title.TextColor3=currentTheme.text;title.Font=Enum.Font.GothamBold;title.TextSize=isMobile and 16 or 18;title.TextXAlignment=Enum.TextXAlignment.Left;title.ZIndex=1201;title.Parent=modal
	RegisterTheme(title,"TextColor3","text")
	local close=Instance.new("TextButton")
	close.Size=UDim2.fromOffset(34,34);close.Position=UDim2.new(1,-44,0,10);close.BackgroundColor3=currentTheme.critical;close.Text="×";close.TextColor3=Color3.new(1,1,1);close.Font=Enum.Font.GothamBold;close.TextSize=22;close.AutoButtonColor=false;close.ZIndex=1202;close.Parent=modal
	Instance.new("UICorner",close).CornerRadius=UDim.new(0,10);RegisterTheme(close,"BackgroundColor3","critical")
	local identity=Instance.new("TextLabel")
	identity.Size=UDim2.new(1,-36,0,48);identity.Position=UDim2.new(0,18,0,52);identity.BackgroundColor3=currentTheme.secondary;identity.TextColor3=currentTheme.text;identity.Font=Enum.Font.GothamMedium;identity.TextSize=isMobile and 12 or 14;identity.TextWrapped=true;identity.ZIndex=1201;identity.Parent=modal
	Instance.new("UICorner",identity).CornerRadius=UDim.new(0,10);RegisterTheme(identity,"BackgroundColor3","secondary");RegisterTheme(identity,"TextColor3","text")
	local hint=Instance.new("TextLabel")
	hint.Size=UDim2.new(1,-36,0,20);hint.Position=UDim2.new(0,18,0,108);hint.BackgroundTransparency=1;hint.Text=isES and "Usar como objetivo en:" or "Use as target in:";hint.TextColor3=currentTheme.textDim;hint.Font=Enum.Font.GothamMedium;hint.TextSize=11;hint.TextXAlignment=Enum.TextXAlignment.Left;hint.ZIndex=1201;hint.Parent=modal;RegisterTheme(hint,"TextColor3","textDim")
	local list=Instance.new("ScrollingFrame")
	list.Size=UDim2.new(1,-36,1,-146);list.Position=UDim2.new(0,18,0,132);list.BackgroundTransparency=1;list.BorderSizePixel=0;list.ScrollBarThickness=3;list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.CanvasSize=UDim2.new();list.ZIndex=1201;list.Parent=modal
	local layout=Instance.new("UIListLayout",list);layout.Padding=UDim.new(0,6);layout.SortOrder=Enum.SortOrder.LayoutOrder

	local function hide() selectedPlayer=nil;modal.Visible=false end
	close.Activated:Connect(hide)
	local function openDestination(tab,apply)
		local target=selectedPlayer
		if not target or target.Parent~=Players then hide();return end
		local ok=pcall(apply,target)
		if not ok then return end
		hide()
		currentTab=tab
		if OpenMainWindow then OpenMainWindow() else main.Visible=true end
		if UpdateTabData then UpdateTabData() end
	end
	local destinations={
		{isES and "Fling 2" or "Fling 2","fling2",function(p) Fling2Core:SetTarget(p);Fling2EfficientCore:SetTarget(p) end},
		{isES and "Fling con vehículo" or "Vehicle Fling","fling_car",function(p) CarFling:SetPlayer(p);CarFlingXeno:SetPlayer(p) end},
		{isES and "Fling con vehículo 2" or "Vehicle Fling 2","fling_car2",function(p) CarFling2Delta:SetPlayer(p);CarFling2Xeno:SetPlayer(p) end},
		{isES and "Fling con objeto" or "Object Fling","fling_object",function(p) ObjectFling2Delta:SetPlayer(p);ObjectFling2Xeno:SetPlayer(p) end},
		{isES and "Fling con moto Delta" or "Delta Motorcycle Fling","fling_moto",function(p) MotoFlingCore:SetTarget(p) end},
		{isES and "Fling con moto Xeno" or "Xeno Motorcycle Fling","fling_moto_xeno",function(p) MotoFlingXenoCore:SetTarget(p) end},
		{isES and "Ubicación de Parejas" or "Couples Position","couples",function(p) CouplesPositionController:SetTarget(p) end},
		{isES and "Perspectiva Cámara" or "Camera Perspective","camera_control",function(p) SpectatorController:SetTarget(p) end},
		{isES and "Control de auto" or "Car Control","car_control",function(p) CarControlController:SetTarget(p) end},
		{isES and "Teletransporte" or "Teleport","movement_control",function(p) MovementControlController:SetTarget(p) end},
	}
	for index,destination in ipairs(destinations) do
		local button=Instance.new("TextButton")
		button.Name="Destination"..index;button.Size=UDim2.new(1,-4,0,38);button.BackgroundColor3=currentTheme.tertiary;button.Text=destination[1];button.TextColor3=currentTheme.text;button.Font=Enum.Font.GothamBold;button.TextSize=isMobile and 11 or 12;button.AutoButtonColor=false;button.ZIndex=1202;button.LayoutOrder=index;button.Parent=list
		Instance.new("UICorner",button).CornerRadius=UDim.new(0,9);RegisterTheme(button,"BackgroundColor3","tertiary");RegisterTheme(button,"TextColor3","text")
		button.Activated:Connect(function() openDestination(destination[2],destination[3]) end)
	end

	local function playerFromPart(part)
		if not part then return nil end
		for _,candidate in ipairs(Players:GetPlayers()) do
			local character=candidate.Character
			if candidate~=player and character and part:IsDescendantOf(character) then return candidate end
		end
	end
	local function overInterface(position)
		local ok,objects=pcall(function() return PlayerGui:GetGuiObjectsAtPosition(position.X,position.Y) end)
		if not ok then return false end
		for _,object in ipairs(objects) do
			if object.Visible and object:IsA("GuiObject") and object:IsDescendantOf(gui) then return true end
		end
		return false
	end
	local mouse=player:GetMouse()
	local function projectedTarget(position,camera)
		local closest,closestDistance=nil,math.huge
		for _,candidate in ipairs(Players:GetPlayers()) do
			local character=candidate~=player and candidate.Character or nil
			if character then
				for _,part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						local screen,onScreen=camera:WorldToScreenPoint(part.Position)
						if onScreen and screen.Z>0 then
							local distance=(Vector2.new(screen.X,screen.Y)-Vector2.new(position.X,position.Y)).Magnitude
							if distance<closestDistance and distance<=70 then closest,closestDistance=candidate,distance end
						end
					end
				end
			end
		end
		return closest
	end
	local function targetAt(position)
		local direct=mouse and playerFromPart(mouse.Target)
		if direct then return direct end
		local camera=Workspace.CurrentCamera;if not camera then return nil end
		local ray=camera:ScreenPointToRay(position.X,position.Y)
		local direction=ray.Direction.Unit
		local origin=ray.Origin
		local remaining=5000
		local excluded=player.Character and{player.Character}or{}
		for _=1,12 do
			local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances=excluded;params.IgnoreWater=true
			local result=Workspace:Raycast(origin,direction*remaining,params)
			if not result then break end
			local target=playerFromPart(result.Instance)
			if target then return target end
			table.insert(excluded,result.Instance)
			local travelled=(result.Position-origin).Magnitude+.05
			remaining-=travelled;if remaining<=0 then break end
			origin=result.Position+direction*.05
		end
		return projectedTarget(position,camera)
	end
	local function selectAt(position)
		if not UserShortcutController:IsEnabled() or modal.Visible or overInterface(position) then return end
		local target=targetAt(position)
		if not target then return end
		selectedPlayer=target;identity.Text=target.DisplayName.."\n@"..target.Name;modal.Visible=true
	end
	local pressed=nil
	local began=UserInputService.InputBegan:Connect(function(input)
		if not UserShortcutController:IsEnabled() then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then pressed={kind=input.UserInputType,position=input.Position,time=os.clock()} end
	end)
	local ended=UserInputService.InputEnded:Connect(function(input)
		if not pressed or pressed.kind~=input.UserInputType then return end
		local start=pressed;pressed=nil
		if os.clock()-start.time>1 or (input.Position-start.position).Magnitude>18 then return end
		selectAt(input.Position)
	end)
	local touchTap=UserInputService.TouchTap:Connect(function(positions)
		if positions and positions[1] then selectAt(positions[1]) end
	end)
	table.insert(UserShortcutController.Connections,began)
	table.insert(UserShortcutController.Connections,ended)
	table.insert(UserShortcutController.Connections,touchTap)
	UserShortcutController.Modal=modal
	return true
end