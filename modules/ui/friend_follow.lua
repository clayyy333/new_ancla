-- Selector de amigos presentes; no intenta detectar instalaciones del script.
return function(context)
    setfenv(1, context)
    local disposed, refreshing = false, false
    local connections = {}
    local friendButtons = {}
    local follow = LocalEmoteFollow
    local function label(parent, text, height)
        local item = Instance.new("TextLabel")
        item.Size = UDim2.new(1, 0, 0, height)
        item.BackgroundTransparency = 1
        item.Text = text
        item.TextWrapped = true
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.Font = Enum.Font.Gotham
        item.TextSize = 13
        item.TextColor3 = currentTheme.text
        item.ZIndex = 7
        item.Parent = parent
        RegisterTheme(item, "TextColor3", "text")
        return item
    end
    local description = label(friendsPanel, "Seguir emotes (experimental)\nElige a un amigo del servidor. La coincidencia puede variar.", 64)
    description.LayoutOrder = 1
    local controls = Instance.new("Frame")
    controls.Size = UDim2.new(1, 0, 0, 36)
    controls.BackgroundTransparency = 1
    controls.LayoutOrder = 2
    controls.Parent = friendsPanel
    local function button(parent, text)
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(0.48, 0, 1, 0)
        item.Text = text
        item.TextSize = 13
        item.Font = Enum.Font.GothamBold
        item.BackgroundColor3 = currentTheme.accent
        item.TextColor3 = currentTheme.text
        item.ZIndex = 8
        item.Parent = parent
        Instance.new("UICorner", item).CornerRadius = UDim.new(0, 8)
        RegisterTheme(item, "BackgroundColor3", "accent")
        RegisterTheme(item, "TextColor3", "text")
        return item
    end
    local refreshButton = button(controls, "Actualizar")
    local stopButton = button(controls, "Dejar de seguir")
    stopButton.Position = UDim2.new(0.52, 0, 0, 0)
    local statusLabel = label(friendsPanel, follow.GetStatus(), 42)
    statusLabel.LayoutOrder = 3
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, 0)
    list.AutomaticSize = Enum.AutomaticSize.Y
    list.BackgroundTransparency = 1
    list.LayoutOrder = 4
    list.Parent = friendsPanel
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list
    local function refresh()
        if disposed or refreshing then return end
        refreshing = true
        refreshButton.Text = "Buscando..."
        task.spawn(function()
            local friends = {}
            local failed = false
            for _, candidate in ipairs(Players:GetPlayers()) do
                if candidate ~= player then
                    local ok, isFriend = pcall(function() return player:IsFriendsWith(candidate.UserId) end)
                    if not ok then failed = true end
                    if ok and isFriend and candidate.Parent == Players then table.insert(friends, candidate) end
                end
            end
            if disposed then return end
            table.sort(friends, function(a, b) return a.Name:lower() < b.Name:lower() end)
            friendButtons = {}
            for _, item in ipairs(list:GetChildren()) do if item ~= layout then item:Destroy() end end
            if #friends == 0 then
                label(list, failed and "No se pudo consultar la amistad. Pulsa Actualizar para reintentar."
                    or "No hay amigos de Roblox en este servidor.", 60)
            end
            for index, friend in ipairs(friends) do
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 58)
                row.BackgroundTransparency = 1
                row.LayoutOrder = index
                row.Parent = list
                local name = label(row, friend.DisplayName .. "\n@" .. friend.Name, 58)
                name.Size = UDim2.new(1, -96, 1, 0)
                local select = button(row, "Seguir")
                friendButtons[friend] = select
                select.Size = UDim2.new(0, 88, 0, 34)
                select.Position = UDim2.new(1, -88, 0, 12)
                select.MouseButton1Click:Connect(function()
                    select.Text = "..."
                    task.spawn(function()
                        local ok = follow.Start(friend)
                        if not disposed and select.Parent then select.Text = ok and "Siguiendo" or "Reintentar" end
                    end)
                end)
            end
            refreshButton.Text = "Actualizar"
            refreshing = false
        end)
    end
    refreshButton.MouseButton1Click:Connect(refresh)
    stopButton.MouseButton1Click:Connect(function() follow.Stop() end)
    connections[#connections + 1] = friendsPanel:GetPropertyChangedSignal("Visible"):Connect(function()
        if friendsPanel.Visible then refresh() end
    end)
    connections[#connections + 1] = Players.PlayerAdded:Connect(function() if friendsPanel.Visible then refresh() end end)
    connections[#connections + 1] = Players.PlayerRemoving:Connect(function() if friendsPanel.Visible then task.defer(refresh) end end)
    local elapsed = 0
    connections[#connections + 1] = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 0.25 or not friendsPanel.Visible then return end
        elapsed = 0
        statusLabel.Text = follow.GetStatus()
        for friend, select in pairs(friendButtons) do
            select.Text = follow.GetTarget() == friend and "Siguiendo" or "Seguir"
        end
    end)
    connections[#connections + 1] = gui.Destroying:Connect(function()
        disposed = true
        for _, connection in ipairs(connections) do connection:Disconnect() end
    end)
    return true
end
