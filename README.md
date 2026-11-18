# Santo Rosario

App para rezar el Santo Rosario de forma guiada, con los misterios del día, letanías, recordatorios
y opciones de accesibilidad (tamaño de texto, alto contraste, botones grandes y modo oscuro).

- **Plataformas:** Android 7.0+ e iOS 15+.
- **Paquete:** `com.alejandrovaldez.santorosario`.
- **Privacidad:** no recopila ni envía datos; todo se guarda en el teléfono ([política](docs/privacidad.md)).

## Desarrollo

Requiere Flutter 3.47.9.

```bash
flutter pub get
flutter run            # en un teléfono o emulador
flutter analyze
flutter test
```

## Estructura

- `lib/data/` — textos de las oraciones y misterios (cada uno escrito una vez).
- `lib/logic/` — recorrido del rosario (`RosarioSession`, 93 pasos).
- `lib/services/` — preferencias, recordatorios y zona horaria.
- `lib/theme/` — colores, medidas y temas (claro, oscuro y alto contraste).
- `lib/screens/` y `lib/widgets/` — interfaz.

## Publicación

Ver [docs/publicacion.md](docs/publicacion.md).
