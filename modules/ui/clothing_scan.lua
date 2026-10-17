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
		code.Text=id and tostring(id) or tr("Código no disponible","Code unavailable"); code.ClearTextOnFocus=false; code.TextEditable=false; code.Font=Enum.Font.Gotham; code.TextSize=13
		code.BackgroundColor3=currentTheme.tertiary; code.TextColor3=currentTheme.text; code.ZIndex=8; code.Parent=r
		RegisterTheme(code,"BackgroundColor3","tertiary"); RegisterTheme(code,"TextColor3","text")
		local b=button(r,isTexture and tr("Copiar textura","Copy texture") or tr("Copiar ID","Copy ID"))
		if not id then b.Text=tr("Sin código","No code");b.AutoButtonColor=false;b.TextTransparency=.5 end
		b.Size=UDim2.new(.35,-8,0,34); b.Position=UDim2.new(.65,0,0,46); b.Activated:Connect(function() if id then copy(id) end end)
		return label,r
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
		local function valid()
			return panel.Parent and token==serial and target.Character==character and character.Parent
		end
		local function kind(item)
			local suffix=item.source=="texture" and tr(" · textura (no catálogo)"," · texture (not catalog)")
				or item.source=="description" and tr(" · descripción, no verificada"," · description, unverified")
				or item.source=="origin" and tr(" · ID de origen"," · source asset ID")
				or tr(" · equipado, código desconocido"," · equipped, unknown ID")
			return item.kind..suffix
		end
		local count=0
		local sourceIds={}
		local function show(item)
			count=count+1
			local label,card=row(item.id,kind(item),item.name,count,item.source=="texture")
			return {item=item,label=label,card=card}
		end
		local ok,items=pcall(function() return ClothingScanReader:Snapshot(character) end)
		local pending={}
		if ok then
			for _,item in ipairs(items) do
				pending[#pending+1]=show(item)
				if item.id and item.source=="origin" then sourceIds[item.id]=true end
			end
		end
		-- Visible instances are rendered before any yielding metadata request.
		busy=false
		status.Text=tr("Objetos equipados: ","Equipped objects: ")..tostring(count)..tr(". Consultando descripción…",". Reading description…")
		task.spawn(function()
			local success,description=pcall(function() return ClothingScanReader:Description(humanoid) end)
			if not valid() then return end
			if success then
				for _,item in ipairs(description) do
					if not sourceIds[item.id] then pending[#pending+1]=show(item);sourceIds[item.id]=true end
				end
			end
			status.Text=count==0 and tr("No se detectaron prendas. El personaje puede estar incompleto.","No clothing detected. The character may be incompletely loaded.")
				or tr("Equipados arriba; descripción como referencia. Una textura no es el ID del catálogo.","Equipped items above; description is a reference. A texture is not a catalog ID.")
			-- At most two metadata calls at once; failures never remove visible items.
			local cursor=0
			local function worker()
				while valid() do
					cursor=cursor+1
					local entry=pending[cursor]
					if not entry then return end
					local item=entry.item
					if item.id and item.source~="texture" then
						local name=cache[item.id]
						if not name then
							local got,info=pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(item.id,Enum.InfoType.Asset) end)
							if got and type(info)=="table" and type(info.Name)=="string" then name=info.Name;cache[item.id]=name end
						end
						if valid() and entry.card.Parent and name then entry.label.Text=kind(item).." — "..name end
					end
				end
			end
			task.spawn(worker);task.spawn(worker)
		end)
	end)
	return true
end
