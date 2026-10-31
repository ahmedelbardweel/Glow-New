import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/admin_api_keys.dart';
import '../../../../core/config/eleven_credit.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../widgets/package_wallet_card.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../content/data/services/habits_pack_two.dart';
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
    if (parts.length == 1)
      return 'المونتاج: ${AdminApiKeys.montageChoice.label}';
    return parts.join(' · ');
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final client = sl<SupabaseClient>();
    final rows = await client
        .from('content_packages')
        .select(
          'id,title,description,cover_url,status,version,draft_content,updated_at',
        )
        .order('updated_at', ascending: false);
    if (!rows.any((row) => row['id'] == LaunchAdminPackage.id)) {
      try {
        await LaunchAdminPackage.ensureCreated(client);
        final starter = await client
            .from('content_packages')
            .select()
            .eq('id', LaunchAdminPackage.id)
            .single();
        rows.insert(0, starter);
      } on PostgrestException catch (error) {
        // PGRST202: launch_admin_package.sql has not been run on this project yet.
        if (error.code != 'PGRST202') rethrow;
        debugPrint('Starter package skipped: ${error.message}');
      }
    }
    if (!rows.any((row) => row['id'] == HabitsPackTwo.id)) {
      try {
        if (await HabitsPackTwo.ensureCreated(client)) {
          final pack = await client
              .from('content_packages')
              .select()
              .eq('id', HabitsPackTwo.id)
              .single();
          rows.insert(0, pack);
        }
      } on PostgrestException catch (error) {
        // PGRST202: habits_pack_2.sql has not been run on this project yet.
        if (error.code != 'PGRST202') rethrow;
        debugPrint('Habits 6–20 package skipped: ${error.message}');
      }
    }
    final packages = List<Map<String, dynamic>>.from(rows);
    final starterIndex = packages.indexWhere(
      (row) => row['id'] == LaunchAdminPackage.id,
    );
    if (starterIndex > 0) packages.insert(0, packages.removeAt(starterIndex));
    final worldIds = <String>{};
    for (final package in packages) {
      final draft = package['draft_content'];
      if (draft is! Map || draft['worlds'] is! List) continue;
      for (final world in draft['worlds'] as List) {
        if (world is Map && world['id'] is String)
          worldIds.add(world['id'] as String);
      }
    }
    if (worldIds.isNotEmpty) {
      // One aggregate request for every card, rather than loading each habit.
      final counts = await client
          .from('worlds')
          .select('id,missions(count)')
          .inFilter('id', worldIds.toList());
      final byWorld = <String, int>{};
      for (final row in counts) {
        final missions = row['missions'] as List;
        byWorld[row['id'] as String] = missions.isEmpty
            ? 0
            : (missions.first['count'] as num).toInt();
      }
      for (final package in packages) {
        final draft = package['draft_content'];
        final worlds = draft is Map && draft['worlds'] is List
            ? draft['worlds'] as List
            : const [];
        package['_mission_count'] = worlds.fold<int>(
          0,
          (count, world) =>
              count + (world is Map ? byWorld[world['id']] ?? 0 : 0),
        );
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
        subtitle:
            'أنشئ بكجًا جديدًا لجمع العوالم والعادات قبل نشرها للمستخدمين',
        submitLabel: 'إنشاء البكج',
      ),
    );
    if (result == null || (result['title'] ?? '').trim().isEmpty || !mounted)
      return;
    try {
      final row = await sl<SupabaseClient>()
          .from('content_packages')
          .insert({
            'title': result['title']!.trim(),
            'description': (result['description'] ?? '').trim(),
            'created_by': sl<SupabaseClient>().auth.currentUser?.id,
            'draft_content': {'worlds': []},
          })
          .select('id')
          .single();
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
                'هل أنت متأكد من حذف البكج "$title"؟ سيتم حذف البكج نهائياً.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.secondary),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppColors.border_radius,
                    ),
                  ),
                ),
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: const Text(
                  'حذف البكج',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم حذف البكج بنجاح')));
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
    if (result == null || (result['title'] ?? '').trim().isEmpty || !mounted)
      return;
    try {
      await sl<SupabaseClient>()
          .from('content_packages')
          .update({
            'title': result['title']!.trim(),
            'description': (result['description'] ?? '').trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', package['id']);
      await _refresh();
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $error')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'إدارة البكجات',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        toolbarHeight: 72,
        titleSpacing: 16,
        actionsPadding: const EdgeInsetsDirectional.only(end: 12),
        centerTitle: false,
        actions: [
          IconButton.filledTonal(
            tooltip: 'شخصيتك',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimaryContainer,
            ),
            onPressed: () => context.push('/custom-character-creator'),
            icon: const Icon(Icons.face_retouching_natural_rounded, size: 22),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'تحديث البكجات',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'الإعدادات',
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
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.secondary,
            ),
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
        label: const Text(
          'بكج جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _packages,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ShimmerLoading(itemCount: 4);
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
              itemBuilder: (context, index) => PackageWalletCard(
                package: items[index],
                onTap: () => context
                    .push('/admin/packages/${items[index]['id']}')
                    .then((_) => _refresh()),
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
