import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../content/domain/entities/mission_entity.dart';
import '../../../content/domain/entities/story_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/bloc/content_event.dart';
import '../../../content/presentation/bloc/content_state.dart';
import '../../../../core/utils/character_helper.dart';

class AddStoryScreen extends StatefulWidget {
  final MissionEntity mission;
  final StoryEntity? storyToEdit;

  const AddStoryScreen({super.key, required this.mission, this.storyToEdit});

  @override
  State<AddStoryScreen> createState() => _AddStoryScreenState();
}

class _AddStoryScreenState extends State<AddStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String _selectedCharacter = 'fort_frontal.glb';
  final List<String> _avatars = CharacterHelper.characters.keys.toList();

  File? _characterFile;
  File? _audioFile;
  late ContentBloc _contentBloc;

  @override
  void initState() {
    super.initState();
    _contentBloc = sl<ContentBloc>();
    if (widget.storyToEdit != null) {
      _titleController.text = widget.storyToEdit!.title;
      _contentController.text = widget.storyToEdit!.content;
      final character = widget.storyToEdit!.characterName;
      if (_avatars.any((a) => character.toLowerCase().contains(a))) {
        _selectedCharacter = character;
      } else {
        _selectedCharacter = ''; // It's a custom uploaded character
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentBloc.close();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppColors.border_radius),
              ),
            ),
            Text(
              'اختر ملف صوتي',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر ملفاً صوتياً من هاتفك لإرفاقه بالقصة',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Pick file option
            InkWell(
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final result = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
                  );
                  if (result != null && result.isNotEmpty) {
                    final pickedPath = result.first.path;
                    if (pickedPath != null) {
                      setState(() {
                        _audioFile = File(pickedPath);
                      });
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ: $e')),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(AppColors.border_radius),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppColors.border_radius),
                      ),
                      child: const Icon(Icons.folder_open, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اختر من الملفات',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'MP3, WAV, M4A, AAC',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
            if (_audioFile != null) ...[
              const SizedBox(height: 12),
              // Remove file option
              InkWell(
                onTap: () {
                  setState(() => _audioFile = null);
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(AppColors.border_radius),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(AppColors.border_radius),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(AppColors.border_radius),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'إزالة الملف الصوتي',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCharacter() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['glb', 'gltf'],
      );
      if (result != null && result.isNotEmpty) {
        final pickedPath = result.first.path;
        if (pickedPath != null) {
          setState(() {
            _characterFile = File(pickedPath);
            _selectedCharacter = ''; // Clear selection since custom is picked
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء رفع الشخصية: $e')),
        );
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final story = StoryEntity(
        id: widget.storyToEdit?.id ?? '', // Supabase gen_random_uuid will handle this if empty
        missionId: widget.mission.id,
        title: _titleController.text.trim(),
        characterName: _characterFile != null ? _characterFile!.path.split('/').last : 
                       (_selectedCharacter.isEmpty ? (widget.storyToEdit?.characterName ?? '') : _selectedCharacter),
        content: _contentController.text.trim(),
        imageUrl: widget.storyToEdit?.imageUrl ?? '',
        audioUrl: widget.storyToEdit?.audioUrl,
        orderIndex: widget.storyToEdit?.orderIndex ?? 0,
      );
      if (widget.storyToEdit != null) {
        _contentBloc.add(ContentEvent.updateStory(story, audioFile: _audioFile, characterFile: _characterFile));
      } else {
        _contentBloc.add(ContentEvent.addStory(story, audioFile: _audioFile, characterFile: _characterFile));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _contentBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(widget.storyToEdit != null ? 'تعديل القصة' : 'إضافة قصة لـ: ${widget.mission.title}'),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: BlocConsumer<ContentBloc, ContentState>(
          listener: (context, state) {
            state.maybeWhen(
              storyAdded: (_) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة القصة بنجاح!')));
                context.pop(true);
              },
              storiesLoaded: (_) {
                if (widget.storyToEdit != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث القصة بنجاح!')));
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

            return SafeArea(top: false, bottom: true, 
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'عنوان القصة'),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'الشخصية الراوية',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    // Big 3D Viewer for the selected avatar
                    if (_characterFile == null)
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7), // Amber-100
                          borderRadius: BorderRadius.circular(AppColors.border_radius),
                          border: Border.all(color: const Color(0xFFF59E0B), width: 3), // Amber-500
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Flutter3DViewer(
                          key: ValueKey(_selectedCharacter), // Rebuild when character changes
                          src: CharacterHelper.getModelPath(_selectedCharacter),
                        ),
                      )
                    else
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppColors.border_radius),
                          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.view_in_ar, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'تم اختيار شخصية مخصصة\n${_characterFile!.path.split('/').last}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Selection Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _avatars.length,
                      itemBuilder: (context, index) {
                        final avatar = _avatars[index];
                        final isSelected = _selectedCharacter.toLowerCase().contains(avatar);
                        final displayName = CharacterHelper.getCleanName(avatar);
                        final charColor = CharacterHelper.getColor(avatar);
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCharacter = avatar),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppColors.border_radius),
                              border: Border.all(
                                color: isSelected ? charColor : Colors.transparent,
                                width: 3,
                              ),
                              color: isSelected ? charColor.withOpacity(0.15) : Theme.of(context).colorScheme.surface,
                            ),
                            child: Center(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? charColor : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Upload custom 3D character button
                    InkWell(
                      onTap: _pickCharacter,
                      borderRadius: BorderRadius.circular(AppColors.border_radius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppColors.border_radius),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _characterFile != null ? 'الشخصية: ${_characterFile!.path.split('/').last}' : 'أو ارفع شخصية مخصصة (3D)',
                                style: TextStyle(
                                  color: _characterFile != null ? Colors.black87 : Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              _characterFile != null ? Icons.check_circle : Icons.upload_file,
                              color: _characterFile != null ? Colors.green : Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_characterFile != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _characterFile = null;
                            _selectedCharacter = _avatars.first;
                          });
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('إلغاء الشخصية المخصصة'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: _pickAudio,
                      borderRadius: BorderRadius.circular(AppColors.border_radius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppColors.border_radius),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _audioFile != null
                                    ? 'ملف الصوت: ${_audioFile!.path.split('/').last}'
                                    : 'إرفاق ملف صوتي (اختياري)',
                                style: TextStyle(
                                  color: _audioFile != null ? Colors.black87 : Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              _audioFile != null ? Icons.check_circle : Icons.audiotrack,
                              color: _audioFile != null ? Colors.green : Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'محتوى القصة',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 10,
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                widget.storyToEdit != null ? 'تحديث القصة' : 'نشر القصة الآن',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        ),
      ),
    );
  }
}
