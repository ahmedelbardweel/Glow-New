import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../content/domain/entities/world_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/bloc/content_event.dart';
import '../../../content/presentation/bloc/content_state.dart';

class AddWorldScreen extends StatefulWidget {
  final WorldEntity? worldToEdit;

  const AddWorldScreen({super.key, this.worldToEdit});

  @override
  State<AddWorldScreen> createState() => _AddWorldScreenState();
}

class _AddWorldScreenState extends State<AddWorldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late ContentBloc _contentBloc;
  
  final List<String> _defaultImages = [
    'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80', // غابات
    'https://images.unsplash.com/photo-1464802686167-b939a6910659?auto=format&fit=crop&w=800&q=80', // فضاء
    'https://images.unsplash.com/photo-1518837695005-2083093ee35b?auto=format&fit=crop&w=800&q=80', // محيط
    'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?auto=format&fit=crop&w=800&q=80', // صحراء
    'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=800&q=80', // خيال
    'https://images.unsplash.com/photo-1507608616759-54f48f0af0ee?auto=format&fit=crop&w=800&q=80', // مطر
  ];
  late String _selectedImage;

  @override
  void initState() {
    super.initState();
    _contentBloc = sl<ContentBloc>();
    if (widget.worldToEdit != null) {
      _titleController.text = widget.worldToEdit!.title;
      _descController.text = widget.worldToEdit!.description;
      _selectedImage = widget.worldToEdit!.imageUrl;
      if (!_defaultImages.contains(_selectedImage)) {
        _defaultImages.add(_selectedImage);
      }
    } else {
      _selectedImage = _defaultImages.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _contentBloc.close();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final world = WorldEntity(
        id: widget.worldToEdit?.id ?? '', // Keeps existing id if editing
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        imageUrl: _selectedImage,
      );
      if (widget.worldToEdit != null) {
        _contentBloc.add(ContentEvent.updateWorld(world));
      } else {
        _contentBloc.add(ContentEvent.addWorld(world));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _contentBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.worldToEdit != null ? 'تعديل عالم' : 'إضافة عالم جديد'),
        ),
        body: BlocConsumer<ContentBloc, ContentState>(
          listener: (context, state) {
            state.maybeWhen(
              worldAdded: (_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الإضافة بنجاح!')));
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
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'اسم العالم (مثال: الغابات)'),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'وصف العالم'),
                      maxLines: 3,
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'اختر صورة العالم:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _defaultImages.length,
                      itemBuilder: (context, index) {
                        final imageUrl = _defaultImages[index];
                        final isSelected = imageUrl == _selectedImage;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedImage = imageUrl),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppColors.border_radius),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: const Icon(Icons.broken_image, color: Colors.white54),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading ? const CircularProgressIndicator() : Text(widget.worldToEdit != null ? 'تحديث العالم' : 'حفظ العالم'),
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
