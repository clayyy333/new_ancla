-- Panel administrativo privado. La conexion HTTP se agregara en un modulo separado.
return function(context)
    setfenv(1, context)

    local OWNER_IDENTITIES = {
        [11739864999] = "psychoo778",
        [11743514302] = "ksablanca0",
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
        button.Size = UDim2.new(.5, -5, 0, 40)
        button.Position = UDim2.new(x, x == 0 and 0 or 5, 0, 0)
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
    local gameButton = makeModeButton(isES and "Jugadores del juego" or "Players in this game", .5)

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

    local function render(players)
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
            item.Size = UDim2.new(1, -4, 0, 46)
            item.BackgroundColor3 = currentTheme.secondary
            item.Text = string.format(
                "  %s   |   %.2f h   |   %s   |   %s",
                tostring(info.username or ""),
                (tonumber(info.total_seconds) or 0) / 3600,
                tostring(info.country_code or "UN"),
                tostring(info.user_id or "")
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
                AdminPanelBridge:LoadPlayers("server", render)
                dataFrame.Visible = true
            end
        end)
    end)
    serverButton.Activated:Connect(function()
        if AdminPanelBridge and AdminPanelBridge.LoadPlayers then
            AdminPanelBridge:LoadPlayers("server", render)
        end
    end)
    gameButton.Activated:Connect(function()
        if AdminPanelBridge and AdminPanelBridge.LoadPlayers then
            AdminPanelBridge:LoadPlayers("game", render)
        end
    end)
    openButton.Activated:Connect(function() modal.Visible = true end)
    close.Activated:Connect(function() modal.Visible = false keyBox.Text = "" end)
    ShowAdminPanel = function() modal.Visible = true end
    return true
end
