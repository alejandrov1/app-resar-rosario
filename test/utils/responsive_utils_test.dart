import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app_resar_rosario/utils/responsive_utils.dart';

void main() {
  group('ResponsiveUtils Tests', () {
    testWidgets('getDeviceType debe identificar correctamente el tipo de dispositivo', 
      (WidgetTester tester) async {
      // Mobile
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getDeviceType(context), 
                     equals(DeviceType.mobile));
              return Container();
            },
          ),
        ),
      );

      // Tablet
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1200)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getDeviceType(context), 
                     equals(DeviceType.tablet));
              return Container();
            },
          ),
        ),
      );

      // Desktop
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.getDeviceType(context), 
                     equals(DeviceType.desktop));
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('isLandscape debe detectar correctamente la orientación', 
      (WidgetTester tester) async {
      // Portrait
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(400, 800),
            orientation: Orientation.portrait,
          ),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.isLandscape(context), isFalse);
              return Container();
            },
          ),
        ),
      );

      // Landscape
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 400),
            orientation: Orientation.landscape,
          ),
          child: Builder(
            builder: (context) {
              expect(ResponsiveUtils.isLandscape(context), isTrue);
              return Container();
            },
          ),
        ),
      );
    });
  });
}