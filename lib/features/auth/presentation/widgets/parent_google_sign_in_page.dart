import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/app_colors.dart';

class ParentGoogleSignInPage extends StatefulWidget {
  const ParentGoogleSignInPage({super.key, required this.authorizationUrl});

  final Future<String> Function() authorizationUrl;

  @override
  State<ParentGoogleSignInPage> createState() => _ParentGoogleSignInPageState();
}

class _ParentGoogleSignInPageState extends State<ParentGoogleSignInPage> {
  WebViewController? _controller;
  var _done = false;
  var _pageLoading = true;

  static const _androidAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36';
  static const _iosAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    final url = await widget.authorizationUrl();
    if (!mounted) return;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surface)
      ..setUserAgent(Platform.isIOS ? _iosAgent : _androidAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _pageLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _pageLoading = false);
          },
          onNavigationRequest: (request) {
            if (_isCallback(request.url)) {
              unawaited(_finish(request.url));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null && _isCallback(url)) unawaited(_finish(url));
          },
          onWebResourceError: (error) {
            final url = error.url;
            if (url != null && _isCallback(url)) unawaited(_finish(url));
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
    setState(() => _controller = controller);
  }

  bool _isCallback(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'glow' && uri.host == 'parent-auth';
  }

  Future<void> _finish(String url) async {
    if (_done) return;
    _done = true;
    try {
      if (!mounted) return;
      Navigator.of(context).pop(url);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage(error, fallback: 'تعذر فتح صفحة جوجل. حاول مرة أخرى.')),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('حساب جوجل'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.secondary,
      ),
      body: Stack(
        children: [
          if (controller != null) WebViewWidget(controller: controller),
          if (controller == null || _pageLoading) const _GooglePageLoader(),
        ],
      ),
    );
  }
}

class _GooglePageLoader extends StatelessWidget {
  const _GooglePageLoader();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 148,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
