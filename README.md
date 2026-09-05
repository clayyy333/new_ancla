# Emotes: version modular local

`main.lua` carga los modulos de `modules/`. No descarga codigo ni consulta la antigua API.

## Uso

- Copia `main.lua` y la carpeta `modules/` al almacenamiento que puede leer tu entorno y ejecuta `main.lua`.
- Si estan dentro de una subcarpeta, configura antes `getgenv().EmotesRootPath = "mi_carpeta"`.
- Si necesitas pegar un unico script, usa **`dist/emotes.lua`**, que incluye todos los modulos y catalogos.

La version modular requiere `readfile`, `loadstring` y `setfenv`. La version generada no necesita leer archivos de modulos. En ambas versiones, conservar datos entre sesiones requiere `readfile`, `isfile` y `writefile`.

## Organizacion

| Ruta | Responsabilidad |
| --- | --- |
| `modules/app.lua` | Crea el contexto privado, precarga los modulos e inicia la aplicacion. |
| `modules/manifest.lua` | Define el orden de inicializacion y los nombres compartidos. |
| `modules/core/` | Servicios, almacenamiento, favoritos, historial, recarga y ciclo de vida. |
| `modules/player/` | Catalogos, emotes, paquetes de animaciones, copia y combinaciones. |
| `modules/ui/` | Idiomas, temas, ventana, tarjetas, ajustes, HUD e informacion del emote. |
| `modules/data/` | Catalogos locales completos, separados de la logica. |

Cada modulo de comportamiento devuelve una funcion `initialize(context)`. Las variables compartidas se guardan en ese contexto mediante `setfenv`; los locales dentro de funciones y bloques siguen siendo privados. Los callbacks consultan el mismo estado, incluso cuando el HUD envuelve las funciones de reproduccion. Un retorno distinto de `true` interrumpe el arranque, por ejemplo si el personaje no admite R15.

Para agregar un modulo, incluyelo en `manifest.order`. Si declaras un nuevo nombre compartido que puede ser `nil`, agregalo tambien a `manifest.sharedNames` para evitar heredar un valor del entorno anfitrion. La recarga crea un contexto nuevo con los modulos precargados; vuelve a ejecutar el archivo de entrada para recoger cambios editados en disco.

## Generar el archivo unico

```powershell
python tools/build.py
```

Edita los archivos de `modules/` y vuelve a generar `dist/emotes.lua`. `dist/` contiene una salida generada, no otra version del codigo que debas mantener manualmente.

Los datos existentes conservan el nombre de archivo anterior para no perder favoritos ni ajustes. Las animaciones y miniaturas siguen usando recursos de Roblox. La sincronizacion por API y las listas continuan fuera de la GUI.

## Verificacion

Con los ejecutables oficiales de Luau disponibles:

```powershell
python tools/test.py --luau "ruta/luau.exe" --compiler "ruta/luau-compile.exe"
```

La suite compila el cargador, los modulos y el archivo generado; valida los catalogos y prueba almacenamiento, reproduccion, velocidad, parada al caminar, HUD, paquetes, aislamiento, recarga y errores de inicializacion con objetos simulados. La apariencia y el comportamiento real de Roblox deben comprobarse dentro del juego.

## Seguir emotes de amigos (experimental)

Abre la pestana **Amigos**, pulsa **Actualizar** y elige **Seguir** junto a un amigo de Roblox que este en el mismo servidor. **Dejar de seguir** cancela el seguimiento. Elegir manualmente un emote, paquete o combinacion tambien lo cancela.

El seguimiento intenta copiar el emote observable, su velocidad y su posicion. Si el amigo deja de bailar, espera al siguiente emote; si abandona el servidor, se detiene. No detecta si el amigo utiliza este script y no envia solicitudes de sincronizacion. Solo funciona con las animaciones que Roblox permite observar desde tu cliente; la coincidencia entre pantallas no esta garantizada.

La logica esta en `modules/player/friend_follow.lua` y el selector en `modules/ui/friend_follow.lua`. No requiere una API externa. Las comprobaciones de amistad utilizan Roblox.
