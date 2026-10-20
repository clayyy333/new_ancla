-- One opt-in preference shared by the three anchor panels.
return function(context)
 setfenv(1,context)
 local Controls={Buttons={}}
 function Controls:Refresh()
  for button in pairs(self.Buttons) do
   if button.Parent then
    button.Text=(isES and "Limpieza de FoldingTable" or "FoldingTable cleanup")..(FoldingCleanupCore.Enabled and " · ON" or " · OFF")
    button.BackgroundColor3=FoldingCleanupCore.Enabled and currentTheme.accent or currentTheme.tertiary
   else self.Buttons[button]=nil end
  end
 end
 function Controls:Create(parent,position,size)
  if not FoldingCleanupCore:IsAvailable() then return nil end
  local button=Instance.new("TextButton")
  button.Name="FoldingTableCleanupToggle";button.Position=position;button.Size=size
  button.TextColor3=currentTheme.text;button.Font=Enum.Font.GothamBold;button.TextSize=isMobile and 9 or 11
  button.TextWrapped=true;button.AutoButtonColor=false;button.BorderSizePixel=0;button.ZIndex=8;button.Parent=parent
  Instance.new("UICorner",button).CornerRadius=UDim.new(0,9)
  RegisterTheme(button,"TextColor3","text")
  RegisterTheme(button,"BackgroundColor3","tertiary")
  self.Buttons[button]=true
  button.Activated:Connect(function()FoldingCleanupCore:SetEnabled(not FoldingCleanupCore.Enabled)end)
  self:Refresh();return button
 end
 FoldingCleanupControls=Controls
 return true
end
