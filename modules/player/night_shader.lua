--==============================================================
-- NIGHT SHADER / SILENT HILL STORM V7.2
-- IMPLEMENTACION SIN GUI
--
-- API:
--
-- NightShader:SetMode("NIGHT4")
-- NightShader:SetMode("HORROR")
-- NightShader:Disable()
-- NightShader:GetMode()
-- NightShader:IsEnabled()
-- NightShader:Destroy()
--
-- V7.2:
-- ✓ Rayo visual desaparece rapidamente
-- ✓ Fade del rayo ~0.08 s
-- ✓ PointLight desaparece independientemente ~0.10 s
-- ✓ ThunderOrigin permanece invisible para el audio 3D
-- ✓ 1 rayo = 1 trueno
-- ✓ Sin tormentas agrupadas
-- ✓ Skybox personalizado
-- ✓ Niebla Silent Hill
-- ✓ Sin Heartbeat / RenderStepped / Stepped
-- ✓ No modifica ClockTime
--==============================================================


return function(context)
    setfenv(1, context)

--==============================================================
-- SERVICIOS
--==============================================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer


--==============================================================
-- CONTROLADOR
--==============================================================

local NightShader = {}


--==============================================================
-- NOMBRES
--==============================================================

local EFFECT_FOLDER_NAME =
    "SilentHillStormV72_Effects"

local FOG_FOLDER_NAME =
    "SilentHillStormV72_Fog"

local LIGHTNING_FOLDER_NAME =
    "SilentHillStormV72_Lightning"

local CUSTOM_SKY_NAME =
    "SilentHillStormV72_Sky"


--==============================================================
-- AUDIO
--==============================================================

local THUNDER_SOUND_ID =
    "rbxassetid://131961817954153"


--==============================================================
-- SKYBOX
--==============================================================

local SKYBOX = {

    Bk = "rbxassetid://154185004",
    Dn = "rbxassetid://154184960",
    Ft = "rbxassetid://154185021",
    Lf = "rbxassetid://154184943",
    Rt = "rbxassetid://154184972",
    Up = "rbxassetid://154185031"

}


--==============================================================
-- CONFIGURACION DEL RAYO
--==============================================================

local STORM = {

    FirstStrikeDelay = 2,

    MinDelay = 7,
    MaxDelay = 18,

    MinDistance = 110,
    MaxDistance = 350,

    MinHeight = 180,
    MaxHeight = 300,

    MinSegments = 10,
    MaxSegments = 16,

    MinThickness = 1.3,
    MaxThickness = 2.2,

    BranchChance = 0.38,

    SoundMinDistance = 25,
    SoundMaxDistance = 1000,

    ----------------------------------------------------------
    -- DESAPARICION VISUAL
    ----------------------------------------------------------

    LightningFadeSteps = 4,
    LightningFadeStepTime = 0.02,

    ----------------------------------------------------------
    -- NUEVO V7.2:
    -- PointLight dura solo ~0.10 segundos.
    ----------------------------------------------------------

    LightFadeSteps = 5,
    LightFadeStepTime = 0.02

}


--==============================================================
-- PRESETS
--==============================================================

local PRESETS = {

    NIGHT4 = {

        Brightness = 0.48,

        Ambient =
            Color3.fromRGB(6, 10, 23),

        OutdoorAmbient =
            Color3.fromRGB(10, 15, 31),

        ColorShiftTop =
            Color3.fromRGB(3, 7, 22),

        ColorShiftBottom =
            Color3.fromRGB(1, 2, 8),

        CorrectionBrightness = -0.30,
        Contrast = 0.34,
        Saturation = -0.27,

        TintColor =
            Color3.fromRGB(115, 148, 230),

        BloomIntensity = 0.50,
        BloomSize = 28,
        BloomThreshold = 0.90,

        AtmosphereColor =
            Color3.fromRGB(55, 76, 130),

        AtmosphereDecay =
            Color3.fromRGB(9, 15, 35),

        AtmosphereDensity = 0.32,
        AtmosphereHaze = 1.80,

        FogColor =
            Color3.fromRGB(30, 38, 58),

        FogStart = 100000,
        FogEnd = 100000

    },


    HORROR = {

        Brightness = 0.32,

        Ambient =
            Color3.fromRGB(9, 11, 12),

        OutdoorAmbient =
            Color3.fromRGB(15, 17, 17),

        ColorShiftTop =
            Color3.fromRGB(7, 9, 9),

        ColorShiftBottom =
            Color3.fromRGB(3, 4, 4),

        CorrectionBrightness = -0.25,
        Contrast = 0.34,
        Saturation = -0.65,

        TintColor =
            Color3.fromRGB(160, 168, 165),

        BloomIntensity = 0.14,
        BloomSize = 18,
        BloomThreshold = 1.15,

        AtmosphereColor =
            Color3.fromRGB(150, 155, 150),

        AtmosphereDecay =
            Color3.fromRGB(65, 70, 68),

        AtmosphereDensity = 0.72,
        AtmosphereHaze = 8,

        FogColor =
            Color3.fromRGB(145, 150, 145),

        FogStart = 5,
        FogEnd = 110

    }

}


--==============================================================
-- ESTADO
--==============================================================

local enabled = false
local destroyed = false

local currentPreset = nil
local applying = false

local originals = {}

local lightingConnections = {}
local permanentConnections = {}

local ShaderFolder = nil
local ColorCorrection = nil
local Bloom = nil
local Atmosphere = nil

local FogFolder = nil
local LightningFolder = nil
local CustomSky = nil

local stormEnabled = false
local stormGeneration = 0


--==============================================================
-- UTILIDADES
--==============================================================

local function disconnectList(list)

    for _, connection in ipairs(list) do

        pcall(function()
            connection:Disconnect()
        end)

    end

    table.clear(list)

end


local function clamp255(value)

    return math.clamp(
        math.floor(value),
        0,
        255
    )

end


--==============================================================
-- GUARDAR ESTADO ORIGINAL
--==============================================================

local function saveOriginals()

    if originals.Saved then
        return
    end

    originals.Saved = true

    originals.Brightness =
        Lighting.Brightness

    originals.Ambient =
        Lighting.Ambient

    originals.OutdoorAmbient =
        Lighting.OutdoorAmbient

    originals.ColorShiftTop =
        Lighting.ColorShift_Top

    originals.ColorShiftBottom =
        Lighting.ColorShift_Bottom

    originals.FogColor =
        Lighting.FogColor

    originals.FogStart =
        Lighting.FogStart

    originals.FogEnd =
        Lighting.FogEnd


    originals.Skies = {}

    for _, object in ipairs(
        Lighting:GetChildren()
    ) do

        if object:IsA("Sky") then

            table.insert(
                originals.Skies,
                {
                    Object = object,
                    Parent = object.Parent
                }
            )

        end

    end

end


--==============================================================
-- EFECTOS
--==============================================================

local function createShaderEffects()

    if ShaderFolder
    and ShaderFolder.Parent then
        return
    end


    ShaderFolder =
        Instance.new("Folder")

    ShaderFolder.Name =
        EFFECT_FOLDER_NAME

    ShaderFolder.Parent =
        Lighting


    ColorCorrection =
        Instance.new(
            "ColorCorrectionEffect"
        )

    ColorCorrection.Name =
        "Horror_ColorCorrection"

    ColorCorrection.Enabled =
        true

    ColorCorrection.Parent =
        ShaderFolder


    Bloom =
        Instance.new(
            "BloomEffect"
        )

    Bloom.Name =
        "Horror_Bloom"

    Bloom.Enabled =
        true

    Bloom.Parent =
        ShaderFolder


    Atmosphere =
        Instance.new("Atmosphere")

    Atmosphere.Name =
        "Horror_Atmosphere"

    Atmosphere.Glare = 0
    Atmosphere.Offset = 0

    Atmosphere.Parent =
        ShaderFolder

end


--==============================================================
-- SKYBOX
--==============================================================

local function removeCustomSky()

    if CustomSky then

        pcall(function()
            CustomSky:Destroy()
        end)

    end

    CustomSky = nil


    if originals.Skies then

        for _, data in ipairs(
            originals.Skies
        ) do

            if data.Object then

                pcall(function()

                    data.Object.Parent =
                        data.Parent

                end)

            end

        end

    end

end


local function createCustomSky()

    removeCustomSky()


    if originals.Skies then

        for _, data in ipairs(
            originals.Skies
        ) do

            if data.Object
            and data.Object.Parent then

                pcall(function()
                    data.Object.Parent = nil
                end)

            end

        end

    end


    CustomSky =
        Instance.new("Sky")


    CustomSky.Name =
        CUSTOM_SKY_NAME


    CustomSky.SkyboxBk =
        SKYBOX.Bk

    CustomSky.SkyboxDn =
        SKYBOX.Dn

    CustomSky.SkyboxFt =
        SKYBOX.Ft

    CustomSky.SkyboxLf =
        SKYBOX.Lf

    CustomSky.SkyboxRt =
        SKYBOX.Rt

    CustomSky.SkyboxUp =
        SKYBOX.Up


    CustomSky.StarCount = 0

    CustomSky.CelestialBodiesShown =
        false


    CustomSky.Parent =
        Lighting

end


--==============================================================
-- NIEBLA
--==============================================================

local function removeFogLayers()

    if FogFolder then

        pcall(function()
            FogFolder:Destroy()
        end)

    end

    FogFolder = nil

end


local function createFogLayer(
    parent,
    root,
    name,
    offsetY,
    sizeY,
    rate,
    minSize,
    maxSize,
    transparency
)

    local part =
        Instance.new("Part")


    part.Name = name

    part.Size =
        Vector3.new(
            100,
            sizeY,
            100
        )

    part.Transparency = 1

    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false

    part.CastShadow = false
    part.Massless = true
    part.Anchored = false


    part.CFrame =
        root.CFrame
        * CFrame.new(
            0,
            offsetY,
            0
        )


    part.Parent =
        parent


    ----------------------------------------------------------
    -- SEGUIR AL HRP
    ----------------------------------------------------------

    local weld =
        Instance.new(
            "WeldConstraint"
        )

    weld.Name =
        "FogFollow"

    weld.Part0 =
        root

    weld.Part1 =
        part

    weld.Parent =
        part


    ----------------------------------------------------------
    -- PARTICULAS
    ----------------------------------------------------------

    local emitter =
        Instance.new(
            "ParticleEmitter"
        )


    emitter.Name =
        name .. "_Emitter"


    emitter.Texture =
        "rbxasset://textures/particles/smoke_main.dds"


    emitter.Rate =
        rate


    emitter.Lifetime =
        NumberRange.new(
            9,
            14
        )


    emitter.Speed =
        NumberRange.new(
            0.25,
            0.85
        )


    emitter.EmissionDirection =
        Enum.NormalId.Top


    emitter.SpreadAngle =
        Vector2.new(
            180,
            180
        )


    emitter.Size =
        NumberSequence.new({

            NumberSequenceKeypoint.new(
                0,
                minSize
            ),

            NumberSequenceKeypoint.new(
                0.30,
                minSize * 1.20
            ),

            NumberSequenceKeypoint.new(
                0.65,
                maxSize
            ),

            NumberSequenceKeypoint.new(
                1,
                maxSize * 1.15
            )

        })


    emitter.Transparency =
        NumberSequence.new({

            NumberSequenceKeypoint.new(
                0,
                1
            ),

            NumberSequenceKeypoint.new(
                0.08,
                transparency + 0.12
            ),

            NumberSequenceKeypoint.new(
                0.20,
                transparency
            ),

            NumberSequenceKeypoint.new(
                0.55,
                math.max(
                    0,
                    transparency - 0.08
                )
            ),

            NumberSequenceKeypoint.new(
                0.82,
                transparency
            ),

            NumberSequenceKeypoint.new(
                1,
                1
            )

        })


    emitter.Color =
        ColorSequence.new({

            ColorSequenceKeypoint.new(
                0,
                Color3.fromRGB(
                    175,
                    180,
                    174
                )
            ),

            ColorSequenceKeypoint.new(
                0.50,
                Color3.fromRGB(
                    140,
                    147,
                    142
                )
            ),

            ColorSequenceKeypoint.new(
                1,
                Color3.fromRGB(
                    105,
                    113,
                    110
                )
            )

        })


    emitter.Rotation =
        NumberRange.new(
            0,
            360
        )


    emitter.RotSpeed =
        NumberRange.new(
            -3,
            3
        )


    emitter.Acceleration =
        Vector3.new(
            0.18,
            0.02,
            0.08
        )


    emitter.LightEmission = 0

    emitter.LightInfluence = 0.35


    emitter.Orientation =
        Enum.ParticleOrientation.FacingCamera


    emitter.Enabled = true

    emitter.Parent = part


    emitter:Emit(
        math.floor(
            rate * 2
        )
    )

end


local function createDenseFog()

    removeFogLayers()


    local character =
        Player.Character
        or Player.CharacterAdded:Wait()


    local root =
        character:WaitForChild(
            "HumanoidRootPart"
        )


    FogFolder =
        Instance.new("Folder")


    FogFolder.Name =
        FOG_FOLDER_NAME


    FogFolder.Parent =
        Workspace


    ----------------------------------------------------------
    -- CAPA BAJA
    ----------------------------------------------------------

    createFogLayer(
        FogFolder,
        root,

        "GroundFog",

        -3.5,
        5,

        24,

        26,
        48,

        0.38
    )


    ----------------------------------------------------------
    -- CAPA MEDIA
    ----------------------------------------------------------

    createFogLayer(
        FogFolder,
        root,

        "MiddleFog",

        1.5,
        9,

        20,

        30,
        55,

        0.42
    )


    ----------------------------------------------------------
    -- CAPA ALTA
    ----------------------------------------------------------

    createFogLayer(
        FogFolder,
        root,

        "UpperFog",

        7,
        12,

        14,

        36,
        65,

        0.52
    )

end


--==============================================================
-- APLICAR PRESET
--==============================================================

local function applyPreset()

    if not enabled
    or applying then
        return
    end


    local preset =
        PRESETS[currentPreset]


    if not preset then
        return
    end


    applying = true


    Lighting.Brightness =
        preset.Brightness

    Lighting.Ambient =
        preset.Ambient

    Lighting.OutdoorAmbient =
        preset.OutdoorAmbient

    Lighting.ColorShift_Top =
        preset.ColorShiftTop

    Lighting.ColorShift_Bottom =
        preset.ColorShiftBottom

    Lighting.FogColor =
        preset.FogColor

    Lighting.FogStart =
        preset.FogStart

    Lighting.FogEnd =
        preset.FogEnd


    if ColorCorrection
    and ColorCorrection.Parent then

        ColorCorrection.Enabled = true

        ColorCorrection.Brightness =
            preset.CorrectionBrightness

        ColorCorrection.Contrast =
            preset.Contrast

        ColorCorrection.Saturation =
            preset.Saturation

        ColorCorrection.TintColor =
            preset.TintColor

    end


    if Bloom
    and Bloom.Parent then

        Bloom.Enabled = true

        Bloom.Intensity =
            preset.BloomIntensity

        Bloom.Size =
            preset.BloomSize

        Bloom.Threshold =
            preset.BloomThreshold

    end


    if Atmosphere
    and Atmosphere.Parent then

        Atmosphere.Color =
            preset.AtmosphereColor

        Atmosphere.Decay =
            preset.AtmosphereDecay

        Atmosphere.Density =
            preset.AtmosphereDensity

        Atmosphere.Haze =
            preset.AtmosphereHaze

        Atmosphere.Glare = 0
        Atmosphere.Offset = 0

    end


    applying = false

end


--==============================================================
-- PROTECCION DEL CLIMA
--==============================================================

local function protectProperty(property)

    local connection =

        Lighting:GetPropertyChangedSignal(
            property
        ):Connect(function()

            if not enabled
            or applying then
                return
            end


            task.defer(function()

                if enabled then
                    applyPreset()
                end

            end)

        end)


    table.insert(
        lightingConnections,
        connection
    )

end


local function startProtection()

    disconnectList(
        lightingConnections
    )


    protectProperty("Brightness")
    protectProperty("Ambient")
    protectProperty("OutdoorAmbient")

    protectProperty("ColorShift_Top")
    protectProperty("ColorShift_Bottom")

    protectProperty("FogColor")
    protectProperty("FogStart")
    protectProperty("FogEnd")

end


--==============================================================
-- CARPETA DE RAYOS
--==============================================================

local function getLightningFolder()

    if LightningFolder
    and LightningFolder.Parent then

        return LightningFolder

    end


    LightningFolder =
        Instance.new("Folder")


    LightningFolder.Name =
        LIGHTNING_FOLDER_NAME


    LightningFolder.Parent =
        Workspace


    return LightningFolder

end


--==============================================================
-- SEGMENTO
--==============================================================

local function createLightningSegment(
    pointA,
    pointB,
    thickness,
    parent
)

    local distance =
        (pointB - pointA).Magnitude


    if distance < 0.01 then
        return
    end


    local part =
        Instance.new("Part")


    part.Name =
        "Lightning"


    part.Anchored = true

    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false

    part.CastShadow = false


    part.Material =
        Enum.Material.Neon


    part.Color =
        Color3.fromRGB(
            220,
            230,
            255
        )


    part.Transparency =
        0.01


    part.Size =
        Vector3.new(
            thickness,
            thickness,
            distance
        )


    part.CFrame =
        CFrame.lookAt(
            (pointA + pointB) / 2,
            pointB
        )


    part.Parent =
        parent

end


--==============================================================
-- RAMA
--==============================================================

local function createBranch(
    startPoint,
    parent
)

    local previous =
        startPoint


    local branchSegments =
        math.random(
            2,
            5
        )


    local side =
        Vector3.new(

            math.random(-100, 100) / 100,

            -0.35,

            math.random(-100, 100) / 100

        )


    if side.Magnitude <= 0.01 then
        return
    end


    side = side.Unit


    for _ = 1, branchSegments do

        local nextPoint =

            previous

            + side
            * math.random(
                8,
                20
            )

            + Vector3.new(

                math.random(-7, 7),

                -math.random(5, 14),

                math.random(-7, 7)

            )


        createLightningSegment(

            previous,
            nextPoint,

            STORM.MinThickness * 0.45,

            parent

        )


        previous =
            nextPoint

    end

end


--==============================================================
-- CREAR RAYO
--==============================================================

local function createLightningBolt()

    if not stormEnabled
    or currentPreset ~= "HORROR" then
        return nil
    end


    local character =
        Player.Character


    if not character then
        return nil
    end


    local root =
        character:FindFirstChild(
            "HumanoidRootPart"
        )


    if not root then
        return nil
    end


    local angle =
        math.rad(
            math.random(
                0,
                359
            )
        )


    local distance =
        math.random(
            STORM.MinDistance,
            STORM.MaxDistance
        )


    local horizontal =
        Vector3.new(

            math.cos(angle) * distance,

            0,

            math.sin(angle) * distance

        )


    local impactPosition =

        root.Position

        + horizontal

        + Vector3.new(

            math.random(-20, 20),

            math.random(15, 40),

            math.random(-20, 20)

        )


    local startPosition =

        impactPosition

        + Vector3.new(

            math.random(-45, 45),

            math.random(
                STORM.MinHeight,
                STORM.MaxHeight
            ),

            math.random(-45, 45)

        )


    local segments =
        math.random(
            STORM.MinSegments,
            STORM.MaxSegments
        )


    local thickness =

        STORM.MinThickness

        + math.random()

        * (
            STORM.MaxThickness
            - STORM.MinThickness
        )


    ----------------------------------------------------------
    -- CARPETA VISUAL
    ----------------------------------------------------------

    local bolt =
        Instance.new("Folder")


    bolt.Name =
        "LightningStrike"


    bolt.Parent =
        getLightningFolder()


    local points = {
        startPosition
    }


    for i = 1, segments - 1 do

        local alpha =
            i / segments


        local center =
            startPosition:Lerp(
                impactPosition,
                alpha
            )


        local spread =
            math.max(
                3,

                math.floor(

                    22
                    * math.sin(
                        alpha * math.pi
                    )

                )
            )


        local jitter =
            Vector3.new(

                math.random(
                    -spread,
                    spread
                ),

                math.random(-5, 5),

                math.random(
                    -spread,
                    spread
                )

            )


        points[#points + 1] =
            center + jitter

    end


    points[#points + 1] =
        impactPosition


    for i = 1, #points - 1 do

        local taper =

            1

            - (
                (i - 1)
                / (#points * 1.7)
            )


        createLightningSegment(

            points[i],

            points[i + 1],

            math.max(
                0.45,
                thickness * taper
            ),

            bolt

        )


        if i > 2
        and i < #points - 1
        and math.random()
            < STORM.BranchChance then

            createBranch(
                points[i],
                bolt
            )

        end

    end


    ----------------------------------------------------------
    -- THUNDER ORIGIN
    --
    -- Este objeto NO es visual.
    -- Permanece únicamente para el audio espacial.
    ----------------------------------------------------------

    local origin =
        Instance.new("Part")


    origin.Name =
        "ThunderOrigin"


    origin.Size =
        Vector3.new(
            1,
            1,
            1
        )


    origin.Position =
        impactPosition


    origin.Anchored = true
    origin.Transparency = 1

    origin.CanCollide = false
    origin.CanTouch = false
    origin.CanQuery = false

    origin.CastShadow = false


    origin.Parent =
        getLightningFolder()


    local closeness =

        1

        - math.clamp(

            (
                distance
                - STORM.MinDistance
            )

            /

            (
                STORM.MaxDistance
                - STORM.MinDistance
            ),

            0,
            1
        )


    ----------------------------------------------------------
    -- POINTLIGHT
    --
    -- IMPORTANTE V7.2:
    -- Aunque inicialmente vive en ThunderOrigin,
    -- su vida es independiente.
    ----------------------------------------------------------

    local light =
        Instance.new("PointLight")


    light.Name =
        "LightningLight"


    light.Color =
        Color3.fromRGB(
            200,
            220,
            255
        )


    light.Brightness =
        8
        + closeness * 14


    light.Range =
        120
        + closeness * 130


    light.Shadows = true


    light.Parent =
        origin


    return {

        Folder = bolt,

        Origin = origin,

        Light = light,

        Distance = distance,

        Closeness = closeness,

        Position = impactPosition

    }

end


--==============================================================
-- FLASH DEL CIELO
--==============================================================

local function flashSky(
    closeness,
    multiplier
)

    if not stormEnabled
    or currentPreset ~= "HORROR" then
        return
    end


    multiplier =
        multiplier or 1


    local strength =

        (
            0.45
            + closeness * 0.75
        )

        * multiplier


    applying = true


    Lighting.Brightness =
        0.75
        + 1.35 * strength


    Lighting.Ambient =
        Color3.fromRGB(

            clamp255(
                80 + 70 * strength
            ),

            clamp255(
                90 + 75 * strength
            ),

            clamp255(
                105 + 90 * strength
            )

        )


    Lighting.OutdoorAmbient =
        Color3.fromRGB(

            clamp255(
                100 + 80 * strength
            ),

            clamp255(
                110 + 85 * strength
            ),

            clamp255(
                125 + 100 * strength
            )

        )


    Lighting.ColorShift_Top =
        Color3.fromRGB(

            clamp255(
                105 + 80 * strength
            ),

            clamp255(
                125 + 80 * strength
            ),

            clamp255(
                150 + 95 * strength
            )

        )


    if Atmosphere
    and Atmosphere.Parent then

        Atmosphere.Color =
            Color3.fromRGB(

                clamp255(
                    165 + 45 * strength
                ),

                clamp255(
                    175 + 45 * strength
                ),

                clamp255(
                    180 + 50 * strength
                )

            )


        Atmosphere.Decay =
            Color3.fromRGB(

                clamp255(
                    85 + 40 * strength
                ),

                clamp255(
                    95 + 40 * strength
                ),

                clamp255(
                    100 + 45 * strength
                )

            )

    end


    applying = false

end


--==============================================================
-- NUEVO V7.2
-- FADE RAPIDO DEL POINTLIGHT
--==============================================================

local function fadeImpactLight(light)

    if not light
    or not light.Parent then
        return
    end


    local initialBrightness =
        light.Brightness


    local initialRange =
        light.Range


    ----------------------------------------------------------
    -- 5 pasos x 0.02 = ~0.10 segundos
    ----------------------------------------------------------

    for step = 1, STORM.LightFadeSteps do

        if not light
        or not light.Parent then
            return
        end


        local alpha =
            step
            / STORM.LightFadeSteps


        local remaining =
            1 - alpha


        light.Brightness =
            initialBrightness
            * remaining


        ------------------------------------------------------
        -- Reducir tambien el alcance ayuda a que no quede
        -- una zona iluminada mientras desaparece.
        ------------------------------------------------------

        light.Range =
            math.max(
                0,
                initialRange
                * remaining
            )


        task.wait(
            STORM.LightFadeStepTime
        )

    end


    ----------------------------------------------------------
    -- DESTRUIR LA LUZ
    --
    -- ThunderOrigin NO se destruye aqui.
    ----------------------------------------------------------

    if light
    and light.Parent then

        pcall(function()
            light:Destroy()
        end)

    end

end


--==============================================================
-- FADE DEL RAYO
--==============================================================

local function fadeLightning(
    visualFolder
)

    if not visualFolder
    or not visualFolder.Parent then
        return
    end


    local lightningParts = {}


    for _, object in ipairs(
        visualFolder:GetDescendants()
    ) do

        if object:IsA("BasePart")
        and object.Name == "Lightning" then

            table.insert(
                lightningParts,
                object
            )

        end

    end


    ----------------------------------------------------------
    -- 4 x 0.02 = ~0.08 segundos
    ----------------------------------------------------------

    for step = 1, STORM.LightningFadeSteps do

        local alpha =
            step
            / STORM.LightningFadeSteps


        for _, part in ipairs(
            lightningParts
        ) do

            if part
            and part.Parent then

                part.Transparency =

                    0.01

                    + (
                        0.99
                        * alpha
                    )

            end

        end


        task.wait(
            STORM.LightningFadeStepTime
        )

    end


    if visualFolder
    and visualFolder.Parent then

        pcall(function()
            visualFolder:Destroy()
        end)

    end

end


--==============================================================
-- TRUENO 3D
--==============================================================

local function playThunder(
    origin,
    distance,
    closeness
)

    if not origin
    or not origin.Parent then
        return
    end


    ----------------------------------------------------------
    -- RETRASO POR DISTANCIA
    ----------------------------------------------------------

    local normalizedDistance =
        math.clamp(

            distance
            / STORM.MaxDistance,

            0,
            1

        )


    local delayTime =

        0.08

        + normalizedDistance
        * 0.85


    task.wait(
        delayTime
    )


    if not stormEnabled
    or currentPreset ~= "HORROR" then

        if origin
        and origin.Parent then

            origin:Destroy()

        end

        return
    end


    if not origin.Parent then
        return
    end


    local sound =
        Instance.new("Sound")


    sound.Name =
        "Thunder3D"


    sound.SoundId =
        THUNDER_SOUND_ID


    sound.Volume =
        1.4
        + closeness * 2.1


    sound.PlaybackSpeed =
        0.96
        + math.random() * 0.08


    sound.RollOffMode =
        Enum.RollOffMode.InverseTapered


    sound.RollOffMinDistance =
        STORM.SoundMinDistance


    sound.RollOffMaxDistance =
        STORM.SoundMaxDistance


    sound.EmitterSize =
        25


    sound.Parent =
        origin


    local endedConnection


    endedConnection =
        sound.Ended:Connect(function()

            if endedConnection then

                endedConnection:Disconnect()

            end


            --------------------------------------------------
            -- AHORA SI:
            -- audio termino -> borrar ThunderOrigin
            --------------------------------------------------

            if origin
            and origin.Parent then

                pcall(function()
                    origin:Destroy()
                end)

            end

        end)


    sound:Play()


    ----------------------------------------------------------
    -- LIMPIEZA DE SEGURIDAD
    ----------------------------------------------------------

    task.delay(
        20,
        function()

            if origin
            and origin.Parent then

                pcall(function()
                    origin:Destroy()
                end)

            end

        end
    )

end


--==============================================================
-- EVENTO DE RAYO
--==============================================================

local function lightningStrike()

    if not stormEnabled
    or currentPreset ~= "HORROR" then
        return
    end

    local strikeGeneration = stormGeneration


    local strike =
        createLightningBolt()


    if not strike then
        return
    end


    ----------------------------------------------------------
    -- TRUENO INDEPENDIENTE
    ----------------------------------------------------------

    task.spawn(function()

        playThunder(

            strike.Origin,

            strike.Distance,

            strike.Closeness

        )

    end)


    ----------------------------------------------------------
    -- FLASH 1
    ----------------------------------------------------------

    flashSky(
        strike.Closeness,
        1
    )


    task.wait(
        0.065
    )


    if not stormEnabled
    or currentPreset ~= "HORROR"
    or strikeGeneration ~= stormGeneration then

        if strike.Folder
        and strike.Folder.Parent then

            strike.Folder:Destroy()

        end

        return
    end


    applyPreset()


    ----------------------------------------------------------
    -- FLASH 2
    ----------------------------------------------------------

    task.wait(
        math.random(
            4,
            9
        ) / 100
    )


    if stormEnabled
    and currentPreset == "HORROR"
    and strikeGeneration == stormGeneration then

        flashSky(
            strike.Closeness,
            0.68
        )


        task.wait(
            0.045
        )


        applyPreset()

    end


    ----------------------------------------------------------
    -- POSIBLE FLASH 3
    --
    -- Sigue siendo el mismo rayo.
    -- No genera otro sonido.
    ----------------------------------------------------------

    if math.random() < 0.28
    and stormEnabled
    and currentPreset == "HORROR"
    and strikeGeneration == stormGeneration then

        task.wait(
            0.045
        )


        flashSky(
            strike.Closeness,
            0.82
        )


        task.wait(
            0.035
        )


        applyPreset()

    end


    ----------------------------------------------------------
    -- V7.2
    --
    -- DESAPARECER SIMULTANEAMENTE:
    --
    -- PointLight: ~0.10 s
    -- Rayo visual: ~0.08 s
    --
    -- ThunderOrigin continua invisible.
    ----------------------------------------------------------

    task.spawn(function()

        fadeImpactLight(
            strike.Light
        )

    end)


    fadeLightning(
        strike.Folder
    )

end


--==============================================================
-- TORMENTA
--==============================================================

local function stopStorm()

    stormEnabled = false

    stormGeneration += 1


    if LightningFolder then

        pcall(function()
            LightningFolder:Destroy()
        end)


        LightningFolder = nil

    end

end


local function startStorm()

    if stormEnabled then
        return
    end


    stormEnabled = true

    stormGeneration += 1


    local generation =
        stormGeneration


    task.spawn(function()


        ------------------------------------------------------
        -- PRIMER RAYO
        ------------------------------------------------------

        task.wait(
            STORM.FirstStrikeDelay
        )


        if stormEnabled
        and generation == stormGeneration
        and currentPreset == "HORROR" then

            lightningStrike()

        end


        ------------------------------------------------------
        -- RAYOS INDIVIDUALES
        ------------------------------------------------------

        while stormEnabled
        and generation == stormGeneration do


            task.wait(

                math.random(
                    STORM.MinDelay,
                    STORM.MaxDelay
                )

            )


            if not stormEnabled
            or generation ~= stormGeneration then

                break

            end


            if currentPreset == "HORROR" then

                lightningStrike()

            end

        end

    end)

end


--==============================================================
-- DESACTIVAR INTERNO
--==============================================================

local function disableInternal()

    stopStorm()


    enabled = false
    currentPreset = nil


    disconnectList(
        lightingConnections
    )


    removeFogLayers()
    removeCustomSky()


    if ShaderFolder then

        pcall(function()
            ShaderFolder:Destroy()
        end)

    end


    ShaderFolder = nil
    ColorCorrection = nil
    Bloom = nil
    Atmosphere = nil


    ----------------------------------------------------------
    -- RESTAURAR LIGHTING
    ----------------------------------------------------------

    if originals.Saved then

        Lighting.Brightness =
            originals.Brightness

        Lighting.Ambient =
            originals.Ambient

        Lighting.OutdoorAmbient =
            originals.OutdoorAmbient

        Lighting.ColorShift_Top =
            originals.ColorShiftTop

        Lighting.ColorShift_Bottom =
            originals.ColorShiftBottom

        Lighting.FogColor =
            originals.FogColor

        Lighting.FogStart =
            originals.FogStart

        Lighting.FogEnd =
            originals.FogEnd

    end


    originals = {}

end


--==============================================================
-- API
--==============================================================

function NightShader:SetMode(mode)

    if destroyed then
        return false
    end


    mode =
        string.upper(
            tostring(mode)
        )


    if mode ~= "NIGHT4"
    and mode ~= "HORROR" then

        warn(
            "[NightShader] Modo invalido:",
            mode
        )

        return false

    end


    ----------------------------------------------------------
    -- DETENER SOLO LO QUE DEPENDE DEL MODO ANTERIOR
    ----------------------------------------------------------

    stopStorm()
    removeFogLayers()


    saveOriginals()


    enabled = true
    currentPreset = mode


    createShaderEffects()


    ----------------------------------------------------------
    -- NIGHT4
    ----------------------------------------------------------

    if mode == "NIGHT4" then

        removeCustomSky()

        startProtection()

        applyPreset()

        return true

    end


    ----------------------------------------------------------
    -- HORROR
    ----------------------------------------------------------

    createCustomSky()

    startProtection()

    applyPreset()

    createDenseFog()

    startStorm()


    return true

end


function NightShader:Disable()

    if destroyed then
        return
    end


    disableInternal()

end


function NightShader:GetMode()

    return currentPreset

end


function NightShader:IsEnabled()

    return enabled

end


function NightShader:Destroy()

    if destroyed then
        return
    end


    disableInternal()


    disconnectList(
        permanentConnections
    )


    destroyed = true

end


--==============================================================
-- RESPAWN
--==============================================================

local respawnConnection =

    Player.CharacterAdded:Connect(
        function(character)


            if destroyed
            or not enabled
            or currentPreset ~= "HORROR" then

                return

            end


            local root =
                character:WaitForChild(
                    "HumanoidRootPart",
                    10
                )


            if not root then
                return
            end


            task.wait(0.5)


            if not destroyed
            and enabled
            and currentPreset == "HORROR" then

                createDenseFog()

            end

        end
    )


table.insert(
    permanentConnections,
    respawnConnection
)


--==============================================================
-- DEVOLVER CONTROLADOR
--==============================================================

NightShaderCore = NightShader
return true
end
