import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/admin_actions_bottom_sheet.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/offline_aware_image.dart';
import '../../../content/domain/entities/world_entity.dart';

class ContentPackageDetailScreen extends StatefulWidget {
  const ContentPackageDetailScreen({super.key, required this.packageId});
  final String packageId;

  @override
  State<ContentPackageDetailScreen> createState() => _ContentPackageDetailScreenState();
}

class _ContentPackageDetailScreenState extends State<ContentPackageDetailScreen> {
  late Future<Map<String, dynamic>> _package;
  bool _busy = false;
  SupabaseClient get _db => sl<SupabaseClient>();

  @override
  void initState() {
    super.initState();
    _package = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final row = await _db
        .from('content_packages')
        .select()
        .eq('id', widget.packageId)
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> _reload() async => setState(() => _package = _load());

  Map<String, dynamic> _draft(Map<String, dynamic> package) {
    final raw = package['draft_content'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    return {'worlds': <dynamic>[]};
  }

  List<WorldEntity> _extractWorlds(Map<String, dynamic> package) {
    final draft = _draft(package);
    final list = draft['worlds'];
    if (list is! List) return [];
    return list.map((item) {
      if (item is Map) {
        return WorldEntity(
          id: (item['id'] ?? '').toString(),
          title: (item['title'] ?? '').toString(),
          description: (item['description'] ?? '').toString(),
          imageUrl: (item['image_url'] ?? '').toString(),
        );
      }
      return const WorldEntity(id: '', title: '', description: '', imageUrl: '');
    }).where((w) => w.id.isNotEmpty || w.title.isNotEmpty).toList();
  }

  Future<void> _saveWorlds(Map<String, dynamic> package, List<WorldEntity> worlds) async {
    setState(() => _busy = true);
    try {
      final content = _draft(package);
      content['worlds'] = worlds.map((w) => {
        'id': w.id,
        'title': w.title,
        'description': w.description,
        'image_url': w.imageUrl,
      }).toList();

      await _db.from('content_packages').update({
        'draft_content': content,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.packageId);
      await _reload();
    } catch (e) {
      _showMessage('تعذر حفظ التغييرات: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addNewWorld(Map<String, dynamic> package) async {
    HapticFeedback.lightImpact();
    final result = await context.push('/admin/add-world');
    if (result == true && mounted) {
      try {
        // Fetch the newest created world from worlds table
        final rows = await _db
            .from('worlds')
            .select()
            .order('created_at', ascending: false)
            .limit(1);
        if (rows.isNotEmpty) {
          final row = rows.first;
          final newWorld = WorldEntity(
            id: row['id'] as String,
            title: row['title'] as String? ?? '',
            description: row['description'] as String? ?? '',
            imageUrl: row['image_url'] as String? ?? '',
          );
          final worlds = _extractWorlds(package);
          if (!worlds.any((w) => w.id == newWorld.id)) {
            worlds.add(newWorld);
            await _saveWorlds(package, worlds);
            _showMessage('تمت إضافة العالم للبكج بنجاح');
          }
        }
      } catch (e) {
        _showMessage('تم حفظ العالم في النظام. يمكنك إضافته للبكج الآن.');
      }
    }
  }

  Future<void> _chooseExistingWorld(Map<String, dynamic> package) async {
    HapticFeedback.lightImpact();
    // Fetch all existing worlds from database
    List<Map<String, dynamic>> allWorlds = [];
    try {
      final rows = await _db.from('worlds').select().order('created_at', ascending: false);
      allWorlds = List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      _showMessage('تعذر جلب العوالم: $e');
      return;
    }

    if (!mounted) return;
    final currentWorlds = _extractWorlds(package);
    final available = allWorlds.where((w) {
      final id = (w['id'] ?? '').toString();
      return !currentWorlds.any((cw) => cw.id == id);
    }).toList();

    if (available.isEmpty) {
      _showMessage('جميع العوالم المتاحة مضافة بالفعل في هذا البكج.');
      return;
    }

    final selected = await showAppSheet<Map<String, dynamic>>(
      context: context,
      heightFactor: 0.65,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختيار عالم للبكج',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'اختر عالماً من العوالم السابقة لإضافته إلى هذا البكج',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: available.length,
                  itemBuilder: (ctx, i) {
                    final w = available[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: (w['image_url'] != null && (w['image_url'] as String).isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppColors.border_radius),
                                child: OfflineAwareImage(
                                  imageUrl: w['image_url'] as String,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                                ),
                                child: const Icon(Icons.public, color: AppColors.secondary),
                              ),
                        title: Text(
                          w['title'] ?? 'عالم',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          w['description'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () => Navigator.of(sheetContext).pop(w),
                          child: const Text('إضافة'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      final newWorld = WorldEntity(
        id: selected['id'].toString(),
        title: selected['title']?.toString() ?? '',
        description: selected['description']?.toString() ?? '',
        imageUrl: selected['image_url']?.toString() ?? '',
      );
      final worlds = _extractWorlds(package);
      worlds.add(newWorld);
      await _saveWorlds(package, worlds);
      _showMessage('تمت إضافة العالم "${newWorld.title}" للبكج بنجاح');
    }
  }

  Future<void> _openAddWorldOptions(Map<String, dynamic> package) async {
    HapticFeedback.lightImpact();
    await showAppSheet<void>(
      context: context,
      heightFactor: 0.36,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'إضافة عالم للبكج',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.border_radius),
                  ),
                ),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _addNewWorld(package);
                },
                icon: const Icon(Icons.add),
                label: const Text('إنشاء عالم جديد', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.border_radius),
                  ),
                ),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _chooseExistingWorld(package);
                },
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('اختيار من العوالم السابقة', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeWorldFromPackage(Map<String, dynamic> package, WorldEntity world) async {
    HapticFeedback.lightImpact();
    final confirm = await showAppSheet<bool>(
      context: context,
      heightFactor: 0.36,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'إزالة العالم من البكج',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'هل أنت متأكد من إزالة عالم "${world.title}" من هذا البكج؟ (لن يتم حذف العالم من النظام).',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
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
                child: const Text('إزالة من البكج', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true || !mounted) return;
    final worlds = _extractWorlds(package);
    worlds.removeWhere((w) => w.id == world.id);
    await _saveWorlds(package, worlds);
    _showMessage('تمت إزالة العالم من البكج');
  }

  Future<void> _publish(Map<String, dynamic> package) async {
    HapticFeedback.lightImpact();
    final worlds = _extractWorlds(package);
    if (worlds.isEmpty) {
      _showMessage('أضف عالماً واحداً على الأقل إلى البكج قبل النشر.');
      return;
    }
    final confirm = await showAppSheet<bool>(
      context: context,
      heightFactor: 0.36,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'نشر البكج للمستخدمين',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'سيصبح هذا البكج بجميع عوالمه وعاداته متاحاً للمستخدمين على الفور.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87),
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
                onPressed: () => Navigator.of(sheetContext).pop(true),
                child: const Text('نشر البكج الآن', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _db.rpc('publish_content_package', params: {'package_id': widget.packageId});
      await _reload();
      _showMessage('تم نشر البكج بنجاح');
    } catch (e) {
      _showMessage('تعذر النشر: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _package,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('تفاصيل البكج')),
            body: Center(
              child: Text(
                'تعذر تحميل البكج: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        final package = snapshot.data!;
        final worlds = _extractWorlds(package);
        final published = package['status'] == 'published';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text('${package['title'] ?? 'عوالم البكج'}'),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: FilledButton.tonal(
                  onPressed: _busy ? null : () => _publish(package),
                  style: FilledButton.styleFrom(
                    backgroundColor: published ? AppColors.tertiaryContainer : AppColors.primaryContainer,
                    foregroundColor: published ? AppColors.onTertiaryContainer : AppColors.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.border_radius),
                    ),
                  ),
                  child: Text(
                    published ? 'منشور (تحديث)' : 'نشر البكج',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'تحديث',
                icon: const Icon(Icons.refresh),
                onPressed: _reload,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppColors.border_radius),
            ),
            onPressed: () => _openAddWorldOptions(package),
            child: const Icon(Icons.add),
          ),
          body: worlds.isEmpty
              ? _buildEmptyState(package)
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: worlds.length,
                    itemBuilder: (context, index) {
                      final world = worlds[index];
                      return _buildWorldCard(package, world);
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(Map<String, dynamic> package) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppColors.border_radius),
              ),
              child: const Icon(
                Icons.public,
                size: 40,
                color: AppColors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد عوالم في هذا البكج حتى الآن',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'أضف عوالم إلى هذا البكج لتبدأ بربط المهام والعادات به.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openAddWorldOptions(package),
              icon: const Icon(Icons.add),
              label: const Text('أضف عالمك الأول'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Exact replica of the beautiful World Card from Image 1 / AdminDashboardScreen
  Widget _buildWorldCard(Map<String, dynamic> package, WorldEntity world) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.border_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Image
          if (world.imageUrl.isNotEmpty)
            OfflineAwareImage(
              imageUrl: world.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: Container(
                height: 180,
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.broken_image, size: 64, color: Colors.white54),
              ),
            )
          else
            Container(
              height: 180,
              width: double.infinity,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.public, size: 64, color: Colors.white54),
            ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        world.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        world.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppColors.border_radius),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.explore, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'عالم استكشافي',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppColors.border_radius),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'مغامرة ممتعة',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ripple Effect -> Opens WorldMissionsScreen (Image 2)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/admin/world-missions', extra: world);
                },
              ),
            ),
          ),
          // Three dots for actions
          Positioned(
            top: 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                showAdminActionsBottomSheet(
                  context: context,
                  onEdit: () {
                    context.push('/admin/add-world', extra: world);
                  },
                  onDelete: () => _removeWorldFromPackage(package, world),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
