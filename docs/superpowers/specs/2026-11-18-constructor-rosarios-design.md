# Constructor de rosarios, biblioteca de oraciones y lectura con cámara — Diseño

**Fecha:** 18 de noviembre de 2026 · **Rama:** `constructor-rosarios` (desde `main`, commit `32d0f5f`) · **Estado:** diseño aprobado por el usuario en el chat.

## 1. Objetivo

Permitir que cualquier persona, sin conocimientos técnicos:

1. Empiece el **Rosario tradicional** con un toque, como hoy. Ese rosario nunca se puede modificar.
2. Tenga **varios tipos de rosario**: plantillas incluidas y rosarios propios.
3. **Construya y edite** rosarios: ver sus partes, agregar, quitar y mover oraciones, y crear partes nuevas.
4. Administre una **biblioteca de oraciones**: crear, editar, copiar y compartir.
5. **Lea con la cámara** oraciones impresas y las guarde en la biblioteca.
6. **Comparta** oraciones con otras apps y, en Android, las **reciba** desde otras apps.

## 2. Decisiones del usuario

| Tema | Decisión |
|---|---|
| Rosario tradicional | Base inamovible y protegida, siempre disponible para iniciar rápido |
| Lector de texto | ML Kit de Google, aceptando actualizar la política de privacidad |
| Uso de las oraciones | En todos los rosarios, enviarlas a otras apps y recibirlas desde otras apps |
| Diseño del constructor | Camino de cuentas |
| Plantillas | Divina Misericordia, Siete Dolores de María y Por los difuntos |
| Misterios en rosarios propios | Se eligen en cada parte: del día, grupo fijo, meditaciones propias o ninguno |
| Recibir desde otras apps | Android en esta versión; en iPhone, botón "Pegar" y extensión en una etapa posterior |
| Entrada desde inicio | "Comenzar a Rezar" inicia el tradicional; debajo, "Mis rosarios" |

## 3. Conceptos

Estos nombres son los que ve el usuario y los que usa el código.

- **Oración:** título y texto. Puede venir de la app (protegida) o ser propia.
- **Parte:** un tramo del rosario con nombre, por ejemplo "Oraciones iniciales". Contiene oraciones en orden, y cada una se reza una o varias veces seguidas.
- **Vueltas:** cuántas veces se repite una parte completa. Una decena con misterios tiene 5 vueltas.
- **Rosario:** nombre y lista de partes.
- **Tipos de rosario:** tradicional (protegido), plantilla (protegida) y propio (editable).

## 4. Experiencia de uso

### 4.1 Inicio y menú

- "Comenzar a Rezar" sigue iniciando el Rosario tradicional con un toque.
- Debajo aparece el enlace "Mis rosarios".
- El menú lateral agrega "Mis rosarios" y "Mis oraciones".

### 4.2 Mis rosarios

- Arriba, el **Rosario tradicional** con un candado y el botón "Rezar".
- Luego la sección **Plantillas** y la sección **Mis rosarios**.
- Cada tarjeta muestra el nombre, las partes, el número de pasos y el botón "Rezar".
- Tocar un rosario protegido abre una vista de solo lectura con "Rezar" y "Crear mi versión".
- Tocar un rosario propio abre el constructor.
- El botón "Crear rosario" ofrece "Empezar en blanco" o "Partir de una plantilla o del tradicional".
- Un rosario propio se puede renombrar, duplicar y eliminar. Eliminar pide confirmación.

### 4.3 Constructor: camino de cuentas

Es una columna vertical: una línea une una cuenta por cada parte. Cada parte es una tarjeta que se abre y se cierra.

- **Parte cerrada:** nombre, número de oraciones y vueltas.
- **Parte abierta:** lista de oraciones con su número de veces, y "+ Agregar oración".
- **Acciones de la parte:** renombrar, cambiar vueltas y misterios, duplicar, eliminar y mover.
- **Acciones de la oración:** cambiar las veces (1 a 99), ver, editar si es propia, quitar y mover.
- **Mover:** se puede arrastrar y también usar botones ↑ ↓, que funcionan con lector de pantalla.
- **"+ Agregar parte"** aparece al final del camino.
- **"+ Agregar oración"** abre la biblioteca con búsqueda y permite crear una oración nueva sin salir.
- **Guardado automático:** cada cambio se guarda solo. Al quitar una oración o una parte aparece "Deshacer".
- **"Rezar"** queda siempre visible. Si el rosario no tiene pasos, se desactiva y explica qué falta.

### 4.4 Misterios de una parte

Cada parte tiene el ajuste **"Meditar en cada vuelta"**:

| Opción | Vueltas | Qué se anuncia al empezar cada vuelta |
|---|---|---|
| Ninguno | Las elige el usuario (1 a 20) | Nada |
| Misterios del día | 5, fijas | El misterio que toca ese día |
| Un grupo fijo | 5, fijas | Gozosos, Dolorosos, Gloriosos o Luminosos |
| Mis meditaciones | Una por cada meditación escrita (1 a 20) | La meditación escrita por el usuario |

### 4.5 Mis oraciones

- Lista con búsqueda por título y texto, y filtros "Todas", "De la app" y "Mías".
- Las oraciones de la app aparecen una sola vez aunque se recen en varias partes.
- Una oración de la app se puede ver, copiar y compartir. "Crear mi versión" hace una copia editable.
- **Nueva oración:** tres caminos claros: "Escribir", "Pegar" y "Con la cámara".
- **Editar una oración en uso:** se avisa "Se actualizará en N rosarios".
- **Eliminar una oración en uso:** se muestran los rosarios afectados antes de confirmar.
- Al salir con cambios sin guardar, pregunta "¿Descartar los cambios?".

### 4.6 Leer con la cámara

1. Elegir "Tomar foto" o "Elegir de la galería", con un consejo breve: buena luz y texto recto.
2. La app lee el texto dentro del teléfono y muestra un indicador mientras trabaja.
3. Pantalla de revisión: texto editable, título sugerido (primera línea), "Agregar otra foto" y "Volver a tomar".
4. Solo se guarda cuando el usuario toca "Guardar".

Reglas:

- Nunca se guarda nada sin revisión.
- La foto no se conserva: el archivo temporal se borra después de leerlo.
- Si no se encuentra texto, se explica cómo mejorar la foto y se ofrece reintentar o escribirla a mano.
- La pantalla avisa que el texto impreso se lee mejor que la letra a mano.
- La limpieza del texto une los renglones de un mismo párrafo y las palabras cortadas con guion al final del renglón.

### 4.7 Compartir y recibir

- **Compartir:** abre el menú del sistema con título y texto.
- **Copiar:** copia título y texto y lo confirma con un mensaje.
- **Recibir en Android:** al compartir texto hacia "Santo Rosario" se abre "Nueva oración" con el texto cargado, sin guardar nada hasta que el usuario confirme. Funciona con la app abierta o cerrada.
- **iPhone:** en esta versión se usa "Pegar". La extensión para recibir queda en la etapa 8.

### 4.8 Rezo

Se usa la pantalla de rezo actual para cualquier rosario. La barra muestra el nombre de la parte y su avance. Mientras se reza, los cambios al rosario no afectan al rezo en curso.

## 5. Arquitectura

### 5.1 Modelos

```dart
enum OrigenOracion { app, propia }
enum FormatoOracion { normal, letanias }

class Oracion {
  final String id;              // 'app:ave_maria' o un identificador único
  final String titulo;
  final String texto;
  final OrigenOracion origen;
  final FormatoOracion formato;
}

class ElementoParte {
  final String id;
  final String oracionId;
  final int veces;              // 1 a 99
}

sealed class FuenteMisterios {}
class SinMisterios extends FuenteMisterios { final int vueltas; }
class MisteriosDelDia extends FuenteMisterios {}
class GrupoMisterios extends FuenteMisterios { final TipoMisterio tipo; }
class MeditacionesPropias extends FuenteMisterios { final List<String> textos; }

class ParteRosario {
  final String id;
  final String nombre;
  final List<ElementoParte> elementos;
  final FuenteMisterios misterios;
}

enum TipoRosario { tradicional, plantilla, propio }

class Rosario {
  final String id;
  final String nombre;
  final TipoRosario tipo;
  final List<ParteRosario> partes;
}
```

Todos los modelos son inmutables, con `toJson`, `fromJson` y `copyWith`.

### 5.2 Motor de rezo único

- `construirPasos(Rosario, {required Map<String, Oracion> oraciones, required TipoMisterio tipoDelDia})` reemplaza la función actual.
- `RosarioSession.comenzar` recibe un rosario y fija los pasos y el misterio del día al empezar.
- El color de cada paso se calcula de forma automática: las partes con vueltas usan el color de misterios, las anteriores el de iniciales y las posteriores el de finales.
- **Prueba de regresión obligatoria:** antes de cambiar el motor se guarda la lista actual de 93 pasos, y el Rosario tradicional debe producir exactamente el mismo resultado.

### 5.3 Almacenamiento

- Solo se guarda lo del usuario: oraciones y rosarios propios. Lo protegido vive en el código.
- Archivo JSON versionado en la carpeta de soporte de la app (`path_provider`).
- La escritura es atómica: archivo temporal, copia de respaldo y renombrado.
- Si el archivo está dañado se recupera el respaldo. Si tampoco sirve, se conserva el archivo dañado aparte, la app sigue funcionando y se muestra un aviso.

### 5.4 Límites

| Dato | Máximo |
|---|---|
| Título de oración | 80 caracteres |
| Texto de oración | 10 000 caracteres |
| Nombre de rosario o parte | 60 caracteres |
| Partes por rosario | 30 |
| Oraciones por parte | 50 |
| Veces por oración | 99 |
| Vueltas o meditaciones | 20 |
| Pasos por rosario | 1 000 |

### 5.5 Componentes nuevos

| Componente | Responsabilidad |
|---|---|
| `lib/models/oracion.dart`, `lib/models/rosario.dart` | Modelos y JSON |
| `lib/data/rosario_tradicional.dart`, `lib/data/plantillas_rosario.dart` | Contenido protegido |
| `lib/services/almacen_rosarios.dart` | Lectura y escritura segura del archivo |
| `lib/services/biblioteca_service.dart` | Estado de oraciones y rosarios (`ChangeNotifier`) |
| `lib/services/lector_texto.dart` | Interfaz del lector e implementación con ML Kit |
| `lib/services/selector_imagen.dart` | Interfaz para cámara y galería |
| `lib/services/compartir_texto.dart` | Interfaz para compartir y copiar |
| `lib/services/texto_recibido.dart` | Interfaz para recibir texto en Android |
| `lib/logic/limpieza_texto.dart` | Limpieza pura del texto leído |
| `lib/screens/mis_rosarios_screen.dart` | Lista de rosarios |
| `lib/screens/constructor_rosario_screen.dart` | Camino de cuentas |
| `lib/screens/mis_oraciones_screen.dart`, `lib/screens/oracion_form_screen.dart` | Biblioteca y formulario |
| `lib/screens/leer_oracion_screen.dart` | Cámara y revisión |
| `lib/widgets/camino_cuentas.dart` | Dibujo del camino |

Cámara, lector, compartir y recepción quedan detrás de interfaces, igual que `NotificationsGateway`, para probarlos con dobles.

### 5.6 Dependencias nuevas

`google_mlkit_text_recognition`, `image_picker`, `share_plus`, `path_provider` y `receive_sharing_intent`. La etapa 0 fija las versiones exactas que compilan con Flutter 3.47.9.

## 6. Riesgos que la etapa 0 debe resolver

La etapa 0 es una compuerta: si algo falla, se detiene el plan y se le presentan opciones al usuario.

| Riesgo | Comprobación |
|---|---|
| ML Kit no compila con AGP 9.1 y Kotlin 2.4 | `flutter build appbundle --release` |
| R8 elimina clases de idiomas opcionales de ML Kit | Reglas `-dontwarn` y app abierta en el teléfono |
| Librerías nativas sin páginas de 16 KB, exigidas por Google Play | `zipalign` / `check_elf_alignment` sobre el AAB |
| El proyecto iOS no tiene `Podfile` y ML Kit usa CocoaPods | `flutter build ios --release --no-codesign` en GitHub Actions |
| iOS mínimo sube de 15.0 a 15.5 | Compilación y pruebas de configuración de iOS |
| Crecimiento de la app | Tamaño del AAB antes y después, comparado y anotado |
| Permisos nuevos en Android | Revisar el manifest final de release, incluido `INTERNET` |

## 7. Privacidad y tiendas

- Actualizar `docs/privacidad.md`: la foto y el texto se procesan en el teléfono; ML Kit envía a Google datos técnicos (dispositivo, app y uso de la función); uso de cámara y galería; la app ya no puede afirmar que no se conecta a internet.
- Actualizar `docs/publicacion.md`: formulario de seguridad de datos de Google Play y privacidad de App Store.
- **iOS:** agregar `NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription` en español.
- **Android:** no se declara el permiso `CAMERA`; se usa la cámara del sistema.

## 8. Accesibilidad y diseño

- Se aplican las reglas vigentes: contraste de 4.5:1, toques de 48 dp, ningún botón parte palabras, texto escalado una sola vez y colores solo en `lib/theme/`.
- La auditoría de contraste y la matriz responsiva cubren todas las pantallas nuevas.
- El camino de cuentas es decorativo para el lector de pantalla; cada tarjeta anuncia su nombre, posición y acciones.
- Todo lo que se puede arrastrar tiene una alternativa con botones.
- Dirección visual: pulir el estilo actual con la guía de Frontend Design.

## 9. Plantillas y validación de textos

- Cada plantilla tiene una marca `textosValidados`.
- Las plantillas sin validar solo se muestran en compilaciones de depuración, nunca en release.
- La etapa 4 genera `docs/plantillas-para-validar.md` con todos los textos y su fuente para que el usuario los apruebe.

## 10. Etapas

| # | Etapa | Entrega |
|---|---|---|
| 0 | Viabilidad técnica | Dependencias que compilan en Android e iOS, con mediciones |
| 1 | Motor de datos | Modelos, almacenamiento y motor único; el tradicional queda igual |
| 2 | Mis oraciones | Biblioteca, crear, editar, pegar, copiar y compartir |
| 3 | Mis rosarios y constructor | Camino de cuentas y rezo de rosarios propios |
| 4 | Plantillas | Tres plantillas y documento de validación |
| 5 | Cámara | Foto o galería, lectura, revisión y guardado |
| 6 | Recibir en Android | Texto compartido desde otras apps |
| 7 | Cierre | Pruebas en el teléfono, privacidad, tiendas y revisión final |
| 8 | Recibir en iPhone (posterior) | Extensión; requiere Mac y cuenta de Apple Developer |

Cada etapa deja la app compilando, con las pruebas en verde y utilizable.

## 11. Fuera de alcance

- Sincronización en la nube, cuentas de usuario y compartir rosarios completos.
- Audio o lectura en voz alta.
- Reconocimiento garantizado de letra a mano.
- Vincular recordatorios con un rosario específico.
- Recortar la imagen antes de leerla: el usuario corrige el texto en la revisión.

## 12. Criterios de aceptación

1. "Comenzar a Rezar" produce exactamente los mismos 93 pasos que hoy, y el Rosario tradicional no se puede modificar.
2. Se puede crear un rosario en blanco, agregar partes y oraciones, moverlas con arrastre y con botones, rezarlo completo y encontrarlo igual al reabrir la app.
3. Se puede crear, editar, eliminar, copiar y compartir una oración, con los avisos de uso descritos.
4. Una oración impresa fotografiada se puede revisar, corregir y guardar, y la foto no queda almacenada.
5. En Android, un texto compartido desde otra app abre "Nueva oración" con la app abierta y con la app cerrada.
6. Un archivo de datos dañado no bloquea la app ni afecta al Rosario tradicional.
7. Las plantillas sin validar no aparecen en release.
8. La auditoría de contraste y la matriz responsiva pasan con las pantallas nuevas.
9. `flutter analyze` termina sin avisos, todas las pruebas pasan, y compilan el AAB de Android y la versión de iOS.
10. La política de privacidad y la guía de publicación reflejan el uso de ML Kit, cámara y galería.
11. El usuario revisó el resultado en su teléfono.
