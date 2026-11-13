-- Original V3 defense routines preserved; application UI and emote sequencing only.
return function(context)
 setfenv(1,context)
 local Players=game:GetService("Players")
 local RunService=game:GetService("RunService")
 local player=Players.LocalPlayer
local Core={Running=false,Starting=false,LastError=nil}
local alive = true
local defenseOn = false
local virtualSitOn = false

local connections = {}
local characterConnections = {}

local humanoid
local root
local character

local checkpoint
local original
local forceField

local lastSitRequest = 0
local sitRecoveries = 0
local seatDetections = 0
local positionCorrections = 0

local function connect(signal, callback, collection)
    local connection = signal:Connect(callback)
    table.insert(collection or connections, connection)
    return connection
end

local function disconnectAll(collection)
    for _, connection in ipairs(collection) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(collection)
end

local function clearForceField()
    if forceField then
        pcall(function()
            forceField:Destroy()
        end)
        forceField = nil
    end
end

local function restoreDefense()
    clearForceField()

    if original then
        local h = original.humanoid
        local r = original.root

        if h and h.Parent then
            pcall(function()
                h.BreakJointsOnDeath = original.breakJoints
                h.MaxHealth = original.maxHealth
                h:SetStateEnabled(
                    Enum.HumanoidStateType.Dead,
                    original.deadEnabled
                )

                if h.Health > 0 then
                    h.Health = math.min(
                        original.health,
                        original.maxHealth
                    )
                end
            end)
        end

        if r and r.Parent then
            pcall(function()
                r.AssemblyLinearVelocity = Vector3.zero
                r.AssemblyAngularVelocity = Vector3.zero
                r.Anchored = original.anchored
            end)
        end
    end

    original = nil
    checkpoint = nil
end

local function captureDefense()
    if not defenseOn or not humanoid or not root then
        return
    end

    restoreDefense()

    original = {
        humanoid = humanoid,
        root = root,
        anchored = root.Anchored,
        health = humanoid.Health,
        maxHealth = humanoid.MaxHealth,
        breakJoints = humanoid.BreakJointsOnDeath,
        deadEnabled = humanoid:GetStateEnabled(
            Enum.HumanoidStateType.Dead
        )
    }

    checkpoint = root.CFrame

    pcall(function()
        humanoid.BreakJointsOnDeath = false
        humanoid:SetStateEnabled(
            Enum.HumanoidStateType.Dead,
            false
        )

        humanoid.MaxHealth = math.huge

        if humanoid.Health > 0 then
            humanoid.Health = math.huge
        end
    end)

    forceField = Instance.new("ForceField")
    forceField.Name = "AnclaV3ForceField"
    forceField.Visible = false
    forceField.Parent = character

    pcall(function()
        root.Anchored = true
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function applyPhysicalDefense()
    if not defenseOn or not root or not checkpoint then
        return
    end

    if not root.Parent then return end

    pcall(function()
        if (root.Position - checkpoint.Position).Magnitude > 0.01 then
            positionCorrections += 1
        end

        root.Anchored = true
        root.CFrame = checkpoint
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
end

local function applyHumanoidDefense()
    if not defenseOn or not humanoid then
        return
    end

    if not humanoid.Parent then return end

    pcall(function()
        humanoid.BreakJointsOnDeath = false
        humanoid:SetStateEnabled(
            Enum.HumanoidStateType.Dead,
            false
        )

        if humanoid.Health > 0 then
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
        end
    end)
end

-- Evita llamadas recursivas a ChangeState.
local requestingSit = false

local function applyVirtualSit()
    if not virtualSitOn or not humanoid then
        return
    end

    if not humanoid.Parent or humanoid.Health <= 0 then
        return
    end

    pcall(function()
        humanoid.Sit = true
    end)

    if requestingSit then return end

    local state = humanoid:GetState()

    if state == Enum.HumanoidStateType.Seated then
        return
    end

    -- Límite corto para evitar bucles de estados.
    local now = os.clock()
    if now - lastSitRequest < 0.015 then
        return
    end

    lastSitRequest = now
    requestingSit = true

    local ok = pcall(function()
        humanoid:ChangeState(
            Enum.HumanoidStateType.Seated
        )
    end)

    requestingSit = false

    if ok then
        sitRecoveries += 1
    end
end

local function stopVirtualSit()
    if humanoid and humanoid.Parent and humanoid.Health > 0 then
        pcall(function()
            humanoid.Sit = false
            humanoid:ChangeState(
                Enum.HumanoidStateType.GettingUp
            )
        end)
    end
end

local function monitorSeat()
    if not humanoid or not humanoid.Parent then
        return
    end

    -- Detecta un asiento real; no destruye uniones
    -- indiscriminadamente.
    if humanoid.SeatPart then
        seatDetections += 1
    end
end

local function bindCharacter(newCharacter)
    disconnectAll(characterConnections)

    restoreDefense()

    character = newCharacter
    humanoid = nil
    root = nil

    local h = newCharacter:WaitForChild("Humanoid", 10)
    local r = newCharacter:WaitForChild("HumanoidRootPart", 10)

    if not alive or player.Character ~= newCharacter then
        return
    end

    if not h or not r then return end

    humanoid = h
    root = r
    lastSitRequest = 0
    requestingSit = false

    connect(h.StateChanged, function(oldState, newState)
        if not alive then return end

        if virtualSitOn
            and newState ~= Enum.HumanoidStateType.Seated then

            applyVirtualSit()
        end
    end, characterConnections)

    connect(h:GetPropertyChangedSignal("SeatPart"), function()
        if alive and h.SeatPart then
            seatDetections += 1
        end
    end, characterConnections)

    if defenseOn then
        captureDefense()
    end

    if virtualSitOn then
        applyVirtualSit()
    end
end


local defaultId=116197008542581
local generation=0
local emoteTrack,emoteAnimation
local function updateUI()
 Core.SitRecoveries=sitRecoveries;Core.SeatDetections=seatDetections;Core.PositionCorrections=positionCorrections
 if UpdateAnchorPanel then UpdateAnchorPanel()end
end
local function stopAnimation()
 if emoteTrack then pcall(function()emoteTrack:Stop(0);emoteTrack:Destroy()end);emoteTrack=nil end
 if emoteAnimation then emoteAnimation:Destroy();emoteAnimation=nil end
end
local function playAnimation(id,mine)
 local animationId="rbxassetid://"..tostring(id)
 local ok,objects=pcall(function()return game:GetObjects(animationId)end)
 if ok and type(objects)=="table"then
  for _,object in ipairs(objects)do
   local found=object:IsA("Animation")and object or object:FindFirstChildWhichIsA("Animation",true)
   if found and found.AnimationId~=""then animationId=found.AnimationId end
   object:Destroy()
  end
 end
 if mine~=generation or not alive or not humanoid or not humanoid.Parent then return false end
 local h=humanoid
 local animator=h:FindFirstChildOfClass("Animator")
 if not animator then animator=Instance.new("Animator");animator.Parent=h end
 local animation=Instance.new("Animation");animation.AnimationId=animationId
 local okLoad,track=pcall(function()return animator:LoadAnimation(animation)end)
 if not okLoad then animation:Destroy();error(track)end
 if mine~=generation or h~=humanoid or not alive then track:Destroy();animation:Destroy();return false end
 stopAnimation()
 emoteTrack=track;emoteAnimation=animation
 track.Priority=Enum.AnimationPriority.Action4;track.Looped=true
 track:Play(0)
 return true
end
local function orderedActivation(mine)
 if not playAnimation(defaultId,mine)then return end
 defenseOn=true
 captureDefense()
 virtualSitOn=true
 lastSitRequest=0
 applyVirtualSit()
 Core.Starting=false;Core.Running=true
 updateUI()
end
function Core:Start()
 if self.Running or self.Starting then return true end
 if not alive then return false,"Flujo cerrado."end
 generation=generation+1;local mine=generation
 if StopEmote then StopEmote(false)end
 self.Starting=true;self.LastError=nil;updateUI()
 task.spawn(function()
  local ok,err=pcall(function()
   local current=player.Character
   if not current then error("Personaje no disponible.")end
   if character~=current or not humanoid or not root then bindCharacter(current)end
   if mine~=generation then return end
   if not humanoid or not root then error("Personaje no disponible.")end
   orderedActivation(mine)
  end)
  if mine==generation and not ok then self.Starting=false;self.LastError=tostring(err);updateUI()end
 end)
 return true
end
function Core:ReplaceEmote(id)
 if not self.Running then return false end
 generation=generation+1;local mine=generation
 task.spawn(function()
  local ok,err=pcall(playAnimation,id,mine)
  if not ok and mine==generation then self.LastError=tostring(err);updateUI()end
 end)
 return true
end
function Core:Stop()
 generation=generation+1
 virtualSitOn=false
 stopVirtualSit()
 defenseOn=false
 restoreDefense()
 stopAnimation()
 self.Running=false;self.Starting=false;updateUI()
 return true
end
-- Original V3 physical phases, humanoid maintenance and seat diagnostics.
if RunService.PreSimulation then
 connect(RunService.PreSimulation,function()
  if not alive then return end
  applyPhysicalDefense()
  applyVirtualSit()
 end)
end
local uiElapsed,seatElapsed=0,0
connect(RunService.Heartbeat,function(dt)
 if not alive then return end
 applyPhysicalDefense()
 applyHumanoidDefense()
 applyVirtualSit()
 seatElapsed=seatElapsed+dt
 if seatElapsed>=0.25 then
  seatElapsed=0
  if defenseOn then monitorSeat()end
 end
 uiElapsed=uiElapsed+dt
 if uiElapsed>=0.25 then uiElapsed=0;updateUI()end
end)
connect(player.CharacterAdded,function(newCharacter)
 local enabled=Core.Running or Core.Starting
 if enabled then
  -- Reset only the per-character resources; keep the user's enabled intent.
  Core:Stop()
  Core.Starting=true
 end
 generation=generation+1;local mine=generation
 task.spawn(function()
  bindCharacter(newCharacter)
  if not alive or mine~=generation then return end
  if enabled then
   local ok,err=pcall(orderedActivation,mine)
   if not ok then Core.Starting=false;Core.LastError=tostring(err)end
  end
  updateUI()
 end)
end)
function Core:Destroy()
 if not alive then return true end
 self:Stop()
 alive=false
 disconnectAll(connections)
 disconnectAll(characterConnections)
 return true
end
NoSitAnchorCore=Core
return true
end
