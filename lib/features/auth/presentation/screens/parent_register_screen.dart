import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/user_message.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/email_code_sheet.dart';

class ParentRegisterScreen extends StatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  State<ParentRegisterScreen> createState() => _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends State<ParentRegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _afterCreate(String email) async {
    final ok = await confirmOwnEmail(context, email);
    if (!ok || !mounted) return;
    context.go('/parent-dashboard');
  }

  void _submit() {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اكتب البريد وكلمة مرور من ستة أحرف على الأقل.'),
        ),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthEvent.registerParent(
          email: email,
          password: password,
          childCode: '',
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب ولي الأمر'),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          state.maybeWhen(
            parentRegistered: (user) => unawaited(_afterCreate(user.email)),
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(userMessage(message))),
              );
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          final busy = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.family_restroom, size: 80, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'حساب جديد لولي الأمر فقط. بعد إنشائه تدخل بالبريد وكلمة المرور.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: busy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إنشاء الحساب'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: busy ? null : () => context.pop(),
                  child: const Text('لديك حساب؟ تسجيل الدخول'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
