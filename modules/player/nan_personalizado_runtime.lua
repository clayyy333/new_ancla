return function(context)
 setfenv(1,context)
 local alive=true
 local authorized=false
 local authorizing=false
 local function runNan()local C={FLING_DURATION=1.5,TOUCH_DISTANCE=3,TOUCH_COOLDOWN=3,SIT_RADIUS=10,WIDTH=520,HEIGHT=460,BG=Color3.fromRGB(2,7,6),PANEL=Color3.fromRGB(7,19,15),TITLE=Color3.fromRGB(4,12,10),STROKE=Color3.fromRGB(27,83,61),WHITE=Color3.fromRGB(231,255,242),GREY=Color3.fromRGB(153,194,171),DIM=Color3.fromRGB(14,48,36),GREEN=Color3.fromRGB(0,255,136),RED=Color3.fromRGB(238,75,101),PURPLE=Color3.fromRGB(0,255,136),CYAN=Color3.fromRGB(85,255,193)}
local P=game:GetService("Players")local R=game:GetService("RunService")local T=game:GetService("TweenService")local U=game:GetService("UserInputService")local W=game:GetService("Workspace")
if not game:IsLoaded()then game.Loaded:Wait()end
local pl=P.LocalPlayer
while not pl do P:GetPropertyChangedSignal("LocalPlayer"):Wait()pl=P.LocalPlayer end
local pg=pl:WaitForChild("PlayerGui")local mob=U.TouchEnabled and not U.KeyboardEnabled
local AF={}local tE=false local tCd={}local mz=false
local sE=false local sC=nil local mt={}
local cE=false local cToken=0 local cCleaning=false
local skipTargetVersion=0
local closing=false
local dragInputConn,keyInputConn
local modo="CINTURA"
local cinturaDepth=13
local followConn=nil
local followActive=false
local followOrigin=nil
local activeReturnToOrigin=nil
local function stopFollow()
 followActive=false
 if followConn then followConn:Disconnect() followConn=nil end
end
local function gc()return pl.Character end
local function grp()local c=gc()return c and c:FindFirstChild("HumanoidRootPart")end
local function gpb(n)n=n:lower()local e,p={},{}for _,x in ipairs(P:GetPlayers())do if x~=pl then local a=x.Name:lower()local b=x.DisplayName:lower()if a==n or b==n then table.insert(e,x)elseif a:find(n,1,true)or b:find(n,1,true)then table.insert(p,x)end end end return #e>0 and e or p end
if pg:FindFirstChild("NaNFlingGUI")then pg.NaNFlingGUI:Destroy()end
local sg=Instance.new("ScreenGui")sg.Name="NaNFlingGUI"sg.ResetOnSpawn=false sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling sg.Parent=pg
local function mc(r,p)local c=Instance.new("UICorner")c.CornerRadius=UDim.new(0,r or 8)c.Parent=p return c end
local function ms(col,t,p)local s=Instance.new("UIStroke")s.Color=col or C.STROKE s.Thickness=t or 1 s.Parent=p return s end
local function mg(a,b,r,p)local g=Instance.new("UIGradient")g.Color=ColorSequence.new(a,b)g.Rotation=r or 90 g.Parent=p return g end
local mf=Instance.new("Frame")mf.Size=UDim2.new(0,C.WIDTH,0,C.HEIGHT)mf.Position=UDim2.new(0.5,-C.WIDTH/2,-0.5,0)mf.BackgroundColor3=C.BG mf.BorderSizePixel=0 mf.Active=true mf.Parent=sg mc(10,mf)ms(Color3.fromRGB(18,112,75),1,mf)mg(Color3.fromRGB(4,14,11),Color3.fromRGB(1,5,4),90,mf)
for scan=1,22 do local line=Instance.new("Frame")line.Size=UDim2.new(1,-4,0,1)line.Position=UDim2.new(0,2,0,scan*20)line.BackgroundColor3=Color3.fromRGB(25,94,67)line.BackgroundTransparency=.9 line.BorderSizePixel=0 line.ZIndex=0 line.Parent=mf end
local matrixLayer=Instance.new("Frame")matrixLayer.Size=UDim2.new(1,0,1,-56)matrixLayer.Position=UDim2.new(0,0,0,56)matrixLayer.BackgroundTransparency=1 matrixLayer.ClipsDescendants=true matrixLayer.ZIndex=0 matrixLayer.Parent=mf
for column=1,16 do
 local stream=Instance.new("TextLabel")stream.Size=UDim2.new(0,24,0,260)stream.Position=UDim2.new(0,(column-1)*34,-.5-math.random(),0)stream.BackgroundTransparency=1 stream.Text="0\n1\n0\n0\n1\n1\n0\n1\n0\n1\n1\n0"stream.TextColor3=Color3.fromRGB(0,180,92)stream.TextTransparency=.78 stream.TextSize=11 stream.Font=Enum.Font.RobotoMono stream.TextYAlignment=Enum.TextYAlignment.Top stream.ZIndex=0 stream.Parent=matrixLayer
 task.spawn(function()while stream.Parent do stream.Position=UDim2.new(0,(column-1)*34,0,-280-math.random(0,180))local tween=T:Create(stream,TweenInfo.new(6+math.random()*5,Enum.EasingStyle.Linear),{Position=UDim2.new(0,(column-1)*34,1,20)})tween:Play()tween.Completed:Wait()end end)
end
T:Create(mf,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-C.WIDTH/2,0.5,-C.HEIGHT/2)}):Play()
task.delay(1,function()if mf and mf.Parent and mf.Position.Y.Scale<0 then mf.Position=UDim2.new(0.5,-C.WIDTH/2,0.5,-C.HEIGHT/2)end end)
local tb=Instance.new("Frame")tb.Size=UDim2.new(1,0,0,56)tb.BackgroundColor3=C.TITLE tb.BorderSizePixel=0 tb.Parent=mf mc(10,tb)mg(Color3.fromRGB(5,28,19),Color3.fromRGB(2,9,7),0,tb)
local accent=Instance.new("Frame")accent.Size=UDim2.new(0,4,0,28)accent.Position=UDim2.new(0,14,0,14)accent.BackgroundColor3=C.PURPLE accent.BorderSizePixel=0 accent.Parent=tb mc(3,accent)mg(C.CYAN,C.PURPLE,90,accent)
local tl=Instance.new("TextLabel")tl.Size=UDim2.new(1,-110,0,23)tl.Position=UDim2.new(0,28,0,8)tl.BackgroundTransparency=1 tl.Text="NaN Personalizado by Psychoo"tl.TextColor3=C.GREEN tl.TextSize=16 tl.Font=Enum.Font.RobotoMono tl.TextXAlignment=Enum.TextXAlignment.Left tl.Parent=tb
local subtitle=Instance.new("TextLabel")subtitle.Size=UDim2.new(1,-110,0,16)subtitle.Position=UDim2.new(0,28,0,31)subtitle.BackgroundTransparency=1 subtitle.Text=""subtitle.TextColor3=C.GREY subtitle.TextSize=10 subtitle.Font=Enum.Font.RobotoMono subtitle.TextXAlignment=Enum.TextXAlignment.Left subtitle.Parent=tb
local minBtn=Instance.new("TextButton")minBtn.Size=UDim2.new(0,30,0,30)minBtn.Position=UDim2.new(1,-76,0,13)minBtn.BackgroundColor3=C.PANEL minBtn.Text="—"minBtn.TextColor3=C.GREY minBtn.TextSize=16 minBtn.Font=Enum.Font.GothamBold minBtn.BorderSizePixel=0 minBtn.Parent=tb mc(8,minBtn)ms(C.STROKE,1,minBtn)
local clsBtn=Instance.new("TextButton")clsBtn.Size=UDim2.new(0,30,0,30)clsBtn.Position=UDim2.new(1,-40,0,13)clsBtn.BackgroundColor3=Color3.fromRGB(49,24,35)clsBtn.Text="×"clsBtn.TextColor3=Color3.fromRGB(255,117,135)clsBtn.TextSize=18 clsBtn.Font=Enum.Font.GothamBold clsBtn.BorderSizePixel=0 clsBtn.Parent=tb mc(8,clsBtn)ms(Color3.fromRGB(112,42,59),1,clsBtn)
local ct=Instance.new("ScrollingFrame")ct.Size=UDim2.new(1,-28,1,-72)ct.Position=UDim2.new(0,14,0,64)ct.BackgroundTransparency=1 ct.BorderSizePixel=0 ct.CanvasSize=UDim2.new(0,0,0,540)ct.ScrollBarThickness=4 ct.ScrollBarImageColor3=C.PURPLE ct.ScrollBarImageTransparency=0.15 ct.ScrollingDirection=Enum.ScrollingDirection.Y ct.ElasticBehavior=Enum.ElasticBehavior.Always ct.ClipsDescendants=true ct.Active=true ct.Parent=mf
local il=Instance.new("TextLabel")il.Size=UDim2.new(1,0,0,20)il.BackgroundTransparency=1 il.Text="DESTINATARIOS"il.TextColor3=C.GREY il.TextSize=10 il.Font=Enum.Font.GothamBold il.TextXAlignment=Enum.TextXAlignment.Left il.Parent=ct

local selectedPlayer = nil
local activeTarget = nil
local selectedPlayerIds = {}
local selectAllPlayers = false
local playerMenuOpen = false
local resetCount = 0
local charAddedConn = nil
local charRemovingConn = nil
local removedCharacter = nil
local updateCommandLayout=function()end
local function playerLabel(player)
	if not player then return "ninguno"end
	if player.DisplayName==player.Name then return "@"..player.Name end
	return player.DisplayName.." (@"..player.Name..")"
end

local playerBtn = Instance.new("TextButton")
playerBtn.Size = UDim2.new(1,0,0,40)
playerBtn.Position = UDim2.new(0,0,0,22)
playerBtn.BackgroundColor3 = Color3.fromRGB(9,24,19)
playerBtn.Text = "JUGADORES: ninguno  ▼"
playerBtn.TextColor3 = Color3.fromRGB(232,238,235)
playerBtn.TextSize = 12
playerBtn.Font = Enum.Font.GothamMedium
playerBtn.TextXAlignment = Enum.TextXAlignment.Left
playerBtn.TextTruncate = Enum.TextTruncate.AtEnd
playerBtn.BorderSizePixel = 0
playerBtn.Parent = ct
mc(9,playerBtn)
local playerBtnStroke=ms(Color3.fromRGB(52,78,67),1,playerBtn)playerBtnStroke.Transparency=.3
local playerPad = Instance.new("UIPadding")
playerPad.PaddingLeft = UDim.new(0,10)
playerPad.Parent = playerBtn

local playerMenu = Instance.new("Frame")
playerMenu.Size = UDim2.new(1,0,0,180)
playerMenu.Position = UDim2.new(0,0,0,64)
playerMenu.BackgroundColor3 = Color3.fromRGB(11,16,28)
playerMenu.BorderSizePixel = 0
playerMenu.Visible = false
playerMenu.ZIndex = 50
playerMenu.Parent = ct
mc(10,playerMenu)
ms(C.PURPLE,1,playerMenu)

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1,-8,1,-8)
playerScroll.Position = UDim2.new(0,4,0,4)
playerScroll.BackgroundTransparency = 1
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 5
playerScroll.ScrollBarImageColor3 = C.PURPLE
playerScroll.CanvasSize = UDim2.new(0,0,0,0)
playerScroll.ZIndex = 51
playerScroll.Parent = playerMenu

local function updateResetLabel()
end

local function clearDeathTracking()
	if charAddedConn then charAddedConn:Disconnect() charAddedConn=nil end
	if charRemovingConn then charRemovingConn:Disconnect() charRemovingConn=nil end
	removedCharacter = nil
end

local function trackPlayerDeaths(player)
	clearDeathTracking()
	if not player then return end
	charRemovingConn = player.CharacterRemoving:Connect(function(char)
		if selectedPlayer == player and player.Parent == P then
			removedCharacter = char
		end
	end)
	charAddedConn = player.CharacterAdded:Connect(function(char)
		if selectedPlayer == player and player.Parent == P and removedCharacter and char ~= removedCharacter then
			removedCharacter = nil
			resetCount = resetCount + 1
			updateResetLabel()
			nt("REINICIO", player.Name.." #"..resetCount, 2)
		end
	end)
end

local function updatePlayerButtonText()
	local count=0
	for _,p in ipairs(P:GetPlayers())do if p~=pl and selectedPlayerIds[p.UserId]then count=count+1 end end
	if selectAllPlayers then playerBtn.Text="JUGADORES: TODOS ("..count..")  ▼"
	elseif count>0 then playerBtn.Text="JUGADORES: "..count.." seleccionado"..(count==1 and ""or"s").."  ▼"
	else playerBtn.Text="JUGADORES: ninguno  ▼"end
	updateCommandLayout()
end

local function refreshPlayerList()
	for _,child in ipairs(playerScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local players = {}
	for _,p in ipairs(P:GetPlayers()) do
		if p ~= pl then
			table.insert(players,p)
		end
	end
	table.sort(players,function(a,b) return a.DisplayName:lower() < b.DisplayName:lower() end)
	local function decoratePlayerRow(row,marked,text)
		row.Text=""
		local indicator=Instance.new("Frame")indicator.Size=UDim2.new(0,16,0,16)indicator.Position=UDim2.new(0,9,0.5,-8)indicator.BackgroundColor3=marked and Color3.fromRGB(0,190,101)or Color3.fromRGB(13,31,25)indicator.BorderSizePixel=0 indicator.ZIndex=53 indicator.Parent=row mc(8,indicator)local indicatorStroke=ms(marked and Color3.fromRGB(72,255,165)or Color3.fromRGB(66,91,79),1,indicator)indicatorStroke.Transparency=marked and 0 or .2
		local check=Instance.new("TextLabel")check.Size=UDim2.new(1,0,1,0)check.BackgroundTransparency=1 check.Text=marked and"✓"or""check.TextColor3=Color3.fromRGB(240,255,247)check.TextSize=11 check.Font=Enum.Font.GothamBold check.ZIndex=54 check.Parent=indicator
		local label=Instance.new("TextLabel")label.Size=UDim2.new(1,-42,1,0)label.Position=UDim2.new(0,34,0,0)label.BackgroundTransparency=1 label.Text=text label.TextColor3=marked and Color3.fromRGB(231,255,241)or Color3.fromRGB(196,211,204)label.TextSize=11 label.Font=Enum.Font.GothamMedium label.TextXAlignment=Enum.TextXAlignment.Left label.TextTruncate=Enum.TextTruncate.AtEnd label.ZIndex=53 label.Parent=row
	end
	
	local y = 0
	local allButton=Instance.new("TextButton")
	allButton.Size=UDim2.new(1,-6,0,30)allButton.Position=UDim2.new(0,2,0,y)
	allButton.BackgroundColor3=selectAllPlayers and Color3.fromRGB(10,45,32)or Color3.fromRGB(8,21,17)
	allButton.BorderSizePixel=0 allButton.ZIndex=52 allButton.Parent=playerScroll mc(6,allButton)local allStroke=ms(selectAllPlayers and Color3.fromRGB(25,117,78)or Color3.fromRGB(42,62,53),1,allButton)allStroke.Transparency=.25 decoratePlayerRow(allButton,selectAllPlayers,"Seleccionar todos")
	allButton.MouseButton1Click:Connect(function()
		selectAllPlayers=not selectAllPlayers
		for _,candidate in ipairs(P:GetPlayers())do if candidate~=pl then selectedPlayerIds[candidate.UserId]=selectAllPlayers or nil end end
		selectedPlayer=nil resetCount=0 clearDeathTracking()updateResetLabel()updatePlayerButtonText()refreshPlayerList()
		nt("JUGADORES",selectAllPlayers and "todos seleccionados"or"selección limpiada",2)
	end)
	y=y+32
	for _,p in ipairs(players) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1,-6,0,30)
		b.Position = UDim2.new(0,2,0,y)
		local marked=selectedPlayerIds[p.UserId]==true
		b.BackgroundColor3 = marked and Color3.fromRGB(10,42,30)or Color3.fromRGB(7,18,15)
		b.Text = ""
		b.BorderSizePixel = 0
		b.ZIndex = 52
		b.Parent = playerScroll
		mc(6,b)
		local rowStroke=ms(marked and Color3.fromRGB(25,105,72)or Color3.fromRGB(38,57,49),1,b)rowStroke.Transparency=.3
		decoratePlayerRow(b,marked,playerLabel(p))
		
		b.MouseButton1Click:Connect(function()
			selectedPlayerIds[p.UserId]=not selectedPlayerIds[p.UserId] or nil
			selectAllPlayers=false
			selectedPlayer = selectedPlayerIds[p.UserId]and p or nil
			resetCount = 0
			updateResetLabel()
			if selectedPlayer then trackPlayerDeaths(p)else clearDeathTracking()end
			updatePlayerButtonText()
			refreshPlayerList()
			nt("JUGADOR",playerLabel(p)..(selectedPlayerIds[p.UserId]and" seleccionado"or" desmarcado"),2)
		end)
		y = y + 32
	end
	playerScroll.CanvasSize = UDim2.new(0,0,0,math.max(y,1))
end

playerBtn.MouseButton1Click:Connect(function()
	playerMenuOpen = not playerMenuOpen
	playerMenu.Visible = playerMenuOpen
	if playerMenuOpen then
		refreshPlayerList()
		updatePlayerButtonText()playerBtn.Text=playerBtn.Text:gsub("▼","▲")
	else
		updatePlayerButtonText()
	end
end)

P.PlayerRemoving:Connect(function(leaving)
	if selectedPlayer == leaving then
		selectedPlayer = nil
		resetCount = 0
		clearDeathTracking()
		updatePlayerButtonText()
		updateResetLabel()
	end
	updatePlayerButtonText()
end)

P.PlayerAdded:Connect(function(joining)
	if selectAllPlayers and joining~=pl then selectedPlayerIds[joining.UserId]=true end
	updatePlayerButtonText()
	if playerMenuOpen then
		refreshPlayerList()
	end
end)

local function selectedTarget()
	if activeTarget and activeTarget.Parent==P and selectedPlayerIds[activeTarget.UserId]then return activeTarget end
	if selectedPlayer and selectedPlayer.Parent==P and selectedPlayerIds[selectedPlayer.UserId]then return selectedPlayer end
	for _,candidate in ipairs(P:GetPlayers())do if candidate~=pl and selectedPlayerIds[candidate.UserId]then return candidate end end
	return nil
end
local function selectedTargetsSnapshot()
	local targets={}
	for _,candidate in ipairs(P:GetPlayers())do
		if candidate~=pl and selectedPlayerIds[candidate.UserId]then table.insert(targets,candidate)end
	end
	table.sort(targets,function(a,b)return a.Name:lower()<b.Name:lower()end)
	return targets
end
local perspectiveActive=false
local perspectiveTarget=nil
local perspectiveConnection=nil
local perspectiveRenderName="NaNPerspective_"..tostring(pl.UserId)
local perspectiveZoomConnection=nil
local perspectivePinchConnection=nil
local perspectiveInputBeganConnection=nil
local perspectiveInputEndedConnection=nil
local perspectiveTouchStartedConnection=nil
local perspectiveTouchMovedConnection=nil
local perspectiveTouchEndedConnection=nil
local perspectiveSavedType=nil
local perspectiveSavedSubject=nil
local perspectiveSavedCFrame=nil
local PERSPECTIVE_DEFAULT_HEIGHT=8
local PERSPECTIVE_MIN_HEIGHT=0
local PERSPECTIVE_MAX_HEIGHT=80
local perspectiveHeight=PERSPECTIVE_DEFAULT_HEIGHT
local perspectiveTargetHeight=PERSPECTIVE_DEFAULT_HEIGHT
local perspectivePinchScale=nil
local perspectiveMode="TOP"
local perspectiveYaw=0
local perspectivePitch=math.rad(-89)
local perspectiveRotating=false
local perspectiveTouch=nil
local perspectiveLastTouch=nil
local perspectivePinching=false
local cameraDistanceInput=nil
local function updateCameraDistanceDisplay()
 if cameraDistanceInput and not cameraDistanceInput:IsFocused()then
  cameraDistanceInput.Text=string.format("%.1f",perspectiveTargetHeight):gsub("%.0$","")
 end
end
local function pointerOverPerspectiveGui(position)
 local ok,objects=pcall(function()return pg:GetGuiObjectsAtPosition(position.X,position.Y)end)
 if not ok then return false end
 for _,object in ipairs(objects)do if object==sg or object:IsDescendantOf(sg)then return true end end
 return false
end
local function setPerspectivePreset(root)
 local look=root and root.CFrame.LookVector or Vector3.new(0,0,-1)
 local horizontal=Vector3.new(look.X,0,look.Z)
 if horizontal.Magnitude<.001 then horizontal=Vector3.new(0,0,-1)else horizontal=horizontal.Unit end
 local radial=perspectiveMode=="BACK"and-horizontal or horizontal
 perspectiveYaw=math.atan2(radial.X,radial.Z)
 perspectivePitch=perspectiveMode=="TOP"and math.rad(-89)or math.rad(-8)
end
local function applyPerspectiveCameraNow()
 if not perspectiveActive or not perspectiveTarget then return false end
 local camera=W.CurrentCamera
 local character=perspectiveTarget.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not camera or not root or not root.Parent then return false end
 local focus=root.Position+Vector3.new(0,1,0)
 local rotation=CFrame.Angles(0,perspectiveYaw,0)*CFrame.Angles(perspectivePitch,0,0)
 local position=focus+rotation:VectorToWorldSpace(Vector3.new(0,0,perspectiveHeight))
 camera.CameraType=Enum.CameraType.Scriptable
 camera.CFrame=CFrame.lookAt(position,focus)
 camera.Focus=CFrame.new(focus)
 return true
end
local function stopTargetPerspective()
 local shouldRestore=perspectiveActive or perspectiveConnection~=nil or perspectiveSavedType~=nil or perspectiveSavedSubject~=nil or perspectiveSavedCFrame~=nil
 perspectiveActive=false
 perspectiveTarget=nil
 if perspectiveConnection then pcall(function()R:UnbindFromRenderStep(perspectiveRenderName)end)perspectiveConnection=nil end
 if perspectiveZoomConnection then perspectiveZoomConnection:Disconnect()perspectiveZoomConnection=nil end
 if perspectivePinchConnection then perspectivePinchConnection:Disconnect()perspectivePinchConnection=nil end
 if perspectiveInputBeganConnection then perspectiveInputBeganConnection:Disconnect()perspectiveInputBeganConnection=nil end
 if perspectiveInputEndedConnection then perspectiveInputEndedConnection:Disconnect()perspectiveInputEndedConnection=nil end
 if perspectiveTouchStartedConnection then perspectiveTouchStartedConnection:Disconnect()perspectiveTouchStartedConnection=nil end
 if perspectiveTouchMovedConnection then perspectiveTouchMovedConnection:Disconnect()perspectiveTouchMovedConnection=nil end
 if perspectiveTouchEndedConnection then perspectiveTouchEndedConnection:Disconnect()perspectiveTouchEndedConnection=nil end
 perspectivePinchScale=nil
 perspectiveRotating=false
 perspectiveTouch=nil
 perspectiveLastTouch=nil
 perspectivePinching=false
 pcall(function()U.MouseBehavior=Enum.MouseBehavior.Default end)
 local camera=W.CurrentCamera
 if shouldRestore and camera then
  camera.CameraType=perspectiveSavedType or Enum.CameraType.Custom
  if perspectiveSavedSubject and perspectiveSavedSubject.Parent then
   camera.CameraSubject=perspectiveSavedSubject
  else
   local character=gc()
   local humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if humanoid then camera.CameraSubject=humanoid end
  end
  if perspectiveSavedCFrame then camera.CFrame=perspectiveSavedCFrame end
 end
 perspectiveSavedType=nil
 perspectiveSavedSubject=nil
 perspectiveSavedCFrame=nil
end
local function startTargetPerspective(target)
 stopTargetPerspective()
 local character=target and target.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local camera=W.CurrentCamera
 if not target or target.Parent~=P or not root or not camera then return false end
 perspectiveSavedType=camera.CameraType
 perspectiveSavedSubject=camera.CameraSubject
 perspectiveSavedCFrame=camera.CFrame
 perspectiveTarget=target
 perspectiveActive=true
 perspectiveHeight=perspectiveTargetHeight
 updateCameraDistanceDisplay()
 setPerspectivePreset(root)
 camera.CameraType=Enum.CameraType.Scriptable
 perspectiveInputBeganConnection=U.InputBegan:Connect(function(input,processed)
  if not perspectiveActive or processed or pointerOverPerspectiveGui(input.Position)then return end
  if input.UserInputType==Enum.UserInputType.MouseButton2 then
   perspectiveRotating=true
   pcall(function()U.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition end)
  end
 end)
 perspectiveInputEndedConnection=U.InputEnded:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton2 then
   perspectiveRotating=false
   pcall(function()U.MouseBehavior=Enum.MouseBehavior.Default end)
  end
 end)
 perspectiveZoomConnection=U.InputChanged:Connect(function(input,processed)
  if not perspectiveActive or processed then return end
  if input.UserInputType==Enum.UserInputType.MouseWheel then
   if pointerOverPerspectiveGui(U:GetMouseLocation())then return end
   perspectiveTargetHeight=math.clamp(perspectiveTargetHeight-input.Position.Z*4,PERSPECTIVE_MIN_HEIGHT,PERSPECTIVE_MAX_HEIGHT)
   updateCameraDistanceDisplay()
  elseif perspectiveRotating and input.UserInputType==Enum.UserInputType.MouseMovement then
   perspectiveYaw-=input.Delta.X*.006
   perspectivePitch=math.clamp(perspectivePitch-input.Delta.Y*.006,math.rad(-89),math.rad(80))
  end
 end)
 perspectivePinchConnection=U.TouchPinch:Connect(function(touches,scale,velocity,state,processed)
  if not perspectiveActive or processed then return end
  if state==Enum.UserInputState.Begin then
   perspectivePinching=true
   perspectiveTouch=nil
   perspectiveLastTouch=nil
   perspectivePinchScale=scale
  elseif state==Enum.UserInputState.Change then
   local previous=perspectivePinchScale or scale
   if previous>0 and scale>0 then
    perspectiveTargetHeight=math.clamp(perspectiveTargetHeight/(scale/previous),PERSPECTIVE_MIN_HEIGHT,PERSPECTIVE_MAX_HEIGHT)
    updateCameraDistanceDisplay()
   end
   perspectivePinchScale=scale
  else
   perspectivePinching=false
   perspectivePinchScale=nil
  end
 end)
 perspectiveTouchStartedConnection=U.TouchStarted:Connect(function(touch,processed)
  if not perspectiveActive or processed or perspectivePinching or perspectiveTouch or pointerOverPerspectiveGui(touch.Position)then return end
  perspectiveTouch=touch
  perspectiveLastTouch=touch.Position
 end)
 perspectiveTouchMovedConnection=U.TouchMoved:Connect(function(touch,processed)
  if not perspectiveActive or processed or perspectivePinching or touch~=perspectiveTouch or not perspectiveLastTouch then return end
  local delta=touch.Position-perspectiveLastTouch
  perspectiveLastTouch=touch.Position
  perspectiveYaw-=delta.X*.007
  perspectivePitch=math.clamp(perspectivePitch-delta.Y*.007,math.rad(-89),math.rad(80))
 end)
 perspectiveTouchEndedConnection=U.TouchEnded:Connect(function(touch)
  if touch==perspectiveTouch then perspectiveTouch=nil perspectiveLastTouch=nil end
 end)
 pcall(function()R:UnbindFromRenderStep(perspectiveRenderName)end)
 perspectiveConnection=true
 R:BindToRenderStep(perspectiveRenderName,Enum.RenderPriority.Last.Value,function(dt)
  if not perspectiveActive or not cE or perspectiveTarget~=selectedTarget()or perspectiveTarget.Parent~=P then
   stopTargetPerspective()
   return
  end
  camera=W.CurrentCamera
  character=perspectiveTarget.Character
  root=character and character:FindFirstChild("HumanoidRootPart")
  if not camera or not root or not root.Parent then
   stopTargetPerspective()
   return
  end
  perspectiveHeight+=(perspectiveTargetHeight-perspectiveHeight)*(1-math.exp(-10*dt))
  local focus=root.Position+Vector3.new(0,1,0)
  local rotation=CFrame.Angles(0,perspectiveYaw,0)*CFrame.Angles(perspectivePitch,0,0)
  local position=focus+rotation:VectorToWorldSpace(Vector3.new(0,0,perspectiveHeight))
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=CFrame.lookAt(position,focus)
  camera.Focus=CFrame.new(focus)
 end)
 return true
end

local flB=Instance.new("TextButton")flB.Size=UDim2.new(1,0,0,40)flB.Position=UDim2.new(0,0,0,70)flB.BackgroundColor3=Color3.fromRGB(5,52,34)flB.Text="ACTIVAR"flB.TextColor3=C.GREEN flB.TextSize=13 flB.Font=Enum.Font.GothamBold flB.BorderSizePixel=0 flB.Parent=ct mc(7,flB)local flBStroke=ms(Color3.fromRGB(0,180,96),1,flB)
local function mkT(t,y,on)local b=Instance.new("TextButton")b.Size=UDim2.new(1,0,0,34)b.Position=UDim2.new(0,0,0,y)b.BackgroundColor3=on and C.DIM or C.PANEL b.Text=t..(on and "   ACTIVO" or "   INACTIVO")b.TextColor3=on and C.WHITE or C.GREY b.TextSize=11 b.Font=Enum.Font.GothamBold b.TextXAlignment=Enum.TextXAlignment.Left b.BorderSizePixel=0 b.Parent=ct mc(9,b)local s=ms(on and C.PURPLE or C.STROKE,1,b)local pd=Instance.new("UIPadding")pd.PaddingLeft=UDim.new(0,12)pd.Parent=b local function ss(o)b.BackgroundColor3=o and Color3.fromRGB(8,54,37)or C.PANEL b.TextColor3=o and C.WHITE or C.GREY s.Color=o and C.PURPLE or C.STROKE end return b,ss end
local modoBtn=Instance.new("TextButton")modoBtn.Size=UDim2.new(1,0,0,34)modoBtn.Position=UDim2.new(0,0,0,116)modoBtn.BackgroundColor3=C.PANEL modoBtn.Text="MODO: CINTURA"modoBtn.TextColor3=C.CYAN modoBtn.TextSize=11 modoBtn.Font=Enum.Font.GothamBold modoBtn.TextXAlignment=Enum.TextXAlignment.Left modoBtn.BorderSizePixel=0 modoBtn.Parent=ct mc(7,modoBtn)ms(C.STROKE,1,modoBtn)
local pd=Instance.new("UIPadding")pd.PaddingLeft=UDim.new(0,10)pd.Parent=modoBtn
local depthFrame=Instance.new("Frame")
depthFrame.Size=UDim2.new(1,0,0,32)
depthFrame.Position=UDim2.new(0,0,0,440)
depthFrame.BackgroundColor3=C.PANEL
depthFrame.BorderSizePixel=0
depthFrame.Parent=ct
mc(9,depthFrame) ms(C.STROKE,1,depthFrame)
local depthLabel=Instance.new("TextLabel")
depthLabel.Size=UDim2.new(1,-94,1,0)
depthLabel.Position=UDim2.new(0,10,0,0)
depthLabel.BackgroundTransparency=1
depthLabel.Text="DISTANCIA DEL OBJETIVO: 0–20"
depthLabel.TextColor3=C.GREY
depthLabel.TextSize=11
depthLabel.Font=Enum.Font.GothamBold
depthLabel.TextXAlignment=Enum.TextXAlignment.Left
depthLabel.Parent=depthFrame
local depthInput=Instance.new("TextBox")
depthInput.Size=UDim2.new(0,75,0,26)
depthInput.Position=UDim2.new(1,-80,0,3)
depthInput.BackgroundColor3=Color3.fromRGB(10,15,27)
depthInput.TextColor3=C.WHITE
depthInput.TextSize=12
depthInput.Font=Enum.Font.GothamBold
depthInput.Text="13"
depthInput.PlaceholderText="DISTANCIA"
depthInput.ClearTextOnFocus=false
depthInput.Parent=depthFrame
mc(7,depthInput) ms(Color3.fromRGB(58,70,99),1,depthInput)
depthInput.FocusLost:Connect(function()
 local value=tonumber(depthInput.Text)
 if value and value==value and value~=math.huge and value~=-math.huge then
  cinturaDepth=math.clamp(value,0,20)
 end
 depthInput.Text=tostring(cinturaDepth)
end)
local balloonChoice="ValentineBalloon"
local OBJECT_SELECTED=Color3.fromRGB(112,72,210)
local OBJECT_STROKE=Color3.fromRGB(168,125,255)
local balloonFrame=Instance.new("Frame")
balloonFrame.Size=UDim2.new(1,0,0,32)
balloonFrame.Position=UDim2.new(0,0,0,478)
balloonFrame.BackgroundTransparency=1
balloonFrame.Parent=ct
local valentineB=Instance.new("TextButton")
valentineB.Size=UDim2.new(.5,-3,1,0)
valentineB.BackgroundColor3=OBJECT_SELECTED
valentineB.Text="VALENTINE"
valentineB.TextColor3=C.WHITE
valentineB.TextSize=10
valentineB.Font=Enum.Font.GothamBold
valentineB.BorderSizePixel=0
valentineB.Parent=balloonFrame
mc(9,valentineB)local valentineStroke=ms(OBJECT_STROKE,1,valentineB)
local newYearB=Instance.new("TextButton")
newYearB.Size=UDim2.new(.5,-3,1,0)
newYearB.Position=UDim2.new(.5,3,0,0)
newYearB.BackgroundColor3=C.PANEL
newYearB.Text="NEW YEAR"
newYearB.TextColor3=C.GREY
newYearB.TextSize=10
newYearB.Font=Enum.Font.GothamBold
newYearB.BorderSizePixel=0
newYearB.Parent=balloonFrame
mc(9,newYearB)local newYearStroke=ms(C.STROKE,1,newYearB)
local function selectBalloon(name)
 if cE or cCleaning then return end
 balloonChoice=name
 local valentine=name=="ValentineBalloon"
 valentineB.BackgroundColor3=valentine and OBJECT_SELECTED or C.PANEL
 valentineB.TextColor3=valentine and C.WHITE or C.GREY
 newYearB.BackgroundColor3=valentine and C.PANEL or OBJECT_SELECTED
 newYearB.TextColor3=valentine and C.GREY or C.WHITE
 valentineStroke.Color=valentine and OBJECT_STROKE or C.STROKE
 newYearStroke.Color=valentine and C.STROKE or OBJECT_STROKE
end
valentineB.MouseButton1Click:Connect(function()selectBalloon("ValentineBalloon")end)
newYearB.MouseButton1Click:Connect(function()selectBalloon("NewYearBalloon")end)
local perspectiveFrame=Instance.new("Frame")
perspectiveFrame.Size=UDim2.new(1,0,0,32)
perspectiveFrame.Position=UDim2.new(0,0,0,516)
perspectiveFrame.BackgroundTransparency=1
perspectiveFrame.Parent=ct
local perspectiveButtons={}
local perspectiveOptions={{"CENTRAL","TOP"},{"FRONTAL","FRONT"},{"TRASERA","BACK"}}
for index,option in ipairs(perspectiveOptions)do
 local button=Instance.new("TextButton")
 button.Size=UDim2.new(1/3,-4,1,0)
 button.Position=UDim2.new((index-1)/3,index==1 and 0 or 2,0,0)
 button.BackgroundColor3=option[2]==perspectiveMode and C.PURPLE or C.PANEL
 button.Text=option[1]
 button.TextColor3=option[2]==perspectiveMode and C.WHITE or C.GREY
 button.TextSize=9
 button.Font=Enum.Font.GothamBold
 button.BorderSizePixel=0
 button.Parent=perspectiveFrame
  mc(9,button)
 perspectiveButtons[option[2]]=button
 button.MouseButton1Click:Connect(function()
  perspectiveMode=option[2]
  if perspectiveActive and perspectiveTarget then
   local character=perspectiveTarget.Character
   local root=character and character:FindFirstChild("HumanoidRootPart")
   if root then setPerspectivePreset(root)end
  end
  for mode,item in pairs(perspectiveButtons)do
   item.BackgroundColor3=mode==perspectiveMode and C.PURPLE or C.PANEL
   item.TextColor3=mode==perspectiveMode and C.WHITE or C.GREY
  end
 end)
end
ct.CanvasSize=UDim2.new(0,0,0,560)
local sTog,sS=mkT("SIT KILL",196,false)sTog.Text="SIT KILL: INACTIVO"
local cameraDistanceFrame=Instance.new("Frame")
cameraDistanceFrame.Size=UDim2.new(1,0,0,34)
cameraDistanceFrame.BackgroundColor3=C.PANEL
cameraDistanceFrame.BorderSizePixel=0
cameraDistanceFrame.Parent=ct
mc(9,cameraDistanceFrame)ms(C.STROKE,1,cameraDistanceFrame)
local cameraDistanceLabel=Instance.new("TextLabel")
cameraDistanceLabel.Size=UDim2.new(1,-164,1,0)
cameraDistanceLabel.Position=UDim2.new(0,10,0,0)
cameraDistanceLabel.BackgroundTransparency=1
cameraDistanceLabel.Text="DISTANCIA CÁMARA: 0–80"
cameraDistanceLabel.TextColor3=C.GREY
cameraDistanceLabel.TextSize=11
cameraDistanceLabel.Font=Enum.Font.GothamBold
cameraDistanceLabel.TextXAlignment=Enum.TextXAlignment.Left
cameraDistanceLabel.Parent=cameraDistanceFrame
cameraDistanceInput=Instance.new("TextBox")
cameraDistanceInput.Size=UDim2.new(0,58,0,28)
cameraDistanceInput.Position=UDim2.new(1,-151,0,3)
cameraDistanceInput.BackgroundColor3=Color3.fromRGB(10,15,27)
cameraDistanceInput.TextColor3=C.WHITE
cameraDistanceInput.TextSize=12
cameraDistanceInput.Font=Enum.Font.GothamBold
cameraDistanceInput.Text=tostring(PERSPECTIVE_DEFAULT_HEIGHT)
cameraDistanceInput.PlaceholderText="0–80"
cameraDistanceInput.ClearTextOnFocus=true
cameraDistanceInput.Parent=cameraDistanceFrame
mc(7,cameraDistanceInput)ms(Color3.fromRGB(58,70,99),1,cameraDistanceInput)
local function applyCameraDistanceInput(immediate,reactivate)
 local normalized=(cameraDistanceInput.Text or ""):gsub(",",".")
 local value=tonumber(normalized)
 if value and value==value and value~=math.huge and value~=-math.huge then
  perspectiveTargetHeight=math.clamp(value,PERSPECTIVE_MIN_HEIGHT,PERSPECTIVE_MAX_HEIGHT)
  if immediate then
   if reactivate and not perspectiveActive then
    local target=selectedTarget()
    if target then startTargetPerspective(target)end
   end
   perspectiveHeight=perspectiveTargetHeight
   applyPerspectiveCameraNow()
  end
  return true
 end
 return false
end
cameraDistanceInput:GetPropertyChangedSignal("Text"):Connect(function()
 if cameraDistanceInput:IsFocused()then applyCameraDistanceInput(true)end
end)
cameraDistanceInput.FocusLost:Connect(function()
 applyCameraDistanceInput(true)
 updateCameraDistanceDisplay()
end)
local cameraDistanceApply=Instance.new("TextButton")
cameraDistanceApply.Size=UDim2.new(0,84,0,28)
cameraDistanceApply.Position=UDim2.new(1,-88,0,3)
cameraDistanceApply.BackgroundColor3=Color3.fromRGB(8,54,37)
cameraDistanceApply.Text="APLICAR"
cameraDistanceApply.TextColor3=C.GREEN
cameraDistanceApply.TextSize=10
cameraDistanceApply.Font=Enum.Font.GothamBold
cameraDistanceApply.BorderSizePixel=0
cameraDistanceApply.Parent=cameraDistanceFrame
mc(7,cameraDistanceApply)ms(Color3.fromRGB(0,180,96),1,cameraDistanceApply)
cameraDistanceApply.MouseButton1Click:Connect(function()
 local accepted=applyCameraDistanceInput(true,true)
 cameraDistanceInput:ReleaseFocus()
 updateCameraDistanceDisplay()
 cameraDistanceApply.Text=accepted and("OK: "..cameraDistanceInput.Text)or"VALOR INVÁLIDO"
 task.delay(1.2,function()if cameraDistanceApply and cameraDistanceApply.Parent then cameraDistanceApply.Text="APLICAR"end end)
end)
local skipB=Instance.new("TextButton")skipB.Size=UDim2.new(1,0,0,36)skipB.Position=UDim2.new(0,0,0,278)skipB.BackgroundColor3=Color3.fromRGB(25,57,84)skipB.Text="SIGUIENTE OBJETIVO   →"skipB.TextColor3=Color3.fromRGB(153,220,255)skipB.TextSize=11 skipB.Font=Enum.Font.GothamBold skipB.BorderSizePixel=0 skipB.Parent=ct mc(9,skipB)ms(Color3.fromRGB(44,105,144),1,skipB)
local stopB=Instance.new("TextButton")stopB.Size=UDim2.new(1,0,0,36)stopB.Position=UDim2.new(0,0,0,320)stopB.BackgroundColor3=Color3.fromRGB(69,27,40)stopB.Text="■  DETENER TODO"stopB.TextColor3=Color3.fromRGB(255,157,171)stopB.TextSize=11 stopB.Font=Enum.Font.GothamBold stopB.BorderSizePixel=0 stopB.Parent=ct mc(9,stopB)ms(Color3.fromRGB(127,49,68),1,stopB)

local resetFrame=Instance.new("Frame")
resetFrame.Size=UDim2.new(1,0,0,36)
resetFrame.Position=UDim2.new(0,0,0,362)
resetFrame.BackgroundColor3=Color3.fromRGB(22,27,46)
resetFrame.BorderSizePixel=0
resetFrame.Parent=ct
mc(9,resetFrame)
ms(C.STROKE,1,resetFrame)
local resetLabel=Instance.new("TextLabel")
resetLabel.Size=UDim2.new(1,-16,1,0)
resetLabel.Position=UDim2.new(0,8,0,0)
resetLabel.BackgroundTransparency=1
resetLabel.Text="REINICIOS: 0"
resetLabel.TextColor3=C.GREY
resetLabel.TextSize=11
resetLabel.Font=Enum.Font.GothamBold
resetLabel.TextXAlignment=Enum.TextXAlignment.Left
resetLabel.Parent=resetFrame

updateResetLabel = function()
	if selectedPlayer and selectedPlayer.Parent == P then
		resetLabel.Text = "REINICIOS: "..resetCount.."  ("..playerLabel(selectedPlayer)..")"
	else
		resetLabel.Text = "REINICIOS: 0  (ninguno)"
	end
end
updateResetLabel()

local sl=Instance.new("TextLabel")sl.Size=UDim2.new(1,0,0,30)sl.Position=UDim2.new(0,0,0,404)sl.BackgroundColor3=Color3.fromRGB(12,18,30)sl.BackgroundTransparency=0 sl.BorderSizePixel=0 sl.Text="   ●  LISTO"sl.TextColor3=Color3.fromRGB(116,207,162)sl.TextSize=10 sl.Font=Enum.Font.GothamMedium sl.TextXAlignment=Enum.TextXAlignment.Left sl.Parent=ct mc(9,sl)ms(C.STROKE,1,sl)
local rail=Instance.new("Frame")rail.Size=UDim2.new(1,-24,0,80)rail.Position=UDim2.new(0,12,0,66)rail.BackgroundColor3=Color3.fromRGB(3,14,10)rail.BorderSizePixel=0 rail.Parent=mf mc(8,rail)ms(Color3.fromRGB(20,103,70),1,rail)
local railAccent=Instance.new("Frame")railAccent.Size=UDim2.new(0,4,1,-14)railAccent.Position=UDim2.new(0,0,0,7)railAccent.BackgroundColor3=C.CYAN railAccent.BorderSizePixel=0 railAccent.Parent=rail mc(2,railAccent)mg(C.CYAN,C.PURPLE,90,railAccent)
local railTitle=Instance.new("TextLabel")railTitle.Size=UDim2.new(0,180,0,18)railTitle.Position=UDim2.new(0,12,0,4)railTitle.BackgroundTransparency=1 railTitle.Text="CONTROLES"railTitle.TextColor3=C.GREY railTitle.TextSize=11 railTitle.Font=Enum.Font.RobotoMono railTitle.TextXAlignment=Enum.TextXAlignment.Left railTitle.Parent=rail
ct.Size=UDim2.new(1,-24,1,-166)ct.Position=UDim2.new(0,12,0,154)ct.CanvasSize=UDim2.new(0,0,0,346)ct.ScrollBarThickness=3
il.Text="CONFIGURACIÓN"
flB.Parent=rail flB.Size=UDim2.new(0,154,0,42)flB.Position=UDim2.new(0,10,0,29)flB.TextWrapped=true flB.TextSize=12
skipB.Parent=rail skipB.Size=UDim2.new(0,148,0,42)skipB.Position=UDim2.new(0,174,0,29)skipB.Text="SIGUIENTE"skipB.TextColor3=C.CYAN skipB.BackgroundColor3=Color3.fromRGB(5,33,27)skipB.TextWrapped=true skipB.TextSize=12
stopB.Parent=rail stopB.Size=UDim2.new(0,164,0,42)stopB.Position=UDim2.new(0,332,0,29)stopB.Text="DETENER"stopB.TextWrapped=true stopB.TextSize=12
updateCommandLayout=function()
 local count=0
 for _,candidate in ipairs(P:GetPlayers())do if candidate~=pl and selectedPlayerIds[candidate.UserId]then count=count+1 end end
 local multiple=count>=2
 skipB.Visible=multiple
 if multiple then
  flB.Size=UDim2.new(0,154,0,42)flB.Position=UDim2.new(0,10,0,29)
  skipB.Size=UDim2.new(0,148,0,42)skipB.Position=UDim2.new(0,174,0,29)
  stopB.Size=UDim2.new(0,164,0,42)stopB.Position=UDim2.new(0,332,0,29)
 else
  flB.Size=UDim2.new(.5,-15,0,42)flB.Position=UDim2.new(0,10,0,29)
  stopB.Size=UDim2.new(.5,-15,0,42)stopB.Position=UDim2.new(.5,5,0,29)
 end
end
updateCommandLayout()
resetFrame.Parent=ct resetFrame.Size=UDim2.new(.48,0,0,30)resetFrame.Position=UDim2.new(0,0,0,314)
resetLabel.Size=UDim2.new(1,-12,1,0)resetLabel.Position=UDim2.new(0,6,0,0)resetLabel.TextSize=10 resetLabel.TextWrapped=false
sl.Parent=ct sl.Size=UDim2.new(.5,-4,0,30)sl.Position=UDim2.new(.5,4,0,314)sl.TextSize=10 sl.TextWrapped=false
modoBtn.Size=UDim2.new(.49,-4,0,34)modoBtn.Position=UDim2.new(0,0,0,70)
sTog.Size=UDim2.new(.51,-4,0,34)sTog.Position=UDim2.new(.49,4,0,70)
modoBtn.Visible=false
sTog.Visible=false
cameraDistanceFrame.Size=UDim2.new(1,0,0,34)cameraDistanceFrame.Position=UDim2.new(0,0,0,110)
depthFrame.Size=UDim2.new(1,0,0,34)depthFrame.Position=UDim2.new(0,0,0,148)
balloonFrame.Size=UDim2.new(.49,-4,0,36)balloonFrame.Position=UDim2.new(0,0,0,186)
perspectiveFrame.Size=UDim2.new(.51,-4,0,36)perspectiveFrame.Position=UDim2.new(.49,4,0,186)
local Extras=(function()
local giftEnabled=false local giftToken=0
local viewerButton=Instance.new("TextButton")viewerButton.Size=UDim2.new(1,0,0,36)viewerButton.Position=UDim2.new(0,0,0,226)viewerButton.BackgroundColor3=Color3.fromRGB(19,30,47)viewerButton.Text="VISOR DE ACCESORIOS Y HRP 3D"viewerButton.TextColor3=Color3.fromRGB(207,178,255)viewerButton.TextSize=11 viewerButton.Font=Enum.Font.GothamBold viewerButton.BorderSizePixel=0 viewerButton.Parent=ct mc(9,viewerButton)ms(Color3.fromRGB(133,82,210),1,viewerButton)
local giftButton=Instance.new("TextButton")giftButton.Size=UDim2.new(1,0,0,36)giftButton.Position=UDim2.new(0,0,0,270)giftButton.BackgroundColor3=C.PANEL giftButton.Text=""giftButton.BorderSizePixel=0 giftButton.Parent=ct mc(9,giftButton)local giftStroke=ms(C.STROKE,1,giftButton)
local giftLabel=Instance.new("TextLabel")giftLabel.Size=UDim2.new(1,-76,1,0)giftLabel.Position=UDim2.new(0,12,0,0)giftLabel.BackgroundTransparency=1 giftLabel.Text="REGALOS SCHOOLBAG"giftLabel.TextColor3=C.GREY giftLabel.TextSize=11 giftLabel.Font=Enum.Font.GothamBold giftLabel.TextXAlignment=Enum.TextXAlignment.Left giftLabel.Parent=giftButton
local giftSwitch=Instance.new("Frame")giftSwitch.Size=UDim2.new(0,48,0,24)giftSwitch.Position=UDim2.new(1,-60,.5,-12)giftSwitch.BackgroundColor3=Color3.fromRGB(35,48,43)giftSwitch.BorderSizePixel=0 giftSwitch.Parent=giftButton mc(12,giftSwitch)
local giftKnob=Instance.new("Frame")giftKnob.Size=UDim2.new(0,18,0,18)giftKnob.Position=UDim2.new(0,3,.5,-9)giftKnob.BackgroundColor3=C.GREY giftKnob.BorderSizePixel=0 giftKnob.Parent=giftSwitch mc(9,giftKnob)
for _,node in ipairs(mf:GetDescendants())do
 if node:IsA("TextLabel")or node:IsA("TextButton")or node:IsA("TextBox")then
  if node:IsA("TextButton")or node:IsA("TextBox")then node.Font=Enum.Font.GothamBold else node.Font=Enum.Font.RobotoMono end
  node.TextStrokeTransparency=1
  if node.TextSize<11 then node.TextSize=11 end
 end
end
playerBtn.Font=Enum.Font.GothamMedium
playerBtn.TextColor3=Color3.fromRGB(232,238,235)
playerBtn.TextStrokeTransparency=1
playerBtnStroke.Color=Color3.fromRGB(52,78,67)
playerBtnStroke.Transparency=.3
local viewerOpen=false
local viewerOptions={attachments=false,mesh=false,boxes=false,hrp=false}
local viewerMarkers={attachments={},mesh={},boxes={},hrp={}}
local viewerFolder=Instance.new("Folder")viewerFolder.Name="NaNLocalViewer"viewerFolder.Parent=sg
local viewerPanel=Instance.new("Frame")viewerPanel.Size=UDim2.new(0,344,0,238)viewerPanel.Position=UDim2.new(.5,-172,.5,-119)viewerPanel.BackgroundColor3=C.BG viewerPanel.BorderSizePixel=0 viewerPanel.Visible=false viewerPanel.ZIndex=200 viewerPanel.Parent=mf mc(10,viewerPanel)ms(Color3.fromRGB(133,82,210),1,viewerPanel)
local viewerTitle=Instance.new("TextLabel")viewerTitle.Size=UDim2.new(1,-52,0,42)viewerTitle.Position=UDim2.new(0,14,0,4)viewerTitle.BackgroundTransparency=1 viewerTitle.Text="VISOR LOCAL 3D"viewerTitle.TextColor3=Color3.fromRGB(207,178,255)viewerTitle.TextSize=14 viewerTitle.Font=Enum.Font.GothamBold viewerTitle.TextXAlignment=Enum.TextXAlignment.Left viewerTitle.ZIndex=201 viewerTitle.Parent=viewerPanel
local viewerClose=Instance.new("TextButton")viewerClose.Size=UDim2.new(0,32,0,32)viewerClose.Position=UDim2.new(1,-40,0,8)viewerClose.BackgroundColor3=Color3.fromRGB(49,24,35)viewerClose.Text="X"viewerClose.TextColor3=Color3.fromRGB(255,117,135)viewerClose.TextSize=13 viewerClose.Font=Enum.Font.GothamBold viewerClose.BorderSizePixel=0 viewerClose.ZIndex=201 viewerClose.Parent=viewerPanel mc(8,viewerClose)
local viewerInfo=Instance.new("TextLabel")viewerInfo.Size=UDim2.new(1,-28,0,32)viewerInfo.Position=UDim2.new(0,14,0,42)viewerInfo.BackgroundTransparency=1 viewerInfo.Text="Usa la selección actual; sin selección muestra tu personaje."viewerInfo.TextWrapped=true viewerInfo.TextColor3=C.GREY viewerInfo.TextSize=10 viewerInfo.Font=Enum.Font.RobotoMono viewerInfo.TextXAlignment=Enum.TextXAlignment.Left viewerInfo.ZIndex=201 viewerInfo.Parent=viewerPanel
local viewerColors={attachments=Color3.fromRGB(255,74,88),hrpAttachments=Color3.fromRGB(65,145,255),hrpCenter=Color3.fromRGB(65,255,110),mesh=Color3.fromRGB(65,145,255),boxes=Color3.fromRGB(65,255,110),hrp=Color3.fromRGB(196,74,255)}
local viewerButtons={}
local viewerNames={attachments="ATTACHMENTS",mesh="MALLA 3D",boxes="HANDLE BOX",hrp="HRP 3D"}
for index,key in ipairs({"attachments","mesh","boxes","hrp"})do
 local button=Instance.new("TextButton")button.Size=UDim2.new(.5,-21,0,38)button.Position=UDim2.new((index-1)%2*.5,index%2==1 and 14 or 7,0,index<=2 and 82 or 126)button.BackgroundColor3=C.PANEL button.Text=viewerNames[key].." - OFF"button.TextColor3=viewerColors[key]button.TextSize=mob and 10 or 11 button.Font=Enum.Font.GothamMedium button.TextStrokeTransparency=1 button.BorderSizePixel=0 button.AutoButtonColor=false button.ZIndex=201 button.Parent=viewerPanel mc(8,button)viewerButtons[key]=button
end
local viewerStatus=Instance.new("TextLabel")viewerStatus.Size=UDim2.new(1,-28,0,38)viewerStatus.Position=UDim2.new(0,14,0,178)viewerStatus.BackgroundColor3=C.PANEL viewerStatus.Text="  MARCADORES: 0"viewerStatus.TextColor3=C.GREY viewerStatus.TextSize=10 viewerStatus.Font=Enum.Font.RobotoMono viewerStatus.TextXAlignment=Enum.TextXAlignment.Left viewerStatus.ZIndex=201 viewerStatus.Parent=viewerPanel mc(8,viewerStatus)ms(C.STROKE,1,viewerStatus)
local function viewerRemove(group,object)local marker=group[object]if marker then marker:Destroy()group[object]=nil end end
local function viewerClear()for _,group in pairs(viewerMarkers)do for object in pairs(group)do viewerRemove(group,object)end end viewerStatus.Text="  MARCADORES: 0"end
local function viewerTargets()local targets={}for _,candidate in ipairs(P:GetPlayers())do if candidate~=pl and selectedPlayerIds[candidate.UserId]then table.insert(targets,candidate)end end if #targets==0 then targets[1]=pl end return targets end
local function viewerContainer(object,character)local current=object while current and current~=character do if current:IsA("Accessory")or current:IsA("Accoutrement")or current:IsA("Tool")then return current end current=current.Parent end end
local function viewerUpdate()
 if closing or not viewerOpen then return end
 local valid={attachments={},mesh={},boxes={},hrp={}}local count=0
 for _,player in ipairs(viewerTargets())do local character=player.Character local hrp=character and character:FindFirstChild("HumanoidRootPart")if character then
  for _,object in ipairs(character:GetDescendants())do
   if viewerOptions.attachments and object:IsA("Attachment")and not object:IsA("Bone")then local part=object.Parent while part and not part:IsA("BasePart")do part=part.Parent end local container=viewerContainer(object,character)if part and(part==hrp or container)then valid.attachments[object]=true local marker=viewerMarkers.attachments[object]if not marker then marker=Instance.new("SphereHandleAdornment")marker.Name="AttachmentPoint"marker.Adornee=part marker.Radius=part==hrp and .13 or .10 marker.CFrame=part.CFrame:ToObjectSpace(object.WorldCFrame)marker.Color3=part==hrp and viewerColors.hrpAttachments or viewerColors.attachments marker.Transparency=0 marker.AlwaysOnTop=true marker.ZIndex=5 marker.Parent=viewerFolder viewerMarkers.attachments[object]=marker end count+=1 end end
   if object:IsA("BasePart")then local container=viewerContainer(object,character)if container then
    if viewerOptions.mesh and(object:IsA("MeshPart")or object:IsA("UnionOperation")or object:FindFirstChildWhichIsA("DataModelMesh"))then valid.mesh[object]=true if not viewerMarkers.mesh[object]then local marker=Instance.new("Highlight")marker.Name="MeshHighlight"marker.Adornee=object marker.FillColor=viewerColors.mesh marker.FillTransparency=.82 marker.OutlineColor=viewerColors.mesh marker.OutlineTransparency=.05 marker.DepthMode=Enum.HighlightDepthMode.Occluded marker.Parent=viewerFolder viewerMarkers.mesh[object]=marker end count+=1 end
    if viewerOptions.boxes then valid.boxes[object]=true if not viewerMarkers.boxes[object]then local marker=Instance.new("SelectionBox")marker.Name="HandleBox"marker.Adornee=object marker.Color3=viewerColors.boxes marker.LineThickness=.025 marker.SurfaceTransparency=1 marker.Transparency=.1 marker.Parent=viewerFolder viewerMarkers.boxes[object]=marker end count+=1 end
   end end
  end
  if viewerOptions.attachments and hrp and hrp:IsA("BasePart")then local key=hrp valid.attachments[key]=true if not viewerMarkers.attachments[key]then local marker=Instance.new("SphereHandleAdornment")marker.Name="HRPCenter"marker.Adornee=hrp marker.Radius=.13 marker.CFrame=CFrame.new()marker.Color3=viewerColors.hrpCenter marker.AlwaysOnTop=true marker.ZIndex=6 marker.Parent=viewerFolder viewerMarkers.attachments[key]=marker end count+=1 end
  if viewerOptions.hrp and hrp and hrp:IsA("BasePart")then valid.hrp[hrp]=true local marker=viewerMarkers.hrp[hrp]if not marker then marker=Instance.new("BoxHandleAdornment")marker.Name="HRP3D"marker.Adornee=hrp marker.Size=hrp.Size marker.CFrame=CFrame.new()marker.Color3=viewerColors.hrp marker.Transparency=.48 marker.AlwaysOnTop=true marker.ZIndex=2 marker.Parent=viewerFolder viewerMarkers.hrp[hrp]=marker else marker.Size=hrp.Size end count+=1 end
 end end
 for key,group in pairs(viewerMarkers)do for object in pairs(group)do if not valid[key][object]then viewerRemove(group,object)end end end
 viewerStatus.Text="  MARCADORES: "..count.."  |  JUGADORES: "..#viewerTargets()
end
for key,button in pairs(viewerButtons)do button.MouseButton1Click:Connect(function()viewerOptions[key]=not viewerOptions[key]button.Text=viewerNames[key]..(viewerOptions[key]and" - ON"or" - OFF")button.BackgroundColor3=viewerOptions[key]and Color3.fromRGB(29,55,44)or C.PANEL viewerUpdate()end)end
viewerButton.MouseButton1Click:Connect(function()viewerOpen=true viewerPanel.Visible=true viewerUpdate()end)
viewerClose.MouseButton1Click:Connect(function()viewerOpen=false viewerPanel.Visible=false viewerClear()end)
local viewerElapsed=0
local viewerConn=R.Heartbeat:Connect(function(dt)viewerElapsed+=dt if viewerElapsed>=.25 then viewerElapsed=0 viewerUpdate()end end)
local giftRecipientIndex=1
local giftReadyAt={}
local function giftVisual(enabled,state)
 giftLabel.Text="REGALOS SCHOOLBAG  ·  "..(state or(enabled and"ON"or"OFF"))
 giftLabel.TextColor3=enabled and C.WHITE or C.GREY
 giftButton.BackgroundColor3=enabled and Color3.fromRGB(8,54,37)or C.PANEL
 giftStroke.Color=enabled and C.PURPLE or C.STROKE
 giftSwitch.BackgroundColor3=enabled and Color3.fromRGB(0,166,91)or Color3.fromRGB(35,48,43)
 T:Create(giftKnob,TweenInfo.new(.16),{Position=enabled and UDim2.new(0,27,.5,-9)or UDim2.new(0,3,.5,-9),BackgroundColor3=enabled and C.WHITE or C.GREY}):Play()
end
local function giftStop()
 giftEnabled=false giftToken+=1 giftVisual(false,"OFF")
end
local function giftSelectedPlayers()
 local result={}
 for _,candidate in ipairs(P:GetPlayers())do if candidate~=pl and selectedPlayerIds[candidate.UserId]then result[#result+1]=candidate end end
 return result
end
local function giftCountSchoolBag()
 local count=0 local backpack=pl:FindFirstChildOfClass("Backpack")
 for _,container in ipairs({backpack,pl.Character})do if container then for _,item in ipairs(container:GetChildren())do if item:IsA("Tool")and item.Name=="SchoolBag"then count+=1 end end end end
 return count
end
local function giftStart()
 local recipients=giftSelectedPlayers()
 if #recipients==0 then return false,"selecciona al menos un jugador"end
 local replicated=game:GetService("ReplicatedStorage")local remotes=replicated:FindFirstChild("Remotes")
 local equipRF=remotes and remotes:FindFirstChild("EquipToolRF")local giftRE=remotes and remotes:FindFirstChild("InteractGiftRE")
 if not equipRF or not giftRE then return false,"remotos de regalos no disponibles"end
 giftToken+=1 local token=giftToken giftEnabled=true giftVisual(true,"ON")
 task.spawn(function()
  local lastRequest=-math.huge
  while giftEnabled and giftToken==token and not closing do
   recipients=giftSelectedPlayers()
   if #recipients==0 then giftVisual(true,"ESPERANDO JUGADORES")task.wait(.15)continue end
   if giftRecipientIndex>#recipients then giftRecipientIndex=1 end
   local recipient=nil
   for _=1,#recipients do local candidate=recipients[giftRecipientIndex]giftRecipientIndex=giftRecipientIndex%#recipients+1 if candidate and candidate.Parent==P and os.clock()>=(giftReadyAt[candidate.UserId]or 0)then recipient=candidate break end end
   if not recipient then giftVisual(true,"ESPERANDO")task.wait(.1)continue end
   if giftCountSchoolBag()==0 then
    giftVisual(true,"OBTENIENDO SCHOOLBAG")
    local ok,result=pcall(function()return equipRF:InvokeServer("SchoolBag")end)
    if not giftEnabled or giftToken~=token then break end
    if not ok then giftVisual(true,"ERROR AL OBTENER")task.wait(.4)continue end
    if result==false then task.wait(.05)continue end
    local deadline=os.clock()+4
    while giftEnabled and giftToken==token and giftCountSchoolBag()==0 and os.clock()<deadline do task.wait(.05)end
    if giftCountSchoolBag()==0 then task.wait(.05)continue end
   end
   local gap=.15-(os.clock()-lastRequest)if gap>0 then task.wait(gap)end
   if not giftEnabled or giftToken~=token or recipient.Parent~=P then continue end
   giftVisual(true,"ENVIANDO A @"..recipient.Name)
   pcall(function()giftRE:FireServer({Action="GiveGift",TargetUserId=recipient.UserId,ToolId="SchoolBag",GiftBox="GiftBox5"})end)
   lastRequest=os.clock()giftReadyAt[recipient.UserId]=lastRequest+4.25
   task.wait()
  end
  if giftToken==token then giftStop()end
 end)
 return true
end
return{GiftButton=giftButton,IsGiftEnabled=function()return giftEnabled end,StartGift=giftStart,StopGift=giftStop,GiftVisual=giftVisual,Close=function()
 giftStop()viewerOpen=false viewerClear()
 if viewerConn then viewerConn:Disconnect()viewerConn=nil end
end}
end)()
local confirmShade=Instance.new("Frame")confirmShade.Size=UDim2.new(1,0,1,0)confirmShade.BackgroundColor3=Color3.fromRGB(0,0,0)confirmShade.BackgroundTransparency=0.2 confirmShade.BorderSizePixel=0 confirmShade.Active=true confirmShade.Visible=false confirmShade.ZIndex=300 confirmShade.Parent=mf
local confirmBox=Instance.new("Frame")confirmBox.Size=UDim2.new(0,300,0,150)confirmBox.Position=UDim2.new(0.5,-150,0.5,-75)confirmBox.BackgroundColor3=C.PANEL confirmBox.BorderSizePixel=0 confirmBox.ZIndex=301 confirmBox.Parent=confirmShade mc(10,confirmBox)ms(C.PURPLE,2,confirmBox)
local confirmTitle=Instance.new("TextLabel")confirmTitle.Size=UDim2.new(1,-24,0,58)confirmTitle.Position=UDim2.new(0,12,0,12)confirmTitle.BackgroundTransparency=1 confirmTitle.Text="¿ESTÁS SEGURO?\nSe detendrán y limpiarán todos los flujos."confirmTitle.TextWrapped=true confirmTitle.TextColor3=C.WHITE confirmTitle.TextSize=14 confirmTitle.Font=Enum.Font.GothamBold confirmTitle.ZIndex=302 confirmTitle.Parent=confirmBox
local confirmYes=Instance.new("TextButton")confirmYes.Size=UDim2.new(0.5,-18,0,42)confirmYes.Position=UDim2.new(0,12,1,-54)confirmYes.BackgroundColor3=C.RED confirmYes.Text="SÍ, CERRAR"confirmYes.TextColor3=C.WHITE confirmYes.TextSize=12 confirmYes.Font=Enum.Font.GothamBold confirmYes.BorderSizePixel=0 confirmYes.ZIndex=302 confirmYes.Parent=confirmBox mc(6,confirmYes)
local confirmNo=Instance.new("TextButton")confirmNo.Size=UDim2.new(0.5,-18,0,42)confirmNo.Position=UDim2.new(0.5,6,1,-54)confirmNo.BackgroundColor3=C.DIM confirmNo.Text="NO"confirmNo.TextColor3=C.WHITE confirmNo.TextSize=12 confirmNo.Font=Enum.Font.GothamBold confirmNo.BorderSizePixel=0 confirmNo.ZIndex=302 confirmNo.Parent=confirmBox mc(6,confirmNo)
local function ss(t)
 if t=="idle"then sl.Text="   ●  LISTO"sl.TextColor3=Color3.fromRGB(116,207,162)
 else sl.Text="   ●  "..string.upper(tostring(t))sl.TextColor3=C.GREY end
end
local function placeBalloonForTarget(target,runToken,itemName,targetCharacter,cycleValid)
 local function valid()
  return cE and runToken==cToken and target==selectedTarget()and target.Parent==P and target.Character==targetCharacter and cycleValid()
 end
 while valid()do
  while valid()do
   local character=gc()
   local root=character and character:FindFirstChild("HumanoidRootPart")
   local targetRoot=targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
   if not root or not targetRoot then return false,"objetivo no disponible"end
   if(root.Position-targetRoot.Position).Magnitude<=math.max(.5,cinturaDepth+.5)then break end
   R.Heartbeat:Wait()
  end
  if not valid()then return false,"cancelado"end
  local remotes=game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
  local equipRemote=remotes and remotes:FindFirstChild("EquipToolRF")
  if not equipRemote or not equipRemote:IsA("RemoteFunction")then ss("conexión para equipar no disponible")return false,"conexión no disponible"end
  ss("solicitando "..itemName.." para "..target.Name.."...")
  local ok,result=pcall(function()return equipRemote:InvokeServer(itemName)end)
  if not ok or result==false then ss("reintentando "..itemName.."...")task.wait(.5)continue end
  local deadline=tick()+5
  local tool=nil
  while valid()and tick()<deadline do
   local character=gc()
   local backpack=pl:FindFirstChildOfClass("Backpack")
   tool=(character and character:FindFirstChild(itemName))or(backpack and backpack:FindFirstChild(itemName))
   if tool and tool:IsA("Tool")then
    if tool.Parent~=character then
     local humanoid=character and character:FindFirstChildOfClass("Humanoid")
     if not humanoid then return false,"personaje no disponible"end
     if not pcall(function()humanoid:EquipTool(tool)end)then tool=nil break end
    end
    if tool.Parent==character then break end
   end
   R.Heartbeat:Wait()
  end
  if not valid()then return false,"cancelado"end
  if not tool or tool.Parent~=gc()then ss("el globo no llegó; reintentando...")task.wait(.35)continue end
  ss("esperando colocación en "..target.Name.."...")
  while valid()do
   local character=gc()
   local backpack=pl:FindFirstChildOfClass("Backpack")
   if tool.Parent~=character and tool.Parent~=backpack then ss("objeto colocado en "..target.Name)return true,"colocado"end
   R.Heartbeat:Wait()
  end
  return false,"cancelado"
 end
 return false,"cancelado"
end
local function removeEquippedBalloonBeforeReturn()
 local character=gc()
 if not character then return true end
 local tool=character:FindFirstChild("ValentineBalloon")or character:FindFirstChild("NewYearBalloon")
 if not tool or not tool:IsA("Tool")then return true end
 local remotes=game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
 local clearRemote=remotes and remotes:FindFirstChild("ClearToolRE")
 if not clearRemote or not clearRemote:IsA("RemoteEvent")then ss("conexión de limpieza no disponible")return false end
 ss("retirando globo antes de regresar...")
 for attempt=1,3 do
  if not tool.Parent then return true end
  local ok=pcall(function()clearRemote:FireServer(true)end)
  if not ok then return false end
  local deadline=tick()+1.5
  while tool.Parent and tick()<deadline do R.Heartbeat:Wait()end
  if not tool.Parent then ss("globo retirado")return true end
  if attempt<3 then task.wait(.25)end
 end
 ss("no se confirmó la retirada del globo")
 return false
end
local function clearHeldObjectThenReturn(returnNow)
 task.spawn(function()
  removeEquippedBalloonBeforeReturn()
  if returnNow then returnNow()end
 end)
end
local launcherSize=mob and 50 or 60
local mB=Instance.new("TextButton")mB.Size=UDim2.new(0,launcherSize,0,launcherSize)mB.Position=UDim2.new(0,20,0.5,-launcherSize/2)mB.BackgroundColor3=Color3.fromRGB(2,15,10)mB.Text=""mB.AutoButtonColor=false mB.BorderSizePixel=0 mB.ClipsDescendants=true mB.Visible=false mB.ZIndex=100 mB.Parent=sg mc(mob and 11 or 14,mB)ms(Color3.fromRGB(0,220,116),2,mB)
local mBTitle=Instance.new("TextLabel")mBTitle.Size=UDim2.new(1,0,1,0)mBTitle.BackgroundTransparency=1 mBTitle.Text="Abrir"mBTitle.TextColor3=C.WHITE mBTitle.TextSize=mob and 10 or 12 mBTitle.Font=Enum.Font.GothamBold mBTitle.TextStrokeColor3=Color3.fromRGB(0,22,12)mBTitle.TextStrokeTransparency=.25 mBTitle.ZIndex=103 mBTitle.Parent=mB
for column=1,3 do
 local digits=Instance.new("TextLabel")digits.Size=UDim2.new(0,14,0,90)digits.Position=UDim2.new(0,5+(column-1)*18,0,-90-math.random(0,40))digits.BackgroundTransparency=1 digits.Text="0\n1\n1\n0\n1"digits.TextColor3=Color3.fromRGB(0,255,136)digits.TextTransparency=.55 digits.TextSize=9 digits.Font=Enum.Font.RobotoMono digits.TextYAlignment=Enum.TextYAlignment.Top digits.ZIndex=101 digits.Parent=mB
 task.spawn(function()while digits.Parent do digits.Position=UDim2.new(0,5+(column-1)*18,0,-95-math.random(0,35))local tween=T:Create(digits,TweenInfo.new(3.5+math.random()*2.5,Enum.EasingStyle.Linear),{Position=UDim2.new(0,5+(column-1)*18,1,8)})tween:Play()tween.Completed:Wait()end end)
end
local dr,ds,sp
local function isInteractivePoint(position)
 local ok,objects=pcall(function()return pg:GetGuiObjectsAtPosition(position.X,position.Y)end)
 if not ok then return false end
 for _,object in ipairs(objects)do
  local current=object
  while current and current~=mf do
   if current:IsA("TextButton")or current:IsA("TextBox")then return true end
   current=current.Parent
  end
 end
 return false
end
local function beginDrag(i)
if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end
 if isInteractivePoint(i.Position)then return end
 dr=true ds=i.Position sp=mf.Position ct.ScrollingEnabled=false
 i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then dr=false ct.ScrollingEnabled=true end end)
end
for _,dragSurface in ipairs({mf,tb,ct,rail,matrixLayer})do dragSurface.InputBegan:Connect(beginDrag)end
dragInputConn=U.InputChanged:Connect(function(i)
if not dr or(i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch)then return end
local d=i.Position-ds
mf.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
end)
local nY=-10
local function nt(t,m,d)d=d or 3 local n=Instance.new("Frame")n.Size=UDim2.new(0,260,0,56)n.Position=UDim2.new(1,10,1,nY-56)n.BackgroundColor3=C.PANEL n.BorderSizePixel=0 n.ZIndex=200 n.Parent=sg mc(6,n)ms(C.PURPLE,1,n)local a=Instance.new("TextLabel")a.Size=UDim2.new(1,-12,0,20)a.Position=UDim2.new(0,10,0,6)a.BackgroundTransparency=1 a.Text=t a.TextColor3=C.WHITE a.TextSize=12 a.Font=Enum.Font.GothamBold a.TextXAlignment=Enum.TextXAlignment.Left a.ZIndex=201 a.Parent=n local b=Instance.new("TextLabel")b.Size=UDim2.new(1,-12,0,20)b.Position=UDim2.new(0,10,0,28)b.BackgroundTransparency=1 b.Text=m b.TextColor3=C.GREY b.TextSize=11 b.Font=Enum.Font.Gotham b.TextXAlignment=Enum.TextXAlignment.Left b.TextWrapped=true b.ZIndex=201 b.Parent=n T:Create(n,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(1,-270,1,nY-56)}):Play()task.delay(d,function()T:Create(n,TweenInfo.new(0.25),{Position=UDim2.new(1,10,1,nY-56)}):Play()task.wait(0.3)n:Destroy()end)end
local matar

local SIT={
VOID_DEPTH=220,
OWN_TRIES=3,
OWN_FRAMES=3,
DRAG_TIME=0.45,
HOLD_TIME=0.85,
CONFIRM_TIMEOUT=2.0,
MAX_ATTEMPTS=10,
RETRY_DELAYS={0.20,0.25,0.30,0.35,0.40,0.45,0.50,0.55,0.60},
COOLDOWN=0.60,
MAX_ATTEMPTS_PER_TARGET=16,
RESET_RELEASE=0.35,
}
local function sitOwns(character)
local root=character and character:FindFirstChild("HumanoidRootPart")
if not root then return false end
local ok,owner=pcall(function()return root:GetNetworkOwner()end)
return ok and owner==pl
end
local function sitOwnRoot(character,root)
if not root or not root.Parent then return false end
if root.Anchored then pcall(function()root.Anchored=false end)end
pcall(function()root:SetNetworkOwner(pl)end)
if sitOwns(character)then return true end
pcall(function()root:SetNetworkOwner(nil)end)
R.Heartbeat:Wait()
if not root.Parent then return false end
if root.Anchored then pcall(function()root.Anchored=false end)end
pcall(function()root:SetNetworkOwner(pl)end)
return sitOwns(character)
end
local function sitOwnAll(character)
local ok=false
for _,p in ipairs(character:GetDescendants())do
if p:IsA("BasePart")then
if p.Anchored then pcall(function()p.Anchored=false end)end
if pcall(function()p:SetNetworkOwner(pl)end)then ok=true end
end
end
return ok
end
local function sitTakeOwnership(character,root)
for _=1,SIT.OWN_TRIES do
if sitOwnRoot(character,root)then return true end
R.Heartbeat:Wait()
end
return false
end
local function sitSnap(character)
local snap={}
for _,p in ipairs(character:GetDescendants())do
if p:IsA("BasePart")then snap[p]={p.Anchored,p.CanCollide,p.Massless,p.CFrame}end
end
return snap
end
local function sitFree(character)
for _,p in ipairs(character:GetDescendants())do
if p:IsA("BasePart")then
pcall(function()p.Anchored=false end)
pcall(function()p.CanCollide=false end)
pcall(function()p.Massless=true end)
end
end
pcall(function()
for _,m in ipairs(character:GetDescendants())do
if m:IsA("Motor6D")then m.Enabled=true end
end
end)
for _,s in ipairs(character:GetDescendants())do
local w=s:FindFirstChild("SeatWeld")
if w and w:IsA("Weld")then pcall(function()w:Destroy()end)end
end
end
local function sitRestore(snap)
for p,s in pairs(snap)do
if p and p.Parent then
pcall(function()p.CanCollide=s[2]end)
pcall(function()p.Massless=s[3]end)
pcall(function()p.CFrame=s[4]end)
pcall(function()p.Anchored=s[1]end)
end
end
end
local function sitDead(ch,hum)
if not ch or not ch.Parent then return true end
if not hum or not hum.Parent then return true end
if hum.Health<=0 then return true end
local ok,name=pcall(function()return hum:GetState().Name end)
return ok and name=="Dead"
end
matar=function(ch,tp,vehicleToken)
local function active()return sE end
if not active()then return end
if not tp or tp~=selectedTarget()or ch~=tp.Character then return end
if not ch or not ch.Parent then return end
local hrp=ch:FindFirstChild("HumanoidRootPart")
local hum=ch:FindFirstChildOfClass("Humanoid")
if not hrp or not hum then return end
task.spawn(function()
local effectMode="ORIGINAL"
local useHealth,useDamage,useDead=true,true,true
local function valid()return active()and tp==selectedTarget()and ch==tp.Character and ch.Parent and hrp.Parent end
local snap=sitSnap(ch)
local oldMax=hum.MaxHealth
local oldWalk=hum.WalkSpeed
local killed=false
local ownedOk=0
for attempt=1,SIT.MAX_ATTEMPTS do
if not valid()then break end
pcall(function()hum.Sit=false end)
pcall(function()hum.PlatformStand=true end)
pcall(function()hum:ChangeState(Enum.HumanoidStateType.GettingUp)end)
pcall(function()hum.WalkSpeed=0 end)
pcall(function()hum.BreakJointsOnDeath=true end)
pcall(function()hum.MaxHealth=math.huge end)
sitFree(ch)
sitOwnAll(ch)
local owned=sitTakeOwnership(ch,hrp)
if not valid()then break end
if owned then ownedOk=ownedOk+1 end
local anchor=grp()
local base=anchor and anchor.Position or hrp.Position
local voidPos=Vector3.new(base.X,base.Y-SIT.VOID_DEPTH,base.Z)
local dragUntil=tick()+SIT.DRAG_TIME
while tick()<dragUntil do
if not valid()then break end
sitOwnRoot(ch,hrp)
hrp.CFrame=CFrame.new(voidPos)
hrp.AssemblyLinearVelocity=Vector3.new(0,-50000,0)
hrp.AssemblyAngularVelocity=Vector3.new(99999,99999,99999)
R.Heartbeat:Wait()
end
if not valid()then break end
for _=1,SIT.OWN_FRAMES do
if not valid()then break end
pcall(function()hrp.Anchored=true end)
hrp.CFrame=CFrame.new(voidPos)
hrp.AssemblyLinearVelocity=Vector3.zero
hrp.AssemblyAngularVelocity=Vector3.zero
if useDamage then
for _,ff in ipairs(ch:GetChildren())do
if ff:IsA("ForceField")then pcall(function()ff:Destroy()end)end
end
pcall(function()hum:TakeDamage(math.huge)end)
end
if useHealth then pcall(function()hum.Health=0 end)end
if useDead then pcall(function()hum:ChangeState(Enum.HumanoidStateType.Dead)end)end
R.Heartbeat:Wait()
end
if not valid()then break end
pcall(function()ch:BreakJoints()end)
local confirmUntil=tick()+SIT.CONFIRM_TIMEOUT
local holdUntil=tick()+SIT.HOLD_TIME
while tick()<confirmUntil do
if sitDead(ch,hum)then killed=true break end
if not valid()then killed=true break end
if tick()<holdUntil then
pcall(function()hrp.Anchored=true end)
hrp.CFrame=CFrame.new(voidPos)
hrp.AssemblyLinearVelocity=Vector3.zero
hrp.AssemblyAngularVelocity=Vector3.zero
else
pcall(function()hrp.Anchored=false end)
if hum.Health>0 then
if useDamage then pcall(function()hum:TakeDamage(math.huge)end)end
if useHealth then pcall(function()hum.Health=0 end)end
end
end
R.Heartbeat:Wait()
end
local okState,stateName=pcall(function()return hum:GetState().Name end)
if killed then break end
if attempt<SIT.MAX_ATTEMPTS then
pcall(function()hrp.Anchored=false end)
task.wait(SIT.RETRY_DELAYS[math.min(attempt,#SIT.RETRY_DELAYS)])
end
end
if killed then
pcall(function()hrp.Anchored=false end)
task.wait(SIT.RESET_RELEASE)
nt("SIT KILL",tp.Name)
else
sitRestore(snap)
pcall(function()hum.MaxHealth=oldMax end)
pcall(function()hum.WalkSpeed=oldWalk end)
pcall(function()hum.PlatformStand=false end)
pcall(function()hum.Sit=false end)
nt("SIT KILL FALLÓ",tp.Name.." ("..SIT.MAX_ATTEMPTS.." intentos, "..ownedOk.." con red)",3)
end
end)
end
local function sitPerform(tch,tp,state)
local function finish(ok)
if mt[tp]==state then
state.busy=false
if ok then state.attempts=0 end
end
end
if not sE or tp~=selectedTarget()or tch~=tp.Character then return finish(false)end
local ch=gc()
local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
local thrp=tch and tch:FindFirstChild("HumanoidRootPart")
local thum=tch and tch:FindFirstChildOfClass("Humanoid")
if not hrp or not thrp or not thum then return finish(false)end
local function valid()return sE and tp==selectedTarget()and tch==tp.Character and tch.Parent and thrp.Parent end
local owned=sitTakeOwnership(tch,thrp)
if not valid()then return finish(false)end
sitFree(tch)
pcall(function()thum.Sit=false end)
pcall(function()thum:ChangeState(Enum.HumanoidStateType.GettingUp)end)
local deadline=tick()+0.9
local seated=false
while tick()<deadline do
if not valid()then return finish(false)end
sitOwnRoot(tch,thrp)
thrp.CFrame=hrp.CFrame*CFrame.new(0,1.2,-2.5)
thrp.AssemblyLinearVelocity=Vector3.zero
thrp.AssemblyAngularVelocity=Vector3.zero
pcall(function()thum.Sit=true end)
pcall(function()thum:ChangeState(Enum.HumanoidStateType.Seated)end)
R.Heartbeat:Wait()
local ok,name=pcall(function()return thum:GetState().Name end)
if ok and name=="Seated"then seated=true break end
end
if not valid()then return finish(false)end
matar(tch,tp)
finish(true)
end
local function startSit()
if sC then sC:Disconnect()end
sE=true mt={}
sC=R.Heartbeat:Connect(function()
if not sE or closing then return end
local tp=selectedTarget()if not tp then return end
local ch=gc()
local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
local tch=tp.Character
local thrp=tch and tch:FindFirstChild("HumanoidRootPart")
local thum=tch and tch:FindFirstChildOfClass("Humanoid")
if not hrp or not thrp or not thum then return end
local dist=(hrp.Position-thrp.Position).Magnitude
if dist>C.SIT_RADIUS or dist<0.15 then return end
local state=mt[tp]
if type(state)~="table"or state.character~=tch then
state={character=tch,busy=false,attempts=0,lastAttempt=0}
mt[tp]=state
end
if state.busy then return end
if tick()-state.lastAttempt>20 then state.attempts=0 end
if state.attempts>=SIT.MAX_ATTEMPTS_PER_TARGET then return end
local cooldown=SIT.COOLDOWN
if tick()-state.lastAttempt<cooldown then return end
state.busy=true state.lastAttempt=tick()state.attempts=state.attempts+1
task.spawn(function()sitPerform(tch,tp,state)end)
end)
ss("efecto sentado activo")
nt("SIT KILL","ataque con confirmación")
end
local function stopSit()
sE=false if sC then sC:Disconnect()sC=nil end mt={}ss("idle")nt("SIT KILL","inactivo",2)
end

local function startFollow(tp,runToken,character,root,origin)
 stopFollow()
 if not cE or not runToken or runToken~=cToken or not root or not root.Parent then return false end
 followActive=true
 followOrigin=origin
 followConn=R.Heartbeat:Connect(function()
  if closing or not cE or runToken~=cToken or tp~=selectedTarget() or character~=gc() or not root.Parent then
   stopFollow()
   return
  end
  local targetChar=tp.Character
  local targetRoot=targetChar and targetChar:FindFirstChild("HumanoidRootPart")
  if not targetRoot or not targetRoot.Parent or not targetChar.Parent then
   stopFollow()
    ss("objetivo sin HRP: esperando reaparición...")
   return
  end
  local desired=targetRoot.Position-Vector3.new(0,cinturaDepth,0)
  root.CFrame=CFrame.new(desired)*CFrame.Angles(-math.pi/2,0,0)
  root.AssemblyLinearVelocity=Vector3.zero
  root.AssemblyAngularVelocity=Vector3.zero
 end)
 return true
end
local function fling(tp,fromTouch,runToken)
if not tp or tp==pl or tp~=selectedTarget()then return end
if AF[tp]then return end
if fromTouch and tCd[tp]then if tick()-tCd[tp]<C.TOUCH_COOLDOWN then return end end
local ch=gc()local trc=tp.Character if not ch or not trc then return end
local hrp=ch:FindFirstChild("HumanoidRootPart")local hum=ch:FindFirstChildOfClass("Humanoid")local thrp=trc:FindFirstChild("HumanoidRootPart")local thum=trc:FindFirstChildOfClass("Humanoid")
if not hrp or not hum or not thrp then return end
AF[tp]=true if fromTouch then tCd[tp]=tick()end
local savedPos=hrp.CFrame
ss("fling "..tp.Name.." ["..modo.."]")nt("NaN "..modo,tp.Name,2)
hum.PlatformStand=true
for _,v in ipairs(ch:GetDescendants())do if v:IsA("BasePart")then v.CanCollide=false v.Massless=true end end
hrp.CanCollide=true
for _,v in ipairs(trc:GetDescendants())do if v:IsA("BasePart")then pcall(function()v:SetNetworkOwner(pl)end)end end
local NaN=0/0
local NaNVec=Vector3.new(NaN,NaN,NaN)
local st=tick()
local steps=0
local cn
cn=R.Heartbeat:Connect(function()
steps=steps+1
local elapsed=tick()-st
local cycleDone=elapsed>=C.FLING_DURATION
if closing or cycleDone or(fromTouch and not tE)or not ch.Parent or not trc.Parent or tp~=selectedTarget()or tp.Character~=trc or(runToken and(not cE or runToken~=cToken))then
cn:Disconnect()AF[tp]=nil
if cycleDone and modo=="CINTURA" and runToken and cE and runToken==cToken and not closing and tp==selectedTarget() and trc.Parent and ch.Parent then
 pcall(function()sethiddenproperty(hrp,"PhysicsRepRootPart",nil)end)
 pcall(function()sethiddenproperty(hum,"MoveDirectionInternal",Vector3.zero)end)
 if hum then hum.PlatformStand=false end
 for _,v in ipairs(ch:GetDescendants())do
  if v:IsA("BasePart")then v.CanCollide=true v.Massless=false end
 end
 if startFollow(tp,runToken,ch,hrp,savedPos) then
  ss("ancla seguidora: "..cinturaDepth.." studs")
  return
 end
end
if hrp and hrp.Parent then hrp.Anchored=true end
for _,v in ipairs(ch:GetDescendants())do
if v:IsA("BasePart")then
v.CanCollide=true
v.Massless=false
v.AssemblyLinearVelocity=Vector3.zero
v.AssemblyAngularVelocity=Vector3.zero
end
end
if hum then hum.PlatformStand=false end
pcall(function()sethiddenproperty(hrp,"PhysicsRepRootPart",nil)end)
task.wait(0.2)
if hrp and hrp.Parent and savedPos then hrp.CFrame=savedPos end
task.wait(0.2)
if hrp and hrp.Parent then hrp.AssemblyLinearVelocity=Vector3.zero hrp.AssemblyAngularVelocity=Vector3.zero end
pcall(function()hrp:SetNetworkOwner(pl)end)
task.wait(0.1)
if hrp and hrp.Parent then hrp.Anchored=false end
task.wait(0.05)
if hrp and hrp.Parent then hrp.AssemblyLinearVelocity=Vector3.zero hrp.AssemblyAngularVelocity=Vector3.zero end
ss("idle")
return
end
if modo=="CINTURA" then
hrp.CFrame=CFrame.new(thrp.Position-Vector3.new(0,cinturaDepth,0))*CFrame.Angles(-math.pi/2,0,0)
hrp.AssemblyLinearVelocity=NaNVec
hrp.AssemblyAngularVelocity=NaNVec
if thum then
pcall(function()thum:Move(NaNVec)end)
pcall(function()sethiddenproperty(thum,"MoveDirectionInternal",NaNVec)end)
end
pcall(function()sethiddenproperty(hum,"MoveDirectionInternal",NaNVec)end)
elseif modo=="ROTACION" then
hrp.CFrame=CFrame.new(thrp.Position)*CFrame.Angles(math.random(-180,180)*math.pi/180,math.random(-180,180)*math.pi/180,math.random(-180,180)*math.pi/180)
hrp.AssemblyLinearVelocity=Vector3.new(math.random(-20000,20000),math.random(-20000,20000),math.random(-20000,20000))
hrp.AssemblyAngularVelocity=Vector3.new(math.random(100000,200000),math.random(100000,200000),math.random(100000,200000))
else
hrp.CFrame=CFrame.new(thrp.Position+Vector3.new(0,1,0))*CFrame.Angles(0,0,0)
hrp.AssemblyLinearVelocity=NaNVec
hrp.AssemblyAngularVelocity=NaNVec
if thum then
pcall(function()thum:Move(NaNVec)end)
end
end
pcall(function()sethiddenproperty(hrp,"PhysicsRepRootPart",thrp)end)
if thum then
if thum.Sit then thum.Sit=false end
if thum.PlatformStand==false then thum.PlatformStand=true end
end
end)
end
local function minimizar()
mz=true
T:Create(mf,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In),{Position=UDim2.new(0.5,-C.WIDTH/2,-0.5,0)}):Play()
task.wait(0.35)
mf.Visible=false
mB.Visible=true
end
minBtn.MouseButton1Click:Connect(minimizar)
mB.MouseButton1Click:Connect(function()
mz=false
mf.Visible=true
mf.Position=UDim2.new(0.5,-C.WIDTH/2,-0.5,0)
T:Create(mf,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-C.WIDTH/2,0.5,-C.HEIGHT/2)}):Play()
mB.Visible=false
end)
local function setContinuousState(enabled)
cE=enabled
flB.Text=enabled and "DESACTIVAR"or"ACTIVAR"
flB.TextColor3=enabled and C.WHITE or C.GREEN
flB.BackgroundColor3=enabled and Color3.fromRGB(118,25,45)or Color3.fromRGB(5,52,34)
flBStroke.Color=enabled and Color3.fromRGB(255,89,116)or Color3.fromRGB(0,180,96)
flBStroke.Thickness=enabled and 1.5 or 1
end
flB.MouseButton1Click:Connect(function()
if cE then
 cToken=cToken+1
 setContinuousState(false)
 activeTarget=nil
stopTargetPerspective()
stopFollow()
local returnNow=activeReturnToOrigin
clearHeldObjectThenReturn(returnNow)
tE=false
if sE then stopSit()end sS(false)sTog.Text="SIT KILL: INACTIVO"
ss("parando...")
nt("NaN FLING","parando ciclo",2)
return
end
if cCleaning then nt("AVISO","espera la limpieza final",2)return end
 local initialTargets=selectedTargetsSnapshot()
 if #initialTargets==0 then nt("AVISO","selecciona uno o más jugadores de la lista")return end
cToken=cToken+1
local myToken=cToken
local startCharacter=gc()
local startRoot=startCharacter and startCharacter:FindFirstChild("HumanoidRootPart")
local startHumanoid=startCharacter and startCharacter:FindFirstChildOfClass("Humanoid")
if not startRoot or not startHumanoid then nt("ERROR","personaje no disponible")return end
local origin=startRoot.CFrame
local originalPlatformStand=startHumanoid.PlatformStand
local originalRootAnchored=startRoot.Anchored
local returningToOrigin=false
local function restoreActivationOrigin()
 if returningToOrigin then return end
 local currentCharacter=gc()
 local currentRoot=currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
 if not currentRoot or not currentRoot.Parent then return end
 returningToOrigin=true
 local wasAnchored=currentRoot.Anchored
 pcall(function()
  currentRoot.Anchored=true
  currentRoot.AssemblyLinearVelocity=Vector3.zero
  currentRoot.AssemblyAngularVelocity=Vector3.zero
  currentRoot.CFrame=origin
 end)
 R.Heartbeat:Wait()
 pcall(function()
  currentRoot.CFrame=origin
  currentRoot.AssemblyLinearVelocity=Vector3.zero
  currentRoot.AssemblyAngularVelocity=Vector3.zero
  currentRoot.Anchored=currentRoot==startRoot and originalRootAnchored or wasAnchored
 end)
 returningToOrigin=false
end
activeReturnToOrigin=restoreActivationOrigin
local originalPartState={}
for _,part in ipairs(startCharacter:GetDescendants())do
if part:IsA("BasePart")then originalPartState[part]={part.CanCollide,part.Massless}end
end
setContinuousState(true)
 nt("NaN CONTINUO",#initialTargets.." objetivo(s)",2)
task.spawn(function()
 local targetIndex=1
 local function waitAtActivationPoint()
  stopTargetPerspective()
  stopFollow()
  if startRoot and startRoot.Parent and startCharacter==gc()then
   startRoot.Anchored=true
   startRoot.AssemblyLinearVelocity=Vector3.zero
   startRoot.AssemblyAngularVelocity=Vector3.zero
   startRoot.CFrame=origin
   R.Heartbeat:Wait()
   startRoot.AssemblyLinearVelocity=Vector3.zero
   startRoot.AssemblyAngularVelocity=Vector3.zero
   startRoot.Anchored=originalRootAnchored
  end
 end
 while cE and myToken==cToken do
  local targets=selectedTargetsSnapshot()
  if #targets==0 then
   activeTarget=nil waitAtActivationPoint()ss("esperando jugadores seleccionados...")task.wait(.2)continue
  end
  if targetIndex>#targets then targetIndex=1 end
  local target=targets[targetIndex]
  activeTarget=target selectedPlayer=target trackPlayerDeaths(target)updateResetLabel()
  local targetSkipVersion=skipTargetVersion
 local targetCharacter=target.Character
 local targetRootAtStart=targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
  if #targets>1 and(not targetCharacter or not targetCharacter.Parent or not targetRootAtStart or not targetRootAtStart.Parent)then
   waitAtActivationPoint()
   ss("omitiendo "..target.Name..": sin HRP")
   targetIndex=targetIndex+1
   task.wait(.05)
   continue
  end
  if not targetCharacter or not targetCharacter.Parent or not targetRootAtStart or not targetRootAtStart.Parent then waitAtActivationPoint()end
  while cE and myToken==cToken and selectedPlayerIds[target.UserId]and target.Parent==P and(not targetCharacter or not targetCharacter.Parent or not targetRootAtStart or not targetRootAtStart.Parent)do
  stopTargetPerspective()
  stopFollow()
   ss("esperando que reaparezca "..target.Name.."...")
  task.wait(.1)
  targetCharacter=target.Character
  targetRootAtStart=targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
 end
  if not cE or myToken~=cToken then break end
  if target.Parent~=P or not selectedPlayerIds[target.UserId]then targetIndex=targetIndex+1 continue end
 local cycleLost=false
  local placementDone=false
 startTargetPerspective(target)
 local targetMonitor=R.Heartbeat:Connect(function()
  if not cE or myToken~=cToken then return end
   if target.Parent~=P or not selectedPlayerIds[target.UserId]or target.Character~=targetCharacter or not targetCharacter.Parent or not targetRootAtStart.Parent or targetCharacter:FindFirstChild("HumanoidRootPart")~=targetRootAtStart then
   cycleLost=true
   stopFollow()
   ss("objetivo reinició o perdió HRP: restaurando...")
  end
 end)
  task.spawn(function()
   local placed=placeBalloonForTarget(target,myToken,balloonChoice,targetCharacter,function()return not cycleLost and skipTargetVersion==targetSkipVersion end)
   if placed then placementDone=true end
  end)
  while cE and myToken==cToken and skipTargetVersion==targetSkipVersion and not cycleLost and not placementDone and target==selectedTarget()and target.Parent==P do
  if followActive then
   task.wait(0.05)
  else
    task.spawn(function()fling(target,false,myToken)end)
    R.Heartbeat:Wait()
    local deadline=tick()+C.FLING_DURATION+1
   repeat task.wait(0.05)until skipTargetVersion~=targetSkipVersion or placementDone or not AF[target]or tick()>=deadline or cycleLost or not cE or myToken~=cToken or target~=selectedTarget()or target.Parent~=P
   local settle=tick()+0.6
   repeat task.wait(0.05)until skipTargetVersion~=targetSkipVersion or placementDone or tick()>=settle or cycleLost or not cE or myToken~=cToken or target~=selectedTarget()or target.Parent~=P
  end
 end
 cCleaning=true
  local skipped=skipTargetVersion~=targetSkipVersion
 if targetMonitor then targetMonitor:Disconnect()targetMonitor=nil end
 stopTargetPerspective()
 stopFollow()
  if not placementDone then removeEquippedBalloonBeforeReturn()end
  ss(placementDone and "cambiando de objetivo..."or"limpiando y regresando...")
  if placementDone then
   task.wait(.05)
  else
   local shutdownDeadline=tick()+3
   while AF[target]and tick()<shutdownDeadline do task.wait(.05)end
   R.Heartbeat:Wait()
   R.Heartbeat:Wait()
  end
 pcall(function()sethiddenproperty(startRoot,"PhysicsRepRootPart",nil)end)
 if startRoot and startRoot.Parent and startCharacter==gc()then
  startRoot.Anchored=true
  startRoot.AssemblyLinearVelocity=Vector3.zero
  startRoot.AssemblyAngularVelocity=Vector3.zero
  for part,state in pairs(originalPartState)do
   if part and part.Parent then
    part.CanCollide=state[1]
    part.Massless=state[2]
    part.AssemblyLinearVelocity=Vector3.zero
    part.AssemblyAngularVelocity=Vector3.zero
   end
  end
  if startHumanoid and startHumanoid.Parent then
   startHumanoid.PlatformStand=originalPlatformStand
   pcall(function()startHumanoid:Move(Vector3.zero)end)
   pcall(function()sethiddenproperty(startHumanoid,"MoveDirectionInternal",Vector3.zero)end)
  end
   if not placementDone or not cE or myToken~=cToken then startRoot.CFrame=origin end
  R.Heartbeat:Wait()
  startRoot.AssemblyLinearVelocity=Vector3.zero
  startRoot.AssemblyAngularVelocity=Vector3.zero
  startRoot.Anchored=originalRootAnchored
 end
 cCleaning=false
  if placementDone then
   targetIndex=targetIndex+1
   ss("siguiente objetivo...")
  elseif skipped then
   targetIndex=targetIndex+1
   ss("objetivo omitido; avanzando...")
  elseif target.Parent~=P or not selectedPlayerIds[target.UserId]then
   targetIndex=targetIndex+1
  elseif cE and myToken==cToken then ss("esperando que reaparezca "..target.Name.."...")end
end
cCleaning=false
 activeTarget=nil
stopTargetPerspective()
restoreActivationOrigin()
if activeReturnToOrigin==restoreActivationOrigin then activeReturnToOrigin=nil end
if myToken==cToken then setContinuousState(false)end
ss("idle")
end)
end)
skipB.MouseButton1Click:Connect(function()
if not cE then nt("SIGUIENTE OBJETIVO","activa primero el NaN",2)return end
if cCleaning then nt("SIGUIENTE OBJETIVO","espera el cambio actual",2)return end
skipTargetVersion=skipTargetVersion+1
stopFollow()
ss("omitiendo objetivo actual...")
nt("SIGUIENTE OBJETIVO","avanzando al siguiente seleccionado",2)
end)
stopB.MouseButton1Click:Connect(function()
stopTargetPerspective()
Extras.StopGift()
cToken=cToken+1 setContinuousState(false)
stopFollow()
local returnNow=activeReturnToOrigin
clearHeldObjectThenReturn(returnNow)
tE=false
if sE then stopSit()end sS(false)sTog.Text="SIT KILL: INACTIVO"
ss("deteniendo y restaurando...")nt("DETENER","flujos cancelados",2)
end)
clsBtn.MouseButton1Click:Connect(function()
if not closing then confirmShade.Visible=true end
end)
confirmNo.MouseButton1Click:Connect(function()
if not closing then confirmShade.Visible=false end
end)
confirmYes.MouseButton1Click:Connect(function()
if closing then return end
closing=true
stopTargetPerspective()
Extras.Close()
confirmYes.Text="CERRANDO..."confirmNo.Active=false
cToken=cToken+1 cE=false
stopFollow()
local returnNow=activeReturnToOrigin
clearHeldObjectThenReturn(returnNow)
tE=false
if sE then stopSit()end
clearDeathTracking()
flB.Text="ACTIVAR"flB.TextColor3=C.GREEN flB.BackgroundColor3=Color3.fromRGB(5,52,34)flBStroke.Color=Color3.fromRGB(0,180,96)flBStroke.Thickness=1
ss("limpiando y cerrando...")
task.spawn(function()
task.wait(0.8)
if dragInputConn then dragInputConn:Disconnect()dragInputConn=nil end
if keyInputConn then keyInputConn:Disconnect()keyInputConn=nil end
if sg and sg.Parent then sg:Destroy()end
end)
end)
Extras.GiftButton.MouseButton1Click:Connect(function()
if Extras.IsGiftEnabled()then Extras.StopGift()nt("REGALOS SCHOOLBAG","desactivado",2)
else local ok,message=Extras.StartGift()if ok then nt("REGALOS SCHOOLBAG","envío continuo activado",2)else Extras.GiftVisual(false,"OFF")nt("REGALOS SCHOOLBAG",message or"no se pudo activar",3)end end
end)
modoBtn.MouseButton1Click:Connect(function()
if modo=="CINTURA"then modo="ROTACION"modoBtn.Text="MODO: ROTACION"
elseif modo=="ROTACION"then modo="CLASICO"modoBtn.Text="MODO: CLASICO"
else modo="CINTURA"modoBtn.Text="MODO: CINTURA"end
nt("MODO",modo,2)
end)
sTog.MouseButton1Click:Connect(function()
if sE then stopSit()sS(false)sTog.Text="SIT KILL: INACTIVO"
else startSit()sS(true)sTog.Text="SIT KILL: ACTIVO"end
end)
if not mob then keyInputConn=U.InputBegan:Connect(function(i,g)if g or closing then return end if i.KeyCode==Enum.KeyCode.X then
if mz then
mz=false
mf.Visible=true
mf.Position=UDim2.new(0.5,-C.WIDTH/2,-0.5,0)
T:Create(mf,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-C.WIDTH/2,0.5,-C.HEIGHT/2)}):Play()
mB.Visible=false
else
minimizar()
end
end end)end
task.wait(0.5)nt("CARGADO","NaN Personalizado by Psychoo",3)ss("idle")
print("[NaN Personalizado] Cintura + Rotación + Clásico + Efecto sentado + Contador de reinicios")

 end
 NanPersonalizadoLauncher={}
 function NanPersonalizadoLauncher:Authorize(password,callback)
  callback=type(callback)=="function"and callback or function()end
  if not alive then callback(false,"launcher_closed")return end
  if authorizing then callback(false,"request_pending")return end
  if not BackendAnchorGuard or not BackendAnchorGuard.UnlockNanAccess then callback(false,"backend_unavailable")return end
  authorizing=true;authorized=false
  BackendAnchorGuard:UnlockNanAccess(password,function(ok,err)
   authorizing=false
   if not alive then callback(false,"launcher_closed")return end
   authorized=ok==true
   callback(authorized,err)
  end)
 end
 function NanPersonalizadoLauncher:Launch()
  if not alive then return false,"launcher_closed"end
  if not authorized then return false,"authorization_required"end
  authorized=false
  return xpcall(runNan,debug.traceback)
 end
 function NanPersonalizadoLauncher:Destroy()
  alive=false;authorized=false;authorizing=false
  local existing=playerGui and playerGui:FindFirstChild("NaNFlingGUI")
  if existing then existing:Destroy()end
 end
 return true
end
