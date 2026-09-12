import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/auth_local_data_source.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final localDataSource = sl<AuthLocalDataSource>();
    final cachedUser = await localDataSource.getLastUser();
    
    if (cachedUser != null) {
      if (cachedUser.role == 'admin') {
        if (mounted) context.go('/admin-dashboard');
      } else {
        if (mounted) context.go('/parent-dashboard');
      }
    } else {
      final cachedChild = await localDataSource.getLastChild();
      if (cachedChild != null) {
        if (mounted) context.go('/child-dashboard');
      } else {
        // If nothing is cached, stay on splash screen and show the button
        if (mounted) {
          setState(() {
            _showButton = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: double.infinity,
                  ),
                  const SizedBox(height: 0),
                  if (_showButton)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.go('/role-selection');
                          },
                          child: const Text('ابدأ الرحلة'),
                        ),
                      ),
                    ),
                  const Spacer(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
