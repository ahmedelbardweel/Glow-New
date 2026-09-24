import 'package:Glow/core/network/network_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/device_id_helper.dart';
import '../../data/datasources/auth_local_data_source.dart';
import '../../data/models/child_profile_model.dart';
import '../../../../core/network/network_info.dart';
import '../../../content/data/services/sync_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showButton = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final localDataSource = sl<AuthLocalDataSource>();
    final cachedUser = await localDataSource.getLastUser();
    final isConnected = await sl<NetworkInfo>().isConnected;

    if (cachedUser != null) {
      if (cachedUser.role == 'admin') {
        if (mounted) context.go('/admin-dashboard');
      } else {
        if (mounted) context.go('/parent-dashboard');
      }
      return;
    } 

    final cachedChild = await localDataSource.getLastChild();
    if (cachedChild != null) {
      if (isConnected) {
        if (mounted) setState(() { _isSyncing = true; });
        await sl<SyncService>().syncAll(childId: cachedChild.id, silent: true);
      }
      if (mounted) context.go('/child-dashboard');
      return;
    }

    if (!isConnected) {
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
        setState(() {
          _showButton = true;
        });
      }
      return;
    }

    // Attempt silent login via device ID
    try {
      if (mounted) setState(() { _isSyncing = true; });
      final deviceId = await DeviceIdHelper.getDeviceId();
      final email = DeviceIdHelper.generateDeviceEmail(deviceId);
      final password = DeviceIdHelper.generateDevicePassword(deviceId);

      final supabase = Supabase.instance.client;
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Fetch child profile
        final data = await supabase
            .from('children_profiles')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (data != null) {
          final child = ChildProfileModel.fromJson(data);
          await localDataSource.cacheChild(child);
          await sl<SyncService>().syncAll(childId: child.id, silent: true);
          if (mounted) {
            context.go('/child-dashboard');
            return;
          }
        }
      }
    } catch (_) {
      // Silent login failed, proceed to show button
    }

    // If nothing is cached or silent login fails, stay on splash screen and show the button
    if (mounted) {
      setState(() {
        _isSyncing = false;
        _showButton = true;
      });
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
                Image.asset('assets/images/logo.png', width: double.infinity),
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
