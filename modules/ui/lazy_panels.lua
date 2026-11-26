-- Build category panels only when their navigation entry is first opened.
return function(context)
 setfenv(1,context)
 local groups={
  settings={"ui/settings","ui/admin_panel","ui/combo_queue"},
  friends={"ui/friends","player/friend_follow","ui/friend_follow"},
  playlists={"ui/playlists"},
  keybinds={"ui/keybinds_panel"},
  anchor={"ui/anchor"},
  move_anchored={"ui/move_anchored"},
  anchor_auto={"ui/anchor_auto"},
  fling2={"ui/fling2"},
  no_entrar={"player/nan_personalizado_runtime","ui/nan_personalizado"},
  fling_custom={"ui/fling_custom"},
  contact_fling={"ui/contact_fling"},
  fling_moto={"ui/fling_moto"},
  fling_moto_xeno={"ui/fling_moto_xeno"},
  fling_experimental={"ui/fling_experimental"},
  fling_car={"ui/fling_car"},
  fling_car2={"ui/fling_car2"},
  fling_object={"ui/fling_object"},
  fps_booster={"ui/graphics"},
  shaders={"ui/shaders"},
  clothing_scan={"ui/clothing_scan_reader","ui/clothing_scan"},
  camera_control={"ui/camera_control"},
  gift_delivery={"ui/gift_delivery"},
  cinematic_camera={"ui/cinematic_camera"},
  flight_control={"ui/flight_control"},
  car_control={"ui/car_control"},
  free_car_control={"ui/free_car_control"},
  movement_control={"ui/movement_control"},
  vertical_control={"ui/vertical_control"},
  couples={"ui/couples"},
  couple_movement={"ui/couple_movement"},
  poses={"ui/poses"},
  preset_poses={"ui/preset_poses"},
 }
 local Core={Alive=true,States={},Modules={},Active=nil,Queue={}}
 LazyPanels=Core
 local overlay=Instance.new("TextLabel");overlay.Name="PanelPreparation";overlay.Size=UDim2.new(1,-24,1,-(titleH+24));overlay.Position=UDim2.fromOffset(12,titleH+12);overlay.BackgroundTransparency=1;overlay.TextColor3=currentTheme.text;overlay.Font=Enum.Font.GothamMedium;overlay.TextSize=13;overlay.TextWrapped=true;overlay.Visible=false;overlay.ZIndex=18;overlay.Parent=content;RegisterTheme(overlay,"TextColor3","text")
 local scheduled=false
 local pump
 function Core:Show(tab,waiting)
  overlay.Visible=waiting==true
  if not waiting then return end
  local state=self.States[tab]
  overlay.Text=state and state.Error and(isES and"No se pudo preparar. Pulsa la categoría para reintentar."or"Could not prepare. Select the category to retry.")or(isES and"Preparando sección..."or"Preparing section...")
  scroll.Visible=false;search.Visible=false;pageBar.Visible=false;emptyLbl.Visible=false
  if CatalogLoadPanel then CatalogLoadPanel.Panel.Visible=false end
  for _,name in ipairs({"playlistBackBtn","playlistDoneBtn"})do if context[name]then context[name].Visible=false end end
 end
 local function loadOne(path)
  if Core.Modules[path]then return end
  if not Core.Alive then error("Panel preparation cancelled")end
  local initializer=loadModule(path)
  if not Core.Alive then error("Panel preparation cancelled")end
  if type(initializer)=="string"then
   local compile=loadstring or load
   local chunk,message=compile(initializer,"="..path);assert(chunk,message);initializer=chunk()
  end
  assert(type(initializer)=="function","Invalid panel module: "..path)
  -- Roll back any UI instances created by a failing initializer.
  local created={}
  local previous={}
  local function exported(name)
   return type(name)=="string"and(name:match("Panel$")or name:match("^Update")or name:match("^Make")or name=="ApplyTheme")
  end
  for name,value in pairs(context)do if exported(name)then previous[name]=value end end
  local connection=gui.DescendantAdded:Connect(function(item)created[#created+1]=item end)
  local ok,err=xpcall(function()initializer(context)end,debug.traceback)
  connection:Disconnect()
  if not ok or not Core.Alive then
   for i=#created,1,-1 do pcall(function()created[i]:Destroy()end)end
   for name in pairs(context)do if exported(name)then context[name]=previous[name]end end
   error(err or"Panel preparation cancelled")
  end
  Core.Modules[path]=true
  if RegisterFeatureController and LocalEmoteFollow then RegisterFeatureController(LocalEmoteFollow)end
 end
 pump=function()
  scheduled=false
  if not Core.Alive or Core.Active then return end
  local tab=table.remove(Core.Queue,1)
  if not tab then return end
  Core.Active=tab
  local state=Core.States[tab]
  task.spawn(function()
   local ok,err=xpcall(function()
    for _,path in ipairs(groups[tab])do
     if not Core.Alive then error("Panel preparation cancelled")end
     task.wait();loadOne(path)
    end
   end,debug.traceback)
   Core.Active=nil;state.Loading=false;state.Loaded=ok and Core.Alive;state.Error=not ok and tostring(err)or nil
   if not Core.Alive then return end
   if not ok then warn("[Panel preparation] "..tab..": "..tostring(err))end
   if currentTab==tab and UpdateTabData then UpdateTabData(false)end
   if #Core.Queue>0 then scheduled=true;task.defer(pump)end
  end)
 end
 function Core:IsPending(tab)
  local state=self.States[tab]
  return groups[tab]~=nil and not(state and state.Loaded)
 end
 function Core:Ensure(tab,retry)
  local group=groups[tab]
  if not group then return true end
  if not self.Alive then return false end
  if tab=="gift_delivery"and game.GameId~=4540138978 then return false end
  local state=self.States[tab]
  if not state then state={Loaded=false,Loading=false};self.States[tab]=state end
  if state.Loaded then return true end
  if state.Loading then return false end
  if state.Error and not retry then return false end
  state.Error=nil;state.Loading=true;self.Queue[#self.Queue+1]=tab
  if not scheduled and not self.Active then scheduled=true;task.defer(pump)end
  return false
 end
 function Core:Destroy()
  self.Alive=false;table.clear(self.Queue)
  if overlay.Parent then overlay:Destroy()end
 end
 return true
end
