-- Interfaz Test 1 dentro de Ancla.
return function(context)
 setfenv(1,context)
 inverseVerticalPanel=Instance.new("ScrollingFrame")
 inverseVerticalPanel.Size=UDim2.new(1,-16,1,-(titleH+20));inverseVerticalPanel.Position=UDim2.new(0,8,0,titleH+8);inverseVerticalPanel.BackgroundTransparency=1;inverseVerticalPanel.BorderSizePixel=0;inverseVerticalPanel.ScrollBarThickness=3;inverseVerticalPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;inverseVerticalPanel.CanvasSize=UDim2.new();inverseVerticalPanel.Visible=false;inverseVerticalPanel.ZIndex=6;inverseVerticalPanel.Parent=content
 local card=Instance.new("Frame");card.Size=UDim2.new(1,-4,0,410);card.BackgroundColor3=currentTheme.secondary;card.ZIndex=7;card.Parent=inverseVerticalPanel;Instance.new("UICorner",card).CornerRadius=UDim.new(0,14);RegisterTheme(card,"BackgroundColor3","secondary")
 local padding=Instance.new("UIPadding",card);padding.PaddingLeft=UDim.new(0,14);padding.PaddingRight=UDim.new(0,14);padding.PaddingTop=UDim.new(0,14)
 local function label(text,y,height)
  local item=Instance.new("TextLabel");item.Size=UDim2.new(1,0,0,height or 20);item.Position=UDim2.new(0,0,0,y);item.BackgroundTransparency=1;item.Text=text;item.TextWrapped=true;item.TextColor3=currentTheme.textDim;item.Font=Enum.Font.GothamMedium;item.TextSize=isMobile and 10 or 12;item.TextXAlignment=Enum.TextXAlignment.Left;item.ZIndex=8;item.Parent=card;RegisterTheme(item,"TextColor3","textDim");return item
 end
 local function input(y,placeholder)
  local item=Instance.new("TextBox");item.Size=UDim2.new(1,0,0,44);item.Position=UDim2.new(0,0,0,y);item.BackgroundColor3=currentTheme.tertiary;item.Text="";item.PlaceholderText=placeholder;item.ClearTextOnFocus=true;item.TextColor3=currentTheme.text;item.PlaceholderColor3=currentTheme.textDim;item.Font=Enum.Font.GothamMedium;item.TextSize=isMobile and 11 or 13;item.ZIndex=9;item.Parent=card;Instance.new("UICorner",item).CornerRadius=UDim.new(0,10);local inset=Instance.new("UIPadding",item);inset.PaddingLeft=UDim.new(0,12);inset.PaddingRight=UDim.new(0,12);RegisterTheme(item,"BackgroundColor3","tertiary");RegisterTheme(item,"TextColor3","text");RegisterTheme(item,"PlaceholderColor3","textDim");return item
 end
 local function button(text,y)
  local item=Instance.new("TextButton");item.Size=UDim2.new(1,0,0,44);item.Position=UDim2.new(0,0,0,y);item.BackgroundColor3=currentTheme.tertiary;item.Text=text;item.TextColor3=currentTheme.text;item.Font=Enum.Font.GothamBold;item.TextSize=isMobile and 11 or 13;item.AutoButtonColor=false;item.ZIndex=9;item.Parent=card;Instance.new("UICorner",item).CornerRadius=UDim.new(0,10);RegisterTheme(item,"BackgroundColor3","tertiary");RegisterTheme(item,"TextColor3","text");return item
 end
 label(isES and"Distancia fisica hacia abajo"or"Physical downward distance",0)
 local distanceInput=input(24,tostring(InverseVerticalController:GetDistance()))
 local applyDistance=button(isES and"Aplicar distancia"or"Apply distance",72)
 label(isES and"Altitud visual del cuerpo y del emote"or"Visual body and emote altitude",128)
 local altitudeInput=input(152,tostring(InverseVerticalController:GetVisualAltitude()))
 local applyAltitude=button(isES and"Aplicar altitud del emote"or"Apply emote altitude",200)
 local toggle=button(isES and"Activar Test 1"or"Activate Test 1",256)
 local status=label("",314,72)
 UpdateInverseVerticalPanel=function(message)
  local active=InverseVerticalController:IsRunning();toggle.Text=active and(isES and"Desactivar Test 1"or"Disable Test 1")or(isES and"Activar Test 1"or"Activate Test 1");toggle.BackgroundColor3=active and currentTheme.accent or currentTheme.tertiary
  if distanceInput.Text==""then distanceInput.PlaceholderText=tostring(InverseVerticalController:GetDistance())end;if altitudeInput.Text==""then altitudeInput.PlaceholderText=tostring(InverseVerticalController:GetVisualAltitude())end
  status.Text=message or InverseVerticalController.Status
 end
 local function applyValues()
  local ok,message=InverseVerticalController:SetDistance(distanceInput.Text~=""and distanceInput.Text or InverseVerticalController:GetDistance());if not ok then UpdateInverseVerticalPanel(message);return false end
  ok,message=InverseVerticalController:SetVisualAltitude(altitudeInput.Text~=""and altitudeInput.Text or InverseVerticalController:GetVisualAltitude());if not ok then UpdateInverseVerticalPanel(message);return false end
  distanceInput.Text=tostring(InverseVerticalController:GetDistance());altitudeInput.Text=tostring(InverseVerticalController:GetVisualAltitude());return true
 end
 applyDistance.Activated:Connect(function()local ok,message=InverseVerticalController:SetDistance(distanceInput.Text~=""and distanceInput.Text or InverseVerticalController:GetDistance());if ok then distanceInput.Text=tostring(message);UpdateInverseVerticalPanel(isES and"Distancia actualizada."or"Distance updated.")else UpdateInverseVerticalPanel(message)end end)
 applyAltitude.Activated:Connect(function()local ok,message=InverseVerticalController:SetVisualAltitude(altitudeInput.Text~=""and altitudeInput.Text or InverseVerticalController:GetVisualAltitude());if ok then altitudeInput.Text=tostring(message);UpdateInverseVerticalPanel(isES and"Altitud del emote actualizada."or"Emote altitude updated.")else UpdateInverseVerticalPanel(message)end end)
 toggle.Activated:Connect(function()
  if InverseVerticalController:IsRunning()then local _,message=InverseVerticalController:Stop(true);UpdateInverseVerticalPanel(message)
  elseif applyValues()then local _,message=InverseVerticalController:Start(InverseVerticalController:GetDistance(),InverseVerticalController:GetVisualAltitude());UpdateInverseVerticalPanel(message)end
 end)
 distanceInput.FocusLost:Connect(function(enterPressed)if enterPressed and applyValues()then UpdateInverseVerticalPanel(isES and"Distancia actualizada."or"Distance updated.")end end)
 altitudeInput.FocusLost:Connect(function(enterPressed)if enterPressed and applyValues()then UpdateInverseVerticalPanel(isES and"Altitud actualizada."or"Altitude updated.")end end)
 UpdateInverseVerticalPanel()
 return true
end