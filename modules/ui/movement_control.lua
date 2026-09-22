-- Vista de velocidad, salto y teletransporte.
return function(context)
	setfenv(1,context)

	movementControlPanel=Instance.new("ScrollingFrame")
	movementControlPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
	movementControlPanel.Position=UDim2.new(0,8,0,titleH+8)
	movementControlPanel.BackgroundTransparency=1
	movementControlPanel.BorderSizePixel=0
	movementControlPanel.ScrollBarThickness=3
	movementControlPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y
	movementControlPanel.CanvasSize=UDim2.new()
	movementControlPanel.Visible=false
	movementControlPanel.ZIndex=6
	movementControlPanel.Parent=content

	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,-4,0,isMobile and 430 or 400)
	card.BackgroundColor3=currentTheme.secondary
	card.ZIndex=7
	card.Parent=movementControlPanel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
	RegisterTheme(card,"BackgroundColor3","secondary")
	local pad=Instance.new("UIPadding",card)
	pad.PaddingLeft=UDim.new(0,14);pad.PaddingRight=UDim.new(0,14);pad.PaddingTop=UDim.new(0,14);pad.PaddingBottom=UDim.new(0,14)

	local function label(text,y)
		local item=Instance.new("TextLabel")
		item.Size=UDim2.new(1,0,0,20);item.Position=UDim2.new(0,0,0,y)
		item.BackgroundTransparency=1;item.Text=text;item.TextColor3=currentTheme.textDim
		item.Font=Enum.Font.GothamMedium;item.TextSize=isMobile and 11 or 12
		item.TextXAlignment=Enum.TextXAlignment.Left;item.ZIndex=8;item.Parent=card
		RegisterTheme(item,"TextColor3","textDim")
		return item
	end
	local function button(text,size,position)
		local item=Instance.new("TextButton")
		item.Size=size;item.Position=position;item.BackgroundColor3=currentTheme.tertiary
		item.Text=text;item.TextColor3=currentTheme.text;item.Font=Enum.Font.GothamBold
		item.TextSize=isMobile and 10 or 12;item.AutoButtonColor=false;item.ZIndex=9;item.Parent=card
		Instance.new("UICorner",item).CornerRadius=UDim.new(0,10)
		RegisterTheme(item,"BackgroundColor3","tertiary");RegisterTheme(item,"TextColor3","text")
		return item
	end
	local function input(y)
		local box=Instance.new("TextBox")
		box.Size=UDim2.new(0.48,-4,0,42);box.Position=UDim2.new(0,0,0,y)
		box.BackgroundColor3=currentTheme.tertiary;box.TextColor3=currentTheme.text
		box.PlaceholderColor3=currentTheme.textDim;box.ClearTextOnFocus=false
		box.Font=Enum.Font.GothamMedium;box.TextSize=isMobile and 11 or 13
		box.TextXAlignment=Enum.TextXAlignment.Left;box.ZIndex=9;box.Parent=card
		Instance.new("UICorner",box).CornerRadius=UDim.new(0,10)
		local inset=Instance.new("UIPadding",box);inset.PaddingLeft=UDim.new(0,12);inset.PaddingRight=UDim.new(0,12)
		RegisterTheme(box,"BackgroundColor3","tertiary");RegisterTheme(box,"TextColor3","text");RegisterTheme(box,"PlaceholderColor3","textDim")
		return box
	end
	local function normalized(box)
		local value=math.clamp(math.floor(tonumber(box.Text) or 0),0,99999)
		box.Text=tostring(value)
		return value
	end

	label(isES and "Velocidad del personaje (0–99999)" or "Character speed (0–99999)",0)
	local speedInput=input(24);speedInput.PlaceholderText="16"
	local applySpeed=button(isES and "Aplicar" or "Apply",UDim2.new(0.25,-4,0,42),UDim2.new(0.49,0,0,24))
	local restoreSpeed=button(isES and "Restaurar" or "Restore",UDim2.new(0.25,-4,0,42),UDim2.new(0.75,0,0,24))

	label(isES and "Potencia de salto (0–99999)" or "Jump power (0–99999)",80)
	local jumpInput=input(104);jumpInput.PlaceholderText="50"
	local applyJump=button(isES and "Aplicar" or "Apply",UDim2.new(0.25,-4,0,42),UDim2.new(0.49,0,0,104))
	local restoreJump=button(isES and "Restaurar" or "Restore",UDim2.new(0.25,-4,0,42),UDim2.new(0.75,0,0,104))

	label(isES and "Teletransporte a jugador" or "Teleport to player",168)
	local targetButton=button(isES and "Seleccionar jugador" or "Select player",UDim2.new(1,0,0,42),UDim2.new(0,0,0,192))
	targetButton.TextXAlignment=Enum.TextXAlignment.Left
	local targetPad=Instance.new("UIPadding",targetButton);targetPad.PaddingLeft=UDim.new(0,12)

	local targetList=Instance.new("ScrollingFrame")
	targetList.Size=UDim2.new(1,0,0,126);targetList.Position=UDim2.new(0,0,0,238)
	targetList.BackgroundColor3=currentTheme.tertiary;targetList.BorderSizePixel=0
	targetList.ScrollBarThickness=3;targetList.AutomaticCanvasSize=Enum.AutomaticSize.Y
	targetList.CanvasSize=UDim2.new();targetList.Visible=false;targetList.ZIndex=30;targetList.Parent=card
	Instance.new("UICorner",targetList).CornerRadius=UDim.new(0,10)
	RegisterTheme(targetList,"BackgroundColor3","tertiary")
	local targetLayout=Instance.new("UIListLayout",targetList);targetLayout.Padding=UDim.new(0,3)

	local teleportButton=button(isES and "Teletransportar" or "Teleport",UDim2.new(1,0,0,44),UDim2.new(0,0,0,244))
	local status=label("",300);status.Size=UDim2.new(1,0,0,50);status.TextWrapped=true

	local function statusText(text,success)
		status.Text=text or ""
		status.TextColor3=success and currentTheme.success or currentTheme.textDim
	end
	local function refreshTargetList()
		for _,child in ipairs(targetList:GetChildren()) do if child~=targetLayout then child:Destroy() end end
		for _,candidate in ipairs(Players:GetPlayers()) do
			if candidate~=player then
				local option=Instance.new("TextButton")
				option.Size=UDim2.new(1,-4,0,36);option.BackgroundColor3=currentTheme.secondary
				option.Text=candidate.DisplayName.."  (@"..candidate.Name..")";option.TextColor3=currentTheme.text
				option.Font=Enum.Font.GothamMedium;option.TextSize=isMobile and 10 or 12
				option.ZIndex=31;option.Parent=targetList
				Instance.new("UICorner",option).CornerRadius=UDim.new(0,8)
				RegisterTheme(option,"BackgroundColor3","secondary");RegisterTheme(option,"TextColor3","text")
				option.Activated:Connect(function()
					MovementControlController:SetTarget(candidate)
					targetButton.Text=option.Text
					targetList.Visible=false
				end)
			end
		end
	end

	UpdateMovementControlPanel=function(message)
		local defaults=MovementControlController:GetDefaults()
		if defaults then
			if speedInput.Text=="" then speedInput.PlaceholderText=tostring(defaults.WalkSpeed) end
			if jumpInput.Text=="" then jumpInput.PlaceholderText=tostring(defaults.UseJumpPower and defaults.JumpPower or defaults.JumpHeight) end
		end
		local target=MovementControlController.Target
		targetButton.Text=target and (target.DisplayName.."  (@"..target.Name..")") or (isES and "Seleccionar jugador" or "Select player")
		if message then statusText(message,true) end
	end

	applySpeed.Activated:Connect(function()
		local ok,result=MovementControlController:SetWalkSpeed(normalized(speedInput))
		statusText(ok and ((isES and "Velocidad aplicada: " or "Speed applied: ")..tostring(result)) or result,ok)
	end)
	restoreSpeed.Activated:Connect(function()
		local ok,result=MovementControlController:RestoreWalkSpeed()
		if ok then speedInput.Text=tostring(result) end
		statusText(ok and (isES and "Velocidad restaurada" or "Speed restored") or result,ok)
	end)
	applyJump.Activated:Connect(function()
		local ok,result=MovementControlController:SetJump(normalized(jumpInput))
		statusText(ok and ((isES and "Salto aplicado: " or "Jump applied: ")..tostring(result)) or result,ok)
	end)
	restoreJump.Activated:Connect(function()
		local ok,result=MovementControlController:RestoreJump()
		if ok then jumpInput.Text=tostring(result) end
		statusText(ok and (isES and "Salto restaurado" or "Jump restored") or result,ok)
	end)
	targetButton.Activated:Connect(function()
		refreshTargetList();targetList.Visible=not targetList.Visible
	end)
	teleportButton.Activated:Connect(function()
		local ok,message=MovementControlController:Teleport();statusText(message,ok)
	end)
	Players.PlayerRemoving:Connect(function(leaving)
		if MovementControlController.Target==leaving then
			MovementControlController:SetTarget(nil);UpdateMovementControlPanel()
		end
	end)

	UpdateMovementControlPanel()
	return true
end