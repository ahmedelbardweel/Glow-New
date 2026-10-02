import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/parent_google_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/email_code_sheet.dart';

class ParentAuthScreen extends StatefulWidget {
  const ParentAuthScreen({super.key});

  @override
  State<ParentAuthScreen> createState() => _ParentAuthScreenState();
}

class _ParentAuthScreenState extends State<ParentAuthScreen> with WidgetsBindingObserver {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  StreamSubscription<dynamic>? _authSub;
  var _awaitingGoogle = false;
  var _googleBusy = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = ParentGoogleAuth.googleSignIns.listen((_) {
      unawaited(_onAuth());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_awaitingGoogle) return;
    Future<void>.delayed(const Duration(seconds: 8), () {
      if (!mounted || !_awaitingGoogle) return;
      setState(() {
        _awaitingGoogle = false;
        _googleBusy = false;
      });
    });
  }

  Future<void> _onAuth() async {
    if (!_awaitingGoogle) return;
    final session = ParentGoogleAuth.googleSessionOrNull();
    if (session == null) return;
    _awaitingGoogle = false;
    try {
      final email = session.user.email ?? '';
      if (!await confirmOwnEmail(context, email)) {
        if (mounted) setState(() => _googleBusy = false);
        return;
      }
      if (!mounted) return;
      await ParentGoogleAuth.rememberAsParent(session);
      if (!mounted) return;
      setState(() => _googleBusy = false);
      context.go('/parent-dashboard');
    } catch (error) {
      if (!mounted) return;
      setState(() => _googleBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage(error, fallback: 'تعذر الدخول. حاول مرة أخرى.')),
        ),
      );
    }
  }

  Future<void> _enterParent(String email) async {
    final ok = await confirmOwnEmail(context, email);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    context.go('/parent-dashboard');
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة البريد وكلمة المرور')),
      );
      return;
    }
    setState(() => _busy = true);
    final result = await sl<AuthRepository>().loginParent(
      email: email,
      password: password,
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage(failure.message))),
        );
      },
      (user) => unawaited(_enterParent(user.email)),
    );
  }

  Future<void> _google() async {
    setState(() => _googleBusy = true);
    _awaitingGoogle = false;
    try {
      final session = await ParentGoogleAuth.signIn(context);
      if (!mounted) return;
      if (session == null) {
        setState(() {
          _awaitingGoogle = false;
          _googleBusy = false;
        });
        return;
      }
      _awaitingGoogle = false;
      final email = session.user.email ?? '';
      if (!await confirmOwnEmail(context, email)) {
        if (mounted) setState(() => _googleBusy = false);
        return;
      }
      if (!mounted) return;
      await ParentGoogleAuth.rememberAsParent(session);
      if (!mounted) return;
      context.go('/parent-dashboard');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _awaitingGoogle = false;
        _googleBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage(error, fallback: 'تعذر الدخول. حاول مرة أخرى.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/role-selection');
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'رجوع',
          icon: const BackButtonIcon(),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/role-selection');
            }
          },
        ),
        title: const Text('دخول ولي الأمر'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.family_restroom, size: 80, color: Colors.orange),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    hintText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _busy || _googleBusy ? null : _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                  child: _busy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('تسجيل الدخول'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy || _googleBusy
                      ? null
                      : () => context.push('/parent-register'),
                  child: const Text('إنشاء حساب ولي أمر'),
                ),
                const SizedBox(height: 8),
                const Text('أو', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _busy || _googleBusy ? null : _google,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.inputBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.border_radius),
                    ),
                  ),
                  child: _googleBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('الدخول بحساب جوجل'),
                ),
              ],
            ),
          ),
      ),
    );
  }
}
