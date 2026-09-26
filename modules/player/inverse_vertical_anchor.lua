-- Test 1: inicia arriba y reutiliza el desplazamiento vertical original.
return function(context)
 setfenv(1,context)
 local C={Running=false,Distance=100,VisualAltitude=0,Origin=nil,PhysicalPosition=nil,Status=isES and"Test 1 desactivado."or"Test 1 disabled."}
 local function finite(value)value=tonumber(value);return value and value==value and math.abs(value)<math.huge and value or nil end
 local function rig()local character=player.Character;return character,character and character:FindFirstChildOfClass("Humanoid"),character and character:FindFirstChild("HumanoidRootPart")end
 local function refresh(message)C.Status=message or C.Status;if UpdateInverseVerticalPanel then UpdateInverseVerticalPanel(C.Status)end end
 function C:IsRunning()return self.Running end
 function C:GetDistance()return self.Distance end
 function C:GetVisualAltitude()return self.VisualAltitude end
 function C:VisualOffset()return-self.Distance+self.VisualAltitude end
 function C:KeepOriginalCameraReference()
  if not VerticalControlController or not self.Origin then return end
  VerticalControlController.Checkpoint=self.Origin
  local anchor=VerticalControlController.CameraAnchor
  if anchor and anchor.Parent then anchor.CFrame=CFrame.new(self.Origin.Position+Vector3.new(0,2,0))*self.Origin.Rotation end
 end
 function C:SetDistance(value)
  value=finite(value);if not value or value<0 then return false,isES and"Escribe una distancia valida mayor o igual a 0."or"Enter a valid distance greater than or equal to 0."end
  self.Distance=value
  if self.Running and self.Origin then
   self.PhysicalPosition=self.Origin*CFrame.new(0,value,0)
   local _,_,root=rig();if root then root.CFrame=self.PhysicalPosition;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
   if AnchorCore and AnchorCore.AnclaEnabled then AnchorCore.Checkpoint=self.PhysicalPosition end
   if VerticalControlController then VerticalControlController:SetOffset(self:VisualOffset());self:KeepOriginalCameraReference()end
  end
  return true,value
 end
 function C:SetVisualAltitude(value)
  value=finite(value);if not value then return false,isES and"Escribe una altitud visual valida."or"Enter a valid visual altitude."end
  self.VisualAltitude=value
  if self.Running and VerticalControlController then VerticalControlController:SetOffset(self:VisualOffset());self:KeepOriginalCameraReference()end
  return true,value
 end
 function C:Start(distance,altitude)
  if self.Running then return true,self.Status end
  local ok,message=self:SetDistance(distance);if not ok then return false,message end
  ok,message=self:SetVisualAltitude(altitude);if not ok then return false,message end
  local _,humanoid,root=rig();if not humanoid or humanoid.Health<=0 or not root then return false,isES and"Tu personaje no esta disponible."or"Your character is unavailable."end
  if not AnchorCore or not VerticalControlController then return false,isES and"Los controladores necesarios no estan disponibles."or"The required controllers are unavailable."end
  if AutoAnchorCore and(AutoAnchorCore.Mode or AutoAnchorCore.Busy)then return false,isES and"Desactiva primero el Ancla automatica."or"Disable Automatic Anchor first."end
  if VerticalControlController:IsRunning()then VerticalControlController:Stop(true)end
  if AnchorCore.TestEnabled then AnchorCore:SetTest(false)end;if AnchorCore.AnclaEnabled then AnchorCore:SetAncla(false)end
  local camera=workspace.CurrentCamera
  local savedCameraType=camera and camera.CameraType;local savedCameraSubject=camera and camera.CameraSubject;local savedCameraCFrame=camera and camera.CFrame
  if camera then camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=savedCameraCFrame end
  self.Origin=root.CFrame;self.PhysicalPosition=self.Origin*CFrame.new(0,self.Distance,0)
  -- Primero sube el personaje completo como un desplazamiento normal.
  root.Anchored=false
  local deadline=os.clock()+0.45
  repeat
   root.CFrame=self.PhysicalPosition;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
   RunService.Heartbeat:Wait()
  until os.clock()>=deadline or not root.Parent
  if not root.Parent then if camera then camera.CameraType=savedCameraType;camera.CameraSubject=savedCameraSubject;camera.CFrame=savedCameraCFrame end;self.Origin=nil;self.PhysicalPosition=nil;return false,isES and"Se interrumpio el desplazamiento."or"Displacement was interrupted."end
  -- El ancla fisica queda arriba.
  local anchored,anchorMessage=AnchorCore:SetAncla(true);if not anchored then root.CFrame=self.Origin;if camera then camera.CameraType=savedCameraType;camera.CameraSubject=savedCameraSubject;camera.CFrame=savedCameraCFrame end;self.Origin=nil;self.PhysicalPosition=nil;return false,anchorMessage end
  AnchorCore.Checkpoint=self.PhysicalPosition;AnchorCore:SetAntiSeat(true);AnchorCore:SetHeartbeat(true)
  -- Reutiliza literalmente el flujo vertical que ya funciona.
  -- Running permanece falso durante Start para evitar que su proteccion mutua cancele Test 1.
  local originalLockCamera=VerticalControlController.LockCamera
  VerticalControlController.LockCamera=function()end
  local callOk,started,verticalMessage=pcall(VerticalControlController.Start,VerticalControlController,self:VisualOffset())
  VerticalControlController.LockCamera=originalLockCamera
  if not callOk or not started then
   AnchorCore:SetHeartbeat(false);AnchorCore:SetAntiSeat(false);AnchorCore:SetAncla(false);root.CFrame=self.Origin
   if camera then camera.CameraType=savedCameraType;camera.CameraSubject=savedCameraSubject;camera.CFrame=savedCameraCFrame end
   self.Origin=nil;self.PhysicalPosition=nil;return false,verticalMessage
  end
  self.Running=true
  -- Crea la camara original directamente abajo; nunca pasa por la posicion fisica superior.
  VerticalControlController.Checkpoint=self.Origin
  if camera then camera.CameraType=savedCameraType;camera.CameraSubject=savedCameraSubject;camera.CFrame=savedCameraCFrame end
  originalLockCamera(VerticalControlController)
  self:KeepOriginalCameraReference();VerticalControlController:Apply()
  self.Status=isES and"Test 1 activo."or"Test 1 active.";refresh();return true,self.Status
 end
 function C:Stop(restore)
  local wasRunning=self.Running;self.Running=false
  if VerticalControlController and VerticalControlController:IsRunning()then VerticalControlController:Stop(false)end
  if AnchorCore then if AnchorCore.HeartbeatEnabled then AnchorCore:SetHeartbeat(false)end;if AnchorCore.AntiSeatEnabled then AnchorCore:SetAntiSeat(false)end;if AnchorCore.AnclaEnabled then AnchorCore:SetAncla(false)end end
  local origin=self.Origin;self.Origin=nil;self.PhysicalPosition=nil
  if restore~=false and origin then local _,_,root=rig();if root then root.CFrame=origin;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end end
  self.Status=isES and"Test 1 desactivado; posicion restaurada."or"Test 1 disabled; position restored.";refresh();return wasRunning,self.Status
 end
 function C:Destroy()self:Stop(true);if self.Removing then self.Removing:Disconnect()end end
 C.Removing=player.CharacterRemoving:Connect(function()if C.Running then C:Stop(false)end end)
 InverseVerticalController=C
 return true
end