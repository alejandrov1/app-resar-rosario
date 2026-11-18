import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/app_tokens.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:app_resar_rosario/widgets/paso_oracion_layout.dart';
import 'package:app_resar_rosario/widgets/rosary_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/app_harness.dart';
import 'support/contraste.dart';
import 'support/recorridos_app.dart';

/// Pulido de la revisión en un teléfono real: barras del sistema, letra grande y alineaciones.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Santo Rosario',
      packageName: 'com.alejandrovaldez.santorosario',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  /// Abre la app completa con el tamaño, la escala del sistema y las preferencias dadas.
  Future<void> abrirApp(
    WidgetTester tester, {
    Size tamano = const Size(360, 640),
    double escalaSistema = 1.0,
    Map<String, Object> preferencias = const {},
  }) async {
    tester.view.physicalSize = tamano * 3;
    tester.view.devicePixelRatio = 3.0;
    tester.platformDispatcher.textScaleFactorTestValue = escalaSistema;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(await appDePrueba(preferencias: preferencias));
    await tester.pumpAndSettle();
  }

  Future<void> abrirFormulario(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Agendar Rosario'));
    await tocar(tester, find.text('Nuevo'));
  }

  RenderParagraph parrafo(WidgetTester tester, Finder texto) => tester.renderObject<RenderParagraph>(texto);

  /// Cuántas líneas ocupa el texto una vez colocado.
  int lineas(WidgetTester tester, Finder texto) {
    final p = parrafo(tester, texto);
    final cajas = p.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length));
    return cajas.map((c) => c.top.round()).toSet().length;
  }

  group('P1 barras del sistema', () {
    const temas = {
      'claro': (1, Brightness.dark),
      'oscuro': (2, Brightness.light),
    };
    for (final MapEntry(key: nombre, value: (modo, iconos)) in temas.entries) {
      testWidgets('inicio en tema $nombre: iconos legibles y navegación transparente', (tester) async {
        await abrirApp(tester, preferencias: {'pref_theme_mode': modo});
        final estilo = SystemChrome.latestStyle!;
        expect(estilo.statusBarIconBrightness, iconos);
        expect(estilo.systemNavigationBarColor, Colors.transparent);
        expect(estilo.systemNavigationBarIconBrightness, iconos);
        expect(estilo.systemNavigationBarDividerColor, Colors.transparent);
      });

      testWidgets('rezo en tema $nombre: iconos claros sobre el fondo de la sección', (tester) async {
        await abrirApp(tester, preferencias: {'pref_theme_mode': modo});
        await tocar(tester, find.text('Comenzar a Rezar'));
        final estilo = SystemChrome.latestStyle!;
        expect(estilo.statusBarIconBrightness, Brightness.light);
        expect(estilo.systemNavigationBarColor, Colors.transparent);
        expect(estilo.systemNavigationBarIconBrightness, Brightness.light);
      });
    }
  });

  group('C1/I1 iconos del sistema legibles sobre el fondo real', () {
    Color iconos(Brightness b) => b == Brightness.light ? Colors.white : Colors.black;
    const temas = {
      'claro': (ThemeMode.light, false),
      'oscuro': (ThemeMode.dark, false),
      'claro alto contraste': (ThemeMode.light, true),
      'oscuro alto contraste': (ThemeMode.dark, true),
    };

    for (final MapEntry(key: nombre, value: (modo, alto)) in temas.entries) {
      for (final seccion in SeccionRosario.values) {
        testWidgets('rezo $nombre · ${seccion.name}', (tester) async {
          final tema = modo == ThemeMode.light ? AppTheme.claro(altoContraste: alto) : AppTheme.oscuro(altoContraste: alto);
          await tester.pumpWidget(MaterialApp(
            theme: tema,
            home: Builder(
              builder: (context) => PasoOracionLayout(
                colores: context.coloresDe(seccion),
                barra: const SizedBox(),
                cuerpo: const SizedBox(),
                onSiguiente: () {},
              ),
            ),
          ));
          await tester.pump();
          final fondo = tema.extension<SeccionesTema>()!.de(seccion).fondo;
          final estilo = SystemChrome.latestStyle!;
          expect(contraste(iconos(estilo.statusBarIconBrightness!), fondo.first), greaterThanOrEqualTo(3),
              reason: 'barra de estado');
          expect(contraste(iconos(estilo.systemNavigationBarIconBrightness!), fondo.last), greaterThanOrEqualTo(3),
              reason: 'barra de navegación');
        });
      }

      testWidgets('inicio $nombre', (tester) async {
        await abrirApp(tester, preferencias: variantesDeTema[nombre]!);
        final tema = Theme.of(tester.element(find.byType(Scaffold).first)).extension<SeccionesTema>()!;
        final estilo = SystemChrome.latestStyle!;
        expect(contraste(iconos(estilo.statusBarIconBrightness!), tema.fondoInicio.first), greaterThanOrEqualTo(3));
        expect(contraste(iconos(estilo.systemNavigationBarIconBrightness!), tema.fondoInicio.last),
            greaterThanOrEqualTo(3));
      });

      testWidgets('menú abierto $nombre: iconos legibles sobre la cabecera', (tester) async {
        await abrirApp(tester, preferencias: variantesDeTema[nombre]!);
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        final tema = Theme.of(tester.element(find.text('Menú principal'))).extension<SeccionesTema>()!;
        final estilo = SystemChrome.latestStyle!;
        expect(contraste(iconos(estilo.statusBarIconBrightness!), tema.iniciales.boton), greaterThanOrEqualTo(3));
      });
    }
  });

  group('letra grande (app 200 % × sistema 150 %)', () {
    Future<void> abrirGrande(WidgetTester tester) =>
        abrirApp(tester, escalaSistema: 1.5, preferencias: {'pref_text_scale': 2.0});

    testWidgets('P2 "Comenzar a Rezar" queda en una línea dentro del botón', (tester) async {
      await abrirGrande(tester);
      final etiqueta = find.text('Comenzar a Rezar');
      expect(lineas(tester, etiqueta), 1);
      final boton = find.ancestor(of: etiqueta, matching: find.byType(FilledButton));
      final rectBoton = tester.getRect(boton);
      final rectEtiqueta = tester.getRect(etiqueta);
      expect(rectBoton.contains(rectEtiqueta.topLeft) && rectBoton.contains(rectEtiqueta.bottomRight), isTrue,
          reason: '$rectEtiqueta dentro de $rectBoton');
      expect(tester.takeException(), isNull);
    });

    testWidgets('P3 la píldora "Misterios Gozosos" no se parte', (tester) async {
      await abrirGrande(tester);
      final pildora = find.text('Misterios Gozosos');
      await tester.ensureVisible(pildora);
      expect(lineas(tester, pildora), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('P5 la barra del formulario limita la letra a 130 %', (tester) async {
      await abrirGrande(tester);
      await abrirFormulario(tester);
      for (final texto in ['Guardar', 'Nuevo recordatorio']) {
        final escala = parrafo(tester, find.text(texto)).textScaler.scale(1);
        expect(escala, lessThanOrEqualTo(1.3 + 1e-9), reason: texto);
      }
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('C2 "Acerca de" limita la letra a 150 % para que sus botones no se partan', (tester) async {
    await abrirApp(tester, escalaSistema: 1.5, preferencias: {'pref_text_scale': 2.0});
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Acerca de'));
    final escala = parrafo(tester, find.text('Ver licencias')).textScaler.scale(1);
    expect(escala, lessThanOrEqualTo(1.5 + 1e-9));
  });

  testWidgets('P6 los 7 días caben en una fila de 48 dp en 360 dp de ancho', (tester) async {
    await abrirApp(tester);
    await abrirFormulario(tester);
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final centros = <double>[];
    for (final dia in dias) {
      final boton = find.byTooltip(dia);
      final tamano = tester.getSize(boton);
      expect(tamano.width, greaterThanOrEqualTo(48), reason: dia);
      expect(tamano.height, greaterThanOrEqualTo(48), reason: dia);
      centros.add(tester.getCenter(boton).dy);
    }
    expect(centros.toSet(), hasLength(1), reason: 'misma fila: $centros');
  });

  testWidgets('P7 la casita se alinea con el borde del contenido y mide 48 dp', (tester) async {
    await abrirApp(tester);
    await tocar(tester, find.text('Comenzar a Rezar'));
    final icono = tester.getTopLeft(find.byIcon(Icons.home_outlined)).dx;
    final texto = tester.getTopLeft(find.text('Señal de la Cruz')).dx;
    expect((icono - texto).abs(), lessThanOrEqualTo(2));
    final boton = tester.getSize(find.byTooltip('Volver al inicio'));
    expect(boton.width, greaterThanOrEqualTo(48));
    expect(boton.height, greaterThanOrEqualTo(48));
  });

  group('U1 marco de la foto', () {
    Future<Color?> colorDelMarco(WidgetTester tester, ThemeData tema) async {
      await tester.pumpWidget(MaterialApp(
        theme: tema,
        home: const Scaffold(
          body: RosaryImageWidget(width: 100, height: 100, imagePath: 'assets/images/imagen-rosario.png'),
        ),
      ));
      final contenedor = tester.widget<Container>(find.descendant(
        of: find.byType(RosaryImageWidget),
        matching: find.byType(Container),
      ));
      return (contenedor.decoration! as BoxDecoration).color;
    }

    testWidgets('en tema oscuro usa el gris lavanda suave', (tester) async {
      expect(await colorDelMarco(tester, AppTheme.oscuro()), AppTokens.fondoFotoOscuro);
    });

    testWidgets('en tema claro conserva el blanco', (tester) async {
      expect(await colorDelMarco(tester, AppTheme.claro()), AppTokens.fondoFoto);
    });
  });
}
