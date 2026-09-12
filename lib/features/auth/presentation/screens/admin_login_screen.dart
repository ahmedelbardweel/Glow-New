import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دخول الإدارة'),
        centerTitle: true,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          state.maybeWhen(
            adminLoggedIn: (user) {
              context.go('/admin-dashboard');
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
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني للإدارة',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
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
                        const SnackBar(content: Text('الرجاء تعبئة جميع الحقول')),
                      );
                      return;
                    }

                    context.read<AuthBloc>().add(AuthEvent.loginAdmin(
                      email: email,
                      password: password,
                    ));
                  },
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('تسجيل الدخول'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
