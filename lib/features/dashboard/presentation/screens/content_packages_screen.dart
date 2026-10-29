import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';

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

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await sl<SupabaseClient>()
        .from('content_packages')
        .select('id,title,description,cover_url,status,version,draft_content,updated_at')
        .order('updated_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _refresh() async => setState(() => _packages = _load());

  Future<void> _createPackage() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بكج جديد'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'اسم البكج')),
          const SizedBox(height: 12),
          TextField(controller: description, decoration: const InputDecoration(labelText: 'وصف مختصر')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إنشاء مسودة')),
        ],
      ),
    );
    if (ok != true || title.text.trim().isEmpty || !mounted) return;
    try {
      final row = await sl<SupabaseClient>().from('content_packages').insert({
        'title': title.text.trim(),
        'description': description.text.trim(),
        'created_by': sl<SupabaseClient>().auth.currentUser?.id,
        'draft_content': {'worlds': []},
      }).select('id').single();
      await _refresh();
      if (mounted) context.push('/admin/packages/${row['id']}');
    } catch (error) {
      _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تنفيذ العملية: $error')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('بكجات المحتوى'), actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createPackage,
          icon: const Icon(Icons.add_rounded),
          label: const Text('بكج جديد'),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _packages,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('تعذر تحميل البكجات. تأكد من تطبيق مخطط Supabase وتسجيل الدخول كأدمن.\n\n${snapshot.error}', textAlign: TextAlign.center),
              ));
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) return _emptyState();
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                itemCount: items.length,
                itemBuilder: (context, index) => _PackageWalletCard(
                  package: items[index],
                  onTap: () => context.push('/admin/packages/${items[index]['id']}').then((_) => _refresh()),
                ),
              ),
            );
          },
        ),
      );

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 92, height: 92,
          decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(28)),
          child: const Icon(Icons.wallet_rounded, size: 44, color: AppColors.onPrimaryContainer),
        ),
        const SizedBox(height: 20),
        const Text('محفظة العوالم تبدأ من هنا', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('أنشئ بكجًا واجمع فيه العوالم والعادات قبل نشرها.', textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton.icon(onPressed: _createPackage, icon: const Icon(Icons.add), label: const Text('إنشاء أول بكج')),
      ]));
}

class _PackageWalletCard extends StatelessWidget {
  const _PackageWalletCard({required this.package, required this.onTap});
  final Map<String, dynamic> package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final draft = package['draft_content'];
    final worlds = draft is Map && draft['worlds'] is List ? draft['worlds'] as List : const [];
    final missionCount = worlds.fold<int>(0, (sum, world) {
      if (world is! Map || world['habits'] is! List) return sum;
      return sum + (world['habits'] as List).length;
    });
    final published = package['status'] == 'published';
    final colors = [AppColors.primaryContainer, AppColors.secondaryContainer, const Color(0xFFE2F4E8)];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 210,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.35)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 18, offset: const Offset(0, 8))],
            ),
            child: Stack(children: [
              Positioned.fill(child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 54),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.wallet_rounded, color: AppColors.secondary.withOpacity(.8)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${package['title'] ?? 'بكج بدون اسم'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
                    _StatusPill(published: published),
                  ]),
                  const SizedBox(height: 9),
                  Text('${package['description'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
                  const Spacer(),
                  Row(children: [
                    _Count(icon: Icons.public_rounded, value: '${worlds.length}', label: 'عوالم'),
                    const SizedBox(width: 14),
                    _Count(icon: Icons.auto_awesome_rounded, value: '$missionCount', label: 'عادات'),
                    const Spacer(),
                    Text('الإصدار ${package['version'] ?? 0}', style: Theme.of(context).textTheme.labelSmall),
                  ]),
                ]),
              )),
              Positioned(left: 0, right: 0, bottom: 0, height: 60, child: Stack(
                children: [
                  for (var i = worlds.length - 1; i >= 0 && i < 3; i--)
                    Positioned(
                      left: 15.0 + i * 9,
                      right: 15.0 + i * 9,
                      bottom: 0,
                      height: 38.0 + (2 - i) * 7,
                      child: Container(
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        decoration: BoxDecoration(color: colors[i], borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), border: Border.all(color: Colors.white, width: 2)),
                        child: Text(worlds[i] is Map ? '${worlds[i]['title'] ?? 'عالم جديد'}' : 'عالم جديد', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  Positioned(left: 0, right: 0, bottom: 0, height: 12, child: Container(decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))))),
                ],
              )),
            ]),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: published ? AppColors.tertiary.withOpacity(.12) : AppColors.primary.withOpacity(.16), borderRadius: BorderRadius.circular(30)),
        child: Text(published ? 'منشور' : 'مسودة', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: published ? AppColors.tertiary : AppColors.onPrimaryContainer)),
      );
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 16, color: AppColors.secondary), const SizedBox(width: 4), Text('$value $label', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]);
}
