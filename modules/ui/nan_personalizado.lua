return function(context)
 setfenv(1,context)
 nanPersonalizadoPanel=Instance.new("ScrollingFrame")
 nanPersonalizadoPanel.Name="NanPersonalizadoPanel"
 nanPersonalizadoPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
 nanPersonalizadoPanel.Position=UDim2.new(0,8,0,titleH+8)
 nanPersonalizadoPanel.BackgroundTransparency=1
 nanPersonalizadoPanel.BorderSizePixel=0
 nanPersonalizadoPanel.ScrollBarThickness=3
 nanPersonalizadoPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y
 nanPersonalizadoPanel.CanvasSize=UDim2.new()
 nanPersonalizadoPanel.Visible=false
 nanPersonalizadoPanel.ZIndex=6
 nanPersonalizadoPanel.Parent=content

 local card=Instance.new("Frame")
 card.Size=UDim2.new(1,0,0,108)
 card.BackgroundColor3=currentTheme.secondary
 card.BorderSizePixel=0
 card.ZIndex=7
 card.Parent=nanPersonalizadoPanel
 Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
 RegisterTheme(card,"BackgroundColor3","secondary")

 local loadButton=Instance.new("TextButton")
 loadButton.Size=UDim2.new(1,-28,0,52)
 loadButton.Position=UDim2.new(0,14,0,14)
 loadButton.BackgroundColor3=currentTheme.accent
 loadButton.BorderSizePixel=0
 loadButton.Text="CARGAR GUI"
 loadButton.TextColor3=Color3.new(1,1,1)
 loadButton.Font=Enum.Font.GothamBold
 loadButton.TextSize=isMobile and 12 or 14
 loadButton.AutoButtonColor=false
 loadButton.ZIndex=8
 loadButton.Parent=card
 Instance.new("UICorner",loadButton).CornerRadius=UDim.new(0,10)
 RegisterTheme(loadButton,"BackgroundColor3","accent")

 local status=Instance.new("TextLabel")
 status.Size=UDim2.new(1,-28,0,28)
 status.Position=UDim2.new(0,14,0,72)
 status.BackgroundTransparency=1
 status.Text="Listo para cargar"
 status.TextColor3=currentTheme.textDim
 status.Font=Enum.Font.GothamMedium
 status.TextSize=isMobile and 9 or 11
 status.TextXAlignment=Enum.TextXAlignment.Center
 status.ZIndex=8
 status.Parent=card
 RegisterTheme(status,"TextColor3","textDim")

 local passwordShade=Instance.new("Frame")
 passwordShade.Name="NanPasswordPrompt"
 passwordShade.Size=UDim2.fromScale(1,1)
 passwordShade.BackgroundColor3=Color3.new(0,0,0)
 passwordShade.BackgroundTransparency=.18
 passwordShade.BorderSizePixel=0
 passwordShade.Visible=false
 passwordShade.Active=true
 passwordShade.ZIndex=210
 passwordShade.Parent=content

 local passwordDialog=Instance.new("Frame")
 passwordDialog.Size=UDim2.new(0,isMobile and 300 or 380,0,224)
 passwordDialog.AnchorPoint=Vector2.new(.5,.5)
 passwordDialog.Position=UDim2.fromScale(.5,.5)
 passwordDialog.BackgroundColor3=currentTheme.secondary
 passwordDialog.BorderSizePixel=0
 passwordDialog.ZIndex=211
 passwordDialog.Parent=passwordShade
 Instance.new("UICorner",passwordDialog).CornerRadius=UDim.new(0,14)
 RegisterTheme(passwordDialog,"BackgroundColor3","secondary")

 local passwordTitle=Instance.new("TextLabel")
 passwordTitle.Size=UDim2.new(1,-28,0,54)
 passwordTitle.Position=UDim2.new(0,14,0,14)
 passwordTitle.BackgroundTransparency=1
 passwordTitle.Text="CONTRASEÑA REQUERIDA"
 passwordTitle.TextColor3=currentTheme.text
 passwordTitle.Font=Enum.Font.GothamBold
 passwordTitle.TextSize=isMobile and 13 or 15
 passwordTitle.ZIndex=212
 passwordTitle.Parent=passwordDialog
 RegisterTheme(passwordTitle,"TextColor3","text")

 local passwordInput=Instance.new("TextBox")
 passwordInput.Size=UDim2.new(1,-28,0,48)
 passwordInput.Position=UDim2.new(0,14,0,72)
 passwordInput.BackgroundColor3=currentTheme.tertiary
 passwordInput.BorderSizePixel=0
 passwordInput.Text=""
 passwordInput.PlaceholderText="Escribe la contraseña"
 passwordInput.TextColor3=currentTheme.text
 passwordInput.PlaceholderColor3=currentTheme.textDim
 passwordInput.Font=Enum.Font.GothamMedium
 passwordInput.TextSize=isMobile and 12 or 14
 passwordInput.ClearTextOnFocus=false
 passwordInput.ZIndex=212
 passwordInput.Parent=passwordDialog
 Instance.new("UICorner",passwordInput).CornerRadius=UDim.new(0,10)
 RegisterTheme(passwordInput,"BackgroundColor3","tertiary")
 RegisterTheme(passwordInput,"TextColor3","text")

 local passwordError=Instance.new("TextLabel")
 passwordError.Size=UDim2.new(1,-28,0,24)
 passwordError.Position=UDim2.new(0,14,0,124)
 passwordError.BackgroundTransparency=1
 passwordError.Text=""
 passwordError.TextColor3=Color3.fromRGB(255,105,125)
 passwordError.Font=Enum.Font.GothamMedium
 passwordError.TextSize=10
 passwordError.ZIndex=212
 passwordError.Parent=passwordDialog

 local confirmPassword=Instance.new("TextButton")
 confirmPassword.Size=UDim2.new(.5,-21,0,48)
 confirmPassword.Position=UDim2.new(0,14,1,-62)
 confirmPassword.BackgroundColor3=currentTheme.accent
 confirmPassword.BorderSizePixel=0
 confirmPassword.Text="CONTINUAR"
 confirmPassword.TextColor3=Color3.new(1,1,1)
 confirmPassword.Font=Enum.Font.GothamBold
 confirmPassword.TextSize=isMobile and 11 or 12
 confirmPassword.ZIndex=212
 confirmPassword.Parent=passwordDialog
 Instance.new("UICorner",confirmPassword).CornerRadius=UDim.new(0,10)
 RegisterTheme(confirmPassword,"BackgroundColor3","accent")

 local cancelPassword=Instance.new("TextButton")
 cancelPassword.Size=UDim2.new(.5,-21,0,48)
 cancelPassword.Position=UDim2.new(.5,7,1,-62)
 cancelPassword.BackgroundColor3=currentTheme.tertiary
 cancelPassword.BorderSizePixel=0
 cancelPassword.Text="CANCELAR"
 cancelPassword.TextColor3=currentTheme.text
 cancelPassword.Font=Enum.Font.GothamBold
 cancelPassword.TextSize=isMobile and 11 or 12
 cancelPassword.ZIndex=212
 cancelPassword.Parent=passwordDialog
 Instance.new("UICorner",cancelPassword).CornerRadius=UDim.new(0,10)
 RegisterTheme(cancelPassword,"BackgroundColor3","tertiary")
 RegisterTheme(cancelPassword,"TextColor3","text")

 local shade=Instance.new("Frame")
 shade.Name="NanLaunchConfirmation"
 shade.Size=UDim2.fromScale(1,1)
 shade.BackgroundColor3=Color3.new(0,0,0)
 shade.BackgroundTransparency=.18
 shade.BorderSizePixel=0
 shade.Visible=false
 shade.Active=true
 shade.ZIndex=200
 shade.Parent=content

 local dialog=Instance.new("Frame")
 dialog.Size=UDim2.new(0,isMobile and 300 or 390,0,220)
 dialog.AnchorPoint=Vector2.new(.5,.5)
 dialog.Position=UDim2.fromScale(.5,.5)
 dialog.BackgroundColor3=currentTheme.secondary
 dialog.BorderSizePixel=0
 dialog.ZIndex=201
 dialog.Parent=shade
 Instance.new("UICorner",dialog).CornerRadius=UDim.new(0,14)
 RegisterTheme(dialog,"BackgroundColor3","secondary")

 local dialogTitle=Instance.new("TextLabel")
 dialogTitle.Size=UDim2.new(1,-28,0,78)
 dialogTitle.Position=UDim2.new(0,14,0,14)
 dialogTitle.BackgroundTransparency=1
 dialogTitle.Text="¿CÓMO QUIERES ABRIR NaN PERSONALIZADO?\nPuedes conservar ambas GUIs o pasar a NaN Personalizado."
 dialogTitle.TextColor3=currentTheme.text
 dialogTitle.Font=Enum.Font.GothamBold
 dialogTitle.TextSize=isMobile and 12 or 14
 dialogTitle.TextWrapped=true
 dialogTitle.ZIndex=202
 dialogTitle.Parent=dialog
 RegisterTheme(dialogTitle,"TextColor3","text")

 local function choice(text,x,color)
  local button=Instance.new("TextButton")
  button.Size=UDim2.new(.5,-21,0,62)
  button.Position=UDim2.new(x,14,0,104)
  button.BackgroundColor3=color
  button.BorderSizePixel=0
  button.Text=text
  button.TextColor3=Color3.new(1,1,1)
  button.TextWrapped=true
  button.Font=Enum.Font.GothamBold
  button.TextSize=isMobile and 10 or 12
  button.AutoButtonColor=false
  button.ZIndex=202
  button.Parent=dialog
  Instance.new("UICorner",button).CornerRadius=UDim.new(0,10)
  return button
 end
 local keepButton=choice("CONSERVAR\nAMBAS GUIs",0,currentTheme.accent)
 local switchButton=choice("PASAR A\nNaN PERSONALIZADO",.5,Color3.fromRGB(96,62,170))
 local cancelButton=Instance.new("TextButton")
 cancelButton.Size=UDim2.new(1,-28,0,32)
 cancelButton.Position=UDim2.new(0,14,1,-42)
 cancelButton.BackgroundTransparency=1
 cancelButton.Text="CANCELAR"
 cancelButton.TextColor3=currentTheme.textDim
 cancelButton.Font=Enum.Font.GothamBold
 cancelButton.TextSize=10
 cancelButton.ZIndex=202
 cancelButton.Parent=dialog
 RegisterTheme(cancelButton,"TextColor3","textDim")

 local busy=false
 local function launch(keepMain)
  if busy then return end
  busy=true;shade.Visible=false;status.Text="Cargando NaN Personalizado..."
  task.spawn(function()
   local ok,err=false,"módulo no disponible"
   if NanPersonalizadoLauncher and NanPersonalizadoLauncher.Launch then ok,err=NanPersonalizadoLauncher:Launch()end
   if ok then
    status.Text="NaN Personalizado cargado"
    if not keepMain then task.defer(function()if gui and gui.Parent then gui.Enabled=false end end)end
   else
    status.Text="No se pudo cargar NaN Personalizado"
    warn("[NaN Personalizado] "..tostring(err))
   end
   busy=false
  end)
 end
 local function validatePassword()
  if busy then return end
  local password=passwordInput.Text
  if password==""then passwordError.Text="Escribe la contraseña"return end
  if not NanPersonalizadoLauncher or not NanPersonalizadoLauncher.Authorize then passwordError.Text="Backend no disponible"return end
  busy=true;confirmPassword.Active=false;passwordError.Text="Validando con el backend...";status.Text="Validando acceso..."
  NanPersonalizadoLauncher:Authorize(password,function(ok,err)
   busy=false;confirmPassword.Active=true;passwordInput.Text=""
   if ok then
    passwordShade.Visible=false;passwordError.Text="";status.Text="Acceso autorizado";shade.Visible=true
   else
    passwordError.Text=err=="http_401"and"Contraseña incorrecta"or"No se pudo validar con el backend"
    status.Text="Acceso no autorizado"
    task.defer(function()if passwordInput.Parent then passwordInput:CaptureFocus()end end)
   end
  end)
 end
 loadButton.Activated:Connect(function()
  if busy then return end
  passwordError.Text="";passwordInput.Text="";passwordShade.Visible=true
  task.defer(function()if passwordInput.Parent then passwordInput:CaptureFocus()end end)
 end)
 confirmPassword.Activated:Connect(validatePassword)
 passwordInput.FocusLost:Connect(function(enterPressed)if enterPressed then validatePassword()end end)
 cancelPassword.Activated:Connect(function()passwordShade.Visible=false;passwordError.Text="";passwordInput.Text=""end)
 keepButton.Activated:Connect(function()launch(true)end)
 switchButton.Activated:Connect(function()launch(false)end)
 cancelButton.Activated:Connect(function()shade.Visible=false end)
 UpdateNanPersonalizadoPanel=function()status.Text=busy and"Cargando NaN Personalizado..."or"Listo para cargar"end
 return true
end
