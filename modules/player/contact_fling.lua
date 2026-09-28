-- Fling por contacto caminable.
-- Pulso extremo dentro del mismo ciclo físico (Delta / Xeno).
return function(context)
    setfenv(1,context)

    local PULSE_VELOCITY=Vector3.new(100000,100000,100000)
    local RESTORE_THRESHOLD=1000
    local RENDER_BIND_NAME="__VR7_CONTACT_FLING_RESTORE_"..tostring(player.UserId)
    local C={Running=false,Destroyed=false,CycleRoot=nil,CycleVelocity=nil,PulseActive=false,OriginalCanCollide=nil,Connections={}}
    C.Status=isES and "Fling por contacto desactivado" or "Contact Fling disabled"

    local function update(text)
        C.Status=text or C.Status
        if UpdateContactFlingPanel then UpdateContactFlingPanel(C.Status) end
    end

    local function getRoot()
        local character=player.Character
        return character and character:FindFirstChild("HumanoidRootPart") or nil
    end

    function C:_RestorePulse()
        if not self.PulseActive then return end
        local root=self.CycleRoot
        local oldVelocity=self.CycleVelocity
        self.PulseActive=false
        self.CycleRoot=nil
        self.CycleVelocity=nil
        if root and root.Parent and oldVelocity then
            pcall(function()
                if root.Velocity.Magnitude>RESTORE_THRESHOLD then root.Velocity=oldVelocity end
            end)
        end
    end

    function C:_OnPostSimulation()
        if not self.Running then return end
        self:_RestorePulse()
        local root=getRoot()
        if not root then return end
        self.CycleRoot=root
        self.CycleVelocity=root.Velocity
        self.PulseActive=true
        root.CanCollide=false
        root.Velocity=PULSE_VELOCITY
    end

    function C:Start()
        if self.Running then return true end
        local root=getRoot()
        if not root then
            local message=isES and "HumanoidRootPart no encontrado." or "HumanoidRootPart not found."
            update(message)
            return false,message
        end
        self.OriginalCanCollide=root.CanCollide
        self.Running=true
        root.CanCollide=false
        update(isES and "Fling por contacto activo" or "Contact Fling active")
        return true
    end

    function C:Stop(respawned)
        self.Running=false
        self:_RestorePulse()
        local root=getRoot()
        if root and self.OriginalCanCollide~=nil then
            pcall(function() root.CanCollide=self.OriginalCanCollide end)
        end
        self.OriginalCanCollide=nil
        if respawned then
            update(isES and "Reaparición: vuelve a activar" or "Respawn: enable it again")
        else
            update(isES and "Fling por contacto desactivado" or "Contact Fling disabled")
        end
    end

    function C:Destroy()
        if self.Destroyed then return end
        self:Stop()
        self.Destroyed=true
        for _,connection in ipairs(self.Connections) do pcall(function() connection:Disconnect() end) end
        table.clear(self.Connections)
        pcall(function() RunService:UnbindFromRenderStep(RENDER_BIND_NAME) end)
    end

    -- Respaldo independiente de los FPS: si el render se retrasó o no ocurrió,
    -- retirar el pulso antes de que Roblox simule el siguiente ciclo físico.
    -- Normalmente no hace nada porque RenderStepped ya restauró la velocidad.
    table.insert(C.Connections,RunService.PreSimulation:Connect(function()
        if C.Running then C:_RestorePulse() end
    end))

    table.insert(C.Connections,RunService.PostSimulation:Connect(function() C:_OnPostSimulation() end))
    pcall(function() RunService:UnbindFromRenderStep(RENDER_BIND_NAME) end)
    RunService:BindToRenderStep(RENDER_BIND_NAME,100000,function()
        if C.Running then C:_RestorePulse() end
    end)
    table.insert(C.Connections,player.CharacterAdded:Connect(function()
        if C.Running then C:Stop(true) end
    end))

    ContactFlingController=C
    return true
end
