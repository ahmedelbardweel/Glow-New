import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../content/domain/entities/mission_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/bloc/content_event.dart';
import '../../../content/presentation/bloc/content_state.dart';
import '../../../../core/utils/admin_actions_bottom_sheet.dart';

class MissionStoriesScreen extends StatefulWidget {
  final MissionEntity mission;

  const MissionStoriesScreen({super.key, required this.mission});

  @override
  State<MissionStoriesScreen> createState() => _MissionStoriesScreenState();
}

class _MissionStoriesScreenState extends State<MissionStoriesScreen> {
  late ContentBloc _contentBloc;

  @override
  void initState() {
    super.initState();
    _contentBloc = sl<ContentBloc>();
    _contentBloc.add(ContentEvent.getStories(widget.mission.id));
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
          title: Text('قصص المهمة: ${widget.mission.title}'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.quiz),
              tooltip: 'الأسئلة والاختبارات',
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/admin/mission-questions', extra: widget.mission);
              },
            ),
          ],
        ),
        body: BlocBuilder<ContentBloc, ContentState>(
          builder: (context, state) {
            return state.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (msg) => Center(child: Text('خطأ: $msg', style: const TextStyle(color: Colors.red))),
              storiesLoaded: (stories) {
                if (stories.isEmpty) {
                  return const Center(child: Text('لا توجد قصص مضافة في هذه المهمة حتى الآن.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('الشخصية الراوية: ${story.characterName}', maxLines: 1),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            showAdminActionsBottomSheet(
                              context: context,
                              onEdit: () async {
                                final result = await context.push('/admin/add-story', extra: {'mission': widget.mission, 'storyToEdit': story});
                                if (result == true) {
                                  _contentBloc.add(ContentEvent.getStories(widget.mission.id));
                                }
                              },
                              onDelete: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('تأكيد الحذف'),
                                    content: const Text('هل أنت متأكد من حذف هذه القصة؟'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _contentBloc.add(ContentEvent.deleteStory(story.id));
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
                          context.push('/admin/story-preview', extra: story);
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
            final result = await context.push('/admin/add-story', extra: widget.mission);
            if (result == true) {
              _contentBloc.add(ContentEvent.getStories(widget.mission.id));
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
