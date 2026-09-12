import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'من أنت؟',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildRoleCard(
                context,
                title: 'طفل (مغامر صغير)',
                icon: Icons.face_retouching_natural,
                color: Theme.of(context).colorScheme.tertiary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/child-onboarding');
                },
              ),
              const SizedBox(height: 10),
              _buildRoleCard(
                context,
                title: 'ولي أمر (متابع الأبطال)',
                icon: Icons.family_restroom,
                color: Theme.of(context).colorScheme.secondary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/parent-auth');
                },
              ),
              const SizedBox(height: 10),
              _buildRoleCard(
                context,
                title: 'إدارة النظام (مشرف)',
                icon: Icons.admin_panel_settings,
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go('/admin-login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
