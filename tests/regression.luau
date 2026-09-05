-- Regresiones de modulos con almacenamiento y objetos Roblox simulados.
local host = getfenv()
local manifest = loadModule("manifest")
local declared = {}
for _, name in ipairs(manifest.sharedNames) do declared[name] = true end
local function context()
    return setmetatable({}, {__index = function(_, key)
        if declared[key] then return nil end
        return host[key]
    end})
end
local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}; for k, v in pairs(value) do result[k] = clone(v) end
    return result
end
local files = {}
local globals = {}
local c = context()
c.player = {UserId = 123}
c._genv = function() return globals end
c.debugLog = function() end
c.Notify = function() end
c.L = {playing = "Playing", stopped = "Stopped", favLimit = "Limit"}
c.HttpService = {
    JSONEncode = function(_, value) return clone(value) end,
    JSONDecode = function(_, value) return clone(value) end,
}
c.writefile = function(path, value) files[path] = value end
c.readfile = function(path) return files[path] end
c.isfile = function(path) return files[path] ~= nil end
assert(loadModule("core/storage")(c))
assert(loadModule("core/favorites")(c))
assert(c.ToggleFavorite(100))
assert(c.ToggleFavorite(200))
assert(not c.ToggleFavorite(100))
c.SetKeybind(200, "Point", "P")
c.Settings.copyEmoteEnabled = true
c.Settings.searchHistory = {"dance"}
c.SaveData()
c.Favorites = {}; c.FavoritesSet = {}; c.Keybinds = {}; c.KeybindsSet = {}
c.Settings.copyEmoteEnabled = false; c.Settings.searchHistory = {}
c.LoadData()
assert(#c.Favorites == 1 and c.IsFavorite(200) and not c.IsFavorite(100))
assert(c.GetKeybind(200).key == "P")
assert(c.Settings.copyEmoteEnabled and c.Settings.searchHistory[1] == "dance")
for id = 1, 25 do c.AddToRecent(id) end
c.AddToRecent(20)
c.RecentEmotes = {}; c.LoadData()
assert(#c.RecentEmotes == 20 and c.RecentEmotes[1] == 20)
local seen = {}; for _, id in ipairs(c.RecentEmotes) do assert(not seen[id]); seen[id] = true end
assert(not c.ToggleFavorite("invalid"))

local callbacks = {}
local heartbeat = {Connect = function(_, callback)
    callbacks.heartbeat = callback
    return {Disconnect = function() end}
end}
local tracks = {}
local animator = {}
function animator:GetPlayingAnimationTracks()
    local active = {}; for _, t in ipairs(tracks) do if t.IsPlaying then table.insert(active, t) end end
    return active
end
function animator:LoadAnimation(animation)
    local track = {Animation = animation, Length = 10, TimePosition = 0, Speed = 1}
    function track:Play(fade) self.IsPlaying = true; self.fade = fade end
    function track:Stop() self.IsPlaying = false end
    function track:AdjustSpeed(speed) self.Speed = speed end
    track.Stopped = {Connect = function() return {Disconnect = function() end} end}
    table.insert(tracks, track)
    return track
end
local humanoid = {MoveDirection = {Magnitude = 0}}
function humanoid:FindFirstChildOfClass(name) if name == "Animator" then return animator end end
local character = {}
function character:FindFirstChildOfClass(name) if name == "Humanoid" then return humanoid end end
c.player.Character = character
c.RunService = {Heartbeat = heartbeat}
c.Enum = {AnimationPriority = {Action4 = 4}}
c.task = {
    spawn = function(fn) fn() end,
    defer = function(fn) fn() end,
    delay = function(_, fn) fn() end,
    wait = function(seconds) return seconds or 0.01 end,
}
c.tick = function() return 100 end
c.workspace = {GetServerTimeNow = function() return 100 end}
local function animation(id, name)
    return {AnimationId = "rbxassetid://" .. id, Name = name or "Dance",
        IsA = function(_, kind) return kind == "Animation" end,
        GetChildren = function() return {} end}
end
c.game = {GetObjects = function(_, uri) return {animation(uri:match("%d+"))} end}
c.Instance = {new = function() return animation(0) end}
c.SafeUtf8Char = function() return "error" end
assert(loadModule("player/emotes")(c))
c.Settings.speed = 1.5
c.PlayEmote(300, "Dance", true)
local first = c.currentAnimTrack
assert(first.IsPlaying and first.Priority == 4 and first.Looped)
assert(first.Speed == 1.5 and first.Animation.AnimationId == "rbxassetid://300")
assert(c.RecentEmotes[1] == 300)
c.PlayEmote(301, "Dance 2", true, 98)
assert(not first.IsPlaying and c.currentAnimTrack.TimePosition == 3)
c.Settings.speed = 0.5; c.ApplySpeedToAllTracks()
assert(c.currentAnimTrack.Speed == 0.5)
humanoid.MoveDirection.Magnitude = 1; callbacks.heartbeat()
assert(c.currentAnimTrack == nil)
humanoid.MoveDirection.Magnitude = 0

-- El modulo de HUD debe envolver la misma funcion que usan las tarjetas.
local shown, hidden = 0, 0
c.ShowEmoteHUD = function() shown += 1 end
c.HideEmoteHUD = function() hidden += 1 end
c._hudHideToken = 0
c.AnimationPacks = {{id = "anim_test"}}
local equipped
c.EquipAnimationPack = function(pack) equipped = pack end
assert(loadModule("player/hud_integration")(c))
c.PlayEmote(302, "HUD", true)
assert(shown == 1 and c.currentAnimTrack.IsPlaying)
c.PlayEmote("anim_test", "Pack")
assert(equipped == c.AnimationPacks[1])
c.StopEmote(false)
assert(hidden == 1 and c.currentAnimTrack == nil)

-- Aplicacion de los siete slots del paquete.
local slotNames = {"idle", "walk", "run", "jump", "fall", "climb", "swim"}
local slots = {}
for _, name in ipairs(slotNames) do slots[name] = {GetChildren = function() return {} end} end
local animate = {Enabled = true, FindFirstChild = function(_, name) return slots[name] end}
function character:FindFirstChild(name) if name == "Animate" then return animate end end
c.game.GetObjects = function(_, uri)
    local id = tonumber(uri:match("%d+"))
    return {animation(id, slotNames[id])}
end
local created = {}
c.Instance.new = function()
    local a = animation(0); table.insert(created, a); return a
end
assert(loadModule("player/animation_packs")(c))
local pack = {name = "Test", Idle = 1, Walk = 2, Run = 3, Jump = 4, Fall = 5, Climb = 6, Swim = 7}
c.EquipAnimationPack(pack)
assert(#created == 7 and c.lastVexroAnimationPack == pack and animate.Enabled)
for i, a in ipairs(created) do assert(a.Parent == slots[slotNames[i]] and a.AnimationId == "rbxassetid://" .. i) end

-- Precarga, aislamiento, orden, recarga y aborto de inicializacion.
local app = loadModule("app")
local order = {}
local starts = 0
local stubModules = {
    manifest = {sharedNames = {"privateNil"}, order = {"first", "second"}},
    ["data/emotes"] = "{}", ["data/animations"] = "{}",
    first = function(ctx)
        starts += 1; table.insert(order, "first")
        assert(ctx.privateNil == nil)
        ctx.value = starts; return true
    end,
    second = function(ctx) table.insert(order, "second"); assert(ctx.value == starts); return true end,
}
local firstContext, ok = app(function(name) return stubModules[name] end, {privateNil = "host"}, "folder/")
assert(ok and table.concat(order, ",") == "first,second")
local secondContext = firstContext.reloadApp()
assert(secondContext ~= firstContext and secondContext.value == 2 and firstContext.value == 1)
stubModules.first = function() return nil end
stubModules.second = function() error("Should not run after abort") end
local _, completed = app(function(name) return stubModules[name] end, {}, "")
assert(not completed)
local ran = false
stubModules.first = function() ran = true; return true end
stubModules.second = nil
assert(not pcall(app, function(name) return stubModules[name] end, {}, ""))
assert(not ran, "Missing module must fail before initialization")
assert(rawget(host, "Settings") == nil and rawget(host, "currentAnimTrack") == nil)
print("PASS: local persistence, playback, speed, stop-on-walk, HUD integration, all animation slots, module isolation, reload, abort and preflight")
