-- Independent adjustable contact pulse; same timing as contact_fling.
-- Flujo lineal estable; usa la GUI principal.
return function(context)
    setfenv(1,context)

    local PlayersService=game:GetService("Players")
    local RunServiceDirect=game:GetService("RunService")
    local LP=PlayersService.LocalPlayer
    local ENV=getgenv()

    if ENV.__VR7_CONTACT_ADJUSTABLE_CLEANUP then
        pcall(ENV.__VR7_CONTACT_ADJUSTABLE_CLEANUP)
    end

    local BIND_NAME="__VR7_CONTACT_ADJUSTABLE_RESTORE"

    local enabled=false
    local destroyed=false
    local connections={}
    local cycleRoot=nil
    local cycleVelocity=nil
    local cycleAssemblyVelocity=nil
    local cyclePulse=nil
    local pulseActive=false
    local originalCanCollide=nil

    local C={Running=false,Intensity=100000,Axes={X=100000,Y=100000,Z=100000},MaxIntensity=1000000000000}
    function C:IsAuthorized()
        return true
    end
    C.Status=isES and "Fling por contacto desactivado" or "Contact Fling disabled"

    local function update(text)
        C.Status=text or C.Status
        if UpdateAdjustableContactFlingPanel then UpdateAdjustableContactFlingPanel(C.Status) end
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
        local applied=cyclePulse
        pulseActive=false
        cycleRoot=nil
        cycleVelocity=nil
        cycleAssemblyVelocity=nil
        cyclePulse=nil

        if root and root.Parent and oldVelocity and oldAssemblyVelocity then
            pcall(function()
                local stillExtreme=root.Velocity.Magnitude>1000
                    or root.AssemblyLinearVelocity.Magnitude>1000
                if stillExtreme or root.Velocity==applied or root.AssemblyLinearVelocity==applied then
                    root.Velocity=oldVelocity
                    root.AssemblyLinearVelocity=oldAssemblyVelocity
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
            pcall(function() root.CanCollide=originalCanCollide end)
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
        if not C:IsAuthorized() then stop(false);return end
        restoreCurrentPulse()

        local root=getRoot()
        if not root then return end

        cycleRoot=root
        cycleVelocity=root.Velocity
        cycleAssemblyVelocity=root.AssemblyLinearVelocity
        pulseActive=true

        root.CanCollide=false
        local pulse=Vector3.new(C.Axes.X,C.Axes.Y,C.Axes.Z)
        cyclePulse=pulse
        root.Velocity=pulse
        root.AssemblyLinearVelocity=pulse
    end

    local function onRenderEnd()
        if not enabled then return end
        restoreCurrentPulse()
    end

    function C:SetIntensity(value)
        if not self:IsAuthorized() then return false end
        if type(value)~="number" or value~=value or value<100000 or value>self.MaxIntensity then return false end
        restoreCurrentPulse()
        self.Intensity=value
        self.Axes={X=value,Y=value,Z=value}
        return true
    end

    function C:SetAxis(axis,value)
        if self.Axes[axis]==nil or type(value)~="number"or value~=value or math.abs(value)>self.MaxIntensity then return false end
        restoreCurrentPulse()
        self.Axes[axis]=value
        self.Intensity=math.max(math.abs(self.Axes.X),math.abs(self.Axes.Y),math.abs(self.Axes.Z))
        return true
    end

    function C:Start()
        if not self:IsAuthorized() then return false,"Solo owners." end
        if ContactFlingController and ContactFlingController.Running then ContactFlingController:Stop() end
        if enabled then return true end
        restoreCurrentPulse()

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
        pcall(function() RunServiceDirect:UnbindFromRenderStep(BIND_NAME) end)
        if ENV.__VR7_CONTACT_ADJUSTABLE_CLEANUP==cleanup then
            ENV.__VR7_CONTACT_ADJUSTABLE_CLEANUP=nil
        end
    end

    function C:Destroy()
        if self.CleanupUI then self.CleanupUI();self.CleanupUI=nil end
        cleanup()
    end

    connections[#connections+1]=RunServiceDirect.PostSimulation:Connect(onPostSimulation)
    pcall(function() RunServiceDirect:UnbindFromRenderStep(BIND_NAME) end)
    RunServiceDirect:BindToRenderStep(BIND_NAME,100000,onRenderEnd)
    connections[#connections+1]=LP.CharacterAdded:Connect(function() stop(true) end)

    ENV.__VR7_CONTACT_ADJUSTABLE_CLEANUP=cleanup
    AdjustableContactFlingController=C
    return true
end
