-- Vista integrada del Fling por contacto.
return function(context)
    setfenv(1,context)

    contactFlingPanel=Instance.new("ScrollingFrame")
    contactFlingPanel.BorderSizePixel=0
    contactFlingPanel.ScrollBarThickness=3
    contactFlingPanel.ScrollingDirection=Enum.ScrollingDirection.Y
    contactFlingPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y
    contactFlingPanel.CanvasSize=UDim2.new()
    contactFlingPanel.Active=true
    contactFlingPanel.Name="ContactFlingPanel"
    contactFlingPanel.Size=UDim2.new(1,-16,1,-(titleH+20))
    contactFlingPanel.Position=UDim2.new(0,8,0,titleH+8)
    contactFlingPanel.BackgroundTransparency=1
    contactFlingPanel.Visible=false
    contactFlingPanel.ZIndex=6
    contactFlingPanel.Parent=content

    local card=Instance.new("Frame")
    card.Size=UDim2.new(1,0,0,320)
    card.BackgroundColor3=currentTheme.secondary
    card.ZIndex=7
    card.Parent=contactFlingPanel
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
    RegisterTheme(card,"BackgroundColor3","secondary")

    local padding=Instance.new("UIPadding")
    padding.PaddingLeft=UDim.new(0,16)
    padding.PaddingRight=UDim.new(0,16)
    padding.PaddingTop=UDim.new(0,16)
    padding.Parent=card

    local function makeButton(y,text,height)
        local button=Instance.new("TextButton")
        button.Size=UDim2.new(1,0,0,height or 44)
        button.Position=UDim2.new(0,0,0,y)
        button.BackgroundColor3=currentTheme.tertiary
        button.Text=text
        button.TextColor3=currentTheme.text
        button.Font=Enum.Font.GothamBold
        button.TextSize=isMobile and 11 or 13
        button.AutoButtonColor=false
        button.ZIndex=8
        button.Parent=card
        Instance.new("UICorner",button).CornerRadius=UDim.new(0,10)
        RegisterTheme(button,"BackgroundColor3","tertiary")
        RegisterTheme(button,"TextColor3","text")
        return button
    end

    local targetLabel=Instance.new("TextLabel")
    targetLabel.Size=UDim2.new(1,0,0,18)
    targetLabel.BackgroundTransparency=1
    targetLabel.Text=isES and "Jugador objetivo" or "Target player"
    targetLabel.TextColor3=currentTheme.textDim
    targetLabel.Font=Enum.Font.GothamMedium
    targetLabel.TextSize=isMobile and 10 or 12
    targetLabel.TextXAlignment=Enum.TextXAlignment.Left
    targetLabel.ZIndex=8
    targetLabel.Parent=card
    RegisterTheme(targetLabel,"TextColor3","textDim")

    local targetButton=makeButton(24,isES and "Seleccionar jugador" or "Select player",40)
    targetButton.Font=Enum.Font.GothamMedium
    targetButton.TextXAlignment=Enum.TextXAlignment.Left
    Instance.new("UIPadding",targetButton).PaddingLeft=UDim.new(0,12)

    local targetList=Instance.new("ScrollingFrame")
    targetList.Size=UDim2.new(1,0,0,120)
    targetList.Position=UDim2.new(0,0,0,68)
    targetList.BackgroundColor3=currentTheme.tertiary
    targetList.BorderSizePixel=0
    targetList.ScrollBarThickness=4
    targetList.AutomaticCanvasSize=Enum.AutomaticSize.Y
    targetList.CanvasSize=UDim2.new()
    targetList.Visible=false
    targetList.ZIndex=30
    targetList.Parent=card
    Instance.new("UICorner",targetList).CornerRadius=UDim.new(0,10)
    RegisterTheme(targetList,"BackgroundColor3","tertiary")
    local targetLayout=Instance.new("UIListLayout")
    targetLayout.Padding=UDim.new(0,3)
    targetLayout.Parent=targetList

    local teleportButton=makeButton(72,isES and "Activar TP" or "Enable TP",44)

    local description=Instance.new("TextLabel")
    description.Size=UDim2.new(1,0,0,50)
    description.Position=UDim2.new(0,0,0,126)
    description.BackgroundTransparency=1
    description.Text=isES and "Genera un pulso físico extremo por contacto y lo retira en el mismo ciclo para conservar el movimiento normal." or "Produces an extreme physical contact pulse and removes it in the same cycle to preserve normal movement."
    description.TextColor3=currentTheme.textDim
    description.Font=Enum.Font.GothamMedium
    description.TextSize=isMobile and 10 or 12
    description.TextWrapped=true
    description.TextXAlignment=Enum.TextXAlignment.Left
    description.TextYAlignment=Enum.TextYAlignment.Top
    description.ZIndex=8
    description.Parent=card
    RegisterTheme(description,"TextColor3","textDim")

    local toggle=makeButton(184,"",48)

    local status=Instance.new("TextLabel")
    status.Size=UDim2.new(1,0,0,42)
    status.Position=UDim2.new(0,0,0,244)
    status.BackgroundTransparency=1
    status.TextColor3=currentTheme.textDim
    status.Font=Enum.Font.GothamMedium
    status.TextSize=isMobile and 10 or 12
    status.TextWrapped=true
    status.TextXAlignment=Enum.TextXAlignment.Left
    status.ZIndex=8
    status.Parent=card
    RegisterTheme(status,"TextColor3","textDim")

    local function refreshTargets()
        for _,child in ipairs(targetList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _,targetPlayer in ipairs(ContactFlingController:GetTargetOptions()) do
            local option=Instance.new("TextButton")
            option.Size=UDim2.new(1,-4,0,34)
            option.BackgroundColor3=currentTheme.secondary
            option.Text=targetPlayer.DisplayName.."  (@"..targetPlayer.Name..")"
            option.TextColor3=currentTheme.text
            option.Font=Enum.Font.GothamMedium
            option.TextSize=isMobile and 10 or 12
            option.ZIndex=31
            option.Parent=targetList
            Instance.new("UICorner",option).CornerRadius=UDim.new(0,8)
            RegisterTheme(option,"BackgroundColor3","secondary")
            RegisterTheme(option,"TextColor3","text")
            option.Activated:Connect(function()
                ContactFlingController:SetTarget(targetPlayer)
                targetList.Visible=false
                UpdateContactFlingPanel()
            end)
        end
    end

    UpdateContactFlingPanel=function(message)
        local active=ContactFlingController.Running
        local target=ContactFlingController:GetTarget()
        targetButton.Text=target and (target.DisplayName.."  (@"..target.Name..")") or (isES and "Seleccionar jugador" or "Select player")
        toggle.Text=active and (isES and "Desactivar Fling por contacto" or "Disable Contact Fling") or (isES and "Activar Fling por contacto" or "Enable Contact Fling")
        toggle.BackgroundColor3=active and currentTheme.accent or currentTheme.tertiary
        status.Text=message or ContactFlingController.Status
    end

    targetButton.Activated:Connect(function()
        targetList.Visible=not targetList.Visible
        if targetList.Visible then refreshTargets() end
    end)

    teleportButton.Activated:Connect(function()
        targetList.Visible=false
        local ok,err=ContactFlingController:TeleportToTarget()
        UpdateContactFlingPanel(ok and nil or err)
    end)

    toggle.Activated:Connect(function()
        targetList.Visible=false
        if ContactFlingController.Running then
            ContactFlingController:Stop()
        else
            local ok,err=ContactFlingController:Start()
            if not ok then UpdateContactFlingPanel(err) end
        end
        UpdateContactFlingPanel()
    end)

    UpdateContactFlingPanel()
    return true
end
