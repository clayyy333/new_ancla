-- Vista integrada del Fling por contacto.
return function(context)
    setfenv(1, context)
    contactFlingPanel=Instance.new("Frame");contactFlingPanel.Name="ContactFlingPanel";contactFlingPanel.Size=UDim2.new(1,-16,1,-(titleH+20));contactFlingPanel.Position=UDim2.new(0,8,0,titleH+8);contactFlingPanel.BackgroundTransparency=1;contactFlingPanel.Visible=false;contactFlingPanel.ZIndex=6;contactFlingPanel.Parent=content
    local card=Instance.new("Frame");card.Size=UDim2.new(1,0,0,210);card.BackgroundColor3=currentTheme.secondary;card.ZIndex=7;card.Parent=contactFlingPanel;Instance.new("UICorner",card).CornerRadius=UDim.new(0,14);RegisterTheme(card,"BackgroundColor3","secondary")
    local padding=Instance.new("UIPadding");padding.PaddingLeft=UDim.new(0,16);padding.PaddingRight=UDim.new(0,16);padding.PaddingTop=UDim.new(0,16);padding.Parent=card
    local description=Instance.new("TextLabel");description.Size=UDim2.new(1,0,0,54);description.BackgroundTransparency=1;description.Text=isES and "Mantiene el cuerpo en un estado físico pasivo mientras caminas normalmente. Quien choque directamente contigo recibe el impulso." or "Keeps your body in a passive physical state while you walk normally. Anyone who collides directly with you receives the impulse.";description.TextColor3=currentTheme.textDim;description.Font=Enum.Font.GothamMedium;description.TextSize=isMobile and 11 or 13;description.TextWrapped=true;description.TextXAlignment=Enum.TextXAlignment.Left;description.TextYAlignment=Enum.TextYAlignment.Top;description.ZIndex=8;description.Parent=card;RegisterTheme(description,"TextColor3","textDim")
    local toggle=Instance.new("TextButton");toggle.Size=UDim2.new(1,0,0,48);toggle.Position=UDim2.new(0,0,0,68);toggle.BackgroundColor3=currentTheme.tertiary;toggle.TextColor3=currentTheme.text;toggle.Font=Enum.Font.GothamBold;toggle.TextSize=isMobile and 12 or 14;toggle.AutoButtonColor=false;toggle.ZIndex=8;toggle.Parent=card;Instance.new("UICorner",toggle).CornerRadius=UDim.new(0,10);RegisterTheme(toggle,"TextColor3","text")
    local status=Instance.new("TextLabel");status.Size=UDim2.new(1,0,0,42);status.Position=UDim2.new(0,0,0,132);status.BackgroundTransparency=1;status.TextColor3=currentTheme.textDim;status.Font=Enum.Font.GothamMedium;status.TextSize=isMobile and 10 or 12;status.TextWrapped=true;status.TextXAlignment=Enum.TextXAlignment.Left;status.ZIndex=8;status.Parent=card;RegisterTheme(status,"TextColor3","textDim")
    UpdateContactFlingPanel=function(message)
        local active=ContactFlingController.Running
        toggle.Text=active and (isES and "Desactivar Fling por contacto" or "Disable Contact Fling") or (isES and "Activar Fling por contacto" or "Enable Contact Fling")
        toggle.BackgroundColor3=active and currentTheme.accent or currentTheme.tertiary
        status.Text=message or ContactFlingController.Status
    end
    toggle.Activated:Connect(function()
        if ContactFlingController.Running then ContactFlingController:Stop() else local ok,err=ContactFlingController:Start();if not ok then UpdateContactFlingPanel(err) end end
        UpdateContactFlingPanel()
    end)
    UpdateContactFlingPanel()
    return true
end