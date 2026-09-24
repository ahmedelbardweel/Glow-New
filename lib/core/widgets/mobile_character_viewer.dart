import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../animation/story_motion.dart';
import '../di/injection_container.dart';
import '../services/character_asset_cache.dart';
import '../services/resource_manager.dart';
import '../utils/character_helper.dart';

/// WKWebView / Android WebView hosts the packaged Three.js runtime. The model
/// enters as bounded binary chunks; no local HTTP server, CDN or network access
/// is needed, including on a fresh install in airplane mode.
class MobileCharacterViewer extends StatefulWidget {
  const MobileCharacterViewer({
    super.key,
    required this.characterName,
    required this.storyText,
    required this.isPlaying,
    required this.isSpeaking,
    required this.interactive,
    required this.showSkeleton,
    this.motion,
    this.playbackPosition,
  });

  final String characterName, storyText;
  final bool isPlaying, isSpeaking, interactive, showSkeleton;
  final CharacterMotion? motion;
  final ValueListenable<Duration>? playbackPosition;

  @override
  State<MobileCharacterViewer> createState() => _MobileCharacterViewerState();
}

class _MobileCharacterViewerState extends State<MobileCharacterViewer>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  late StoryMotionPlan _plan;
  Timer? _timeout, _visibilityTimer;
  bool _ready = false, _booted = false, _foreground = true, _ticker = true;
  bool _visible = true, _sending = false;
  String? _error, _lastMessage, _queuedMessage;
  int _generation = 0;
  Duration _lastPosition = Duration.zero;
  final _clock = Stopwatch(), _startup = Stopwatch();
  final _playbackClock = Stopwatch();
  int _lastPositionSent = -1000;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _plan = StoryMotionPlan.fromText(widget.storyText);
    widget.playbackPosition?.addListener(_positionChanged);
    _clock.start();
    if (widget.isPlaying) _playbackClock.start();
    unawaited(_initialize());
    _visibilityTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _checkVisibility(),
    );
  }

  Future<void> _initialize() async {
    final generation = ++_generation;
    _startup
      ..reset()
      ..start();
    _booted = _ready = false;
    _lastMessage = _queuedMessage = null;
    try {
      final controller = WebViewController();
      _controller = controller;
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(const Color(0xFFF4F7F5));
      await controller.addJavaScriptChannel(
        'GlowCharacter',
        onMessageReceived: (message) {
          if (!mounted || generation != _generation) return;
          final payload = jsonDecode(message.message) as Map<String, dynamic>;
          switch (payload['type']) {
            case 'boot':
              if (_booted) return;
              _booted = true;
              unawaited(_loadModel(controller, generation));
            case 'ready':
              if (_error != null) return;
              _timeout?.cancel();
              _startup.stop();
              if (kDebugMode)
                debugPrint(
                  'Character mobile ready: ${_startup.elapsedMilliseconds}ms; ${payload['triangles']} triangles; ${payload['clips']}',
                );
              setState(() => _ready = true);
            case 'loaded':
              _timeout?.cancel();
            case 'error':
              _fail(
                payload['message'] ?? 'WebGL initialization failed',
                generation,
              );
            case 'sample':
              if (kDebugMode) debugPrint('Character mobile sample: $payload');
          }
        },
      );
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => request.url.startsWith('file:')
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onWebResourceError: (error) {
            if (error.isForMainFrame == true)
              _fail(error.description, generation);
          },
        ),
      );
      if (!mounted || generation != _generation) return;
      setState(() {});
      _timeout?.cancel();
      _timeout = Timer(
        const Duration(seconds: 45),
        () => _fail('Character initialization timed out', generation),
      );
      await controller.loadFlutterAsset('assets/3d/character_mobile.html');
    } catch (error) {
      _fail(error, generation);
    }
  }

  Future<Uint8List> _modelBytes() async {
    final source = CharacterHelper.getModelPath(widget.characterName);
    final uri = Uri.tryParse(source);
    if (uri?.scheme == 'file') return File(uri!.toFilePath()).readAsBytes();
    if (uri?.scheme == 'http' || uri?.scheme == 'https') {
      final manager = sl<ResourceManager>();
      final path =
          manager.getLocalFilePath(source) ??
          await manager
              .downloadAndCacheFile(source, folder: 'models')
              .timeout(const Duration(seconds: 30));
      if (path == null)
        throw StateError('Custom model has not been downloaded');
      return File(path).readAsBytes();
    }
    return CharacterAssetCache.instance.load(source);
  }

  Future<void> _loadModel(WebViewController controller, int generation) async {
    try {
      final bytes = await _modelBytes();
      if (!mounted || generation != _generation) return;
      await controller.runJavaScript('GlowViewer.begin(${bytes.length});');
      // Bound temporary channel strings instead of retaining an 8 MB base64
      // copy of the model per view. Skeleton and texture bytes stay untouched.
      const chunkSize = 384 * 1024;
      for (var offset = 0; offset < bytes.length; offset += chunkSize) {
        if (!mounted || generation != _generation) return;
        final end = (offset + chunkSize).clamp(0, bytes.length);
        final chunk = base64Encode(Uint8List.sublistView(bytes, offset, end));
        await controller.runJavaScript('GlowViewer.append("$chunk", $offset);');
      }
      if (!mounted || generation != _generation) return;
      await controller.runJavaScript(
        'GlowViewer.update(${jsonEncode(_state(seek: true))});GlowViewer.load();',
      );
    } catch (error) {
      _fail(error, generation);
    }
  }

  Map<String, Object> _state({bool seek = false}) {
    final position =
        widget.playbackPosition?.value ??
        _playbackClock.elapsed;
    final color =
        CharacterHelper.getColor(widget.characterName).toARGB32() & 0xFFFFFF;
    return {
      'motion': (widget.motion ?? _plan.motionAt(position)).clipName,
      'playing': widget.isPlaying,
      'speaking': widget.isSpeaking,
      'interactive': widget.interactive,
      'skeleton': widget.showSkeleton,
      'visible': _visible,
      'originalGreen':
          CharacterHelper.getColorKey(widget.characterName) == 'port',
      'color': '#${color.toRadixString(16).padLeft(6, '0')}',
      'position': position.inMilliseconds / 1000,
      'seek': seek,
      'diagnostics': const bool.fromEnvironment('GLOW_CHARACTER_DIAGNOSTICS'),
    };
  }

  void _positionChanged() {
    final position = widget.playbackPosition?.value ?? Duration.zero;
    final seek =
        position < _lastPosition ||
        (position - _lastPosition).inMilliseconds > 1200;
    _lastPosition = position;
    if (seek || _clock.elapsedMilliseconds - _lastPositionSent >= 200) {
      _lastPositionSent = _clock.elapsedMilliseconds;
      _sendState(seek: seek);
    }
  }

  void _sendState({bool seek = false}) {
    if (!_booted || _controller == null || _error != null) return;
    final message = jsonEncode(_state(seek: seek));
    if (message == _lastMessage) return;
    _lastMessage = message;
    _queuedMessage = message;
    if (!_sending) unawaited(_flushState());
  }

  Future<void> _flushState() async {
    _sending = true;
    final generation = _generation;
    try {
      while (mounted && generation == _generation && _queuedMessage != null) {
        final message = _queuedMessage!;
        _queuedMessage = null;
        await _controller!.runJavaScript('GlowViewer.update($message);');
      }
    } catch (error) {
      _fail(error, generation);
    } finally {
      _sending = false;
      if (mounted && _queuedMessage != null && _error == null) {
        unawaited(_flushState());
      }
    }
  }

  void _checkVisibility() {
    if (!mounted) return;
    var visible = _foreground && _ticker;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize && box.attached) {
      visible =
          visible &&
          (box.localToGlobal(Offset.zero) & box.size).overlaps(
            Offset.zero & MediaQuery.sizeOf(context),
          );
    }
    if (_visible != visible) {
      _visible = visible;
      _syncPlaybackClock();
      _sendState();
    }
    if (widget.playbackPosition == null && widget.isPlaying && visible)
      _sendState();
  }

  void _fail(Object error, int generation) {
    if (!mounted || generation != _generation || _error != null) return;
    _timeout?.cancel();
    debugPrint('Character mobile error: $error');
    unawaited(_release(_controller));
    setState(() {
      _ready = false;
      _error = error.toString();
      _controller = null;
    });
  }

  @override
  void didUpdateWidget(covariant MobileCharacterViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storyText != widget.storyText)
      _plan = StoryMotionPlan.fromText(widget.storyText);
    if (oldWidget.storyText != widget.storyText) _playbackClock.reset();
    _syncPlaybackClock();
    if (oldWidget.playbackPosition != widget.playbackPosition) {
      oldWidget.playbackPosition?.removeListener(_positionChanged);
      widget.playbackPosition?.addListener(_positionChanged);
    }
    if (oldWidget.characterName != widget.characterName ||
        oldWidget.storyText != widget.storyText ||
        oldWidget.motion != widget.motion ||
        oldWidget.isPlaying != widget.isPlaying ||
        oldWidget.isSpeaking != widget.isSpeaking ||
        oldWidget.showSkeleton != widget.showSkeleton ||
        oldWidget.interactive != widget.interactive ||
        oldWidget.playbackPosition != widget.playbackPosition) {
      _sendState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ticker = TickerMode.valuesOf(context).enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _syncPlaybackClock() {
    if (_visible && widget.isPlaying) {
      _playbackClock.start();
    } else {
      _playbackClock.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _checkVisibility();
  }

  Future<void> _release(WebViewController? controller) async {
    try {
      await controller?.runJavaScript('window.GlowViewer?.dispose();');
    } catch (_) {
      /* Native view may already be detached. */
    }
  }

  void _retry() {
    unawaited(_release(_controller));
    setState(() {
      _controller = null;
      _error = null;
    });
    unawaited(_initialize());
  }

  @override
  void dispose() {
    ++_generation;
    _timeout?.cancel();
    _visibilityTimer?.cancel();
    widget.playbackPosition?.removeListener(_positionChanged);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_release(_controller));
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'شخصية ${CharacterHelper.getCleanName(widget.characterName)} متحركة',
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (_controller != null && _error == null)
          WebViewWidget(key: ValueKey(_controller), controller: _controller!),
        if (!_ready && _error == null)
          ColoredBox(
            color: const Color(0xFFF4F7F5),
            child: _GlowingLoader(
              color: CharacterHelper.getColor(widget.characterName),
            ),
          ),
        if (_error != null)
          ColoredBox(
            color: const Color(0xFFF4F7F5),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'تعذّر عرض الشخصية الآن. أعد المحاولة.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _GlowingLoader extends StatefulWidget {
  final Color color;
  const _GlowingLoader({required this.color});

  @override
  State<_GlowingLoader> createState() => _GlowingLoaderState();
}

class _GlowingLoaderState extends State<_GlowingLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = Curves.easeInOutSine.transform(_controller.value);
          return Container(
            height: 100 + (50 * value),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  widget.color.withValues(alpha: 0.4 + (0.2 * value)),
                  widget.color.withValues(alpha: 0.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
