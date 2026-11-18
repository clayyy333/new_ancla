-- Catalogs are fetched only after an explicit button press in their section.
return function(context)
 setfenv(1,context)
 local Core={Alive=true,Active=nil,Emotes={Loaded=false,Loading=false,Progress=0},Animations={Loaded=false,Loading=false,Progress=0}}
 CatalogLoadState=Core
 local function changed()if CatalogLoadPanel then CatalogLoadPanel:Refresh()end end
 function Core:ForTab(tab)
  if tab=="animations"then return "Animations"end
  if tab=="emotes"or tab=="favorites"or tab=="recent"or tab=="playlists"or tab=="keybinds"then return "Emotes"end
 end
 function Core:IsPending(tab)
  local kind=self:ForTab(tab)
  return kind~=nil and not self[kind].Loaded
 end
 function Core:Load(kind)
  local state=self[kind]
  if not self.Alive or not state or state.Loaded or self.Active then return false end
  self.Active=kind;state.Loading=true;state.Error=nil;state.Progress=0;state.Stage="download";changed()
  task.spawn(function()
   local function report(value,stage)
    if not Core.Alive then error("Catalog load cancelled")end
    state.Progress=math.max(state.Progress,math.min(value,.99));state.Stage=stage;changed()
   end
   local ok,err=xpcall(function()
    if kind=="Emotes"then
     state.Fallback=LoadEmotes(report)
     local byId={}
     for index,emote in ipairs(Emotes)do
      emote._lname=emote.name:lower();byId[emote.id]=emote
      if index%100==0 then report(.92+.07*index/math.max(1,#Emotes),"index");task.wait()end
     end
     report(.99,"index");EmotesById=byId
    else
     state.Fallback=LoadAnimations(report)
    end
    if not Core.Alive then error("Catalog load cancelled")end
    state.Loaded=true;state.Progress=1;state.Stage="done"
   end,debug.traceback)
   state.Loading=false;Core.Active=nil
   if not Core.Alive then return end
   if not ok then state.Error=tostring(err);state.Stage="error";state.Loaded=false end
   changed()
   if ok and kind=="Animations"and RestoreSavedAnimationSelection then RestoreSavedAnimationSelection()end
   if UpdateTabData then UpdateTabData()end
  end)
  return true
 end
 function Core:Destroy()self.Alive=false end
 MakeRow,MakeSectionHeader,MakePillToggle=nil,nil,nil
 return true
end
