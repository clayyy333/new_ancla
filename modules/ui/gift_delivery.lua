-- Panel compacto de regalos dentro de la categoria Control.
return function(context)
	setfenv(1,context)
	if game.GameId~=4540138978 or not GiftDeliveryCore or not GiftEffectProtectionCore then return true end
	local Core=GiftDeliveryCore
	local Effects=GiftEffectProtectionCore
	giftDeliveryPanel=Instance.new("ScrollingFrame");giftDeliveryPanel.Name="GiftDeliveryPanel";giftDeliveryPanel.Size=UDim2.new(1,-16,1,-(titleH+20));giftDeliveryPanel.Position=UDim2.new(0,8,0,titleH+8);giftDeliveryPanel.BackgroundTransparency=1;giftDeliveryPanel.BorderSizePixel=0;giftDeliveryPanel.ScrollBarThickness=3;giftDeliveryPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;giftDeliveryPanel.CanvasSize=UDim2.new();giftDeliveryPanel.Visible=false;giftDeliveryPanel.ZIndex=6;giftDeliveryPanel.Parent=content
	local card=Instance.new("Frame");card.Size=UDim2.new(1,0,0,544);card.BackgroundColor3=currentTheme.secondary;card.BorderSizePixel=0;card.ZIndex=7;card.Parent=giftDeliveryPanel;Instance.new("UICorner",card).CornerRadius=UDim.new(0,14);RegisterTheme(card,"BackgroundColor3","secondary")
	local function button(parent,text,size,pos,z)
		local b=Instance.new("TextButton");b.Size=size;b.Position=pos;b.BackgroundColor3=currentTheme.tertiary;b.BorderSizePixel=0;b.Text=text;b.TextColor3=currentTheme.text;b.Font=Enum.Font.GothamBold;b.TextSize=isMobile and 10 or 12;b.TextWrapped=true;b.AutoButtonColor=false;b.ZIndex=z or 8;b.Parent=parent;Instance.new("UICorner",b).CornerRadius=UDim.new(0,9);RegisterTheme(b,"BackgroundColor3","tertiary");RegisterTheme(b,"TextColor3","text");return b
	end
	local function label(text,pos,height)
		local l=Instance.new("TextLabel");l.Size=UDim2.new(1,-24,0,height or 18);l.Position=pos;l.BackgroundTransparency=1;l.Text=text;l.TextColor3=currentTheme.textDim;l.Font=Enum.Font.GothamMedium;l.TextSize=isMobile and 10 or 12;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextWrapped=true;l.ZIndex=8;l.Parent=card;RegisterTheme(l,"TextColor3","textDim");return l
	end
	label(isES and"Destinatarios"or"Recipients",UDim2.new(0,12,0,10))
	local playerButton=button(card,"",UDim2.new(1,-24,0,42),UDim2.new(0,12,0,32),10)
	label(isES and"Objeto"or"Item",UDim2.new(0,12,0,84))
	local itemButton=button(card,"",UDim2.new(1,-24,0,42),UDim2.new(0,12,0,106),10)
	local sendToggle=button(card,"",UDim2.new(1,-24,0,44),UDim2.new(0,12,0,162),8)
	local giftEffectsToggle=button(card,"",UDim2.new(.5,-16,0,44),UDim2.new(0,12,0,216),8)
	local whistleAnimationToggle=button(card,"",UDim2.new(.5,-16,0,44),UDim2.new(.5,4,0,216),8)
	local whistleSoundToggle=button(card,"",UDim2.new(.64,-14,0,44),UDim2.new(0,12,0,268),8)
	local whistleScopeToggle=button(card,"",UDim2.new(.36,-14,0,44),UDim2.new(.64,2,0,268),8)
	local status=label("",UDim2.new(0,12,0,320),38);status.TextXAlignment=Enum.TextXAlignment.Center
	local cleanupToggle=button(card,"",UDim2.new(1,-24,0,44),UDim2.new(0,12,0,364),8)
	local cleanupStatus=label("",UDim2.new(0,12,0,418),24);cleanupStatus.TextXAlignment=Enum.TextXAlignment.Center
	local blockReception=button(card,isES and"Bloquear Regalos ( Solo  desactiva envios de este mismo script )"or"Block Gifts ( Only blocks gifts sent by this script )",UDim2.new(1,-24,0,54),UDim2.new(0,12,0,454),8)
	local receptionStatus=label("",UDim2.new(0,12,0,514),22);receptionStatus.TextXAlignment=Enum.TextXAlignment.Center

	local function dropdown(y,height)
		local list=Instance.new("ScrollingFrame");list.Size=UDim2.new(1,-24,0,height);list.Position=UDim2.new(0,12,0,y);list.BackgroundColor3=currentTheme.tertiary;list.BorderSizePixel=0;list.ScrollBarThickness=3;list.AutomaticCanvasSize=Enum.AutomaticSize.Y;list.CanvasSize=UDim2.new();list.Visible=false;list.ZIndex=40;list.Parent=card;Instance.new("UICorner",list).CornerRadius=UDim.new(0,10);RegisterTheme(list,"BackgroundColor3","tertiary");local layout=Instance.new("UIListLayout",list);layout.Padding=UDim.new(0,3);return list
	end
	local playerList=dropdown(76,isMobile and 180 or 210)
	local itemList=dropdown(150,isMobile and 180 or 210)
	local function clearList(list)for _,child in ipairs(list:GetChildren())do if child:IsA("TextButton")then child:Destroy()end end end
	local function option(list,text,callback,selected)
		local b=button(list,text,UDim2.new(1,-4,0,36),UDim2.new(),41);b.LayoutOrder=#list:GetChildren();b.TextXAlignment=Enum.TextXAlignment.Left;local pad=Instance.new("UIPadding",b);pad.PaddingLeft=UDim.new(0,12);if selected then b.BackgroundColor3=currentTheme.accent end;b.Activated:Connect(callback);return b
	end
	local function closeLists(except)if except~=playerList then playerList.Visible=false end;if except~=itemList then itemList.Visible=false end end
	local function rebuildPlayers()
		clearList(playerList)
		option(playerList,(Core.AutoSelect and"[x] "or"[ ] ")..(isES and"Seleccionar todos + nuevos"or"Select all + newcomers"),function()Core:SetSelectAll(not Core.AutoSelect);rebuildPlayers()end,Core.AutoSelect)
		for _,candidate in ipairs(Core:GetPlayers())do
			local selected=Core:IsSelected(candidate.UserId)
			option(playerList,(selected and"[x] "or"[ ] ")..candidate.DisplayName.."  (@"..candidate.Name..")",function()Core:TogglePlayer(candidate);rebuildPlayers()end,selected)
		end
	end
	local function rebuildItems()
		clearList(itemList)
		for _,name in ipairs(Core.Items)do
			option(itemList,(Core.Item==name and"[x] "or"[ ] ")..name,function()Core:SetItem(name);itemList.Visible=false end,Core.Item==name)
		end
	end
	playerButton.Activated:Connect(function()local opening=not playerList.Visible;closeLists(opening and playerList or nil);playerList.Visible=opening;if opening then rebuildPlayers()end end)
	itemButton.Activated:Connect(function()local opening=not itemList.Visible;closeLists(opening and itemList or nil);itemList.Visible=opening;if opening then rebuildItems()end end)
	sendToggle.Activated:Connect(function()closeLists();if Core.Running then Core:Stop()else local ok,err=Core:Start();if not ok and err then status.Text=err end end end)
	giftEffectsToggle.Activated:Connect(function()Effects:SetGiftEffectsEnabled(not Effects.GiftEffectsEnabled)end)
	whistleAnimationToggle.Activated:Connect(function()Effects:SetWhistleAnimationEnabled(not Effects.WhistleAnimationEnabled)end)
	whistleSoundToggle.Activated:Connect(function()Effects:SetWhistleSoundEnabled(not Effects.WhistleSoundEnabled)end)
	whistleScopeToggle.Activated:Connect(function()Effects:SetWhistleScope(Effects.WhistleScope=="SELF"and"ALL"or"SELF")end)
	cleanupToggle.Activated:Connect(function()Core:SetAntiEnabled(not Core.AntiEnabled)end)
	blockReception.Activated:Connect(function()closeLists();Core:BlockReception()end)

	UpdateGiftDeliveryPanel=function(message)
		local allowed=Core.Allowed==true
		playerButton.Active=allowed;itemButton.Active=allowed;sendToggle.Active=allowed;cleanupToggle.Active=allowed
		if controlTabBtns and controlTabBtns.gift_delivery then controlTabBtns.gift_delivery.btn.Active=true end
		blockReception.Active=not Core.ReceptionBlocked and not Core.ReceptionBusy
		blockReception.BackgroundColor3=Core.ReceptionBlocked and currentTheme.accent or currentTheme.tertiary
		receptionStatus.Text=Core.ReceptionMessage or(Core.ReceptionBusy and(isES and"Aplicando bloqueo..."or"Applying block...")or(Core.ReceptionBlocked and(isES and"Bloqueado durante esta sesión"or"Blocked for this session")or(isES and"Sin PIN · Solo durante esta sesión"or"No PIN · This session only")))
		playerButton.Text=(isES and"Usuarios seleccionados: "or"Selected users: ")..Core:GetSelectedCount().."  ▼"
		itemButton.Text=Core.Item.."  ▼"
		sendToggle.Text=Core.Running and(isES and"ENVÍO CONTINUO: ACTIVADO"or"CONTINUOUS DELIVERY: ON")or(isES and"ENVÍO CONTINUO: DESACTIVADO"or"CONTINUOUS DELIVERY: OFF")
		sendToggle.BackgroundColor3=Core.Running and currentTheme.accent or currentTheme.tertiary
		giftEffectsToggle.Text=(isES and"CANCELAR SONIDO Y ANIMACIÓN DE REGALOS"or"CANCEL GIFT SOUND AND ANIMATION").." · "..(Effects.GiftEffectsEnabled and"ON"or"OFF")
		giftEffectsToggle.BackgroundColor3=Effects.GiftEffectsEnabled and currentTheme.accent or currentTheme.tertiary
		whistleAnimationToggle.Text=(isES and"ELIMINAR ANIMACIÓN DE SILBATO"or"REMOVE WHISTLE ANIMATION").." · "..(Effects.WhistleAnimationEnabled and"ON"or"OFF")
		whistleAnimationToggle.BackgroundColor3=Effects.WhistleAnimationEnabled and currentTheme.accent or currentTheme.tertiary
		whistleSoundToggle.Text=(isES and"ELIMINAR SONIDO DE SILBATO"or"REMOVE WHISTLE SOUND").." · "..(Effects.WhistleSoundEnabled and"ON"or"OFF")
		whistleSoundToggle.BackgroundColor3=Effects.WhistleSoundEnabled and currentTheme.accent or currentTheme.tertiary
		whistleScopeToggle.Text=Effects.WhistleScope=="ALL"and(isES and"TODOS"or"ALL")or(isES and"PROPIO"or"SELF")
		whistleScopeToggle.BackgroundColor3=Effects.WhistleScope=="ALL"and currentTheme.accent or currentTheme.tertiary
		status.Text=not allowed and(isES and"Desactivado por el administrador"or"Disabled by administrator")or message or((isES and"Estado: "or"Status: ")..Core:GetStateText().." · "..Core:GetSelectedCount()..(isES and" destinatario(s)"or" recipient(s)"))
		cleanupToggle.Text=(isES and"LIMPIEZA DE REGALOS (NO BLOQUEA): "or"GIFT CLEANUP (NON-BLOCKING): ")..(Core.AntiEnabled and"ON"or"OFF")
		cleanupToggle.BackgroundColor3=Core.AntiEnabled and currentTheme.accent or currentTheme.tertiary
		cleanupStatus.Text=string.format(isES and"Detectados: %d · Limpiados: %d · Fallos: %d"or"Detected: %d · Cleaned: %d · Failures: %d",Core.AntiDetected,Core.AntiRemoved,Core.AntiFailures)
	end
	Core:OnChanged(function()if giftDeliveryPanel.Parent then UpdateGiftDeliveryPanel()end end)
	Effects:OnChanged(function()if giftDeliveryPanel.Parent then UpdateGiftDeliveryPanel()end end)
	giftDeliveryPanel.Destroying:Connect(function()if Core and Core.Destroy then Core:Destroy()end end)
	UpdateGiftDeliveryPanel();return true
end
