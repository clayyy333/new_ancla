-- Refuerzo de replicación exclusivamente para Xeno.
-- Observa los motores existentes; no controla targets, CFrames ni sus ciclos Start/Stop.
return function(context)
    setfenv(1,context)

    local RunServiceDirect=game:GetService("RunService")
    local PlayersDirect=game:GetService("Players")
    local LP=PlayersDirect.LocalPlayer
    local ENV=getgenv()

    local function executorName()
        local ok,name=pcall(function()
            if type(identifyexecutor)=="function" then return identifyexecutor() end
            if type(getexecutorname)=="function" then return getexecutorname() end
            return ""
        end)
        return ok and string.lower(tostring(name or "")) or ""
    end

    local Core={
        Enabled=string.find(executorName(),"xeno",1,true)~=nil,
        Connection=nil,
        LastRadiusRefresh=0,
    }

    local function disconnectPrevious()
        local old=ENV.__VR7_XENO_FLING_ASSIST_CLEANUP
        if type(old)=="function" then pcall(old) end
    end
    disconnectPrevious()

    local function wake(part)
        if not part or not part.Parent or not part:IsA("BasePart") or part.Anchored then return end
        pcall(function()
            if type(sethiddenproperty)=="function" then
                sethiddenproperty(part,"NetworkIsSleeping",false)
            end
        end)
    end

    local function mirrorVelocity(part)
        if not part or not part.Parent or not part:IsA("BasePart") or part.Anchored then return end
        wake(part)

        local linear=part.AssemblyLinearVelocity
        local angular=part.AssemblyAngularVelocity
        if linear.Magnitude>1000 then
            pcall(function() part.Velocity=linear end)
        end
        if angular.Magnitude>1000 then
            pcall(function() part.RotVelocity=angular end)
        end
    end

    local function refreshSimulationRadius()
        local now=os.clock()
        if now-Core.LastRadiusRefresh<0.5 then return end
        Core.LastRadiusRefresh=now

        pcall(function()
            if type(setsimulationradius)=="function" then
                setsimulationradius(math.huge,math.huge)
            end
        end)
        pcall(function()
            if type(sethiddenproperty)=="function" then
                sethiddenproperty(LP,"SimulationRadius",math.huge)
                sethiddenproperty(LP,"MaximumSimulationRadius",math.huge)
            end
        end)
    end

    local function activeCharacterFling()
        return (Fling2Core and Fling2Core.Running)
            or (Fling2EfficientCore and Fling2EfficientCore.Running)
    end

    local function reinforceCharacter()
        if not activeCharacterFling() then return false end
        local character=LP.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if root then mirrorVelocity(root) end
        return root~=nil
    end

    local function reinforceVehicle(engine)
        if not engine or not engine.Running or type(engine.GetCar)~="function" then return false end
        local vehicle=engine:GetCar()
        if not vehicle or not vehicle.Parent then return false end

        if vehicle:IsA("BasePart") then
            mirrorVelocity(vehicle)
            return true
        end

        for _,part in ipairs(vehicle:GetDescendants()) do
            if part:IsA("BasePart") and not part.Anchored then
                mirrorVelocity(part)
            end
        end
        return true
    end

    local function onPostSimulation()
        if not Core.Enabled then return end

        local active=reinforceCharacter()
        active=reinforceVehicle(CarFlingXeno) or active
        active=reinforceVehicle(CarFling2Xeno) or active

        if active then refreshSimulationRadius() end
    end

    function Core:Destroy()
        if self.Connection then
            pcall(function() self.Connection:Disconnect() end)
            self.Connection=nil
        end
        if ENV.__VR7_XENO_FLING_ASSIST_CLEANUP then
            ENV.__VR7_XENO_FLING_ASSIST_CLEANUP=nil
        end
    end

    if Core.Enabled then
        Core.Connection=RunServiceDirect.PostSimulation:Connect(onPostSimulation)
    end

    ENV.__VR7_XENO_FLING_ASSIST_CLEANUP=function() Core:Destroy() end
    XenoFlingReplicationAssist=Core
    return true
end
