-- Owner-only experiment: one selected Player, one physics writer, separated phases.
return function(context)
    setfenv(1,context)
    local core={Running=false,Phase="IDLE",Cycles=0,Recoveries=0,LastError=nil,Mode="CINTURA",SitKillEnabled=false,
        Config={Speed=10000,Distance=100,Azimuth=60,Elevation=0,ContactTime=.2,LaunchTime=.25,HitDuration=1.5}}
    ObjectV8FlingCore=core
    local connection,selected,character,humanoid,root,checkpoint
    local savedParts,savedHumanoid={},nil
    local targetCharacter,targetRoot,targetHumanoid
    local departure,incoming,previousPosition,previousTarget,flightDeadline
    local phaseStart,retryAt=0,0
    local sitStage,sitCharacter
    local nan=0/0
    local nanVector=Vector3.new(nan,nan,nan)
    local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
    local function valid(v)return v and finite(v.X)and finite(v.Y)and finite(v.Z)end
    local function dot(a,b)return a.X*b.X+a.Y*b.Y+a.Z*b.Z end
    local function refresh(message)if UpdateObjectFlingPanel then UpdateObjectFlingPanel(message)end end
    local function attempt(fn)
        local ok,err=pcall(fn)
        if not ok then core.LastError=tostring(err)end
        return ok
    end
    function core:IsAuthorized()
        return ExperimentalFlingCore and ExperimentalFlingCore:IsAuthorized()==true or false
    end
    local function zero()
        if root and root.Parent then
            attempt(function()root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end)
        end
    end
    local function restoreCharacter()
        zero()
        for part,values in pairs(savedParts)do
            if part.Parent then attempt(function()
                part.AssemblyLinearVelocity=Vector3.zero;part.AssemblyAngularVelocity=Vector3.zero
                part.CanCollide=values.CanCollide;part.Massless=values.Massless
            end)end
        end
        if humanoid and humanoid.Parent and savedHumanoid then attempt(function()
            humanoid.AutoRotate=savedHumanoid.AutoRotate;humanoid.PlatformStand=savedHumanoid.PlatformStand
        end)end
        if root and root.Parent and sethiddenproperty then attempt(function()sethiddenproperty(root,"PhysicsRepRootPart",nil)end)end
        savedParts={};savedHumanoid=nil
    end
    local function rememberParts()
        for _,part in ipairs(character:GetDescendants())do
            if part:IsA("BasePart")and not savedParts[part]then
                savedParts[part]={CanCollide=part.CanCollide,Massless=part.Massless}
            end
        end
    end
    local function bindCharacter(c,h,r)
        character,humanoid,root=c,h,r
        savedHumanoid={AutoRotate=h.AutoRotate,PlatformStand=h.PlatformStand}
        rememberParts();h.AutoRotate=false
    end
    local function clearHit()
        sitStage=nil;zero()
        if humanoid and humanoid.Parent and savedHumanoid then humanoid.PlatformStand=savedHumanoid.PlatformStand end
        for part,values in pairs(savedParts)do
            if part.Parent then part.CanCollide=values.CanCollide;part.Massless=values.Massless end
        end
        if root and root.Parent and sethiddenproperty then attempt(function()sethiddenproperty(root,"PhysicsRepRootPart",nil)end)end
    end
    local function waitFor(phase)
        if core.Phase~=phase then clearHit();core.Phase=phase;targetCharacter=nil;targetRoot=nil;targetHumanoid=nil;refresh()end
    end
    function core:SetParameter(name,value)
        local limits={Speed={0,1000000000},Distance={.5,2000000000},Azimuth={-360,360},Elevation={-90,90},ContactTime={.01,10},LaunchTime={.01,10},HitDuration={.05,10}}
        local range=limits[name]
        if not range or not finite(value)or value<range[1]or value>range[2]then return false end
        self.Config[name]=value;return true
    end
    function core:SetMode(value)
        if not self:IsAuthorized()or(value~="CINTURA"and value~="ROTACION"and value~="CLASICO")then return false end
        self.Mode=value;refresh();return true
    end
    function core:SetSitKillEnabled(value)
        if not self:IsAuthorized()then return false end
        self.SitKillEnabled=value==true
        if not self.SitKillEnabled then sitStage=nil end
        refresh();return true
    end
    function core:GetTarget()return selected end
    function core:SetTarget(value)
        if not self:IsAuthorized()or not value or value==player or value.Parent~=Players then return false end
        clearHit();selected=value;self.Phase=self.Running and "WAIT_TARGET"or"IDLE"
        targetCharacter=nil;targetRoot=nil;targetHumanoid=nil;sitCharacter=nil
        refresh();return true
    end
    function core:Stop(message)
        local running=self.Running;self.Running=false;self.Phase="IDLE"
        if connection then connection:Disconnect();connection=nil end
        restoreCharacter()
        if running and root and root.Parent and humanoid and humanoid.Health>0 and player.Character==character and checkpoint then
            root.CFrame=checkpoint;zero()
        end
        targetCharacter=nil;targetRoot=nil;targetHumanoid=nil;sitStage=nil;sitCharacter=nil
        if running then refresh(message or "Fling test detenido; regreso al checkpoint.")end
        return running
    end
    local function beginDeparture(tr,th,now)
        clearHit();core.Cycles=core.Cycles+1
        targetCharacter=selected.Character;targetRoot=tr;targetHumanoid=th
        local look=tr.CFrame.LookVector
        local forward=Vector3.new(look.X,0,look.Z)
        forward=forward.Magnitude>.001 and forward.Unit or Vector3.new(0,0,-1)
        local right=Vector3.new(-forward.Z,0,forward.X)
        local az,el=math.rad(core.Config.Azimuth),math.rad(core.Config.Elevation)
        local direction=((forward*math.cos(az)+right*math.sin(az))*math.cos(el)+Vector3.new(0,math.sin(el),0)).Unit
        departure=tr.Position+direction*core.Config.Distance;incoming=direction*(-1)
        root.CFrame=CFrame.new(departure);phaseStart=now;core.Phase="PREPARE"
    end
    -- These are local attempts, not evidence of server-authorized damage or ownership.
    local function sitAttempt()
        if not core.SitKillEnabled or sitCharacter==targetCharacter or sitStage then return end
        sitCharacter=targetCharacter;sitStage=1
        for _,part in ipairs(targetCharacter:GetDescendants())do
            if part:IsA("BasePart")then attempt(function()part.Anchored=false;part.CanCollide=false;part.Massless=true end)end
        end
        attempt(function()targetHumanoid.Sit=false;targetHumanoid.PlatformStand=true end)
        attempt(function()targetRoot.CFrame=root.CFrame*CFrame.new(0,1.5,-3)end)
        attempt(function()targetRoot.AssemblyLinearVelocity=Vector3.zero;targetRoot.AssemblyAngularVelocity=Vector3.zero end)
        attempt(function()targetHumanoid.Sit=true;targetHumanoid:ChangeState(Enum.HumanoidStateType.Seated)end)
    end
    local function advanceSit()
        if not sitStage then return end
        if sitStage==1 then
            sitStage=2
            attempt(function()targetHumanoid.Sit=false;targetHumanoid:ChangeState(Enum.HumanoidStateType.GettingUp)end)
        else
            sitStage=nil
            attempt(function()targetRoot.CFrame=CFrame.new(targetRoot.Position.X,-8000,targetRoot.Position.Z)end)
            attempt(function()targetRoot.AssemblyLinearVelocity=Vector3.new(0,-50000,0);targetRoot.AssemblyAngularVelocity=Vector3.new(99999,99999,99999)end)
            attempt(function()targetHumanoid.Health=0;targetHumanoid:TakeDamage(999999);targetHumanoid:ChangeState(Enum.HumanoidStateType.Dead)end)
            for _,part in ipairs(targetCharacter:GetDescendants())do
                if part:IsA("BasePart")then attempt(function()part.CFrame=CFrame.new(part.Position.X,-8000,part.Position.Z)end)end
            end
        end
    end
    local function hit()
        if core.Mode=="ROTACION"then
            root.CFrame=CFrame.new(targetRoot.Position)*CFrame.Angles(math.rad(math.random(-180,180)),math.rad(math.random(-180,180)),math.rad(math.random(-180,180)))
            root.AssemblyLinearVelocity=Vector3.new(math.random(-20000,20000),math.random(-20000,20000),math.random(-20000,20000))
            root.AssemblyAngularVelocity=Vector3.new(math.random(100000,200000),math.random(100000,200000),math.random(100000,200000))
        else
            root.CFrame=CFrame.new(targetRoot.Position+(core.Mode=="CLASICO"and Vector3.new(0,1,0)or Vector3.zero))
                *CFrame.Angles(core.Mode=="CINTURA"and -math.pi/2 or 0,0,0)
            attempt(function()root.AssemblyLinearVelocity=nanVector end)
            attempt(function()root.AssemblyAngularVelocity=nanVector end)
            attempt(function()targetHumanoid:Move(nanVector)end)
            if sethiddenproperty then
                attempt(function()sethiddenproperty(humanoid,"MoveDirectionInternal",nanVector)end)
                if core.Mode=="CINTURA"then attempt(function()sethiddenproperty(targetHumanoid,"MoveDirectionInternal",nanVector)end)end
            end
        end
        if sethiddenproperty then attempt(function()sethiddenproperty(root,"PhysicsRepRootPart",targetRoot)end)end
        attempt(function()targetHumanoid.Sit=false;targetHumanoid.PlatformStand=true end)
    end
    local function beginHit(now)
        zero();rememberParts()
        humanoid.PlatformStand=true
        for part in pairs(savedParts)do if part.Parent then part.CanCollide=false;part.Massless=true end end
        root.CanCollide=true
        phaseStart=now;core.Phase="HIT";sitAttempt();hit()
    end
    local function step()
        if not core:IsAuthorized()then core:Stop("Prueba exclusiva para owners.");return end
        if not selected or selected.Parent~=Players then core:Stop("El jugador seleccionado salio.");return end
        local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
        if not r or not h or h.Health<=0 then waitFor("WAIT_LOCAL");return end
        if c~=character or r~=root then restoreCharacter();bindCharacter(c,h,r);targetCharacter=nil;core.Phase="WAIT_TARGET"end
        local tc=selected.Character;local tr=tc and tc:FindFirstChild("HumanoidRootPart");local th=tc and tc:FindFirstChildOfClass("Humanoid")
        if not tr or not th or not valid(tr.Position)then waitFor("WAIT_TARGET");return end
        local now=os.clock();if now<retryAt then return end
        if tc~=targetCharacter or tr~=targetRoot or th~=targetHumanoid or core.Phase=="WAIT_TARGET"or core.Phase=="WAIT_LOCAL"or core.Phase=="RECOVERING"then beginDeparture(tr,th,now)end
        local cfg=core.Config
        if core.Phase=="HIT"then
            if now-phaseStart>=cfg.HitDuration then beginDeparture(tr,th,now)
            else advanceSit();hit()end
        elseif not valid(r.Position)then
            core.Recoveries=core.Recoveries+1;beginDeparture(tr,th,now)
        elseif core.Phase=="PREPARE"then
            r.CFrame=CFrame.new(departure);zero()
            if now-phaseStart>=cfg.ContactTime then
                local offset=tr.Position-r.Position
                if offset.Magnitude<=.5 then beginHit(now);return end
                incoming=offset.Unit;previousPosition=r.Position;previousTarget=tr.Position
                flightDeadline=now+offset.Magnitude/math.max(cfg.Speed,1)+cfg.LaunchTime
                r.AssemblyLinearVelocity=incoming*cfg.Speed;phaseStart=now;core.Phase="INBOUND"
            end
        elseif core.Phase=="INBOUND"then
            local before=previousPosition-previousTarget;local after=r.Position-tr.Position;local segment=after-before
            local length=dot(segment,segment);local t=length>0 and math.max(0,math.min(1,-dot(before,segment)/length))or 0
            if after.Magnitude<=.5 or((before+segment*t).Magnitude<=.5 and dot(after,incoming)>=0)then beginHit(now);return end
            if now>=flightDeadline then core.Recoveries=core.Recoveries+1;beginDeparture(tr,th,now);return end
            local offset=tr.Position-r.Position;if offset.Magnitude>.001 then incoming=offset.Unit end
            r.AssemblyLinearVelocity=incoming*cfg.Speed;r.AssemblyAngularVelocity=Vector3.zero
            previousPosition=r.Position;previousTarget=tr.Position
        else beginDeparture(tr,th,now)end
    end
    function core:Start(value)
        if not self:IsAuthorized()then return false,"Prueba exclusiva para owners."end
        if V8PersistentFlingCore and V8PersistentFlingCore.Running then return false,"Desactiva el otro V8 persistente primero."end
        if self.Running then return self:SetTarget(value)end
        if not value or value==player or value.Parent~=Players then return false,"Selecciona un jugador."end
        local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid");local r=c and c:FindFirstChild("HumanoidRootPart")
        if not r or not h or h.Health<=0 or not valid(r.Position)then return false,"Tu personaje no esta disponible."end
        checkpoint=r.CFrame;bindCharacter(c,h,r);selected=value
        self.Running=true;self.Phase="WAIT_TARGET";self.Cycles=0;self.Recoveries=0;self.LastError=nil;retryAt=0;sitCharacter=nil
        local function protectedStep()
            local ok,err=xpcall(step,debug.traceback)
            if not ok then
                self.LastError=tostring(err);self.Recoveries=self.Recoveries+1
                clearHit();self.Phase="RECOVERING";targetCharacter=nil;targetRoot=nil;retryAt=os.clock()+.1
                refresh("Recuperando referencias del objetivo.")
            end
        end
        connection=RunService.Heartbeat:Connect(protectedStep);protectedStep();refresh();return true
    end
    function core:Destroy()self:Stop()end
    return true
end
