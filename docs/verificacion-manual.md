# Verificación manual — Santo Rosario (release)

Dispositivo: _pendiente_ · Fecha: _pendiente_

Versión probada: 1.0.0 (1), paquete `com.alejandrovaldez.santorosario`, APK de release firmado con la clave de subida.

## Antes de empezar

1. Desinstalar la app vieja (`com.example.app_resar_rosario`) si está en el teléfono. Es otra app y sigue mandando sus propios avisos.
2. Copiar el APK al teléfono, abrirlo y permitir "Instalar apps desconocidas" para la app desde la que se abre (Archivos, Drive, etc.). Si Play Protect avisa, elegir "Instalar de todas formas".
3. Abrir la app una vez y entrar a "Agendar Rosario" para conceder los permisos.

## Pruebas

Marcar ✅ o ❌ y anotar lo que se vio.

| # | Prueba | Resultado |
|---|---|---|
| 1 | Recordatorio tipo Notificación a +2 min con la app cerrada: llega a la hora local exacta (±1 min) con el ícono de la cruz | |
| 2 | Recordatorio tipo Alarma a +2 min con el teléfono bloqueado: suena el sonido de alarma y aparece en pantalla completa | |
| 3 | Reiniciar el teléfono con un recordatorio activo: vuelve a sonar en su siguiente horario | |
| 4 | Quitar "Alarmas y recordatorios" en Ajustes: la app muestra el aviso y el recordatorio llega igual (con posible retraso) | |
| 5 | Quitar el permiso de notificaciones: la app lo avisa y "Permitir notificaciones" abre los ajustes | |
| 6 | Texto al 200 %, alto contraste y tema oscuro; cerrar y abrir la app: se conservan | |
| 7 | Rosario completo; el botón Atrás del sistema retrocede un paso; letanías con respuestas resaltadas | |
| 8 | El selector de hora y los diálogos están en español | |
| 9 | "Acerca de" muestra la versión y "Ver licencias" incluye Lora | |
| 10 | Editar un recordatorio cambiando los días: solo suena en los días nuevos | |
| 11 | Con un aviso del rosario visible en la barra de notificaciones, abrir la app: el aviso sigue ahí | |
| 12 | Rosario en horizontal con texto al 200 %: nada se corta y "Continuar" siempre se puede tocar | |

Cada ❌ se analiza, se corrige con su prueba automática cuando sea posible y se vuelve a verificar ese punto.

## Verificación automática al cerrar la rama (12 de noviembre de 2026)

- `flutter analyze`: sin avisos. `flutter test`: 165 pruebas pasan.
- GitHub Actions en la rama `mejora-integral`: CI (análisis, pruebas y `.aab`) ✅ y iOS (compilación sin firma) ✅.
- `.aab` y APK de release firmados con la clave de subida (no con la de depuración).
- Grafo del proyecto (Graphify): 919 nodos y 130 comunidades. Al inicio eran 786 nodos y 47 comunidades, contando las plataformas que se eliminaron.
- El rezo no depende de los recordatorios: `lib/logic/` y `rezo_screen.dart` no importan nada de notificaciones.
