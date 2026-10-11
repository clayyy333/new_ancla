-- On-demand inspection only. Never fetches the player's profile outfit.
return function(context)
	setfenv(1, context)
	local function tr(es,en) return isES and es or en end
	clothingScanPanel=Instance.new("ScrollingFrame")
	local panel=clothingScanPanel
	panel.Name="ClothingScanPanel"
	panel.Size=UDim2.new(1,-16,1,-(titleH+20))
	panel.Position=UDim2.new(0,8,0,titleH+8)
	panel.BackgroundTransparency=1; panel.BorderSizePixel=0
	panel.ScrollBarThickness=3; panel.AutomaticCanvasSize=Enum.AutomaticSize.Y
	panel.CanvasSize=UDim2.new(); panel.Visible=false; panel.ZIndex=6; panel.Parent=content
	local layout=Instance.new("UIListLayout",panel); layout.Padding=UDim.new(0,8); layout.SortOrder=Enum.SortOrder.LayoutOrder
	local function button(parent,text)
		local b=Instance.new("TextButton"); b.Text=text; b.Font=Enum.Font.GothamBold; b.TextSize=12
		b.BackgroundColor3=currentTheme.tertiary; b.TextColor3=currentTheme.text; b.BorderSizePixel=0
		b.ZIndex=8; b.Parent=parent; Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
		RegisterTheme(b,"BackgroundColor3","tertiary"); RegisterTheme(b,"TextColor3","text"); return b
	end
	local selectButton=button(panel,tr("Elegir usuario","Choose player")); selectButton.Size=UDim2.new(1,-4,0,40); selectButton.LayoutOrder=1
	local picker=Instance.new("ScrollingFrame"); picker.Size=UDim2.new(1,-4,0,160); picker.BackgroundTransparency=1
	picker.BorderSizePixel=0; picker.ScrollBarThickness=3; picker.AutomaticCanvasSize=Enum.AutomaticSize.Y; picker.CanvasSize=UDim2.new()
	picker.Visible=false; picker.ZIndex=7; picker.LayoutOrder=2; picker.Parent=panel
	local pl=Instance.new("UIListLayout",picker); pl.Padding=UDim.new(0,4)
	local scan=button(panel,tr("Escanear ropa actual","Scan current clothing")); scan.Size=selectButton.Size; scan.LayoutOrder=3
	local status=Instance.new("TextLabel"); status.Size=UDim2.new(1,-8,0,56); status.BackgroundTransparency=1
	status.TextWrapped=true; status.TextSize=11; status.Font=Enum.Font.Gotham; status.TextColor3=currentTheme.textDim
	status.Text=tr("Elige un usuario. Los cambios directos del juego pueden no coincidir con su descripción aplicada.","Choose a player. Direct game changes may differ from their applied description.")
	status.ZIndex=8; status.LayoutOrder=4; status.Parent=panel; RegisterTheme(status,"TextColor3","textDim")
	local selected, busy, serial=nil,false,0
	local cache={}
	local rows={}
	local function copy(value)
		local fn=setclipboard or toclipboard
		if type(fn)=="function" then
			local ok=pcall(fn,tostring(value))
			if ok then status.Text=tr("Código copiado.","Code copied."); return end
		end
		status.Text=tr("Tu ejecutor no permite copiar. Mantén pulsado o selecciona el código del campo.","Your executor cannot copy. Long-press or select the code field.")
	end
	local function row(id,kind,name,order,isTexture)
		local r=Instance.new("Frame"); r.Size=UDim2.new(1,-4,0,86); r.BackgroundColor3=currentTheme.secondary
		r.BorderSizePixel=0; r.ZIndex=7; r.LayoutOrder=order+4; r.Parent=panel; rows[#rows+1]=r
		Instance.new("UICorner",r).CornerRadius=UDim.new(0,10); RegisterTheme(r,"BackgroundColor3","secondary")
		local label=Instance.new("TextLabel"); label.Size=UDim2.new(1,-16,0,38); label.Position=UDim2.new(0,8,0,4)
		label.BackgroundTransparency=1; label.Text=kind.." — "..name; label.TextWrapped=true; label.TextXAlignment=Enum.TextXAlignment.Left
		label.Font=Enum.Font.Gotham; label.TextSize=12; label.TextColor3=currentTheme.text; label.ZIndex=8; label.Parent=r
		RegisterTheme(label,"TextColor3","text")
		local code=Instance.new("TextBox"); code.Size=UDim2.new(.65,-12,0,34); code.Position=UDim2.new(0,8,0,46)
		code.Text=tostring(id); code.ClearTextOnFocus=false; code.TextEditable=false; code.Font=Enum.Font.Gotham; code.TextSize=13
		code.BackgroundColor3=currentTheme.tertiary; code.TextColor3=currentTheme.text; code.ZIndex=8; code.Parent=r
		RegisterTheme(code,"BackgroundColor3","tertiary"); RegisterTheme(code,"TextColor3","text")
		local b=button(r,isTexture and tr("Copiar textura","Copy texture") or tr("Copiar ID","Copy ID"))
		b.Size=UDim2.new(.35,-8,0,34); b.Position=UDim2.new(.65,0,0,46); b.Activated:Connect(function() copy(id) end)
	end
	selectButton.Activated:Connect(function()
		if busy then return end
		picker.Visible=not picker.Visible
		if not picker.Visible then return end
		for _,c in ipairs(picker:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local players=game:GetService("Players"):GetPlayers()
		table.sort(players,function(a,b) return a.Name:lower()<b.Name:lower() end)
		for _,p in ipairs(players) do
			local b=button(picker,p.DisplayName.." (@"..p.Name..")"); b.Size=UDim2.new(1,-4,0,36)
			b.Activated:Connect(function() selected=p; selectButton.Text=p.DisplayName.." (@"..p.Name..")"; picker.Visible=false end)
		end
	end)
	scan.Activated:Connect(function()
		if busy then return end
		local target=selected
		local character=target and target.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then status.Text=tr("Elige un usuario con personaje cargado.","Choose a player with a loaded character."); return end
		busy=true; serial=serial+1; local token=serial
		picker.Visible=false; status.Text=tr("Escaneando…","Scanning…")
		for _,r in ipairs(rows) do r:Destroy() end; rows={}
		task.spawn(function()
			local ok,err=pcall(function()
				local description=humanoid:GetAppliedDescription()
				local items,seen={},{}
				local function add(id,kind,texture)
					id=tonumber(id); if not id or id<=0 then return end
					local key=(texture and "texture:" or "asset:")..id
					if seen[key] then return end; seen[key]=true
					items[#items+1]={id=id,kind=kind,texture=texture}
				end
				for _,entry in ipairs({{"Shirt","Shirt",tr("Camisa","Shirt"),"ShirtTemplate"},{"Pants","Pants",tr("Pantalón","Pants"),"PantsTemplate"},{"GraphicTShirt","ShirtGraphic",tr("Camiseta","T-shirt"),"Graphic"}}) do
					local actual=character:FindFirstChildOfClass(entry[2])
					if actual then
						if description[entry[1]]>0 then add(description[entry[1]],entry[3]..tr(" (descripción aplicada)"," (applied description)"),false) end
						local texture=tostring(actual[entry[4]]):match("%d+")
						add(texture,entry[3]..tr(" · textura actual (no catálogo)"," · current texture (not catalog)"),true)
					end
				end
				for _,a in ipairs(description:GetAccessories(true)) do add(a.AssetId,tostring(a.AccessoryType):gsub("Enum.AccessoryType%.","")..tr(" (descripción aplicada)"," (applied description)"),false) end
				description:Destroy()
				for i,item in ipairs(items) do
					if not panel.Parent or token~=serial then return end
					local name=tr("Nombre no disponible","Name unavailable")
					if item.texture then name=tr("ID de imagen","Image ID") else
						name=cache[item.id]
						if not name then
							local got,info=pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(item.id,Enum.InfoType.Asset) end)
							name=got and info.Name or tr("Nombre no disponible","Name unavailable")
							if got then cache[item.id]=name end
						end
					end
					if not panel.Parent then return end
					if target.Character~=character or not character.Parent then
						for _,r in ipairs(rows) do r:Destroy() end; rows={}
						status.Text=tr("El personaje cambió durante el escaneo. Vuelve a escanear.","Character changed during the scan. Scan again.")
						return
					end
					row(item.id,item.kind,name,i,item.texture)
				end
				status.Text=#items==0 and tr("No se encontraron prendas identificables.","No identifiable clothing found.") or tr("Escaneo terminado. Catálogo según descripción; texturas según ropa visible. No se consultó el perfil.","Scan complete. Catalog from description; textures from visible clothing. Profile was not queried.")
			end)
			busy=false
			if not ok and panel.Parent then status.Text=tr("No se pudo completar. Vuelve a escanear.","Scan failed. Try scanning again."); warn("[ClothingScan] "..tostring(err)) end
		end)
	end)
	return true
end
