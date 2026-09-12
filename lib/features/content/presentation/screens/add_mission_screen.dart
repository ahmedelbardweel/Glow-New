import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../content/domain/entities/world_entity.dart';
import '../../../content/domain/entities/mission_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/bloc/content_event.dart';
import '../../../content/presentation/bloc/content_state.dart';

class AddMissionScreen extends StatefulWidget {
  final WorldEntity world;
  final MissionEntity? missionToEdit;

  const AddMissionScreen({super.key, required this.world, this.missionToEdit});

  @override
  State<AddMissionScreen> createState() => _AddMissionScreenState();
}

class _AddMissionScreenState extends State<AddMissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _badgeController = TextEditingController();
  final _starsController = TextEditingController();
  late ContentBloc _contentBloc;

  @override
  void initState() {
    super.initState();
    _contentBloc = sl<ContentBloc>();
    if (widget.missionToEdit != null) {
      _titleController.text = widget.missionToEdit!.title;
      _badgeController.text = widget.missionToEdit!.badgeName;
      _starsController.text = widget.missionToEdit!.starsReward.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _badgeController.dispose();
    _starsController.dispose();
    _contentBloc.close();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final mission = MissionEntity(
        id: widget.missionToEdit?.id ?? '', // Supabase gen_random_uuid will handle this
        worldId: widget.world.id,
        title: _titleController.text.trim(),
        badgeName: _badgeController.text.trim(),
        starsReward: int.tryParse(_starsController.text.trim()) ?? 0,
        orderIndex: widget.missionToEdit?.orderIndex ?? 0,
      );
      if (widget.missionToEdit != null) {
        _contentBloc.add(ContentEvent.updateMission(mission));
      } else {
        _contentBloc.add(ContentEvent.addMission(mission));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _contentBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.missionToEdit != null ? 'تعديل المهمة' : 'إضافة مهمة لـ: ${widget.world.title}'),
        ),
        body: BlocConsumer<ContentBloc, ContentState>(
          listener: (context, state) {
            state.maybeWhen(
              missionAdded: (_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة المهمة بنجاح!')));
                context.pop(true);
              },
              missionsLoaded: (_) {
                if (widget.missionToEdit != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث المهمة بنجاح!')));
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
              padding: const EdgeInsets.all(10.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'اسم المهمة (مثال: المهمة الأولى)'),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _badgeController,
                      decoration: const InputDecoration(labelText: 'اسم الوسم (مثال: وسام الثقة)'),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _starsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'عدد النجوم (مثال: 50)'),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading ? const CircularProgressIndicator() : Text(widget.missionToEdit != null ? 'تحديث المهمة' : 'حفظ المهمة'),
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
