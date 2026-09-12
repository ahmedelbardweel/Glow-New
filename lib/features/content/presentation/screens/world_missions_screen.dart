import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../content/domain/entities/world_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/bloc/content_event.dart';
import '../../../content/presentation/bloc/content_state.dart';
import '../../../../core/utils/admin_actions_bottom_sheet.dart';

class WorldMissionsScreen extends StatefulWidget {
  final WorldEntity world;

  const WorldMissionsScreen({super.key, required this.world});

  @override
  State<WorldMissionsScreen> createState() => _WorldMissionsScreenState();
}

class _WorldMissionsScreenState extends State<WorldMissionsScreen> {
  late ContentBloc _contentBloc;

  @override
  void initState() {
    super.initState();
    _contentBloc = sl<ContentBloc>();
    _contentBloc.add(ContentEvent.getMissions(widget.world.id));
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
          title: Text('مهام: ${widget.world.title}'),
          centerTitle: true,
        ),
        body: BlocBuilder<ContentBloc, ContentState>(
          builder: (context, state) {
            return state.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (msg) => Center(child: Text('خطأ: $msg', style: const TextStyle(color: Colors.red))),
              missionsLoaded: (missions) {
                if (missions.isEmpty) {
                  return const Center(child: Text('لا توجد مهام في هذا العالم حتى الآن.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: missions.length,
                  itemBuilder: (context, index) {
                    final mission = missions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(mission.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الوسم: ${mission.badgeName} | النجوم: ${mission.starsReward}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            showAdminActionsBottomSheet(
                              context: context,
                              onEdit: () async {
                                final result = await context.push('/admin/add-mission', extra: {'world': widget.world, 'missionToEdit': mission});
                                if (result == true) {
                                  _contentBloc.add(ContentEvent.getMissions(widget.world.id));
                                }
                              },
                              onDelete: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('تأكيد الحذف'),
                                    content: const Text('هل أنت متأكد من حذف هذه المهمة؟'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _contentBloc.add(ContentEvent.deleteMission(mission.id));
                                        },
                                        child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/admin/mission-stories', extra: mission);
                        },
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
            final result = await context.push('/admin/add-mission', extra: widget.world);
            if (result == true) {
              _contentBloc.add(ContentEvent.getMissions(widget.world.id));
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
