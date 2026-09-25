-- Test 1: HRP fisico abajo, cuerpo visual y camara arriba.
return function(context)
 setfenv(1,context)
 local C={Running=false,Distance=100,VisualAltitude=0,Origin=nil,Lower=nil,Joint=nil,C0=nil,C1=nil,CameraAnchor=nil,SavedCameraType=nil,SavedCameraSubject=nil,SavedCameraCFrame=nil,LastCameraAnchorPosition=nil,Connections={},Status=isES and "Test 1 desactivado."or"Test 1 disabled."}
 local function finite(v)v=tonumber(v);return v and v==v and math.abs(v)<math.huge and v or nil end
 local function rig()local c=player.Character;return c,c and c:FindFirstChildOfClass("Humanoid"),c and c:FindFirstChild("HumanoidRootPart")end
 local function refresh(m)C.Status=m or C.Status;if UpdateInverseVerticalPanel then UpdateInverseVerticalPanel(C.Status)end end
 function C:IsRunning()return self.Running end
 function C:GetDistance()return self.Distance end
 function C:GetVisualAltitude()return self.VisualAltitude end
 function C:RestoreVisual()
  if self.Joint and self.Joint.Parent then if self.C0 then self.Joint.C0=self.C0 end;if self.C1 then self.Joint.C1=self.C1 end end
  self.Joint=nil;self.C0=nil;self.C1=nil
 end
 function C:GetJoint(character,root)
  if self.Joint and self.Joint.Parent and(self.Joint.Part0==root or self.Joint.Part1==root)then return self.Joint end
  self:RestoreVisual()
  for _,j in ipairs(character:GetDescendants())do
   if j:IsA("Motor6D")and(j.Part0==root or j.Part1==root)then self.Joint=j;self.C0=j.C0;self.C1=j.C1;return j end
  end
 end
 function C:Apply()
  if not self.Running or not self.Origin then return false end
  local character,humanoid,root=rig();if not character or not humanoid or humanoid.Health<=0 or not root then return false end
  local joint=self:GetJoint(character,root);if not joint then return false end
  local shift=CFrame.new(0,self.Distance+self.VisualAltitude,0)
  if joint.Part0==root then joint.C0=self.C0*shift else joint.C1=self.C1*shift:Inverse()end
  if self.CameraAnchor and self.CameraAnchor.Parent then
   local desired=self.Origin*CFrame.new(0,self.VisualAltitude+2,0)
   local previous=self.LastCameraAnchorPosition
   self.CameraAnchor.CFrame=desired
   local camera=workspace.CurrentCamera
   if previous and camera and camera.CameraSubject==self.CameraAnchor then
    local delta=desired.Position-previous
    if delta.Magnitude>.001 then camera.CFrame=camera.CFrame+delta end
   end
   self.LastCameraAnchorPosition=desired.Position
  end
  return true
 end
 function C:CreateCamera()
  local camera=workspace.CurrentCamera;if not camera then return end
  self.SavedCameraType=self.SavedCameraType or camera.CameraType;self.SavedCameraSubject=self.SavedCameraSubject or camera.CameraSubject;self.SavedCameraCFrame=self.SavedCameraCFrame or camera.CFrame
  local anchor=Instance.new("Part");anchor.Name="InverseVerticalCameraAnchor";anchor.Size=Vector3.new(1,1,1);anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CFrame=self.Origin*CFrame.new(0,self.VisualAltitude+2,0);anchor.Parent=workspace
  self.CameraAnchor=anchor;self.LastCameraAnchorPosition=anchor.Position;camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=anchor;if self.SavedCameraCFrame then camera.CFrame=self.SavedCameraCFrame end
 end
 function C:RestoreCamera()
  local camera=workspace.CurrentCamera
  if camera then camera.CameraType=self.SavedCameraType or Enum.CameraType.Custom;if self.SavedCameraSubject and self.SavedCameraSubject.Parent then camera.CameraSubject=self.SavedCameraSubject else local _,h=rig();if h then camera.CameraSubject=h end end end
  if self.CameraAnchor then self.CameraAnchor:Destroy();self.CameraAnchor=nil end
  self.SavedCameraType=nil;self.SavedCameraSubject=nil;self.SavedCameraCFrame=nil;self.LastCameraAnchorPosition=nil
 end
 function C:SetDistance(v)
  v=finite(v);if not v or v<0 then return false,isES and"Escribe una distancia valida mayor o igual a 0."or"Enter a valid distance greater than or equal to 0."end
  self.Distance=v
  if self.Running and self.Origin then self.Lower=self.Origin*CFrame.new(0,-v,0);if AnchorCore and AnchorCore.TestEnabled then AnchorCore.TestCheckpoint=self.Lower end;local _,_,root=rig();if root then root.CFrame=self.Lower end;self:Apply()end
  return true,v
 end
 function C:SetVisualAltitude(v)
  v=finite(v);if not v then return false,isES and"Escribe una altitud visual valida."or"Enter a valid visual altitude."end
  self.VisualAltitude=v;if self.Running then self:Apply()end;return true,v
 end
 function C:Start(distance,altitude)
  if self.Running then return true,self.Status end
  local ok,msg=self:SetDistance(distance);if not ok then return false,msg end;ok,msg=self:SetVisualAltitude(altitude);if not ok then return false,msg end
  local character,humanoid,root=rig();if not character or not humanoid or humanoid.Health<=0 or not root then return false,isES and"Tu personaje no esta disponible."or"Your character is unavailable."end
  if AutoAnchorCore and(AutoAnchorCore.Mode or AutoAnchorCore.Busy)then return false,isES and"Desactiva primero el Ancla automatica."or"Disable Automatic Anchor first."end
  if VerticalControlController and VerticalControlController:IsRunning()then VerticalControlController:Stop(true)end
  if not AnchorCore then return false,isES and"El controlador de Ancla no esta disponible."or"Anchor controller is unavailable."end
  if AnchorCore.TestEnabled then AnchorCore:SetTest(false)end
  local camera=workspace.CurrentCamera
  if camera then self.SavedCameraType=camera.CameraType;self.SavedCameraSubject=camera.CameraSubject;self.SavedCameraCFrame=camera.CFrame end
  self.Origin=root.CFrame;self.Lower=self.Origin*CFrame.new(0,-self.Distance,0);root.CFrame=self.Lower;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero;self.Running=true
  local anchored,message=AnchorCore:SetTest(true);if not anchored then self.Running=false;root.CFrame=self.Origin;return false,message end
  AnchorCore.TestCheckpoint=self.Lower;self:CreateCamera();self:Apply()
  self.Connections[#self.Connections+1]=RunService.RenderStepped:Connect(function()if C.Running then C:Apply()end end)
  self.Status=isES and"Test 1 activo."or"Test 1 active.";refresh();return true,self.Status
 end
 function C:Stop(restore)
  local was=self.Running;self.Running=false
  for _,connection in ipairs(self.Connections)do pcall(function()connection:Disconnect()end)end;table.clear(self.Connections)
  self:RestoreVisual();self:RestoreCamera();if AnchorCore and AnchorCore.TestEnabled then AnchorCore:SetTest(false)end
  local origin=self.Origin;self.Origin=nil;self.Lower=nil
  if restore~=false and origin then local _,_,root=rig();if root then root.CFrame=origin;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end end
  self.Status=isES and"Test 1 desactivado; posicion restaurada."or"Test 1 disabled; position restored.";refresh();return was,self.Status
 end
 function C:Destroy()self:Stop(true);if self.Removing then self.Removing:Disconnect()end;if self.Added then self.Added:Disconnect()end end
 C.Removing=player.CharacterRemoving:Connect(function()if C.Running then C:RestoreVisual()end end)
 C.Added=player.CharacterAdded:Connect(function(character)
  if not C.Running or not C.Lower then return end
  task.defer(function()
   local root=character:WaitForChild("HumanoidRootPart",8);local humanoid=character:WaitForChild("Humanoid",8);if not C.Running or not root or not humanoid then return end
   root.CFrame=C.Lower;if AnchorCore then AnchorCore.TestCheckpoint=C.Lower;if not AnchorCore.TestEnabled then AnchorCore:SetTest(true)end end;task.wait(.15);C:Apply()
  end)
 end)
 InverseVerticalController=C
 return true
end