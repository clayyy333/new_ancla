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
- `DATABASE_PATH`: ubicación de SQLite.
- `SESSION_TIMEOUT_SECONDS`: tiempo para considerar una sesión desconectada.
- `ANCHOR_OBSERVER_QUORUM`: observadores necesarios antes de crear una orden.
- `TRUST_PROXY_COUNTRY_HEADER`: acepta `CF-IPCountry` o `X-Country-Code` únicamente cuando el proxy sea confiable.

## Pendiente antes de producción

- Elegir PostgreSQL para persistencia duradera en Render.
- Configurar un dominio y HTTPS.
- Rotar tokens.
- Añadir retención y eliminación de datos.
- Mostrar un aviso de recopilación de estadísticas.
- Crear el módulo Lua de conexión solamente después de probar la API.
