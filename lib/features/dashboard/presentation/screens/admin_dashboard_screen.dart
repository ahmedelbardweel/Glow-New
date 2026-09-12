import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../content/data/services/database_seeder.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/bloc/content_event.dart';
import '../../../content/presentation/bloc/content_state.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late ContentBloc _contentBloc;
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _contentBloc = sl<ContentBloc>();
    _contentBloc.add(const ContentEvent.getWorlds());
  }

  Future<void> _handleSeedDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعبئة المحتوى في Supabase'),
        content: const Text(
          'سيتم ملء قاعدة البيانات بعوالم خيالية، مهام، قصص تفاعلية كاملة مع شخصيات 3D وأسئلة تحديات.\n\nهل ترغب في المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ابدأ التعبئة'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isSeeding = true);
      try {
        final seeder = DatabaseSeeder(sl());
        await seeder.seedDatabase();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تمت تعبئة البيانات في Supabase بنجاح! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          _contentBloc.add(const ContentEvent.getWorlds());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ أثناء التعبئة: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSeeding = false);
      }
    }
  }

  @override
  void dispose() {
    _contentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _contentBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة العوالم (Worlds)'),
          centerTitle: true,
          actions: [
            if (_isSeeding)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.auto_fix_high_rounded),
                tooltip: 'تعبئة بيانات احترافية (Seeder)',
                onPressed: _handleSeedDatabase,
              ),
          ],
        ),
        body: BlocBuilder<ContentBloc, ContentState>(
          builder: (context, state) {
            return state.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (msg) => Center(child: Text('خطأ: $msg', style: const TextStyle(color: Colors.red))),
              worldsLoaded: (worlds) {
                if (worlds.isEmpty) {
                  return const Center(child: Text('لا توجد عوالم مضافة حتى الآن. أضف عالمك الأول!'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: worlds.length,
                  itemBuilder: (context, index) {
                    final world = worlds[index];
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
                            Image.network(
                              world.imageUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
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
                                                Text('عالم استكشافي', style: TextStyle(color: Colors.white, fontSize: 10)),
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
                                                Text('مغامرة ممتعة', style: TextStyle(color: Colors.white, fontSize: 10)),
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
                          // Ripple Effect
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
                        ],
                      ),
                    );
                  },
                );
              },
              orElse: () => const SizedBox(),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            HapticFeedback.lightImpact();
            final result = await context.push('/admin/add-world');
            if (result == true) {
              _contentBloc.add(const ContentEvent.getWorlds());
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
