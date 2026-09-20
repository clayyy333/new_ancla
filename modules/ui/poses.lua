-- Biblioteca editable de poses guardadas de Parejas.
return function(context)
	setfenv(1,context)
	posesPanel=Instance.new("ScrollingFrame");posesPanel.Size=UDim2.new(1,-16,1,-(titleH+20));posesPanel.Position=UDim2.new(0,8,0,titleH+8);posesPanel.BackgroundTransparency=1;posesPanel.BorderSizePixel=0;posesPanel.ScrollBarThickness=3;posesPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;posesPanel.CanvasSize=UDim2.new();posesPanel.Visible=false;posesPanel.Parent=content
	local layout=Instance.new("UIListLayout",posesPanel);layout.Padding=UDim.new(0,8);layout.SortOrder=Enum.SortOrder.LayoutOrder
	local lastMessage=isES and"Selecciona una pose guardada."or"Select a saved pose."
	local function corner(object,radius)Instance.new("UICorner",object).CornerRadius=UDim.new(0,radius or 9)end
	local function themed(object,property,key)RegisterTheme(object,property,key)end
	local function makeButton(parent,text,size,position)
		local button=Instance.new("TextButton");button.Size=size;button.Position=position;button.BackgroundColor3=currentTheme.tertiary;button.Text=text;button.TextColor3=currentTheme.text;button.Font=Enum.Font.GothamBold;button.TextSize=isMobile and 10 or 12;button.AutoButtonColor=false;button.Parent=parent;corner(button);themed(button,"BackgroundColor3","tertiary");themed(button,"TextColor3","text");return button
	end
	UpdatePosesPanel=function(message)
		if message then lastMessage=message end
		for _,child in ipairs(posesPanel:GetChildren())do if child~=layout then child:Destroy()end end
		local header=Instance.new("Frame");header.Size=UDim2.new(1,-4,0,72);header.BackgroundColor3=currentTheme.secondary;header.LayoutOrder=0;header.Parent=posesPanel;corner(header,12);themed(header,"BackgroundColor3","secondary")
		local status=Instance.new("TextLabel");status.Size=UDim2.new(1,-132,1,-12);status.Position=UDim2.new(0,12,0,6);status.BackgroundTransparency=1;status.Text=lastMessage;status.TextWrapped=true;status.TextXAlignment=Enum.TextXAlignment.Left;status.TextColor3=currentTheme.textDim;status.Font=Enum.Font.GothamMedium;status.TextSize=isMobile and 10 or 12;status.Parent=header;themed(status,"TextColor3","textDim")
		local stop=makeButton(header,isES and"Detener pose"or"Stop pose",UDim2.new(0,112,0,38),UDim2.new(1,-122,.5,-19));stop.BackgroundColor3=currentTheme.critical;themed(stop,"BackgroundColor3","critical");stop.MouseButton1Click:Connect(function()local _,msg=CoupleMovementController:StopSavedPose();UpdatePosesPanel(msg)end)
		local poses=Settings.couplePoses or{}
		if #poses==0 then local empty=Instance.new("TextLabel");empty.Size=UDim2.new(1,-4,0,64);empty.BackgroundColor3=currentTheme.secondary;empty.Text=isES and"Aún no hay poses guardadas."or"No saved poses yet.";empty.TextColor3=currentTheme.textDim;empty.Font=Enum.Font.GothamMedium;empty.TextSize=12;empty.LayoutOrder=1;empty.Parent=posesPanel;corner(empty,10);themed(empty,"BackgroundColor3","secondary");themed(empty,"TextColor3","textDim");return end
		for index,pose in ipairs(poses)do
			local card=Instance.new("Frame");card.Size=UDim2.new(1,-4,0,148);card.BackgroundColor3=currentTheme.secondary;card.LayoutOrder=index;card.Parent=posesPanel;corner(card,12);themed(card,"BackgroundColor3","secondary")
			local name=Instance.new("TextBox");name.Size=UDim2.new(1,-132,0,38);name.Position=UDim2.new(0,10,0,10);name.BackgroundColor3=currentTheme.tertiary;name.Text=tostring(pose.name or("Pose "..index));name.PlaceholderText=isES and"Nombre de la pose"or"Pose name";name.ClearTextOnFocus=false;name.TextColor3=currentTheme.text;name.Font=Enum.Font.GothamBold;name.TextSize=isMobile and 10 or 12;name.Parent=card;corner(name);themed(name,"BackgroundColor3","tertiary");themed(name,"TextColor3","text")
			local rename=makeButton(card,isES and"Guardar nombre"or"Save name",UDim2.new(0,112,0,38),UDim2.new(1,-122,0,10))
			local info=Instance.new("TextLabel");info.Size=UDim2.new(1,-20,0,22);info.Position=UDim2.new(0,10,0,50);info.BackgroundTransparency=1;info.Text=string.format("ID %s  ·  %.1f–%.1fs  ·  %.1f studs",tostring(pose.id),tonumber(pose.start)or 0,tonumber(pose.finish)or 0,tonumber(pose.distance)or 0);info.TextColor3=currentTheme.textDim;info.Font=Enum.Font.GothamMedium;info.TextSize=isMobile and 9 or 11;info.TextXAlignment=Enum.TextXAlignment.Left;info.Parent=card;themed(info,"TextColor3","textDim")
			local minus=makeButton(card,"−",UDim2.new(0,42,0,34),UDim2.new(0,10,0,76));local speed=makeButton(card,string.format(isES and"Velocidad: %.1fx"or"Speed: %.1fx",tonumber(pose.speed)or 1),UDim2.new(1,-124,0,34),UDim2.new(0,56,0,76));local plus=makeButton(card,"+",UDim2.new(0,42,0,34),UDim2.new(1,-52,0,76))
			local use=makeButton(card,isES and"Usar pose"or"Use pose",UDim2.new(.68,-12,0,30),UDim2.new(0,10,0,114));local delete=makeButton(card,isES and"Eliminar"or"Delete",UDim2.new(.32,-8,0,30),UDim2.new(.68,2,0,114));delete.BackgroundColor3=currentTheme.critical;themed(delete,"BackgroundColor3","critical")
			local function saveName()if CoupleMovementController:RenameSavedPose(index,name.Text)then UpdatePosesPanel(isES and"Nombre actualizado."or"Name updated.")else UpdatePosesPanel(isES and"Escribe un nombre válido."or"Enter a valid name.")end end
			rename.MouseButton1Click:Connect(saveName);name.FocusLost:Connect(function(enter)if enter then saveName()end end)
			minus.MouseButton1Click:Connect(function()CoupleMovementController:SetSavedPoseSpeed(index,(tonumber(pose.speed)or 1)-.1);UpdatePosesPanel()end);plus.MouseButton1Click:Connect(function()CoupleMovementController:SetSavedPoseSpeed(index,(tonumber(pose.speed)or 1)+.1);UpdatePosesPanel()end)
			use.MouseButton1Click:Connect(function()local _,msg=CoupleMovementController:UseSavedPose(index);UpdatePosesPanel(msg)end)
			delete.MouseButton1Click:Connect(function()CoupleMovementController:DeleteSavedPose(index);UpdatePosesPanel(isES and"Pose eliminada."or"Pose deleted.")end)
		end
	end
	UpdatePosesPanel();return true
end