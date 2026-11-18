-- Small load cards; existing graphics panels are still built normally.
return function(context)
 setfenv(1,context)
 function CreateGraphicsLoadControl(parent,kind,title,order,onChanged)
  local service=GraphicsFeatureLoader
  local card=Instance.new("Frame");card.Name=kind.."Loader";card.LayoutOrder=order;card.Size=UDim2.new(1,-4,0,134);card.BackgroundColor3=currentTheme.secondary;card.BorderSizePixel=0;card.ZIndex=7;card.Parent=parent;Instance.new("UICorner",card).CornerRadius=UDim.new(0,12);RegisterTheme(card,"BackgroundColor3","secondary")
  local button=Instance.new("TextButton");button.Size=UDim2.new(1,-24,0,42);button.Position=UDim2.fromOffset(12,12);button.BackgroundColor3=currentTheme.tertiary;button.TextColor3=currentTheme.text;button.TextSize=isMobile and 11 or 13;button.Font=Enum.Font.GothamBold;button.BorderSizePixel=0;button.TextWrapped=true;button.ZIndex=8;button.Parent=card;Instance.new("UICorner",button).CornerRadius=UDim.new(0,9);RegisterTheme(button,"BackgroundColor3","tertiary");RegisterTheme(button,"TextColor3","text")
  local status=Instance.new("TextLabel");status.Size=UDim2.new(1,-24,0,34);status.Position=UDim2.fromOffset(12,58);status.BackgroundTransparency=1;status.TextColor3=currentTheme.textDim;status.TextSize=11;status.TextWrapped=true;status.Font=Enum.Font.Gotham;status.ZIndex=8;status.Parent=card;RegisterTheme(status,"TextColor3","textDim")
  local track=Instance.new("Frame");track.Size=UDim2.new(1,-24,0,5);track.Position=UDim2.fromOffset(12,103);track.BackgroundColor3=currentTheme.tertiary;track.BorderSizePixel=0;track.ZIndex=8;track.Parent=card;Instance.new("UICorner",track).CornerRadius=UDim.new(0,3);RegisterTheme(track,"BackgroundColor3","tertiary")
  local fill=Instance.new("Frame");fill.Size=UDim2.fromScale(0,1);fill.BackgroundColor3=currentTheme.accent;fill.BorderSizePixel=0;fill.ZIndex=9;fill.Parent=track;Instance.new("UICorner",fill).CornerRadius=UDim.new(0,3);RegisterTheme(fill,"BackgroundColor3","accent")
  local stages={download=isES and"Descargando..."or"Downloading...",compile=isES and"Preparando código..."or"Preparing code...",initialize=isES and"Inicializando..."or"Initializing...",prepare=isES and"Preparando..."or"Preparing...",scan=isES and"Preparando mapa..."or"Preparing map..."}
  local function refresh()
   if not card.Parent then return end
   local state=service.States[kind]
   card.Visible=not state.Loaded
   button.Active=service.Active==nil and not state.Loaded
   button.Text=state.Loading and((stages[state.Stage]or"").." "..math.floor(state.Progress*100).."%")or((isES and"Cargar "or"Load ")..title)
   status.Text=state.Error and(isES and"No se pudo cargar. Pulsa para reintentar."or"Could not load. Press to retry.")or(service.Active and not state.Loading and(isES and"Espera a que termine la otra carga."or"Wait for the other load to finish."))or(isES and"Solo se carga al pulsar este botón."or"Loads only when you press this button.")
   track.Visible=state.Loading;fill.Size=UDim2.fromScale(state.Progress or 0,1)
   if onChanged then onChanged(state.Loaded)end
  end
  button.Activated:Connect(function()service:Load(kind)end)
  service:OnChanged(kind,refresh);refresh()
  return card
 end
 return true
end
