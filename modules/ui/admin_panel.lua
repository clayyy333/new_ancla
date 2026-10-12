-- Panel administrativo privado. La conexion HTTP se agregara en un modulo separado.
return function(context)
    setfenv(1, context)

    local OWNER_IDENTITIES = {
        [11739864999] = "psychoo778",
        [11743514302] = "ksablanca0",
        [11747901934] = "psycho777oo",
        [11797966007] = "psychoop77",
    }
    local GAME_PLACE_ID = 12985361032
    local ownerUsername = OWNER_IDENTITIES[player.UserId]
    if not ownerUsername or string.lower(player.Name) ~= ownerUsername then
        return true
    end

    MakeSectionHeader(isES and "Administracion" or "Administration", 23)
    local row = MakeRow(
        "",
        isES and "Panel de administrador" or "Administrator panel",
        "Metro Life RP · " .. tostring(GAME_PLACE_ID),
        24
    )
    local openButton = Instance.new("TextButton")
    openButton.Size = UDim2.new(0, isMobile and 100 or 125, 0, 34)
    openButton.AnchorPoint = Vector2.new(1, .5)
    openButton.Position = UDim2.new(1, -12, .5, 0)
    openButton.BackgroundColor3 = currentTheme.accent
    openButton.Text = isES and "Abrir panel" or "Open panel"
    openButton.TextColor3 = Color3.new(1, 1, 1)
    openButton.Font = Enum.Font.GothamBold
    openButton.TextSize = isMobile and 11 or 12
    openButton.ZIndex = 9
    openButton.Parent = row
    Instance.new("UICorner", openButton).CornerRadius = UDim.new(0, 10)
    RegisterTheme(openButton, "BackgroundColor3", "accent")

    local modal = Instance.new("Frame")
    modal.Name = "OwnerAdminPanel"
    modal.AnchorPoint = Vector2.new(.5, .5)
    modal.Position = UDim2.fromScale(.5, .5)
    modal.Size = UDim2.new(0, isMobile and 345 or 650, 0, isMobile and 430 or 470)
    modal.BackgroundColor3 = currentTheme.primary
    modal.BorderSizePixel = 0
    modal.Visible = false
    modal.Active = true
    modal.ZIndex = 1500
    modal.Parent = gui
    Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 18)
    RegisterTheme(modal, "BackgroundColor3", "primary")
    local stroke = Instance.new("UIStroke", modal)
    stroke.Thickness = 2
    stroke.Color = currentTheme.accent
    RegisterTheme(stroke, "Color", "accent")

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 0, 44)
    title.Position = UDim2.new(0, 18, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = isES and "Panel de administrador" or "Administrator panel"
    title.TextColor3 = currentTheme.text
    title.Font = Enum.Font.GothamBold
    title.TextSize = isMobile and 16 or 19
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 1501
    title.Parent = modal
    RegisterTheme(title, "TextColor3", "text")

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(38, 38)
    close.Position = UDim2.new(1, -48, 0, 10)
    close.BackgroundColor3 = currentTheme.critical
    close.Text = "×"
    close.TextColor3 = Color3.new(1, 1, 1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 22
    close.ZIndex = 1502
    close.Parent = modal
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 10)
    RegisterTheme(close, "BackgroundColor3", "critical")

    local loginFrame = Instance.new("Frame")
    loginFrame.Size = UDim2.new(1, -36, 1, -76)
    loginFrame.Position = UDim2.new(0, 18, 0, 62)
    loginFrame.BackgroundTransparency = 1
    loginFrame.ZIndex = 1501
    loginFrame.Parent = modal

    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(1, 0, 0, 46)
    keyBox.Position = UDim2.new(0, 0, 0, 50)
    keyBox.BackgroundColor3 = currentTheme.secondary
    keyBox.PlaceholderText = isES and "Clave privada" or "Private key"
    keyBox.Text = ""
    keyBox.ClearTextOnFocus = false
    keyBox.TextColor3 = currentTheme.text
    keyBox.PlaceholderColor3 = currentTheme.textDim
    keyBox.Font = Enum.Font.Gotham
    keyBox.TextSize = 14
    keyBox.ZIndex = 1502
    keyBox.Parent = loginFrame
    Instance.new("UICorner", keyBox).CornerRadius = UDim.new(0, 10)
    RegisterTheme(keyBox, "BackgroundColor3", "secondary")
    RegisterTheme(keyBox, "TextColor3", "text")
    RegisterTheme(keyBox, "PlaceholderColor3", "textDim")

    local loginButton = Instance.new("TextButton")
    loginButton.Size = UDim2.new(1, 0, 0, 46)
    loginButton.Position = UDim2.new(0, 0, 0, 108)
    loginButton.BackgroundColor3 = currentTheme.accent
    loginButton.Text = isES and "Validar y abrir" or "Validate and open"
    loginButton.TextColor3 = Color3.new(1, 1, 1)
    loginButton.Font = Enum.Font.GothamBold
    loginButton.TextSize = 13
    loginButton.ZIndex = 1502
    loginButton.Parent = loginFrame
    Instance.new("UICorner", loginButton).CornerRadius = UDim.new(0, 10)
    RegisterTheme(loginButton, "BackgroundColor3", "accent")

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 52)
    status.Position = UDim2.new(0, 0, 0, 166)
    status.BackgroundTransparency = 1
    status.Text = isES and "Introduce la clave privada para conectar con Render." or "Enter the private key to connect to Render."
    status.TextColor3 = currentTheme.textDim
    status.Font = Enum.Font.Gotham
    status.TextSize = isMobile and 11 or 12
    status.TextWrapped = true
    status.ZIndex = 1502
    status.Parent = loginFrame
    RegisterTheme(status, "TextColor3", "textDim")

    local dataFrame = Instance.new("Frame")
    dataFrame.Size = UDim2.new(1, -24, 1, -68)
    dataFrame.Position = UDim2.new(0, 12, 0, 58)
    dataFrame.BackgroundTransparency = 1
    dataFrame.Visible = false
    dataFrame.ZIndex = 1501
    dataFrame.Parent = modal

    local function makeModeButton(text, x)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(.333, -5, 0, 40)
        button.Position = UDim2.new(x, x == 0 and 0 or 4, 0, 0)
        button.BackgroundColor3 = currentTheme.secondary
        button.Text = text
        button.TextColor3 = currentTheme.text
        button.Font = Enum.Font.GothamBold
        button.TextSize = isMobile and 10 or 12
        button.ZIndex = 1502
        button.Parent = dataFrame
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
        RegisterTheme(button, "BackgroundColor3", "secondary")
        RegisterTheme(button, "TextColor3", "text")
        return button
    end
    local serverButton = makeModeButton(isES and "Jugadores de este servidor" or "Players in this server", 0)
    local gameButton = makeModeButton(isES and "Jugadores del juego" or "Players in this game", .333)
    local customButton = makeModeButton(isES and "Fling personalizado" or "Custom Fling", .667)

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, 0, 1, -52)
    list.Position = UDim2.new(0, 0, 0, 50)
    list.BackgroundTransparency = 1
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.ScrollBarThickness = isMobile and 6 or 4
    list.ZIndex = 1502
    list.Parent = dataFrame
    local layout = Instance.new("UIListLayout", list)
    layout.Padding = UDim.new(0, 5)

    local serverScope=true
    local loadServer
    local function render(players,remoteCommands)
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end
        if type(players) ~= "table" or #players == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 44)
            empty.BackgroundTransparency = 1
            empty.Text = isES and "No hay jugadores conectados." or "No connected players."
            empty.TextColor3 = currentTheme.textDim
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 12
            empty.ZIndex = 1503
            empty.Parent = list
            RegisterTheme(empty, "TextColor3", "textDim")
            return
        end
        for _, info in ipairs(players) do
            local item = Instance.new("TextLabel")
            item.Size = UDim2.new(1, -4, 0, (serverScope and info.id) and 150 or 46)
            item.BackgroundColor3 = currentTheme.secondary
            item.Text = string.format(
                "  %s   |   %.2f h   |   %s   |   %s   |   %s",
                tostring(info.username or ""),
                (tonumber(info.total_seconds) or 0) / 3600,
                tostring(info.country_code or "UN"),
                tostring(info.user_id or ""),
                ((info.custom_fling_using == true or tonumber(info.custom_fling_using) == 1)
                    and (isES and "Usando Fling personalizado" or "Using Custom Fling")
                    or (isES and "Fuera" or "Outside"))
            )
            item.TextColor3 = currentTheme.text
            item.Font = Enum.Font.Gotham
            item.TextSize = isMobile and 9 or 11
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.ZIndex = 1503
            item.Parent = list
            Instance.new("UICorner", item).CornerRadius = UDim.new(0, 9)
            RegisterTheme(item, "BackgroundColor3", "secondary")
            RegisterTheme(item, "TextColor3", "text")
            if serverScope and info.id then
                item.TextYAlignment=Enum.TextYAlignment.Top
                local selected=tonumber(info.enabled)==1 and info.controller_session_id==(BackendAnchorGuard and BackendAnchorGuard.SessionId)
                local function control(text,x,y,width)
                    local button=makeModeButton(text,0);button.Parent=item;button.Size=UDim2.new(width,-6,0,32);button.Position=UDim2.new(x,3,0,y);button.ZIndex=1504;return button
                end
                local permission=tonumber(info.consent)==1
                local choose=control(permission and (selected and (isES and "Quitar control" or "Disable control") or (isES and "Habilitar control" or "Enable control")) or (isES and "Sin permiso" or "No consent"),0,32,1)
                local anchor=control(isES and "Activar ancla + desfase" or "Enable anchor + phase",0,108,.5)
                local fling=control(isES and "Activar Fling corto" or "Enable short Fling",.5,108,.5)
                local target=control(isES and "Elegir objetivo" or "Choose target",0,70,1)
                local targetId,index=nil,0
                local candidates={};for _,p in ipairs(players) do if tonumber(p.consent)==1 and p.user_id~=info.user_id then candidates[#candidates+1]=p end end
                target.Activated:Connect(function() if #candidates==0 then return end;index=index%#candidates+1;targetId=candidates[index].user_id;target.Text=(isES and "Objetivo: " or "Target: ")..candidates[index].username end)
                local latest={}
                for _,c in ipairs(remoteCommands or {}) do
                    if c.target_session_id==info.id and not latest[c.action] then latest[c.action]=c end
                end
                local anchorOn=tonumber(info.anchored)==1 and info.anchor_mode=="Desfase"
                local flingOn=tonumber(info.short_fling_enabled)==1
                anchor.Text=anchorOn and (isES and "Desactivar ancla + desfase" or "Disable anchor + phase") or anchor.Text
                fling.Text=flingOn and (isES and "Desactivar Fling corto" or "Disable short Fling") or fling.Text
                for _,c in ipairs(remoteCommands or {}) do
                    if c.target_session_id==info.id then
                        if c.status=="pending" then choose.Text=isES and "Orden pendiente" or "Command pending"
                        elseif c.status=="applied" then choose.Text=isES and "Aplicado · quitar control" or "Applied · disable control"
                        elseif c.status=="failed" or c.status=="rejected" or c.status=="expired" then choose.Text=isES and "Error · actualizar" or "Error · refresh" end
                        break
                    end
                end
                local pending=false
                choose.Activated:Connect(function()
                    if pending or not permission then return end;pending=true
                    AdminPanelBridge:Remote("PUT","/sessions/"..info.id,{enabled=not selected},function(response,err)
                        pending=false;if not item.Parent then return end
                        if response then loadServer() else choose.Text=tostring(err or "Error") end
                    end)
                end)
                local function send(action,button)
                    if pending or not selected then return end
                    if action=="short_fling_on" and not targetId then target.Text=isES and "Elige un objetivo primero" or "Choose a target first";return end
                    pending=true;button.Text=isES and "Enviando…" or "Sending…"
                    AdminPanelBridge:Remote("POST","/commands",{session_ids={info.id},action=action,target_user_id=targetId},function(response,err)
                        pending=false;if not item.Parent then return end
                        button.Text=response and (isES and "Pendiente · actualizar" or "Pending · refresh") or tostring(err or "Error")
                        if response and response.command_ids and response.command_ids[1] then
                            local cid=response.command_ids[1]
                            task.spawn(function()
                                for attempt=1,8 do
                                    task.wait(2)
                                    if not item.Parent or not modal.Visible or not serverScope then return end
                                    local finished,received=false,false
                                    AdminPanelBridge:Remote("GET","",nil,function(state)
                                        received=true
                                        if not state or not item.Parent then return end
                                        for _,c in ipairs(state.commands or {}) do
                                            if c.id==cid and c.status~="pending" then
                                                finished=true
                                                if c.status=="applied" then
                                                    if action=="anchor_phase_on" or action=="anchor_phase_off" then anchorOn=action=="anchor_phase_on" end
                                                    if action=="short_fling_on" or action=="short_fling_off" then flingOn=action=="short_fling_on" end
                                                    button.Text=isES and "Aplicado" or "Applied"
                                                    anchor.Text=anchorOn and (isES and "Desactivar ancla + desfase" or "Disable anchor + phase") or (isES and "Activar ancla + desfase" or "Enable anchor + phase")
                                                    fling.Text=flingOn and (isES and "Desactivar Fling corto" or "Disable short Fling") or (isES and "Activar Fling corto" or "Enable short Fling")
                                                    choose.Text=isES and "Aplicado · quitar control" or "Applied · disable control"
                                                else button.Text=(isES and "Error: " or "Error: ")..c.status end
                                                break
                                            end
                                        end
                                    end)
                                    local deadline=os.clock()+9
                                    repeat task.wait(.1) until received or os.clock()>=deadline or not item.Parent
                                    if finished then return end
                                end
                            end)
                        end
                    end)
                end
                anchor.Activated:Connect(function() send(anchorOn and "anchor_phase_off" or "anchor_phase_on",anchor) end)
                fling.Activated:Connect(function() send(flingOn and "short_fling_off" or "short_fling_on",fling) end)
            end
        end
    end

    loadServer=function()
        serverScope=true
        AdminPanelBridge:Remote("GET","",nil,function(response,err)
            if not serverScope or not modal.Visible then return end
            if response then render(response.sessions,response.commands)
            else status.Text=tostring(err or "Error");AdminPanelBridge:LoadPlayers("server",render) end
        end)
    end

    local function renderCustomProfiles(remoteProfiles)
        local merged={}
        Settings.ownerCustomFlingProfiles=type(Settings.ownerCustomFlingProfiles)=="table" and Settings.ownerCustomFlingProfiles or {}
        for id,profile in pairs(Settings.ownerCustomFlingProfiles) do merged[tostring(id)]=profile end
        if type(remoteProfiles)=="table" then for _,profile in ipairs(remoteProfiles) do merged[tostring(profile.user_id)]=profile end end
        local profiles={};for _,profile in pairs(merged) do table.insert(profiles,profile) end
        table.sort(profiles,function(a,b) return (tonumber(a.updated_at) or 0)>(tonumber(b.updated_at) or 0) end)
        for _,child in ipairs(list:GetChildren()) do if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end end
        if #profiles==0 then
            local empty=Instance.new("TextLabel");empty.Size=UDim2.new(1,0,0,44);empty.BackgroundTransparency=1;empty.Text=isES and "No hay ajustes guardados." or "No saved settings.";empty.TextColor3=currentTheme.muted;empty.ZIndex=1503;empty.Parent=list
            return
        end
        for _,profile in ipairs(profiles) do
            local row=Instance.new("Frame");row.Size=UDim2.new(1,0,0,52);row.BackgroundColor3=currentTheme.secondary;row.BorderSizePixel=0;row.ZIndex=1503;row.Parent=list;Instance.new("UICorner",row).CornerRadius=UDim.new(0,9);RegisterTheme(row,"BackgroundColor3","secondary")
            local label=Instance.new("TextLabel");label.Size=UDim2.new(.46,-10,1,0);label.Position=UDim2.new(0,10,0,0);label.BackgroundTransparency=1;label.Text=(profile.display_name or profile.username or "Usuario").." (@"..tostring(profile.username or "?")..")";label.TextColor3=currentTheme.text;label.TextXAlignment=Enum.TextXAlignment.Left;label.Font=Enum.Font.Gotham;label.TextSize=isMobile and 9 or 11;label.ZIndex=1504;label.Parent=row;RegisterTheme(label,"TextColor3","text")
            local equip=makeModeButton(isES and "Equipar ajustes" or "Equip settings",0);equip.Parent=row;equip.Size=UDim2.new(.26,-4,0,34);equip.Position=UDim2.new(.47,0,.5,-17);equip.ZIndex=1504
            local save=makeModeButton(isES and "Guardar ajustes" or "Save settings",0);save.Parent=row;save.Size=UDim2.new(.26,-4,0,34);save.Position=UDim2.new(.74,0,.5,-17);save.ZIndex=1504
            equip.Activated:Connect(function() if CustomFlingCore and CustomFlingCore:ApplySettings(profile) then Settings.customFlingSettings=CustomFlingCore:ExportSettings();SaveLocalData();if UpdateCustomFlingPanel then UpdateCustomFlingPanel() end;equip.Text=isES and "Equipado" or "Equipped" end end)
            save.Activated:Connect(function() Settings.ownerCustomFlingProfiles[tostring(profile.user_id)]=profile;SaveLocalData();save.Text=isES and "Guardado local" or "Saved locally" end)
        end
    end

    AdminPanelBridge = AdminPanelBridge or nil
    SetAdminPanelPlayers = render
    loginButton.Activated:Connect(function()
        if not AdminPanelBridge or type(AdminPanelBridge.Login) ~= "function" then
            status.Text = isES and "Conexion pendiente: el frontend aun no esta enlazado al backend." or "Pending connection: frontend is not linked to backend yet."
            return
        end
        AdminPanelBridge:Login(keyBox.Text, function(ok, message)
            status.Text = tostring(message or "")
            if ok then
                loginFrame.Visible = false
                keyBox.Text = ""
                loadServer()
                dataFrame.Visible = true
            end
        end)
    end)
    serverButton.Activated:Connect(function()
        if AdminPanelBridge and AdminPanelBridge.LoadPlayers then
            loadServer()
        end
    end)
    gameButton.Activated:Connect(function()
        serverScope=false
        if AdminPanelBridge and AdminPanelBridge.LoadPlayers then
            AdminPanelBridge:LoadPlayers("game", render)
        end
    end)
    customButton.Activated:Connect(function()
        serverScope=false
        local cached={};for _,profile in pairs(Settings.ownerCustomFlingProfiles or {}) do table.insert(cached,profile) end
        renderCustomProfiles(cached)
        if AdminPanelBridge and AdminPanelBridge.LoadCustomFlingProfiles then AdminPanelBridge:LoadCustomFlingProfiles(function(profiles) if profiles then renderCustomProfiles(profiles) end end) end
    end)
    openButton.Activated:Connect(function() modal.Visible = true end)
    close.Activated:Connect(function() modal.Visible = false keyBox.Text = "" end)
    ShowAdminPanel = function() modal.Visible = true end
    return true
end
