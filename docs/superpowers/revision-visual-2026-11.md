# Revisión visual y pendientes — noviembre 2026

La revisión visual en un teléfono real sigue pendiente. Aquí quedan anotados los pendientes menores que se dejaron para después.

## Pendientes menores

- La app reprograma todos los recordatorios en cada arranque en frío, así que el inicio se vuelve un poco más lento al crecer la lista; reprogramar solo cuando cambien la zona horaria, los permisos o los datos.
- La zona horaria se lee una sola vez por proceso: un cambio con la app abierta no se detecta, y el respaldo a UTC es silencioso.
- `showWhenLocked`/`turnScreenOn` en la única actividad: la app se puede usar sobre la pantalla de bloqueo si estaba abierta cuando el teléfono se bloqueó; es lo que recomienda el plugin.
- iOS admite 64 notificaciones pendientes; con 7 por recordatorio, más de 9 recordatorios diarios se pierden; considerar un solo ID con `DateTimeComponents.time` para los diarios.
- Dos cambios rápidos seguidos en la lista de recordatorios pueden mezclar los guardados (`_apply`); se corrige solo en el siguiente arranque.
- `build.gradle.kts`: no se cierra el `FileInputStream`, una clave faltante en `key.properties` da un error poco claro y las rutas relativas de `storeFile` se resuelven desde `android/app`.
- Revisar en la primera corrida de CI de iOS: `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` y los tamaños de ícono extra; las versiones mínimas de iOS de los plugins; el SDK 36 y el NDK en ubuntu-latest.
