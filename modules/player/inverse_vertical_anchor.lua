-- Test 1 independiente: HRP arriba y desplazamiento visual propio hacia abajo.
return function(context)
 setfenv(1,context)
 local C={Running=false,Distance=100,VisualAltitude=0,Origin=nil,PhysicalPosition=nil,VisualJoint=nil,VisualC0=nil,VisualC1=nil,CameraAnchor=nil,SavedCameraType=nil,SavedCameraSubject=nil,SavedCameraCFrame=nil,SavedCollisions={},Connection=nil,Removing=nil,Status=isES and"Test 1 desactivado."or"Test 1 disabled."}
 local function finite(value)value=tonumber(value);return value and value==value and math.abs(value)<math.huge and value or nil end
 local function rig()local character=player.Character;return character,character and character:FindFirstChildOfClass("Humanoid"),character and character:FindFirstChild("HumanoidRootPart")end
 local function refresh(message)C.Status=message or C.Status;if UpdateInverseVerticalPanel then UpdateInverseVerticalPanel(C.Status)end end
 function C:IsRunning()return self.Running end
 function C:GetDistance()return self.Distance end
 function C:GetVisualAltitude()return self.VisualAltitude end
 function C:SetCharacterCollisions(disabled)
  local character=player.Character
  if disabled then
   table.clear(self.SavedCollisions)
   if character then for _,part in ipairs(character:GetDescendants())do if part:IsA("BasePart")then self.SavedCollisions[part]=part.CanCollide;part.CanCollide=false end end end
  else
   for part,value in pairs(self.SavedCollisions)do if part.Parent then part.CanCollide=value end end
   table.clear(self.SavedCollisions)
  end
 end
 function C:RestoreVisual()
  if self.VisualJoint and self.VisualJoint.Parent then if self.VisualC0 then self.VisualJoint.C0=self.VisualC0 end;if self.VisualC1 then self.VisualJoint.C1=self.VisualC1 end end
  self.VisualJoint=nil;self.VisualC0=nil;self.VisualC1=nil
 end
 function C:GetRootJoint(character,root)
  if self.VisualJoint and self.VisualJoint.Parent and(self.VisualJoint.Part0==root or self.VisualJoint.Part1==root)then return self.VisualJoint end
  self:RestoreVisual()
  local joint=root:FindFirstChild("RootJoint")
  if not joint or not joint:IsA("Motor6D")then
   for _,candidate in ipairs(character:GetDescendants())do if candidate:IsA("Motor6D")and candidate.Name=="RootJoint"and(candidate.Part0==root or candidate.Part1==root)then joint=candidate;break end end
  end
  if not joint or not joint:IsA("Motor6D")then
   for _,candidate in ipairs(character:GetDescendants())do if candidate:IsA("Motor6D")and(candidate.Part0==root or candidate.Part1==root)then joint=candidate;break end end
  end
  if not joint then return nil end
  self.VisualJoint=joint;self.VisualC0=joint.C0;self.VisualC1=joint.C1;return joint
 end
 function C:ApplyVisual()
  if not self.Running then return false end
  local character,humanoid,root=rig();if not character or not humanoid or humanoid.Health<=0 or not root then return false end
  local joint=self:GetRootJoint(character,root);if not joint then return false end
  local shift=CFrame.new(0,-self.Distance+self.VisualAltitude,0)
  if joint.Part0==root then joint.C0=self.VisualC0*shift else joint.C1=self.VisualC1*shift:Inverse()end
  root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  return true
 end
 function C:CreateCamera()
  local camera=workspace.CurrentCamera;if not camera or not self.Origin then return end
  if self.CameraAnchor then self.CameraAnchor:Destroy()end
  local anchor=Instance.new("Part");anchor.Name="VexroTest1Camera";anchor.Size=Vector3.new(1,1,1);anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CFrame=CFrame.new(self.Origin.Position+Vector3.new(0,self.VisualAltitude+2,0))*self.Origin.Rotation;anchor.Parent=workspace
  self.CameraAnchor=anchor;camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=anchor
 end
 function C:UpdateCamera()
  if self.CameraAnchor and self.CameraAnchor.Parent and self.Origin then self.CameraAnchor.CFrame=CFrame.new(self.Origin.Position+Vector3.new(0,self.VisualAltitude+2,0))*self.Origin.Rotation end
 end
 function C:RestoreCamera()
  local camera=workspace.CurrentCamera
  if camera then camera.CameraType=self.SavedCameraType or Enum.CameraType.Custom;if self.SavedCameraSubject and self.SavedCameraSubject.Parent then camera.CameraSubject=self.SavedCameraSubject else local _,humanoid=rig();if humanoid then camera.CameraSubject=humanoid end end;if self.SavedCameraCFrame then camera.CFrame=self.SavedCameraCFrame end end
  if self.CameraAnchor then self.CameraAnchor:Destroy();self.CameraAnchor=nil end
  self.SavedCameraType=nil;self.SavedCameraSubject=nil;self.SavedCameraCFrame=nil
 end
 function C:SetDistance(value)
  value=finite(value);if not value or value<0 then return false,isES and"Escribe una distancia valida mayor o igual a 0."or"Enter a valid distance greater than or equal to 0."end
  self.Distance=value
  if self.Running and self.Origin then self.PhysicalPosition=self.Origin*CFrame.new(0,value,0);local _,_,root=rig();if root then root.CFrame=self.PhysicalPosition end;if AnchorCore and AnchorCore.AnclaEnabled then AnchorCore.Checkpoint=self.PhysicalPosition end;self:ApplyVisual()end
  return true,value
 end
 function C:SetVisualAltitude(value)
  value=finite(value);if not value then return false,isES and"Escribe una altitud visual valida."or"Enter a valid visual altitude."end
  self.VisualAltitude=value;if self.Running then self:ApplyVisual();self:UpdateCamera()end;return true,value
 end
 function C:Start(distance,altitude)
  if self.Running then return true,self.Status end
  local ok,message=self:SetDistance(distance);if not ok then return false,message end;ok,message=self:SetVisualAltitude(altitude);if not ok then return false,message end
  local character,humanoid,root=rig();if not character or not humanoid or humanoid.Health<=0 or not root then return false,isES and"Tu personaje no esta disponible."or"Your character is unavailable."end
  if not AnchorCore then return false,isES and"El controlador de Ancla no esta disponible."or"Anchor controller is unavailable."end
  if AutoAnchorCore and(AutoAnchorCore.Mode or AutoAnchorCore.Busy)then return false,isES and"Desactiva primero el Ancla automatica."or"Disable Automatic Anchor first."end
  if AnchorCore.TestEnabled then AnchorCore:SetTest(false)end;if AnchorCore.AnclaEnabled then AnchorCore:SetAncla(false)end
  local camera=workspace.CurrentCamera
  if camera then self.SavedCameraType=camera.CameraType;self.SavedCameraSubject=camera.CameraSubject;self.SavedCameraCFrame=camera.CFrame;camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=self.SavedCameraCFrame end
  self.Origin=root.CFrame;self.PhysicalPosition=self.Origin*CFrame.new(0,self.Distance,0);self.Running=true
  root.Anchored=false
  local deadline=os.clock()+0.45
  repeat
   root.CFrame=self.PhysicalPosition;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
   if camera then camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=self.SavedCameraCFrame end
   RunService.Heartbeat:Wait()
  until os.clock()>=deadline or not root.Parent
  if not root.Parent then self.Running=false;self:RestoreCamera();self.Origin=nil;self.PhysicalPosition=nil;return false,isES and"Se interrumpio el desplazamiento."or"Displacement was interrupted."end
  local anchored,anchorMessage=AnchorCore:SetAncla(true);if not anchored then self.Running=false;root.CFrame=self.Origin;self:RestoreCamera();self.Origin=nil;self.PhysicalPosition=nil;return false,anchorMessage end
  AnchorCore.Checkpoint=self.PhysicalPosition;AnchorCore:SetAntiSeat(true);AnchorCore:SetHeartbeat(true)
  self:SetCharacterCollisions(true);self:ApplyVisual();self:CreateCamera();self:UpdateCamera()
  self.Connection=RunService.Heartbeat:Connect(function()if C.Running then C:ApplyVisual()end end)
  self.Status=isES and"Test 1 activo."or"Test 1 active.";refresh();return true,self.Status
 end
 function C:Stop(restore)
  local wasRunning=self.Running;self.Running=false
  if self.Connection then self.Connection:Disconnect();self.Connection=nil end
  self:RestoreVisual();self:SetCharacterCollisions(false);self:RestoreCamera()
  if AnchorCore then if AnchorCore.HeartbeatEnabled then AnchorCore:SetHeartbeat(false)end;if AnchorCore.AntiSeatEnabled then AnchorCore:SetAntiSeat(false)end;if AnchorCore.AnclaEnabled then AnchorCore:SetAncla(false)end end
  local origin=self.Origin;self.Origin=nil;self.PhysicalPosition=nil
  if restore~=false and origin then local _,_,root=rig();if root then root.CFrame=origin;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end end
  self.Status=isES and"Test 1 desactivado; posicion restaurada."or"Test 1 disabled; position restored.";refresh();return wasRunning,self.Status
 end
 function C:Destroy()self:Stop(true);if self.Removing then self.Removing:Disconnect();self.Removing=nil end end
 C.Removing=player.CharacterRemoving:Connect(function()if C.Running then C:Stop(false)end end)
 InverseVerticalController=C
 return true
end