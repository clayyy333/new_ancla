-- Interfaz Test 1 dentro de Ancla.
return function(context)
 setfenv(1,context)
 inverseVerticalPanel=Instance.new("ScrollingFrame")
 inverseVerticalPanel.Size=UDim2.new(1,-16,1,-(titleH+20));inverseVerticalPanel.Position=UDim2.new(0,8,0,titleH+8);inverseVerticalPanel.BackgroundTransparency=1;inverseVerticalPanel.BorderSizePixel=0;inverseVerticalPanel.ScrollBarThickness=3;inverseVerticalPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;inverseVerticalPanel.CanvasSize=UDim2.new();inverseVerticalPanel.Visible=false;inverseVerticalPanel.ZIndex=6;inverseVerticalPanel.Parent=content
 local card=Instance.new("Frame");card.Size=UDim2.new(1,-4,0,350);card.BackgroundColor3=currentTheme.secondary;card.ZIndex=7;card.Parent=inverseVerticalPanel;Instance.new("UICorner",card).CornerRadius=UDim.new(0,14);RegisterTheme(card,"BackgroundColor3","secondary")
 local padding=Instance.new("UIPadding",card);padding.PaddingLeft=UDim.new(0,14);padding.PaddingRight=UDim.new(0,14);padding.PaddingTop=UDim.new(0,14)
 local function label(text,y,height)
  local item=Instance.new("TextLabel");item.Size=UDim2.new(1,0,0,height or 20);item.Position=UDim2.new(0,0,0,y);item.BackgroundTransparency=1;item.Text=text;item.TextWrapped=true;item.TextColor3=currentTheme.textDim;item.Font=Enum.Font.GothamMedium;item.TextSize=isMobile and 10 or 12;item.TextXAlignment=Enum.TextXAlignment.Left;item.ZIndex=8;item.Parent=card;RegisterTheme(item,"TextColor3","textDim");return item
 end
 local function styledButton(text,y)
  local item=Instance.new("TextButton");item.Size=UDim2.new(1,0,0,44);item.Position=UDim2.new(0,0,0,y);item.BackgroundColor3=currentTheme.tertiary;item.Text=text;item.TextColor3=currentTheme.text;item.Font=Enum.Font.GothamBold;item.TextSize=isMobile and 11 or 13;item.AutoButtonColor=false;item.ZIndex=9;item.Parent=card;Instance.new("UICorner",item).CornerRadius=UDim.new(0,10);RegisterTheme(item,"BackgroundColor3","tertiary");RegisterTheme(item,"TextColor3","text");return item
 end
 label(isES and"Distancia fisica hacia arriba"or"Physical upward distance",0)
 local distanceInput=Instance.new("TextBox");distanceInput.Size=UDim2.new(1,0,0,44);distanceInput.Position=UDim2.new(0,0,0,24);distanceInput.BackgroundColor3=currentTheme.tertiary;distanceInput.Text="";distanceInput.PlaceholderText=tostring(InverseVerticalController:GetDistance());distanceInput.ClearTextOnFocus=true;distanceInput.TextColor3=currentTheme.text;distanceInput.PlaceholderColor3=currentTheme.textDim;distanceInput.Font=Enum.Font.GothamMedium;distanceInput.TextSize=isMobile and 11 or 13;distanceInput.ZIndex=9;distanceInput.Parent=card;Instance.new("UICorner",distanceInput).CornerRadius=UDim.new(0,10);local inset=Instance.new("UIPadding",distanceInput);inset.PaddingLeft=UDim.new(0,12);inset.PaddingRight=UDim.new(0,12);RegisterTheme(distanceInput,"BackgroundColor3","tertiary");RegisterTheme(distanceInput,"TextColor3","text");RegisterTheme(distanceInput,"PlaceholderColor3","textDim")
 local applyDistance=styledButton(isES and"Aplicar distancia"or"Apply distance",76)
 label(isES and"Altitud visual del cuerpo y del emote"or"Visual body and emote altitude",132)
 local down=styledButton("-1",158);down.Size=UDim2.new(.28,0,0,44)
 local altitudeValue=Instance.new("TextLabel");altitudeValue.Size=UDim2.new(.4,-8,0,44);altitudeValue.Position=UDim2.new(.3,4,0,158);altitudeValue.BackgroundColor3=currentTheme.tertiary;altitudeValue.TextColor3=currentTheme.text;altitudeValue.Font=Enum.Font.GothamBold;altitudeValue.TextSize=isMobile and 11 or 13;altitudeValue.ZIndex=9;altitudeValue.Parent=card;Instance.new("UICorner",altitudeValue).CornerRadius=UDim.new(0,10);RegisterTheme(altitudeValue,"BackgroundColor3","tertiary");RegisterTheme(altitudeValue,"TextColor3","text")
 local up=styledButton("+1",158);up.Size=UDim2.new(.28,0,0,44);up.Position=UDim2.new(.72,0,0,158)
 local toggle=styledButton(isES and"Activar Test 1"or"Activate Test 1",216)
 local status=label("",272,60)
 UpdateInverseVerticalPanel=function(message)
  local active=InverseVerticalController:IsRunning();toggle.Text=active and(isES and"Desactivar Test 1"or"Disable Test 1")or(isES and"Activar Test 1"or"Activate Test 1");toggle.BackgroundColor3=active and currentTheme.accent or currentTheme.tertiary
  if distanceInput.Text==""then distanceInput.PlaceholderText=tostring(InverseVerticalController:GetDistance())end
  local altitude=InverseVerticalController:GetVisualAltitude();altitudeValue.Text=(altitude>0 and"+"or"")..tostring(altitude).." studs"
  status.Text=message or InverseVerticalController.Status
 end
 local function applyDistanceValue()
  local ok,message=InverseVerticalController:SetDistance(distanceInput.Text~=""and distanceInput.Text or InverseVerticalController:GetDistance())
  if ok then distanceInput.Text=tostring(message);UpdateInverseVerticalPanel(isES and"Distancia actualizada."or"Distance updated.")else UpdateInverseVerticalPanel(message)end
  return ok
 end
 applyDistance.Activated:Connect(applyDistanceValue)
 down.Activated:Connect(function()local ok,message=InverseVerticalController:SetVisualAltitude(InverseVerticalController:GetVisualAltitude()-1);UpdateInverseVerticalPanel(ok and(isES and"Emote bajado 1 stud."or"Emote lowered 1 stud.")or message)end)
 up.Activated:Connect(function()local ok,message=InverseVerticalController:SetVisualAltitude(InverseVerticalController:GetVisualAltitude()+1);UpdateInverseVerticalPanel(ok and(isES and"Emote subido 1 stud."or"Emote raised 1 stud.")or message)end)
 toggle.Activated:Connect(function()
  if InverseVerticalController:IsRunning()then local _,message=InverseVerticalController:Stop(true);UpdateInverseVerticalPanel(message)
  elseif applyDistanceValue()then local _,message=InverseVerticalController:Start(InverseVerticalController:GetDistance(),InverseVerticalController:GetVisualAltitude());UpdateInverseVerticalPanel(message)end
 end)
 distanceInput.FocusLost:Connect(function(enterPressed)if enterPressed then applyDistanceValue()end end)
 UpdateInverseVerticalPanel()
 return true
end