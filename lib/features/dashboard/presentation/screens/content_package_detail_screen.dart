import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';

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

  Future<Map<String, dynamic>> _load() async => Map<String, dynamic>.from(
        await _db.from('content_packages').select().eq('id', widget.packageId).single(),
      );

  Future<void> _reload() async => setState(() => _package = _load());

  Future<void> _save(Map<String, dynamic> package, Map<String, dynamic> content) async {
    setState(() => _busy = true);
    try {
      await _db.from('content_packages').update({
        'title': package['title'],
        'description': package['description'],
        'draft_content': content,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', widget.packageId);
      await _reload();
    } catch (error) {
      _message('تعذر حفظ المسودة: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editPackage(Map<String, dynamic> package) async {
    final title = TextEditingController(text: '${package['title'] ?? ''}');
    final description = TextEditingController(text: '${package['description'] ?? ''}');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات البكج'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'اسم البكج')),
          const SizedBox(height: 10),
          TextField(controller: description, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'الوصف')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حفظ'))],
      ),
    );
    if (accepted != true || !mounted) return;
    package['title'] = title.text.trim();
    package['description'] = description.text.trim();
    await _save(package, _draft(package));
  }

  Future<void> _addWorld(Map<String, dynamic> package) async {
    final title = TextEditingController();
    final description = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عالم للمسودة'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'اسم العالم')),
          const SizedBox(height: 10),
          TextField(controller: description, decoration: const InputDecoration(labelText: 'وصف العالم')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إضافة'))],
      ),
    );
    if (accepted != true || title.text.trim().isEmpty || !mounted) return;
    final content = _draft(package);
    final worlds = List<Map<String, dynamic>>.from(content['worlds'] as List? ?? const []);
    worlds.add({'id': 'draft_${DateTime.now().microsecondsSinceEpoch}', 'title': title.text.trim(), 'description': description.text.trim(), 'image_url': '', 'habits': <Map<String, dynamic>>[]});
    content['worlds'] = worlds;
    await _save(package, content);
  }

  Future<void> _addHabit(Map<String, dynamic> package, Map<String, dynamic> world) async {
    final title = TextEditingController();
    final badge = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة عادة'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'اسم العادة')),
          const SizedBox(height: 10),
          TextField(controller: badge, decoration: const InputDecoration(labelText: 'اسم الوسام')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إضافة'))],
      ),
    );
    if (accepted != true || title.text.trim().isEmpty || !mounted) return;
    final content = _draft(package);
    final worlds = List<Map<String, dynamic>>.from(content['worlds'] as List? ?? const []);
    final target = worlds.firstWhere((item) => item['id'] == world['id']);
    final habits = List<Map<String, dynamic>>.from(target['habits'] as List? ?? const []);
    habits.add({'id': 'draft_${DateTime.now().microsecondsSinceEpoch}', 'title': title.text.trim(), 'badge_name': badge.text.trim(), 'stories': <Map<String, dynamic>>[], 'questions': <Map<String, dynamic>>[]});
    target['habits'] = habits;
    content['worlds'] = worlds;
    await _save(package, content);
  }

  Future<void> _publish(Map<String, dynamic> package) async {
    final content = _draft(package);
    final worlds = content['worlds'] as List? ?? const [];
    if (worlds.isEmpty || worlds.every((w) => w is Map && (w['habits'] as List? ?? const []).isEmpty)) {
      _message('أضف عالمًا وعادة واحدة على الأقل قبل النشر.');
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نشر البكج؟'),
        content: const Text('سيصبح الإصدار الحالي متاحًا للمستخدمين. يمكنك تعديل المسودة لاحقًا ونشر إصدار جديد.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ليس الآن')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('نشر'))],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _db.rpc('publish_content_package', params: {'package_id': widget.packageId});
      await _reload();
      _message('تم نشر إصدار البكج.');
    } catch (error) {
      _message('تعذر النشر: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, dynamic> _draft(Map<String, dynamic> package) {
    final raw = package['draft_content'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return {'worlds': <dynamic>[]};
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('محتوى البكج'), actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh_rounded), tooltip: 'تحديث'),
        ]),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _package,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError) return Center(child: Text('تعذر تحميل المسودة: ${snapshot.error}'));
            final package = snapshot.data!;
            final worlds = List<Map<String, dynamic>>.from(_draft(package)['worlds'] as List? ?? const []);
            return Stack(children: [
              ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 120), children: [
                _header(package, worlds.length),
                const SizedBox(height: 22),
                for (final world in worlds) _worldCard(package, world),
                OutlinedButton.icon(onPressed: () => _addWorld(package), icon: const Icon(Icons.add_rounded), label: const Text('إضافة عالم')),
              ]),
              Positioned(left: 16, right: 16, bottom: 16, child: SafeArea(child: FilledButton.icon(
                onPressed: _busy ? null : () => _publish(package),
                icon: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.publish_rounded),
                label: Text(_busy ? 'جارٍ الحفظ…' : 'نشر البكج'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
              ))),
            ]);
          },
        ),
      );

  Widget _header(Map<String, dynamic> package, int worldCount) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primaryContainer, Color(0xFFFFF4CC)]), borderRadius: BorderRadius.circular(24)),
        child: Row(children: [
          const Icon(Icons.wallet_rounded, size: 40, color: AppColors.onPrimaryContainer),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${package['title']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('${package['description'] ?? ''}'),
            const SizedBox(height: 6),
            Text('$worldCount عوالم  ·  الإصدار ${package['version'] ?? 0}  ·  ${package['status'] == 'published' ? 'منشور' : 'مسودة'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ])),
          IconButton(onPressed: () => _editPackage(package), icon: const Icon(Icons.edit_outlined)),
        ]),
      );

  Widget _worldCard(Map<String, dynamic> package, Map<String, dynamic> world) {
    final habits = List<Map<String, dynamic>>.from(world['habits'] as List? ?? const []);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ExpansionTile(
        leading: CircleAvatar(backgroundColor: AppColors.secondaryContainer, child: const Icon(Icons.public_rounded, color: AppColors.secondary)),
        title: Text('${world['title'] ?? 'عالم جديد'}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${world['description'] ?? ''}  ·  ${habits.length} عادات'),
        children: [
          for (var i = 0; i < habits.length; i++) ListTile(
            leading: Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: [AppColors.primaryContainer, AppColors.secondaryContainer, const Color(0xFFE2F4E8)][i % 3], borderRadius: BorderRadius.circular(11)), child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
            title: Text('${habits[i]['title'] ?? 'عادة'}'),
            subtitle: Text('${(habits[i]['stories'] as List? ?? const []).length} قصص · ${(habits[i]['questions'] as List? ?? const []).length} أسئلة'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => _message('إدارة القصص والأسئلة ستُربط في الخطوة التالية داخل هذا البكج.'),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _addHabit(package, world), icon: const Icon(Icons.add), label: const Text('إضافة عادة')))),
        ],
      ),
    );
  }
}
