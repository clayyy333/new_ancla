# Backend local del script

Backend independiente para telemetría, estadísticas administrativas y coordinación futura del ancla. En este estado no está conectado a Render ni al código Lua.

## Funciones preparadas

- Registro de usuarios y sesiones.
- Heartbeat con acumulación limitada del tiempo de uso.
- País aproximado, recibido desde un proxy confiable o reportado por el cliente.
- Estado del ancla por sesión.
- Vista general y vista enfocada por `PlaceId + JobId`.
- Observaciones cooperativas de desplazamiento.
- Órdenes seguras para volver al checkpoint local.
- Coordinación del ancla limitada por `GameId + PlaceId` a Metro Life.
- Descubrimiento mínimo de jugadores anclados en el mismo `JobId`.
- Historial de recuperaciones.
- Panel administrativo protegido por token.
- Base SQLite local con WAL.

## Seguridad

El token administrativo nunca debe incluirse en Lua. El script utilizará una clave de ingestión separada y cada ejecución recibirá un token temporal de sesión. Como el cliente controla su ejecutor, la telemetría debe considerarse aproximada y no una prueba de identidad.

El backend nunca envía coordenadas. Una orden de recuperación solamente indica al cliente afectado que ejecute su regreso al checkpoint local si el ancla continúa activa.

## Inicio local

Desde la carpeta `backend`:

1. Crear un entorno virtual.
2. Instalar dependencias:

   `pip install -r requirements.txt`

3. Copiar `.env.example` como `.env` y cambiar ambos tokens.
4. Ejecutar:

   `uvicorn app.main:app --reload --env-file .env`

5. Abrir `http://127.0.0.1:8000`.

## Pruebas

Instalar `requirements-dev.txt` y ejecutar:

`pytest -q`

## Variables importantes

- `ADMIN_TOKEN`: acceso exclusivo al panel.
- `CLIENT_INGEST_KEY`: credencial separada para los clientes Lua.
- `ANCHOR_ALLOWED_GAME_ID`: experiencia autorizada para la vigilancia
  (`4540138978` para Metro Life).
- `ANCHOR_ALLOWED_PLACE_ID`: lugar autorizado para la vigilancia
  (`12985361032` para Metro Life).
- `DATABASE_PATH`: ubicación de SQLite.
- `NETWORK_INFO_ALLOWED_PLACE_IDS`: lista de `PlaceId` autorizados, separados
  por comas. Si queda vacia, los perfiles de red no se almacenan en ningun juego.
- `SESSION_TIMEOUT_SECONDS`: tiempo para considerar una sesión desconectada.
- `ANCHOR_OBSERVER_QUORUM`: observadores necesarios antes de crear una orden.
- `TRUST_PROXY_COUNTRY_HEADER`: acepta `CF-IPCountry` o `X-Country-Code` únicamente cuando el proxy sea confiable.

## Despliegue reemplazando un servicio existente de Render

Este backend puede usar un Web Service existente sin crear otro servicio. En
Render, cambia la fuente del servicio al repositorio `clayyy333/new_ancla`, usa
la rama `main` y configura `backend` como Root Directory.

- Build Command: `pip install -r requirements.txt`
- Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
- Health Check Path: `/health`
- `DATABASE_PATH`: `/tmp/fling-telemetry.db`

El archivo SQLite bajo `/tmp` es deliberadamente efímero: se reinicia cuando
Render suspende, reinicia o vuelve a desplegar el servicio. No se necesita un
disco ni PostgreSQL cuando solo interesa el estado de la ejecución actual.

Cambiar la fuente de un servicio reemplaza la API que ese servicio publicaba
antes. No reutilices secretos del backend anterior; elimina sus variables y
crea valores nuevos para `ADMIN_TOKEN`, `CLIENT_INGEST_KEY` y
`OWNER_PANEL_KEY`.

## Pendiente antes de producción

- Elegir PostgreSQL únicamente si más adelante se necesita persistencia.
- Configurar un dominio y HTTPS.
- Rotar tokens.
- Añadir retención y eliminación de datos.
- Mostrar un aviso de recopilación de estadísticas.
- Crear el módulo Lua de conexión solamente después de probar la API.

## Estado de la conexión Lua

La API cooperativa está preparada, pero deliberadamente aún no está conectada
al script Lua ni a la GUI. Fuera de la pareja autorizada `GameId + PlaceId`, las
rutas del ancla rechazan solicitudes y los heartbeats no pueden marcar una
sesión como anclada.
