-- Controlador local de fuegos artificiales integrado; no crea interfaces.
return function(context)
	setfenv(1,context)
	local Lighting = game:GetService("Lighting")--[[
    ============================================================
                      SKY FIREWORKS V3.2.1
    ============================================================

    CORRECCIÓN:
    ✓ El nombre mantiene UN SOLO COLOR.
    ✓ La respiración NO cambia el color.
    ✓ Los destellos sobre las letras mantienen el color del nombre.
    ✓ Los flashes al desprenderse un punto mantienen el color del nombre.
    ✓ SOLO las chispitas/brasas que salen DESPUÉS son multicolor.

    CONSERVA V3.2:
    ✓ Sin Ring.
    ✓ Ritmo más tranquilo.
    ✓ Chispas con vidas variadas.
    ✓ Fuegos de dos colores.
    ✓ Cambio de color en fuegos normales.
    ✓ Explosiones secundarias.
    ✓ Cascadas 3D.
    ✓ Cometas fragmentados.
    ✓ Corazones.
    ✓ Fuego gigante ocasional.
    ✓ Respiración lenta del nombre.
    ✓ Desintegración irregular del nombre.
    ✓ Sin sonido.
]]

----------------------------------------------------------------
-- SERVICIOS
----------------------------------------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- LIMPIAR VERSIONES ANTERIORES
----------------------------------------------------------------

for _, name in ipairs({
    "SkyFireworksV1",
    "SkyFireworksV2",
    "SkyFireworksV21",
    "SkyFireworksV22",
    "SkyFireworksV3",
    "SkyFireworksV31",
    "SkyFireworksV32",
    "SkyFireworksV321"
}) do
    local old = PlayerGui:FindFirstChild(name)

    if old then
        old:Destroy()
    end
end

local oldFolder = workspace:FindFirstChild("__LOCAL_SKY_FIREWORKS")

if oldFolder then
    oldFolder:Destroy()
end

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------

local CONFIG = {
    MEDIUM_MIN_DELAY = 1.8,
    MEDIUM_MAX_DELAY = 3.0,

    FAR_MIN_DELAY = 1.4,
    FAR_MAX_DELAY = 2.5,

    CLOSE_MIN_DELAY = 6.5,
    CLOSE_MAX_DELAY = 10.5,

    SPECIAL_MIN_DELAY = 18,
    SPECIAL_MAX_DELAY = 28,

    FINALE_MIN_DELAY = 42,
    FINALE_MAX_DELAY = 62,

    GIANT_MIN_DELAY = 55,
    GIANT_MAX_DELAY = 85,

    FAR_MIN_DISTANCE = 270,
    FAR_MAX_DISTANCE = 470,

    FAR_MIN_HEIGHT = 125,
    FAR_MAX_HEIGHT = 230,

    MEDIUM_MIN_DISTANCE = 105,
    MEDIUM_MAX_DISTANCE = 235,

    MEDIUM_MIN_HEIGHT = 90,
    MEDIUM_MAX_HEIGHT = 180,

    CLOSE_MIN_DISTANCE = 45,
    CLOSE_MAX_DISTANCE = 80,

    CLOSE_MIN_HEIGHT = 70,
    CLOSE_MAX_HEIGHT = 115,

    NAME_DISTANCE = 125,
    NAME_HEIGHT = 65,

    NAME_VISIBLE_TIME = 10,

    -- Respiración lenta.
    NAME_BREATH_DURATION = 4.0,

    MAX_NAME_LENGTH = 12,
    NAME_MAX_WIDTH = 118,

    NAME_BRIGHT_TRANSPARENCY = 0.025,

    -- No llega a apagarse demasiado.
    NAME_DIM_TRANSPARENCY = 0.48,

    NAME_MAX_BRIGHTNESS = 5.2,
    NAME_MIN_BRIGHTNESS = 1.15,

    NAME_MAX_RANGE = 20,
    NAME_MIN_RANGE = 7,
}

----------------------------------------------------------------
-- ESTADO
----------------------------------------------------------------

local enabled = false
local destroyed = false
local generation = 0
local nameBusy = false

----------------------------------------------------------------
-- CARPETA
----------------------------------------------------------------

local RootFolder = Instance.new("Folder")
RootFolder.Name = "__LOCAL_SKY_FIREWORKS"
RootFolder.Parent = workspace

----------------------------------------------------------------
-- COLORES
----------------------------------------------------------------

local COLORS = {
    Color3.fromRGB(255,55,55),
    Color3.fromRGB(255,100,35),
    Color3.fromRGB(255,210,55),
    Color3.fromRGB(255,245,190),

    Color3.fromRGB(80,255,125),

    Color3.fromRGB(50,220,255),
    Color3.fromRGB(70,125,255),

    Color3.fromRGB(165,70,255),

    Color3.fromRGB(255,65,215),
    Color3.fromRGB(255,110,175)
}

local GOLD = {
    Color3.fromRGB(255,248,205),
    Color3.fromRGB(255,225,120),
    Color3.fromRGB(255,190,60),
    Color3.fromRGB(255,155,35)
}

local HEART_COLORS = {
    Color3.fromRGB(255,45,75),
    Color3.fromRGB(255,70,135),
    Color3.fromRGB(255,105,180),
    Color3.fromRGB(255,40,110)
}

----------------------------------------------------------------
-- ESTA PALETA SOLO SE USA PARA LAS BRASAS DESPRENDIDAS
-- DEL NOMBRE.
----------------------------------------------------------------

local NAME_EMBER_COLORS = {
    Color3.fromRGB(255,245,190),
    Color3.fromRGB(255,185,55),
    Color3.fromRGB(255,255,255),

    Color3.fromRGB(80,220,255),
    Color3.fromRGB(75,125,255),

    Color3.fromRGB(175,80,255),
    Color3.fromRGB(255,70,210),

    Color3.fromRGB(255,65,80),

    Color3.fromRGB(90,255,145),

    Color3.fromRGB(255,120,45)
}

----------------------------------------------------------------
-- COLOR RANDOM
----------------------------------------------------------------

local function randomColor()
    return COLORS[math.random(1,#COLORS)]
end

local function randomGold()
    return GOLD[math.random(1,#GOLD)]
end

local function randomHeart()
    return HEART_COLORS[math.random(1,#HEART_COLORS)]
end

----------------------------------------------------------------
-- COLOR DIFERENTE
----------------------------------------------------------------

local function differentColor(original)
    local selected = randomColor()
    local tries = 0

    while selected == original and tries < 8 do
        selected = randomColor()
        tries += 1
    end

    return selected
end

----------------------------------------------------------------
-- INTERPOLACIÓN COLOR
----------------------------------------------------------------

local function colorLerp(a,b,t)
    return Color3.new(
        a.R + (b.R-a.R)*t,
        a.G + (b.G-a.G)*t,
        a.B + (b.B-a.B)*t
    )
end

----------------------------------------------------------------
-- ROOT
----------------------------------------------------------------

local function getRoot()
    local character = Player.Character

    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
end

----------------------------------------------------------------
-- DIRECCIÓN ESFÉRICA
----------------------------------------------------------------

local function sphereDirection()
    local z = math.random()*2-1
    local a = math.random()*math.pi*2

    local r = math.sqrt(
        math.max(
            0,
            1-z*z
        )
    )

    return Vector3.new(
        r*math.cos(a),
        z,
        r*math.sin(a)
    )
end

----------------------------------------------------------------
-- DIRECCIÓN HORIZONTAL
----------------------------------------------------------------

local function horizontalDirection()
    local a = math.random()*math.pi*2

    return Vector3.new(
        math.cos(a),
        0,
        math.sin(a)
    )
end

----------------------------------------------------------------
-- DURACIÓN NATURAL
----------------------------------------------------------------

local function naturalLife(
    shortMin,
    shortMax,
    mediumMin,
    mediumMax,
    longMin,
    longMax
)

    local chance = math.random()

    if chance < 0.60 then
        return math.random(
            math.floor(shortMin*10),
            math.floor(shortMax*10)
        )/10

    elseif chance < 0.90 then
        return math.random(
            math.floor(mediumMin*10),
            math.floor(mediumMax*10)
        )/10

    else
        return math.random(
            math.floor(longMin*10),
            math.floor(longMax*10)
        )/10
    end
end

----------------------------------------------------------------
-- POSICIÓN CIELO
----------------------------------------------------------------

local function skyPosition(layer)
    local root = getRoot()

    if not root then
        return nil
    end

    local d1,d2,h1,h2

    if layer == "FAR" then
        d1 = CONFIG.FAR_MIN_DISTANCE
        d2 = CONFIG.FAR_MAX_DISTANCE
        h1 = CONFIG.FAR_MIN_HEIGHT
        h2 = CONFIG.FAR_MAX_HEIGHT

    elseif layer == "CLOSE" then
        d1 = CONFIG.CLOSE_MIN_DISTANCE
        d2 = CONFIG.CLOSE_MAX_DISTANCE
        h1 = CONFIG.CLOSE_MIN_HEIGHT
        h2 = CONFIG.CLOSE_MAX_HEIGHT

    else
        d1 = CONFIG.MEDIUM_MIN_DISTANCE
        d2 = CONFIG.MEDIUM_MAX_DISTANCE
        h1 = CONFIG.MEDIUM_MIN_HEIGHT
        h2 = CONFIG.MEDIUM_MAX_HEIGHT
    end

    local distance =
        d1 + math.random()*(d2-d1)

    local height =
        h1 + math.random()*(h2-h1)

    return root.Position
        + horizontalDirection()*distance
        + Vector3.new(0,height,0)
end

----------------------------------------------------------------
-- GLOW
----------------------------------------------------------------

local function glow(position,color,size,parent)
    if destroyed then
        return nil
    end

    local p = Instance.new("Part")

    p.Shape = Enum.PartType.Ball

    p.Size = Vector3.new(
        size,
        size,
        size
    )

    p.Position = position
    p.Material = Enum.Material.Neon
    p.Color = color

    p.Anchored = true

    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false

    p.CastShadow = false

    p.Parent = parent or RootFolder

    return p
end

----------------------------------------------------------------
-- TRAIL
----------------------------------------------------------------

local function makeTrail(part,color,width,lifetime)
    local a0 = Instance.new("Attachment")
    local a1 = Instance.new("Attachment")

    a0.Position = Vector3.new(
        0,
        width/2,
        0
    )

    a1.Position = Vector3.new(
        0,
        -width/2,
        0
    )

    a0.Parent = part
    a1.Parent = part

    local trail = Instance.new("Trail")

    trail.Attachment0 = a0
    trail.Attachment1 = a1

    trail.FaceCamera = true
    trail.LightEmission = 1

    trail.Color = ColorSequence.new(color)

    trail.Lifetime = lifetime
    trail.MinLength = 0.02

    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(0.45,0.72),
        NumberSequenceKeypoint.new(1,0)
    })

    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,0.03),
        NumberSequenceKeypoint.new(0.55,0.25),
        NumberSequenceKeypoint.new(1,1)
    })

    trail.Parent = part

    return trail
end

----------------------------------------------------------------
-- FLASH
----------------------------------------------------------------

local function flash(position,color,scale)
    scale = scale or 1

    local p = glow(
        position,
        Color3.new(1,1,1),
        1.2*scale
    )

    if not p then
        return
    end

    local light = Instance.new("PointLight")

    light.Color = color
    light.Brightness = 10*scale
    light.Range = 28*scale
    light.Parent = p

    TweenService:Create(
        p,
        TweenInfo.new(
            0.20,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ),
        {
            Size = Vector3.new(6,6,6)*scale,
            Transparency = 1
        }
    ):Play()

    TweenService:Create(
        light,
        TweenInfo.new(0.18),
        {
            Brightness = 0,
            Range = 0
        }
    ):Play()

    Debris:AddItem(p,0.25)
end

----------------------------------------------------------------
-- MOTOR CHISPAS
----------------------------------------------------------------

local ActiveSparks = {}

local MAX_ACTIVE_SPARKS = isMobile and 520 or 900

local function addSpark(options)
    if #ActiveSparks >= MAX_ACTIVE_SPARKS then return nil end
    options = options or {}

    local position = options.position

    local color =
        options.color
        or Color3.new(1,1,1)

    local size =
        options.size
        or 0.32

    local p = glow(
        position,
        color,
        size
    )

    if not p then
        return
    end

    local trail

    if options.trail and options.trail > 0 then
        trail = makeTrail(
            p,
            color,
            size,
            options.trail
        )
    end

    table.insert(
        ActiveSparks,
        {
            part = p,

            velocity =
                options.velocity
                or Vector3.zero,

            gravity =
                options.gravity
                or 9,

            drag =
                options.drag
                or 0.2,

            life =
                options.life
                or 4,

            age = 0,

            size = size,

            trail = trail,

            trailLife =
                options.trail
                or 0,

            flicker = options.flicker,

            slowFade = options.slowFade,

            suspend =
                options.suspend
                or 0,

            secondary = options.secondary,
            secondaryDone = false,

            ember = options.ember,
            emberTimer = math.random()*0.2,

            fadeVariation =
                math.random(48,72)/100,

            startColor = color,

            finalColor =
                options.finalColor,

            colorStart =
                options.colorStart
                or math.random(35,58)/100
        }
    )

    return p
end

----------------------------------------------------------------
-- MOTOR CENTRAL
----------------------------------------------------------------

local SparkConnection

SparkConnection = RunService.RenderStepped:Connect(function(dt)

    for i = #ActiveSparks,1,-1 do
        local s = ActiveSparks[i]
        local p = s.part

        if not p or not p.Parent then
            table.remove(ActiveSparks,i)
            continue
        end

        s.age += dt

        local alpha = s.age/s.life

        if alpha >= 1 then
            if s.trail then
                s.trail.Enabled = false
            end

            p:Destroy()

            table.remove(
                ActiveSparks,
                i
            )

            continue
        end

        --------------------------------------------------------
        -- GRAVEDAD
        --------------------------------------------------------

        local gravityScale = 1

        if alpha < s.suspend then
            gravityScale = math.max(
                0.08,
                alpha/
                math.max(
                    s.suspend,
                    0.001
                )
            )
        end

        s.velocity +=
            Vector3.new(
                0,
                -s.gravity*gravityScale,
                0
            )*dt

        --------------------------------------------------------
        -- DRAG
        --------------------------------------------------------

        s.velocity *= math.exp(-s.drag*dt)

        --------------------------------------------------------
        -- POSICIÓN
        --------------------------------------------------------

        p.Position += s.velocity*dt

        --------------------------------------------------------
        -- CAMBIO COLOR DE FUEGOS NORMALES
        --------------------------------------------------------

        if
            s.finalColor
            and
            alpha > s.colorStart
        then

            local colorAlpha = math.clamp(
                (
                    alpha-s.colorStart
                )
                /
                (
                    1-s.colorStart
                ),
                0,
                1
            )

            colorAlpha =
                colorAlpha*
                colorAlpha*
                (3-2*colorAlpha)

            local newColor = colorLerp(
                s.startColor,
                s.finalColor,
                colorAlpha
            )

            p.Color = newColor

            if s.trail then
                s.trail.Color =
                    ColorSequence.new(
                        newColor
                    )
            end
        end

        --------------------------------------------------------
        -- EXPLOSIÓN SECUNDARIA
        --------------------------------------------------------

        if
            s.secondary
            and
            not s.secondaryDone
            and
            alpha > 0.52
        then

            s.secondaryDone = true

            task.spawn(
                s.secondary,
                p.Position
            )
        end

        --------------------------------------------------------
        -- BRASAS
        --------------------------------------------------------

        if s.ember then
            s.emberTimer += dt

            if
                s.emberTimer > 0.15
                and
                alpha < 0.68
            then

                s.emberTimer = 0

                if math.random() < 0.20 then
                    local ember = glow(
                        p.Position,
                        p.Color,
                        s.size*0.30
                    )

                    if ember then
                        TweenService:Create(
                            ember,
                            TweenInfo.new(
                                math.random(25,55)/100
                            ),
                            {
                                Transparency = 1,
                                Size = Vector3.new(
                                    0.03,
                                    0.03,
                                    0.03
                                )
                            }
                        ):Play()

                        Debris:AddItem(
                            ember,
                            0.6
                        )
                    end
                end
            end
        end

        --------------------------------------------------------
        -- FADE
        --------------------------------------------------------

        local fadeStart =
            s.fadeVariation

        if s.slowFade then
            fadeStart = math.min(
                0.78,
                fadeStart+0.08
            )
        end

        local transparency = 0

        if alpha > fadeStart then
            transparency =
                (
                    alpha-fadeStart
                )
                /
                (
                    1-fadeStart
                )

            transparency =
                transparency*
                transparency*
                (3-2*transparency)
        end

        --------------------------------------------------------
        -- FLICKER
        --------------------------------------------------------

        if
            s.flicker
            or
            alpha > 0.80
        then

            local flick = math.max(
                0,
                math.sin(
                    s.age*18+i*0.71
                )
            )

            local strength = math.clamp(
                (alpha-0.55)/0.45,
                0,
                1
            )

            transparency +=
                flick*
                0.20*
                strength
        end

        p.Transparency =
            math.clamp(
                transparency,
                0,
                0.98
            )

        --------------------------------------------------------
        -- TRAIL
        --------------------------------------------------------

        if
            s.trail
            and
            alpha > fadeStart
        then

            local remaining = math.clamp(
                1-
                (
                    (
                        alpha-fadeStart
                    )
                    /
                    (
                        1-fadeStart
                    )
                ),
                0,
                1
            )

            s.trail.Lifetime = math.max(
                0.02,
                s.trailLife*remaining
            )
        end

        --------------------------------------------------------
        -- REDUCIR TAMAÑO FINAL
        --------------------------------------------------------

        if alpha > 0.80 then
            local k = math.max(
                0.08,
                1-
                (
                    (
                        alpha-0.80
                    )
                    /
                    0.20
                )
            )

            p.Size = Vector3.new(
                s.size*k,
                s.size*k,
                s.size*k
            )
        end
    end
end)

----------------------------------------------------------------
-- MINI CRACKLE
----------------------------------------------------------------

local function miniCrackle(position,color)
    color =
        color
        or Color3.new(1,1,1)

    local second =
        differentColor(color)

    flash(
        position,
        color,
        0.22
    )

    for i = 1,math.random(7,12) do
        addSpark({
            position = position,

            velocity =
                sphereDirection()*
                math.random(5,13),

            color =
                i%3 == 0
                and second
                or color,

            finalColor =
                math.random() < 0.35
                and second
                or nil,

            life =
                math.random(8,18)/10,

            size =
                math.random(10,19)/100,

            gravity = 4,
            drag = 0.35,
            trail = 0.05,

            flicker = true
        })
    end
end

----------------------------------------------------------------
-- CRISANTEMO
----------------------------------------------------------------

local function chrysanthemum(position,scale)
    scale = scale or 1

    local outerColor = randomColor()

    local innerColor =
        differentColor(
            outerColor
        )

    flash(
        position,
        outerColor,
        scale
    )

    for i = 1,math.floor(68*scale) do
        local endColor

        if math.random() < 0.38 then
            endColor = innerColor
        end

        addSpark({
            position = position,

            velocity =
                sphereDirection()*
                math.random(28,46)*
                scale,

            color = outerColor,

            finalColor = endColor,

            life = naturalLife(
                2.4,3.2,
                3.3,4.2,
                4.3,5.0
            ),

            size = 0.31*scale,

            gravity = 10,
            drag = 0.24,
            trail = 0.44*scale,
            suspend = 0.18,

            slowFade =
                math.random() < 0.25,

            ember =
                math.random() < 0.18
        })
    end

    for i = 1,math.floor(30*scale) do
        addSpark({
            position = position,

            velocity =
                sphereDirection()*
                math.random(13,25)*
                scale,

            color = innerColor,

            finalColor =
                math.random() < 0.28
                and Color3.new(1,1,1)
                or nil,

            life = naturalLife(
                1.8,2.5,
                2.6,3.2,
                3.3,3.8
            ),

            size = 0.27*scale,

            gravity = 7,
            drag = 0.26,
            trail = 0.18*scale,

            flicker =
                math.random() < 0.20
        })
    end
end

----------------------------------------------------------------
-- PEONÍA
----------------------------------------------------------------

local function peony(position,scale)
    scale = scale or 1

    local outer = randomColor()
    local inner = differentColor(outer)

    flash(
        position,
        outer,
        scale
    )

    for i = 1,math.floor(78*scale) do
        local selectedColor

        if i%4 == 0 then
            selectedColor = inner
        else
            selectedColor = outer
        end

        addSpark({
            position = position,

            velocity =
                sphereDirection()*
                math.random(24,40)*
                scale,

            color = selectedColor,

            finalColor =
                math.random() < 0.30
                and
                (
                    selectedColor == outer
                    and inner
                    or outer
                )
                or nil,

            life = naturalLife(
                2.0,2.7,
                2.8,3.4,
                3.5,4.0
            ),

            size = 0.37*scale,

            gravity = 7,
            drag = 0.19,
            trail = 0.09,
            suspend = 0.20,

            slowFade =
                math.random() < 0.18
        })
    end
end

----------------------------------------------------------------
-- ESTRELLAS
----------------------------------------------------------------

local function stars(position,scale)
    scale = scale or 1

    local mainColor = randomColor()

    local secondColor =
        differentColor(
            mainColor
        )

    flash(
        position,
        mainColor,
        0.9*scale
    )

    for i = 1,math.floor(62*scale) do
        local c

        if i%5 == 0 then
            c = Color3.fromRGB(
                255,
                250,
                220
            )

        elseif i%3 == 0 then
            c = secondColor

        else
            c = mainColor
        end

        addSpark({
            position = position,

            velocity =
                sphereDirection()*
                math.random(16,34)*
                scale,

            color = c,

            finalColor =
                math.random() < 0.28
                and secondColor
                or nil,

            life = naturalLife(
                2.2,3.0,
                3.1,4.0,
                4.1,4.8
            ),

            size = 0.27*scale,

            gravity = 6,
            drag = 0.24,
            trail = 0.10,

            flicker = true,
            suspend = 0.22,

            slowFade =
                math.random() < 0.30
        })
    end
end

----------------------------------------------------------------
-- WILLOW
----------------------------------------------------------------

local function willow(position,scale)
    scale = scale or 1

    local gold = randomGold()
    local finish = randomColor()

    flash(
        position,
        gold,
        1.1*scale
    )

    for i = 1,math.floor(84*scale) do
        local d = sphereDirection()

        d = Vector3.new(
            d.X,
            d.Y*0.52+0.30,
            d.Z
        )

        if d.Magnitude > 0 then
            d = d.Unit
        end

        addSpark({
            position = position,

            velocity =
                d*
                math.random(18,33)*
                scale,

            color = gold,

            finalColor =
                math.random() < 0.22
                and finish
                or nil,

            life = naturalLife(
                3.0,4.1,
                4.2,5.4,
                5.5,6.6
            ),

            size = 0.36*scale,

            gravity = 6.8,
            drag = 0.30,

            trail =
                math.random(65,105)/
                100*
                scale,

            suspend = 0.24,

            slowFade =
                math.random() < 0.45,

            ember =
                math.random() < 0.38
        })
    end
end

----------------------------------------------------------------
-- CASCADA 3D
----------------------------------------------------------------

local function waterfall(position,scale)
    scale = scale or 1

    local gold = randomGold()

    local secondaryColor =
        differentColor(gold)

    flash(
        position,
        gold,
        scale
    )

    for i = 1,math.floor(76*scale) do
        local angle =
            math.random()*
            math.pi*2

        local depth =
            math.random(-85,85)/
            10*
            scale

        local horizontalSpeed =
            math.random(3,12)

        addSpark({
            position =
                position+
                Vector3.new(
                    math.random(-45,45)/10,
                    math.random(-12,12)/10,
                    depth
                ),

            velocity =
                Vector3.new(
                    math.cos(angle)*
                    horizontalSpeed,

                    math.random(4,15),

                    math.sin(angle)*
                    horizontalSpeed+
                    math.random(-35,35)/10
                )*scale,

            color =
                i%7 == 0
                and Color3.new(1,1,1)
                or gold,

            finalColor =
                math.random() < 0.18
                and secondaryColor
                or nil,

            life = naturalLife(
                3.0,4.0,
                4.1,5.5,
                5.6,7.0
            ),

            size = 0.33*scale,

            gravity = 6,
            drag = 0.18,

            trail =
                math.random(65,115)/
                100*
                scale,

            flicker =
                i%6 == 0,

            suspend = 0.12,

            slowFade =
                math.random() < 0.42,

            ember =
                math.random() < 0.40
        })
    end
end

----------------------------------------------------------------
-- CORONA
----------------------------------------------------------------

local function crown(position,scale)
    scale = scale or 1

    local gold = randomGold()
    local tipColor = randomColor()

    flash(
        position,
        gold,
        1.15*scale
    )

    for arm = 1,14 do
        local a =
            (arm/14)*
            math.pi*2

        local base = Vector3.new(
            math.cos(a),
            0.55,
            math.sin(a)
        ).Unit

        for j = 1,5 do
            addSpark({
                position = position,

                velocity =
                    (
                        base+
                        Vector3.new(
                            math.random(-8,8)/100,
                            math.random(-5,5)/100,
                            math.random(-8,8)/100
                        )
                    ).Unit
                    *
                    (18+j*3)
                    *
                    scale,

                color = gold,

                finalColor =
                    j >= 4
                    and tipColor
                    or nil,

                life = naturalLife(
                    2.8,3.8,
                    3.9,4.8,
                    4.9,5.8
                ),

                size = 0.38*scale,

                gravity = 7,
                drag = 0.28,

                trail =
                    math.random(55,95)/
                    100*
                    scale,

                suspend = 0.20,

                slowFade =
                    math.random() < 0.35,

                ember =
                    math.random() < 0.28
            })
        end
    end
end

----------------------------------------------------------------
-- CLUSTER
----------------------------------------------------------------

local function clusterBurst(position,scale)
    scale = scale or 1

    local primary = randomColor()

    local secondary =
        differentColor(primary)

    flash(
        position,
        primary,
        scale
    )

    for i = 1,38 do
        local createSecondary =
            i%6 == 0

        addSpark({
            position = position,

            velocity =
                sphereDirection()*
                math.random(20,38)*
                scale,

            color = primary,

            finalColor =
                math.random() < 0.35
                and secondary
                or nil,

            life = naturalLife(
                2.2,2.9,
                3.0,3.7,
                3.8,4.4
            ),

            size = 0.31*scale,

            gravity = 7,
            drag = 0.22,
            trail = 0.30,

            slowFade =
                math.random() < 0.25,

            secondary =
                createSecondary
                and
                function(p)
                    miniCrackle(
                        p,
                        secondary
                    )
                end
                or nil
        })
    end
end

----------------------------------------------------------------
-- PALMERA
----------------------------------------------------------------

local function palm(position,scale)
    scale = scale or 1

    local gold = randomGold()
    local ends = randomColor()

    flash(
        position,
        gold,
        1.1*scale
    )

    for arm = 1,9 do
        local a =
            (arm/9)*
            math.pi*2

        local direction = Vector3.new(
            math.cos(a),
            math.random(45,75)/100,
            math.sin(a)
        ).Unit

        for branch = 1,5 do
            addSpark({
                position = position,

                velocity =
                    direction*
                    (16+branch*3)*
                    scale,

                color = gold,

                finalColor =
                    branch >= 4
                    and ends
                    or nil,

                life = naturalLife(
                    2.9,3.8,
                    3.9,4.9,
                    5.0,6.0
                ),

                size = 0.40*scale,

                gravity = 7.5,
                drag = 0.27,

                trail =
                    math.random(60,105)/
                    100*
                    scale,

                suspend = 0.22,

                slowFade =
                    math.random() < 0.38,

                ember =
                    math.random() < 0.30
            })
        end
    end
end

----------------------------------------------------------------
-- CORAZÓN
----------------------------------------------------------------

local function heartBurst(position,scale,color)
    scale = scale or 1
    color = color or randomHeart()

    local endColor =
        Color3.fromRGB(
            255,
            175,
            215
        )

    flash(
        position,
        Color3.fromRGB(
            255,
            220,
            230
        ),
        1.1*scale
    )

    local points = 64

    for i = 1,points do
        local t =
            (i/points)*
            math.pi*2

        local x =
            16*
            math.sin(t)^3

        local y =
            13*math.cos(t)
            -5*math.cos(2*t)
            -2*math.cos(3*t)
            -math.cos(4*t)

        local direction =
            Vector3.new(
                x/16,
                y/16,
                0
            )

        addSpark({
            position = position,

            velocity =
                direction*
                25*
                scale,

            color = color,

            finalColor =
                math.random() < 0.30
                and endColor
                or nil,

            life = naturalLife(
                2.8,3.5,
                3.6,4.2,
                4.3,4.8
            ),

            size = 0.40*scale,

            gravity = 3.2,
            drag = 0.24,
            trail = 0.16,

            flicker = true,
            suspend = 0.30,

            slowFade =
                math.random() < 0.40
        })
    end

    task.delay(0.55,function()
        if destroyed then
            return
        end

        for i = 1,18 do
            local t =
                math.random()*
                math.pi*2

            local r =
                math.random(20,75)/100

            local x =
                16*
                math.sin(t)^3/
                16

            local y =
                (
                    13*math.cos(t)
                    -5*math.cos(2*t)
                    -2*math.cos(3*t)
                    -math.cos(4*t)
                )/16

            addSpark({
                position =
                    position+
                    Vector3.new(
                        x*r*15*scale,
                        y*r*15*scale,
                        math.random(-15,15)/10
                    ),

                velocity =
                    Vector3.new(
                        math.random(-3,3),
                        math.random(-1,4),
                        math.random(-2,2)
                    ),

                color =
                    Color3.fromRGB(
                        255,
                        235,
                        245
                    ),

                life =
                    math.random(16,28)/10,

                size = 0.20*scale,

                gravity = 2.5,
                drag = 0.30,

                flicker = true
            })
        end
    end)
end

----------------------------------------------------------------
-- CORAZÓN LLUVIA
----------------------------------------------------------------

local function rainingHeart(position,scale)
    scale = scale or 1

    heartBurst(
        position,
        scale,
        randomHeart()
    )

    task.delay(1.45,function()
        if destroyed then
            return
        end

        for i = 1,32 do
            local c

            if math.random() < 0.35 then
                c = randomHeart()
            else
                c = Color3.fromRGB(
                    255,
                    100,
                    155
                )
            end

            addSpark({
                position =
                    position+
                    Vector3.new(
                        math.random(-110,110)/10*scale,
                        math.random(-20,80)/10*scale,
                        math.random(-35,35)/10
                    ),

                velocity =
                    Vector3.new(
                        math.random(-3,3),
                        math.random(-2,3),
                        math.random(-3,3)
                    ),

                color = c,

                finalColor =
                    math.random() < 0.25
                    and
                    Color3.fromRGB(
                        255,
                        220,
                        235
                    )
                    or nil,

                life = naturalLife(
                    2.0,2.8,
                    2.9,3.8,
                    3.9,4.7
                ),

                size = 0.23*scale,

                gravity = 6,
                drag = 0.25,
                trail = 0.28,

                flicker = true,

                slowFade =
                    math.random() < 0.35
            })
        end
    end)
end

----------------------------------------------------------------
-- DOBLE CORAZÓN
----------------------------------------------------------------

local function doubleHeart(position,scale)
    scale = scale or 1

    heartBurst(
        position+
        Vector3.new(
            -10*scale,
            2,
            0
        ),
        scale*0.75,
        Color3.fromRGB(
            255,
            60,
            100
        )
    )

    task.delay(0.35,function()
        if destroyed then
            return
        end

        heartBurst(
            position+
            Vector3.new(
                11*scale,
                -3,
                0
            ),
            scale*0.70,
            Color3.fromRGB(
                255,
                110,
                190
            )
        )
    end)
end

----------------------------------------------------------------
-- COHETE
----------------------------------------------------------------

local function launchRocket(
    target,
    explosion,
    startOverride
)

    local root = getRoot()

    if not root then
        return
    end

    local launchGeneration =
        generation

    local start =
        startOverride
        or
        Vector3.new(
            target.X+
            math.random(-12,12),

            root.Position.Y+1,

            target.Z+
            math.random(-12,12)
        )

    local rocket = glow(
        start,
        Color3.fromRGB(
            255,
            225,
            160
        ),
        0.44
    )

    if not rocket then
        return
    end

    local trail = makeTrail(
        rocket,
        Color3.fromRGB(
            255,
            175,
            55
        ),
        0.45,
        0.48
    )

    local duration =
        math.random(12,17)/10

    local elapsed = 0

    local connection

    connection =
        RunService.RenderStepped:Connect(
            function(dt)

                if
                    destroyed
                    or
                    not rocket
                    or
                    not rocket.Parent
                then

                    if connection then
                        connection:Disconnect()
                    end

                    if rocket then
                        rocket:Destroy()
                    end

                    return
                end

                elapsed += dt

                local alpha =
                    elapsed/duration

                if alpha >= 1 then
                    connection:Disconnect()

                    local p =
                        rocket.Position

                    trail.Enabled = false
                    rocket:Destroy()

                    if
                        enabled
                        and
                        generation ==
                        launchGeneration
                    then
                        explosion(p)
                    end

                    return
                end

                local eased =
                    1-(1-alpha)^2

                local wobble =
                    Vector3.new(
                        math.sin(alpha*11)*0.45,
                        math.sin(alpha*math.pi)*1.5,
                        math.cos(alpha*9)*0.45
                    )

                rocket.Position =
                    start:Lerp(
                        target,
                        eased
                    )
                    +
                    wobble
            end
        )
end

----------------------------------------------------------------
-- COMETA FRAGMENTADO
----------------------------------------------------------------

local function fragmentedComet()
    local root = getRoot()
    local camera = workspace.CurrentCamera

    if not root or not camera then
        return
    end

    local forward =
        camera.CFrame.LookVector

    forward = Vector3.new(
        forward.X,
        0,
        forward.Z
    )

    if forward.Magnitude < 0.1 then
        return
    end

    forward = forward.Unit

    local right = Vector3.new(
        -forward.Z,
        0,
        forward.X
    )

    local center =
        root.Position
        +
        forward*
        math.random(105,155)
        +
        Vector3.new(
            0,
            math.random(95,135),
            0
        )

    local start =
        root.Position
        +
        forward*25
        +
        right*
        math.random(-25,25)

    launchRocket(
        center,

        function(pos)
            flash(
                pos,
                Color3.new(1,1,1),
                0.8
            )

            local offsets = {
                Vector3.new(-24,7,-5),
                Vector3.new(0,17,6),
                Vector3.new(24,4,-4)
            }

            for index,offset in ipairs(offsets) do
                task.delay(
                    (index-1)*0.16,
                    function()
                        local branchPosition =
                            pos+offset

                        if index == 1 then
                            peony(
                                branchPosition,
                                0.72
                            )

                        elseif index == 2 then
                            stars(
                                branchPosition,
                                0.78
                            )

                        else
                            chrysanthemum(
                                branchPosition,
                                0.72
                            )
                        end
                    end
                )
            end
        end,

        start
    )
end

----------------------------------------------------------------
-- TIPOS NORMALES
----------------------------------------------------------------

local NORMAL_TYPES = {
    chrysanthemum,
    peony,
    stars,
    willow,
    waterfall,
    crown,
    clusterBurst,
    palm
}

----------------------------------------------------------------
-- RANDOM
----------------------------------------------------------------

local function launchRandom(layer)
    local p = skyPosition(layer)

    if not p then
        return
    end

    local effect =
        NORMAL_TYPES[
            math.random(
                1,
                #NORMAL_TYPES
            )
        ]

    local scale = 1

    if layer == "FAR" then
        scale =
            math.random(55,78)/100

    elseif layer == "CLOSE" then
        scale =
            math.random(105,130)/100
    end

    launchRocket(
        p,
        function(pos)
            effect(
                pos,
                scale
            )
        end
    )
end

----------------------------------------------------------------
-- COHETES CRUZADOS
----------------------------------------------------------------

local function crossedRockets()
    local root = getRoot()

    if not root then
        return
    end

    local camera =
        workspace.CurrentCamera

    if not camera then
        return
    end

    local forward =
        camera.CFrame.LookVector

    forward = Vector3.new(
        forward.X,
        0,
        forward.Z
    )

    if forward.Magnitude < 0.1 then
        return
    end

    forward = forward.Unit

    local right = Vector3.new(
        -forward.Z,
        0,
        forward.X
    )

    local center =
        root.Position
        +
        forward*95
        +
        Vector3.new(
            0,
            85,
            0
        )

    local startLeft =
        root.Position+
        right*-38+
        forward*30

    local startRight =
        root.Position+
        right*38+
        forward*30

    launchRocket(
        center+right*18,
        function(p)
            chrysanthemum(p,1)
        end,
        startLeft
    )

    task.delay(0.20,function()
        if enabled and not destroyed then
            launchRocket(
                center-right*18,
                function(p)
                    willow(p,1)
                end,
                startRight
            )
        end
    end)
end

----------------------------------------------------------------
-- ESPECIAL
----------------------------------------------------------------

local function specialShape()
    local p = skyPosition("MEDIUM")

    if not p then
        return
    end

    local r = math.random(1,3)

    if r == 1 then
        launchRocket(
            p,
            function(pos)
                heartBurst(pos,1)
            end
        )

    elseif r == 2 then
        launchRocket(
            p,
            function(pos)
                rainingHeart(pos,1)
            end
        )

    else
        launchRocket(
            p,
            function(pos)
                doubleHeart(pos,1)
            end
        )
    end
end

----------------------------------------------------------------
-- SECUENCIA
----------------------------------------------------------------

local function coordinatedSequence()
    local token = generation
    local p = skyPosition("MEDIUM")

    if not p then
        return
    end

    launchRocket(
        p,
        function(pos)
            stars(pos,1)
        end
    )

    task.wait(0.70)

    if not enabled or generation ~= token then
        return
    end

    launchRocket(
        p+Vector3.new(-38,-5,4),
        function(pos)
            peony(pos,0.9)
        end
    )

    task.wait(0.35)

    if not enabled or generation ~= token then
        return
    end

    launchRocket(
        p+Vector3.new(38,-5,-4),
        function(pos)
            peony(pos,0.9)
        end
    )

    task.wait(1.05)

    if not enabled or generation ~= token then
        return
    end

    launchRocket(
        p+Vector3.new(0,25,0),
        function(pos)
            willow(pos,1.25)
        end
    )
end

----------------------------------------------------------------
-- FUEGO GIGANTE
----------------------------------------------------------------

local function giantFirework()
    local root = getRoot()
    local camera = workspace.CurrentCamera

    if not root or not camera then
        return
    end

    local forward =
        camera.CFrame.LookVector

    forward = Vector3.new(
        forward.X,
        0,
        forward.Z
    )

    if forward.Magnitude < 0.1 then
        forward =
            Vector3.new(
                0,
                0,
                -1
            )
    else
        forward = forward.Unit
    end

    local target =
        root.Position
        +
        forward*155
        +
        Vector3.new(
            0,
            150,
            0
        )

    launchRocket(
        target,
        function(pos)

            flash(
                pos,
                Color3.new(1,1,1),
                1.8
            )

            chrysanthemum(
                pos,
                1.55
            )

            task.delay(0.42,function()
                if destroyed then
                    return
                end

                stars(
                    pos,
                    1.35
                )
            end)

            task.delay(0.90,function()
                if destroyed then
                    return
                end

                waterfall(
                    pos+
                    Vector3.new(
                        0,
                        -3,
                        0
                    ),
                    1.55
                )
            end)
        end
    )
end

----------------------------------------------------------------
-- FINAL
----------------------------------------------------------------

local function finale()
    local token = generation

    for i = 1,4 do
        if not enabled or generation ~= token then
            return
        end

        launchRandom("FAR")
        task.wait(0.52)
    end

    task.wait(0.70)

    for i = 1,3 do
        if not enabled or generation ~= token then
            return
        end

        launchRandom("MEDIUM")
        task.wait(0.58)
    end

    task.wait(0.6)
    fragmentedComet()

    task.wait(0.9)
    crossedRockets()

    task.wait(1.1)
    specialShape()

    task.wait(1.0)

    local p = skyPosition("CLOSE")

    if p then
        launchRocket(
            p,
            function(pos)

                willow(
                    pos,
                    1.35
                )

                task.delay(0.65,function()
                    waterfall(
                        pos,
                        1.25
                    )
                end)
            end
        )
    end
end

----------------------------------------------------------------
-- FONT 5x7
----------------------------------------------------------------

local FONT = {

A={"01110","10001","10001","11111","10001","10001","10001"},
B={"11110","10001","10001","11110","10001","10001","11110"},
C={"01111","10000","10000","10000","10000","10000","01111"},
D={"11110","10001","10001","10001","10001","10001","11110"},
E={"11111","10000","10000","11110","10000","10000","11111"},
F={"11111","10000","10000","11110","10000","10000","10000"},
G={"01111","10000","10000","10111","10001","10001","01111"},
H={"10001","10001","10001","11111","10001","10001","10001"},
I={"11111","00100","00100","00100","00100","00100","11111"},
J={"00111","00010","00010","00010","10010","10010","01100"},
K={"10001","10010","10100","11000","10100","10010","10001"},
L={"10000","10000","10000","10000","10000","10000","11111"},
M={"10001","11011","10101","10101","10001","10001","10001"},
N={"10001","11001","10101","10011","10001","10001","10001"},
O={"01110","10001","10001","10001","10001","10001","01110"},
P={"11110","10001","10001","11110","10000","10000","10000"},
Q={"01110","10001","10001","10001","10101","10010","01101"},
R={"11110","10001","10001","11110","10100","10010","10001"},
S={"01111","10000","10000","01110","00001","00001","11110"},
T={"11111","00100","00100","00100","00100","00100","00100"},
U={"10001","10001","10001","10001","10001","10001","01110"},
V={"10001","10001","10001","10001","10001","01010","00100"},
W={"10001","10001","10001","10101","10101","11011","10001"},
X={"10001","10001","01010","00100","01010","10001","10001"},
Y={"10001","10001","01010","00100","00100","00100","00100"},
Z={"11111","00001","00010","00100","01000","10000","11111"},

["0"]={"01110","10001","10011","10101","11001","10001","01110"},
["1"]={"00100","01100","00100","00100","00100","00100","01110"},
["2"]={"01110","10001","00001","00010","00100","01000","11111"},
["3"]={"11110","00001","00001","01110","00001","00001","11110"},
["4"]={"00010","00110","01010","10010","11111","00010","00010"},
["5"]={"11111","10000","10000","11110","00001","00001","11110"},
["6"]={"01110","10000","10000","11110","10001","10001","01110"},
["7"]={"11111","00001","00010","00100","01000","01000","01000"},
["8"]={"01110","10001","10001","01110","10001","10001","01110"},
["9"]={"01110","10001","10001","01111","00001","00001","01110"}
}

----------------------------------------------------------------
-- SMOOTHSTEP
----------------------------------------------------------------

local function smoothStep(t)
    t = math.clamp(
        t,
        0,
        1
    )

    return t*t*(3-2*t)
end

----------------------------------------------------------------
-- RESPIRACIÓN
----------------------------------------------------------------

local function breathPower(elapsed,offset)
    local cycle =
        (
            elapsed/
            CONFIG.NAME_BREATH_DURATION
            +
            offset
        )%1

    local wave =
        (
            math.cos(
                cycle*
                math.pi*
                2
            )
            +
            1
        )/2

    wave = smoothStep(wave)

    return 0.22 + wave*0.78
end

----------------------------------------------------------------
-- CHISPITA DESPRENDIDA DEL NOMBRE
--
-- AQUÍ SÍ EXISTE VARIACIÓN DE COLOR.
----------------------------------------------------------------

local function dropNameEmber(
    position,
    originalColor,
    stronger
)

    local emberColor

    ------------------------------------------------------------
    -- Algunas mantienen el color original.
    -- La mayoría adquieren otro color.
    ------------------------------------------------------------

    if math.random() < 0.16 then
        emberColor = originalColor
    else
        emberColor =
            NAME_EMBER_COLORS[
                math.random(
                    1,
                    #NAME_EMBER_COLORS
                )
            ]
    end

    local velocityScale =
        stronger
        and 1.45
        or 1

    addSpark({
        position = position,

        velocity =
            Vector3.new(
                math.random(-24,24)/10,
                math.random(-4,12)/10,
                math.random(-18,18)/10
            )*
            velocityScale,

        color = emberColor,

        --------------------------------------------------------
        -- No hacemos otro cambio cromático posterior.
        -- Cada chispa mantiene el color que recibió al salir.
        --------------------------------------------------------

        finalColor = nil,

        life =
            stronger
            and math.random(20,36)/10
            or math.random(16,32)/10,

        size =
            stronger
            and math.random(17,28)/100
            or math.random(13,24)/100,

        gravity = 4.5,
        drag = 0.20,

        trail =
            stronger
            and 0.22
            or 0.16,

        flicker = true,
        slowFade = true
    })
end

----------------------------------------------------------------
-- MOSTRAR NOMBRE
----------------------------------------------------------------

local function showSkyName(text)
    if nameBusy then
        return
    end

    text =
        string.upper(
            tostring(
                text or ""
            )
        )

    text =
        string.sub(
            text,
            1,
            CONFIG.MAX_NAME_LENGTH
        )

    if text == "" then
        return
    end

    local root = getRoot()
    local camera = workspace.CurrentCamera

    if not root or not camera then
        return
    end

    nameBusy = true

    ------------------------------------------------------------
    -- PRELUDIO
    ------------------------------------------------------------

    local PRELUDE = {
        stars,
        peony,
        chrysanthemum,
        stars,
        peony
    }

    for i = 1,5 do
        root = getRoot()
        camera = workspace.CurrentCamera

        if not root or not camera then
            nameBusy = false
            return
        end

        local target =
            root.Position
            +
            camera.CFrame.LookVector*
            (CONFIG.NAME_DISTANCE+15)
            +
            Vector3.new(
                (i-3)*20,
                CONFIG.NAME_HEIGHT+
                math.random(18,38),
                0
            )

        local effect = PRELUDE[i]

        launchRocket(
            target,
            function(pos)
                effect(
                    pos,
                    1
                )
            end
        )

        task.wait(0.28)
    end

    task.wait(2.2)

    root = getRoot()
    camera = workspace.CurrentCamera

    if not root or not camera then
        nameBusy = false
        return
    end

    ------------------------------------------------------------
    -- ORIENTACIÓN
    ------------------------------------------------------------

    local forward =
        camera.CFrame.LookVector

    forward = Vector3.new(
        forward.X,
        0,
        forward.Z
    )

    if forward.Magnitude < 0.1 then
        forward =
            Vector3.new(
                0,
                0,
                -1
            )
    else
        forward = forward.Unit
    end

    local right = Vector3.new(
        -forward.Z,
        0,
        forward.X
    )

    local center =
        root.Position
        +
        forward*
        CONFIG.NAME_DISTANCE
        +
        Vector3.new(
            0,
            CONFIG.NAME_HEIGHT,
            0
        )

    ------------------------------------------------------------
    -- TAMAÑO
    ------------------------------------------------------------

    local spacing = 2.75

    local columns =
        (#text*6)-1

    local width =
        columns*spacing

    if width > CONFIG.NAME_MAX_WIDTH then
        spacing *=
            CONFIG.NAME_MAX_WIDTH/
            width

        width =
            CONFIG.NAME_MAX_WIDTH
    end

    local startX =
        -width/2

    local folder =
        Instance.new("Folder")

    folder.Name =
        "SkyBreathingName"

    folder.Parent =
        RootFolder

    ------------------------------------------------------------
    -- UN SOLO COLOR PARA TODO EL NOMBRE
    ------------------------------------------------------------

    local nameColor =
        randomColor()

    local points = {}

    ------------------------------------------------------------
    -- CREAR LETRAS
    ------------------------------------------------------------

    for charIndex = 1,#text do
        local character =
            string.sub(
                text,
                charIndex,
                charIndex
            )

        local pattern =
            FONT[character]

        if pattern then
            for row = 1,7 do
                for col = 1,5 do

                    if
                        string.sub(
                            pattern[row],
                            col,
                            col
                        ) == "1"
                    then

                        local x =
                            startX
                            +
                            (
                                (charIndex-1)*6
                                +
                                col-1
                            )
                            *
                            spacing

                        local y =
                            (7-row)*
                            spacing

                        local position =
                            center
                            +
                            right*x
                            +
                            Vector3.new(
                                0,
                                y,
                                0
                            )

                        local p = glow(
                            position,
                            nameColor,
                            math.max(
                                0.9,
                                spacing*0.58
                            ),
                            folder
                        )

                        if p then
                            p.Transparency = 1

                            local light =
                                Instance.new(
                                    "PointLight"
                                )

                            light.Color =
                                nameColor

                            light.Brightness = 0
                            light.Range = 2
                            light.Parent = p

                            table.insert(
                                points,
                                {
                                    part = p,
                                    light = light,

                                    offset =
                                        math.random(-15,15)/
                                        1000,

                                    detached = false
                                }
                            )
                        end
                    end
                end
            end
        end
    end

    ------------------------------------------------------------
    -- ENCENDIDO
    ------------------------------------------------------------

    for index,data in ipairs(points) do
        task.delay(
            index*0.004,
            function()

                if
                    data.part
                    and
                    data.part.Parent
                then

                    TweenService:Create(
                        data.part,
                        TweenInfo.new(
                            0.65,
                            Enum.EasingStyle.Quad,
                            Enum.EasingDirection.Out
                        ),
                        {
                            Transparency =
                                CONFIG.NAME_BRIGHT_TRANSPARENCY
                        }
                    ):Play()

                    TweenService:Create(
                        data.light,
                        TweenInfo.new(
                            0.70,
                            Enum.EasingStyle.Quad,
                            Enum.EasingDirection.Out
                        ),
                        {
                            Brightness =
                                CONFIG.NAME_MAX_BRIGHTNESS,

                            Range =
                                CONFIG.NAME_MAX_RANGE
                        }
                    ):Play()
                end
            end
        )
    end

    task.wait(0.85)

    ------------------------------------------------------------
    -- RESPIRACIÓN
    ------------------------------------------------------------

    local started = os.clock()

    local sparkleClock = 0
    local finalSparkClock = 0

    while
        folder.Parent
        and
        os.clock()-started <
        CONFIG.NAME_VISIBLE_TIME
    do

        local dt =
            RunService.RenderStepped:Wait()

        local elapsed =
            os.clock()-started

        local remaining =
            CONFIG.NAME_VISIBLE_TIME-
            elapsed

        local finalWeakness = 1

        if remaining < 1.5 then
            local t =
                math.clamp(
                    remaining/1.5,
                    0,
                    1
                )

            finalWeakness =
                0.55+
                0.45*
                smoothStep(t)
        end

        local averagePower = 0
        local visibleCount = 0

        for _,data in ipairs(points) do
            if
                data.part
                and
                data.part.Parent
                and
                not data.detached
            then

                local power =
                    breathPower(
                        elapsed,
                        data.offset
                    )
                    *
                    finalWeakness

                averagePower += power
                visibleCount += 1

                ------------------------------------------------
                -- SOLO CAMBIA BRILLO/TRANSPARENCIA.
                -- EL COLOR NO SE TOCA.
                ------------------------------------------------

                data.part.Color = nameColor
                data.light.Color = nameColor

                data.part.Transparency =
                    CONFIG.NAME_DIM_TRANSPARENCY
                    +
                    (
                        CONFIG.NAME_BRIGHT_TRANSPARENCY
                        -
                        CONFIG.NAME_DIM_TRANSPARENCY
                    )
                    *
                    power

                data.light.Brightness =
                    CONFIG.NAME_MIN_BRIGHTNESS
                    +
                    (
                        CONFIG.NAME_MAX_BRIGHTNESS
                        -
                        CONFIG.NAME_MIN_BRIGHTNESS
                    )
                    *
                    power^1.3

                data.light.Range =
                    CONFIG.NAME_MIN_RANGE
                    +
                    (
                        CONFIG.NAME_MAX_RANGE
                        -
                        CONFIG.NAME_MIN_RANGE
                    )
                    *
                    power
            end
        end

        if visibleCount > 0 then
            averagePower /=
                visibleCount
        end

        --------------------------------------------------------
        -- DESTELLOS ENCIMA DEL NOMBRE
        --
        -- IMPORTANTE:
        -- SON DEL MISMO COLOR QUE EL NOMBRE.
        --------------------------------------------------------

        sparkleClock += dt

        if
            sparkleClock > 0.18
            and
            averagePower > 0.72
            and
            remaining > 2.6
            and
            #points > 0
        then

            sparkleClock = 0

            for i = 1,math.random(1,3) do
                local data =
                    points[
                        math.random(
                            1,
                            #points
                        )
                    ]

                if
                    data
                    and
                    data.part
                    and
                    data.part.Parent
                    and
                    not data.detached
                then

                    ------------------------------------------------
                    -- MISMO COLOR DEL NOMBRE.
                    ------------------------------------------------

                    local star = glow(
                        data.part.Position,
                        nameColor,
                        data.part.Size.X*0.60,
                        folder
                    )

                    if star then
                        TweenService:Create(
                            star,
                            TweenInfo.new(0.45),
                            {
                                Transparency = 1,
                                Size =
                                    data.part.Size*
                                    2.1
                            }
                        ):Play()

                        Debris:AddItem(
                            star,
                            0.5
                        )
                    end
                end
            end
        end

        --------------------------------------------------------
        -- DESINTEGRACIÓN
        --------------------------------------------------------

        if
            remaining < 2.35
            and
            #points > 0
        then

            local progress =
                math.clamp(
                    (
                        2.35-
                        remaining
                    )
                    /
                    2.35,
                    0,
                    1
                )

            finalSparkClock += dt

            local interval =
                0.14-
                progress*
                0.075

            interval =
                math.max(
                    0.055,
                    interval
                )

            if finalSparkClock > interval then
                finalSparkClock = 0

                local amount =
                    math.random(2,4)

                if progress > 0.55 then
                    amount =
                        math.random(3,6)
                end

                for i = 1,amount do
                    local data =
                        points[
                            math.random(
                                1,
                                #points
                            )
                        ]

                    if
                        data
                        and
                        data.part
                        and
                        data.part.Parent
                    then

                        ------------------------------------------------
                        -- DESTELLO SOBRE LA LETRA:
                        -- MISMO COLOR DEL NOMBRE.
                        ------------------------------------------------

                        local star = glow(
                            data.part.Position,
                            nameColor,
                            math.random(18,30)/10,
                            folder
                        )

                        if star then
                            TweenService:Create(
                                star,
                                TweenInfo.new(
                                    math.random(25,50)/100,
                                    Enum.EasingStyle.Quad,
                                    Enum.EasingDirection.Out
                                ),
                                {
                                    Transparency = 1,

                                    Size =
                                        star.Size*
                                        math.random(16,26)/10
                                }
                            ):Play()

                            Debris:AddItem(
                                star,
                                0.55
                            )
                        end

                        ------------------------------------------------
                        -- ESTA ES LA CHISPITA QUE SALE DESPUÉS.
                        --
                        -- AQUÍ SÍ PUEDE SER ROJA, AZUL,
                        -- VERDE, VIOLETA, DORADA, ETC.
                        ------------------------------------------------

                        if math.random() < 0.42 then
                            dropNameEmber(
                                data.part.Position,
                                nameColor,
                                progress > 0.65
                            )
                        end
                    end
                end
            end

            ----------------------------------------------------
            -- PUNTOS QUE SE DESPRENDEN
            ----------------------------------------------------

            if progress > 0.28 then
                local detachChance =
                    0.002+
                    progress*
                    0.018

                for _,data in ipairs(points) do
                    if
                        not data.detached
                        and
                        data.part
                        and
                        data.part.Parent
                        and
                        math.random() <
                        detachChance
                    then

                        data.detached = true

                        local oldPosition =
                            data.part.Position

                        ------------------------------------------------
                        -- LA BRASA QUE SALE:
                        -- MULTICOLOR.
                        ------------------------------------------------

                        dropNameEmber(
                            oldPosition,
                            nameColor,
                            true
                        )

                        ------------------------------------------------
                        -- FLASH EN LA LETRA:
                        -- MISMO COLOR DEL NOMBRE.
                        ------------------------------------------------

                        local detachedFlash = glow(
                            oldPosition,
                            nameColor,
                            data.part.Size.X*0.8,
                            folder
                        )

                        if detachedFlash then
                            TweenService:Create(
                                detachedFlash,
                                TweenInfo.new(0.35),
                                {
                                    Transparency = 1,

                                    Size =
                                        detachedFlash.Size*
                                        2.5
                                }
                            ):Play()

                            Debris:AddItem(
                                detachedFlash,
                                0.4
                            )
                        end

                        data.light.Brightness = 0
                        data.light.Range = 0

                        data.part.Transparency = 1
                    end
                end
            end
        end
    end

    ------------------------------------------------------------
    -- DESINTEGRACIÓN FINAL
    ------------------------------------------------------------

    local remainingPoints = {}

    for _,data in ipairs(points) do
        if
            data.part
            and
            data.part.Parent
            and
            not data.detached
        then

            table.insert(
                remainingPoints,
                data
            )
        end
    end

    ------------------------------------------------------------
    -- TRES OLEADAS
    ------------------------------------------------------------

    for wave = 1,3 do
        local waveCount =
            math.ceil(
                #remainingPoints/3
            )

        for i = 1,waveCount do
            if #remainingPoints <= 0 then
                break
            end

            local index =
                math.random(
                    1,
                    #remainingPoints
                )

            local data =
                table.remove(
                    remainingPoints,
                    index
                )

            if
                data
                and
                data.part
                and
                data.part.Parent
            then

                data.detached = true

                local pos =
                    data.part.Position

                ------------------------------------------------
                -- CHISPITA DESPRENDIDA:
                -- MULTICOLOR.
                ------------------------------------------------

                if math.random() < 0.70 then
                    dropNameEmber(
                        pos,
                        nameColor,
                        true
                    )
                end

                ------------------------------------------------
                -- DESTELLO EN EL PUNTO ORIGINAL:
                -- MISMO COLOR DEL NOMBRE.
                ------------------------------------------------

                if math.random() < 0.72 then
                    local star = glow(
                        pos,
                        nameColor,
                        math.random(18,32)/10,
                        folder
                    )

                    if star then
                        TweenService:Create(
                            star,
                            TweenInfo.new(
                                math.random(28,52)/100
                            ),
                            {
                                Transparency = 1,

                                Size =
                                    star.Size*
                                    math.random(18,28)/10
                            }
                        ):Play()

                        Debris:AddItem(
                            star,
                            0.6
                        )
                    end
                end

                ------------------------------------------------
                -- APAGAR PUNTO
                ------------------------------------------------

                TweenService:Create(
                    data.part,
                    TweenInfo.new(
                        math.random(35,75)/100,
                        Enum.EasingStyle.Quad,
                        Enum.EasingDirection.In
                    ),
                    {
                        Transparency = 1,

                        Size =
                            data.part.Size*
                            0.15
                    }
                ):Play()

                TweenService:Create(
                    data.light,
                    TweenInfo.new(0.35),
                    {
                        Brightness = 0,
                        Range = 0
                    }
                ):Play()
            end
        end

        task.wait(0.22)
    end

    ------------------------------------------------------------
    -- RESTO
    ------------------------------------------------------------

    for _,data in ipairs(remainingPoints) do
        if
            data.part
            and
            data.part.Parent
        then

            ----------------------------------------------------
            -- LO QUE SE DESPRENDE:
            -- MULTICOLOR.
            ----------------------------------------------------

            dropNameEmber(
                data.part.Position,
                nameColor,
                true
            )

            TweenService:Create(
                data.part,
                TweenInfo.new(0.65),
                {
                    Transparency = 1,

                    Size =
                        data.part.Size*
                        0.15
                }
            ):Play()

            TweenService:Create(
                data.light,
                TweenInfo.new(0.4),
                {
                    Brightness = 0,
                    Range = 0
                }
            ):Play()
        end
    end

    task.wait(1.4)

    if folder then
        folder:Destroy()
    end

    nameBusy = false
end

----------------------------------------------------------------
-- INICIAR
----------------------------------------------------------------

local function startSystem()
    if enabled then
        return
    end

    enabled = true
    generation += 1

    local token = generation

    ------------------------------------------------------------
    -- LEJANOS
    ------------------------------------------------------------

    task.spawn(function()
        while
            enabled
            and
            generation == token
        do

            launchRandom("FAR")

            task.wait(
                CONFIG.FAR_MIN_DELAY
                +
                math.random()*
                (
                    CONFIG.FAR_MAX_DELAY
                    -
                    CONFIG.FAR_MIN_DELAY
                )
            )
        end
    end)

    ------------------------------------------------------------
    -- MEDIOS
    ------------------------------------------------------------

    task.spawn(function()
        task.wait(0.75)

        while
            enabled
            and
            generation == token
        do

            launchRandom("MEDIUM")

            task.wait(
                CONFIG.MEDIUM_MIN_DELAY
                +
                math.random()*
                (
                    CONFIG.MEDIUM_MAX_DELAY
                    -
                    CONFIG.MEDIUM_MIN_DELAY
                )
            )
        end
    end)

    ------------------------------------------------------------
    -- CERCANOS
    ------------------------------------------------------------

    task.spawn(function()
        while
            enabled
            and
            generation == token
        do

            task.wait(
                CONFIG.CLOSE_MIN_DELAY
                +
                math.random()*
                (
                    CONFIG.CLOSE_MAX_DELAY
                    -
                    CONFIG.CLOSE_MIN_DELAY
                )
            )

            if
                enabled
                and
                generation == token
            then

                launchRandom("CLOSE")
            end
        end
    end)

    ------------------------------------------------------------
    -- ESPECIALES
    ------------------------------------------------------------

    task.spawn(function()
        while
            enabled
            and
            generation == token
        do

            task.wait(
                CONFIG.SPECIAL_MIN_DELAY
                +
                math.random()*
                (
                    CONFIG.SPECIAL_MAX_DELAY
                    -
                    CONFIG.SPECIAL_MIN_DELAY
                )
            )

            if
                not enabled
                or
                generation ~= token
            then
                break
            end

            local choice =
                math.random(1,4)

            if choice == 1 then
                specialShape()

            elseif choice == 2 then
                crossedRockets()

            elseif choice == 3 then
                coordinatedSequence()

            else
                fragmentedComet()
            end
        end
    end)

    ------------------------------------------------------------
    -- FINAL
    ------------------------------------------------------------

    task.spawn(function()
        while
            enabled
            and
            generation == token
        do

            task.wait(
                CONFIG.FINALE_MIN_DELAY
                +
                math.random()*
                (
                    CONFIG.FINALE_MAX_DELAY
                    -
                    CONFIG.FINALE_MIN_DELAY
                )
            )

            if
                enabled
                and
                generation == token
            then
                finale()
            end
        end
    end)

    ------------------------------------------------------------
    -- GIGANTE
    ------------------------------------------------------------

    task.spawn(function()
        while
            enabled
            and
            generation == token
        do

            task.wait(
                CONFIG.GIANT_MIN_DELAY
                +
                math.random()*
                (
                    CONFIG.GIANT_MAX_DELAY
                    -
                    CONFIG.GIANT_MIN_DELAY
                )
            )

            if
                enabled
                and
                generation == token
            then

                giantFirework()
            end
        end
    end)
end

----------------------------------------------------------------
-- DETENER
----------------------------------------------------------------

local function stopSystem()
    enabled = false
    generation += 1
    nameBusy = false

    for i = #ActiveSparks,1,-1 do
        local s = ActiveSparks[i]

        if
            s.part
            and
            s.part.Parent
        then

            s.part:Destroy()
        end

        ActiveSparks[i] = nil
    end

    if RootFolder then
        for _,child in ipairs(
            RootFolder:GetChildren()
        ) do

            child:Destroy()
        end
    end
end

----------------------------------------------------------------

local Fireworks = {NameGeneration=0}
local bloom

local function enableBloom()
	if bloom and bloom.Parent then return end
	bloom=Instance.new("BloomEffect")
	bloom.Name="VexroFireworksBloom"
	bloom.Intensity=0.55
	bloom.Size=32
	bloom.Threshold=1.15
	bloom.Parent=Lighting
end

local function disableBloom()
	if bloom then bloom:Destroy();bloom=nil end
end

function Fireworks:Enable()
	if destroyed then return false end
	enableBloom();startSystem();return true
end

function Fireworks:Disable()
	self.NameGeneration+=1
	stopSystem();disableBloom();return true
end

function Fireworks:ShowName(text)
	text=tostring(text or ""):match("^%s*(.-)%s*$")
	if text=="" then return false,"empty_name" end
	if destroyed then return false,"destroyed" end
	self:Enable();self.NameGeneration+=1
	local token=self.NameGeneration
	task.spawn(function()
		task.wait(2)
		if destroyed or not enabled or token~=Fireworks.NameGeneration then return end
		showSkyName(text)
	end)
	return true
end

function Fireworks:IsEnabled() return enabled and not destroyed end

function Fireworks:Destroy()
	if destroyed then return end
	self.NameGeneration+=1;destroyed=true;stopSystem();disableBloom()
	if SparkConnection then SparkConnection:Disconnect();SparkConnection=nil end
	if RootFolder then RootFolder:Destroy();RootFolder=nil end
end

SkyFireworksCore=Fireworks
return true
end