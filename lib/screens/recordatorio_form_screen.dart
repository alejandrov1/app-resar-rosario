import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/reminder_model.dart';
import '../theme/app_tokens.dart';

const _diasSemana = [
  (1, 'L', 'Lunes'),
  (2, 'M', 'Martes'),
  (3, 'X', 'Miércoles'),
  (4, 'J', 'Jueves'),
  (5, 'V', 'Viernes'),
  (6, 'S', 'Sábado'),
  (7, 'D', 'Domingo'),
];

const _atajos = <(String, Set<int>)>[
  ('Diario', {1, 2, 3, 4, 5, 6, 7}),
  ('Entre semana', {1, 2, 3, 4, 5}),
  ('Fin de semana', {6, 7}),
];

/// Crear o editar un recordatorio a pantalla completa. Devuelve el recordatorio guardado, o `null` si se cierra.
class RecordatorioFormScreen extends StatefulWidget {
  const RecordatorioFormScreen({super.key, this.recordatorio});

  final RosarioReminder? recordatorio;

  static Future<RosarioReminder?> abrir(BuildContext context, {RosarioReminder? recordatorio}) {
    return Navigator.of(context).push<RosarioReminder>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => RecordatorioFormScreen(recordatorio: recordatorio),
    ));
  }

  @override
  State<RecordatorioFormScreen> createState() => _RecordatorioFormScreenState();
}

/// Lo que se puede editar, para saber si hubo cambios.
@immutable
class _Valores {
  const _Valores(this.titulo, this.hora, this.dias, this.tipo, this.descripcion);

  final String titulo;
  final TimeOfDay hora;
  final Set<int> dias;
  final ReminderType tipo;
  final String descripcion;

  @override
  bool operator ==(Object other) =>
      other is _Valores &&
      other.titulo == titulo &&
      other.hora == hora &&
      setEquals(other.dias, dias) &&
      other.tipo == tipo &&
      other.descripcion == descripcion;

  @override
  int get hashCode => Object.hash(titulo, hora, Object.hashAllUnordered(dias), tipo, descripcion);
}

class _RecordatorioFormScreenState extends State<RecordatorioFormScreen> {
  final _formulario = GlobalKey<FormState>();
  final _claveDias = GlobalKey();
  final _claveTitulo = GlobalKey();
  late final TextEditingController _titulo =
      TextEditingController(text: widget.recordatorio?.title ?? 'Rezar el Santo Rosario');
  late TimeOfDay _hora = widget.recordatorio?.time ?? const TimeOfDay(hour: 19, minute: 0);
  late final Set<int> _dias = {...?widget.recordatorio?.daysOfWeek};
  late ReminderType _tipo = widget.recordatorio?.type ?? ReminderType.notification;
  late String _descripcion = widget.recordatorio?.description ?? 'Es hora de tu oración. El Señor está contigo.';
  late final _Valores _inicial;
  bool _faltanDias = false;

  /// Ya se guardó o se confirmó el descarte: se puede cerrar sin preguntar.
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    _inicial = _valores();
    _titulo.addListener(_redibujar);
  }

  @override
  void dispose() {
    _titulo
      ..removeListener(_redibujar)
      ..dispose();
    super.dispose();
  }

  void _redibujar() => setState(() {});

  _Valores _valores() => _Valores(_titulo.text, _hora, {..._dias}, _tipo, _descripcion);

  bool get _hayCambios => _valores() != _inicial;

  Future<void> _elegirHora() async {
    final hora = await showTimePicker(context: context, initialTime: _hora);
    if (hora != null) setState(() => _hora = hora);
  }

  void _aplicar(ReminderTemplate plantilla) {
    HapticFeedback.selectionClick();
    setState(() {
      _titulo.text = plantilla.title;
      _descripcion = plantilla.description;
      _hora = plantilla.time;
      _dias
        ..clear()
        ..addAll(plantilla.daysOfWeek);
      _tipo = plantilla.type;
      _faltanDias = false;
    });
  }

  void _cambiarDias(Set<int> dias) => setState(() {
        _dias
          ..clear()
          ..addAll(dias);
        _faltanDias = false;
      });

  void _guardar() {
    final tituloValido = _formulario.currentState!.validate();
    setState(() => _faltanDias = _dias.isEmpty);
    if (_dias.isEmpty || !tituloValido) {
      HapticFeedback.heavyImpact();
      final clave = _dias.isEmpty ? _claveDias : _claveTitulo;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final destino = clave.currentContext;
        if (destino != null) Scrollable.ensureVisible(destino, duration: const Duration(milliseconds: 300));
      });
      return;
    }
    _cerrando = true;
    Navigator.of(context).pop(RosarioReminder(
      id: widget.recordatorio?.id ?? 0,
      title: _titulo.text.trim(),
      description: _descripcion,
      time: _hora,
      daysOfWeek: _dias.toList()..sort(),
      isActive: widget.recordatorio?.isActive ?? true,
      type: _tipo,
      createdAt: widget.recordatorio?.createdAt ?? DateTime.now(),
    ));
  }

  Future<bool> _confirmarDescarte() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('¿Descartar los cambios?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Seguir editando')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Descartar')),
        ],
      ),
    );
    return descartar ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final nuevo = widget.recordatorio == null;

    return PopScope<RosarioReminder>(
      canPop: _cerrando || !_hayCambios,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navegador = Navigator.of(context);
        if (await _confirmarDescarte()) {
          _cerrando = true;
          navegador.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: () => Navigator.maybePop(context),
          ),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(nuevo ? 'Nuevo recordatorio' : 'Editar recordatorio'),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppTokens.espacioS),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: FilledButton(
                  onPressed: _guardar,
                  child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Guardar', maxLines: 1)),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formulario,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.espacioM),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTokens.anchoMaximo),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (nuevo) ...[
                        const _Titulo('Plantillas'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final plantilla in ReminderTemplates.templates)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(end: AppTokens.espacioS),
                                  child: ActionChip(
                                    avatar: Icon(plantilla.type.icon, size: 18),
                                    label: Text(plantilla.title),
                                    onPressed: () => _aplicar(plantilla),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTokens.espacioL),
                      ],
                      _SelectorHora(hora: _hora, onTap: _elegirHora),
                      const SizedBox(height: AppTokens.espacioL),
                      _Titulo('Repetir', key: _claveDias),
                      _SelectorDias(
                        dias: _dias,
                        onCambio: (dia, marcado) => _cambiarDias(marcado ? {..._dias, dia} : ({..._dias}..remove(dia))),
                      ),
                      const SizedBox(height: AppTokens.espacioS),
                      Wrap(
                        spacing: AppTokens.espacioS,
                        runSpacing: AppTokens.espacioS,
                        children: [
                          for (final (nombre, conjunto) in _atajos)
                            ChoiceChip(
                              label: Text(nombre),
                              selected: setEquals(_dias, conjunto),
                              onSelected: (_) => _cambiarDias(conjunto),
                            ),
                        ],
                      ),
                      if (_faltanDias) ...[
                        const SizedBox(height: AppTokens.espacioS),
                        Text('Elige al menos un día', style: textos.bodyMedium?.copyWith(color: esquema.error)),
                      ],
                      const SizedBox(height: AppTokens.espacioL),
                      const _Titulo('Tipo'),
                      SegmentedButton<ReminderType>(
                        segments: [
                          for (final tipo in ReminderType.values)
                            ButtonSegment(
                              value: tipo,
                              icon: Icon(tipo.icon),
                              label: FittedBox(fit: BoxFit.scaleDown, child: Text(tipo.displayName, maxLines: 1)),
                            ),
                        ],
                        selected: {_tipo},
                        onSelectionChanged: (seleccion) => setState(() => _tipo = seleccion.first),
                      ),
                      const SizedBox(height: AppTokens.espacioS),
                      Text(_tipo.description, style: textos.bodyMedium?.copyWith(color: esquema.onSurfaceVariant)),
                      const SizedBox(height: AppTokens.espacioL),
                      TextFormField(
                        key: _claveTitulo,
                        controller: _titulo,
                        maxLength: 50,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          prefixIcon: Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un título' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.espacioS),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

/// La hora en grande; toda la tarjeta abre el selector.
class _SelectorHora extends StatelessWidget {
  const _SelectorHora({required this.hora, required this.onTap});

  final TimeOfDay hora;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final texto = hora.format(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: 'Hora: $texto. Toca para cambiarla',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.espacioM),
            child: Column(
              children: [
                Text('Hora', style: textos.titleSmall?.copyWith(color: esquema.primary)),
                const SizedBox(height: AppTokens.espacioXS),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(texto, maxLines: 1, style: textos.displayMedium?.copyWith(color: esquema.onSurface)),
                ),
                Text('Toca para cambiarla', style: textos.bodySmall?.copyWith(color: esquema.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Siete botones circulares iguales; si no caben a 48 dp en una fila, se reparten en dos.
class _SelectorDias extends StatelessWidget {
  const _SelectorDias({required this.dias, required this.onCambio});

  final Set<int> dias;
  final void Function(int dia, bool marcado) onCambio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final porFila = limites.maxWidth / 7 >= 48 ? 7 : 4;
        final ancho = limites.maxWidth / porFila;
        return Wrap(
          runSpacing: AppTokens.espacioS,
          children: [
            for (final (dia, letra, nombre) in _diasSemana)
              SizedBox(
                width: ancho,
                child: Center(
                  child: _BotonDia(
                    letra: letra,
                    nombre: nombre,
                    marcado: dias.contains(dia),
                    onTap: () => onCambio(dia, !dias.contains(dia)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BotonDia extends StatelessWidget {
  const _BotonDia({required this.letra, required this.nombre, required this.marcado, required this.onTap});

  final String letra;
  final String nombre;
  final bool marcado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Tooltip(
      message: nombre,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: marcado,
        label: nombre,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: 48,
          child: Material(
            color: marcado ? esquema.primary : Colors.transparent,
            shape: CircleBorder(side: BorderSide(color: marcado ? esquema.primary : esquema.outline)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.espacioXS),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      letra,
                      style: textos.titleMedium?.copyWith(color: marcado ? esquema.onPrimary : esquema.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
