import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_colors.dart';
import 'custom_loader.dart';

/// Camera preview for a QR sheet. The camera starts after the sheet is open,
/// using the selector that works on real Android phones.
class AppQrScanner extends StatefulWidget {
  const AppQrScanner({super.key, required this.onCode, this.handle});

  /// Return true when [raw] was accepted and the sheet should close.
  final bool Function(String raw) onCode;

  /// Lets the sheet pause the live camera before reading an uploaded image.
  final AppQrScanHandle? handle;

  @override
  State<AppQrScanner> createState() => _AppQrScannerState();
}

/// Pauses the live camera so an uploaded photo can be read without freezing it.
class AppQrScanHandle {
  _AppQrScannerState? _state;

  Future<void> pause() => _state?.pause() ?? Future<void>.value();

  Future<BarcodeCapture?> analyze(String path) {
    final state = _state;
    if (state == null) return Future<BarcodeCapture?>.value();
    return state.analyze(path);
  }

  Future<void> resume() => _state?.resume() ?? Future<void>.value();
}

class _AppQrScannerState extends State<AppQrScanner> with WidgetsBindingObserver {
  MobileScannerController? _camera;
  var _handled = false;
  var _recovering = false;
  var _recoveries = 0;
  var _useNewSelector = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.handle?._state = this;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted || _handled) return;
        _openCamera();
      });
    });
  }

  @override
  void didUpdateWidget(AppQrScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handle != widget.handle) {
      if (oldWidget.handle?._state == this) oldWidget.handle?._state = null;
      widget.handle?._state = this;
    }
  }

  Future<void> pause() async {
    final camera = _camera;
    if (camera == null) return;
    try {
      await camera.stop().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<BarcodeCapture?> analyze(String path) {
    final camera = _camera;
    final future = camera == null
        ? MobileScannerPlatform.instance.analyzeImage(
            path,
            formats: const [BarcodeFormat.qrCode],
          )
        : camera.analyzeImage(path, formats: const [BarcodeFormat.qrCode]);
    return future.timeout(const Duration(seconds: 12));
  }

  Future<void> resume() async {
    if (!mounted || _handled) return;
    final camera = _camera;
    if (camera == null) {
      _openCamera();
      return;
    }
    try {
      await camera.start().timeout(const Duration(seconds: 3));
    } catch (_) {
      if (mounted) _openCamera();
    }
  }

  void _openCamera({bool reset = true}) {
    final previous = _camera;
    previous?.removeListener(_onCamera);
    final next = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 400,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
      returnImage: false,
      useNewCameraSelector: _useNewSelector,
    );
    next.addListener(_onCamera);
    if (reset) _recoveries = 0;
    _recovering = false;
    setState(() => _camera = next);
    if (previous != null) unawaited(previous.dispose());
  }

  void _onCamera() {
    final camera = _camera;
    if (camera == null) return;
    if (camera.value.isRunning && camera.value.error == null) {
      _recoveries = 0;
      return;
    }
    final error = camera.value.error;
    if (error != null && _willRetry(error)) unawaited(_recover());
  }

  bool _willRetry(MobileScannerException error) {
    if (_handled || _recoveries >= 3) return false;
    return error.errorCode != MobileScannerErrorCode.unsupported &&
        error.errorCode != MobileScannerErrorCode.permissionDenied;
  }

  /// The permission dialog pauses the screen, so the first open often fails
  /// even after the user allows the camera. Try again once the app is back.
  Future<void> _recover() async {
    if (!mounted || _handled || _recovering) return;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    final camera = _camera;
    final error = camera?.value.error;
    if (camera == null || error == null || camera.value.isRunning) return;
    if (!_willRetry(error)) return;
    _recovering = true;
    _recoveries++;
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted || _handled) {
      _recovering = false;
      return;
    }
    final current = _camera;
    try {
      if (current != null && current.value.error != null && !current.value.isRunning) {
        await current.start().timeout(const Duration(seconds: 4));
      }
    } catch (_) {}
    _recovering = false;
    if (!mounted || _handled) return;
    final after = _camera?.value.error;
    if (after != null && _recoveries == 1) {
      _useNewSelector = !_useNewSelector;
      _openCamera(reset: false);
      return;
    }
    setState(() {});
    if (after != null && _willRetry(after)) unawaited(_recover());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_recover());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.removeListener(_onCamera);
    if (widget.handle?._state == this) widget.handle?._state = null;
    final camera = _camera;
    if (camera != null) unawaited(camera.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !mounted) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    if (!widget.onCode(raw)) return;
    _handled = true;
    final camera = _camera;
    if (camera != null) unawaited(camera.stop());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight) * 0.72;
        final window = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
          width: side,
          height: side,
        );
        final camera = _camera;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (camera == null)
              const ColoredBox(color: AppColors.secondary)
            else
              MobileScanner(
                controller: camera,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) {
                  if (_recovering || _willRetry(error)) {
                    return const ColoredBox(
                      color: AppColors.secondary,
                      child: Center(child: CustomLoader(color: Colors.white)),
                    );
                  }
                  return _CameraMessage(
                    message: _cameraMessage(error),
                    onRetry: _handled ? null : _openCamera,
                  );
                },
              ),
            IgnorePointer(
              child: CustomPaint(
                painter: _QrFramePainter(window),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _cameraMessage(MobileScannerException error) {
  switch (error.errorCode) {
    case MobileScannerErrorCode.permissionDenied:
      return 'اسمح للكاميرا حتى يُمسح الرمز. إذا رفضت الإذن من قبل، فعّله من إعدادات التطبيق ثم أعد المحاولة.';
    case MobileScannerErrorCode.unsupported:
      return 'هذا الجهاز لا يوفّر كاميرا للمسح.';
    case MobileScannerErrorCode.genericError:
    case MobileScannerErrorCode.controllerAlreadyInitialized:
    case MobileScannerErrorCode.controllerDisposed:
    case MobileScannerErrorCode.controllerUninitialized:
      return 'تعذر فتح الكاميرا. أعد المحاولة، وتأكد أن إذن الكاميرا مفعّل.';
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ColoredBox(
      color: AppColors.secondary,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QrFramePainter extends CustomPainter {
  const _QrFramePainter(this.window);

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(window, Radius.circular(AppColors.border_radius)),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(shade, Paint()..color = const Color(0x88001946));
    canvas.drawRRect(
      RRect.fromRectAndRadius(window, Radius.circular(AppColors.border_radius)),
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _QrFramePainter oldDelegate) => oldDelegate.window != window;
}
