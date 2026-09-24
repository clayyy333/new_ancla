-- Fling pasivo por contacto, aislado de los motores de Fling 2.
return function(context)
    setfenv(1, context)
    local C={Running=false,Bursting=false,Generation=0,TouchConnections={},Connections={},LastContact=setmetatable({},{__mode="k"})}
    C.Status=isES and "Fling por contacto desactivado" or "Contact Fling disabled"
    local function update(text) C.Status=text or C.Status;if UpdateContactFlingPanel then UpdateContactFlingPanel(C.Status) end end
    local function disconnect(list) for _,v in ipairs(list) do pcall(function() v:Disconnect() end) end;table.clear(list) end
    local function getPlayer(part)
        local node=part
        while node and node~=workspace do
            if node:IsA("Model") then local p=Players:GetPlayerFromCharacter(node);if p then return p,node end end
            node=node.Parent
        end
    end
    local function getRoot(character)
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health<=0 or not root or not root:IsA("BasePart") then return nil end
        return root,humanoid
    end
    function C:_Burst(other,otherCharacter)
        if not self.Running or self.Bursting or other==player then return end
        local now=os.clock();if now-(self.LastContact[other] or 0)<0.8 then return end;self.LastContact[other]=now
        local root,humanoid=getRoot(player.Character);local targetRoot=getRoot(otherCharacter);if not root or not targetRoot then return end
        self.Bursting=true;self.Generation+=1
        local generation,checkpoint,autoRotate=self.Generation,root.CFrame,humanoid.AutoRotate
        humanoid.AutoRotate=false;update((isES and "Contacto con " or "Contact with ")..other.DisplayName)
        task.spawn(function()
            local started=os.clock()
            while self.Running and self.Generation==generation and os.clock()-started<0.16 do
                if not root.Parent or not targetRoot.Parent then break end
                local delta=targetRoot.Position-checkpoint.Position;local flat=Vector3.new(delta.X,0,delta.Z)
                local direction=flat.Magnitude>0.05 and flat.Unit or checkpoint.LookVector
                root.CFrame=CFrame.lookAt(checkpoint.Position,checkpoint.Position+direction)
                root.AssemblyAngularVelocity=Vector3.new(900000000,900000000,900000000)
                root.AssemblyLinearVelocity=direction*900000000+Vector3.new(0,900000000,0)
                RunService.Heartbeat:Wait()
            end
            if root.Parent then root.CFrame=checkpoint;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
            if humanoid.Parent then humanoid.AutoRotate=autoRotate end
            if self.Generation==generation then self.Bursting=false;update(isES and "Activo: esperando contacto" or "Active: waiting for contact") end
        end)
    end
    function C:_Bind(character)
        disconnect(self.TouchConnections);if not self.Running or not character then return end
        local function bind(part)
            if not part:IsA("BasePart") then return end
            table.insert(self.TouchConnections,part.Touched:Connect(function(hit) local other,model=getPlayer(hit);if other then self:_Burst(other,model) end end))
        end
        for _,part in ipairs(character:GetDescendants()) do bind(part) end
        table.insert(self.TouchConnections,character.DescendantAdded:Connect(bind))
    end
    function C:Start()
        if self.Running then return true end
        if not getRoot(player.Character) then return false,isES and "Tu personaje no está disponible." or "Your character is unavailable." end
        self.Running=true;self:_Bind(player.Character);update(isES and "Activo: esperando contacto" or "Active: waiting for contact");return true
    end
    function C:Stop()
        if not self.Running then return end
        self.Running=false;self.Bursting=false;self.Generation+=1;disconnect(self.TouchConnections)
        local root,humanoid=getRoot(player.Character);if root then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end;if humanoid then humanoid.AutoRotate=true end
        update(isES and "Fling por contacto desactivado" or "Contact Fling disabled")
    end
    function C:Destroy() self:Stop();disconnect(self.Connections) end
    table.insert(C.Connections,player.CharacterAdded:Connect(function(character) if C.Running then task.defer(function() C:_Bind(character) end) end end))
    table.insert(C.Connections,player.CharacterRemoving:Connect(function() disconnect(C.TouchConnections);C.Bursting=false;C.Generation+=1 end))
    ContactFlingController=C
    return true
end