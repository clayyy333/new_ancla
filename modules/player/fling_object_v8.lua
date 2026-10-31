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
    local diagnostic={}
    local function number(n)return type(n)=="number"and string.format("%.3f",n)or tostring(n)end
    local function vector(v)
        if not v then return "nil"end
        return "("..number(v.X)..","..number(v.Y)..","..number(v.Z)..")"
    end
    local function snapshot()
        local ok,value=pcall(function()
            local tc=selected and selected.Character
            local tr=tc and tc:FindFirstChild("HumanoidRootPart")
            local th=tc and tc:FindFirstChildOfClass("Humanoid")
            local distance=root and tr and valid(root.Position)and valid(tr.Position)and(root.Position-tr.Position).Magnitude
            return "phase="..core.Phase.." mode="..core.Mode.." cycle="..core.Cycles
                .." localHealth="..number(humanoid and humanoid.Health).." targetHealth="..number(th and th.Health)
                .." localPos="..vector(root and root.Position).." targetPos="..vector(tr and tr.Position)
                .." distance="..number(distance).." linear="..vector(root and root.AssemblyLinearVelocity)
                .." angular="..vector(root and root.AssemblyAngularVelocity)
                .." anchored="..tostring(root and root.Anchored).." localSit="..tostring(humanoid and humanoid.Sit)
                .." targetSit="..tostring(th and th.Sit).." localSeat="..tostring(humanoid and humanoid.SeatPart)
                .." targetSeat="..tostring(th and th.SeatPart).." localRigCurrent="..tostring(player.Character==character).." sitStage="..tostring(sitStage)
        end)
        return ok and value or "snapshot unavailable: "..tostring(value)
    end
    function core:ClearDiagnostic()
        diagnostic={Started=os.clock(),Events={},First={},Count=0,Operations={},HitFrames=0,HitEntries=0,LastSample=-math.huge}
        self.Diagnostic=diagnostic
    end
    core:ClearDiagnostic()
    local function record(event,detail)
        diagnostic.Count=diagnostic.Count+1
        local entry=string.format("t=%.3f %s %s",os.clock()-diagnostic.Started,event,detail or snapshot())
        if #diagnostic.First<12 then diagnostic.First[#diagnostic.First+1]=entry end
        diagnostic.Events[(diagnostic.Count-1)%128+1]=entry
    end
    local function observe()
        local changed=diagnostic.LastPhase~=core.Phase
        if changed then diagnostic.LastPhase=core.Phase;record("PHASE")end
        if os.clock()-diagnostic.LastSample>=.2 then
            diagnostic.LastSample=os.clock()
            if not changed then record("SAMPLE")end
        end
    end
    function core:GetDiagnosticReport()
        local lines={"FLING TEST DIAGNOSTIC V1 | Local observations; no server acceptance or cause of death proven",
            "Running="..tostring(self.Running).." OwnerAuthorized="..tostring(self:IsAuthorized()).." Phase="..self.Phase,
            "Local="..tostring(player.Name).."/"..tostring(player.UserId).." Target="..tostring(selected and selected.Name).."/"..tostring(selected and selected.UserId),
            "Mode="..self.Mode.." SitKillEnabled="..tostring(self.SitKillEnabled).." HitEntries="..diagnostic.HitEntries.." HitFrames="..diagnostic.HitFrames,
            "Cycles="..self.Cycles.." Recoveries="..self.Recoveries.." Events="..diagnostic.Count.." LastError="..tostring(self.LastError),
            "A successful pcall only means no local API error. This report performs no physics writes.","CURRENT:",snapshot(),"CONFIG:"}
        for _,key in ipairs({"Speed","Distance","Azimuth","Elevation","ContactTime","LaunchTime","HitDuration"})do lines[#lines+1]=key.."="..tostring(self.Config[key])end
        lines[#lines+1]="OPERATIONS (attempted / no local error / failed):"
        local names={};for name in pairs(diagnostic.Operations)do names[#names+1]=name end;table.sort(names)
        for _,name in ipairs(names)do
            local op=diagnostic.Operations[name]
            lines[#lines+1]=name.." "..op.Attempts.." / "..op.Successes.." / "..op.Failures.." lastError="..tostring(op.LastError)
        end
        lines[#lines+1]="FIRST EVENTS:"
        for _,entry in ipairs(diagnostic.First)do lines[#lines+1]=entry end
        lines[#lines+1]="LATEST EVENTS (up to 128):"
        for index=math.max(1,diagnostic.Count-127),diagnostic.Count do lines[#lines+1]=diagnostic.Events[(index-1)%128+1]end
        return table.concat(lines,"\n")
    end
    local function attempt(fn,label)
        label=label or "other_local_write"
        local op=diagnostic.Operations[label]
        if not op then op={Attempts=0,Successes=0,Failures=0};diagnostic.Operations[label]=op end
        op.Attempts=op.Attempts+1
        local ok,err=pcall(fn)
        if ok then op.Successes=op.Successes+1
        else
            op.Failures=op.Failures+1;core.LastError=tostring(err)
            if op.LastError~=tostring(err)then record("WRITE_ERROR",label..": "..tostring(err))end
            op.LastError=tostring(err)
        end
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
        self.Mode=value;record("MODE_CHANGED");refresh();return true
    end
    function core:SetSitKillEnabled(value)
        if not self:IsAuthorized()then return false end
        self.SitKillEnabled=value==true
        record("SIT_OPTION",tostring(self.SitKillEnabled))
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
        if running then record("STOP",snapshot().." reason="..tostring(message));refresh(message or "Fling test detenido; regreso al checkpoint.")end
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
        sitCharacter=targetCharacter;sitStage=1;record("SIT_LOCAL_ATTEMPT")
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
            sitStage=nil;record("SIT_LOCAL_FINAL_STAGE")
            attempt(function()targetRoot.CFrame=CFrame.new(targetRoot.Position.X,-8000,targetRoot.Position.Z)end)
            attempt(function()targetRoot.AssemblyLinearVelocity=Vector3.new(0,-50000,0);targetRoot.AssemblyAngularVelocity=Vector3.new(99999,99999,99999)end)
            attempt(function()targetHumanoid.Health=0;targetHumanoid:TakeDamage(999999);targetHumanoid:ChangeState(Enum.HumanoidStateType.Dead)end)
            for _,part in ipairs(targetCharacter:GetDescendants())do
                if part:IsA("BasePart")then attempt(function()part.CFrame=CFrame.new(part.Position.X,-8000,part.Position.Z)end)end
            end
        end
    end
    local function hit()
        diagnostic.HitFrames=diagnostic.HitFrames+1
        if core.Mode=="ROTACION"then
            root.CFrame=CFrame.new(targetRoot.Position)*CFrame.Angles(math.rad(math.random(-180,180)),math.rad(math.random(-180,180)),math.rad(math.random(-180,180)))
            root.AssemblyLinearVelocity=Vector3.new(math.random(-20000,20000),math.random(-20000,20000),math.random(-20000,20000))
            root.AssemblyAngularVelocity=Vector3.new(math.random(100000,200000),math.random(100000,200000),math.random(100000,200000))
        else
            root.CFrame=CFrame.new(targetRoot.Position+(core.Mode=="CLASICO"and Vector3.new(0,1,0)or Vector3.zero))
                *CFrame.Angles(core.Mode=="CINTURA"and -math.pi/2 or 0,0,0)
            attempt(function()root.AssemblyLinearVelocity=nanVector end,"local_linear_NaN")
            attempt(function()root.AssemblyAngularVelocity=nanVector end,"local_angular_NaN")
            attempt(function()targetHumanoid:Move(nanVector)end,"target_move_NaN")
            if sethiddenproperty then
                attempt(function()sethiddenproperty(humanoid,"MoveDirectionInternal",nanVector)end,"local_hidden_direction")
                if core.Mode=="CINTURA"then attempt(function()sethiddenproperty(targetHumanoid,"MoveDirectionInternal",nanVector)end,"target_hidden_direction")end
            end
        end
        if sethiddenproperty then attempt(function()sethiddenproperty(root,"PhysicsRepRootPart",targetRoot)end,"local_replication_root")end
        attempt(function()targetHumanoid.Sit=false;targetHumanoid.PlatformStand=true end)
    end
    local function beginHit(now)
        zero();rememberParts()
        humanoid.PlatformStand=true
        for part in pairs(savedParts)do if part.Parent then part.CanCollide=false;part.Massless=true end end
        root.CanCollide=true
        phaseStart=now;core.Phase="HIT";diagnostic.HitEntries=diagnostic.HitEntries+1
        record("HIT_ENTER");sitAttempt();hit()
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
            if now-phaseStart>=cfg.HitDuration then record("HIT_EXIT","duration="..number(now-phaseStart).." "..snapshot());beginDeparture(tr,th,now)
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
        self:ClearDiagnostic()
        checkpoint=r.CFrame;bindCharacter(c,h,r);selected=value
        self.Running=true;self.Phase="WAIT_TARGET";self.Cycles=0;self.Recoveries=0;self.LastError=nil;retryAt=0;sitCharacter=nil
        record("START")
        local function protectedStep()
            local ok,err=xpcall(step,debug.traceback)
            if not ok then
                self.LastError=tostring(err);self.Recoveries=self.Recoveries+1
                clearHit();self.Phase="RECOVERING";targetCharacter=nil;targetRoot=nil;retryAt=os.clock()+.1
                record("STEP_ERROR",tostring(err))
                refresh("Recuperando referencias del objetivo.")
            end
            observe()
        end
        connection=RunService.Heartbeat:Connect(protectedStep);protectedStep();refresh();return true
    end
    function core:Destroy()self:Stop()end
    return true
end
