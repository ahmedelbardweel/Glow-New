import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/audio/child_button_clips.dart';
import '../../../../core/audio/child_button_voice.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/network_info.dart';
import '../../data/child_account_service.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/parent_google_auth.dart';
import '../../../content/data/services/sync_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showButton = false;
  final Completer<void> _logoDone = Completer<void>();

  Future<void> _holdForLogo() async {
    await _logoDone.future;
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  void initState() {
    super.initState();
    unawaited(ChildButtonVoice.warm());
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final localDataSource = sl<AuthLocalDataSource>();
    final cachedUser = await localDataSource.getLastUser();

    if (cachedUser != null) {
      if (!mounted) return;
      if (cachedUser.role == 'admin') {
        _go('/admin-dashboard');
      } else if (cachedUser.role == 'organization') {
        _go('/organization-dashboard');
      } else if (cachedUser.role == 'teacher') {
        _go('/teacher-dashboard');
      } else {
        _go('/parent-dashboard');
      }
      return;
    }

    final googleSession = ParentGoogleAuth.googleSessionOrNull();
    if (googleSession != null) {
      try {
        await ParentGoogleAuth.rememberAsParent(googleSession);
        if (mounted) _go('/parent-dashboard');
        return;
      } catch (_) {}
    }

    final restored = await sl<ChildAccountService>().restoreLastChild();
    final cachedChild = restored ?? await localDataSource.getLastChild();
    final isConnected = await sl<NetworkInfo>().isConnected;

    if (!isConnected) {
      if (cachedChild != null) {
        if (mounted) _go('/child-dashboard');
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'يجب الاتصال بالإنترنت في أول تشغيل للتطبيق لتنزيل المحتوى.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _revealStartButton();
      }
      return;
    }

    if (cachedChild != null) {
      unawaited(_syncChildIfNeeded(cachedChild.id));
      sl<SyncService>().prefetchCachedStoryAudio();
      if (mounted) await _go('/child-dashboard');
      return;
    }

    try {
      final child = await sl<ChildAccountService>().signInKnownDevice();
      if (child != null) {
        await sl<ChildAccountService>().rememberExisting(child: child, slot: '');
        await _syncChildIfNeeded(child.id);
        sl<SyncService>().prefetchCachedStoryAudio();
        if (mounted) {
          _go('/child-dashboard');
          return;
        }
      }
    } catch (_) {
      // Silent login failed, proceed to show button
    }

    if (mounted) _revealStartButton();
  }

  Future<void> _go(String route) async {
    await _holdForLogo();
    if (!mounted) return;
    await _sayAppName();
    if (!mounted) return;
    context.go(route);
  }

  void _revealStartButton() {
    unawaited(() async {
      await _holdForLogo();
      if (!mounted) return;
      setState(() => _showButton = true);
      unawaited(_welcomeFirstVisit());
    }());
  }

  /// Every splash says the app name from a bundled clip.
  Future<void> _sayAppName() async {
    if (!childButtonClips.containsKey('Glow')) return;
    await ChildButtonVoice.warm();
    await ChildButtonVoice.playSequence(const ['Glow']);
  }

  /// The first time the start button appears, greet the child, say Glow,
  /// then read the button. Later splash visits only say the name.
  Future<void> _welcomeFirstVisit() async {
    const first = ['أهلاً بك', 'Glow', 'ابدأ الرحلة'];
    final box = Hive.box('auth');
    final heard = box.get('SPLASH_WELCOME_HEARD') == true;
    final phrases = heard ? const ['Glow'] : first;
    if (phrases.any((phrase) => !childButtonClips.containsKey(phrase))) return;
    if (!heard) await box.put('SPLASH_WELCOME_HEARD', true);
    await ChildButtonVoice.warm();
    await ChildButtonVoice.playSequence(phrases);
  }

  Future<void> _syncChildIfNeeded(String childId) async {
    final sync = sl<SyncService>();
    if (!await sync.needsSync()) return;
    await sync.syncAll(childId: childId, silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final overhang = MediaQuery.viewPaddingOf(context).top + 16;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _HangingLogo(
                      overhang: overhang,
                      onFinished: () {
                        if (!_logoDone.isCompleted) _logoDone.complete();
                      },
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _showButton ? 1 : 0,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOut,
                    child: IgnorePointer(
                      ignoring: !_showButton,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ChildButtonVoice.press('ابدأ الرحلة', () async {
                              if (context.mounted) context.go('/role-selection');
                            });
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'ابدأ الرحلة',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo canvas the cut pieces were taken from.
const double _logoCanvasW = 1280;
const double _logoCanvasH = 853;

class _LogoPiece {
  const _LogoPiece(this.asset, this.x, this.y, this.w, this.h);

  final String asset;
  final double x;
  final double y;
  final double w;
  final double h;
}

const _letters = <_LogoPiece>[
  _LogoPiece('assets/images/logo_g.png', 159, 219, 273, 284),
  _LogoPiece('assets/images/logo_l.png', 442, 266, 150, 224),
  _LogoPiece('assets/images/logo_o.png', 582, 143, 298, 360),
  _LogoPiece('assets/images/logo_w.png', 849, 291, 272, 200),
];

const _line = _LogoPiece('assets/images/logo_line.png', 403, 474, 470, 93);
const _caption = _LogoPiece('assets/images/logo_text.png', 239, 588, 801, 65);

/// Letters drop from the top center into their logo places, then the line
/// fades in and the caption rises. Motion is paint-only so it stays smooth.
class _HangingLogo extends StatefulWidget {
  const _HangingLogo({required this.overhang, required this.onFinished});

  /// Distance from this box to the top of the screen, so the thread
  /// starts above the safe area.
  final double overhang;
  final VoidCallback onFinished;

  @override
  State<_HangingLogo> createState() => _HangingLogoState();
}

class _HangingLogoState extends State<_HangingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _play;
  late final List<CurvedAnimation> _letterT;
  late final CurvedAnimation _lineT;
  late final CurvedAnimation _captionT;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _play = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _letterT = [
      for (var i = 0; i < _letters.length; i++)
        CurvedAnimation(
          parent: _play,
          curve: Interval(i * 0.08, i * 0.08 + 0.36, curve: Curves.easeOutCubic),
        ),
    ];
    _lineT = CurvedAnimation(
      parent: _play,
      curve: const Interval(0.70, 0.86, curve: Curves.easeOut),
    );
    _captionT = CurvedAnimation(
      parent: _play,
      curve: const Interval(0.86, 1, curve: Curves.easeOutCubic),
    );
    _play.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onFinished();
    });
  }

  void _playOnce(List<ImageProvider> frames) {
    if (_started) return;
    _started = true;
    unawaited(() async {
      await Future.wait([
        for (final frame in frames) precacheImage(frame, context),
      ]);
      if (mounted) _play.forward();
    }());
  }

  @override
  void dispose() {
    for (final animation in _letterT) {
      animation.dispose();
    }
    _lineT.dispose();
    _captionT.dispose();
    _play.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final maxH = constraints.maxHeight;
            if (maxW <= 0 || maxH <= 0) return const SizedBox.shrink();
            final scale = math.min(maxW / _logoCanvasW, maxH / _logoCanvasH);
            final logoTop = (maxH - _logoCanvasH * scale) / 2;
            final logoLeft = (maxW - _logoCanvasW * scale) / 2;
            final anchorX = maxW / 2;
            final dpr = MediaQuery.devicePixelRatioOf(context);
            final frames = <ImageProvider>[
              for (final piece in [..._letters, _line, _caption])
                ResizeImage(
                  AssetImage(piece.asset),
                  width: math.max(1, (piece.w * scale * dpr).round()),
                  height: math.max(1, (piece.h * scale * dpr).round()),
                ),
            ];
            _playOnce(frames);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < _letters.length; i++)
                  _placed(
                    piece: _letters[i],
                    scale: scale,
                    logoLeft: logoLeft,
                    logoTop: logoTop,
                    child: _slide(
                      animation: _letterT[i],
                      piece: _letters[i],
                      scale: scale,
                      logoLeft: logoLeft,
                      logoTop: logoTop,
                      anchorX: anchorX,
                      fromTop: -widget.overhang,
                    ),
                  ),
                _placed(
                  piece: _line,
                  scale: scale,
                  logoLeft: logoLeft,
                  logoTop: logoTop,
                  child: _fadeRise(
                    animation: _lineT,
                    rise: 10,
                    piece: _line,
                    scale: scale,
                  ),
                ),
                _placed(
                  piece: _caption,
                  scale: scale,
                  logoLeft: logoLeft,
                  logoTop: logoTop,
                  child: _fadeRise(
                    animation: _captionT,
                    rise: _caption.h * scale,
                    piece: _caption,
                    scale: scale,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _placed({
    required _LogoPiece piece,
    required double scale,
    required double logoLeft,
    required double logoTop,
    required Widget child,
  }) {
    return Positioned(
      left: logoLeft + piece.x * scale,
      top: logoTop + piece.y * scale,
      width: piece.w * scale,
      height: piece.h * scale,
      child: child,
    );
  }

  Widget _slide({
    required Animation<double> animation,
    required _LogoPiece piece,
    required double scale,
    required double logoLeft,
    required double logoTop,
    required double anchorX,
    required double fromTop,
  }) {
    final width = piece.w * scale;
    final height = piece.h * scale;
    final restLeft = logoLeft + piece.x * scale;
    final begin = Offset(anchorX - width / 2 - restLeft, fromTop - height - (logoTop + piece.y * scale));
    return AnimatedBuilder(
      animation: animation,
      child: _bitmap(piece, width, height),
      builder: (context, child) {
        final t = animation.value;
        return Transform.translate(
          offset: Offset(begin.dx * (1 - t), begin.dy * (1 - t)),
          child: child,
        );
      },
    );
  }

  Widget _fadeRise({
    required Animation<double> animation,
    required double rise,
    required _LogoPiece piece,
    required double scale,
  }) {
    return AnimatedBuilder(
      animation: animation,
      child: _bitmap(piece, piece.w * scale, piece.h * scale),
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, rise * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _bitmap(_LogoPiece piece, double width, double height) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return RepaintBoundary(
      child: Image(
        image: ResizeImage(
          AssetImage(piece.asset),
          width: math.max(1, (width * dpr).round()),
          height: math.max(1, (height * dpr).round()),
        ),
        width: width,
        height: height,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
      ),
    );
  }
}
