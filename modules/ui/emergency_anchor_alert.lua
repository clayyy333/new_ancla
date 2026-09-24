-- Aviso compacto cuando el ancla de emergencia interviene.
return function(context)
	setfenv(1,context)
	local modal=Instance.new("Frame")
	modal.Name="EmergencyAnchorAlert"
	modal.AnchorPoint=Vector2.new(.5,.5)
	modal.Position=UDim2.fromScale(.5,.5)
	modal.Size=UDim2.new(0,isMobile and 300 or 360,0,isMobile and 215 or 230)
	modal.BackgroundColor3=currentTheme.primary
	modal.BorderSizePixel=0
	modal.Visible=false
	modal.Active=true
	modal.ZIndex=1300
	modal.Parent=gui
	Instance.new("UICorner",modal).CornerRadius=UDim.new(0,16)
	RegisterTheme(modal,"BackgroundColor3","primary")
	local stroke=Instance.new("UIStroke",modal)
	stroke.Thickness=2;stroke.Color=currentTheme.accent;stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
	RegisterTheme(stroke,"Color","accent")
	local gradient=Instance.new("UIGradient",stroke)
	gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,currentTheme.stroke),ColorSequenceKeypoint.new(.5,currentTheme.accent),ColorSequenceKeypoint.new(1,currentTheme.stroke)})
	task.spawn(function()
		local rotation=0
		while modal.Parent do rotation+=360;TweenService:Create(gradient,TweenInfo.new(8,Enum.EasingStyle.Linear),{Rotation=rotation}):Play();task.wait(8)end
	end)
	local title=Instance.new("TextLabel")
	title.Size=UDim2.new(1,-32,0,32);title.Position=UDim2.new(0,16,0,16);title.BackgroundTransparency=1;title.Text=isES and"Ancla de Emergencia"or"Emergency Anchor";title.TextColor3=currentTheme.text;title.Font=Enum.Font.GothamBold;title.TextSize=isMobile and 16 or 18;title.TextXAlignment=Enum.TextXAlignment.Left;title.ZIndex=1301;title.Parent=modal;RegisterTheme(title,"TextColor3","text")
	local message=Instance.new("TextLabel")
	message.Size=UDim2.new(1,-32,0,55);message.Position=UDim2.new(0,16,0,54);message.BackgroundTransparency=1;message.Text=isES and"Notamos un movimiento extraño. Te anclaste."or"We noticed unusual movement. You were anchored.";message.TextColor3=currentTheme.textDim;message.Font=Enum.Font.GothamMedium;message.TextSize=isMobile and 12 or 14;message.TextWrapped=true;message.TextXAlignment=Enum.TextXAlignment.Left;message.TextYAlignment=Enum.TextYAlignment.Top;message.ZIndex=1301;message.Parent=modal;RegisterTheme(message,"TextColor3","textDim")
	local function button(text,x,colorKey)
		local item=Instance.new("TextButton");item.Size=UDim2.new(.5,-20,0,46);item.Position=UDim2.new(x, x==0 and 16 or 4,1,-62);item.BackgroundColor3=currentTheme[colorKey];item.Text=text;item.TextColor3=Color3.new(1,1,1);item.Font=Enum.Font.GothamBold;item.TextSize=isMobile and 11 or 13;item.AutoButtonColor=false;item.ZIndex=1301;item.Parent=modal;Instance.new("UICorner",item).CornerRadius=UDim.new(0,10);RegisterTheme(item,"BackgroundColor3",colorKey);return item
	end
	local cancel=button(isES and"Cancelar ancla"or"Cancel anchor",0,"critical")
	local keep=button(isES and"Seguir anclado"or"Stay anchored",.5,"accent")
	HideEmergencyAnchorAlert=function()modal.Visible=false end
	ShowEmergencyAnchorAlert=function()modal.Visible=true end
	keep.Activated:Connect(HideEmergencyAnchorAlert)
	cancel.Activated:Connect(function()
		if AnchorCore then
			AnchorCore:SetHeartbeat(false)
			AnchorCore:SetAntiSeat(false)
			AnchorCore:SetAncla(false)
		end
		if UpdateAnchorPanel then UpdateAnchorPanel(isES and"Ancla de emergencia cancelada."or"Emergency anchor cancelled.")end
		HideEmergencyAnchorAlert()
	end)
	return true
end