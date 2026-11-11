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

/// Formulario para crear o editar un recordatorio. Se muestra en una hoja inferior.
class ReminderForm extends StatefulWidget {
  const ReminderForm({super.key, this.reminder, required this.onSave});

  final RosarioReminder? reminder;
  final ValueChanged<RosarioReminder> onSave;

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _titulo =
      TextEditingController(text: widget.reminder?.title ?? 'Rezar el Santo Rosario');
  late TimeOfDay _hora = widget.reminder?.time ?? const TimeOfDay(hour: 19, minute: 0);
  late final Set<int> _dias = {...?widget.reminder?.daysOfWeek};
  late ReminderType _tipo = widget.reminder?.type ?? ReminderType.notification;
  late String _descripcion = widget.reminder?.description ?? 'Es hora de tu oración. El Señor está contigo.';
  bool _faltanDias = false;

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

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

  void _guardar() {
    final valido = _formulario.currentState!.validate();
    setState(() => _faltanDias = _dias.isEmpty);
    if (!valido || _dias.isEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    widget.onSave(RosarioReminder(
      id: widget.reminder?.id ?? 0,
      title: _titulo.text.trim(),
      description: _descripcion,
      time: _hora,
      daysOfWeek: _dias.toList()..sort(),
      isActive: widget.reminder?.isActive ?? true,
      type: _tipo,
      createdAt: widget.reminder?.createdAt ?? DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return Padding(
      // El espacio del teclado se aplica una sola vez, aquí (E10).
      padding: EdgeInsets.only(
        left: AppTokens.espacioL,
        right: AppTokens.espacioL,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppTokens.espacioL,
      ),
      child: Form(
        key: _formulario,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.reminder == null ? 'Nuevo recordatorio' : 'Editar recordatorio', style: textos.titleLarge),
              const SizedBox(height: AppTokens.espacioL),
              if (widget.reminder == null) ...[
                Text('Plantillas rápidas', style: textos.titleSmall),
                const SizedBox(height: AppTokens.espacioS),
                Wrap(
                  spacing: AppTokens.espacioS,
                  runSpacing: AppTokens.espacioS,
                  children: [
                    for (final plantilla in ReminderTemplates.templates)
                      ActionChip(
                        avatar: Icon(plantilla.type.icon, size: 18),
                        label: Text(plantilla.title),
                        onPressed: () => _aplicar(plantilla),
                      ),
                  ],
                ),
                const SizedBox(height: AppTokens.espacioL),
              ],
              TextFormField(
                controller: _titulo,
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un título' : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Hora'),
                subtitle: Text(_hora.format(context), style: textos.titleMedium),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _elegirHora,
              ),
              const SizedBox(height: AppTokens.espacioS),
              Text('Repetir', style: textos.titleSmall),
              const SizedBox(height: AppTokens.espacioS),
              Wrap(
                spacing: AppTokens.espacioS,
                runSpacing: AppTokens.espacioS,
                children: [
                  for (final (dia, letra, nombre) in _diasSemana)
                    FilterChip(
                      label: Text(letra),
                      tooltip: nombre,
                      selected: _dias.contains(dia),
                      onSelected: (marcado) => setState(() {
                        marcado ? _dias.add(dia) : _dias.remove(dia);
                        _faltanDias = false;
                      }),
                    ),
                ],
              ),
              if (_faltanDias) ...[
                const SizedBox(height: AppTokens.espacioS),
                Text('Elige al menos un día', style: textos.bodySmall?.copyWith(color: esquema.error)),
              ],
              const SizedBox(height: AppTokens.espacioL),
              Text('Tipo', style: textos.titleSmall),
              const SizedBox(height: AppTokens.espacioS),
              SegmentedButton<ReminderType>(
                segments: [
                  for (final tipo in ReminderType.values)
                    ButtonSegment(value: tipo, label: Text(tipo.displayName), icon: Icon(tipo.icon)),
                ],
                selected: {_tipo},
                onSelectionChanged: (seleccion) => setState(() => _tipo = seleccion.first),
              ),
              const SizedBox(height: AppTokens.espacioS),
              Text(_tipo.description, style: textos.bodySmall),
              const SizedBox(height: AppTokens.espacioXL),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
                  const SizedBox(width: AppTokens.espacioM),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _guardar,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
