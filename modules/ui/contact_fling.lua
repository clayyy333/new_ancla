-- Vista integrada del Fling por contacto.
return function(context)
    setfenv(1, context)
    contactFlingPanel=Instance.new("ScrollingFrame");contactFlingPanel.BorderSizePixel=0;contactFlingPanel.ScrollBarThickness=3;contactFlingPanel.ScrollingDirection=Enum.ScrollingDirection.Y;contactFlingPanel.AutomaticCanvasSize=Enum.AutomaticSize.Y;contactFlingPanel.CanvasSize=UDim2.new();contactFlingPanel.Active=true;contactFlingPanel.Name="ContactFlingPanel";contactFlingPanel.Size=UDim2.new(1,-16,1,-(titleH+20));contactFlingPanel.Position=UDim2.new(0,8,0,titleH+8);contactFlingPanel.BackgroundTransparency=1;contactFlingPanel.Visible=false;contactFlingPanel.ZIndex=6;contactFlingPanel.Parent=content
    local card=Instance.new("Frame");card.Size=UDim2.new(1,0,0,416);card.BackgroundColor3=currentTheme.secondary;card.ZIndex=7;card.Parent=contactFlingPanel;Instance.new("UICorner",card).CornerRadius=UDim.new(0,14);RegisterTheme(card,"BackgroundColor3","secondary")
    local padding=Instance.new("UIPadding");padding.PaddingLeft=UDim.new(0,16);padding.PaddingRight=UDim.new(0,16);padding.PaddingTop=UDim.new(0,16);padding.Parent=card
    local description=Instance.new("TextLabel");description.Size=UDim2.new(1,0,0,54);description.BackgroundTransparency=1;description.Text=isES and "Genera un pulso físico extremo por contacto y lo retira en el mismo ciclo para conservar el movimiento normal." or "Produces an extreme physical contact pulse and removes it in the same cycle to preserve normal movement.";description.TextColor3=currentTheme.textDim;description.Font=Enum.Font.GothamMedium;description.TextSize=isMobile and 11 or 13;description.TextWrapped=true;description.TextXAlignment=Enum.TextXAlignment.Left;description.TextYAlignment=Enum.TextYAlignment.Top;description.ZIndex=8;description.Parent=card;RegisterTheme(description,"TextColor3","textDim")
    local toggle=Instance.new("TextButton");toggle.Size=UDim2.new(1,0,0,48);toggle.Position=UDim2.new(0,0,0,68);toggle.BackgroundColor3=currentTheme.tertiary;toggle.TextColor3=currentTheme.text;toggle.Font=Enum.Font.GothamBold;toggle.TextSize=isMobile and 12 or 14;toggle.AutoButtonColor=false;toggle.ZIndex=8;toggle.Parent=card;Instance.new("UICorner",toggle).CornerRadius=UDim.new(0,10);RegisterTheme(toggle,"TextColor3","text")
    local status=Instance.new("TextLabel");status.Size=UDim2.new(1,0,0,42);status.Position=UDim2.new(0,0,0,132);status.BackgroundTransparency=1;status.TextColor3=currentTheme.textDim;status.Font=Enum.Font.GothamMedium;status.TextSize=isMobile and 10 or 12;status.TextWrapped=true;status.TextXAlignment=Enum.TextXAlignment.Left;status.ZIndex=8;status.Parent=card;RegisterTheme(status,"TextColor3","textDim")
    UpdateContactFlingPanel=function(message)
        local active=ContactFlingController.Running
        toggle.Text=active and (isES and "Desactivar Fling por contacto" or "Disable Contact Fling") or (isES and "Activar Fling por contacto" or "Enable Contact Fling")
        toggle.BackgroundColor3=active and currentTheme.accent or currentTheme.tertiary
        status.Text=message or ContactFlingController.Status
    end
    toggle.Activated:Connect(function()
        if ContactFlingController.Running then ContactFlingController:Stop() else AdjustableContactFlingController:Stop();local ok,err=ContactFlingController:Start();if not ok then UpdateContactFlingPanel(err) end end
        UpdateContactFlingPanel()
    end)
    local adjustable=AdjustableContactFlingController
    if not adjustable:IsAuthorized() then
        card.Size=UDim2.new(1,0,0,210)
        UpdateContactFlingPanel()
        return true
    end
    local adjustableToggle=toggle:Clone();adjustableToggle.Name="AdjustableContactToggle";adjustableToggle.Position=UDim2.fromOffset(0,188);adjustableToggle.Parent=card
    RegisterTheme(adjustableToggle,"TextColor3","text")
    local amount=Instance.new("TextBox",card)
    amount.Size=UDim2.new(1,0,0,36);amount.Position=UDim2.fromOffset(0,244);amount.BackgroundColor3=currentTheme.tertiary;amount.TextColor3=currentTheme.text;amount.BorderSizePixel=0;amount.ClearTextOnFocus=false;amount.Font=Enum.Font.Code;amount.TextSize=13;amount.ZIndex=8
    Instance.new("UICorner",amount).CornerRadius=UDim.new(0,8);RegisterTheme(amount,"BackgroundColor3","tertiary");RegisterTheme(amount,"TextColor3","text")
    local slider=Instance.new("TextButton",card)
    slider.Name="ContactIntensitySlider";slider.Size=UDim2.new(1,0,0,32);slider.Position=UDim2.fromOffset(0,288);slider.BackgroundTransparency=1;slider.Text="";slider.ZIndex=8;slider.AutoButtonColor=false
    local track=Instance.new("Frame",slider);track.Size=UDim2.new(1,0,0,6);track.Position=UDim2.new(0,0,.5,-3);track.BorderSizePixel=0;track.BackgroundColor3=currentTheme.tertiary;track.ZIndex=8;RegisterTheme(track,"BackgroundColor3","tertiary")
    local fill=Instance.new("Frame",track);fill.Size=UDim2.fromScale(0,1);fill.BackgroundColor3=currentTheme.accent;fill.BorderSizePixel=0;fill.ZIndex=9;RegisterTheme(fill,"BackgroundColor3","accent")
    local knob=Instance.new("Frame",slider);knob.Size=UDim2.fromOffset(18,18);knob.AnchorPoint=Vector2.new(.5,.5);knob.Position=UDim2.fromScale(0,.5);knob.BackgroundColor3=currentTheme.text;knob.BorderSizePixel=0;knob.ZIndex=10;Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0);RegisterTheme(knob,"BackgroundColor3","text")
    local adjustableStatus=status:Clone();adjustableStatus.Position=UDim2.fromOffset(0,328);adjustableStatus.Size=UDim2.new(1,0,0,54);adjustableStatus.Parent=card;RegisterTheme(adjustableStatus,"TextColor3","textDim")
    UpdateAdjustableContactFlingPanel=function(message)
        adjustableToggle.Text=adjustable.Running and (isES and "Desactivar contacto ajustable"or "Disable adjustable contact")or (isES and "Activar contacto ajustable"or "Enable adjustable contact")
        adjustableToggle.BackgroundColor3=adjustable.Running and currentTheme.accent or currentTheme.tertiary
        amount.Text=string.format("%.0f",adjustable.Intensity)
        local alpha=math.log(adjustable.Intensity/100000)/math.log(10000)
        fill.Size=UDim2.fromScale(alpha,1);knob.Position=UDim2.fromScale(alpha,.5)
        adjustableStatus.Text=message or ((isES and "Velocidad por eje XYZ · "or "Speed per XYZ axis · ")..string.format("%.2fx",adjustable.Intensity/100000)..(isES and " del original. Ajustable durante el uso."or " original strength. Adjustable while running."))
    end
    adjustableToggle.Activated:Connect(function()
        if adjustable.Running then adjustable:Stop()else local ok,err=adjustable:Start();if not ok then UpdateAdjustableContactFlingPanel(err);return end end
        UpdateContactFlingPanel();UpdateAdjustableContactFlingPanel()
    end)
    amount.FocusLost:Connect(function()
        local ok=adjustable:SetIntensity(tonumber((amount.Text:gsub(",","."))))
        UpdateAdjustableContactFlingPanel(not ok and (isES and "Valor permitido: 100000 a 1000000000 por eje."or "Allowed: 100000 to 1000000000 per axis.")or nil)
    end)
    local inputService=game:GetService("UserInputService")
    local dragging,dragInput=false,nil
    local function slide(input)
        local width=slider.AbsoluteSize.X;if width<=0 then return end
        local alpha=math.clamp((input.Position.X-slider.AbsolutePosition.X)/width,0,1)
        adjustable:SetIntensity(math.floor(100000*10000^alpha+.5));UpdateAdjustableContactFlingPanel()
    end
    slider.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true;dragInput=input;contactFlingPanel.ScrollingEnabled=false;slide(input)
        end
    end)
    local moved=inputService.InputChanged:Connect(function(input)
        if dragging and (input==dragInput or input.UserInputType==Enum.UserInputType.MouseMovement)then slide(input)end
    end)
    local ended=inputService.InputEnded:Connect(function(input)
        if input==dragInput then dragging=false;dragInput=nil;contactFlingPanel.ScrollingEnabled=true end
    end)
    adjustable.CleanupUI=function()moved:Disconnect();ended:Disconnect();dragging=false;contactFlingPanel.ScrollingEnabled=true end
    UpdateAdjustableContactFlingPanel()
    UpdateContactFlingPanel()
    return true
end
