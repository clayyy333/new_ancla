-- Sigue solamente animaciones observables por este cliente.
return function(context)
    setfenv(1, context)
    local target, sourceTrack, sourceId, ownedTrack
    local pending, disposed = false, false
    local selectionVersion = 0
    local elapsed, missing, retryAt = 0, 0, 0
    local status = "Selecciona a un amigo del servidor."
    local connections = {}
    local basePlay, baseStop = PlayEmote, StopEmote
    local follow = {}
    LocalEmoteFollow = follow

    local function stopPlayback()
        if pending or (ownedTrack and currentAnimTrack == ownedTrack) then
            -- Cancelar tambien las cargas que aun no terminaron.
            _genv().lastVexroEmote = nil
            baseStop(false)
        end
        pending, ownedTrack, sourceTrack, sourceId = false, nil, nil, nil
    end
    function follow.Stop()
        selectionVersion += 1
        target = nil
        stopPlayback()
        status = "Seguimiento detenido."
    end
    function follow.GetTarget() return target end
    function follow.GetStatus() return status end
    function follow.Start(friend)
        if disposed or not friend or friend == player or friend.Parent ~= Players then return false end
        selectionVersion += 1
        local version = selectionVersion
        local ok, isFriend = pcall(function() return player:IsFriendsWith(friend.UserId) end)
        if version ~= selectionVersion then return false end
        if disposed or not ok or not isFriend or friend.Parent ~= Players then
            status = "No se pudo confirmar la amistad de Roblox."
            return false
        end
        follow.Stop()
        target = friend
        missing, retryAt = 0, 0
        status = "Esperando un emote visible de " .. friend.DisplayName .. "..."
        return true
    end

    local function visibleEmote(character)
        if not character then return nil end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        if not animator then return nil end
        local movement = {}
        local animate = character:FindFirstChild("Animate")
        if animate then
            for _, item in ipairs(animate:GetDescendants()) do
                if item:IsA("Animation") then
                    local id = item.AnimationId:match("%d+")
                    if id then movement[id] = true end
                end
            end
        end
        local best, bestId, priority = nil, nil, -1
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            local id = track.Animation and track.Animation.AnimationId:match("%d+")
            local value = track.Priority.Value
            if id and track.IsPlaying and not movement[id]
                and (EmotesById[tonumber(id)] or value >= Enum.AnimationPriority.Action.Value) then
                if value > priority or (value == priority and track == sourceTrack) then
                    best, bestId, priority = track, tonumber(id), value
                end
            end
        end
        return best, bestId
    end

    local function update(dt)
        if disposed or not target then return end
        if target.Parent ~= Players then follow.Stop(); status = "Tu amigo salio del servidor."; return end
        local track, id = visibleEmote(target.Character)
        if not track then
            missing += dt
            if missing >= 0.6 then stopPlayback() end
            status = "Esperando un emote visible de " .. target.DisplayName .. "..."
            return
        end
        missing = 0
        if track ~= sourceTrack or id ~= sourceId then
            stopPlayback()
            sourceTrack, sourceId = track, id
            retryAt = 0
        end
        if not ownedTrack and not pending and tick() >= retryAt then
            -- No confundir una pista manual anterior con el nuevo emote pendiente.
            baseStop(false)
            pending = true
            retryAt = tick() + 3
            local meta = EmotesById[id]
            local ok = pcall(basePlay, id, meta and meta.name or ("Emote " .. id), true)
            if not ok then pending = false end
        end
        if pending then
            local active = _genv().lastVexroEmote
            if currentAnimTrack and currentAnimTrack.IsPlaying and active and active.id == id then
                ownedTrack, pending = currentAnimTrack, false
            elseif tick() >= retryAt then
                _genv().lastVexroEmote = nil
                pending = false
                status = "No se pudo cargar el emote; reintentando..."
                return
            end
        end
        if ownedTrack and currentAnimTrack == ownedTrack then
            if not ownedTrack.IsPlaying then ownedTrack = nil; return end
            ownedTrack.Looped = track.Looped
            ownedTrack:AdjustSpeed(track.Speed)
            if ownedTrack.Length > 0 then
                local position = track.TimePosition
                if track.Looped then position %= ownedTrack.Length else position = math.min(position, ownedTrack.Length) end
                if math.abs(ownedTrack.TimePosition - position) > 0.15 then ownedTrack.TimePosition = position end
            end
            status = "Siguiendo a " .. target.DisplayName .. " (experimental)"
        end
    end

    -- La reproduccion manual siempre tiene prioridad.
    PlayEmote = function(...) follow.Stop(); return basePlay(...) end
    StopEmote = function(...) follow.Stop(); return baseStop(...) end
    local basePack, baseCombo = EquipAnimationPack, StartCombo
    EquipAnimationPack = function(...) follow.Stop(); return basePack(...) end
    StartCombo = function(...) follow.Stop(); return baseCombo(...) end
    connections[#connections + 1] = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 0.15 then return end
        local step = elapsed; elapsed = 0
        local ok = pcall(update, step)
        if not ok then status = "No se pudo leer la animacion de tu amigo." end
    end)
    connections[#connections + 1] = player.CharacterRemoving:Connect(function() follow.Stop() end)
    connections[#connections + 1] = Players.PlayerRemoving:Connect(function(leaving)
        if leaving == target then follow.Stop(); status = "Tu amigo salio del servidor." end
    end)
    function follow.Destroy()
        if disposed then return end
        disposed = true
        follow.Stop()
        for _, connection in ipairs(connections) do connection:Disconnect() end
    end
    connections[#connections + 1] = gui.Destroying:Connect(follow.Destroy)
    return true
end
