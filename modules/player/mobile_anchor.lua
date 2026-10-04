-- Ancla movil experimental: conserva locomocion y corrige impulsos anormales.
return function(context)
 setfenv(1,context)
 local OWNERS={[11739864999]="psychoo778",[11743514302]="ksablanca0",[11747901934]="psycho777oo"};local expected=OWNERS[player.UserId]
 local Core={Running=false,SafeCFrame=nil,LastPosition=nil,GraceUntil=0,Corrections=0};local persistent,runtime,collisions={},{},{}
 local function authorized()return expected~=nil and string.lower(player.Name)==expected end
 local function rig()local c=player.Character;return c,c and c:FindFirstChildOfClass("Humanoid"),c and c:FindFirstChild("HumanoidRootPart")end
 local function disconnectRuntime()for _,c in ipairs(runtime)do pcall(function()c:Disconnect()end)end;table.clear(runtime)end
 local function restoreCollisions()for part,value in pairs(collisions)do if part and part.Parent then pcall(function()part.CanCollide=value end)end end;table.clear(collisions)end
 local function suppressPart(part)if part:IsA("BasePart")and collisions[part]==nil then collisions[part]=part.CanCollide;part.CanCollide=false end end
 local function suppressCharacter(character)if not character or character==player.Character then return end;for _,o in ipairs(character:GetDescendants())do suppressPart(o)end;runtime[#runtime+1]=character.DescendantAdded:Connect(suppressPart)end
 local function bindPlayers()for _,other in ipairs(Players:GetPlayers())do if other~=player then suppressCharacter(other.Character);runtime[#runtime+1]=other.CharacterAdded:Connect(suppressCharacter)end end;runtime[#runtime+1]=Players.PlayerAdded:Connect(function(other)if other~=player then runtime[#runtime+1]=other.CharacterAdded:Connect(suppressCharacter)end end)end
 local function zeroCharacter(character)for _,o in ipairs(character:GetDescendants())do if o:IsA("BasePart")then o.AssemblyLinearVelocity=Vector3.zero;o.AssemblyAngularVelocity=Vector3.zero end end end
 function Core:IsAuthorized()return authorized()end;function Core:IsRunning()return self.Running end
 function Core:Correct()local c,h,r=rig();if not c or not h or not r or not self.SafeCFrame then return false end;c:PivotTo(self.SafeCFrame);zeroCharacter(c);self.LastPosition=self.SafeCFrame.Position;self.GraceUntil=os.clock()+0.18;self.Corrections+=1;return true end
 function Core:Start()
  if self.Running then return true end;if not authorized()then return false,isES and"Función experimental no disponible."or"Experimental feature unavailable."end
  local c,h,r=rig();if not c or not h or h.Health<=0 or not r then return false,isES and"Tu personaje no está disponible."or"Your character is unavailable."end
  if AutoAnchorCore and(AutoAnchorCore.Mode or AutoAnchorCore.Busy)then return false,isES and"Desactiva primero el Ancla automática."or"Disable Automatic Anchor first."end
  if AnchorCore then if AnchorCore.TestEnabled then AnchorCore:SetTest(false)end;if AnchorCore.AnclaEnabled then AnchorCore:SetAncla(false)end;if AnchorCore.AntiSeatEnabled then AnchorCore:SetAntiSeat(false)end;if AnchorCore.HeartbeatEnabled then AnchorCore:SetHeartbeat(false)end end
  self.Running=true;self.SafeCFrame=r.CFrame;self.LastPosition=r.Position;self.GraceUntil=os.clock()+0.35;self.Corrections=0;bindPlayers()
  runtime[#runtime+1]=RunService.Heartbeat:Connect(function(dt)
   if not self.Running then return end;if(AnchorCore and(AnchorCore.TestEnabled or AnchorCore.AnclaEnabled))or(AutoAnchorCore and(AutoAnchorCore.Mode or AutoAnchorCore.Busy))then self:Stop();return end
   local character,humanoid,root=rig();if not character or not humanoid or humanoid.Health<=0 or not root then return end;if humanoid.SeatPart then self.SafeCFrame=root.CFrame;self.LastPosition=root.Position;return end
   local delta=self.LastPosition and(root.Position-self.LastPosition).Magnitude or 0;local allowed=math.max(13,(humanoid.WalkSpeed+40)*math.max(dt,1/60)*4)
   local threatened=os.clock()>self.GraceUntil and(root.AssemblyLinearVelocity.Magnitude>95 or root.AssemblyAngularVelocity.Magnitude>35 or delta>allowed)
   if threatened then self:Correct();return end;self.LastPosition=root.Position;if humanoid.FloorMaterial~=Enum.Material.Air or math.abs(root.AssemblyLinearVelocity.Y)<35 then self.SafeCFrame=root.CFrame end
  end);return true
 end
 function Core:Stop()if not self.Running then return true end;self.Running=false;disconnectRuntime();restoreCollisions();self.SafeCFrame=nil;self.LastPosition=nil;self.GraceUntil=0;if UpdateAnchorPanel then task.defer(UpdateAnchorPanel)end;return true end
 function Core:Toggle()if self.Running then return self:Stop()end;return self:Start()end
 function Core:Destroy()self:Stop();for _,c in ipairs(persistent)do c:Disconnect()end;table.clear(persistent)end
 persistent[#persistent+1]=player.CharacterAdded:Connect(function(character)if not Core.Running then return end;local root=character:WaitForChild("HumanoidRootPart",8);if root and Core.Running then Core.SafeCFrame=root.CFrame;Core.LastPosition=root.Position;Core.GraceUntil=os.clock()+1 end end)
 MobileAnchorCore=Core;return true
end