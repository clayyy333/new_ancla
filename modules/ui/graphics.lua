-- Panel de Graficos: FPS Booster local, sin backend.
return function(context)
	setfenv(1,context)

	graphicsPanel=Instance.new("ScrollingFrame")
	graphicsPanel.Name="GraphicsPanel"
	graphicsPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
	graphicsPanel.Position=UDim2.new(0,8,0,titleH+8)
	graphicsPanel.BackgroundTransparency=1
	graphicsPanel.BorderSizePixel=0
	graphicsPanel.ScrollBarThickness=3
	graphicsPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y
	graphicsPanel.CanvasSize=UDim2.new()
	graphicsPanel.Visible=false
	graphicsPanel.ZIndex=6
	graphicsPanel.Parent=content

	local layout=Instance.new("UIListLayout",graphicsPanel)
	layout.Padding=UDim.new(0,8)
	local padding=Instance.new("UIPadding",graphicsPanel)
	padding.PaddingBottom=UDim.new(0,8)

	local card=Instance.new("Frame")
	card.Size=UDim2.new(1,-4,0,isMobile and 300 or 274)
	card.BackgroundColor3=currentTheme.secondary
	card.BorderSizePixel=0
	card.ZIndex=7
	card.Parent=graphicsPanel
	Instance.new("UICorner",card).CornerRadius=UDim.new(0,12)
	RegisterTheme(card,"BackgroundColor3","secondary")

	local heading=Instance.new("TextLabel")
	heading.Size=UDim2.new(1,-24,0,28)
	heading.Position=UDim2.new(0,12,0,10)
	heading.BackgroundTransparency=1
	heading.Text="FPS Booster"
	heading.TextColor3=currentTheme.text
	heading.Font=Enum.Font.GothamBold
	heading.TextSize=isMobile and 14 or 16
	heading.TextXAlignment=Enum.TextXAlignment.Left
	heading.ZIndex=8
	heading.Parent=card
	RegisterTheme(heading,"TextColor3","text")

	local description=Instance.new("TextLabel")
	description.Size=UDim2.new(1,-24,0,34)
	description.Position=UDim2.new(0,12,0,38)
	description.BackgroundTransparency=1
	description.Text=isES and "Optimización visual local. No modifica física, clima ni streaming." or "Local visual optimization. Does not change physics, weather, or streaming."
	description.TextColor3=currentTheme.textDim
	description.Font=Enum.Font.Gotham
	description.TextSize=isMobile and 10 or 11
	description.TextWrapped=true
	description.TextXAlignment=Enum.TextXAlignment.Left
	description.ZIndex=8
	description.Parent=card
	RegisterTheme(description,"TextColor3","textDim")

	local function button(text,x,width,y)
		local item=Instance.new("TextButton")
		item.Size=UDim2.new(width,-6,0,38)
		item.Position=UDim2.new(x,3,0,y)
		item.BackgroundColor3=currentTheme.tertiary
		item.Text=text
		item.TextColor3=currentTheme.text
		item.Font=Enum.Font.GothamBold
		item.TextSize=isMobile and 10 or 12
		item.AutoButtonColor=false
		item.ZIndex=8
		item.Parent=card
		Instance.new("UICorner",item).CornerRadius=UDim.new(0,9)
		RegisterTheme(item,"BackgroundColor3","tertiary")
		RegisterTheme(item,"TextColor3","text")
		return item
	end

	local suave=button("SUAVE",0,1/3,78)
	local fuerte=button("FUERTE",1/3,1/3,78)
	local extremo=button("EXTREMO",2/3,1/3,78)
	local decrease=button("− 100",0,.25,130)
	local distance=button("1000 studs",.25,.5,130)
	local increase=button("+ 100",.75,.25,130)
	distance.Active=false
	distance.AutoButtonColor=false
	local restore=button(isES and "Restaurar gráficos" or "Restore graphics",0,1,182)

	local status=Instance.new("TextLabel")
	status.Size=UDim2.new(1,-24,0,isMobile and 56 or 42)
	status.Position=UDim2.new(0,12,0,230)
	status.BackgroundTransparency=1
	status.TextColor3=currentTheme.textDim
	status.Font=Enum.Font.Gotham
	status.TextSize=isMobile and 10 or 11
	status.TextWrapped=true
	status.TextXAlignment=Enum.TextXAlignment.Left
	status.TextYAlignment=Enum.TextYAlignment.Top
	status.ZIndex=8
	status.Parent=card
	RegisterTheme(status,"TextColor3","textDim")

	local busy=false
	local function stateText(message)
		if not FPSBoosterCore then
			return isES and "El módulo FPS Booster no está disponible." or "FPS Booster module is unavailable."
		end
		local state=FPSBoosterCore:GetState()
		local mode=game.GameId==4540138978 and "Metro Life LOD" or (isES and "LOD universal" or "Universal LOD")
		local base=string.format("%s · %s · %s studs",tostring(state.profile),mode,tostring(state.renderDistance or "—"))
		return message and (message.."\n"..base) or base
	end

	UpdateFPSBoosterPanel=function(message)
		local value=FPSBoosterCore and FPSBoosterCore:GetRenderDistance()
		distance.Text=value and (tostring(value).." studs") or "— studs"
		status.Text=stateText(message)
		local active=not busy
		suave.Active=active
		fuerte.Active=active
		extremo.Active=active
		restore.Active=active
		decrease.Active=active and value~=nil
		increase.Active=active and value~=nil
	end

	local function apply(profile)
		if busy or not FPSBoosterCore then return end
		busy=true
		UpdateFPSBoosterPanel(isES and "Aplicando optimización..." or "Applying optimization...")
		task.spawn(function()
			local ok=FPSBoosterCore:SetProfile(profile)
			busy=false
			UpdateFPSBoosterPanel(ok and (isES and "Perfil aplicado." or "Profile applied.") or (isES and "No se pudo aplicar el perfil." or "Could not apply profile."))
		end)
	end

	suave.Activated:Connect(function() apply("SUAVE") end)
	fuerte.Activated:Connect(function() apply("FUERTE") end)
	extremo.Activated:Connect(function() apply("EXTREMO") end)
	decrease.Activated:Connect(function()
		if not busy and FPSBoosterCore then FPSBoosterCore:DecreaseRenderDistance();UpdateFPSBoosterPanel() end
	end)
	increase.Activated:Connect(function()
		if not busy and FPSBoosterCore then FPSBoosterCore:IncreaseRenderDistance();UpdateFPSBoosterPanel() end
	end)
	restore.Activated:Connect(function()
		if busy or not FPSBoosterCore then return end
		busy=true
		UpdateFPSBoosterPanel(isES and "Restaurando gráficos..." or "Restoring graphics...")
		task.spawn(function()
			local ok=FPSBoosterCore:Restore()
			busy=false
			UpdateFPSBoosterPanel(ok and (isES and "Gráficos restaurados." or "Graphics restored.") or (isES and "No se pudo restaurar." or "Could not restore."))
		end)
	end)

	UpdateFPSBoosterPanel()
	return true
end
