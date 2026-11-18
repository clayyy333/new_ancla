-- Explicit per-section loading, with a light progress card and no startup requests.
return function(context)
 setfenv(1,context)
 local Core=CatalogLoadState
 local panel=Instance.new("Frame");panel.Name="CatalogLoader";panel.Size=UDim2.new(1,-16,1,-(titleH+16));panel.Position=UDim2.new(0,8,0,titleH+8);panel.BackgroundTransparency=1;panel.Visible=false;panel.ZIndex=20;panel.Parent=content
 local card=Instance.new("Frame");card.Size=UDim2.new(1,-16,0,180);card.Position=UDim2.new(0,8,.15,0);card.BackgroundColor3=currentTheme.secondary;card.BorderSizePixel=0;card.ZIndex=21;card.Parent=panel;Instance.new("UICorner",card).CornerRadius=UDim.new(0,12);RegisterTheme(card,"BackgroundColor3","secondary")
 local function label(y,h,size)
  local item=Instance.new("TextLabel");item.Size=UDim2.new(1,-28,0,h);item.Position=UDim2.fromOffset(14,y);item.BackgroundTransparency=1;item.TextColor3=currentTheme.text;item.TextSize=size;item.TextWrapped=true;item.Font=Enum.Font.GothamMedium;item.ZIndex=22;item.Parent=card;RegisterTheme(item,"TextColor3","text");return item
 end
 local heading=label(12,28,16)
 local status=label(44,36,11)
 local loadButton=Instance.new("TextButton");loadButton.Size=UDim2.new(1,-28,0,38);loadButton.Position=UDim2.fromOffset(14,90);loadButton.BackgroundColor3=currentTheme.tertiary;loadButton.TextColor3=currentTheme.text;loadButton.TextSize=13;loadButton.Font=Enum.Font.GothamBold;loadButton.BorderSizePixel=0;loadButton.ZIndex=22;loadButton.Parent=card;Instance.new("UICorner",loadButton).CornerRadius=UDim.new(0,8);RegisterTheme(loadButton,"BackgroundColor3","tertiary");RegisterTheme(loadButton,"TextColor3","text")
 local track=Instance.new("Frame");track.Position=UDim2.fromOffset(14,142);track.Size=UDim2.new(1,-28,0,5);track.BackgroundColor3=currentTheme.tertiary;track.BorderSizePixel=0;track.ZIndex=22;track.Parent=card;Instance.new("UICorner",track).CornerRadius=UDim.new(0,3);RegisterTheme(track,"BackgroundColor3","tertiary")
 local fill=Instance.new("Frame");fill.Size=UDim2.fromScale(0,1);fill.BackgroundColor3=currentTheme.accent;fill.BorderSizePixel=0;fill.ZIndex=23;fill.Parent=track;Instance.new("UICorner",fill).CornerRadius=UDim.new(0,3);RegisterTheme(fill,"BackgroundColor3","accent")
 local percent=label(151,20,11)
 local stages={download=isES and"Descargando catálogo..."or"Downloading catalog...",decode=isES and"Leyendo catálogo..."or"Reading catalog...",prepare=isES and"Preparando elementos..."or"Preparing items...",index=isES and"Preparando búsqueda..."or"Preparing search..."}
 local UI={Kind=nil,Panel=panel}
 function UI:Refresh()
  if not panel.Parent or not self.Kind then return end
  local state=Core[self.Kind]
  local noun=self.Kind=="Emotes"and(isES and"emotes"or"emotes")or(isES and"animaciones"or"animations")
  heading.Text=self.Kind=="Emotes"and L.emotes or L.animations
  loadButton.Text=state.Loading and(isES and"Cargando..."or"Loading...")or((isES and"Cargar "or"Load ")..noun)
  loadButton.Active=Core.Active==nil and not state.Loaded
  status.Text=state.Error and(isES and"No se pudo cargar. Pulsa para reintentar."or"Could not load. Press to retry.")or(state.Loading and stages[state.Stage])or(Core.Active and(isES and"Espera a que termine la otra carga."or"Wait for the other catalog to finish."))or(isES and"Se cargará únicamente cuando pulses el botón."or"Loads only when you press the button.")
  track.Visible=state.Loading;percent.Visible=state.Loading
  fill.Size=UDim2.fromScale(state.Progress or 0,1);percent.Text=math.floor((state.Progress or 0)*100).."%"
 end
 function UI:SetTab(tab)
  self.Kind=Core:ForTab(tab)
  local waiting=Core:IsPending(tab)
  panel.Visible=waiting
  if waiting then
   scroll.Visible=false;search.Visible=false;pageBar.Visible=false;emptyLbl.Visible=false
   if playlistsPanel then playlistsPanel.Visible=false end
   if keybindsPanel then keybindsPanel.Visible=false end
   if playlistBackBtn then playlistBackBtn.Visible=false end
   if playlistDoneBtn then playlistDoneBtn.Visible=false end
   self:Refresh()
  end
  return waiting
 end
 loadButton.Activated:Connect(function()if UI.Kind then Core:Load(UI.Kind)end end)
 CatalogLoadPanel=UI
 return true
end
