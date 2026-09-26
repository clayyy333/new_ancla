-- Test 1 local: personaje fisico arriba y clon visual en la posicion inicial.
return function(context)
 setfenv(1,context)
 local C={Running=false,Distance=100,VisualAltitude=0,Origin=nil,PhysicalPosition=nil,VisualClone=nil,CloneTrack=nil,SavedCameraType=nil,SavedCameraSubject=nil,SavedCameraCFrame=nil,SavedCollisions={},SavedTransparency={},Connections={},SelectedEmoteId=nil,SelectedEmoteName=nil,Status=isES and"Test 1 desactivado."or"Test 1 disabled."}
 local function finite(v)v=tonumber(v);return v and v==v and math.abs(v)<math.huge and v or nil end
 local function rig()local character=player.Character;return character,character and character:FindFirstChildOfClass("Humanoid"),character and character:FindFirstChild("HumanoidRootPart")end
 local function refresh(message)C.Status=message or C.Status;if UpdateInverseVerticalPanel then UpdateInverseVerticalPanel(C.Status)end end
 function C:IsRunning()return self.Running end
 function C:GetDistance()return self.Distance end
 function C:GetVisualAltitude()return self.VisualAltitude end
 function C:CaptureSelectedEmote()
  local selected=_genv().lastVexroEmote
  if type(selected)=="table"and selected.id then self.SelectedEmoteId=selected.id;self.SelectedEmoteName=selected.name or tostring(selected.id);return true end
  return self.SelectedEmoteId~=nil
 end
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
 function C:SetOriginalVisible(visible)
  local character=player.Character
  if visible then
   for part,value in pairs(self.SavedTransparency)do if part.Parent then part.LocalTransparencyModifier=value end end
   table.clear(self.SavedTransparency)
  elseif character then
   table.clear(self.SavedTransparency)
   for _,part in ipairs(character:GetDescendants())do
    if part:IsA("BasePart")then self.SavedTransparency[part]=part.LocalTransparencyModifier;part.LocalTransparencyModifier=1 end
   end
  end
 end
 function C:DestroyClone()
  if self.CloneTrack then pcall(function()self.CloneTrack:Stop(0)end);self.CloneTrack=nil end
  if self.VisualClone then self.VisualClone:Destroy();self.VisualClone=nil end
 end
 function C:CreateClone(character)
  self:DestroyClone()
  local wasArchivable=character.Archivable;character.Archivable=true
  local ok,clone=pcall(function()return character:Clone()end)
  character.Archivable=wasArchivable
  if not ok or not clone then return false end
  clone.Name="VexroTest1Visual"
  for _,object in ipairs(clone:GetDescendants())do
   if object:IsA("Script")or object:IsA("LocalScript")or object:IsA("Tool")then object:Destroy()
   elseif object:IsA("BasePart")then object.Anchored=(object.Name=="HumanoidRootPart");object.CanCollide=false;object.CanTouch=false;object.CanQuery=false;object.Massless=true;object.LocalTransparencyModifier=0 end
  end
  local cloneRoot=clone:FindFirstChild("HumanoidRootPart")
  local cloneHumanoid=clone:FindFirstChildOfClass("Humanoid")
  if not cloneRoot or not cloneHumanoid then clone:Destroy();return false end
  cloneRoot.Transparency=1;cloneHumanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;cloneHumanoid.BreakJointsOnDeath=false
  clone.Parent=workspace;clone:PivotTo(self.Origin*CFrame.new(0,self.VisualAltitude,0));self.VisualClone=clone
  if self.SelectedEmoteId then
   local animator=cloneHumanoid:FindFirstChildOfClass("Animator")or Instance.new("Animator",cloneHumanoid)
   local animation=Instance.new("Animation");animation.AnimationId="rbxassetid://"..tostring(self.SelectedEmoteId):gsub("^rbxassetid://","")
   local loaded,track=pcall(function()return animator:LoadAnimation(animation)end);animation:Destroy()
   if loaded and track then track.Looped=true;track.Priority=Enum.AnimationPriority.Action4;track:Play(0.1);self.CloneTrack=track end
  end
  return true
 end
 function C:UpdateVisual()
  if not self.Running or not self.Origin or not self.VisualClone or not self.VisualClone.Parent then return false end
  self.VisualClone:PivotTo(self.Origin*CFrame.new(0,self.VisualAltitude,0))
  if self.CloneTrack and not self.CloneTrack.IsPlaying then pcall(function()self.CloneTrack:Play(0.1)end)end
  return true
 end
 function C:AttachCamera()
  local camera=workspace.CurrentCamera
  local humanoid=self.VisualClone and self.VisualClone:FindFirstChildOfClass("Humanoid")
  if not camera or not humanoid then return false end
  camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=humanoid
  return true
 end
 function C:RestoreCamera()
  local camera=workspace.CurrentCamera
  if camera then
   camera.CameraType=self.SavedCameraType or Enum.CameraType.Custom
   if self.SavedCameraSubject and self.SavedCameraSubject.Parent then camera.CameraSubject=self.SavedCameraSubject else local _,humanoid=rig();if humanoid then camera.CameraSubject=humanoid end end
   if self.SavedCameraCFrame then camera.CFrame=self.SavedCameraCFrame end
  end
  self.SavedCameraType=nil;self.SavedCameraSubject=nil;self.SavedCameraCFrame=nil
 end
 function C:SetDistance(value)
  value=finite(value);if not value or value<0 then return false,isES and"Escribe una distancia valida mayor o igual a 0."or"Enter a valid distance greater than or equal to 0."end
  self.Distance=value
  if self.Running and self.Origin then
   self.PhysicalPosition=self.Origin*CFrame.new(0,value,0)
   if AnchorCore and AnchorCore.AnclaEnabled then AnchorCore.Checkpoint=self.PhysicalPosition end
   local _,_,root=rig();if root then root.CFrame=self.PhysicalPosition end
  end
  return true,value
 end
 function C:SetVisualAltitude(value)
  value=finite(value);if not value then return false,isES and"Escribe una altitud visual valida."or"Enter a valid visual altitude."end
  self.VisualAltitude=value;if self.Running then self:UpdateVisual()end;return true,value
 end
 function C:Start(distance,altitude)
  if self.Running then return true,self.Status end
  local ok,message=self:SetDistance(distance);if not ok then return false,message end
  ok,message=self:SetVisualAltitude(altitude);if not ok then return false,message end
  local character,humanoid,root=rig();if not character or not humanoid or humanoid.Health<=0 or not root then return false,isES and"Tu personaje no esta disponible."or"Your character is unavailable."end
  if AutoAnchorCore and(AutoAnchorCore.Mode or AutoAnchorCore.Busy)then return false,isES and"Desactiva primero el Ancla automatica."or"Disable Automatic Anchor first."end
  if VerticalControlController and VerticalControlController:IsRunning()then VerticalControlController:Stop(true)end
  if not AnchorCore then return false,isES and"El controlador de Ancla no esta disponible."or"Anchor controller is unavailable."end
  if AnchorCore.TestEnabled then AnchorCore:SetTest(false)end;if AnchorCore.AnclaEnabled then AnchorCore:SetAncla(false)end
  local camera=workspace.CurrentCamera
  if camera then self.SavedCameraType=camera.CameraType;self.SavedCameraSubject=camera.CameraSubject;self.SavedCameraCFrame=camera.CFrame;camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=self.SavedCameraCFrame end
  self.Origin=root.CFrame;self.PhysicalPosition=self.Origin*CFrame.new(0,self.Distance,0);self:CaptureSelectedEmote();self.Running=true
  if not self:CreateClone(character)then self.Running=false;self:RestoreCamera();return false,isES and"No se pudo crear la imagen visual del personaje."or"The visual character could not be created."end
  self:SetOriginalVisible(false);self:SetCharacterCollisions(true)
  root.Anchored=false
  local deadline=os.clock()+0.35
  repeat
   if not self.Running or not root.Parent then self:Stop(false);return false,isES and"Se interrumpio el desplazamiento."or"Displacement was interrupted."end
   root.CFrame=self.PhysicalPosition;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
   if camera and self.SavedCameraCFrame then camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=self.SavedCameraCFrame end
   RunService.Heartbeat:Wait()
  until os.clock()>=deadline
  local anchored,anchorMessage=AnchorCore:SetAncla(true)
  if not anchored then self:Stop(true);return false,anchorMessage end
  AnchorCore.Checkpoint=self.PhysicalPosition;AnchorCore:SetAntiSeat(true);AnchorCore:SetHeartbeat(true)
  self:UpdateVisual();self:AttachCamera()
  self.Connections[#self.Connections+1]=RunService.Heartbeat:Connect(function()if C.Running then C:UpdateVisual()end end)
  self.Status=isES and"Test 1 activo (visual local)."or"Test 1 active (local visual).";refresh();return true,self.Status
 end
 function C:Stop(restore)
  local wasRunning=self.Running;self.Running=false
  for _,connection in ipairs(self.Connections)do pcall(function()connection:Disconnect()end)end;table.clear(self.Connections)
  self:SetOriginalVisible(true);self:SetCharacterCollisions(false);self:RestoreCamera();self:DestroyClone()
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