import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/admin_api_keys.dart';
import '../../../../core/config/eleven_credit.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../content/data/services/launch_admin_package.dart';
import '../../../organization/presentation/widgets/create_organization_sheet.dart';
import '../../../organization/presentation/widgets/staff_settings_sheet.dart';
import '../widgets/admin_api_keys_sheet.dart';

class ContentPackagesScreen extends StatefulWidget {
  const ContentPackagesScreen({super.key});

  @override
  State<ContentPackagesScreen> createState() => _ContentPackagesScreenState();
}

class _ContentPackagesScreenState extends State<ContentPackagesScreen> {
  late Future<List<Map<String, dynamic>>> _packages;

  @override
  void initState() {
    super.initState();
    _packages = _load();
  }

  String _apiKeysSubtitle(ElevenCredit credit) {
    final parts = <String>[];
    if (credit.state == ElevenCreditState.ready) {
      parts.add('Eleven المتبقي ${groupDigits(credit.remaining)}');
    } else if (credit.exhausted || credit.state == ElevenCreditState.invalid) {
      parts.add('Eleven ${credit.label}');
    }
    if (AdminApiKeys.geminiExhausted) parts.add('Gemini خلص الرصيد');
    parts.insert(0, AdminApiKeys.montageChoice.label);
    if (parts.length == 1) return 'المونتاج: ${AdminApiKeys.montageChoice.label}';
    return parts.join(' · ');
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = sl<SupabaseClient>();
    final rows = await client
        .from('content_packages')
        .select('id,title,description,cover_url,status,version,draft_content,updated_at')
        .order('updated_at', ascending: false);
    if (!rows.any((row) => row['id'] == LaunchAdminPackage.id)) {
      await LaunchAdminPackage.ensureCreated(client);
      final starter = await client.from('content_packages').select()
          .eq('id', LaunchAdminPackage.id).single();
      rows.insert(0, starter);
    }
    final packages = List<Map<String, dynamic>>.from(rows);
    final starterIndex = packages.indexWhere((row) => row['id'] == LaunchAdminPackage.id);
    if (starterIndex > 0) packages.insert(0, packages.removeAt(starterIndex));
    final worldIds = <String>{};
    for (final package in packages) {
      final draft = package['draft_content'];
      if (draft is! Map || draft['worlds'] is! List) continue;
      for (final world in draft['worlds'] as List) {
        if (world is Map && world['id'] is String) worldIds.add(world['id'] as String);
      }
    }
    if (worldIds.isNotEmpty) {
      // One aggregate request for every card, rather than loading each habit.
      final counts = await client.from('worlds').select('id,missions(count)')
          .inFilter('id', worldIds.toList());
      final byWorld = <String, int>{};
      for (final row in counts) {
        final missions = row['missions'] as List;
        byWorld[row['id'] as String] = missions.isEmpty ? 0 : (missions.first['count'] as num).toInt();
      }
      for (final package in packages) {
        final draft = package['draft_content'];
        final worlds = draft is Map && draft['worlds'] is List ? draft['worlds'] as List : const [];
        package['_mission_count'] = worlds.fold<int>(0,
            (count, world) => count + (world is Map ? byWorld[world['id']] ?? 0 : 0));
      }
    }
    return packages;
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final request = _load();
    setState(() => _packages = request);
    await request;
  }

  Future<void> _createPackage() async {
    HapticFeedback.lightImpact();
    final result = await showAppSheet<Map<String, String>>(
      context: context,
      heightFactor: 0.58,
      avoidKeyboard: true,
      builder: (sheetContext) => const _PackageFormSheet(
        title: 'بكج جديد',
        subtitle: 'أنشئ بكجًا جديدًا لجمع العوالم والعادات قبل نشرها للمستخدمين',
        submitLabel: 'إنشاء مسودة',
      ),
    );
    if (result == null || (result['title'] ?? '').trim().isEmpty || !mounted) return;
    try {
      final row = await sl<SupabaseClient>().from('content_packages').insert({
        'title': result['title']!.trim(),
        'description': (result['description'] ?? '').trim(),
        'created_by': sl<SupabaseClient>().auth.currentUser?.id,
        'draft_content': {'worlds': []},
      }).select('id').single();
      await _refresh();
      if (mounted) context.push('/admin/packages/${row['id']}');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deletePackage(String id, String title) async {
    HapticFeedback.lightImpact();
    final confirm = await showAppSheet<bool>(
      context: context,
      heightFactor: 0.38,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تأكيد الحذف',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'هل أنت متأكد من حذف البكج "$title"؟ سيتم حذف المسودة نهائياً.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.border_radius),
                  ),
                ),
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: const Text('حذف البكج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await sl<SupabaseClient>().from('content_packages').delete().eq('id', id);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف البكج بنجاح')),
        );
      }
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editPackageMeta(Map<String, dynamic> package) async {
    HapticFeedback.lightImpact();
    final result = await showAppSheet<Map<String, String>>(
      context: context,
      heightFactor: 0.58,
      avoidKeyboard: true,
      builder: (sheetContext) => _PackageFormSheet(
        title: 'تعديل بيانات البكج',
        subtitle: 'تعديل اسم ووصف البكج الحالي',
        initialTitle: '${package['title'] ?? ''}',
        initialDescription: '${package['description'] ?? ''}',
        submitLabel: 'حفظ التعديلات',
      ),
    );
    if (result == null || (result['title'] ?? '').trim().isEmpty || !mounted) return;
    try {
      await sl<SupabaseClient>().from('content_packages').update({
        'title': result['title']!.trim(),
        'description': (result['description'] ?? '').trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', package['id']);
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تعذر تنفيذ العملية: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('إدارة البكجات'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.tonalIcon(
              onPressed: () {
                context.push('/custom-character-creator');
              },
              label: const Text(
                'شخصيتك',
                style: TextStyle(fontWeight: FontWeight.bold,fontSize: 10),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.more_vert),
            onPressed: () async {
              await AdminApiKeys.sync();
              if (!context.mounted) return;
              final credit = await ElevenCredit.load();
              if (!context.mounted) return;
              showStaffSettingsSheet(
                context,
                settings: [
                  StaffSetting(
                    title: 'بكجات المحتوى',
                    subtitle: 'إنشاء ومتابعة ونشر بكجات العوالم والعادات',
                    onTap: (sheetContext) async {
                      Navigator.of(sheetContext).pop();
                      context.push('/admin/packages');
                    },
                  ),
                  StaffSetting(
                    title: 'مفاتيح الصوت والمونتاج',
                    subtitle: _apiKeysSubtitle(credit),
                    onTap: (sheetContext) async {
                      Navigator.of(sheetContext).pop();
                      if (!context.mounted) return;
                      await showAdminApiKeysSheet(context);
                    },
                  ),
                  StaffSetting(
                    title: 'إنشاء حساب منظمة',
                    subtitle: 'اسم وبريد وكلمة مرور. المنظمة تدخل بهما لاحقاً',
                    onTap: (sheetContext) async {
                      Navigator.of(sheetContext).pop();
                      if (!context.mounted) return;
                      await showCreateOrganizationSheet(context);
                    },
                  ),
                ],
                onLogout: () async {
                  await sl<AuthLocalDataSource>().clearCache();
                  if (context.mounted) context.go('/role-selection');
                },
              );
            },
          ),

        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPackage,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.border_radius),
        ),
        icon: const Icon(Icons.add),
        label: const Text('بكج جديد', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _packages,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'تعذر تحميل البكجات. تأكد من تطبيق مخطط Supabase وتسجيل الدخول كأدمن.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) return _emptyState();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: items.length,
              itemBuilder: (context, index) => _PackageCard(
                package: items[index],
                onTap: () => context.push('/admin/packages/${items[index]['id']}').then((_) => _refresh()),
                onEdit: () => _editPackageMeta(items[index]),
                onDelete: () => _deletePackage(
                  items[index]['id'].toString(),
                  items[index]['title']?.toString() ?? '',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                'لا توجد بكجات محتوى حتى الآن',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'أنشئ بكجًا واجمع فيه العوالم والعادات والقصص قبل نشرها للمستخدمين.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
}

class _PackageFormSheet extends StatefulWidget {
  const _PackageFormSheet({
    required this.title,
    required this.subtitle,
    this.initialTitle = '',
    this.initialDescription = '',
    required this.submitLabel,
  });

  final String title;
  final String subtitle;
  final String initialTitle;
  final String initialDescription;
  final String submitLabel;

  @override
  State<_PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends State<_PackageFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _desc;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _desc = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.secondary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'اسم البكج'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'وصف مختصر'),
            ),
            const Spacer(),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                ),
              ),
              onPressed: () {
                if (_title.text.trim().isEmpty) return;
                Navigator.of(context).pop({
                  'title': _title.text.trim(),
                  'description': _desc.text.trim(),
                });
              },
              child: Text(
                widget.submitLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> package;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final draft = package['draft_content'];
    final worlds = draft is Map && draft['worlds'] is List ? draft['worlds'] as List : const [];
    final missionCount = package['_mission_count'] as int? ?? worlds.fold<int>(0, (sum, world) {
      if (world is! Map || world['habits'] is! List) return sum;
      return sum + (world['habits'] as List).length;
    });
    final published = package['status'] == 'published';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.border_radius),
        border: Border.all(color: AppColors.inputBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(AppColors.border_radius),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${package['title'] ?? 'بكج بدون اسم'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          if ((package['description'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${package['description']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _StatusPill(published: published),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 25, color: Colors.black54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.border_radius),
                      ),
                      onSelected: (val) {
                        if (val == 'edit') {
                          onEdit();
                        } else if (val == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('تعديل البيانات'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('حذف البكج', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (worlds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < worlds.length && i < 3; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(AppColors.border_radius),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.public, size: 12, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                worlds[i] is Map ? '${worlds[i]['title'] ?? 'عالم'}' : 'عالم',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (worlds.length > 3)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(AppColors.border_radius),
                          ),
                          child: Text(
                            '+${worlds.length - 3}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 5),
                const Divider(height: 1, color: AppColors.inputBorder),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _Badge(
                      icon: Icons.public_rounded,
                      value: '${worlds.length}',
                      label: 'عوالم',
                      bgColor: AppColors.secondaryContainer,
                      fgColor: AppColors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    _Badge(
                      icon: Icons.auto_awesome_rounded,
                      value: '$missionCount',
                      label: 'عادات',
                      bgColor: AppColors.primaryContainer,
                      fgColor: AppColors.onPrimaryContainer,
                    ),
                    const Spacer(),
                    Text(
                      'الإصدار ${package['version'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 13,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.published});
  final bool published;

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: published ? AppColors.tertiaryContainer : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppColors.border_radius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            Text(
              published ? 'منشور' : 'مسودة',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: published ? AppColors.onTertiaryContainer : AppColors.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.value,
    required this.label,
    required this.bgColor,
    required this.fgColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppColors.border_radius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: 4),
            Text(
              '$value $label',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      );
}
