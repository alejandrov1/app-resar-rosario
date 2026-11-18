# Viabilidad en Android del constructor de rosarios (noviembre 2026)

Resultado de la compuerta de la Tarea 1: las dependencias del lector de texto, compartir y almacenamiento compilan y funcionan en Android.

## Versiones resueltas

| Paquete | Versión |
| --- | --- |
| google_mlkit_text_recognition | 1.0.3 |
| image_picker | 1.2.4 |
| share_plus | 13.3.1 |
| path_provider | 2.1.6 |
| receive_sharing_intent | 1.9.0 |

`flutter pub add` los resolvió sin conflictos.

## Tamaño del AAB de release

| Momento | Bytes | MB |
| --- | --- | --- |
| Antes de las dependencias | 57139176 | 54.5 |
| Después (con reglas de R8 finales) | 71747025 | 68.4 |
| Diferencia | 14607849 | 13.9 |

## Páginas de 16 KB

Se revisaron las 10 librerías nativas `.so` de `lib/arm64-v8a` y `lib/x86_64` del APK de release. Resultado: `SIN PROBLEMAS`.

## Permisos del manifest final

`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `VIBRATE`, `WAKE_LOCK`, `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (propio de la app), `ACCESS_NETWORK_STATE` e `INTERNET`.

`CAMERA` **no aparece**, así que no fue necesario quitarlo del manifest. `INTERNET` y `ACCESS_NETWORK_STATE` son los que agrega ML Kit.

## Cambios de compilación

- `compileSdk` subió de 36 a 37 porque `receive_sharing_intent` 1.9.0 lo exige (`checkReleaseAarMetadata` falló con 36).
- Se agregó `android/app/proguard-rules.pro` con `-dontwarn` para los modelos de idiomas opcionales de ML Kit (chino, devanagari, japonés, coreano) y se enlazó en `release`.

## Hallazgo de R8

- **Síntoma:** en la app de prueba de release, el lector fallaba con `NullPointerException` dentro de ML Kit. Solo ocurría en release.
- **Causa:** R8 quitaba los constructores sin argumentos de las tres clases `ComponentRegistrar` de ML Kit, que se instancian por reflexión. Queda confirmada por el resultado: el lector falló sin la regla y funcionó con ella.
- **Solución:** en `proguard-rules.pro`:

```proguard
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
```

## Prueba en el teléfono

Teléfono Infinix X6871, Android 15 (API 35), app de prueba en release.

- La cámara abrió y el lector devolvió 576 caracteres.
- Acentos y eñe correctos (Señora, lágrimas, María, Jesús).
- Errores menores de reconocimiento: "miseicordiosos" por "misericordiosos", "iDios" por "¡Dios" e "ioh" por "¡oh".
- El texto fotografiado parece venir de una pantalla y no de papel, porque la salida incluye "video/7273..." y "Buscar". La prueba con papel impreso sigue sin hacerse.

Después de borrar la app de prueba se reinstaló la app real con `adb install -r` (sin desinstalar) y arrancó sin fallos.
