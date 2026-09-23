import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/story_timeline.dart';
import '../utils/character_helper.dart';
import '../theme/app_colors.dart';

class StoryTimelineEditor extends StatefulWidget {
  final File audioFile;
  final StoryTimeline? initialTimeline;
  final ValueChanged<StoryTimeline> onTimelineChanged;

  const StoryTimelineEditor({
    super.key,
    required this.audioFile,
    this.initialTimeline,
    required this.onTimelineChanged,
  });

  @override
  State<StoryTimelineEditor> createState() => _StoryTimelineEditorState();
}

class _StoryTimelineEditorState extends State<StoryTimelineEditor> {
  late AudioPlayer _audioPlayer;
  Duration _totalDuration = Duration.zero;
  List<StoryBlock> _blocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    if (widget.initialTimeline != null) {
      _blocks = List.from(widget.initialTimeline!.blocks);
    }
    _loadAudioDuration();
  }

  @override
  void didUpdateWidget(covariant StoryTimelineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioFile.path != widget.audioFile.path) {
      _loadAudioDuration();
    }
  }

  Future<void> _loadAudioDuration() async {
    setState(() => _isLoading = true);
    try {
      await _audioPlayer.setSourceDeviceFile(widget.audioFile.path);
      final duration = await _audioPlayer.getDuration();
      if (duration != null && mounted) {
        setState(() {
          _totalDuration = duration;
          _isLoading = false;
        });
        
        // If no blocks, add a default block covering the whole audio for the first character
        if (_blocks.isEmpty && duration.inSeconds > 0) {
          _blocks.add(StoryBlock(
            characterId: 'port', // Default
            startTime: 0.0,
            endTime: duration.inMilliseconds / 1000.0,
          ));
          _notifyChanged();
        }
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onTimelineChanged(StoryTimeline(
      blocks: _blocks,
      totalDuration: _totalDuration.inMilliseconds / 1000.0,
    ));
  }

  void _addBlock() {
    double start = 0.0;
    if (_blocks.isNotEmpty) {
      start = _blocks.last.endTime;
    }
    
    // Ensure we don't exceed total duration
    double totalSecs = _totalDuration.inMilliseconds / 1000.0;
    if (start >= totalSecs) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وصلت لنهاية المقطع الصوتي')),
      );
      return;
    }

    double end = start + 5.0; // Default 5 seconds
    if (end > totalSecs) end = totalSecs;

    setState(() {
      _blocks.add(StoryBlock(
        characterId: 'port',
        startTime: start,
        endTime: end,
      ));
    });
    _notifyChanged();
  }

  void _updateBlock(int index, String? newChar, double? newStart, double? newEnd) {
    setState(() {
      final old = _blocks[index];
      _blocks[index] = StoryBlock(
        characterId: newChar ?? old.characterId,
        startTime: newStart ?? old.startTime,
        endTime: newEnd ?? old.endTime,
      );
      
      // Auto-adjust the start time of the next block
      if (newEnd != null && index < _blocks.length - 1) {
        final next = _blocks[index + 1];
        _blocks[index + 1] = StoryBlock(
          characterId: next.characterId,
          startTime: newEnd,
          endTime: next.endTime,
        );
      }
    });
    _notifyChanged();
  }

  void _removeBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
      // Auto adjust times to fill gap
      if (index > 0 && index < _blocks.length) {
         final prev = _blocks[index - 1];
         final next = _blocks[index];
         _blocks[index] = StoryBlock(
           characterId: next.characterId,
           startTime: prev.endTime, // connect them
           endTime: next.endTime
         );
      }
    });
    _notifyChanged();
  }

  String _formatTime(double seconds) {
    final d = Duration(milliseconds: (seconds * 1000).round());
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppColors.border_radius),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'المحرر الزمني (Timeline)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'المدة: ${_formatTime(_totalDuration.inMilliseconds / 1000.0)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_blocks.isEmpty)
            const Center(child: Text('لم يتم إضافة مقاطع بعد'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _blocks.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                final block = _blocks[index];
                return Row(
                  children: [
                    // Character selector
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: CharacterHelper.characters.keys.contains(block.characterId) 
                            ? block.characterId 
                            : 'port',
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: CharacterHelper.characters.keys.map((key) {
                          return DropdownMenuItem(
                            value: key,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 8,
                                  backgroundColor: CharacterHelper.getColor(key),
                                ),
                                const SizedBox(width: 8),
                                Text(CharacterHelper.getCleanName(key)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) _updateBlock(index, val, null, null);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time adjuster
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(_formatTime(block.startTime), style: const TextStyle(fontSize: 12)),
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Divider(thickness: 2),
                                ),
                              ),
                              Text(_formatTime(block.endTime), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          Slider(
                            value: block.endTime,
                            min: block.startTime + 0.5,
                            max: (index == _blocks.length - 1) 
                                ? (_totalDuration.inMilliseconds / 1000.0)
                                : (_blocks[index+1].endTime - 0.5),
                            onChanged: (val) => _updateBlock(index, null, null, val),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeBlock(index),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _addBlock,
              icon: const Icon(Icons.add),
              label: const Text('إضافة مقطع لشخصية جديدة'),
            ),
          ),
        ],
      ),
    );
  }
}
