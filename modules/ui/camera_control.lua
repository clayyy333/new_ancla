-- Vista de perspectiva orbital integrada.
return function(context)
	setfenv(1,context)
	cameraControlPanel=Instance.new("ScrollingFrame");cameraControlPanel.BorderSizePixel=0;cameraControlPanel.ScrollBarThickness=3;cameraControlPanel.ScrollingDirection=Enum.ScrollingDirection.Y;cameraControlPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;cameraControlPanel.CanvasSize=UDim2.new();cameraControlPanel.Active=true; cameraControlPanel.Size=UDim2.new(1,-16,1,-(titleH+20)); cameraControlPanel.Position=UDim2.new(0,8,0,titleH+8); cameraControlPanel.BackgroundTransparency=1; cameraControlPanel.Visible=false; cameraControlPanel.ZIndex=6; cameraControlPanel.Parent=content
	local card=Instance.new("Frame"); card.Size=UDim2.new(1,0,0,isMobile and 250 or 270); card.BackgroundColor3=currentTheme.secondary; card.ZIndex=7; card.Parent=cameraControlPanel; Instance.new("UICorner",card).CornerRadius=UDim.new(0,14); RegisterTheme(card,"BackgroundColor3","secondary")
	local pad=Instance.new("UIPadding",card); pad.PaddingLeft=UDim.new(0,14); pad.PaddingRight=UDim.new(0,14); pad.PaddingTop=UDim.new(0,14)
	local label=Instance.new("TextLabel"); label.Size=UDim2.new(1,0,0,20); label.BackgroundTransparency=1; label.Text=isES and "Jugador observado" or "Observed player"; label.TextColor3=currentTheme.textDim; label.Font=Enum.Font.GothamMedium; label.TextSize=13; label.TextXAlignment=Enum.TextXAlignment.Left; label.ZIndex=8; label.Parent=card; RegisterTheme(label,"TextColor3","textDim")
	local target=Instance.new("TextButton"); target.Size=UDim2.new(1,0,0,40); target.Position=UDim2.new(0,0,0,26); target.BackgroundColor3=currentTheme.tertiary; target.TextColor3=currentTheme.text; target.Font=Enum.Font.GothamMedium; target.TextSize=13; target.TextXAlignment=Enum.TextXAlignment.Left; target.ZIndex=10; target.Parent=card; Instance.new("UICorner",target).CornerRadius=UDim.new(0,10); Instance.new("UIPadding",target).PaddingLeft=UDim.new(0,12); RegisterTheme(target,"BackgroundColor3","tertiary"); RegisterTheme(target,"TextColor3","text")
	local list=Instance.new("ScrollingFrame"); list.Size=UDim2.new(1,0,0,120); list.Position=UDim2.new(0,0,0,70); list.BackgroundColor3=currentTheme.tertiary; list.ScrollBarThickness=4; list.AutomaticCanvasSize=Enum.AutomaticSize.Y; list.CanvasSize=UDim2.new(); list.Visible=false; list.ZIndex=30; list.Parent=card; Instance.new("UICorner",list).CornerRadius=UDim.new(0,10); RegisterTheme(list,"BackgroundColor3","tertiary"); Instance.new("UIListLayout",list).Padding=UDim.new(0,3)
	local function action(text,y,w,x)
		local b=Instance.new("TextButton"); b.Size=UDim2.new(w or 1,0,0,42); b.Position=UDim2.new(x or 0,0,0,y); b.BackgroundColor3=currentTheme.tertiary; b.Text=text; b.TextColor3=currentTheme.text; b.Font=Enum.Font.GothamBold; b.TextSize=13; b.ZIndex=8; b.Parent=card; Instance.new("UICorner",b).CornerRadius=UDim.new(0,10); RegisterTheme(b,"BackgroundColor3","tertiary"); RegisterTheme(b,"TextColor3","text"); return b
	end
	local toggle=action(isES and "Activar perspectiva orbital" or "Enable orbital view",82)
	local minus=action("-",134,0.22,0); local zoom=action("",134,0.52,0.24); local plus=action("+",134,0.22,0.78)
	local hint=Instance.new("TextLabel"); hint.Size=UDim2.new(1,0,0,48); hint.Position=UDim2.new(0,0,0,184); hint.BackgroundTransparency=1; hint.Text=isMobile and (isES and "Arrastra la pantalla para rotar." or "Drag the screen to rotate.") or (isES and "Clic derecho + mover para rotar. Rueda para zoom." or "Right-click + move to rotate. Wheel to zoom."); hint.TextWrapped=true; hint.TextColor3=currentTheme.textDim; hint.Font=Enum.Font.GothamMedium; hint.TextSize=11; hint.ZIndex=8; hint.Parent=card; RegisterTheme(hint,"TextColor3","textDim")
	UpdateCameraControlPanel=function(message)
		local p=SpectatorController:GetTarget(); target.Text=p and (p.DisplayName.."  (@"..p.Name..")") or (isES and "Seleccionar jugador" or "Select player")
		toggle.Text=SpectatorController:IsActive() and (isES and "Desactivar perspectiva orbital" or "Disable orbital view") or (isES and "Activar perspectiva orbital" or "Enable orbital view")
		toggle.BackgroundColor3=SpectatorController:IsActive() and currentTheme.critical or currentTheme.tertiary
		zoom.Text=(isES and "Zoom: " or "Zoom: ")..tostring(math.floor(SpectatorController:GetZoom()))
		if message then hint.Text=message end
	end
	target.MouseButton1Click:Connect(function()
		list.Visible=not list.Visible
		if list.Visible then
			for _,c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
			for _,p in ipairs(SpectatorController:GetTargetOptions()) do local b=action("",0); b.Parent=list; b.Size=UDim2.new(1,-4,0,34); b.Position=UDim2.new(); b.Text=p.DisplayName.."  (@"..p.Name..")"; b.ZIndex=31; b.MouseButton1Click:Connect(function() SpectatorController:SetTarget(p); list.Visible=false; UpdateCameraControlPanel() end) end
		end
	end)
	toggle.MouseButton1Click:Connect(function() local ok,err; if SpectatorController:IsActive() then SpectatorController:Stop(); ok=true else ok,err=SpectatorController:Start() end; UpdateCameraControlPanel(ok and nil or err) end)
	minus.MouseButton1Click:Connect(function() SpectatorController:ZoomIn(); UpdateCameraControlPanel() end); plus.MouseButton1Click:Connect(function() SpectatorController:ZoomOut(); UpdateCameraControlPanel() end)
	UpdateCameraControlPanel(); return true
end