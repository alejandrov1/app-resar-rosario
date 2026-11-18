# Revisión visual y pendientes — noviembre 2026

Registro de la revisión visual en un teléfono real y de los pendientes menores que se dejaron para después.

## Revisión en el teléfono

**Dispositivo:** Infinix GT 20 Pro, Android 15, pantalla de 360×812 dp. **Fechas:** 12 y 18 de noviembre de 2026.

Se instaló la versión de release y se revisaron capturas de inicio, menú, misterios del día, rezo, diálogo de salir, lista de recordatorios, formulario y configuración. Las variantes fueron modo claro, modo oscuro, alto contraste claro y letra del sistema al 200 %. Los ajustes del teléfono se restauraron al terminar.

**Resultado:** todos los textos se leen, ningún dato se repite en el rezo y ningún botón parte palabras.

### Problemas encontrados y corregidos

| Problema | Corrección |
|---|---|
| Textos casi blancos sobre fondo claro en casi toda la app | El tema vuelve a dar color a todos los estilos de texto |
| Datos repetidos en cada paso del rezo | Barra de contexto y cuerpo con cada dato una sola vez |
| "Atrás" partía la palabra y los botones del rezo no estaban fijos | Botón cuadrado para retroceder y botones fijos abajo |
| Formulario de recordatorio incómodo y tapado por la barra del teléfono | Formulario a pantalla completa con "Guardar" siempre visible |
| Íconos de la barra de estado invisibles en el inicio claro y en el rezo con alto contraste claro | El color de los íconos se calcula según el fondo real de cada pantalla |
| Franja gris en la barra de navegación del teléfono | Barra transparente, de borde a borde |
| "Comenzar a Rezar" y la píldora del misterio se deformaban con letra grande | Una sola línea que se ajusta al ancho |
| "Ave María · 1 de 10" dejaba el "10" solo en otro renglón | Los contadores ya no se separan |
| Selector de tema y botones de diálogos partían palabras con letra al 200 % | Etiqueta común para botones, siempre en una línea |
| Los 7 días ocupaban dos filas y luego quedaban pegados | Una sola fila, con círculos de 44 dp separados y área de toque de 48 dp |

### Decisiones del usuario

- En modo oscuro, el recuadro de la imagen del rosario usa un blanco suave para no deslumbrar.
- En "¿Salir del rosario?" se destaca "Seguir rezando", que es la opción segura.
- "Comenzar a Rezar" queda fijo abajo en la pantalla de inicio.

## Pendientes menores

- La app reprograma todos los recordatorios en cada arranque en frío, así que el inicio se vuelve un poco más lento al crecer la lista; reprogramar solo cuando cambien la zona horaria, los permisos o los datos.
- La zona horaria se lee una sola vez por proceso: un cambio con la app abierta no se detecta, y el respaldo a UTC es silencioso.
- `showWhenLocked`/`turnScreenOn` en la única actividad: la app se puede usar sobre la pantalla de bloqueo si estaba abierta cuando el teléfono se bloqueó; es lo que recomienda el plugin.
- iOS admite 64 notificaciones pendientes; con 7 por recordatorio, más de 9 recordatorios diarios se pierden; considerar un solo ID con `DateTimeComponents.time` para los diarios.
- Dos cambios rápidos seguidos en la lista de recordatorios pueden mezclar los guardados (`_apply`); se corrige solo en el siguiente arranque.
- `build.gradle.kts`: no se cierra el `FileInputStream`, una clave faltante en `key.properties` da un error poco claro y las rutas relativas de `storeFile` se resuelven desde `android/app`.
- En horizontal, las listas no aplican los márgenes laterales de las muescas de la pantalla.
- Con letra de más de 200 % en teléfonos bajos, la barra del rezo se desplaza junto con la oración; los botones de abajo siempre quedan visibles.
- Revisar en la primera corrida de CI de iOS: `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` y los tamaños de ícono extra; las versiones mínimas de iOS de los plugins; el SDK 36 y el NDK en ubuntu-latest.
