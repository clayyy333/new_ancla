-- Independent fixed anchor: emote -> defense -> virtual sitting.
return function(context)
 setfenv(1,context)
 local P=game:GetService("Players")
 local R=game:GetService("RunService")
 local Core={Running=false,Starting=false,LastError=nil}
 local token=0
 local saved,track,animation,field,step
 local function refresh()if UpdateAnchorPanel then UpdateAnchorPanel()end end
 local function virtualSit(enabled)
  local h=saved and saved.h
  if not h or not h.Parent then return end
  h.Sit=enabled
  h:ChangeState(enabled and Enum.HumanoidStateType.Seated or Enum.HumanoidStateType.GettingUp)
 end
 local function defense(enabled)
  local s=saved;if not s then return end
  local h,r=s.h,s.r
  if enabled then
   h.BreakJointsOnDeath=false;h:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
   if h.Health>0 then h.MaxHealth=math.huge;h.Health=math.huge end
   field=Instance.new("ForceField");field.Visible=false;field.Parent=s.character
   r.Anchored=true;r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
  else
   if step then step:Disconnect();step=nil end
   if field then field:Destroy();field=nil end
   if h.Parent then
    h.BreakJointsOnDeath=s.breakJoints;h:SetStateEnabled(Enum.HumanoidStateType.Dead,s.dead)
    h.MaxHealth=s.maxHealth
    if h.Health>0 then h.Health=math.min(s.health,s.maxHealth)end
   end
   if r.Parent then r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero;r.Anchored=s.anchored end
  end
 end
 function Core:Stop()
  token=token+1;self.Starting=false;self.Running=false
  -- Required order, including cancellation and closing the main GUI.
  pcall(virtualSit,false)
  pcall(defense,false)
  if step then step:Disconnect();step=nil end
  if field then field:Destroy();field=nil end
  if track then pcall(function()track:Stop(0);track:Destroy()end);track=nil end
  if animation then animation:Destroy();animation=nil end
  saved=nil;refresh();return true
 end
 function Core:Start()
  if self.Running or self.Starting then return true end
  local character=P.LocalPlayer.Character
  local h=character and character:FindFirstChildOfClass("Humanoid")
  local r=character and character:FindFirstChild("HumanoidRootPart")
  if not h or not r or h.Health<=0 then return false,"Personaje no disponible."end
  self.Starting=true;self.LastError=nil;token=token+1;local mine=token;refresh()
  task.spawn(function()
   local ok,err=xpcall(function()
    local id="rbxassetid://116197008542581"
    -- Catalog emotes may contain an internal AnimationId.
    local loaded,objects=pcall(function()return game:GetObjects(id)end)
    if loaded and type(objects)=="table"then
     for _,object in ipairs(objects)do
      local found=object:IsA("Animation")and object or object:FindFirstChildWhichIsA("Animation",true)
      if found and found.AnimationId~=""then id=found.AnimationId end
      object:Destroy()
     end
    end
    if mine~=token or P.LocalPlayer.Character~=character then return end
    local animator=h:FindFirstChildOfClass("Animator")
    if not animator then animator=Instance.new("Animator");animator.Parent=h end
    local anim=Instance.new("Animation");anim.AnimationId=id
    animation=anim
    local playing=animator:LoadAnimation(anim)
    if mine~=token or P.LocalPlayer.Character~=character then playing:Destroy();return end
    track=playing;playing.Priority=Enum.AnimationPriority.Action4;playing.Looped=true
    playing:Play(0)
    saved={character=character,h=h,r=r,frame=r.CFrame,anchored=r.Anchored,
     health=h.Health,maxHealth=h.MaxHealth,breakJoints=h.BreakJointsOnDeath,
     dead=h:GetStateEnabled(Enum.HumanoidStateType.Dead)}
    defense(true)
    virtualSit(true)
    self.Running=true;self.Starting=false
    step=R.Heartbeat:Connect(function()
     if not self.Running then return end
     if P.LocalPlayer.Character~=character or not r.Parent or not h.Parent or h.Health<=0 then self:Stop();return end
     local applied,problem=pcall(function()
      r.Anchored=true;r.CFrame=saved.frame
      r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
      h.BreakJointsOnDeath=false;h:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
      h.MaxHealth=math.huge;h.Health=math.huge
      h.Sit=true
      if h:GetState()~=Enum.HumanoidStateType.Seated then h:ChangeState(Enum.HumanoidStateType.Seated)end
     end)
     if not applied then self.LastError=tostring(problem);self:Stop()end
    end)
   end,debug.traceback)
   if mine~=token then return end
   if not ok then self.LastError=tostring(err);self:Stop()end
   self.Starting=false;refresh()
  end)
  return true
 end
 function Core:Destroy()return self:Stop()end
 NoSitAnchorCore=Core
 return true
end
