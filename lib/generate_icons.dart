// generate_icons.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  print('Generando iconos optimizados...');
  
  // Lee la imagen original
  final originalFile = File('assets/icons/icono-rosario.png');
  if (!originalFile.existsSync()) {
    print('Error: No se encontró assets/icons/icono-rosario.png');
    return;
  }
  
  final originalImage = img.decodeImage(originalFile.readAsBytesSync());
  if (originalImage == null) {
    print('Error: No se pudo decodificar la imagen');
    return;
  }
  
  // Crea versión con padding para evitar cortes
  final paddedImage = addPadding(originalImage);
  
  // Guarda la versión con padding
  File('assets/icons/icono-rosario-padded.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(paddedImage));
  
  // Crea versión foreground para Android
  final foregroundImage = createForegroundVersion(originalImage);
  File('assets/icons/icono-rosario-foreground.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(foregroundImage));
  
  print('Iconos generados exitosamente!');
}

img.Image addPadding(img.Image src) {
  // Añade 15% de padding alrededor
  final padding = (src.width * 0.15).round();
  final newSize = src.width + (padding * 2);
  
  final padded = img.Image(width: newSize, height: newSize);
  img.fill(padded, color: img.ColorRgba8(0, 0, 0, 0)); // Transparente
  
  // Centra la imagen original
  img.compositeImage(padded, src, dstX: padding, dstY: padding);
  
  return padded;
}

img.Image createForegroundVersion(img.Image src) {
  // Para Android adaptive icon, el contenido debe estar en el 66% central
  const targetSize = 1024;
  final contentSize = (targetSize * 0.66).round();
  
  // Redimensiona manteniendo aspecto
  final resized = img.copyResize(src, 
    width: contentSize, 
    height: contentSize,
    interpolation: img.Interpolation.linear
  );
  
  // Crea imagen con el tamaño correcto
  final foreground = img.Image(width: targetSize, height: targetSize);
  img.fill(foreground, color: img.ColorRgba8(0, 0, 0, 0)); // Transparente
  
  // Centra el contenido
  final offset = (targetSize - contentSize) ~/ 2;
  img.compositeImage(foreground, resized, dstX: offset, dstY: offset);
  
  return foreground;
}