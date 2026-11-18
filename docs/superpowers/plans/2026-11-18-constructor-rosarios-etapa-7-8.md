# Constructor de rosarios — Etapas 7 y 8: cierre y recibir texto en iPhone

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. La Task 20 la hace el controlador con el usuario. **La Task 21 no se ejecuta** sin una Mac y una cuenta de Apple Developer.

**Goal:** Dejar la documentación de privacidad y tiendas al día, comprobar todo en un teléfono real y cerrar la rama.

**Architecture:** Sin código nuevo de producción, salvo las correcciones que salgan de las pruebas en el teléfono y de la revisión final.

**Tech Stack:** adb, GitHub Actions, superpowers:requesting-code-review, frontend-design:frontend-design, Graphify.

**Spec:** `docs/superpowers/specs/2026-11-18-constructor-rosarios-design.md` · **Índice:** `docs/superpowers/plans/2026-11-18-constructor-rosarios.md`

## Global Constraints

Se aplican todas las del índice, incluida la sección "Reglas aprendidas en este proyecto".

---

### Task 19: Política de privacidad y guía de publicación

**Files:**
- Modify: `docs/privacidad.md`, `docs/publicacion.md`, `README.md`
- Test: `test/plataforma/documentos_test.dart`

**Interfaces:**
- Consumes: la lista de permisos anotada en `docs/superpowers/viabilidad-constructor-2026-11.md` (Task 1).

- [ ] **Step 1: Escribir la prueba**

`test/plataforma/documentos_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final privacidad = File('docs/privacidad.md').readAsStringSync();
  final publicacion = File('docs/publicacion.md').readAsStringSync();

  test('la política ya no promete que la app no usa internet', () {
    expect(privacidad, isNot(contains('la app no se conecta a internet')));
  });

  test('la política explica la cámara, las fotos y ML Kit', () {
    for (final tema in ['cámara', 'galería', 'ML Kit', 'no se guarda', 'Google']) {
      expect(privacidad, contains(tema), reason: tema);
    }
  });

  test('la guía de publicación cubre la seguridad de datos de las tiendas', () {
    for (final tema in ['Seguridad de los datos', 'ML Kit', 'App Privacy']) {
      expect(publicacion, contains(tema), reason: tema);
    }
  });
}
```

- [ ] **Step 2: Ver que falla**

Run: `flutter test test/plataforma/documentos_test.dart`
Expected: FAIL.

- [ ] **Step 3: Actualizar la política de privacidad**

Reemplazar `docs/privacidad.md` completo. En "Vigente desde", escribir la fecha real del cambio:

```markdown
# Política de privacidad — Santo Rosario

Vigente desde el <fecha del cambio>.

**Santo Rosario no pide cuentas, no muestra anuncios y no vende ni comparte tus datos personales.**

- **Qué guarda la app:** tus preferencias (tamaño de texto, contraste, botones, tema), tus recordatorios, y las oraciones y rosarios que crees. Todo se guarda en tu teléfono y la app no lo envía a ningún servidor. Si tienes activada la copia de seguridad de tu teléfono (Google en Android, iCloud en iPhone), esa copia puede incluir estos datos; se administra desde los ajustes de tu cuenta de Google o de Apple, no desde la app.
- **Cámara y galería:** solo se usan cuando eliges leer una oración con una foto. La foto se procesa dentro de tu teléfono, no se envía a ningún servidor y no se guarda: se borra en cuanto se lee el texto.
- **Lectura de texto (ML Kit de Google):** para leer las oraciones la app usa ML Kit, un componente de Google que funciona dentro del teléfono. Ni la foto ni el texto leído salen de tu teléfono. ML Kit sí envía a Google datos técnicos para diagnóstico y estadísticas de uso de esa función: información del dispositivo (fabricante, modelo y versión del sistema) y de la app (nombre del paquete y versión). Más información en https://developers.google.com/ml-kit/android-data-disclosure.
- **Compartir:** una oración solo se envía a otra app cuando tú tocas "Compartir" y eliges esa app.
- **Permisos:** las notificaciones y las alarmas se usan únicamente para avisarte a la hora de rezar que tú elegiste.
- **Publicidad y análisis:** la app no tiene anuncios ni herramientas propias de análisis o rastreo.
- **Menores:** la app es apta para todo público y no pide datos a nadie.

Si tienes dudas, abre un reporte en https://github.com/alejandrov1/app-resar-rosario/issues
```

- [ ] **Step 4: Actualizar la guía de publicación**

Agregar en `docs/publicacion.md` esta sección antes del final:

```markdown
## Datos que declarar por la cámara y ML Kit

**Google Play, formulario "Seguridad de los datos":**

- La app recopila, a través de ML Kit, información del dispositivo y de la app para diagnóstico y análisis.
- Esos datos se cifran en tránsito y no se comparten con terceros.
- Las fotos y el texto leído se procesan solo en el teléfono: no se declaran como recopilados.
- Antes de enviar el formulario, comprobar la información vigente en https://developers.google.com/ml-kit/android-data-disclosure.

**App Store, sección "App Privacy":**

- Declarar los datos de diagnóstico que correspondan a ML Kit, según la documentación vigente de Google.
- Incluir el archivo de privacidad de los paquetes y revisar las advertencias que muestre App Store Connect al subir la compilación.

**Publicar la política actualizada** (`docs/privacidad.md`) antes de enviar la nueva versión a revisión.
```

En `README.md`, agregar a la lista de funciones: rosarios personalizados, biblioteca de oraciones, lectura de oraciones impresas con la cámara y compartir oraciones.

- [ ] **Step 5: Ver que pasa y guardar**

Run: `flutter test test/plataforma/documentos_test.dart`
Expected: `All tests passed!`.

```bash
git add docs/privacidad.md docs/publicacion.md README.md test/plataforma/documentos_test.dart
git commit -m "docs: privacidad y publicación con cámara, ML Kit y oraciones propias"
```

---

### Task 20: Verificación en el teléfono, revisión final y cierre

La hace el controlador con el usuario.

**Files:**
- Create: `docs/verificacion-constructor.md`

- [ ] **Step 1: Revisión final de toda la rama**

Aplicar **superpowers:requesting-code-review** sobre `git diff main...constructor-rosarios`, en el modelo más capaz, pasando el spec y este plan. Pedir atención especial a:
- protección del Rosario tradicional y de las plantillas;
- pérdida de datos en el archivo del usuario;
- que la foto siempre se borre;
- semántica de los botones nuevos;
- `singleTask` y los recordatorios existentes.

Aplicar **superpowers:receiving-code-review**: verificar cada hallazgo contra el código antes de aceptarlo. Corregir los críticos e importantes, cada uno con su prueba.

- [ ] **Step 2: Instalar la versión de release**

Run: `flutter build apk --release`
Run: `adb install -r build/app/outputs/flutter-apk/app-release.apk`

- [ ] **Step 3: Recorrer la lista con el usuario**

Crear `docs/verificacion-constructor.md` con el dispositivo, la fecha y el resultado (✅/❌ y nota) de cada punto:

```markdown
# Verificación manual — Constructor de rosarios

Dispositivo: <modelo y versión de Android> · Fecha: <fecha de la prueba>

| # | Prueba | Resultado |
|---|---|---|
| 1 | "Comenzar a Rezar" inicia el tradicional con un toque y se reza completo | |
| 2 | El tradicional no se puede editar desde ninguna pantalla | |
| 3 | Crear un rosario en blanco, agregar partes y oraciones, moverlas arrastrando y con el menú | |
| 4 | Cerrar la app por completo, volver a abrirla y encontrar el rosario igual | |
| 5 | Rezar un rosario propio con misterios del día, con un grupo fijo y con meditaciones propias | |
| 6 | Quitar una oración y usar "Deshacer" | |
| 7 | Crear, editar, copiar, compartir y eliminar una oración propia | |
| 8 | Pegar un texto copiado de otra app | |
| 9 | Leer con la cámara una oración impresa, corregirla y guardarla | |
| 10 | Elegir una foto de la galería y agregar una segunda foto a la misma oración | |
| 11 | Fotografiar algo sin texto: la app explica qué hacer | |
| 12 | Compartir hacia "Santo Rosario" desde otra app, con la app cerrada y abierta | |
| 13 | Modo oscuro, alto contraste y letra al 200 % en las pantallas nuevas | |
| 14 | Una alarma programada sigue sonando y abriendo la app | |
```

Revisar las capturas con **frontend-design:frontend-design**. Cada ❌ se analiza con **superpowers:systematic-debugging**, se corrige con su prueba y se vuelve a verificar.

- [ ] **Step 4: Verificación final**

Run: `flutter analyze`
Run: `flutter test`
Run: `flutter build appbundle --release`
Expected: `No issues found!`, `All tests passed!` y el `.aab` firmado.

Run: `graphify update .`

```bash
git add docs/verificacion-constructor.md
git commit -m "docs: verificación manual del constructor de rosarios"
```

- [ ] **Step 5: Subir y cerrar la rama**

Con la autorización del usuario, subir la rama y confirmar que los flujos "CI" e "iOS" terminan en verde. Luego aplicar **superpowers:finishing-a-development-branch** y ejecutar solo la opción que elija el usuario.

---

### Task 21: Recibir texto en iPhone (posterior)

**No ejecutar** hasta que el usuario confirme que tiene una Mac con Xcode, una cuenta de Apple Developer y un iPhone para probar. Sin eso no se puede configurar ni comprobar una extensión de iOS.

**Files:**
- Create: extensión `ShareExtension` en `ios/`
- Modify: `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`, `lib/services/texto_recibido.dart`
- Test: `test/plataforma/ios_config_test.dart`

**Interfaces:**
- Consumes: `TextoRecibido`, `TextoRecibidoSistema`.

- [ ] **Step 1: Leer la guía del paquete**

Abrir la sección de iOS del README de `receive_sharing_intent` en la versión fijada en `pubspec.lock` y seguir sus pasos si difieren de los de esta tarea.

- [ ] **Step 2: Crear la extensión en Xcode**

En `ios/Runner.xcworkspace`: **File → New → Target → Share Extension**, nombre `ShareExtension`, mínimo iOS 15.5, sin activar el esquema.

Reemplazar `ios/ShareExtension/ShareViewController.swift`:

```swift
import receive_sharing_intent

class ShareViewController: RSIShareViewController {
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
```

- [ ] **Step 3: Configurar el grupo de la app**

En **Signing & Capabilities** de `Runner` y de `ShareExtension`, agregar **App Groups** con `group.com.alejandrovaldez.santorosario`.

- [ ] **Step 4: Declarar el tipo de contenido**

En `ios/ShareExtension/Info.plist`, dentro de `NSExtension`:

```xml
<key>NSExtensionAttributes</key>
<dict>
    <key>NSExtensionActivationRule</key>
    <dict>
        <key>NSExtensionActivationSupportsText</key>
        <true/>
    </dict>
</dict>
```

En `ios/Runner/Info.plist`, agregar el esquema de URL que pide el paquete:

```xml
<key>AppGroupId</key>
<string>group.com.alejandrovaldez.santorosario</string>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)</string>
        </array>
    </dict>
</array>
```

- [ ] **Step 5: Activar la recepción en iPhone**

En `lib/services/texto_recibido.dart`, reemplazar `_disponible` por:

```dart
  bool get _disponible =>
      defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
```

Y actualizar el comentario de la clase: "Funciona en Android y en iPhone".

Agregar en `test/plataforma/ios_config_test.dart`:

```dart
  test('recibe texto compartido desde otras apps', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains('group.com.alejandrovaldez.santorosario'));
    expect(plist, contains(r'ShareMedia-$(PRODUCT_BUNDLE_IDENTIFIER)'));
  });
```

- [ ] **Step 6: Probar en un iPhone real y guardar**

Probar compartir texto desde Notas y Safari con la app cerrada y abierta. Confirmar que se abre "Nueva oración" sin guardar nada.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

```bash
git add ios lib/services/texto_recibido.dart test/plataforma/ios_config_test.dart
git commit -m "feat: recibir en iPhone oraciones compartidas desde otras apps"
```
