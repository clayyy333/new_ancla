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

    local C={Running=false}
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
        if not enabled then return end

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

    function C:Start()
        if enabled then return true end

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

    ENV.__VR7_CONTACT_FLING_CLEANUP=cleanup
    ContactFlingController=C
    return true
end
