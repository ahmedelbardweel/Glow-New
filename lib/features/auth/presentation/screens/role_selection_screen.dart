import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/child_account_sheets.dart';
import '../../../organization/presentation/widgets/student_join_sheet.dart';
import '../widgets/account_transfer_sheets.dart';

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
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final code = await showAccountScanner(context);
              if (code == null || !context.mounted) return;
              await claimScannedCode(context, code);
            },
            child: const Text(
              'مسح QR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(10.0),
          children: [
            const SizedBox(height: 20),
            _buildRoleCard(
              context,
              title: 'طفل (مغامر صغير)',
              color: Theme.of(context).colorScheme.tertiary,
              onTap: () {
                HapticFeedback.lightImpact();
                showChildRoleSheet(context);
              },
            ),
            const SizedBox(height: 10),
            _buildRoleCard(
              context,
              title: 'ولي أمر (متابع الأبطال)',
              color: Theme.of(context).colorScheme.secondary,
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/parent-auth');
              },
            ),
            const SizedBox(height: 10),
            _buildRoleCard(
              context,
              title: 'منظمة',
              color: Theme.of(context).colorScheme.secondary,
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/organization-auth');
              },
            ),
            const SizedBox(height: 10),
            _buildRoleCard(
              context,
              title: 'طالب',
              color: Theme.of(context).colorScheme.tertiary,
              onTap: () {
                HapticFeedback.lightImpact();
                startStudentJoin(context);
              },
            ),
            const SizedBox(height: 10),
            _buildRoleCard(
              context,
              title: 'إدارة النظام (مشرف)',
              color: Theme.of(context).colorScheme.primary,
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/admin-login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                'دخول',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
