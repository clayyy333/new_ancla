# VR7 ORIGINAL --- Datos del Analyzer

> Referencia basada en las observaciones obtenidas del **VR7 ORIGINAL**
> mediante los analyzers usados durante las pruebas. Los datos
> observados y las inferencias se distinguen; esto no representa el
> código fuente original.

## 1. `BodyVelocity` / `Flinger`

Se observó un `BodyVelocity` dentro del `HumanoidRootPart`:

``` text
Nombre: Flinger
Velocity: (900000000, 900000000, 900000000)
MaxForce: (inf, inf, inf)
P: 1250
```

Al crearse apareció brevemente con valores por defecto:

``` text
Velocity: (0, 2, 0)
MaxForce: (4000, 4000, 4000)
P: 1250
```

Casi inmediatamente pasó a `900000000` XYZ y `inf` XYZ.

## 2. Velocidades máximas observadas

``` text
MaxLocalLinearVelocity ≈ 2,527,354,112
MaxLocalAngularVelocity ≈ 5,456,958,464

MaxTargetLinearVelocity ≈ 12,096.62
MaxTargetAngularVelocity ≈ 24,117.86
```

Aunque `Flinger.Velocity` era 900 millones, el assembly local registró
valores bastante superiores.

## 3. Estado del Humanoid

Durante la ejecución activa se observó principalmente:

``` text
HumanoidState = FallingDown
PlatformStand = false
AutoRotate = true
```

Esto no coincide con reproducciones anteriores que usaban `Physics`,
`PlatformStand=true` y `AutoRotate=false`.

Al finalizar se observó aproximadamente:

``` text
FallingDown → GettingUp → Running
```

## 4. Animaciones y cuerpo

Al inicio aparecieron brevemente `WalkAnim` y `RunAnim`; poco después se
detuvieron. Durante buena parte de la ejecución podía quedar activa una
animación idle.

``` text
PoseSamples = 334
PoseEvents = 19
MaxPoseDelta ≈ 209.829°
MaxLocalAnimations = 4
MaxTargetAnimations = 3
```

El cuerpo no estaba completamente congelado.

## 5. Patrón espacial principal

``` text
NEAR → FAR → RETURN → NEAR
```

Se observaron al menos dos formas de regreso: **directo** y
**escalonado**.

## 6. Regreso directo

Ejemplos:

``` text
~4,487,425 studs → 1.5 studs
~17,003,482 studs → 1.5 studs
~12,572,022 studs → 1.5 studs
```

Tiempo aproximado observado de algunos retornos directos:

``` text
0.007 – 0.012 s
```

No se observó un `FAR_TIME = 0.04` fijo para todos los ciclos.

## 7. Regreso escalonado

Patrón:

``` text
FAR extremo
→ 16.070 studs
→ cientos/miles de studs
→ 1.5 studs
```

Ejemplos:

``` text
7,554,477 → 16.070 → ~549.94 → 1.5
9,193,601 → 16.070 → ~1623 → oscilaciones → 1.5
9,194,745 → 16.070 → ~1203 → oscilaciones → 1.5
```

Se observaron excursiones intermedias aproximadamente entre cientos y
varios miles de studs. No está demostrado que exista una lista fija.

## 8. Significado probable de `16.070`

Geométricamente:

``` text
sqrt(16² + 1.5²) ≈ 16.070158
```

Además, se observaron posiciones relativas compatibles con
`(0,+1.5,+16)` y combinaciones con signos opuestos.

Hipótesis útil:

``` text
(0, +1.5, +16)
(0, +1.5, -16)
(0, -1.5, +16)
(0, -1.5, -16)
```

Esto es una **inferencia geométrica**, no confirmación del código
fuente.

## 9. Distancia NEAR

``` text
MinDistance = 1.499996 studs
```

Se observaron offsets:

``` text
(0, +1.5, 0)
(0, -1.5, 0)
```

Por tanto, ORIGINAL aparecía tanto encima como debajo del target.

## 10. Duración NEAR

Muchos episodios estuvieron aproximadamente en:

``` text
0.05 – 0.06 s
```

Rango práctico observado:

``` text
~0.040 – 0.085 s
```

Máximo:

``` text
LongestNear ≈ 0.086953 s
```

No se observó un dwell fijo de `0.12 s`.

## 11. Rotaciones

Ejemplos registrados:

``` text
(-20, 180, 180)
(-60, 0, 0)
(40, 0, 0)
(40, 180, 180)
```

También aparecieron valores X similares a:

``` text
-80, -60, -40, -20, 0, 20, 40, 60, 80
```

con algunos flips `Y=180`, `Z=180`.

No conocemos la regla exacta de selección de orientación.

## 12. Distancias FAR

``` text
MaxDistance ≈ 21,098,414 studs
LocalBigMoves = 175
LocalExtremeMoves = 220
MaxLocalDelta ≈ 21,098,414
```

Magnitudes aproximadas observadas:

``` text
4.5 millones
7.5 millones
9.2 millones
11 millones
12.5 millones
15 millones
17 millones
21 millones
```

No está demostrado que ORIGINAL tenga una tabla fija con estas cifras.

## 13. Ciclos registrados

En aproximadamente `11.627322 s`:

``` text
NearEntries = 111
NearLeaves = 111
TrackingLost = 111
Recovered = 110
FarEntries = 153
FarLeaves = 153
```

El único `TrackingLost` no recuperado correspondió al apagado. En esa
captura, mientras ORIGINAL permaneció activo, la recuperación fue
extremadamente consistente.

## 14. Overlap

``` text
OverlapEntries = 68
TotalOverlapTime ≈ 5.607902 s
LongestOverlap ≈ 0.465938 s
```

El analyzer medía **bounding-box overlap**, no un `Touched` físico
definitivo. Por tanto, demuestra proximidad/solapamiento espacial, no
causalidad física.

## 15. Target con checkpoint

El target estaba siendo reposicionado continuamente:

``` text
TargetBigMoves = 0
TargetExtremeMoves = 0
MaxTargetDelta ≈ 0.000063
```

Aun así:

``` text
MaxTargetLinearVelocity ≈ 12,096.62
MaxTargetAngularVelocity ≈ 24,117.86
```

Por ello, que el target permaneciera visualmente en su sitio no
significa que no registrara velocidad física transitoria.

## 16. Startup

Secuencia aproximada:

``` text
t ≈ 0.9927
Flinger aparece
→ valores default
→ Velocity = 900,000,000 XYZ
→ MaxForce = inf XYZ
→ t ≈ 1.0015: NEAR a ~1.5
→ WalkAnim / RunAnim brevemente
→ Humanoid = FallingDown
→ Walk / Run se detienen
→ ciclos NEAR/FAR/RETURN
```

## 17. Shutdown

Secuencia observada aproximada:

``` text
ENTER NEAR a 1.5
→ Flinger todavía activo
→ Flinger eliminado
→ sale de NEAR
→ FallingDown → GettingUp
→ GettingUp → Running
→ finaliza seguimiento
```

La relación temporal entre eliminación de `Flinger` y fin del TP **no
demuestra causalidad**. En otras capturas, la eliminación no ocurrió
necesariamente en la misma situación espacial.

## 18. Posible restauración del checkpoint inicial

Distancia local-target inicial:

``` text
~41.28955 studs
```

Después del apagado volvió aproximadamente a:

``` text
~41.29 studs
```

Esto es compatible con una restauración del CFrame/posición inicial del
atacante. Es una **inferencia fuerte**, no una prueba directa del código
fuente.

## 19. Resumen del capture principal

``` text
DURATION
11.627322 s

FRAMES
RenderFrames = 1269
HeartbeatFrames = 1269
RawSamplesStored = 577

TP
NearEntries = 111
NearLeaves = 111
TrackingLost = 111
Recovered = 110
FarEntries = 153
FarLeaves = 153
LongestNear = 0.086953
LongestLost = 1.369902
MinDistance = 1.499996
MaxDistance = 21,098,414
LocalBigMoves = 175
LocalExtremeMoves = 220
MaxLocalDelta = 21,098,414

PHYSICS
MaxLocalLinear = 2,527,354,112
MaxLocalAngular = 5,456,958,464
MaxTargetLinear = 12,096.620117
MaxTargetAngular = 24,117.855469

FLINGER
FlingerCreated = 1
FlingerRemoved = 1
FlingerCreatedAt ≈ 0.9927401
FlingerRemovedAt ≈ 10.256145

BODY
PoseSamples = 334
PoseEvents = 19
MaxPoseDelta = 209.829102
MaxLocalAnimations = 4
MaxTargetAnimations = 3

OVERLAP
OverlapEntries = 68
TotalOverlapTime = 5.607902
LongestOverlap = 0.465938

LIFECYCLE
Character replacements = 0
HRP replacements = 0
ObjectsAdded = 1
ObjectsRemoved = 1
```

## 20. Modelo observable resumido

``` text
START
│
├─ crear Flinger
│    Velocity = 900m XYZ
│    MaxForce = inf XYZ
│    P = 1250
│
├─ Humanoid → FallingDown
│    PlatformStand = false
│    AutoRotate = true
│
└─ iniciar ciclos
     │
     ├─ NEAR
     │    distancia ≈ 1.5
     │    Y = +1.5 o -1.5
     │    orientación variable
     │    ~0.040–0.085 s
     │
     ├─ FAR
     │    millones de studs
     │
     └─ RETURN
          ├─ directo:
          │    FAR → 1.5
          │    ~7–12 ms observados
          │
          └─ escalonado:
               FAR
               → (0, ±1.5, ±16)
               → cientos/miles
               → 1.5

REPETIR

STOP
├─ proceso final de salida
├─ eliminar Flinger
├─ restaurar Humanoid
├─ GettingUp → Running
└─ probable restauración del checkpoint inicial
```

## 21. Datos que más distinguen a VR7 ORIGINAL

1.  `Flinger.Velocity = 900,000,000` XYZ.
2.  `MaxForce = inf` XYZ.
3.  `P = 1250`.
4.  Assembly linear observado por encima de 2.5 mil millones.
5.  Assembly angular observado por encima de 5.4 mil millones.
6.  `FallingDown`.
7.  `PlatformStand = false`.
8.  `AutoRotate = true`.
9.  NEAR extremadamente consistente alrededor de `1.5`.
10. Uso de `+1.5` y `-1.5`.
11. NEAR corto y variable.
12. FAR de millones de studs.
13. Retornos directos muy rápidos.
14. Retornos escalonados.
15. Punto `16.070`, compatible con `(0,±1.5,±16)`.
16. Orientaciones variables.
17. Recuperación consistente mientras está activo.
18. Overlap frecuente.
19. Velocidad transitoria registrada en el target con checkpoint.
20. Restauración progresiva del Humanoid al apagar.
21. Evidencia compatible con restauración de posición inicial.

## 22. Lo que NO conocemos

Los analyzers no permiten afirmar:

-   el código fuente exacto;
-   qué función concreta produce cada cambio de CFrame;
-   si las distancias FAR provienen de una tabla;
-   el porcentaje exacto de retornos directos/escalonados;
-   la regla exacta para escoger `+1.5/-1.5`;
-   la regla exacta para las rotaciones;
-   si `16.070` es constante explícita o consecuencia geométrica;
-   si `BodyVelocity` causa por sí solo todos los saltos;
-   el network ownership interno;
-   decisiones internas del servidor;
-   mecanismos internos del executor;
-   causalidad únicamente a partir de correlaciones temporales.

## 23. Checklist para comparar una reproducción

``` text
A. Flinger
B. estado del Humanoid
C. distancia NEAR
D. signo del offset vertical
E. duración NEAR
F. magnitud FAR
G. tiempo de retorno
H. retorno directo/escalonado
I. punto intermedio
J. orientación
K. velocidad lineal
L. velocidad angular
M. overlap
N. estabilidad de recuperación
O. startup
P. shutdown
Q. restauración del checkpoint
```

Coincidir únicamente en un valor ---por ejemplo
`Velocity = 900000000`--- no implica que el comportamiento completo sea
equivalente a VR7 ORIGINAL.
