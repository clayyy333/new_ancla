-- Fling pasivo mediante un accesorio físico independiente.
return function(context)
    setfenv(1,context)

    local ANGULAR_FORCE=900000000
    local HANDLE_OFFSET=Vector3.new(0,0,-2.25)
    local SELF_RECOIL_LIMIT=160
    local C={
        Running=false,
        SelectedAccessory=nil,
        Handle=nil,
        RestoreData=nil,
        RuntimeInstances={},
        PhysicsConnections={},
        Connections={},
        SafeRootVelocity=Vector3.zero,
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

    local function destroyRuntime()
        for index=#C.RuntimeInstances,1,-1 do
            local object=C.RuntimeInstances[index]
            if object then pcall(function() object:Destroy() end) end
            C.RuntimeInstances[index]=nil
        end
    end

    local function findAccessory(character)
        local bestAccessory,bestHandle,bestWeld,bestScore
        for _,accessory in ipairs(character:GetChildren()) do
            if accessory:IsA("Accessory") then
                local handle=accessory:FindFirstChild("Handle")
                local weld=handle and (handle:FindFirstChild("AccessoryWeld") or handle:FindFirstChildWhichIsA("Weld"))
                if handle and handle:IsA("BasePart") and weld and weld:IsA("Weld") and weld.Part1 then
                    local size=handle.Size
                    local volume=size.X*size.Y*size.Z
                    local score=volume+(weld.Name=="AccessoryWeld" and 1000 or 0)
                    if not bestScore or score>bestScore then
                        bestAccessory,bestHandle,bestWeld,bestScore=accessory,handle,weld,score
                    end
                end
            end
        end
        return bestAccessory,bestHandle,bestWeld
    end

    function C:_ReleaseAccessory()
        disconnect(self.PhysicsConnections)
        local handle=self.Handle
        local data=self.RestoreData
        if handle and handle.Parent then
            pcall(function()
                handle.AssemblyLinearVelocity=Vector3.zero
                handle.AssemblyAngularVelocity=Vector3.zero
            end)
        end
        destroyRuntime()
        if handle and handle.Parent and data then
            pcall(function()
                handle.CanCollide=data.CanCollide
                handle.CanTouch=data.CanTouch
                handle.CanQuery=data.CanQuery
                handle.Massless=data.Massless
                handle.CustomPhysicalProperties=data.CustomPhysicalProperties
                handle.LocalTransparencyModifier=data.LocalTransparencyModifier
                handle.CFrame=data.CFrame
            end)
            if data.Weld and data.Weld.Parent then
                pcall(function()
                    data.Weld.Part0=data.Part0
                    data.Weld.Part1=data.Part1
                    data.Weld.C0=data.C0
                    data.Weld.C1=data.C1
                end)
            end
        end
        self.SelectedAccessory=nil
        self.Handle=nil
        self.RestoreData=nil
        self.SafeRootVelocity=Vector3.zero
    end

    function C:_PrepareCharacter(character)
        self:_ReleaseAccessory()
        if not self.Running or not character then return false end
        local root=character:FindFirstChild("HumanoidRootPart")
        local humanoid=character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health<=0 then return false end

        local accessory,handle,weld=findAccessory(character)
        if not accessory then
            update(isES and "No se encontró un accesorio clásico compatible con Handle." or "No compatible classic accessory with a Handle was found.")
            return false
        end

        self.SelectedAccessory=accessory
        self.Handle=handle
        self.RestoreData={
            Weld=weld,Part0=weld.Part0,Part1=weld.Part1,C0=weld.C0,C1=weld.C1,
            CanCollide=handle.CanCollide,CanTouch=handle.CanTouch,CanQuery=handle.CanQuery,
            Massless=handle.Massless,CustomPhysicalProperties=handle.CustomPhysicalProperties,
            LocalTransparencyModifier=handle.LocalTransparencyModifier,CFrame=handle.CFrame,
        }

        weld.Part1=nil
        handle.CanCollide=true
        handle.CanTouch=true
        handle.CanQuery=false
        handle.Massless=false
        handle.LocalTransparencyModifier=1
        handle.CustomPhysicalProperties=PhysicalProperties.new(100,0,0,100,100)
        handle.CFrame=root.CFrame*CFrame.new(HANDLE_OFFSET)

        local rootAttachment=Instance.new("Attachment")
        rootAttachment.Name="ContactFlingRootAttachment"
        rootAttachment.Position=HANDLE_OFFSET
        rootAttachment.Parent=root
        table.insert(self.RuntimeInstances,rootAttachment)

        local handleAttachment=Instance.new("Attachment")
        handleAttachment.Name="ContactFlingHandleAttachment"
        handleAttachment.Parent=handle
        table.insert(self.RuntimeInstances,handleAttachment)

        local align=Instance.new("AlignPosition")
        align.Name="ContactFlingAlignPosition"
        align.Attachment0=handleAttachment
        align.Attachment1=rootAttachment
        align.ApplyAtCenterOfMass=true
        align.ReactionForceEnabled=false
        align.MaxForce=math.huge
        align.MaxVelocity=math.huge
        align.Responsiveness=200
        align.RigidityEnabled=true
        align.Parent=handle
        table.insert(self.RuntimeInstances,align)

        local angular=Instance.new("AngularVelocity")
        angular.Name="ContactFlingAngularVelocity"
        angular.Attachment0=handleAttachment
        angular.RelativeTo=Enum.ActuatorRelativeTo.World
        angular.AngularVelocity=Vector3.new(ANGULAR_FORCE,ANGULAR_FORCE,ANGULAR_FORCE)
        angular.MaxTorque=math.huge
        angular.ReactionTorqueEnabled=false
        angular.Parent=handle
        table.insert(self.RuntimeInstances,angular)

        for _,part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part~=handle then
                local constraint=Instance.new("NoCollisionConstraint")
                constraint.Name="ContactFlingNoCollision"
                constraint.Part0=handle
                constraint.Part1=part
                constraint.Parent=handle
                table.insert(self.RuntimeInstances,constraint)
            end
        end

        table.insert(self.PhysicsConnections,RunService.PreSimulation:Connect(function()
            if not self.Running or self.Handle~=handle or not handle.Parent or not root.Parent then return end
            handle.AssemblyAngularVelocity=Vector3.new(ANGULAR_FORCE,ANGULAR_FORCE,ANGULAR_FORCE)
            local expected=(root.CFrame*CFrame.new(HANDLE_OFFSET)).Position
            if (handle.Position-expected).Magnitude>5 then
                handle.CFrame=CFrame.new(expected)*root.CFrame.Rotation
            end
        end))
        table.insert(self.PhysicsConnections,RunService.Heartbeat:Connect(function()
            if not self.Running or self.Handle~=handle or not handle.Parent or not root.Parent then return end
            handle.AssemblyAngularVelocity=Vector3.new(ANGULAR_FORCE,ANGULAR_FORCE,ANGULAR_FORCE)
        end))
        table.insert(self.PhysicsConnections,RunService.PostSimulation:Connect(function()
            if not self.Running or self.Handle~=handle or not root.Parent then return end
            local velocity=root.AssemblyLinearVelocity
            if velocity.Magnitude<=SELF_RECOIL_LIMIT then
                self.SafeRootVelocity=velocity
            else
                -- El accesorio no debe transferir su propio retroceso al personaje local.
                root.AssemblyLinearVelocity=self.SafeRootVelocity
                root.AssemblyAngularVelocity=Vector3.zero
            end
        end))

        update((isES and "Activo con accesorio: " or "Active with accessory: ")..accessory.Name)
        return true
    end

    function C:Start()
        if self.Running then return true end
        local character=player.Character
        if not character then return false,isES and "Tu personaje no está disponible." or "Your character is unavailable." end
        self.Running=true
        if not self:_PrepareCharacter(character) then
            self.Running=false
            self:_ReleaseAccessory()
            return false,self.Status
        end
        return true
    end

    function C:Stop()
        if not self.Running and not self.Handle then return end
        self.Running=false
        self:_ReleaseAccessory()
        update(isES and "Fling por contacto desactivado" or "Contact Fling disabled")
    end

    function C:Destroy()
        self:Stop()
        disconnect(self.Connections)
    end

    table.insert(C.Connections,player.CharacterRemoving:Connect(function()
        C:_ReleaseAccessory()
    end))
    table.insert(C.Connections,player.CharacterAdded:Connect(function(character)
        if not C.Running then return end
        task.defer(function()
            character:WaitForChild("HumanoidRootPart",5)
            task.wait(1)
            if C.Running then
                if not C:_PrepareCharacter(character) then C.Running=false end
            end
        end)
    end))

    ContactFlingController=C
    return true
end