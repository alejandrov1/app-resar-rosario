# Mejora integral — Fase 6: Verificación final

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Antes de declarar terminada cualquier tarea, aplicar **superpowers:verification-before-completion**.

**Goal:** Demostrar con evidencia que todo funciona: recorrido completo probado, 0 avisos del analizador, cobertura medida, revisión de código sin hallazgos críticos y verificación manual en un teléfono real.

**Architecture:** Sin código nuevo de producción salvo las correcciones que salgan de la revisión.

**Tech Stack:** flutter_test, `flutter test --coverage`, superpowers:requesting-code-review, Graphify.

**Spec:** `docs/superpowers/specs/2026-11-09-mejora-integral-design.md` (§5 Fase 6, §6) · **Índice:** `docs/superpowers/plans/2026-11-09-mejora-integral.md`

## Global Constraints

- Rama `mejora-integral`; cada commit termina con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push`, PR o merge solo con autorización explícita del usuario.
- `flutter analyze` con **0 avisos de cualquier nivel** (incluidos `info`).
- No se relaja ninguna prueba para que pase: se corrige el código.

---

### Task 31: Recorrido completo, cero avisos y cobertura

**Files:**
- Create: `test/recorrido_completo_test.dart`
- Modify: `.gitignore` (agregar `/coverage/`)
- Modify: archivos de `lib/` o `test/` que tengan avisos `info`

**Interfaces:**
- Consumes: `appDePrueba`, `lunes` (Task 15).
- Produces: prueba de punta a punta del rosario; reporte de cobertura por archivo.

- [ ] **Step 1: Escribir la prueba del recorrido completo**

`test/recorrido_completo_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('se reza el rosario completo de principio a fin y se vuelve al inicio', (tester) async {
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();

    // Momentos clave del recorrido: índice del paso → texto que debe verse.
    const hitos = {
      0: 'Oraciones Iniciales',
      3: 'Misterios Gozosos · 1/5',
      5: 'Misterio 1/5 · Ave María 1/10',
      14: 'Misterio 1/5 · Ave María 10/10',
      19: 'Misterios Gozosos · 2/5',
      67: 'Misterios Gozosos · 5/5',
      83: 'Oraciones Finales',
      92: 'Dulce Madre',
    };

    for (var paso = 0; paso < 93; paso++) {
      final esperado = hitos[paso];
      if (esperado != null) {
        expect(find.text(esperado), findsOneWidget, reason: 'paso $paso');
      }
      await tester.tap(find.text(paso == 92 ? 'Terminar Rosario' : 'Continuar'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Comenzar a Rezar'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr la prueba**

Run: `flutter test test/recorrido_completo_test.dart`
Expected: `All tests passed!`. Si falla un hito, el mensaje dice qué paso: se corrige el código (no la prueba), salvo que el hito esté mal contado (comprobar con `construirPasos()[n]`).

- [ ] **Step 3: Dejar el analizador en cero**

Run: `flutter analyze`
Expected final: `No issues found!`. Corregir cada aviso `info` restante (p. ej. `prefer_const_constructors` → agregar `const`; `deprecated_member_use` → usar la API indicada en el mensaje). Repetir hasta `No issues found!`.

- [ ] **Step 4: Medir la cobertura**

Agregar `/coverage/` al final de `.gitignore`.

Run: `flutter test --coverage`

Run:

```bash
python - <<'EOF'
import collections
total, cubiertas = collections.Counter(), collections.Counter()
archivo = None
for linea in open('coverage/lcov.info', encoding='utf-8'):
    if linea.startswith('SF:'):
        ruta = linea[3:].strip().replace('\\', '/')
        archivo = ruta[ruta.find('lib/'):]
    elif linea.startswith('DA:'):
        total[archivo] += 1
        cubiertas[archivo] += int(linea.split(',')[1]) > 0
for f in sorted(total):
    print(f"{100 * cubiertas[f] / total[f]:5.1f}%  {f}")
EOF
```

Expected — mínimos por archivo:

| Archivo | Mínimo |
|---|---|
| `lib/logic/rosario_session.dart` | 95 % |
| `lib/services/schedule_calculator.dart` | 100 % |
| `lib/services/notification_service.dart` | 90 % |
| `lib/services/preferences_service.dart` | 95 % |
| `lib/models/reminder_model.dart` | 90 % |
| `lib/widgets/letanias_widget.dart` | 90 % |

`lib/services/notifications_gateway.dart` (la parte `FlutterNotificationsGateway`) y `lib/main.dart` quedan fuera: hablan con el sistema operativo y se verifican a mano en la Task 33. Si un archivo de la tabla queda abajo del mínimo, agregar la prueba que falta para la rama sin cubrir que muestra el reporte.

- [ ] **Step 5: Commit**

```bash
git add test/recorrido_completo_test.dart .gitignore lib test
git commit -m "test: recorrido completo del rosario y analizador en cero" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 32: Revisión de código de toda la rama

**Files:**
- Modify: los que indique la revisión

**Interfaces:**
- Consumes: diferencia `main...mejora-integral`.
- Produces: hallazgos críticos e importantes corregidos y registrados.

- [ ] **Step 1: Pedir la revisión**

Aplicar **superpowers:requesting-code-review** sobre `git diff main...mejora-integral`, pasando como requisitos el spec (`docs/superpowers/specs/2026-11-09-mejora-integral-design.md`) y este plan. Pedir que revise en especial: programación de recordatorios (IDs, zona horaria, permisos, migración), escalado de texto, contraste, manifest y manejo de secretos.

- [ ] **Step 2: Atender los hallazgos**

Aplicar **superpowers:receiving-code-review**: verificar cada hallazgo antes de aceptarlo. Los críticos e importantes se corrigen (cada uno con su prueba si es un error de comportamiento, y su commit `fix: …`). Los menores se corrigen si son baratos o se anotan en `docs/superpowers/revision-visual-2026-11.md` bajo "Pendientes menores".

- [ ] **Step 3: Verificar**

Run: `flutter analyze && flutter test && flutter build appbundle --release`
Expected: `No issues found!`; `All tests passed!`; `.aab` compila.

---

### Task 33: Verificación manual en un teléfono real y cierre de la rama

**Files:**
- Create: `docs/verificacion-manual.md`

**Interfaces:**
- Consumes: app de release firmada (Task 27); usuario con un teléfono Android.
- Produces: registro de la verificación manual; rama lista para integrar.

- [ ] **Step 1: Instalar la compilación de release**

Run: `flutter build apk --release && flutter install --release`
Expected: la app se instala y abre.

- [ ] **Step 2: Recorrer la lista con el usuario y registrar el resultado**

`docs/verificacion-manual.md`, con el resultado (✅/❌ y nota) de cada punto:

```markdown
# Verificación manual — Santo Rosario (release)

Dispositivo: <modelo y versión de Android del teléfono usado> · Fecha: <fecha de la prueba>

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
```

Los campos de dispositivo y fecha se llenan con los datos reales de la prueba. Cada ❌ se trata con **superpowers:systematic-debugging**, se corrige con su prueba automática cuando sea posible y se vuelve a verificar ese punto.

- [ ] **Step 3: Actualizar el grafo y comparar con el inicio**

Run: `graphify update . && graphify path "RosarioSession" "NotificationService"`
Expected: la ruta pasa por `SantoRosarioApp` (donde se registran ambos proveedores).

Run: `grep -n "notification_service\|notifications_gateway" lib/logic/*.dart lib/screens/rezo_screen.dart`
Expected: sin coincidencias (el rezo no depende de los recordatorios).

Anotar en `docs/verificacion-manual.md` el número de nodos y comunidades que reporta `graphify-out/GRAPH_REPORT.md` (al inicio eran 786 nodos y 47 comunidades, contando las plataformas que se eliminaron).

- [ ] **Step 4: Commit**

```bash
git add docs/verificacion-manual.md
git commit -m "docs: verificación manual de la versión de release" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 5: Cerrar la rama**

Aplicar **superpowers:finishing-a-development-branch**: presentar al usuario las opciones (abrir PR hacia `main`, merge local o dejar la rama) y ejecutar **solo** la que elija. Cualquier `push` o PR requiere su autorización explícita.

**Cierre del proyecto:** criterios de la sección 5 del spec cumplidos y con evidencia (pruebas, analizador, workflows, verificación manual).
