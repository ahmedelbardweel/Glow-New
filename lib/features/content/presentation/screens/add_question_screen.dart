import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../content/domain/entities/mission_entity.dart';
import '../../../content/domain/entities/question_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/bloc/content_event.dart';
import '../../../content/presentation/bloc/content_state.dart';

class AddQuestionScreen extends StatefulWidget {
  final MissionEntity mission;

  const AddQuestionScreen({super.key, required this.mission});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionsControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctOptionIndex = 0;

  late ContentBloc _contentBloc;

  @override
  void initState() {
    super.initState();
    _contentBloc = sl<ContentBloc>();
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionsControllers) {
      controller.dispose();
    }
    _contentBloc.close();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final options = _optionsControllers.map((c) => c.text.trim()).toList();
      
      final question = QuestionEntity(
        id: '', // Supabase gen_random_uuid will handle this
        missionId: widget.mission.id,
        questionText: _questionController.text.trim(),
        options: options,
        correctAnswerIndex: _correctOptionIndex,
      );
      
      _contentBloc.add(ContentEvent.addQuestion(question));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _contentBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة سؤال جديد'),
        ),
        body: BlocConsumer<ContentBloc, ContentState>(
          listener: (context, state) {
            state.maybeWhen(
              questionAdded: (_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة السؤال بنجاح!')));
                context.pop(true);
              },
              error: (msg) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $msg')));
              },
              orElse: () {},
            );
          },
          builder: (context, state) {
            final isLoading = state.maybeWhen(loading: () => true, orElse: () => false);

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _questionController,
                      decoration: const InputDecoration(labelText: 'نص السؤال'),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'الخيارات (اختر الإجابة الصحيحة)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: _correctOptionIndex,
                              onChanged: (val) {
                                setState(() {
                                  _correctOptionIndex = val!;
                                });
                              },
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _optionsControllers[index],
                                decoration: InputDecoration(labelText: 'الخيار ${index + 1}'),
                                validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading ? const CircularProgressIndicator() : const Text('حفظ السؤال'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
