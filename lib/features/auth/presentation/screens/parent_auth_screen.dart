import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../../core/theme/app_colors.dart';
import '../../data/parent_google_auth.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      unawaited(_onAuth(data));
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

  Future<void> _onAuth(dynamic data) async {
    if (!_awaitingGoogle) return;
    final session = data.session;
    if (data.event != AuthChangeEvent.signedIn || session == null) return;
    if (!ParentGoogleAuth.isGoogleUser(session.user)) return;
    _awaitingGoogle = false;
    try {
      await ParentGoogleAuth.rememberAsParent(session);
      if (!mounted) return;
      context.go('/parent-dashboard');
    } catch (error) {
      if (!mounted) return;
      setState(() => _googleBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
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
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دخول ولي الأمر'),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          state.maybeWhen(
            parentRegistered: (user) {
              context.go('/parent-dashboard');
            },
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          final isLoading = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );

          return SingleChildScrollView(
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
                  onPressed: isLoading ? null : () {
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();

                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('الرجاء تعبئة البريد وكلمة المرور')),
                      );
                      return;
                    }

                    context.read<AuthBloc>().add(AuthEvent.registerParent(
                      email: email,
                      password: password,
                      childCode: '',
                    ));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('تسجيل ومتابعة'),
                ),
                const SizedBox(height: 16),
                const Text('أو', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: isLoading || _googleBusy ? null : _google,
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
          );
        },
      ),
    );
  }
}
