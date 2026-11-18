# Revisión visual y de experiencia de uso — Diseño

**Fecha:** 12 de noviembre de 2026 · **Rama:** `mejora-integral` (PR #1) · **Estado:** aprobado por el usuario en el chat.

**Origen:** las capturas del APK de release en un Infinix GT 20 Pro (Android, letra del sistema agrandada) muestran:
- textos casi blancos sobre fondo claro;
- datos repetidos en el rezo;
- un botón con la palabra partida ("Atrá / s");
- un formulario de recordatorio difícil de usar.

## 1. Objetivo

Que todo texto de la app se lea bien en claro, oscuro y alto contraste. Que cada pantalla muestre cada dato una sola vez. Que nada se corte en ningún teléfono moderno, con letra grande ni en horizontal. Y que crear un recordatorio sea tan fácil como en una app de alarmas.

## 2. Hallazgos

| # | Hallazgo | Evidencia |
|---|---|---|
| H1 | **Todos los estilos de texto del tema quedaron sin color.** `AppTheme._crear` hace `base.textTheme.merge(Typography.englishLike2021)`. Los estilos de `englishLike2021` tienen `inherit: false`, y `TextStyle.merge` devuelve `other` tal cual, sin color. Android pinta en blanco el texto sin color. | Prueba de diagnóstico: `titleLarge`, `bodyLarge` y `headlineSmall` dan `color=null` en el tema claro y en el oscuro. En las capturas se ven en blanco los títulos de diálogos, las oraciones, el texto de los campos, la hora y los títulos de sección. |
| H2 | Las pruebas de contraste existentes comparan los colores del diseño, no el texto dibujado, y no detectaron H1. | `test/theme/*` |
| H3 | **El rezo repite datos.** En el anuncio del misterio, "2/5" sale 3 veces y el nombre del misterio 2. En las oraciones iniciales salen "Oraciones iniciales · 1/3", "Oraciones Iniciales" y "Paso 1 de 3". En el Ave María, el número se repite en la barra, en el título y en las cuentas. | `rezo_screen.dart` (`tituloDelPaso`, `_Encabezado`, `_Contenido`) y `progreso_rosario.dart` |
| H4 | El botón "Atrás" ocupa un tercio de la fila y su palabra se parte con letra grande. | Captura 4 |
| H5 | El botón de inicio se desplaza junto con la oración y se pierde en las oraciones largas. Además, un toque accidental reinicia el rosario sin preguntar. | `paso_oracion_layout.dart` |
| H6 | Formulario de recordatorio: el final queda bajo la barra de navegación del teléfono, "Guardar" solo se ve al final del desplazamiento, los días ocupan 2 renglones y la hora es un texto pequeño. | Captura 3 y `reminder_form.dart` |
| H7 | El misterio del día aparece en la tarjeta de inicio y otra vez en el menú lateral. | `inicio_screen.dart` y `app_drawer.dart` |

## 3. Diseño

### 3.1 Tema y colores

- El tema toma tamaños y colores en el mismo orden que usa Flutter internamente (`ThemeData.localize`): `textTheme: Typography.englishLike2021.merge(base.textTheme)`. Todo estilo del `textTheme` debe tener color (`onSurface` de la variante).
- Se prohíbe en el tema cualquier estilo de texto sin color, y una prueba lo verifica en las 4 variantes.
- **Auditoría de contraste:** una prueba nueva recorre los estados de la sección 3.6 en las 4 variantes (claro, oscuro, claro con alto contraste y oscuro con alto contraste).
  - Para cada texto dibujado (cada `RichText` y cada tramo con su propio estilo), el color efectivo no es nulo.
  - El contraste contra el fondo real es al menos **4.5:1**, o **3:1** en texto grande según WCAG (≥ 24 px, o ≥ 18.66 px en negrita).
  - El fondo real es el relleno más cercano entre los ancestros: `Material`, `Card`, `ColoredBox`, `DecoratedBox` o `Container` con color. Si el fondo es un degradado, cuenta el color del degradado con peor contraste.
  - Quedan fuera los textos de controles deshabilitados.
- Los colores siguen viviendo solo en `lib/theme/`.

### 3.2 Pantalla de rezo

**Estructura**, de arriba abajo:

1. **Barra del rezo (fija, fuera del desplazamiento):**
   - Botón de inicio de 48 dp como mínimo, con información sobre herramientas "Volver al inicio". Al tocarlo abre el diálogo "¿Salir del rosario?", con el texto "Se perderá el avance de este rosario." y los botones [Seguir rezando] y [Salir].
   - Nombre de la sección: "Oraciones iniciales", "Misterios {Tipo}" o "Oraciones finales".
   - Avance de la sección, escrito "{n} de {N}". En las iniciales y las finales es la oración dentro de la sección (p. ej. "1 de 3"). En los misterios es el misterio (p. ej. "2 de 5").
   - Barra con el avance del rosario completo. El lector de pantalla anuncia "Progreso del rosario: {X} por ciento".
2. **Cuerpo (se desplaza):**
   - **Anuncio del misterio:** ícono ✦, el título "{n}.º Misterio {Singular}" (p. ej. "2.º Misterio Luminoso"), el nombre del misterio con el estilo de oración en tamaño destacado y la guía "Medita en este misterio.". Cada dato una vez.
   - **Oraciones dentro de un misterio:**
     - Arriba, una línea pequeña de recordatorio con ✦ y el nombre del misterio, en color de acento.
     - Luego el título de la oración. En el Ave María el título es "Ave María · {r} de 10" y debajo van las cuentas. Las cuentas no repiten el número como texto visible, y su descripción para el lector de pantalla no se suma a la del título.
     - Luego el texto de la oración.
   - **Oraciones iniciales y finales:** el título de la oración y su texto. No se muestra "Paso n de N", porque ya está en la barra.
   - **Letanías:** se quedan como están (`LetaniasWidget`).
3. **Pie fijo:**
   - Botón "paso anterior": cuadrado, delineado, con ícono ‹, información sobre herramientas y semántica "Paso anterior". Su altura es la de los botones (normales o grandes) y su ancho es igual a su altura. No aparece en el primer paso.
   - Botón principal: relleno, ocupa el resto del ancho y dice "Continuar ›", o "Terminar Rosario" en el último paso.
   - Las etiquetas de los botones van en una sola línea. Si no caben, el texto se reduce para entrar (`FittedBox` con `BoxFit.scaleDown`). Nunca se parte una palabra.

**Comportamiento:**
- El botón Atrás del sistema sigue retrocediendo un paso.
- Al pasar de un paso a otro, el cuerpo vuelve arriba.

**Textos de referencia** para las pruebas (índice del paso → lo que se ve):

| Paso | Barra | Cuerpo |
|---|---|---|
| 0 | Oraciones iniciales · 1 de 3 | Señal de la Cruz |
| 3 | Misterios Gozosos · 1 de 5 | 1.º Misterio Gozoso + nombre del misterio |
| 5 | Misterios Gozosos · 1 de 5 | Ave María · 1 de 10 |
| 14 | Misterios Gozosos · 1 de 5 | Ave María · 10 de 10 |
| 19 | Misterios Gozosos · 2 de 5 | 2.º Misterio Gozoso |
| 67 | Misterios Gozosos · 5 de 5 | 5.º Misterio Gozoso |
| 83 | Oraciones finales · 1 de 10 | Letanías de la Santísima Virgen |
| 92 | Oraciones finales · 10 de 10 | Dulce Madre |

En la barra, el nombre de la sección y el avance pueden ir en widgets separados. Las pruebas buscan cada parte por separado.

**Regla de no repetición**, que verifica una prueba en cada uno de los 93 pasos:
- El nombre de la sección se ve exactamente una vez.
- El avance "{n} de {N}" de la sección se ve una vez.
- En los pasos de misterio, el nombre del misterio se ve una vez.
- En los Ave María, "{r} de 10" se ve una vez.

### 3.3 Formulario de recordatorio (pantalla completa)

- Se abre como diálogo de pantalla completa (`MaterialPageRoute(fullscreenDialog: true)`) desde "Mis recordatorios". Devuelve el `RosarioReminder` guardado, o nada si se cancela. La pantalla de lista llama al servicio igual que hoy.
- **Barra superior:**
  - A la izquierda, ✕ con información sobre herramientas "Cerrar".
  - El título "Nuevo recordatorio" o "Editar recordatorio".
  - A la derecha, el botón "Guardar", siempre visible.
- **Al cerrar** con ✕ o con el botón Atrás del sistema, si hubo cambios, aparece el diálogo "¿Descartar los cambios?" con [Seguir editando] y [Descartar].
- **Contenido**, en este orden y dentro del área segura:
  1. *Plantillas* (solo al crear): una fila deslizable de chips. Al tocar una, llena todo el formulario, como hoy.
  2. *Hora*: la etiqueta "Hora" y la hora en grande (`displayMedium`), con el formato de 12 o 24 horas del teléfono. Toda el área se puede tocar, tiene la semántica "Hora: {hora}. Toca para cambiarla" y abre el selector de hora en español.
  3. *Repetir*:
     - 7 botones circulares iguales (L M X J V S D), cada uno con el nombre completo del día como semántica e información sobre herramientas.
     - Si el ancho no da 48 dp por botón, se reparten en 2 filas (4 + 3).
     - Debajo, los atajos "Diario", "Entre semana" y "Fin de semana". Cada atajo se marca cuando la selección coincide exactamente con él.
     - Si no hay días al guardar, sale el error "Elige al menos un día".
  4. *Tipo*: el selector Notificación / Alarma y debajo su explicación.
  5. *Título*: un campo de texto de 50 caracteres como máximo, sin contador visible, con el error "Escribe un título" si queda vacío.
- **Guardar:** valida el formulario. Si algo falta, desplaza la vista hasta el primer error y lo muestra.
- **Teclado:** el contenido se ajusta al teclado (`resizeToAvoidBottomInset`) sin sumar el espacio dos veces.

### 3.4 Lista "Mis recordatorios"

- Los colores quedan corregidos con 3.1.
- Toda la tarjeta se puede tocar para editar, con la semántica "Editar {título}". El interruptor (activar o desactivar), "Editar" y "Eliminar" se quedan como están.
- El último elemento de la lista no queda tapado por el botón "Nuevo".

### 3.5 Inicio y menú

- Se quita "Misterios del día" del menú lateral.
- La tarjeta del misterio del día en inicio se puede tocar y abre el diálogo con los 5 misterios. Muestra el indicador visible "Ver los 5 misterios ›" y tiene la semántica correspondiente.
- **Imagen del rosario:**
  - Su altura se reduce con letra grande o en horizontal.
  - En 360×640 con letra al 100 % y al 150 %, "Comenzar a Rezar" se ve sin desplazar.
  - Con 200 % o más se permite desplazar, según la regla de reflujo de WCAG.

### 3.6 Reglas para cualquier pantalla

**Matriz de pruebas:**
- Tamaños (en dp):
  - 360×640, teléfono pequeño;
  - 411×914, teléfono moderno como el Infinix;
  - 640×360, horizontal;
  - 800×1280, tableta.
- Escala de texto: 1.0, 2.0 y 3.0 (3.0 es el máximo que permite la app).
- Estados que se recorren:
  - inicio;
  - menú abierto;
  - diálogo de misterios;
  - los 93 pasos del rezo;
  - el diálogo de salir;
  - "Mis recordatorios" vacía y con recordatorios activos e inactivos, cada una con los 3 avisos de permisos;
  - formulario nuevo y de edición, con el error de días;
  - configuración;
  - "Acerca de".
- En cada combinación:
  - no hay desbordes (`RenderFlex overflowed`) ni excepciones;
  - en el rezo, los botones del pie quedan completos dentro de la pantalla;
  - en el formulario, "Guardar" queda completo dentro de la pantalla.

**Reglas generales:**
- Áreas táctiles de 48 dp como mínimo, y cada botón con etiqueta (`androidTapTargetGuideline` y `labeledTapTargetGuideline`) en todas las pantallas de la matriz con escala 1.0.
- Ningún botón parte palabras.
- El contenido mide como máximo 600 dp de ancho en tabletas.
- Toda pantalla respeta las áreas seguras de arriba y de abajo.

### 3.7 Validación en el teléfono

Con el teléfono del usuario conectado por USB (depuración USB):
- se instala la versión de release;
- se toman capturas (`adb exec-out screencap`) de las pantallas de 3.6, en claro, en oscuro y con la letra del sistema al máximo.

Las capturas se revisan con la guía de Frontend Design. Las observaciones y los ajustes de gusto que decida el usuario se anotan en `docs/superpowers/revision-visual-2026-11.md`. Las capturas no se suben al repositorio.

## 4. Fuera de alcance

- La lógica de programación de recordatorios: IDs, zona horaria, permisos y canales.
- Dependencias nuevas.
- Cambios en los textos de las oraciones.
- La paleta de colores por sección. Solo se ajusta un tono si la auditoría de contraste lo exige.

## 5. Criterios de aceptación

1. Ningún estilo del tema tiene el color nulo, en las 4 variantes (prueba).
2. La auditoría de contraste pasa en todos los estados de 3.6 en las 4 variantes.
3. El recorrido completo de 93 pasos pasa con los textos de referencia de 3.2, y la regla de no repetición se cumple en cada paso.
4. La matriz de 3.6 no tiene desbordes, y los botones del pie del rezo y "Guardar" del formulario quedan siempre visibles completos.
5. El formulario funciona de punta a punta:
   - crear, editar y cancelar con y sin cambios;
   - plantillas;
   - atajos de días;
   - errores de días y de título.
6. `flutter analyze` termina sin avisos, todas las pruebas pasan y `flutter build appbundle --release` compila.
7. Las capturas en el teléfono del usuario se revisaron, y el usuario aprobó el resultado o se anotaron sus ajustes.

## 6. Archivos afectados

**Código:**
- `lib/theme/app_theme.dart`: H1.
- `lib/screens/rezo_screen.dart`, `lib/widgets/paso_oracion_layout.dart`, `lib/widgets/progreso_rosario.dart` y `lib/widgets/rosary_beads_widget.dart`: 3.2.
- Nuevo `lib/widgets/barra_rezo.dart`, si conviene separarlo: 3.2.
- Nuevo `lib/screens/recordatorio_form_screen.dart`, que reemplaza a `lib/widgets/reminder_form.dart`: 3.3.
- `lib/screens/agendar_rosario_screen.dart`: 3.3 y 3.4.
- `lib/screens/inicio_screen.dart` y `lib/widgets/app_drawer.dart`: 3.5.

**Pruebas:**
- Nuevas: `test/accesibilidad/auditoria_contraste_test.dart` (3.1) y `test/responsivo_test.dart` (3.6), con un ayudante compartido en `test/support/` para recorrer los estados.
- Se actualizan las que dependen de los textos o estructuras que cambian: el recorrido completo, el rezo, el formulario, el menú, el inicio y la prueba de texto grande.

**Documentación:** `docs/superpowers/revision-visual-2026-11.md` (3.7).

Las restricciones globales del plan original siguen vigentes:
- colores solo en `lib/theme/`;
- escalado de texto una sola vez en `MaterialApp.builder`;
- nombres en español para pantallas y widgets;
- sin dependencias nuevas;
- `git push` solo con autorización.
