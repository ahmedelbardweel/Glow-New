import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';

class ParentGoogleSignInPage extends StatefulWidget {
  const ParentGoogleSignInPage({super.key});

  @override
  State<ParentGoogleSignInPage> createState() => _ParentGoogleSignInPageState();
}

class _ParentGoogleSignInPageState extends State<ParentGoogleSignInPage> {
  WebViewController? _controller;
  var _done = false;

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
    final response = await Supabase.instance.client.auth.getOAuthSignInUrl(
      provider: OAuthProvider.google,
      redirectTo: 'glow://parent-auth',
    );
    if (!mounted) return;
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.surface)
      ..setUserAgent(Platform.isIOS ? _iosAgent : _androidAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
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
      ..loadRequest(Uri.parse(response.url));
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
      final result = await Supabase.instance.client.auth.getSessionFromUrl(Uri.parse(url));
      if (!mounted) return;
      Navigator.of(context).pop(result.session);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
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
      body: controller == null
          ? const SizedBox.expand()
          : WebViewWidget(controller: controller),
    );
  }
}
