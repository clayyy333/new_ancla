-- El panel decide la disponibilidad; los permisos de owner siguen en sus controladores.
return function(context)
    setfenv(1,context)
    local blocked,stopping=false,false
    local buttons=setmetatable({},{__mode="k"})
    local cores,seen={},{}
    local connections={}
    AreFeaturesBlocked=function()return blocked end
    local falseAllowed={SetEnabled=true,SetAutoEnabled=true,SetMobileEnabled=true,SetPhase=true,
        SetTest=true,SetHeartbeat=true,SetAntiSeat=true,SetAncla=true,SetSprint=true,SetBoost=true}
    local function activating(name)
        if name:sub(1,1)=="_"then return false end
        for _,prefix in ipairs({"Start","Enable","Set","Toggle","Position","Teleport","Preview","Use","Rejoin","Equip","Select","Change","Increase","Decrease","Add","Adjust","Accept"})do
            if name:sub(1,#prefix)==prefix then return true end
        end
        return name=="Force"or name=="RefreshTarget"
    end
    local function register(core)
        if type(core)~="table"or seen[core]then return end
        seen[core]=true;cores[#cores+1]=core
        local methods={}
        for name,fn in pairs(core)do if type(name)=="string"and type(fn)=="function"and activating(name)then methods[#methods+1]={name,fn}end end
        for _,entry in ipairs(methods)do
            local name,original=entry[1],entry[2]
            core[name]=function(self,...)
                if blocked and not stopping and not(falseAllowed[name]and select(1,...)==false)then return false end
                return original(self,...)
            end
        end
    end
    -- Solo se inspeccionan los controladores de esta aplicacion, nunca Workspace.
    for name,value in pairs(context)do
        if type(name)=="string"and(name:match("Core$")or name:match("Controller$")or name:match("Coordinator$")
            or name:match("^CarFling")or name=="LocalEmoteFollow")then register(value)end
    end
    -- Algunos cargadores exponen estas referencias mediante __index.
    for _,name in ipairs({"AnchorCore","AutoAnchorCore","StaticPassThroughAnchorCore","StaticNoclipAnchorCore",
        "MobileAnchorCore","MobileAnchorV11Core","MobileAnchorV13Core","EmergencyAnchorController",
        "DeploymentSafetyCore","DeploymentAnchorMotorCore","BabyVehicleAnchorCore","SeatAnchorLabCore",
        "AutoSkateDelta","AutoSkateXeno","AnchorTestSkateDelta","AnchorTestAntiRam","AnchorForceReturn",
        "Fling2Core","Fling2EfficientCore","Fling2AutoController","ExperimentalFlingCore","HybridFlingCore",
        "V8PersistentFlingCore","CustomFlingCore","ObjectV8FlingCore","NoMotosCore","NoMotos2Core",
        "ContactFlingController","AdjustableContactFlingController","MotoFlingCore","MotoFlingXenoCore",
        "CarFling","CarFlingXeno","CarFling2Delta","CarFling2Xeno","CarFlingAutoCoordinator",
        "FoldingCleanupCore","ValentineCleanupCore","GenericAttachedCleanupCore","SpectatorController",
        "FlightController","CarControlController","FreeCarController","MovementControlController",
        "UserShortcutController","VerticalControlController","CouplesPositionController","CoupleMovementController",
        "PresetPoseController","AmbientSoundController","AntiAFKController","RejoinController",
        "FPSBoosterCore","NightShaderCore","SkyFireworksCore","LocalEmoteFollow"})do register(context[name])end
    for _,name in ipairs({"PlayEmote","EquipAnimationPart","EquipAnimationPack","ApplyAnimationCombination","ReapplyAnimationSelection","ApplySpeedToAllTracks"})do
        local original=context[name]
        if type(original)=="function"then
            context[name]=function(...)if blocked and not stopping then return false end;return original(...)end
        end
    end
    local function call(core,method,...)
        if type(core[method])=="function"then pcall(core[method],core,...)end
    end
    local function stopFunctions()
        stopping=true
        -- Cortamos las secuencias antes de parar sus pistas para que no se relancen.
        isComboActive=false;_comboLoopEnabled=false
        if type(ComboQueue)=="table"then table.clear(ComboQueue)end
        if LocalEmoteFollow and type(LocalEmoteFollow.Stop)=="function"then pcall(LocalEmoteFollow.Stop)end
        if type(StopEmote)=="function"then pcall(StopEmote,false)end
        if type(SuspendAnimationSelection)=="function"then pcall(SuspendAnimationSelection)end
        for _,core in ipairs(cores)do
            for _,method in ipairs({"Stop","StopLoop","Release","Disable","Restore","RestoreWalkSpeed","RestoreJump","ClearMobileInput"})do call(core,method)end
            if core~=AmbientSoundController then call(core,"SetEnabled",false)end
            for _,method in ipairs({"SetAutoEnabled","SetMobileEnabled","SetPhase","SetTest","SetHeartbeat","SetAntiSeat","SetAncla"})do call(core,method,false)end
        end
        if AmbientSoundController then call(AmbientSoundController,"SetEnabled",true)end
        stopping=false
    end
    local function windowControl(button)
        return button==minBtn or button==closeBtn or button.Name=="WindowLauncher"
    end
    local function protect(button)
        if not(button:IsA("GuiButton")or button:IsA("TextBox"))or buttons[button]or button.Name=="FeatureBlockShade"or windowControl(button)then return end
        local shade=Instance.new("TextButton")
        shade.Name="FeatureBlockShade";shade.Size=UDim2.fromScale(1,1);shade.Text=""
        shade.BackgroundColor3=Color3.new(0,0,0);shade.BackgroundTransparency=.45
        shade.BorderSizePixel=0;shade.AutoButtonColor=false;shade.Active=true
        shade.ZIndex=button.ZIndex+50;shade.Visible=blocked
        local corner=button:FindFirstChildOfClass("UICorner")
        if corner then corner:Clone().Parent=shade end
        local state={shade=shade,active=button.Active,editable=button:IsA("TextBox")and button.TextEditable}
        buttons[button]=state;shade.Parent=button
        if blocked then
            button.Active=false
            if button:IsA("TextBox")then button.TextEditable=false end
        end
    end
    -- Incluye tarjetas, HUD, ajustes, controles y botones que se creen despues.
    if gui then
        for _,button in ipairs(gui:GetDescendants())do protect(button)end
        connections[#connections+1]=gui.DescendantAdded:Connect(protect)
        connections[#connections+1]=gui.Destroying:Connect(function()
            for _,connection in ipairs(connections)do connection:Disconnect()end
            table.clear(connections)
        end)
    end
    ApplyFeatureBlock=function(value)
        value=value==true
        if value==blocked then return end
        blocked=value
        if blocked then stopFunctions()end
        for button,state in pairs(buttons)do
            if button.Parent then
                state.shade.Visible=blocked
                button.Active=not blocked and state.active or false
                if button:IsA("TextBox")then button.TextEditable=not blocked and state.editable or false end
            else buttons[button]=nil end
        end
    end
    if BackendAnchorGuard then ApplyFeatureBlock(BackendAnchorGuard.FeaturesBlocked)end
    return true
end
