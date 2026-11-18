import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/etiqueta_boton.dart';
import 'recordatorio_form_screen.dart';

/// Lista de recordatorios con alta, edición, activación y borrado.
class AgendarRosarioScreen extends StatefulWidget {
  const AgendarRosarioScreen({super.key});

  @override
  State<AgendarRosarioScreen> createState() => _AgendarRosarioScreenState();
}

class _AgendarRosarioScreenState extends State<AgendarRosarioScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _pedirPermisoSiFalta());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de los ajustes del sistema, se revisan los permisos.
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationService>().refreshPermissions();
    }
  }

  Future<void> _pedirPermisoSiFalta() async {
    final servicio = context.read<NotificationService>();
    if (servicio.isAvailable && !servicio.permissions.notifications) {
      await servicio.requestPermissions();
    }
  }

  Future<void> _avisar(Future<ReminderResult> operacion) async {
    final mensajero = ScaffoldMessenger.of(context);
    final resultado = await operacion;
    if (!resultado.ok) {
      mensajero.showSnackBar(SnackBar(content: Text(resultado.message!)));
    }
  }

  Future<void> _abrirFormulario({RosarioReminder? recordatorio}) async {
    HapticFeedback.lightImpact();
    final servicio = context.read<NotificationService>();
    final guardado = await RecordatorioFormScreen.abrir(context, recordatorio: recordatorio);
    if (guardado == null || !mounted) return;
    await _avisar(recordatorio == null ? servicio.addReminder(guardado) : servicio.updateReminder(guardado));
  }

  Future<void> _confirmarEliminar(RosarioReminder recordatorio) async {
    final servicio = context.read<NotificationService>();
    final eliminar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('Eliminar recordatorio'),
        content: Text('¿Quieres eliminar "${recordatorio.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const EtiquetaBoton('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const EtiquetaBoton('Eliminar')),
        ],
      ),
    );
    if (eliminar ?? false) await _avisar(servicio.removeReminder(recordatorio.id));
  }

  @override
  Widget build(BuildContext context) {
    final servicio = context.watch<NotificationService>();
    final recordatorios = servicio.reminders;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis recordatorios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTokens.espacioM + AppTokens.margenLateral(MediaQuery.sizeOf(context).width),
          AppTokens.espacioS,
          AppTokens.espacioM + AppTokens.margenLateral(MediaQuery.sizeOf(context).width),
          MediaQuery.textScalerOf(context).scale(56) +
              AppTokens.espacioXL +
              AppTokens.espacioM +
              MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _AvisoPermisos(servicio: servicio),
          if (recordatorios.isEmpty)
            const _SinRecordatorios()
          else
            for (final r in recordatorios)
              _TarjetaRecordatorio(
                recordatorio: r,
                onCambiar: () => _avisar(servicio.toggleReminder(r.id)),
                onEditar: () => _abrirFormulario(recordatorio: r),
                onEliminar: () => _confirmarEliminar(r),
              ),
        ],
      ),
    );
  }
}

class _AvisoPermisos extends StatelessWidget {
  const _AvisoPermisos({required this.servicio});

  final NotificationService servicio;

  @override
  Widget build(BuildContext context) {
    if (!servicio.isAvailable) {
      return _Aviso(
        icono: Icons.notifications_off_outlined,
        texto: servicio.initError ?? 'Las notificaciones no están disponibles.',
      );
    }
    if (!servicio.permissions.notifications) {
      return _Aviso(
        icono: Icons.notifications_off_outlined,
        texto: 'Las notificaciones están desactivadas. Sin ellas, los recordatorios no sonarán.',
        accion: 'Permitir notificaciones',
        onAccion: () async {
          final permisos = await servicio.requestPermissions();
          if (!permisos.notifications) await servicio.openSettings();
        },
      );
    }
    if (!servicio.permissions.exactAlarms) {
      return _Aviso(
        icono: Icons.schedule_outlined,
        texto: 'Los avisos pueden llegar con unos minutos de retraso. Para que suenen a la hora exacta, '
            'permite "Alarmas y recordatorios".',
        accion: 'Permitir',
        onAccion: servicio.requestExactAlarms,
      );
    }
    return const SizedBox.shrink();
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto, this.accion, this.onAccion});

  final IconData icono;
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Card(
      color: esquema.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.espacioM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: esquema.onSecondaryContainer),
                const SizedBox(width: AppTokens.espacioM),
                Expanded(
                  child: Text(texto, style: textos.bodyMedium?.copyWith(color: esquema.onSecondaryContainer)),
                ),
              ],
            ),
            if (accion != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onAccion,
                  style: TextButton.styleFrom(foregroundColor: esquema.onSecondaryContainer),
                  child: EtiquetaBoton(accion!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SinRecordatorios extends StatelessWidget {
  const _SinRecordatorios();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioXL * 2, horizontal: AppTokens.espacioL),
      child: Column(
        children: [
          Icon(Icons.alarm_add, size: 80, color: esquema.onSurfaceVariant),
          const SizedBox(height: AppTokens.espacioL),
          Text('No hay recordatorios', style: textos.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppTokens.espacioS),
          Text(
            'Toca «Nuevo» para programar tu primer recordatorio del Santo Rosario.',
            textAlign: TextAlign.center,
            style: textos.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TarjetaRecordatorio extends StatelessWidget {
  const _TarjetaRecordatorio({
    required this.recordatorio,
    required this.onCambiar,
    required this.onEditar,
    required this.onEliminar,
  });

  final RosarioReminder recordatorio;
  final VoidCallback onCambiar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final activo = recordatorio.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.espacioS),
      child: Semantics(
        onTapHint: 'Editar ${recordatorio.title}',
        child: InkWell(
          onTap: onEditar,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.espacioM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(recordatorio.type.icon, color: esquema.primary),
                    const SizedBox(width: AppTokens.espacioS),
                    Expanded(child: Text(recordatorio.title, style: textos.titleMedium)),
                    Semantics(
                      label: activo ? 'Desactivar ${recordatorio.title}' : 'Activar ${recordatorio.title}',
                      child: Switch(value: activo, onChanged: (_) => onCambiar()),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    recordatorio.time.format(context),
                    maxLines: 1,
                    style: textos.displaySmall?.copyWith(color: activo ? esquema.onSurface : esquema.onSurfaceVariant),
                  ),
                ),
                Text(recordatorio.daysText, style: textos.bodyMedium),
                const SizedBox(height: AppTokens.espacioS),
                Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton.icon(onPressed: onEditar, icon: const Icon(Icons.edit_outlined), label: const EtiquetaBoton('Editar')),
                    TextButton.icon(
                      onPressed: onEliminar,
                      icon: const Icon(Icons.delete_outline),
                      label: const EtiquetaBoton('Eliminar'),
                      style: TextButton.styleFrom(foregroundColor: esquema.error),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
