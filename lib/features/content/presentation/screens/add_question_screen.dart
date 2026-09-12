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
  final QuestionEntity? questionToEdit;

  const AddQuestionScreen({super.key, required this.mission, this.questionToEdit});

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
    if (widget.questionToEdit != null) {
      _questionController.text = widget.questionToEdit!.questionText;
      _correctOptionIndex = widget.questionToEdit!.correctAnswerIndex;
      for (int i = 0; i < widget.questionToEdit!.options.length && i < 4; i++) {
        _optionsControllers[i].text = widget.questionToEdit!.options[i];
      }
    }
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
        id: widget.questionToEdit?.id ?? '', // Supabase gen_random_uuid will handle this if empty
        missionId: widget.mission.id,
        questionText: _questionController.text.trim(),
        options: options,
        correctAnswerIndex: _correctOptionIndex,
      );
      
      if (widget.questionToEdit != null) {
        _contentBloc.add(ContentEvent.updateQuestion(question));
      } else {
        _contentBloc.add(ContentEvent.addQuestion(question));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _contentBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.questionToEdit != null ? 'تعديل السؤال' : 'إضافة سؤال جديد'),
        ),
        body: BlocConsumer<ContentBloc, ContentState>(
          listener: (context, state) {
            state.maybeWhen(
              questionAdded: (_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة السؤال بنجاح!')));
                context.pop(true);
              },
              questionsLoaded: (_) {
                if (widget.questionToEdit != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث السؤال بنجاح!')));
                  context.pop(true);
                }
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
                        child: isLoading ? const CircularProgressIndicator() : Text(widget.questionToEdit != null ? 'تحديث السؤال' : 'حفظ السؤال'),
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
