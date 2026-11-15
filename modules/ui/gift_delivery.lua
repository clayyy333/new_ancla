-- Panel compacto de regalos dentro de la categoria Control.
return function(context)
	setfenv(1,context)
	local Core=GiftDeliveryCore
	giftDeliveryPanel=Instance.new("ScrollingFrame");giftDeliveryPanel.Name="GiftDeliveryPanel";giftDeliveryPanel.Size=UDim2.new(1,-16,1,-(titleH+20));giftDeliveryPanel.Position=UDim2.new(0,8,0,titleH+8);giftDeliveryPanel.BackgroundTransparency=1;giftDeliveryPanel.BorderSizePixel=0;giftDeliveryPanel.ScrollBarThickness=3;giftDeliveryPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;giftDeliveryPanel.CanvasSize=UDim2.new();giftDeliveryPanel.Visible=false;giftDeliveryPanel.ZIndex=6;giftDeliveryPanel.Parent=content
	local card=Instance.new("Frame");card.Size=UDim2.new(1,0,0,350);card.BackgroundColor3=currentTheme.secondary;card.BorderSizePixel=0;card.ZIndex=7;card.Parent=giftDeliveryPanel;Instance.new("UICorner",card).CornerRadius=UDim.new(0,14);RegisterTheme(card,"BackgroundColor3","secondary")
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
	local status=label("",UDim2.new(0,12,0,216),38);status.TextXAlignment=Enum.TextXAlignment.Center
	local cleanupToggle=button(card,"",UDim2.new(1,-24,0,44),UDim2.new(0,12,0,260),8)
	local cleanupStatus=label("",UDim2.new(0,12,0,314),24);cleanupStatus.TextXAlignment=Enum.TextXAlignment.Center
	local pinShade=Instance.new("Frame");pinShade.Size=UDim2.fromScale(1,1);pinShade.BackgroundColor3=Color3.new(0,0,0);pinShade.BackgroundTransparency=.18;pinShade.BorderSizePixel=0;pinShade.Visible=false;pinShade.ZIndex=60;pinShade.Parent=card;Instance.new("UICorner",pinShade).CornerRadius=UDim.new(0,14)
	local pinBox=Instance.new("Frame");pinBox.Size=UDim2.new(1,-40,0,190);pinBox.AnchorPoint=Vector2.new(.5,.5);pinBox.Position=UDim2.fromScale(.5,.5);pinBox.BackgroundColor3=currentTheme.secondary;pinBox.BorderSizePixel=0;pinBox.ZIndex=61;pinBox.Parent=pinShade;Instance.new("UICorner",pinBox).CornerRadius=UDim.new(0,12);RegisterTheme(pinBox,"BackgroundColor3","secondary")
	local pinTitle=Instance.new("TextLabel");pinTitle.Size=UDim2.new(1,-24,0,42);pinTitle.Position=UDim2.new(0,12,0,10);pinTitle.BackgroundTransparency=1;pinTitle.Text=isES and"Acceso a Regalos"or"Gift Access";pinTitle.TextColor3=currentTheme.text;pinTitle.Font=Enum.Font.GothamBold;pinTitle.TextSize=14;pinTitle.ZIndex=62;pinTitle.Parent=pinBox;RegisterTheme(pinTitle,"TextColor3","text")
	local pinInput=Instance.new("TextBox");pinInput.Size=UDim2.new(1,-24,0,42);pinInput.Position=UDim2.new(0,12,0,58);pinInput.BackgroundColor3=currentTheme.tertiary;pinInput.BorderSizePixel=0;pinInput.PlaceholderText=isES and"Ingresa el PIN"or"Enter PIN";pinInput.Text="";pinInput.TextColor3=currentTheme.text;pinInput.PlaceholderColor3=currentTheme.textDim;pinInput.Font=Enum.Font.GothamMedium;pinInput.TextSize=13;pinInput.ClearTextOnFocus=false;pinInput.ZIndex=62;pinInput.Parent=pinBox;Instance.new("UICorner",pinInput).CornerRadius=UDim.new(0,9);RegisterTheme(pinInput,"BackgroundColor3","tertiary");RegisterTheme(pinInput,"TextColor3","text");RegisterTheme(pinInput,"PlaceholderColor3","textDim")
	local pinSubmit=button(pinBox,isES and"VALIDAR"or"VALIDATE",UDim2.new(.5,-18,0,40),UDim2.new(0,12,0,112),62)
	local pinCancel=button(pinBox,isES and"CANCELAR"or"CANCEL",UDim2.new(.5,-18,0,40),UDim2.new(.5,6,0,112),62)
	local pinMessage=Instance.new("TextLabel");pinMessage.Size=UDim2.new(1,-24,0,24);pinMessage.Position=UDim2.new(0,12,0,158);pinMessage.BackgroundTransparency=1;pinMessage.Text="";pinMessage.TextColor3=currentTheme.textDim;pinMessage.Font=Enum.Font.GothamMedium;pinMessage.TextSize=10;pinMessage.TextWrapped=true;pinMessage.ZIndex=62;pinMessage.Parent=pinBox;RegisterTheme(pinMessage,"TextColor3","textDim")

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
	local function openPin()pinInput.Text="";pinMessage.Text="";pinShade.Visible=true;task.defer(function()pinInput:CaptureFocus()end)end
	local pinBusy=false
	local function submitPin()
		if pinBusy then return end
		local pin=pinInput.Text;if pin==""then pinMessage.Text=isES and"Ingresa el PIN."or"Enter the PIN.";return end
		if not BackendAnchorGuard or not BackendAnchorGuard.UnlockGiftAccess then pinMessage.Text=isES and"Servicio no disponible."or"Service unavailable.";return end
		pinBusy=true;pinSubmit.Text=isES and"VALIDANDO…"or"VALIDATING…"
		BackendAnchorGuard:UnlockGiftAccess(pin,function(ok)
			pinBusy=false;pinInput.Text="";pinSubmit.Text=isES and"VALIDAR"or"VALIDATE"
			if ok then pinShade.Visible=false;local started,err=Core:Start();if not started and err then status.Text=tostring(err)end
			else pinMessage.Text=isES and"PIN incorrecto."or"Incorrect PIN."end
		end)
	end
	pinSubmit.Activated:Connect(submitPin);pinInput.FocusLost:Connect(function(enter)if enter then submitPin()end end);pinCancel.Activated:Connect(function()if not pinBusy then pinInput.Text="";pinShade.Visible=false end end)
	sendToggle.Activated:Connect(function()closeLists();if Core.Running then Core:Stop()else local ok,err=Core:Start();if not ok and err=="pin_required"then openPin()elseif not ok and err then status.Text=err end end end)
	cleanupToggle.Activated:Connect(function()Core:SetAntiEnabled(not Core.AntiEnabled)end)

	UpdateGiftDeliveryPanel=function(message)
		local allowed=Core.Allowed==true
		playerButton.Active=allowed;itemButton.Active=allowed;sendToggle.Active=allowed;cleanupToggle.Active=allowed
		if controlTabBtns and controlTabBtns.gift_delivery then controlTabBtns.gift_delivery.btn.Active=allowed end
		playerButton.Text=(isES and"Usuarios seleccionados: "or"Selected users: ")..Core:GetSelectedCount().."  ▼"
		itemButton.Text=Core.Item.."  ▼"
		sendToggle.Text=Core.Running and(isES and"ENVÍO CONTINUO: ACTIVADO"or"CONTINUOUS DELIVERY: ON")or(isES and"ENVÍO CONTINUO: DESACTIVADO"or"CONTINUOUS DELIVERY: OFF")
		sendToggle.BackgroundColor3=Core.Running and currentTheme.accent or currentTheme.tertiary
		status.Text=not allowed and(isES and"Desactivado por el administrador"or"Disabled by administrator")or message or((isES and"Estado: "or"Status: ")..Core.State.." · "..Core:GetSelectedCount()..(isES and" destinatario(s)"or" recipient(s)"))
		cleanupToggle.Text=(isES and"LIMPIEZA DE REGALOS (NO BLOQUEA): "or"GIFT CLEANUP (NON-BLOCKING): ")..(Core.AntiEnabled and"ON"or"OFF")
		cleanupToggle.BackgroundColor3=Core.AntiEnabled and currentTheme.accent or currentTheme.tertiary
		cleanupStatus.Text=string.format(isES and"Detectados: %d · Limpiados: %d · Fallos: %d"or"Detected: %d · Cleaned: %d · Failures: %d",Core.AntiDetected,Core.AntiRemoved,Core.AntiFailures)
	end
	Core:OnChanged(function()if giftDeliveryPanel.Parent then UpdateGiftDeliveryPanel()end end)
	giftDeliveryPanel.Destroying:Connect(function()if Core and Core.Destroy then Core:Destroy()end end)
	UpdateGiftDeliveryPanel();return true
end
