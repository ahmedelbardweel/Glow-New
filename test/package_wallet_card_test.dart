import 'dart:io';
import 'dart:ui' as ui;
import 'package:Glow/features/dashboard/presentation/widgets/package_wallet_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const previewFont = String.fromEnvironment('WALLET_PREVIEW_FONT');
  setUpAll(() async {
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    if (previewFont.isEmpty) return;
    final loader = FontLoader('WalletPreview');
    loader.addFont(
      File(
        previewFont,
      ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
    );
    await loader.load();
  });
  for (final width in [320.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('wallet full width $width text scale $scale', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var opened = 0;
        var edited = 0;
        final capture = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              splashFactory: NoSplash.splashFactory,
              fontFamily: previewFont.isEmpty ? null : 'WalletPreview',
            ),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1200),
                textScaler: TextScaler.linear(scale),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: RepaintBoundary(
                      key: capture,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: PackageWalletCard(
                          package: {
                            'title': 'بكج البداية — العادات الخمس',
                            'description':
                                'رحلة ممتعة لبناء عادات جميلة، خطوة بخطوة مع أصدقاء Glow.',
                            'status': 'draft',
                            'version': 1,
                            '_mission_count': 5,
                            'draft_content': {
                              'worlds': [
                                {'title': 'عالم العادات الذكية للأبطال'},
                                {'title': 'عالم المغامرات والاكتشاف'},
                                {'title': 'عالم الصداقة والتعاون'},
                                {'title': 'عالم جديد'},
                              ],
                            },
                          },
                          onTap: () => opened++,
                          onEdit: () => edited++,
                          onDelete: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 3; i++) {
          expect(
            tester.getSize(find.byKey(ValueKey('wallet-world-$i'))).width,
            width - 32,
          );
        }
        if (width == 430 && scale == 1) {
          final boundary =
              capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory('build').create(recursive: true);
            await File(
              'build/package_wallet_review.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(find.byTooltip('خيارات البكج'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تعديل البيانات'));
        await tester.pumpAndSettle();
        expect(edited, 1);
        expect(opened, 0);
        await tester.ensureVisible(find.text('فتح البكج'));
        await tester.tap(find.text('فتح البكج'));
        expect(opened, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
