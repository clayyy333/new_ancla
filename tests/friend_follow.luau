do
    local function signal()
        local listeners = {}
        return {
            Connect = function(_, callback)
                local connection = {active = true}
                function connection:Disconnect() self.active = false end
                table.insert(listeners, {callback, connection})
                return connection
            end,
            Fire = function(_, ...)
                for _, item in ipairs(listeners) do if item[2].active then item[1](...) end end
            end,
        }
    end
    local d = setmetatable({}, {__index = getfenv()})
    local now, loads = 0, 0
    local globals = {}
    d._genv = function() return globals end
    d.tick = function() return now end
    d.EmotesById = {}
    d.Enum = {AnimationPriority = {Action = {Value = 2}}}
    d.Players = {PlayerRemoving = signal()}
    d.player = {CharacterRemoving = signal(), IsFriendsWith = function(_, id) return id == 2 end}
    d.gui = {Destroying = signal()}
    d.RunService = {Heartbeat = signal()}
    local delayed = false
    d.PlayEmote = function(id)
        loads += 1
        globals.lastVexroEmote = {id = id}
        if delayed then return end
        d.currentAnimTrack = {IsPlaying = true, Length = 10, TimePosition = 0,
            AdjustSpeed = function(self, value) self.Speed = value end}
    end
    d.StopEmote = function()
        if d.currentAnimTrack then d.currentAnimTrack.IsPlaying = false end
        d.currentAnimTrack = nil
    end
    d.EquipAnimationPack = function() end
    d.StartCombo = function() end
    local tracks, movement = {}, {}
    local remoteAnimator = {GetPlayingAnimationTracks = function() return tracks end}
    local remoteHumanoid = {FindFirstChildOfClass = function() return remoteAnimator end}
    local character = {
        FindFirstChildOfClass = function() return remoteHumanoid end,
        FindFirstChild = function() return {GetDescendants = function() return movement end} end,
    }
    local friend = {UserId = 2, DisplayName = "Friend", Parent = d.Players, Character = character}
    local function track(id)
        return {Animation = {AnimationId = "rbxassetid://" .. id}, Priority = {Value = 4},
            IsPlaying = true, Looped = true, Speed = 0.5, TimePosition = 3}
    end
    local function step(dt) now += dt; d.RunService.Heartbeat:Fire(dt) end
    assert(loadModule("player/friend_follow")(d))
    local follow = d.LocalEmoteFollow
    assert(not follow.Start({UserId = 3, Parent = d.Players}))
    assert(follow.Start(friend))
    tracks = {track(101)}; step(0.2)
    assert(loads == 1 and d.currentAnimTrack.TimePosition == 3 and d.currentAnimTrack.Speed == 0.5)
    local first = d.currentAnimTrack
    tracks[1].Speed = 0; tracks[1].TimePosition = 4; step(0.2)
    assert(loads == 1 and d.currentAnimTrack == first and first.Speed == 0 and first.TimePosition == 4)
    tracks = {track(102)}; step(0.2)
    assert(loads == 2 and not first.IsPlaying and d.currentAnimTrack ~= first)
    tracks = {}; step(0.7)
    assert(not d.currentAnimTrack and follow.GetTarget() == friend)
    tracks = {track(103)}; step(0.2)
    assert(d.currentAnimTrack and loads == 3)
    d.PlayEmote(200)
    assert(follow.GetTarget() == nil and globals.lastVexroEmote.id == 200)
    follow.Start(friend); step(0.2)
    d.Players.PlayerRemoving:Fire(friend)
    assert(not follow.GetTarget() and not d.currentAnimTrack)
    -- Los movimientos del personaje no se copian, aunque el ID exista en el catalogo.
    movement = {{AnimationId = "rbxassetid://103", IsA = function() return true end}}
    d.EmotesById[103] = {name = "Movement"}
    follow.Start(friend); local previousLoads = loads; step(0.7)
    assert(loads == previousLoads and not d.currentAnimTrack)
    movement = {}; delayed = true; step(0.2)
    assert(globals.lastVexroEmote)
    follow.Stop()
    assert(globals.lastVexroEmote == nil)
    delayed = false
    follow.Start(friend); step(0.2)
    d.player.CharacterRemoving:Fire()
    assert(not follow.GetTarget() and not d.currentAnimTrack)
    follow.Start(friend); step(0.2)
    d.gui.Destroying:Fire()
    previousLoads = loads; step(1)
    assert(not follow.GetTarget() and not d.currentAnimTrack and loads == previousLoads)
    assert(not follow.Start(friend))
    print("PASS: experimental following, phase/speed, source changes, manual override, friends-only, movement exclusion, cancellation and cleanup")
end
