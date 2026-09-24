-- Fling físico pasivo por contacto, aislado de los motores de Fling 2.
return function(context)
    setfenv(1,context)

    local C={
        Running=false,
        PhysicsConnections={},
        Connections={},
        SavedAutoRotate=nil,
        DesiredRotation=nil,
    }
    C.Status=isES and "Fling por contacto desactivado" or "Contact Fling disabled"

    local function update(text)
        C.Status=text or C.Status
        if UpdateContactFlingPanel then UpdateContactFlingPanel(C.Status) end
    end

    local function disconnect(list)
        for _,connection in ipairs(list) do pcall(function() connection:Disconnect() end) end
        table.clear(list)
    end

    local function getCharacterState(character)
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health<=0 or not root or not root:IsA("BasePart") then return nil end
        return root,humanoid
    end

    function C:_BindCharacter(character)
        disconnect(self.PhysicsConnections)
        local root,humanoid=getCharacterState(character)
        if not self.Running or not root then return false end

        self.SavedAutoRotate=humanoid.AutoRotate
        self.DesiredRotation=root.CFrame.Rotation
        humanoid.AutoRotate=false

        -- La velocidad angular permanece en el cuerpo completo. No busca objetivos ni
        -- espera eventos Touched: la propia colisión física transmite el impulso.
        table.insert(self.PhysicsConnections,RunService.PreSimulation:Connect(function()
            if not self.Running or not root.Parent or humanoid.Health<=0 then return end
            local move=humanoid.MoveDirection
            local flat=Vector3.new(move.X,0,move.Z)
            if flat.Magnitude>0.05 then
                self.DesiredRotation=CFrame.lookAt(Vector3.zero,flat.Unit).Rotation
            end
            root.AssemblyAngularVelocity=Vector3.new(900000000,900000000,900000000)
        end))

        -- Compensa solo la rotación visible; conserva posición, salto y velocidad de marcha.
        table.insert(self.PhysicsConnections,RunService.PostSimulation:Connect(function()
            if not self.Running or not root.Parent then return end
            root.CFrame=CFrame.new(root.Position)*(self.DesiredRotation or root.CFrame.Rotation)
        end))

        update(isES and "Activo: cuerpo físico pasivo" or "Active: passive physical body")
        return true
    end

    function C:Start()
        if self.Running then return true end
        local root=getCharacterState(player.Character)
        if not root then
            return false,isES and "Tu personaje no está disponible." or "Your character is unavailable."
        end
        self.Running=true
        if not self:_BindCharacter(player.Character) then
            self.Running=false
            return false,isES and "No se pudo preparar el personaje." or "Could not prepare the character."
        end
        return true
    end

    function C:Stop()
        if not self.Running then return end
        self.Running=false
        disconnect(self.PhysicsConnections)
        local root,humanoid=getCharacterState(player.Character)
        if root then root.AssemblyAngularVelocity=Vector3.zero end
        if humanoid and self.SavedAutoRotate~=nil then humanoid.AutoRotate=self.SavedAutoRotate end
        self.DesiredRotation=nil
        self.SavedAutoRotate=nil
        update(isES and "Fling por contacto desactivado" or "Contact Fling disabled")
    end

    function C:Destroy()
        self:Stop()
        disconnect(self.Connections)
    end

    table.insert(C.Connections,player.CharacterAdded:Connect(function(character)
        if C.Running then
            task.defer(function()
                character:WaitForChild("HumanoidRootPart",5)
                if C.Running then C:_BindCharacter(character) end
            end)
        end
    end))
    table.insert(C.Connections,player.CharacterRemoving:Connect(function()
        disconnect(C.PhysicsConnections)
        C.DesiredRotation=nil
        C.SavedAutoRotate=nil
    end))

    ContactFlingController=C
    return true
end