import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'contraste.dart';

/// Revisa cada texto dibujado: debe tener color y contraste WCAG suficiente contra su fondo real
/// (4.5:1, o 3:1 en texto grande). Devuelve una línea por cada falla.
List<String> fallasDeContraste(WidgetTester tester, String pantalla) {
  final fallas = <String>[];
  for (final elemento in find.byType(RichText).evaluate()) {
    final parrafo = elemento.renderObject;
    if (parrafo is! RenderParagraph || !parrafo.hasSize || parrafo.size.isEmpty) continue;
    // Los íconos se dibujan como texto, pero son gráficos y no entran en esta regla.
    if (elemento.findAncestorWidgetOfExactType<Icon>() != null) continue;
    if (_enControlDeshabilitado(elemento)) continue;
    final fondos = _fondosDe(elemento);

    void visitar(InlineSpan span, TextStyle? heredado) {
      if (span is! TextSpan) return;
      final estilo = heredado == null ? span.style : heredado.merge(span.style);
      final texto = span.text ?? '';
      if (texto.trim().isNotEmpty) {
        final color = estilo?.color ?? estilo?.foreground?.color;
        if (color == null) {
          fallas.add('$pantalla: "$texto" no tiene color');
        } else {
          final tamano = parrafo.textScaler.scale(estilo?.fontSize ?? 14);
          final negrita = (estilo?.fontWeight ?? FontWeight.normal).value >= FontWeight.bold.value;
          final minimo = tamano >= 24 || (negrita && tamano >= 18.66) ? 3.0 : 4.5;
          for (final fondo in fondos) {
            final relacion = contraste(Color.alphaBlend(color, fondo), fondo);
            if (relacion < minimo) {
              fallas.add('$pantalla: "$texto" ${relacion.toStringAsFixed(2)}:1 (mínimo $minimo) — $color sobre $fondo');
              break;
            }
          }
        }
      }
      for (final hijo in span.children ?? const <InlineSpan>[]) {
        visitar(hijo, estilo);
      }
    }

    visitar((elemento.widget as RichText).text, null);
  }
  return fallas;
}

bool _enControlDeshabilitado(Element elemento) {
  var deshabilitado = false;
  elemento.visitAncestorElements((ancestro) {
    final widget = ancestro.widget;
    if (widget is ButtonStyleButton) {
      deshabilitado = !widget.enabled;
      return false;
    }
    return true;
  });
  return deshabilitado;
}

/// Colores posibles del fondo real. Si el fondo es un degradado, devuelve todos sus colores.
List<Color> _fondosDe(Element elemento) {
  final capas = <Color>[]; // de la más cercana a la más lejana
  List<Color>? degradado;
  elemento.visitAncestorElements((ancestro) {
    if (ancestro is! RenderObjectElement) return true;
    final render = ancestro.renderObject;
    Color? relleno;
    List<Color>? colores;
    if (render is RenderPhysicalShape) {
      relleno = render.color;
    } else if (render is RenderPhysicalModel) {
      relleno = render.color;
    } else if (render is RenderDecoratedBox && render.position == DecorationPosition.background) {
      final decoracion = render.decoration;
      if (decoracion is BoxDecoration) {
        relleno = decoracion.color;
        colores = decoracion.gradient?.colors;
      } else if (decoracion is ShapeDecoration) {
        relleno = decoracion.color;
        colores = decoracion.gradient?.colors;
      }
    } else if (ancestro.widget is ColoredBox) {
      relleno = (ancestro.widget as ColoredBox).color;
    }
    if (colores != null && colores.isNotEmpty) {
      degradado = colores;
      return false;
    }
    if (relleno != null && relleno.a > 0) {
      capas.add(relleno);
      return relleno.a < 1; // si es translúcido, sigue hacia el fondo de abajo
    }
    return true;
  });
  final opaca = capas.isNotEmpty && capas.last.a >= 1 ? capas.removeLast() : null;
  final bases = degradado ?? [opaca ?? Theme.of(elemento).colorScheme.surface];
  return [
    for (final base in bases) capas.reversed.fold(base, (fondo, capa) => Color.alphaBlend(capa, fondo)),
  ];
}
