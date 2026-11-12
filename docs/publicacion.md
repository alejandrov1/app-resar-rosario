# Publicación de Santo Rosario

## Antes de empezar (lo hace el dueño de la app)

- [ ] Cuenta de Google Play Console (pago único).
- [ ] Cuenta del Apple Developer Program (pago anual).
- [ ] Clave de subida de Android creada y respaldada (ver "Firma de Android" más abajo). Sin ella no se puede actualizar la app.
- [ ] Política de privacidad publicada en una URL: activar GitHub Pages del repositorio y usar la página de `docs/privacidad.md`.

## Firma de Android

1. Crear la clave de subida con un `keytool` de JDK 17 o superior (viene con cualquier JDK, por ejemplo Temurin 21).
   En PowerShell, en una sola línea:

   ```powershell
   keytool -genkeypair -v -keystore C:\ruta\a\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Crear `android/key.properties` (está en `.gitignore`) con estas claves, que son las que lee `android/app/build.gradle.kts`:

   ```properties
   storePassword=…
   keyPassword=…
   keyAlias=upload
   storeFile=C:\\ruta\\a\\upload-keystore.jks
   ```

3. Respaldar el archivo `.jks` y sus contraseñas en un lugar seguro, fuera del repositorio. **Nunca** se suben al repositorio.
   Sin la clave no se puede actualizar la app.

## Google Play

1. Compilar: `flutter build appbundle --release` (con `android/key.properties` presente).
2. Play Console → Crear app → nombre "Santo Rosario", idioma Español (México), app gratuita.
3. Activar **Play App Signing** y subir el `.aab` de `build/app/outputs/bundle/release/`.
4. Ficha de Play Store:
   - Ícono 512 × 512: `android/app/src/main/ic_launcher-playstore.png`.
   - Gráfico de funciones 1024 × 500 y al menos 2 capturas de teléfono (tomarlas en claro y oscuro).
   - Descripción corta y completa.
5. Contenido de la app:
   - Política de privacidad: la URL publicada.
   - Seguridad de los datos: "La app no recopila ni comparte datos".
   - Clasificación de contenido: cuestionario (sin contenido sensible).
   - Público objetivo: todas las edades. Si se eligen edades menores de 13 años, la app entra a la política de Familias de Google Play,
     con requisitos adicionales; si se elige 13 años o más, se evitan.
   - Declaración de **intent de pantalla completa** (`USE_FULL_SCREEN_INTENT`): la usa la opción "Alarma" para que el recordatorio aparezca con el teléfono bloqueado.
   - En Android 14 o superior Play exige esa declaración. Si la rechazan, quitar el permiso `USE_FULL_SCREEN_INTENT` del
     `AndroidManifest.xml` y la opción `fullScreenIntent` en `lib/services/notifications_gateway.dart`; las alarmas se
     mostrarán como notificaciones emergentes (heads-up).
6. Las cuentas personales nuevas deben hacer una **prueba cerrada** antes de producción (Play exige un número mínimo de testers durante un periodo; Play Console indica los requisitos vigentes de la cuenta).
7. Prueba interna → prueba cerrada → producción.
8. Para los testers: desinstalar antes la app anterior (`com.example.app_resar_rosario`). Es otra app distinta y conserva sus propios recordatorios.

## App Store

1. App Store Connect → Apps → Nueva app con el identificador `com.alejandrovaldez.santorosario`.
2. Certificado "Apple Distribution", perfil de aprovisionamiento "App Store" y una clave de API de App Store Connect.
3. Guardar en GitHub (Settings → Secrets and variables → Actions) el certificado `.p12` en base64, su contraseña,
   el perfil en base64 y la clave de API. Después ampliar `.github/workflows/ios.yml` para firmar con
   `flutter build ipa --export-options-plist` y subir a TestFlight.
4. Privacidad de la app: "Datos no recopilados".
5. Capturas de iPhone (6.9" y 6.5"), descripción y palabras clave.
6. Probar en TestFlight: que el recordatorio llegue con la app cerrada y también con la app abierta.
7. Enviar a revisión.
