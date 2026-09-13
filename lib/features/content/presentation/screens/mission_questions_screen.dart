import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../content/domain/entities/mission_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/bloc/content_event.dart';
import '../../../content/presentation/bloc/content_state.dart';
import '../../../../core/utils/admin_actions_bottom_sheet.dart';
import '../../../../core/widgets/shimmer_loading.dart';

class MissionQuestionsScreen extends StatefulWidget {
  final MissionEntity mission;

  const MissionQuestionsScreen({super.key, required this.mission});

  @override
  State<MissionQuestionsScreen> createState() => _MissionQuestionsScreenState();
}

class _MissionQuestionsScreenState extends State<MissionQuestionsScreen> {
  late ContentBloc _contentBloc;

  @override
  void initState() {
    super.initState();
    _contentBloc = sl<ContentBloc>();
    _contentBloc.add(ContentEvent.getQuestions(widget.mission.id));
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
          title: Text('أسئلة المهمة: ${widget.mission.title}'),
          centerTitle: true,
        ),
        body: BlocBuilder<ContentBloc, ContentState>(
          builder: (context, state) {
            return state.maybeWhen(
              loading: () => const ShimmerLoading(),
              error: (msg) => Center(child: Text('خطأ: $msg', style: const TextStyle(color: Colors.red))),
              questionsLoaded: (questions) {
                if (questions.isEmpty) {
                  return const Center(child: Text('لا توجد أسئلة مضافة في هذه المهمة حتى الآن.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final question = questions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${index + 1}. ${question.questionText}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.more_vert),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    showAdminActionsBottomSheet(
                                      context: context,
                                      onEdit: () async {
                                        final result = await context.push('/admin/add-question', extra: {'mission': widget.mission, 'questionToEdit': question});
                                        if (result == true) {
                                          _contentBloc.add(ContentEvent.getQuestions(widget.mission.id));
                                        }
                                      },
                                      onDelete: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('تأكيد الحذف'),
                                            content: const Text('هل أنت متأكد من حذف هذا السؤال؟'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _contentBloc.add(ContentEvent.deleteQuestion(question.id));
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
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(question.options.length, (optIndex) {
                              final isCorrect = optIndex == question.correctAnswerIndex;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCorrect ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                                  border: isCorrect ? Border.all(color: Colors.green) : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrect ? Icons.check_circle : Icons.circle_outlined,
                                      color: isCorrect ? Colors.green : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(question.options[optIndex])),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
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
            final result = await context.push('/admin/add-question', extra: widget.mission);
            if (result == true) {
              _contentBloc.add(ContentEvent.getQuestions(widget.mission.id));
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
