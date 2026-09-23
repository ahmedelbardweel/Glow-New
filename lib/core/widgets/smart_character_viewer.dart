import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:three_js/three_js.dart' as three;
import '../animation/story_motion.dart';
import '../animation/character_skin_palette.dart';
import '../di/injection_container.dart';
import '../services/resource_manager.dart';
import '../utils/character_helper.dart';

/// Keeps the packaged GLB in memory. Opening another story therefore does not
/// read the same multi-megabyte asset from storage again.
class _CharacterModelBytesCache {
  static final Map<String, Future<Uint8List>> _assets = {};

  static Future<Uint8List> loadAsset(String assetPath) {
    return _assets.putIfAbsent(assetPath, () async {
      final data = await rootBundle.load(assetPath);
      final view = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      return Uint8List.fromList(view);
    });
  }
}

/// A failed native renderer is not retried by every card in the app. A manual
/// retry resets this small circuit breaker after a device or GPU recovers.
class _CharacterRendererHealth {
  static Object? _lastFailure;

  static Object? get lastFailure => _lastFailure;
  static bool get isUnavailable => _lastFailure != null;

  static void markUnavailable(Object error) => _lastFailure ??= error;
  static void reset() => _lastFailure = null;
}

/// One skinned GLB with reusable animations and five material colors.
/// Speaking uses a stylized cadence, not phoneme-based lip synchronization.
class SmartCharacterViewer extends StatelessWidget {
  const SmartCharacterViewer({
    super.key,
    required this.characterName,
    this.storyText = '',
    this.isPlaying = true,
    this.isSpeaking = false,
    this.playbackPosition,
    this.motion,
    this.interactive = true,
    this.showSkeleton = false,
  });
  final String characterName;
  final String storyText;
  final bool isPlaying;
  final bool isSpeaking;
  final ValueListenable<Duration>? playbackPosition;
  final CharacterMotion? motion;
  final bool interactive;
  final bool showSkeleton;

  @override
  Widget build(BuildContext context) {
    final source = CharacterHelper.getModelPath(characterName);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.hasBoundedWidth ? constraints.maxWidth : 320,
          constraints.hasBoundedHeight ? constraints.maxHeight : 360,
        );
        if (size.isEmpty) return const SizedBox.shrink();
        return _CharacterSurface(
          // Color/scene updates retain the rig. A size change needs a new texture.
          key: ValueKey('$source/${size.width.round()}/${size.height.round()}'),
          source: source,
          size: size,
          configuration: this,
        );
      },
    );
  }
}

class _CharacterSurface extends StatefulWidget {
  const _CharacterSurface({
    super.key,
    required this.source,
    required this.size,
    required this.configuration,
  });
  final String source;
  final Size size;
  final SmartCharacterViewer configuration;
  @override
  State<_CharacterSurface> createState() => _CharacterSurfaceState();
}

class _CharacterSurfaceState extends State<_CharacterSurface>
    with WidgetsBindingObserver {
  _GuardedThreeJS? _view;
  late StoryMotionPlan _plan;
  final _actions = <String, three.AnimationAction>{};
  final _bones = <three.Object3D>[];
  final _skinPalette = CharacterSkinPalette();
  three.Object3D? _model;
  three.AnimationMixer? _mixer;
  three.AnimationAction? _activeAction;
  three.OrbitControls? _orbit;
  three.Object3D? _jaw;
  three.Object3D? _mouth;
  three.Quaternion? _jawRest;
  three.LineSegments? _skeleton;
  three.Float32BufferAttribute? _skeletonPositions;
  final _point = three.Vector3();
  final _jawRotation = three.Quaternion();
  final _jawAxis = three.Vector3(1, 0, 0);
  bool _ready = false;
  bool _foreground = true;
  bool _tickerEnabled = true;
  Object? _error;
  double _elapsed = 0;
  double _speechBlend = 0;
  Duration _lastPosition = Duration.zero;
  Timer? _loadTimeout;
  int _loadGeneration = 0;
  bool _compatibilityMode = false;
  SmartCharacterViewer get config => widget.configuration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _plan = StoryMotionPlan.fromText(config.storyText);
    config.playbackPosition?.addListener(_onPosition);
    _createView();
  }

  void _createView() {
    if (_CharacterRendererHealth.isUnavailable) {
      _error = _CharacterRendererHealth.lastFailure;
      return;
    }
    final generation = ++_loadGeneration;
    final view = _GuardedThreeJS(
      size: widget.size,
      settings: three.Settings(
        clearColor: 0xF4F7F5,
        // Enable MSAA for smooth stylized cartoon edges
        antialias: true,
        enableShadowMap: false,
        toneMapping: three.NoToneMapping,
        // SurfaceProducer API causes shader validation errors on many Android
        // devices. Fall back to the older texture path on native platforms.
        useSurfaceProducer: kIsWeb,
        stencil: false,
        precision: three.Precision.highp, // higher precision for better quality
        screenResolution: _compatibilityMode
            ? 0.8
            : (!kIsWeb && (Platform.isAndroid || Platform.isIOS) ? 1.0 : 2.0),
      ),
      setup: () => _setup(generation),
      onError: (error, stack) {
        if (generation == _loadGeneration) _onError(error, stack);
      },
      onSetupComplete: () {
        if (generation != _loadGeneration) return;
        _loadTimeout?.cancel();
        if (mounted && _error == null) setState(() => _ready = true);
      },
    );
    _view = view;
    // Early disposal must be safe even before the native texture exists.
    view.scene = three.Scene();
    view.camera = three.PerspectiveCamera(
      38,
      widget.size.width / widget.size.height,
      0.05,
      100,
    );
    _loadTimeout = Timer(
      Duration(seconds: _compatibilityMode ? 8 : 6),
      () => _onError(
        TimeoutException('Character renderer did not become ready quickly.'),
        StackTrace.current,
      ),
    );
  }

  void _onError(Object error, [StackTrace? stack]) {
    if (!mounted || _error != null) return;
    _loadTimeout?.cancel();
    debugPrint('Character viewer error: $error\n$stack');
    if (!_compatibilityMode) {
      _compatibilityMode = true;
      _restartRenderer();
      return;
    }
    _CharacterRendererHealth.markUnavailable(error);
    setState(() => _error = error);
  }

  Future<void> _setup(int generation) async {
    final loader = three.GLTFLoader();
    three.GLTFData? data;
    try {
      data = await _loadModel(loader);
    } catch (e, stack) {
      debugPrint('=== GLB LOAD ERROR ===\n$e\n$stack');
      rethrow;
    } finally {
      loader.dispose();
    }
    if (data == null) throw StateError('The GLB could not be loaded.');
    if (!mounted || _error != null || generation != _loadGeneration) {
      data.scene.dispose();
      return;
    }
    final view = _view;
    if (view == null) {
      data.scene.dispose();
      return;
    }
    _model = data.scene;
    view.scene.add(_model!);
    _model!.traverse((object) {
      if (object is three.Bone) _bones.add(object);
      if (object is three.SkinnedMesh) object.frustumCulled = false;
    });
    if (widget.source == CharacterHelper.sharedModelPath) {
      _skinPalette.attach(_model!);
    }
    _recolor();
    _jaw = _model!.getObjectByName('Jaw');
    _mouth = _model!.getObjectByName('Mouth');
    _jawRest = _jaw?.quaternion.clone();
    _mixer = three.AnimationMixer(_model!);
    for (final clip
        in (data.animations ?? const []).whereType<three.AnimationClip>()) {
      final action = _mixer!.clipAction(clip);
      if (action != null) _actions[clip.name] = action;
    }
    _frameModel();
    _buildLighting();
    _buildSkeleton();
    _orbit = three.OrbitControls(view.camera, view.globalKey)
      ..enabled = config.interactive
      ..enablePan = false
      ..enableDamping = true
      ..minDistance = 3
      ..maxDistance = 16;
    _orbit!.target.setValues(0, 1.78, 0);
    view.addAnimationEvent(_animate);
    _selectMotion();
    _mixer!.update(0);
  }

  Future<three.GLTFData?> _loadModel(three.GLTFLoader loader) async {
    final source = widget.source;
    final uri = Uri.tryParse(source);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      if (uri?.scheme == 'file') return loader.fromPath(uri!.toFilePath());
      return loader.fromBytes(
        await _CharacterModelBytesCache.loadAsset(source),
      );
    }

    // Online uploads use the same verified file cache as stories and audio.
    // If the file was downloaded before, it opens immediately without a
    // network call. If this is a fresh device, the first download becomes the
    // offline copy for later sessions.
    try {
      final manager = sl<ResourceManager>();
      final cachedPath = manager.getLocalFilePath(source);
      if (cachedPath != null) return loader.fromPath(cachedPath);
      final downloadedPath = await manager
          .downloadAndCacheFile(source, folder: 'models')
          .timeout(const Duration(seconds: 6));
      if (downloadedPath != null) return loader.fromPath(downloadedPath);
    } catch (_) {
      // The standalone studio and tests do not register the resource cache.
    }
    return loader.fromNetwork(uri).timeout(const Duration(seconds: 6));
  }

  void _frameModel() {
    final bounds = three.BoundingBox().setFromObject(_model!);
    final extent = bounds.getSize(three.Vector3());
    final center = bounds.getCenter(three.Vector3());
    if (!extent.y.isFinite || extent.y <= 0) {
      throw StateError('The model has no renderable geometry.');
    }
    final scale = 3.5 / extent.y;
    _model!.scale.setValues(scale, scale, scale);
    _model!.position.setValues(
      -center.x * scale,
      -bounds.min.y * scale,
      -center.z * scale,
    );
    final aspect = widget.size.width / widget.size.height;
    final distance =
        math.max(3.5, extent.x * scale / aspect) /
        (2 * math.tan(38 * math.pi / 360)) *
        1.26;
    _view?.camera.position.setValues(0.32, 2.06, distance);
    _view?.camera.lookAt(three.Vector3(0, 1.78, 0));
  }

  void _buildLighting() {
    final view = _view;
    if (view == null) return;
    view.scene.add(three.HemisphereLight(0xEAF6FF, 0x8D8270, 0.75));
    view.scene.add(
      three.DirectionalLight(0xFFF2DC, 1.7)..position.setValues(-3, 6, 6),
    );
    view.scene.add(
      three.DirectionalLight(0xD7EFFF, 0.65)..position.setValues(4, 3, -3),
    );
    // Layered ellipses make a soft contact shadow without a shadow-map pass.
    for (var i = 0; i < 5; i++) {
      view.scene.add(
        three.Mesh(
            three.SphereGeometry(1, 32, 8),
            three.MeshBasicMaterial({
              three.MaterialProperty.color: 0x31483B,
              three.MaterialProperty.transparent: true,
              three.MaterialProperty.opacity: 0.025,
              three.MaterialProperty.depthWrite: false,
            }),
          )
          ..position.setValues(0, -0.04 - i * 0.001, 0)
          ..scale.setValues(0.60 + i * 0.10, 0.018, 0.38 + i * 0.07),
      );
    }
  }

  void _recolor() {
    if (widget.source != CharacterHelper.sharedModelPath) return;
    final color = CharacterHelper.getColor(config.characterName);
    _skinPalette.setColor(
      color,
      originalGreen:
          CharacterHelper.getColorKey(config.characterName) == 'port',
    );
    _model?.traverse((object) {
      final material = object.material;
      if (material?.name == 'BodyColor' || material?.name == 'BodyDetail') {
        final shade = material!.name == 'BodyDetail' ? 0.55 : 1.0;
        material.color
            .setRGB(color.r * shade, color.g * shade, color.b * shade)
            .convertSRGBToLinear();
      }
    });
  }

  void _buildSkeleton() {
    final view = _view;
    if (view == null) return;
    _bones.removeWhere((bone) => bone.parent is! three.Bone);
    if (_bones.isEmpty) return;
    _skeletonPositions = three.Float32BufferAttribute.fromList(
      List<double>.filled(_bones.length * 6, 0),
      3,
    );
    final geometry = three.BufferGeometry()
      ..setAttributeFromString('position', _skeletonPositions!);
    _skeleton =
        three.LineSegments(
            geometry,
            three.LineBasicMaterial({
              three.MaterialProperty.color: 0xFFB547,
              three.MaterialProperty.depthTest: false,
              three.MaterialProperty.depthWrite: false,
            }),
          )
          ..frustumCulled = false
          ..renderOrder = 100
          ..visible = config.showSkeleton;
    view.scene.add(_skeleton!);
  }

  void _updateSkeleton() {
    if (_skeleton == null || !config.showSkeleton) return;
    for (var i = 0; i < _bones.length; i++) {
      _bones[i].getWorldPosition(_point);
      _skeletonPositions!.setXYZ(i * 2, _point.x, _point.y, _point.z);
      _bones[i].parent!.getWorldPosition(_point);
      _skeletonPositions!.setXYZ(i * 2 + 1, _point.x, _point.y, _point.z);
    }
    _skeletonPositions!.needsUpdate = true;
  }

  Duration get _position =>
      config.playbackPosition?.value ??
      Duration(microseconds: (_elapsed * 1000000).round());

  void _selectMotion() {
    final motion = config.motion ?? _plan.motionAt(_position);
    final next =
        _actions[motion.clipName] ??
        _actions['Idle'] ??
        (_actions.isEmpty ? null : _actions.values.first);
    if (next == null || identical(next, _activeAction)) return;
    final previous = _activeAction;
    next.reset().setEffectiveWeight(1).play();
    if (previous != null) next.crossFadeFrom(previous, 0.3);
    _activeAction = next;
  }

  void _onPosition() {
    final position = _position;
    if (position < _lastPosition ||
        (position - _lastPosition).inMilliseconds > 1200) {
      _mixer?.stopAllAction();
      _activeAction = null;
      _elapsed = position.inMicroseconds / 1000000;
      _selectMotion();
      final action = _activeAction;
      if (action != null && action.clip.duration > 0) {
        action.time = _elapsed % action.clip.duration;
      }
      _mixer?.update(0);
    }
    _lastPosition = position;
  }

  void _animate(double delta) {
    if (!mounted || !_foreground || !_tickerEnabled || _error != null) return;
    _orbit?.update();
    if (config.isPlaying) {
      final dt = delta.clamp(0.0, 0.08);
      _elapsed += dt;
      _selectMotion();
      _mixer?.update(dt);
      _speechBlend +=
          ((config.isSpeaking ? 1.0 : 0.0) - _speechBlend) *
          math.min(1.0, dt * 12);
      if (_speechBlend > 0.001 && _jaw != null && _jawRest != null) {
        final t = _position.inMicroseconds / 1000000;
        final syllable = math.pow(math.sin(t * 10.7), 2).toDouble();
        final envelope = math.sin(t * 2.1) > -0.65 ? 1.0 : 0.15;
        final clipOpening =
            2 * math.atan2(_jaw!.quaternion.x, _jaw!.quaternion.w);
        final speechOpening =
            (0.025 + syllable * envelope * 0.185) * _speechBlend;
        _jawRotation.setFromAxisAngle(
          _jawAxis,
          math.max(clipOpening, speechOpening),
        );
        _jaw!.quaternion.setFrom(_jawRest!).multiply(_jawRotation);
        // The mouth now has a sculpted opening and a hinged jaw. A modest
        // lip motion complements that geometry without stretching it across
        // the face during speech.
        _mouth?.scale.setValues(1, 1 + syllable * envelope * 1.6, 1);
      }
    }
    _updateSkeleton();
  }

  @override
  void didUpdateWidget(covariant _CharacterSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.configuration;
    debugPrint('SmartCharacterViewer didUpdateWidget: old=${old.characterName}, new=${config.characterName}');
    if (old.characterName != config.characterName) _recolor();
    if (old.storyText != config.storyText) {
      _plan = StoryMotionPlan.fromText(config.storyText);
      _elapsed = 0;
      _lastPosition = Duration.zero;
      _mixer?.stopAllAction();
      _activeAction = null;
    }
    if (old.playbackPosition != config.playbackPosition) {
      old.playbackPosition?.removeListener(_onPosition);
      config.playbackPosition?.addListener(_onPosition);
      _onPosition();
    }
    if (old.isSpeaking && !config.isSpeaking && _jawRest != null) {
      _jaw?.quaternion.setFrom(_jawRest!);
      _mouth?.scale.setValues(1, 1, 1);
    }
    _orbit?.enabled = config.interactive;
    _skeleton?.visible = config.showSkeleton;
    _selectMotion();
    _mixer?.update(0);
    _updateSkeleton();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _view?.visible = _foreground && _tickerEnabled && _error == null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _view?.visible = _foreground && _tickerEnabled && _error == null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    config.playbackPosition?.removeListener(_onPosition);
    _loadTimeout?.cancel();
    _disposeRenderer();
    super.dispose();
  }

  void _disposeRenderer() {
    _skinPalette.dispose();
    _orbit?.dispose();
    _orbit = null;
    _mixer?.stopAllAction();
    for (final action in _actions.values.toList()) {
      _mixer?.uncacheAction(action.clip, _model);
    }
    _view?.dispose();
    _view = null;
    _actions.clear();
    _bones.clear();
    _activeAction = null;
    _mixer = null;
    _model = null;
    _jaw = null;
    _mouth = null;
    _jawRest = null;
    _speechBlend = 0;
    _skeleton = null;
    _skeletonPositions = null;
  }

  void _restartRenderer() {
    _disposeRenderer();
    if (!mounted) return;
    setState(() {
      _error = null;
      _ready = false;
      _createView();
    });
  }

  void _retry() {
    _CharacterRendererHealth.reset();
    _compatibilityMode = false;
    _restartRenderer();
  }

  @override
  Widget build(BuildContext context) {
    final color = CharacterHelper.getColor(config.characterName);
    return Semantics(
      label:
          'شخصية ${CharacterHelper.getCleanName(config.characterName)} متحركة',
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The platform texture must stay in the tree while it initializes;
          // the fallback is painted above it until the first rendered frame.
          if (_view != null) _view!.build(),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'حدث خطأ في تشغيل 3D على هذا الجهاز/المحاكي:\n$_error',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          if (!_ready && _error == null)
            const SizedBox.shrink(),
          if (_error != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: FilledButton.tonalIcon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('تشغيل العرض ثلاثي الأبعاد'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fast, offline-safe visual shown while 3D initializes and on devices without
/// a compatible graphics driver. It preserves the character identity instead
/// of showing a dead-end error card.
class _CharacterFallback extends StatelessWidget {
  const _CharacterFallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _MascotFallbackPainter(color),
      child: const SizedBox.expand(),
    ),
  );
}

class _MascotFallbackPainter extends CustomPainter {
  _MascotFallbackPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const design = Size(260, 340);
    final scale = math.min(
      size.width / design.width,
      size.height / design.height,
    );
    canvas
      ..translate(
        (size.width - design.width * scale) / 2,
        (size.height - design.height * scale) / 2,
      )
      ..scale(scale);
    final body = Paint()..color = color;
    final shade = Paint()
      ..color = Color.alphaBlend(Colors.black.withOpacity(.22), color);
    final cream = Paint()..color = const Color(0xFFF4D999);
    final hat = Paint()..color = const Color(0xFF454951);
    final frame = Paint()
      ..color = const Color(0xFF36473F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final eye = Paint()..color = const Color(0xFFD9F09E);
    final pupil = Paint()..color = const Color(0xFF183B2B);

    canvas.drawOval(const Rect.fromLTWH(82, 246, 42, 58), body);
    canvas.drawOval(const Rect.fromLTWH(136, 246, 42, 58), body);
    canvas.drawOval(const Rect.fromLTWH(68, 125, 124, 148), body);
    canvas.drawOval(const Rect.fromLTWH(91, 145, 78, 112), cream);
    canvas.drawOval(const Rect.fromLTWH(50, 151, 37, 91), shade);
    canvas.drawOval(const Rect.fromLTWH(173, 151, 37, 91), shade);
    canvas.drawOval(const Rect.fromLTWH(48, 47, 164, 130), body);
    canvas.drawOval(const Rect.fromLTWH(72, 112, 116, 50), cream);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(54, 38, 152, 24),
        const Radius.circular(13),
      ),
      hat,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(78, 14, 104, 42),
        const Radius.circular(18),
      ),
      hat,
    );
    canvas.drawCircle(const Offset(94, 14), 13, hat);
    canvas.drawCircle(const Offset(166, 14), 13, hat);

    for (final center in const [Offset(103, 94), Offset(157, 94)]) {
      canvas.drawCircle(center, 26, eye);
      canvas.drawCircle(center, 26, frame);
      canvas.drawCircle(Offset(center.dx, center.dy + 2), 9, pupil);
      canvas.drawCircle(
        Offset(center.dx - 3, center.dy - 4),
        3,
        Paint()..color = Colors.white,
      );
    }
    canvas.drawLine(const Offset(129, 94), const Offset(131, 94), frame);
    canvas.drawOval(const Rect.fromLTWH(115, 75, 30, 17), shade);
    canvas.drawArc(
      const Rect.fromLTWH(102, 125, 56, 22),
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF7C2830)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    for (final x in [91.0, 103.0, 115.0, 145.0, 157.0, 169.0]) {
      canvas.drawOval(Rect.fromLTWH(x, 220, 8, 17), body);
    }
    for (final x in [93.0, 104.0, 115.0, 147.0, 158.0, 169.0]) {
      canvas.drawOval(Rect.fromLTWH(x, 285, 9, 13), body);
    }
  }

  @override
  bool shouldRepaint(covariant _MascotFallbackPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Contains native initialization/render errors and safely disposes textures
/// created after a route has already been closed.
class _GuardedThreeJS extends three.ThreeJS {
  _GuardedThreeJS({
    required super.size,
    required super.settings,
    required super.setup,
    required super.onSetupComplete,
    required this.onError,
  });
  final void Function(Object, StackTrace) onError;
  bool _initializing = false;
  bool _closing = false;
  bool _failed = false;

  @override
  Future<void> initPlatformState() async {
    if (_closing) return;
    _initializing = true;
    try {
      await super.initPlatformState();
    } catch (error, stack) {
      _failed = true;
      if (!_closing) onError(error, stack);
    } finally {
      _initializing = false;
      if (_closing) _finishDispose();
    }
  }

  @override
  Future<void> animate(Duration duration) async {
    if (_closing || _failed) return;
    try {
      await super.animate(duration);
    } catch (error, stack) {
      _failed = true;
      if (!_closing) onError(error, stack);
    }
  }

  @override
  void dispose() {
    if (_closing) return;
    _closing = true;
    visible = false;
    if (!_initializing) _finishDispose();
  }

  void _finishDispose() {
    final nativeAngle = angle;
    angle = null;
    super.dispose();
    // flutter_angle 0.4.2 assumes EGL initialized even when loading its native
    // library failed. A cleanup exception must not abort the route's disposal.
    try {
      nativeAngle?.dispose([texture]);
    } catch (error) {
      debugPrint(
        'Character native cleanup after initialization failure: $error',
      );
    }
  }
}
