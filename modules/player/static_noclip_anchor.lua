-- Independent static anchor. No Workspace enumeration or shared anchor state.
return function(context)
 setfenv(1,context)
 local C={Running=false,ConstantReturn=false,SeatPrevention=false,Checkpoint=nil}
 local function authorized()return ExperimentalFlingCore and ExperimentalFlingCore:IsAuthorized()end
 local links,parts,pending={},{},{}
 local vehicleParts,contactModels={},setmetatable({},{__mode="k"})
 local char,hum,root,old,guard
 local bridgeReleased=false
 local knownNames={Babycar_a=true,Babycar_b=true,Babycar_c=true,Stretcher=true,FoldingTable_1=true,Folding_table_02=true}
 local knownSeats,modifiedSeats={},{}
 local scanned=setmetatable({},{__mode="k"})
 local nextQuery=0
 local queryParams
 local function isSeat(p)return p:IsA("Seat")or p:IsA("VehicleSeat")end
 local function knownContainer(p)
  local n=p
  while n and n~=workspace do if knownNames[n.Name]then return n end;n=n.Parent end
 end
 local function register(p)
  if isSeat(p)and knownContainer(p)then knownSeats[p]=true end
 end
 local function restoreSeat(seat,state)
  if seat.Parent then pcall(function()seat.Disabled=state.Disabled;seat.CanTouch=state.CanTouch end)end
  modifiedSeats[seat]=nil
 end
 local function restoreSeats()
  for seat,state in pairs(modifiedSeats)do restoreSeat(seat,state)end
 end
 local function near(seat)
  return seat.Parent and not seat:IsDescendantOf(char)and (seat.Position-root.Position).Magnitude<=15
 end
 local function prevent(seat)
  if not near(seat)then return end
  if not modifiedSeats[seat]then modifiedSeats[seat]={Disabled=seat.Disabled,CanTouch=seat.CanTouch}end
  seat.Disabled=true;seat.CanTouch=false
 end
 local function seatStep()
  if not C.SeatPrevention then return end
  for seat,state in pairs(modifiedSeats)do if not near(seat)then restoreSeat(seat,state)end end
  for seat in pairs(knownSeats)do
   if seat:IsDescendantOf(workspace)then prevent(seat)else knownSeats[seat]=nil end
  end
  local now=os.clock()
  if now<nextQuery then return end
  nextQuery=now+.10
  if not queryParams then queryParams=OverlapParams.new();queryParams.FilterType=Enum.RaycastFilterType.Exclude end
  queryParams.FilterDescendantsInstances={char}
  -- No MaxParts truncation: a dense scene must not hide an unknown seat.
  for _,part in ipairs(workspace:GetPartBoundsInRadius(root.Position,15,queryParams))do
   local container=knownContainer(part)
   if container and not scanned[container]then
    scanned[container]=true
    for _,descendant in ipairs(container:GetDescendants())do register(descendant)end
   end
   if isSeat(part)then register(part);prevent(part)end
  end
  for seat in pairs(knownSeats)do prevent(seat)end
 end
 local function busy()
  for _,core in ipairs({AnchorCore,StaticPassThroughAnchorCore,DeploymentAnchorMotorCore,MobileAnchorCore,MobileAnchorV11Core,MobileAnchorV13Core})do
   if core and (core.Running or core.AnclaEnabled or core.TestEnabled)then return true end
  end
  return AutoAnchorCore and (AutoAnchorCore.Mode or AutoAnchorCore.Busy)
 end
 local function refresh()if UpdateAnchorPanel then UpdateAnchorPanel()end end
 local function body(p)return p and p:IsDescendantOf(char)and not p:FindFirstAncestorOfClass("Tool")end
 local function inspect(j)
  if not j.Parent then pending[j]=nil;return end
  local a,b=j.Part0,j.Part1
  if not a or not b then return end
  pending[j]=nil
  if a:IsDescendantOf(char)and b:IsDescendantOf(char)then return end
  if body(a)~=body(b)then j:Destroy();bridgeReleased=true end
 end
 local function observe(j)
  if not(j:IsA("JointInstance")or j:IsA("WeldConstraint"))or j:IsA("Motor6D")or j.Name=="AccessoryWeld"then return end
  if j.Part0 and j.Part1 then inspect(j)
  elseif j.Name=="SeatWeld"or j:IsDescendantOf(char)then 
   local count=0;for _ in pairs(pending)do count=count+1 end
   if count<64 then pending[j]=os.clock()+.5 end
  end
 end
 local function returnHome()
  if root and root.Parent and C.Checkpoint then
   root.CFrame=C.Checkpoint;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  end
 end
 local function zeroBody()
  for p in pairs(parts)do
   if p.Parent then
    p.CanCollide=false
    p.AssemblyLinearVelocity=Vector3.zero;p.AssemblyAngularVelocity=Vector3.zero
   else parts[p]=nil end
  end
 end
 local function release()
  if guard or not C.Running then return end
  guard=true
  local seat=hum.SeatPart
  if seat and seat.Parent then for _,j in ipairs(seat:GetChildren())do observe(j)end end
  hum.Sit=false
  local state=hum:GetState()
  if seat or bridgeReleased or state==Enum.HumanoidStateType.Seated or state==Enum.HumanoidStateType.Ragdoll or state==Enum.HumanoidStateType.FallingDown then
   if state==Enum.HumanoidStateType.Seated or state==Enum.HumanoidStateType.Ragdoll or state==Enum.HumanoidStateType.FallingDown then hum:ChangeState(Enum.HumanoidStateType.GettingUp)end
   returnHome();zeroBody();bridgeReleased=false
  end
  guard=false
 end
 local function add(p)
  if p:IsA("BasePart")and body(p)then
   parts[p]=p.CanCollide;p.CanCollide=false
   links[#links+1]=p.Touched:Connect(function(hit)
    if not C.Running or not hit or hit:IsDescendantOf(char)then return end
    local model=hit:FindFirstAncestorOfClass("Model")
    if not model or contactModels[model]then return end
    if not(model:FindFirstChildOfClass("Seat")or model:FindFirstChildOfClass("VehicleSeat"))then return end
    contactModels[model]=true
    for _,v in ipairs(model:GetDescendants())do
     if v:IsA("BasePart")and not v:IsDescendantOf(char)then
      if vehicleParts[v]==nil then vehicleParts[v]=v.CanCollide end
      v.CanCollide=false
     end
     if C.SeatPrevention and isSeat(v)then prevent(v)end
    end
    release()
   end)
  end
  observe(p)
 end
 function C:SetConstantReturn(value)
  if not authorized()then return false,"Solo owners."end
  self.ConstantReturn=value==true;refresh();return true
 end
 function C:SetSeatPrevention(value)
  if not authorized()then return false,"Solo owners."end
  self.SeatPrevention=value==true;nextQuery=0
  if not self.SeatPrevention then restoreSeats()end
  refresh();return true
 end
 function C:Stop()
  self.Running=false
  restoreSeats();table.clear(knownSeats);scanned=setmetatable({},{__mode="k"});queryParams=nil
  for _,l in ipairs(links)do l:Disconnect()end;table.clear(links)
  for p,v in pairs(parts)do if p.Parent then p.CanCollide=v end end;table.clear(parts);table.clear(pending)
  for p,v in pairs(vehicleParts)do if p.Parent then p.CanCollide=v end end;table.clear(vehicleParts)
  contactModels=setmetatable({},{__mode="k"});bridgeReleased=false
  if hum and hum.Parent and old then
   hum.AutoRotate=old.Rotate;hum:SetStateEnabled(Enum.HumanoidStateType.Seated,old.Seated)
   hum.PlatformStand=old.PlatformStand;hum.WalkSpeed=old.WalkSpeed;hum.JumpPower=old.JumpPower
  end
  char=nil;hum=nil;root=nil;old=nil;guard=false;self.Checkpoint=nil;refresh();return true
 end
 function C:Start()
  if not authorized()then return false,"Solo owners."end
  if self.Running then return true end
  if busy()then return false,"Desactiva las otras anclas primero."end
  char=player.Character;hum=char and char:FindFirstChildOfClass("Humanoid");root=char and char:FindFirstChild("HumanoidRootPart")
  if not root or not hum or hum.Health<=0 then return false,"Personaje no disponible."end
  old={Rotate=hum.AutoRotate,Seated=hum:GetStateEnabled(Enum.HumanoidStateType.Seated),PlatformStand=hum.PlatformStand,WalkSpeed=hum.WalkSpeed,JumpPower=hum.JumpPower}
  self.Checkpoint=root.CFrame;self.Running=true;hum.AutoRotate=false;hum:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
  for _,p in ipairs(char:GetDescendants())do add(p)end
  for p in pairs(parts)do for _,j in ipairs(p:GetJoints())do observe(j)end end
  for _,other in ipairs(Players:GetPlayers())do
   if other.Character and other.Character~=char then
    for _,p in ipairs(other.Character:GetDescendants())do register(p)end
   end
  end
  links[#links+1]=char.DescendantAdded:Connect(add)
  links[#links+1]=workspace.DescendantAdded:Connect(function(j)if self.Running then register(j);observe(j)end end)
  links[#links+1]=hum:GetPropertyChangedSignal("Sit"):Connect(release)
  links[#links+1]=hum:GetPropertyChangedSignal("SeatPart"):Connect(release)
  links[#links+1]=hum.StateChanged:Connect(release)
  links[#links+1]=hum.Seated:Connect(function(active)if active then release()end end)
  links[#links+1]=hum.Died:Connect(function()self:Stop()end)
  links[#links+1]=player.CharacterRemoving:Connect(function(r)if r==char then self:Stop()end end)
  links[#links+1]=(RunService.PreSimulation or RunService.Stepped):Connect(function()
   if not authorized()or busy()then self:Stop();return end
   if not root.Parent or hum.Health<=0 then self:Stop();return end
   zeroBody()
   hum.PlatformStand=true;hum.WalkSpeed=0;hum.JumpPower=0;hum.AutoRotate=false
   for j,deadline in pairs(pending)do
    if os.clock()>deadline then pending[j]=nil else inspect(j)end
   end
   seatStep()
   release()
   if self.ConstantReturn then returnHome()
   else
    local pos=root.Position
    root.CFrame=CFrame.new(pos.X,self.Checkpoint.Position.Y,pos.Z)*self.Checkpoint.Rotation
    root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
   end
  end)
  -- Verify the result after physics as well, using the same cached body parts.
  links[#links+1]=(RunService.PostSimulation or RunService.Heartbeat):Connect(function()
   if not self.Running or not root.Parent or hum.Health<=0 then return end
   release()
   if self.ConstantReturn then returnHome()
   else
    local pos=root.Position
    root.CFrame=CFrame.new(pos.X,self.Checkpoint.Position.Y,pos.Z)*self.Checkpoint.Rotation
   end
   zeroBody()
   hum.PlatformStand=true;hum.Sit=false;hum.WalkSpeed=0;hum.JumpPower=0;hum.AutoRotate=false
  end)
  release();zeroBody();hum.PlatformStand=true;hum.WalkSpeed=0;hum.JumpPower=0;refresh();return true
 end
 function C:Destroy()self:Stop()end
 StaticNoclipAnchorCore=C
 return true
end
