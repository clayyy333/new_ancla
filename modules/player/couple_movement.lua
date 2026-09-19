return function(context)
 setfenv(1,context)
 local C={Selected=nil,Speed=1,StartTime=0,EndTime=5,Looping=false,Connection=nil}
 Settings.coupleLoops=type(Settings.coupleLoops)=="table" and Settings.coupleLoops or {}
 Settings.couplePoses=type(Settings.couplePoses)=="table" and Settings.couplePoses or {}
 local function roundHalf(v)return math.floor((tonumber(v)or 0)*2+0.5)/2 end
 function C:Find(query)
  query=tostring(query or ""):lower():gsub("^%s+",""):gsub("%s+$","")
  local id=tonumber(query)
  for _,e in ipairs(Emotes)do if (id and tonumber(e.id)==id)or tostring(e.name):lower()==query then self.Selected=e;return e end end
  return nil
 end
 function C:GetSelected()return self.Selected end
 function C:SetSpeed(v)self.Speed=math.clamp(roundHalf(v),.5,3);if currentAnimTrack then pcall(function()currentAnimTrack:AdjustSpeed(self.Speed)end)end end
 function C:SetStart(v)self.StartTime=math.max(0,roundHalf(v));if self.EndTime<=self.StartTime then self.EndTime=self.StartTime+.5 end end
 function C:SetEnd(v)local max=(currentAnimTrack and currentAnimTrack.Length>0)and currentAnimTrack.Length or 999;self.EndTime=math.clamp(roundHalf(v),self.StartTime+.5,max)end
 function C:Preview()
  if not self.Selected then return false,isES and"Busca un emote por nombre o ID."or"Find an emote by name or ID."end
  PlayEmote(self.Selected.id,self.Selected.name);task.wait(.12)
  if not currentAnimTrack then return false,isES and"No se pudo cargar el emote."or"Could not load the emote."end
  if currentAnimTrack.Length>0 then self.EndTime=math.min(self.EndTime,math.floor(currentAnimTrack.Length*2)/2) end
  currentAnimTrack.Looped=false;currentAnimTrack.TimePosition=math.min(self.StartTime,math.max(0,currentAnimTrack.Length-.05));currentAnimTrack:AdjustSpeed(self.Speed);self.Looping=true
  return true
 end
 function C:StopLoop()self.Looping=false end
 function C:SaveLoop()
  if not self.Selected then return false end
  local item={name=self.Selected.name,id=self.Selected.id,speed=self.Speed,start=self.StartTime,finish=self.EndTime}
  Settings.coupleLoops[#Settings.coupleLoops+1]=item;SaveLocalData();return true,item
 end
 function C:SavePose(loopIndex)
  local loop=Settings.coupleLoops[loopIndex];if not loop then return false end
  local pose={name=loop.name,id=loop.id,speed=loop.speed,start=loop.start,finish=loop.finish,distance=CouplesPositionController:GetDistance(),height=CouplesPositionController:GetHeight(),orbit=CouplesPositionController:GetAngle(),rotation=CouplesPositionController:GetSelfAngle()}
  Settings.couplePoses[#Settings.couplePoses+1]=pose;SaveLocalData();return true
 end
 C.Connection=RunService.Heartbeat:Connect(function()if C.Looping and currentAnimTrack and currentAnimTrack.IsPlaying and currentAnimTrack.TimePosition>=C.EndTime then currentAnimTrack.TimePosition=C.StartTime;currentAnimTrack:AdjustSpeed(C.Speed)end end)
 function C:Destroy()if self.Connection then self.Connection:Disconnect()end end
 CoupleMovementController=C;return true
end