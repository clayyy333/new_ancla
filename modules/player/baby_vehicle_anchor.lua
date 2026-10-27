-- Owner-only Babycar cycle using the existing deployment anchor motor.
return function(context)
 setfenv(1,context)
 local Core={Running=false,State="STOPPED",LastError=nil,TPHeight=0,TPSeparation=3.5}
 local function validOffset(name,value)
  return type(value)=="number"and value==value and math.abs(value)<math.huge and (name~="TPSeparation"or value>=0)
 end
 local savedOffsets=Settings and Settings.deploymentTPOffsets
 if type(savedOffsets)=="table"then
  for _,name in ipairs({"TPHeight","TPSeparation"})do
   if validOffset(name,savedOffsets[name])then Core[name]=savedOffsets[name]end
  end
 end
 BabyVehicleAnchorCore=Core
 local connections,jointWatches={},{}
 local character,humanoid,root,backpack,home,tool,oldTool,target,targetJoint
 local equipRemote,clearRemote,generation,requesting= nil,nil,0,false
 local handled=setmetatable({},{__mode="k"})
 local stateSince,lastRetry,lastSide,side=0,0,0,1
 local inspect,prepare,follow,watch
 local function authorized()return ExperimentalFlingCore and ExperimentalFlingCore:IsAuthorized()end
 function Core:SetTPOffset(name,value)
  if not authorized()or (name~="TPHeight"and name~="TPSeparation")or not validOffset(name,value)then return false end
  self[name]=value
  if Settings then
   Settings.deploymentTPOffsets={TPHeight=self.TPHeight,TPSeparation=self.TPSeparation}
   if SaveLocalData then SaveLocalData()end
  end
  return true
 end
 local function destination(tr,s)
  return (tr.CFrame*CFrame.new(s*Core.TPSeparation,0,0)).Position+Vector3.new(0,Core.TPHeight,0)
 end
 local function status(state,message)
  Core.State=state;stateSince=os.clock();Core.LastError=message
  if DeploymentSafetyCore then DeploymentSafetyCore.LastError=message or state end
  if UpdateAnchorPanel then UpdateAnchorPanel()end
 end
 local function connect(signal,fn,bucket)
  local c=signal:Connect(fn);table.insert(bucket or connections,c);return c
 end
 local function disconnect(list)for _,c in ipairs(list)do c:Disconnect()end;table.clear(list)end
 local function findTool()
  local t=character and character:FindFirstChild("Babycar_a")or nil
  t=t or (backpack and backpack:FindFirstChild("Babycar_a"))
  return t and t:IsA("Tool")and t or nil
 end
 local function jointType(j)
  return j:IsA("JointInstance")or j:IsA("WeldConstraint")
 end
 local function valid(j)
  return j and j.Parent and j.Part0 and j.Part1 and (not j:IsA("WeldConstraint")or j.Enabled)
 end
 local function playerFrom(part)
  local node=part and part.Parent
  while node do
   if node:IsA("Model")then local p=Players:GetPlayerFromCharacter(node);if p then return p end end
   node=node.Parent
  end
 end
 local function protect(j)
  if not valid(j)then return false end
  local a,b=j.Part0,j.Part1
  -- Own tool is part of the character too: only release LOCAL BODY -> foreign seat.
  local localA=a:IsDescendantOf(character)and not a:FindFirstAncestorOfClass("Tool")
  local localB=b:IsDescendantOf(character)and not b:FindFirstAncestorOfClass("Tool")
  local seat=localA and b or localB and a
  if seat and (seat:IsA("Seat")or seat:IsA("VehicleSeat"))and not seat:IsDescendantOf(character)then
   j:Destroy();humanoid.Sit=false
   root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
   return true
  end
  return false
 end
 local function returnHome()
  target=nil;targetJoint=nil
  if home and DeploymentAnchorMotorCore:IsRunning()then DeploymentAnchorMotorCore:RelocateForDeployment(home)end
 end
 function Core:Stop()
  self.Running=false;generation=generation+1;requesting=false
  disconnect(connections)
  for j,list in pairs(jointWatches)do disconnect(list);jointWatches[j]=nil end
  returnHome();DeploymentAnchorMotorCore:Stop()
  tool=nil;oldTool=nil;character=nil;humanoid=nil;root=nil;backpack=nil;home=nil
  status("STOPPED");return true
 end
 function Core:IsRunning()return self.Running end
 local function fail(message)Core:Stop();status("ERROR",message)end
 local function useReady(t)
  if not Core.Running then return end
  if Core.State~="PREPARING"and Core.State~="REARMING"then return end
  tool=t
  if Core.State=="REARMING"then returnHome()end
  status("WAITING","Ancla activa; esperando usuario conectado a vehiculo.")
  for _,j in ipairs(t:GetDescendants())do if jointType(j)then inspect(j)end end
 end
 prepare=function()
  if not Core.Running or requesting then return end
  local existing=findTool()
  if existing and existing~=oldTool then useReady(existing);return end
  requesting=true;lastRetry=os.clock();local token=generation
  task.spawn(function()
   local ok,err=pcall(function()return equipRemote:InvokeServer("Babycar_a")end)
   if not Core.Running or generation~=token then return end
   requesting=false
   if not ok then Core.LastError="No se pudo invocar Babycar: "..tostring(err)end
   local t=findTool()
   if t and t~=oldTool then useReady(t)end
  end)
 end
 local function score(tr,s)
  local pos=destination(tr,s)
  local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
  params.FilterDescendantsInstances={character,tr.Parent};params.MaxParts=80
  local n=0
  for _,p in ipairs(workspace:GetPartBoundsInRadius(pos,2.5,params))do
   if p:IsA("Seat")or p:IsA("VehicleSeat")then n=n+100 elseif p.CanCollide then n=n+1 end
  end
  return n
 end
 follow=function(first)
  local tr=target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
  if not tr or not tool or tool.Parent~=character then return false end
  humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false);humanoid.Sit=false
  -- No spatial query or remote call before the first relocation.
  if not first and os.clock()-lastSide>=.2 then
   lastSide=os.clock()
   local ok,right,left=pcall(function()return score(tr,1),score(tr,-1)end)
   if ok then if right+1<left then side=1 elseif left+1<right then side=-1 end end
  end
  local pos=destination(tr,side)
  local frame=(pos-tr.Position).Magnitude>.001 and CFrame.lookAt(pos,tr.Position)or CFrame.new(pos)*tr.CFrame.Rotation
  DeploymentAnchorMotorCore:RelocateForDeployment(frame)
  return true
 end
 local function equipped()
  if Core.State~="EQUIPPING"or not tool or tool.Parent~=character then return end
  status("FOLLOWING","Ancla siguiendo al lateral del vehiculo.")
  lastSide=os.clock();follow(true)
  for _,j in ipairs(tool:GetDescendants())do watch(j);if Core.State~="FOLLOWING"then break end end
 end
 watch=function(j)
  if not jointType(j)or jointWatches[j]then return end
  local cars=workspace:FindFirstChild("Cars")
  local a,b=j.Part0,j.Part1
  if j.Name~="SeatWeld"and not(cars and j:IsDescendantOf(cars))and not j:IsDescendantOf(character)
   and not(tool and j:IsDescendantOf(tool))and not(a and a:IsDescendantOf(character))and not(b and b:IsDescendantOf(character))then return end
  local list={};jointWatches[j]=list
  connect(j:GetPropertyChangedSignal("Part0"),function()inspect(j)end,list)
  connect(j:GetPropertyChangedSignal("Part1"),function()inspect(j)end,list)
  if j:IsA("WeldConstraint")then connect(j:GetPropertyChangedSignal("Enabled"),function()inspect(j)end,list)end
  connect(j.AncestryChanged,function()
   if not j:IsDescendantOf(workspace)then disconnect(list);jointWatches[j]=nil end
  end,list)
  inspect(j)
 end
 inspect=function(j)
  if not Core.Running or not jointType(j)or not valid(j)then return end
  if protect(j)then return end
  local a,b=j.Part0,j.Part1
  local pa,pb=playerFrom(a),playerFrom(b)
  -- Only confirm the selected passenger, not any unrelated player/tool joint.
  if Core.State=="FOLLOWING"and tool and target then
   if (pa==target and b:IsDescendantOf(tool))or(pb==target and a:IsDescendantOf(tool))then
    oldTool=tool;status("CLEARING","Pasajero confirmado; esperando retirada del coche.")
    local ok,err=pcall(function()clearRemote:FireServer(true)end)
    if not ok then fail("Error al retirar el coche: "..tostring(err))end
    return
   end
  end
  if Core.State~="WAITING"or handled[j]then return end
  local p,part
  if pa and pa~=player and not pb then p,part=pa,b elseif pb and pb~=player and not pa then p,part=pb,a end
  local cars=workspace:FindFirstChild("Cars")
  if not p or not cars or not part:IsDescendantOf(cars)or part:FindFirstAncestorOfClass("Tool")then return end
  local name=string.lower(j.Name)
  if name~="seatweld"and name~="weldtoplayer"and not(j:IsA("WeldConstraint")and (part:IsA("Seat")or part:IsA("VehicleSeat")))then return end
  if not p.Character or not p.Character:FindFirstChild("HumanoidRootPart")then return end
  tool=findTool();if not tool then return end
  handled[j]=true;target=p;targetJoint=j;side=1
  status("EQUIPPING","Equipando coche; ancla activa.")
  humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false);humanoid.Sit=false
  local ok,err=pcall(function()humanoid:EquipTool(tool)end)
  if not ok then fail("Error al equipar: "..tostring(err));return end
  equipped()
 end
 function Core:Start()
  if not authorized()then return false,"Disponible solo para owners."end
  if self.Running then return true end
  if not DeploymentSafetyCore:IsAvailable()then return false,"Disponible solo en Metro Life."end
  character=player.Character;humanoid=character and character:FindFirstChildOfClass("Humanoid")
  root=character and character:FindFirstChild("HumanoidRootPart");backpack=player:FindFirstChild("Backpack")
  if not root or not humanoid or humanoid.Health<=0 or not backpack then return false,"Personaje no disponible."end
  local remotes=game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
  equipRemote=remotes and remotes:FindFirstChild("EquipToolRF");clearRemote=remotes and remotes:FindFirstChild("ClearToolRE")
  if not equipRemote or not equipRemote:IsA("RemoteFunction")or not clearRemote or not clearRemote:IsA("RemoteEvent")then return false,"No se encuentran los remotos del coche."end
  home=root.CFrame
  local ok,err=DeploymentAnchorMotorCore:Start();if not ok then return false,err end
  self.Running=true;generation=generation+1;handled=setmetatable({},{__mode="k"});oldTool=nil;tool=nil;requesting=false
  status("PREPARING","Preparando coche con ancla activa.")
  local function added(item)
   if item.Name=="Babycar_a"and item:IsA("Tool")then
    if self.State=="PREPARING"or self.State=="REARMING"then if item~=oldTool then useReady(item)end end
    equipped()
    for _,j in ipairs(item:GetDescendants())do watch(j)end
   end
  end
  connect(character.ChildAdded,added);connect(backpack.ChildAdded,added)
  connect(workspace.DescendantAdded,watch)
  connect(humanoid:GetPropertyChangedSignal("SeatPart"),function()
   local seat=humanoid.SeatPart
   if seat then local j=seat:FindFirstChild("SeatWeld");if j then watch(j);protect(j)end end
   humanoid.Sit=false
  end)
  connect(humanoid.Died,function()fail("Personaje muerto; vuelve a activar el flujo.")end)
  connect(player.CharacterRemoving,function(c)if c==character then self:Stop()end end)
  connect(RunService.Heartbeat,function()
   if not authorized()or not DeploymentAnchorMotorCore:IsRunning()then self:Stop();return end
   local now=os.clock()
   if self.State=="CLEARING"then
    -- FireServer success is not deletion confirmation. Require departure from BOTH containers.
   if oldTool and not oldTool:IsDescendantOf(character)and not oldTool:IsDescendantOf(backpack)then
     tool=nil;status("REARMING","Coche retirado; esperando reinvocacion antes del regreso.");prepare()
    elseif now-stateSince>5 then fail("No se confirmo la retirada del coche; ciclo detenido.")end
   elseif self.State=="PREPARING"or self.State=="REARMING"then
    if now-stateSince>10 then fail("No se confirmo la invocacion del coche; ciclo detenido.")
    elseif now-lastRetry>=1 then prepare()end
   elseif self.State=="EQUIPPING"then
    equipped();if self.State=="EQUIPPING"and now-stateSince>3 then fail("No se confirmo que el coche quedara equipado.")end
   elseif self.State=="FOLLOWING"then
    if not target or target.Parent~=Players or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart")then
     returnHome();status("WAITING")
    elseif not tool or tool.Parent~=character then
     returnHome();tool=nil;oldTool=nil;status("PREPARING");prepare()
    else follow(false)end
   elseif self.State=="WAITING"and now-lastRetry>=.15 then
    lastRetry=now
    -- Rescan cached candidate references, not every player's full connected assembly.
    for j in pairs(jointWatches)do inspect(j);if self.State~="WAITING"then break end end
   end
  end)
  local cars=workspace:FindFirstChild("Cars")
  if cars then for _,j in ipairs(cars:GetDescendants())do watch(j)end end
  prepare();return true
 end
 function Core:Destroy()self:Stop()end
 return true
end
