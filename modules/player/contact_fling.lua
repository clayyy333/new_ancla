-- WALK FLING CLONE V3 integrado.
-- Conserva literalmente el ciclo físico probado; usa la GUI principal.
return function(context)
    setfenv(1,context)

    local PlayersService=game:GetService("Players")
    local RunServiceDirect=game:GetService("RunService")
    local LP=PlayersService.LocalPlayer
    local ENV=getgenv()

    -- Retirar cualquier copia previa, incluida la GUI de prueba independiente.
    if ENV.__WF_V3_CLEANUP then pcall(ENV.__WF_V3_CLEANUP) end
    if ENV.__WF_ADAPTIVE_CLEANUP then pcall(ENV.__WF_ADAPTIVE_CLEANUP) end
    if ENV.__VR7_CONTACT_FLING_CLEANUP then
        pcall(ENV.__VR7_CONTACT_FLING_CLEANUP)
    end

    local PULSE_MAGNITUDE=500000
    local ANGULAR_PULSE_MAGNITUDE=250000
    local BIND_NAME="__WF_V3_RESTORE"

    local enabled=false
    local destroyed=false
    local connections={}
    local cycleRoot=nil
    local cycleVelocity=nil
    local cycleAssemblyVelocity=nil
    local cycleAngularVelocity=nil
    local cycleAssemblyAngularVelocity=nil
    local pulseActive=false
    local originalCanCollide=nil
    local pulseDirection=1
    local teleporting=false

    local C={Running=false,SelectedTarget=nil}
    C.Status=isES and "Fling por contacto desactivado" or "Contact Fling disabled"

    local function update(text)
        C.Status=text or C.Status
        if UpdateContactFlingPanel then UpdateContactFlingPanel(C.Status) end
    end

    local function getRoot()
        local character=LP.Character
        if not character then return nil end
        return character:FindFirstChild("HumanoidRootPart")
    end

    local function restoreCurrentPulse()
        if not pulseActive then return end

        local root=cycleRoot
        local oldVelocity=cycleVelocity
        local oldAssemblyVelocity=cycleAssemblyVelocity
        local oldAngularVelocity=cycleAngularVelocity
        local oldAssemblyAngularVelocity=cycleAssemblyAngularVelocity
        pulseActive=false
        cycleRoot=nil
        cycleVelocity=nil
        cycleAssemblyVelocity=nil
        cycleAngularVelocity=nil
        cycleAssemblyAngularVelocity=nil

        if root and root.Parent and oldVelocity and oldAssemblyVelocity
            and oldAngularVelocity and oldAssemblyAngularVelocity then
            pcall(function()
                local stillExtreme=root.Velocity.Magnitude>1000
                    or root.AssemblyLinearVelocity.Magnitude>1000
                    or root.RotVelocity.Magnitude>1000
                    or root.AssemblyAngularVelocity.Magnitude>1000
                if stillExtreme then
                    root.Velocity=oldVelocity
                    root.AssemblyLinearVelocity=oldAssemblyVelocity
                    root.RotVelocity=oldAngularVelocity
                    root.AssemblyAngularVelocity=oldAssemblyAngularVelocity
                end
            end)
        end
    end

    local function stop(respawned)
        enabled=false
        C.Running=false
        restoreCurrentPulse()

        local root=getRoot()
        if root and originalCanCollide~=nil then
            pcall(function()
                root.CanCollide=originalCanCollide
            end)
        end
        originalCanCollide=nil

        if respawned then
            update(isES and "Reaparición: vuelve a activar" or "Respawn: enable it again")
        else
            update(isES and "Fling por contacto desactivado" or "Contact Fling disabled")
        end
    end

    local function onPostSimulation()
        if not enabled or teleporting then return end

        restoreCurrentPulse()

        local root=getRoot()
        if not root then return end

        -- El HRP debe seguir siendo la raíz de la assembly del personaje.
        -- Si Roblox expone otra raíz interna, escribir ambas propiedades sobre
        -- el HRP continúa afectando la assembly sin mover CFrames.
        local physicalVelocity=root.Velocity
        local physicalAssemblyVelocity=root.AssemblyLinearVelocity
        local physicalAngularVelocity=root.RotVelocity
        local physicalAssemblyAngularVelocity=root.AssemblyAngularVelocity
        cycleRoot=root
        cycleVelocity=physicalVelocity
        cycleAssemblyVelocity=physicalAssemblyVelocity
        cycleAngularVelocity=physicalAngularVelocity
        cycleAssemblyAngularVelocity=physicalAssemblyAngularVelocity
        pulseActive=true

        -- Alternar X/Z produce impactos repetidos sin acumular siempre
        -- desplazamiento propio en una sola dirección horizontal.
        pulseDirection=-pulseDirection
        local pulse=Vector3.new(
            PULSE_MAGNITUDE*pulseDirection,
            PULSE_MAGNITUDE,
            PULSE_MAGNITUDE*pulseDirection
        )

        local angularPulse=Vector3.new(
            ANGULAR_PULSE_MAGNITUDE*pulseDirection,
            ANGULAR_PULSE_MAGNITUDE,
            -ANGULAR_PULSE_MAGNITUDE*pulseDirection
        )

        root.CanCollide=false
        root.Velocity=pulse
        root.AssemblyLinearVelocity=pulse
        root.RotVelocity=angularPulse
        root.AssemblyAngularVelocity=angularPulse
    end

    local function onRenderEnd()
        if not enabled then return end
        restoreCurrentPulse()
    end

    function C:GetTargetOptions()
        local result={}
        for _,target in ipairs(PlayersService:GetPlayers()) do
            if target~=LP then result[#result+1]=target end
        end
        return result
    end

    function C:SetTarget(target)
        self.SelectedTarget=typeof(target)=="Instance"
            and target:IsA("Player")
            and target.Parent==PlayersService
            and target
            or nil
        return self.SelectedTarget~=nil
    end

    function C:GetTarget()
        return self.SelectedTarget
    end

    function C:TeleportToTarget()
        if teleporting then
            return false,isES and "El TP ya está en curso." or "Teleport is already running."
        end

        local target=self.SelectedTarget
        if not target or target.Parent~=PlayersService then
            return false,isES and "Selecciona un jugador." or "Select a player."
        end

        local targetRoot=nil
        local targetFrame=nil
        local targetCharacter=target.Character or workspace:FindFirstChild(target.Name)

        local function captureTargetFrame()
            targetCharacter=target.Character or workspace:FindFirstChild(target.Name) or targetCharacter
            if not targetCharacter or not targetCharacter.Parent then return end
            local directRoot=targetCharacter:FindFirstChild("HumanoidRootPart")
            if directRoot and directRoot:IsA("BasePart") then
                targetRoot=directRoot
                targetFrame=directRoot.CFrame
                return
            end
            local anyPart=targetCharacter:FindFirstChildWhichIsA("BasePart",true)
            if anyPart then
                local ok,pivot=pcall(function() return targetCharacter:GetPivot() end)
                if ok and typeof(pivot)=="CFrame" then targetFrame=pivot end
            end
        end

        captureTargetFrame()
        if targetFrame then
            pcall(function() workspace:RequestStreamAroundAsync(targetFrame.Position,0.5) end)
        end
        if not targetRoot and TargetRootResolver then
            targetRoot=TargetRootResolver:Resolve(target,3)
            if targetRoot and targetRoot.Parent then targetFrame=targetRoot.CFrame end
        end
        if not targetFrame then
            local deadline=os.clock()+3
            repeat
                captureTargetFrame()
                if targetFrame then
                    pcall(function() workspace:RequestStreamAroundAsync(targetFrame.Position,0.5) end)
                end
                if not targetFrame then task.wait(0.1) end
            until targetFrame or os.clock()>=deadline or target.Parent~=PlayersService
        end
        if not targetFrame then
            return false,isES and "No se recibió la ubicación del jugador lejano." or "The distant player's position was not received."
        end

        local character=LP.Character
        local root=getRoot()
        if not character or not root then
            return false,isES and "Tu HRP no está disponible." or "Your HRP is unavailable."
        end

        pcall(function()
            workspace:RequestStreamAroundAsync(targetFrame.Position,1)
        end)

        teleporting=true
        restoreCurrentPulse()
        update(isES and "Forzando TP..." or "Forcing teleport...")

        local moved=false
        local deadline=os.clock()+1
        while os.clock()<deadline do
            if not character.Parent or not root.Parent or target.Parent~=PlayersService then break end
            local currentCharacter=target.Character
            local currentTargetRoot=currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")
            if currentTargetRoot and currentTargetRoot.Parent then
                targetRoot=currentTargetRoot
                targetFrame=currentTargetRoot.CFrame
            end

            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
            local ok=pcall(function() character:PivotTo(targetFrame) end)
            if not ok then pcall(function() root.CFrame=targetFrame end) end
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
            moved=true
            RunServiceDirect.Heartbeat:Wait()
        end

        if character.Parent and root.Parent then
            pcall(function() character:PivotTo(targetFrame) end)
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
        end
        teleporting=false

        if not moved then
            return false,isES and "No se pudo completar el TP." or "Teleport could not be completed."
        end
        update((isES and "TP realizado a " or "Teleported to ")..target.DisplayName)
        return true
    end

    function C:Start()
        if enabled then return true end

        -- Cada activación comienza un ciclo físico completamente nuevo.
        restoreCurrentPulse()
        teleporting=false
        pulseDirection=1

        local root=getRoot()
        if not root then
            local message=isES and "HumanoidRootPart no encontrado." or "HumanoidRootPart not found."
            update(message)
            return false,message
        end

        originalCanCollide=root.CanCollide
        enabled=true
        self.Running=true
        root.CanCollide=false
        update(isES and "Fling por contacto activo" or "Contact Fling active")
        return true
    end

    function C:Stop(respawned)
        stop(respawned)
    end

    local function cleanup()
        if destroyed then return end
        stop(false)
        destroyed=true

        for _,connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(connections)

        pcall(function()
            RunServiceDirect:UnbindFromRenderStep(BIND_NAME)
        end)

        if ENV.__VR7_CONTACT_FLING_CLEANUP==cleanup then
            ENV.__VR7_CONTACT_FLING_CLEANUP=nil
        end
    end

    function C:Destroy()
        cleanup()
    end

    connections[#connections+1]=RunServiceDirect.PostSimulation:Connect(onPostSimulation)

    pcall(function()
        RunServiceDirect:UnbindFromRenderStep(BIND_NAME)
    end)
    RunServiceDirect:BindToRenderStep(BIND_NAME,100000,onRenderEnd)

    connections[#connections+1]=LP.CharacterAdded:Connect(function()
        stop(true)
    end)
    connections[#connections+1]=PlayersService.PlayerRemoving:Connect(function(leaving)
        if C.SelectedTarget==leaving then
            C.SelectedTarget=nil
            update(isES and "El jugador seleccionado salió." or "The selected player left.")
        end
    end)

    ENV.__VR7_CONTACT_FLING_CLEANUP=cleanup
    ContactFlingController=C
    return true
end
