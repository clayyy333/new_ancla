--[[
    FPS BOOSTER CORE V3
    SIN UI

    Diseñado para que otra GUI controle el módulo.

    API PUBLICA:
    --------------------------------------------------------
    FPSBooster:SetProfile("SUAVE")
    FPSBooster:SetProfile("FUERTE")
    FPSBooster:SetProfile("EXTREMO")

    FPSBooster:SetRenderDistance(800)
    FPSBooster:IncreaseRenderDistance()
    FPSBooster:DecreaseRenderDistance()

    FPSBooster:GetRenderDistance()
    FPSBooster:GetProfile()
    FPSBooster:GetStats()
    FPSBooster:GetState()

    FPSBooster:Restore()
    FPSBooster:Destroy()
    --------------------------------------------------------

    DISTANCIAS:
    SUAVE   = 1000
    FUERTE  = 600
    EXTREMO = 300

    MIN = 300
    MAX = 1500
    STEP = 100

    PRINCIPIOS:
    - NO Destroy() sobre objetos del juego.
    - NO RenderStepped.
    - NO Heartbeat.
    - NO Stepped.
    - NO modifica física.
    - NO modifica CFrame.
    - NO modifica StreamingEnabled.
    - NO modifica ClockTime.
    - NO modifica Atmosphere.
    - NO modifica Fog.
    - NO modifica ColorCorrection.
    - NO escanea Workspace continuamente.
    - El escaneo pesado se realiza al aplicar un perfil.
    - El LOD se actualiza a baja frecuencia y solo si el
      jugador se ha desplazado lo suficiente.
]]

return function(context)
	setfenv(1,context)

local IS_METRO_LIFE = game.GameId == 4540138978

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local FPSBooster = {}

--==========================================================
-- CONFIGURACION
--==========================================================

local MIN_RENDER_DISTANCE = 300
local MAX_RENDER_DISTANCE = 1500
local RENDER_STEP = 100

local PROFILE_RENDER_DISTANCE = {
    SUAVE = 1000,
    FUERTE = 600,
    EXTREMO = 300
}

-- Cada cuantos segundos comprobar movimiento.
-- No es un loop por frame.
local LOD_CHECK_INTERVAL = 2.5

-- Solo recalcular LOD si el jugador se movio esta distancia.
local PLAYER_MOVE_THRESHOLD = 80

-- Cantidad procesada antes de ceder tiempo al juego.
local SCAN_BATCH_SIZE = 750
local RESTORE_BATCH_SIZE = 500
local LOD_BATCH_SIZE = 20

--==========================================================
-- ESTADO
--==========================================================

local currentProfile = "NORMAL"
local renderDistance = nil

local processing = false
local destroyed = false

-- Guarda SOLO propiedades que realmente modificamos.
local originalProperties = {}

-- Evita procesar dos veces un objeto durante un perfil.
local processedObjects = setmetatable({}, {
    __mode = "k"
})

-- Cache de grupos visuales utilizados para LOD.
local lodGroups = {}

-- Para evitar registrar el mismo grupo varias veces.
local registeredLODGroups = setmetatable({}, {
    __mode = "k"
})

local connections = {}

local watcherToken = 0
local lastLODPosition = nil

local stats = {
    scanned = 0,
    shadowsDisabled = 0,
    lightShadowsDisabled = 0,
    postEffectsDisabled = 0,
    effectsDisabled = 0,
    materialsSimplified = 0,

    lodGroups = 0,
    lodHidden = 0,
    lodVisible = 0,

    newObjects = 0
}

--==========================================================
-- UTILIDADES SEGURAS
--==========================================================

local function safeGet(object, property)

    local ok, value = pcall(function()
        return object[property]
    end)

    if ok then
        return true, value
    end

    return false, nil
end

local function safeSet(object, property, value)

    return pcall(function()
        object[property] = value
    end)
end

--==========================================================
-- GUARDAR VALORES ORIGINALES
--==========================================================

local function rememberProperty(object, property)

    if not object then
        return
    end

    local properties = originalProperties[object]

    if not properties then
        properties = {}
        originalProperties[object] = properties
    end

    -- Usamos una estructura explícita porque una propiedad
    -- original podría ser false.
    if properties[property] ~= nil then
        return
    end

    local ok, value = safeGet(
        object,
        property
    )

    if ok then

        properties[property] = {
            value = value
        }
    end
end

local function changeProperty(object, property, value)

    if not object then
        return false
    end

    local ok, currentValue = safeGet(
        object,
        property
    )

    if not ok then
        return false
    end

    if currentValue == value then
        return false
    end

    rememberProperty(
        object,
        property
    )

    return safeSet(
        object,
        property,
        value
    )
end

--==========================================================
-- PERSONAJES
--==========================================================

local function isCharacterObject(object)

    local current = object

    while current and current ~= Workspace do

        if current:IsA("Model") then

            if current:FindFirstChildOfClass(
                "Humanoid"
            ) then

                return true
            end
        end

        current = current.Parent
    end

    return false
end

--==========================================================
-- RESET DE ESTADISTICAS
--==========================================================

local function resetProfileStats()

    stats.scanned = 0

    stats.shadowsDisabled = 0
    stats.lightShadowsDisabled = 0
    stats.postEffectsDisabled = 0
    stats.effectsDisabled = 0
    stats.materialsSimplified = 0

    -- No reiniciamos lodGroups porque representa
    -- el cache actual.

    stats.lodHidden = 0
    stats.lodVisible = 0
end

--==========================================================
-- OPTIMIZACION VISUAL
--==========================================================

local function optimizeObject(object, profile)

    if not object or not object.Parent then
        return
    end

    if processedObjects[object] then
        return
    end

    processedObjects[object] = true

    stats.scanned += 1

    if isCharacterObject(object) then
        return
    end

    --------------------------------------------------------
    -- BASEPART
    --------------------------------------------------------

    if object:IsA("BasePart") then

        -- Principal ahorro gráfico:
        -- evitar sombras individuales.

        if changeProperty(
            object,
            "CastShadow",
            false
        ) then

            stats.shadowsDisabled += 1
        end

        ----------------------------------------------------
        -- EXTREMO
        ----------------------------------------------------

        if profile == "EXTREMO" then

            local ok, material = safeGet(
                object,
                "Material"
            )

            if ok
            and material ~= Enum.Material.Plastic
            and material ~= Enum.Material.SmoothPlastic then

                if changeProperty(
                    object,
                    "Material",
                    Enum.Material.SmoothPlastic
                ) then

                    stats.materialsSimplified += 1
                end
            end
        end

        return
    end

    --------------------------------------------------------
    -- LUCES
    --------------------------------------------------------

    if object:IsA("PointLight")
    or object:IsA("SpotLight")
    or object:IsA("SurfaceLight") then

        -- Conservamos la luz.
        -- Solo quitamos el calculo de sombras.

        if changeProperty(
            object,
            "Shadows",
            false
        ) then

            stats.lightShadowsDisabled += 1
        end

        return
    end

    --------------------------------------------------------
    -- POSTPROCESADO
    --------------------------------------------------------

    if object:IsA("DepthOfFieldEffect")
    or object:IsA("BloomEffect")
    or object:IsA("SunRaysEffect") then

        if changeProperty(
            object,
            "Enabled",
            false
        ) then

            stats.postEffectsDisabled += 1
        end

        return
    end

    --------------------------------------------------------
    -- IMPORTANTE:
    --
    -- ColorCorrection NO se modifica.
    --
    -- Puede formar parte del sistema:
    -- - dia/noche
    -- - clima
    -- - color ambiental
    --------------------------------------------------------

    --------------------------------------------------------
    -- PARTICULAS / EFECTOS
    --------------------------------------------------------

    if object:IsA("ParticleEmitter")
    or object:IsA("Beam")
    or object:IsA("Trail")
    or object:IsA("Smoke")
    or object:IsA("Fire")
    or object:IsA("Sparkles") then

        if profile == "FUERTE"
        or profile == "EXTREMO" then

            if changeProperty(
                object,
                "Enabled",
                false
            ) then

                stats.effectsDisabled += 1
            end
        end

        return
    end
end

--==========================================================
-- LIGHTING GLOBAL
--==========================================================

local function optimizeGlobalLighting()

    -- Un solo cambio con impacto potencialmente grande.
    changeProperty(
        Lighting,
        "GlobalShadows",
        false
    )

    -- DELIBERADAMENTE NO MODIFICAMOS:
    --
    -- ClockTime
    -- TimeOfDay
    -- Brightness
    -- FogStart
    -- FogEnd
    -- GeographicLatitude
    -- Atmosphere
    -- ColorCorrection
end

--==========================================================
-- NOMBRES LOD
--==========================================================

-- Estos nombres aprovechan mapas que ya organizan
-- sus visuales mediante grupos LOD.
--
-- Si no existen, simplemente no se registran.

local LOD_NAMES = {

    detailed = true,
    detailedoutline = true,
    outline = true,
    viewoutline = true,
    lod_outwall = true,
    notdynamic = true
}

local function isUniversalLODGroup(object)
    if not object or not object:IsA("Model")
    or isCharacterObject(object) then
        return false
    end

    local parent = object.Parent
    if parent ~= Workspace
    and not (
        parent
        and parent:IsA("Folder")
        and parent.Parent == Workspace
    ) then
        return false
    end

    local ok, size = pcall(function()
        local _, bounds = object:GetBoundingBox()
        return bounds
    end)
    if not ok then
        return false
    end

    local largest = math.max(size.X, size.Y, size.Z)
    return largest >= 4
        and largest <= 350
        and object:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

local function isLODGroup(object)
    if not object then
        return false
    end

    if not IS_METRO_LIFE then
        return isUniversalLODGroup(object)
    end

    if not (
        object:IsA("Model")
        or object:IsA("Folder")
    ) then
        return false
    end

    return LOD_NAMES[
        string.lower(object.Name)
    ] == true
end

--==========================================================
-- POSICION REPRESENTATIVA DEL GRUPO
--==========================================================

local function getGroupPosition(group)

    if not group or not group.Parent then
        return nil
    end

    if group:IsA("Model") then

        local ok, pivot = pcall(function()
            return group:GetPivot()
        end)

        if ok then
            return pivot.Position
        end
    end

    -- Folder no tiene Pivot.
    -- Encontramos una pieza representativa UNA VEZ.

    local firstPart =
        group:FindFirstChildWhichIsA(
            "BasePart",
            true
        )

    if firstPart then
        return firstPart.Position
    end

    return nil
end

--==========================================================
-- REGISTRAR GRUPO LOD
--==========================================================

local function registerLODGroup(object)

    if not isLODGroup(object) then
        return false
    end

    if registeredLODGroups[object] then
        return false
    end

    local position =
        getGroupPosition(object)

    if not position then
        return false
    end

    registeredLODGroups[object] = true

    table.insert(lodGroups, {

        object = object,

        -- Posicion cacheada.
        position = position,

        -- Las partes se obtienen solamente
        -- cuando sea necesario ocultar el grupo.
        parts = nil,

        hidden = false
    })

    stats.lodGroups = #lodGroups

    return true
end

--==========================================================
-- CACHEAR PARTES DE UN GRUPO
--==========================================================

local function cacheGroupParts(entry)

    if entry.parts then
        return entry.parts
    end

    local parts = {}

    local group = entry.object

    if not group or not group.Parent then

        entry.parts = parts
        return parts
    end

    local descendants =
        group:GetDescendants()

    for _, object in ipairs(descendants) do

        if object:IsA("BasePart")
        and not isCharacterObject(object) then

            table.insert(
                parts,
                object
            )
        end
    end

    entry.parts = parts

    return parts
end

--==========================================================
-- OCULTAR / MOSTRAR LOD LOCALMENTE
--==========================================================

local function setLODHidden(entry, hidden)

    if entry.hidden == hidden then
        return
    end

    entry.hidden = hidden

    local parts =
        cacheGroupParts(entry)

    for index, part in ipairs(parts) do

        if part and part.Parent then

            pcall(function()

                -- Solo afecta la visualizacion local.
                --
                -- NO cambia:
                -- Transparency real
                -- CanCollide
                -- CFrame
                -- Anchored
                -- masa
                -- fisica

                part.LocalTransparencyModifier =
                    hidden and 1 or 0
            end)
        end

        if index % 250 == 0 then
            task.wait()
        end
    end
end

--==========================================================
-- ACTUALIZAR LOD
--==========================================================

local function updateLOD(force)

    if destroyed then
        return
    end

    if not renderDistance then
        return
    end

    local character =
        LocalPlayer.Character

    if not character then
        return
    end

    local root =
        character:FindFirstChild(
            "HumanoidRootPart"
        )

    if not root then
        return
    end

    local playerPosition =
        root.Position

    --------------------------------------------------------
    -- EVITAR CALCULOS INNECESARIOS
    --------------------------------------------------------

    if not force
    and lastLODPosition then

        local movement =
            (
                playerPosition
                - lastLODPosition
            ).Magnitude

        if movement <
            PLAYER_MOVE_THRESHOLD then

            return
        end
    end

    lastLODPosition =
        playerPosition

    local hidden = 0
    local visible = 0

    --------------------------------------------------------
    -- SOLO CALCULAMOS DISTANCIA DE GRUPOS,
    -- NO DE CADA PARTE DEL MAPA.
    --------------------------------------------------------

    for index, entry in ipairs(lodGroups) do

        local object = entry.object

        if object
        and object.Parent then

            local distance =
                (
                    entry.position
                    - playerPosition
                ).Magnitude

            local shouldHide =
                distance > renderDistance

            setLODHidden(
                entry,
                shouldHide
            )

            if shouldHide then
                hidden += 1
            else
                visible += 1
            end
        end

        if index % LOD_BATCH_SIZE == 0 then
            task.wait()
        end
    end

    stats.lodHidden = hidden
    stats.lodVisible = visible
end

--==========================================================
-- CONSTRUIR CACHE LOD
--==========================================================

local function buildLODCache()

    lodGroups = {}

    registeredLODGroups =
        setmetatable({}, {
            __mode = "k"
        })

    stats.lodGroups = 0

    -- Para mantenerlo relativamente universal,
    -- analizamos Workspace una sola vez.
    --
    -- No depende exclusivamente de ART_City.

    local descendants =
        Workspace:GetDescendants()

    for index, object in ipairs(descendants) do

        if isLODGroup(object) then
            registerLODGroup(object)
        end

        if index % 1500 == 0 then
            task.wait()
        end
    end

    stats.lodGroups = #lodGroups
end

--==========================================================
-- ESCANEO VISUAL
--==========================================================

local function scanVisuals(profile)

    processedObjects =
        setmetatable({}, {
            __mode = "k"
        })

    local descendants =
        Workspace:GetDescendants()

    for index, object in ipairs(descendants) do

        optimizeObject(
            object,
            profile
        )

        if index % SCAN_BATCH_SIZE == 0 then
            task.wait()
        end
    end

    -- Lighting normalmente contiene muy pocos objetos.

    for _, object in ipairs(
        Lighting:GetDescendants()
    ) do

        optimizeObject(
            object,
            profile
        )
    end
end

--==========================================================
-- DISTANCIA
--==========================================================

local function normalizeDistance(distance)

    distance = tonumber(distance)

    if not distance then
        return nil
    end

    distance = math.floor(
        distance / RENDER_STEP + 0.5
    ) * RENDER_STEP

    return math.clamp(
        distance,
        MIN_RENDER_DISTANCE,
        MAX_RENDER_DISTANCE
    )
end

--==========================================================
-- API: SET RENDER DISTANCE
--==========================================================

function FPSBooster:SetRenderDistance(distance)

    if destroyed then
        return nil
    end

    local normalized =
        normalizeDistance(distance)

    if not normalized then
        return nil
    end

    renderDistance =
        normalized

    lastLODPosition = nil

    task.spawn(function()
        updateLOD(true)
    end)

    return renderDistance
end

--==========================================================
-- API: +
--==========================================================

function FPSBooster:IncreaseRenderDistance()

    if destroyed then
        return nil
    end

    local current =
        renderDistance
        or MIN_RENDER_DISTANCE

    return self:SetRenderDistance(
        current + RENDER_STEP
    )
end

--==========================================================
-- API: -
--==========================================================

function FPSBooster:DecreaseRenderDistance()

    if destroyed then
        return nil
    end

    local current =
        renderDistance
        or MIN_RENDER_DISTANCE

    return self:SetRenderDistance(
        current - RENDER_STEP
    )
end

--==========================================================
-- API: GET DISTANCE
--==========================================================

function FPSBooster:GetRenderDistance()

    return renderDistance
end

--==========================================================
-- APLICAR PERFIL
--==========================================================

function FPSBooster:SetProfile(profile)

    if destroyed or processing then
        return false
    end

    profile =
        string.upper(
            tostring(profile)
        )

    local defaultDistance =
        PROFILE_RENDER_DISTANCE[profile]

    if not defaultDistance then

        warn(
            "[FPSBooster] Perfil invalido: "
            .. tostring(profile)
        )

        return false
    end

    -- Evita que un perfil mas fuerte deje cambios acumulados
    -- al seleccionar posteriormente uno mas suave.
    if currentProfile ~= "NORMAL"
    and not self:Restore() then
        return false
    end

    processing = true

    currentProfile =
        profile

    resetProfileStats()

    --------------------------------------------------------
    -- Cada perfil establece SU distancia inicial.
    --------------------------------------------------------

    renderDistance =
        defaultDistance

    lastLODPosition = nil

    --------------------------------------------------------
    -- OPTIMIZACIONES
    --------------------------------------------------------

    optimizeGlobalLighting()

    scanVisuals(profile)

    --------------------------------------------------------
    -- LOD
    --------------------------------------------------------

    updateLOD(true)

    processing = false

    return true
end

--==========================================================
-- API: PERFIL
--==========================================================

function FPSBooster:GetProfile()

    return currentProfile
end

--==========================================================
-- API: STATS
--==========================================================

function FPSBooster:GetStats()

    return {

        profile =
            currentProfile,

        renderDistance =
            renderDistance,

        scanned =
            stats.scanned,

        shadowsDisabled =
            stats.shadowsDisabled,

        lightShadowsDisabled =
            stats.lightShadowsDisabled,

        postEffectsDisabled =
            stats.postEffectsDisabled,

        effectsDisabled =
            stats.effectsDisabled,

        materialsSimplified =
            stats.materialsSimplified,

        lodGroups =
            stats.lodGroups,

        lodHidden =
            stats.lodHidden,

        lodVisible =
            stats.lodVisible,

        newObjects =
            stats.newObjects
    }
end

--==========================================================
-- API: ESTADO GENERAL
--==========================================================

function FPSBooster:GetState()

    return {

        profile =
            currentProfile,

        renderDistance =
            renderDistance,

        minRenderDistance =
            MIN_RENDER_DISTANCE,

        maxRenderDistance =
            MAX_RENDER_DISTANCE,

        renderStep =
            RENDER_STEP,

        processing =
            processing,

        destroyed =
            destroyed
    }
end

--==========================================================
-- RESTAURAR LOD
--==========================================================

local function restoreLOD()

    for index, entry in ipairs(lodGroups) do

        if entry.hidden then

            setLODHidden(
                entry,
                false
            )
        end

        if index % LOD_BATCH_SIZE == 0 then
            task.wait()
        end
    end

    stats.lodHidden = 0
end

--==========================================================
-- API: RESTORE
--==========================================================

function FPSBooster:Restore()

    if destroyed or processing then
        return false
    end

    processing = true

    --------------------------------------------------------
    -- QUITAR NUESTRO CULLING
    --------------------------------------------------------

    renderDistance = nil
    lastLODPosition = nil

    restoreLOD()

    --------------------------------------------------------
    -- RESTAURAR PROPIEDADES GRAFICAS
    --------------------------------------------------------

    local restored = 0

    for object, properties in pairs(
        originalProperties
    ) do

        if object and object.Parent then

            for property, saved in pairs(
                properties
            ) do

                safeSet(
                    object,
                    property,
                    saved.value
                )

                restored += 1

                if restored %
                    RESTORE_BATCH_SIZE == 0 then

                    task.wait()
                end
            end
        end
    end

    originalProperties = {}

    processedObjects =
        setmetatable({}, {
            __mode = "k"
        })

    currentProfile =
        "NORMAL"

    processing = false

    return true
end

--==========================================================
-- OBJETOS NUEVOS
--==========================================================

local function onNewObject(object)

    if destroyed then
        return
    end

    stats.newObjects += 1

    --------------------------------------------------------
    -- OPTIMIZACION VISUAL
    --------------------------------------------------------

    if currentProfile ~= "NORMAL" then

        task.defer(function()

            if destroyed then
                return
            end

            optimizeObject(
                object,
                currentProfile
            )
        end)
    end

    --------------------------------------------------------
    -- NUEVOS GRUPOS LOD
    --------------------------------------------------------

    if isLODGroup(object) then

        task.defer(function()

            if destroyed then
                return
            end

            if registerLODGroup(object)
            and renderDistance then

                updateLOD(true)
            end
        end)
    end
end

table.insert(
    connections,

    Workspace.DescendantAdded:Connect(
        onNewObject
    )
)

table.insert(
    connections,

    Lighting.DescendantAdded:Connect(
        onNewObject
    )
)

--==========================================================
-- WATCHER LOD
--==========================================================

local function startLODWatcher()

    watcherToken += 1

    local myToken =
        watcherToken

    task.spawn(function()

        while not destroyed
        and watcherToken == myToken do

            task.wait(
                LOD_CHECK_INTERVAL
            )

            if renderDistance
            and currentProfile ~= "NORMAL" then

                updateLOD(false)
            end
        end
    end)
end

--==========================================================
-- API: DESTROY
--==========================================================

function FPSBooster:Destroy()

    if destroyed then
        return
    end

    -- Primero restauramos.
    self:Restore()

    destroyed = true

    watcherToken += 1

    for _, connection in ipairs(
        connections
    ) do

        pcall(function()
            connection:Disconnect()
        end)
    end

    connections = {}
end

--==========================================================
-- INICIALIZACION
--==========================================================

task.spawn(function()

    buildLODCache()

    if not destroyed then
        startLODWatcher()
    end
end)

FPSBoosterCore = FPSBooster
return true
end
