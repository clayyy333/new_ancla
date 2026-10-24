-- Fall decisions only. Physics writes remain in independent MobileAnchorV13Core.
return function(context)
 setfenv(1,context)
 local Factory={}
 local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
 local function clearance(h,r)
  local height=math.max(0,h.HipHeight or 0)+r.Size.Y*.5
  if h.RigType==Enum.HumanoidRigType.R6 then
   local leg=r.Parent and r.Parent:FindFirstChild("Left Leg")
   height=height+(leg and leg.Size.Y or 2)
  end
  return math.max(1,height)
 end
 function Factory.new()
  local G={History={}}
  function G:Reset(character,humanoid,root,now)
   self.Character=character;self.Humanoid=humanoid;self.Root=root;self.History={};self.Ground=nil;self.SampleTime=-math.huge
   self.Candidate=nil;self.Votes=0;self.Center=false;self.StableSince=nil;self.LastCommit=-math.huge
   self.PeakY=root and root.Position.Y or nil;self.LastY=self.PeakY;self.LastTime=now
   self.NormalJump=false;self.LastProbe=-math.huge;self.Probe=nil;self.LastAction=-math.huge
   self.Status="WAIT_SAFE_GROUND";self.Recoveries=0;self.Brakes=0
  end
  function G:Accept(result)
   local slope=self.Humanoid and self.Humanoid.MaxSlopeAngle or 45
   local minimumNormal=math.max(.55,math.cos(math.rad(slope)))
   if not result or not result.Instance or not result.Normal or result.Normal.Y<minimumNormal then return false end
   if not result.Position or not finite(result.Position.Y)then return false end
   if result.Material==Enum.Material.Water then return false end
   local p=result.Instance
   if p:IsDescendantOf(self.Character)then return false end
   for _,name in ipairs({"Cars","ObjectPlaceFolder"})do
    local folder=workspace:FindFirstChild(name)
    if folder and p:IsDescendantOf(folder)then return false end
   end
   if p:IsA("Terrain")then return true end
   if not p:IsA("BasePart")or not p.CanCollide then return false end
   local v=p.AssemblyLinearVelocity
   return finite(v.Y)and math.abs(v.Y)<8 and v.Magnitude<25 and p.AssemblyAngularVelocity.Magnitude<4
  end
  function G:BeginSample(now)
   self.Candidate=nil;self.Votes=0;self.Center=false;self.SampleTime=now
  end
  function G:ObserveSupport(result,center,humanoid,root)
   if not self:Accept(result)then return end
   local gap=root.Position.Y-result.Position.Y-clearance(humanoid,root)
   if gap<-.65 or gap>.75 then return end
   self.Votes=self.Votes+1;self.Center=self.Center or center
   if not self.Candidate or center then self.Candidate=result end
  end
  function G:EndSample()
   self.Ground=(self.Center or self.Votes>=2)and self.Candidate or nil
  end
  function G:Grounded(now,h,r)
   if not self.Ground or now-self.SampleTime>.12 or not self:Accept(self.Ground)then return false end
   local gap=r.Position.Y-self.Ground.Position.Y-clearance(h,r)
   return gap>=-.65 and gap<=.75 and math.abs(r.AssemblyLinearVelocity.Y)<8
  end
  function G:CommitSafe(now,h,r,stable)
   if not stable or not self:Grounded(now,h,r)or h:GetState()==Enum.HumanoidStateType.Jumping then
    self.StableSince=nil;return false
   end
   self.StableSince=self.StableSince or now
   if now-self.StableSince<.18 then return false end
   if now-self.LastCommit<.10 then return true end
   self.LastCommit=now
   local p=self.Ground.Instance
   local sample={CFrame=r.CFrame,Part=p,Time=now,Clearance=clearance(h,r)}
   if p:IsA("BasePart")then sample.Relative=p.CFrame:ToObjectSpace(r.CFrame)end
   self.History[#self.History+1]=sample
   if #self.History>16 then table.remove(self.History,1)end
   self.Status="ARMED"
   return true
  end
  function G:Params()
   if not self.QueryParams then self.QueryParams=RaycastParams.new()end
   local excluded={self.Character}
   for _,name in ipairs({"Cars","ObjectPlaceFolder"})do
    local folder=workspace:FindFirstChild(name);if folder then excluded[#excluded+1]=folder end
   end
   self.QueryParams.FilterType=Enum.RaycastFilterType.Exclude
   self.QueryParams.FilterDescendantsInstances=excluded
   self.QueryParams.IgnoreWater=false;self.QueryParams.RespectCanCollide=true
   if self.Root.CollisionGroup then self.QueryParams.CollisionGroup=self.Root.CollisionGroup end
   return self.QueryParams
  end
  function G:RecoveryFrame(h,r)
   local params=self:Params()
   -- Prefer newest, but reject removed/moved-away platforms and stale support.
   for i=#self.History,1,-1 do
    local sample=self.History[i]
    local p=sample.Part
    if p and p:IsDescendantOf(workspace)then
     local frame=sample.Relative and p.CFrame*sample.Relative or sample.CFrame
     local result=workspace:Raycast(frame.Position+Vector3.new(0,1,0),Vector3.new(0,-sample.Clearance-2,0),params)
     if result and result.Instance==p and self:Accept(result)then
      local gap=frame.Position.Y-result.Position.Y-sample.Clearance
      local killHeight=workspace.FallenPartsDestroyHeight
      if math.abs(gap)<=.8 and (not finite(killHeight)or frame.Position.Y>killHeight+sample.Clearance+8)then return frame end
     end
    end
   end
  end
  function G:Recovered(now,r)
   self.PeakY=r.Position.Y;self.LastY=r.Position.Y;self.LastTime=now
   self.NormalJump=false;self.Ground=nil;self.SampleTime=-math.huge
   self.LastProbe=-math.huge;self.Probe=nil;self.StableSince=nil
  end
  function G:Step(now,dt,character,h,r,threatened)
   if self.Character~=character or self.Root~=r then self:Reset(character,h,r,now)end
   local state=h:GetState()
   local v=r.AssemblyLinearVelocity
   if h.Health<=0 or r.Anchored or h.Sit or h.SeatPart or state==Enum.HumanoidStateType.Swimming or state==Enum.HumanoidStateType.Climbing then
    self:Recovered(now,r);self.Status="SUSPENDED";return
   end
   if not finite(v.X)or not finite(v.Y)or not finite(v.Z)or not finite(r.Position.X)or not finite(r.Position.Y)or not finite(r.Position.Z)then self.Status="INVALID_PHYSICS";return end
   local down=math.max(0,-v.Y)
   local interval=self.LastTime and now-self.LastTime or 0
   if interval>1e-4 and interval<.5 and self.LastY then down=math.max(down,(self.LastY-r.Position.Y)/interval)end
   self.LastY=r.Position.Y;self.LastTime=now
   local grounded=self:Grounded(now,h,r)
   if grounded and down<8 then
    self.PeakY=r.Position.Y;self.NormalJump=false
    if #self.History>0 then self.Status="ARMED"end
    return
   end
   self.StableSince=nil
   self.PeakY=math.max(self.PeakY or r.Position.Y,r.Position.Y)
   local gravity=finite(workspace.Gravity)and math.max(0,workspace.Gravity)or 196.2
   local jumpHeight=(h.UseJumpPower==false and h.JumpHeight)or ((h.JumpPower or 50)^2/(2*math.max(gravity,1)))
   local jumpBudget=math.min(30,math.max(4,jumpHeight or 7)+3)
   if not threatened and v.Y>2 and v.Y<70 and (state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall)then self.NormalJump=true end
   local drop=self.PeakY-r.Position.Y
   local horizon=math.min(.18,math.max(.06,(finite(dt)and dt or 1/60)*2+.03))
   local projectedDrop=down*horizon+.5*gravity*horizon*horizon
   local killHeight=workspace.FallenPartsDestroyHeight
   local voidRisk=finite(killHeight)and r.Position.Y-projectedDrop<=killHeight+clearance(h,r)+12
   local dangerous=down>=38 and drop>=(self.NormalJump and jumpBudget or 6)
   local violent=down>=90 and drop>=1
   if down<18 and not voidRisk then self.Status="AIRBORNE";return end
   -- One predictive probe, at most 25-50/s while descending. Reuse the normal
   -- five support rays for grounding; do not add another footprint scan.
   if now-self.LastProbe>=(down>=70 and .02 or .04)then
    self.LastProbe=now
    local ahead=Vector3.new(v.X*horizon,0,v.Z*horizon)
    if ahead.Magnitude>12 then ahead=ahead*(12/ahead.Magnitude)end
    self.Probe=workspace:Raycast(r.Position+ahead+Vector3.new(0,.5,0),Vector3.new(0,-math.min(256,clearance(h,r)+projectedDrop+8),0),self:Params())
   end
   local impact=self:Accept(self.Probe)and r.Position.Y-self.Probe.Position.Y-clearance(h,r)<=projectedDrop+.5
   local reason=voidRisk and "VOID_PREDICTED"or (violent and "VIOLENT_DESCENT")or (dangerous and impact and "IMPACT_PREDICTED")or (dangerous and "UNSAFE_DROP")
   if not reason then self.Status="DESCENDING";return end
   if now-self.LastAction<.20 then return end
   self.LastAction=now
   local destination=self:RecoveryFrame(h,r)
   self.Status=destination and "RECOVERING"or "BRAKING_NO_SAFE_GROUND"
   if destination then self.Recoveries=self.Recoveries+1 else self.Brakes=self.Brakes+1 end
   return {Action=destination and "RETURN"or "BRAKE",CFrame=destination,Reason=reason,DownSpeed=down,Drop=drop,Horizon=horizon,PredictedImpact=impact==true,BrakeY=math.max(v.Y,-16)}
  end
  return G
 end
 MobileFallGuardFactory=Factory
 return true
end
