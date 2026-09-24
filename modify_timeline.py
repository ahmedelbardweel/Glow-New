import os
import sys

file_path = r'c:\Users\Ahmed\AndroidStudioProjects\glow_app\lib\core\widgets\story_timeline_editor.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Add import
if 'story_motion.dart' not in text:
    text = text.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../animation/story_motion.dart';")

# State variables
state_vars_target = '''  late AudioPlayer _localAudioPlayer; 
  Duration _totalDuration = Duration.zero;
  List<StoryBlock> _blocks = [];
  bool _isLoading = true;
  
  double _pixelsPerSecond = 80.0;
  final double _blockHeight = 50.0;
  final double _trackHeight = 60.0;
  final double _waveformHeight = 40.0;
  
  final GlobalKey _trackKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  
  int? _selectedBlockIndex;'''
state_vars_new = '''  late AudioPlayer _localAudioPlayer; 
  Duration _totalDuration = Duration.zero;
  List<StoryBlock> _blocks = [];
  List<StoryMotionBlock> _motionBlocks = [];
  bool _isLoading = true;
  
  double _pixelsPerSecond = 80.0;
  final double _blockHeight = 50.0;
  final double _trackHeight = 60.0;
  final double _waveformHeight = 40.0;
  
  final GlobalKey _trackKey = GlobalKey();
  final GlobalKey _motionTrackKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  
  int? _selectedBlockIndex;
  int? _selectedMotionBlockIndex;
  String? _lastPreviewCharacter;
  String? _lastPreviewMotion;'''
if '_motionBlocks =' not in text:
    text = text.replace(state_vars_target, state_vars_new)

# Init State
init_state_target = '''    if (widget.initialTimeline != null && widget.initialTimeline!.blocks.isNotEmpty) {
      _blocks = List.from(widget.initialTimeline!.blocks);
    }'''
init_state_new = '''    if (widget.initialTimeline != null) {
      if (widget.initialTimeline!.blocks.isNotEmpty) {
        _blocks = List.from(widget.initialTimeline!.blocks);
      }
      if (widget.initialTimeline!.motionBlocks.isNotEmpty) {
        _motionBlocks = List.from(widget.initialTimeline!.motionBlocks);
      }
    }'''
if 'widget.initialTimeline!.motionBlocks' not in text:
    text = text.replace(init_state_target, init_state_new)

# Notify Changed
notify_target = '''  void _notifyChanged() {
    _blocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    widget.onTimelineChanged(
      StoryTimeline(
        blocks: _blocks,
        totalDuration: _totalDuration.inMilliseconds / 1000.0,
      ),
    );
  }'''
notify_new = '''  void _notifyChanged() {
    _blocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    _motionBlocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    widget.onTimelineChanged(
      StoryTimeline(
        blocks: _blocks,
        motionBlocks: _motionBlocks,
        totalDuration: _totalDuration.inMilliseconds / 1000.0,
      ),
    );
  }'''
if '_motionBlocks.sort' not in text:
    text = text.replace(notify_target, notify_new)

# Motion Blocks Methods
motion_methods = '''
  void _addMotionBlockAtTime(String motionId, double timeInSeconds) {
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (totalSeconds == 0) return;

    if (timeInSeconds < 0) timeInSeconds = 0;
    double end = timeInSeconds + 3.0;
    if (end > totalSeconds) end = totalSeconds;

    final List<StoryMotionBlock> updatedBlocks = [];
    for (var b in _motionBlocks) {
      if (b.endTime <= timeInSeconds || b.startTime >= end) {
        updatedBlocks.add(b);
      } else if (b.startTime < timeInSeconds && b.endTime > end) {
        updatedBlocks.add(
          StoryMotionBlock(motionId: b.motionId, startTime: b.startTime, endTime: timeInSeconds),
        );
        updatedBlocks.add(
          StoryMotionBlock(motionId: b.motionId, startTime: end, endTime: b.endTime),
        );
      } else if (b.startTime < timeInSeconds && b.endTime <= end) {
        updatedBlocks.add(
          StoryMotionBlock(motionId: b.motionId, startTime: b.startTime, endTime: timeInSeconds),
        );
      } else if (b.startTime >= timeInSeconds && b.endTime > end) {
        updatedBlocks.add(
          StoryMotionBlock(motionId: b.motionId, startTime: end, endTime: b.endTime),
        );
      }
    }
    updatedBlocks.add(
      StoryMotionBlock(motionId: motionId, startTime: timeInSeconds, endTime: end),
    );

    setState(() {
      _motionBlocks = updatedBlocks;
      _selectedMotionBlockIndex = _motionBlocks.indexWhere((b) => b.startTime == timeInSeconds);
      _selectedBlockIndex = null;
    });
    _notifyChanged();
  }

  void _updateMotionBlockStart(int index, double deltaSeconds) {
    final block = _motionBlocks[index];
    double newStart = block.startTime + deltaSeconds;
    if (newStart < 0) newStart = 0;
    if (newStart > block.endTime - 0.5) newStart = block.endTime - 0.5;
    if (index > 0) {
      final prevBlock = _motionBlocks[index - 1];
      if (newStart < prevBlock.endTime) newStart = prevBlock.endTime;
    }
    setState(() {
      _motionBlocks[index] = StoryMotionBlock(
        motionId: block.motionId,
        startTime: newStart,
        endTime: block.endTime,
      );
    });
    _notifyChanged();
  }

  void _updateMotionBlockEnd(int index, double deltaSeconds) {
    final block = _motionBlocks[index];
    double newEnd = block.endTime + deltaSeconds;
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newEnd > totalSeconds) newEnd = totalSeconds;
    if (newEnd < block.startTime + 0.5) newEnd = block.startTime + 0.5;
    if (index < _motionBlocks.length - 1) {
      final nextBlock = _motionBlocks[index + 1];
      if (newEnd > nextBlock.startTime) newEnd = nextBlock.startTime;
    }
    setState(() {
      _motionBlocks[index] = StoryMotionBlock(
        motionId: block.motionId,
        startTime: block.startTime,
        endTime: newEnd,
      );
    });
    _notifyChanged();
  }

  void _moveMotionBlock(int index, double deltaSeconds) {
    final block = _motionBlocks[index];
    double newStart = block.startTime + deltaSeconds;
    double duration = block.endTime - block.startTime;
    if (newStart < 0) newStart = 0;
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newStart + duration > totalSeconds) newStart = totalSeconds - duration;
    if (index > 0 && newStart < _motionBlocks[index - 1].endTime) {
      newStart = _motionBlocks[index - 1].endTime;
    }
    if (index < _motionBlocks.length - 1 && (newStart + duration) > _motionBlocks[index + 1].startTime) {
      newStart = _motionBlocks[index + 1].startTime - duration;
    }
    setState(() {
      _motionBlocks[index] = StoryMotionBlock(
        motionId: block.motionId,
        startTime: newStart,
        endTime: newStart + duration,
      );
    });
    _notifyChanged();
  }

  String? _getActiveMotionAt(double time) {
    for (var b in _motionBlocks) {
      if (time >= b.startTime && time <= b.endTime) return b.motionId;
    }
    return null;
  }
'''
if '_addMotionBlockAtTime' not in text:
    get_char = '''  String? _getActiveCharacterAt(double time) {
    for (var b in _blocks) {
      if (time >= b.startTime && time <= b.endTime) return b.characterId;
    }
    return null;
  }'''
    text = text.replace(get_char, get_char + motion_methods)


# Toolbar methods (Split, Delete, Duplicate)
# We will just replace the methods completely to be safe.
split_target = '''  void _splitBlock() {
    if (_selectedBlockIndex == null) return;
    final time = (widget.positionNotifier?.value.inMilliseconds ?? 0) / 1000.0;
    final index = _selectedBlockIndex!;
    final block = _blocks[index];

    if (time > block.startTime + 0.1 && time < block.endTime - 0.1) {
      setState(() {
        _blocks[index] = StoryBlock(
          characterId: block.characterId,
          startTime: block.startTime,
          endTime: time,
        );
        _blocks.insert(
          index + 1,
          StoryBlock(
            characterId: block.characterId,
            startTime: time,
            endTime: block.endTime,
          ),
        );
        _selectedBlockIndex = index + 1;
      });
      _notifyChanged();
    }
  }'''
split_new = '''  void _splitBlock() {
    final time = (widget.positionNotifier?.value.inMilliseconds ?? 0) / 1000.0;
    if (_selectedBlockIndex != null) {
      final index = _selectedBlockIndex!;
      final block = _blocks[index];
      if (time > block.startTime + 0.1 && time < block.endTime - 0.1) {
        setState(() {
          _blocks[index] = StoryBlock(characterId: block.characterId, startTime: block.startTime, endTime: time);
          _blocks.insert(index + 1, StoryBlock(characterId: block.characterId, startTime: time, endTime: block.endTime));
          _selectedBlockIndex = index + 1;
        });
        _notifyChanged();
      }
    } else if (_selectedMotionBlockIndex != null) {
      final index = _selectedMotionBlockIndex!;
      final block = _motionBlocks[index];
      if (time > block.startTime + 0.1 && time < block.endTime - 0.1) {
        setState(() {
          _motionBlocks[index] = StoryMotionBlock(motionId: block.motionId, startTime: block.startTime, endTime: time);
          _motionBlocks.insert(index + 1, StoryMotionBlock(motionId: block.motionId, startTime: time, endTime: block.endTime));
          _selectedMotionBlockIndex = index + 1;
        });
        _notifyChanged();
      }
    }
  }'''
if 'if (_selectedMotionBlockIndex != null)' not in split_target and 'StoryMotionBlock' not in split_target:
    text = text.replace(split_target, split_new)

del_target = '''  void _deleteBlock() {
    if (_selectedBlockIndex != null) {
      setState(() {
        _blocks.removeAt(_selectedBlockIndex!);
        _selectedBlockIndex = null;
      });
      _notifyChanged();
    }
  }'''
del_new = '''  void _deleteBlock() {
    if (_selectedBlockIndex != null) {
      setState(() {
        _blocks.removeAt(_selectedBlockIndex!);
        _selectedBlockIndex = null;
      });
      _notifyChanged();
    } else if (_selectedMotionBlockIndex != null) {
      setState(() {
        _motionBlocks.removeAt(_selectedMotionBlockIndex!);
        _selectedMotionBlockIndex = null;
      });
      _notifyChanged();
    }
  }'''
if 'removeAt(_selectedMotionBlockIndex' not in text:
    text = text.replace(del_target, del_new)

dup_target = '''  void _duplicateBlock() {
    if (_selectedBlockIndex != null) {
      final block = _blocks[_selectedBlockIndex!];
      final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
      final duration = block.endTime - block.startTime;
      double newStart = block.endTime;
      double newEnd = newStart + duration;

      if (newStart >= totalSeconds) return;
      if (newEnd > totalSeconds) newEnd = totalSeconds;

      _addBlockAtTime(block.characterId, newStart);
    }
  }'''
dup_new = '''  void _duplicateBlock() {
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (_selectedBlockIndex != null) {
      final block = _blocks[_selectedBlockIndex!];
      final duration = block.endTime - block.startTime;
      double newStart = block.endTime;
      double newEnd = newStart + duration;
      if (newStart >= totalSeconds) return;
      _addBlockAtTime(block.characterId, newStart);
    } else if (_selectedMotionBlockIndex != null) {
      final block = _motionBlocks[_selectedMotionBlockIndex!];
      final duration = block.endTime - block.startTime;
      double newStart = block.endTime;
      double newEnd = newStart + duration;
      if (newStart >= totalSeconds) return;
      _addMotionBlockAtTime(block.motionId, newStart);
    }
  }'''
if '_addMotionBlockAtTime(block.motionId' not in text:
    text = text.replace(dup_target, dup_new)


# UI Track building
build_track_target = '''  Widget _buildTrack(double trackWidth, double totalSeconds) {
    return Container(
      height: _trackHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.inputBorder, width: 0.5),
      ),
      child: DragTarget<String>(
        key: _trackKey,
        onWillAcceptWithDetails: (details) => CharacterHelper.characters.keys.contains(details.data),
        onAcceptWithDetails: (details) {
          final renderBox = _trackKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final offset = renderBox.globalToLocal(details.offset);
            final scrollOffset = _scrollController.offset;
            final timeInSeconds = (offset.dx + scrollOffset) / _pixelsPerSecond;
            _addBlockAtTime(details.data, timeInSeconds);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Stack(
            children: [
              if (candidateData.isNotEmpty)
                Container(
                  color: Colors.blue.withOpacity(0.1),
                ),
              ..._blocks.asMap().entries.map((entry) {
                final index = entry.key;
                final block = entry.value;
                return _buildBlockWidget(index, block);
              }),
            ],
          );
        },
      ),
    );
  }'''

build_motion_track = '''
  Widget _buildMotionTrack(double trackWidth, double totalSeconds) {
    return Container(
      height: _trackHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.inputBorder, width: 0.5),
      ),
      child: DragTarget<String>(
        key: _motionTrackKey,
        onWillAcceptWithDetails: (details) => CharacterMotion.values.any((m) => m.name == details.data),
        onAcceptWithDetails: (details) {
          final renderBox = _motionTrackKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final offset = renderBox.globalToLocal(details.offset);
            final scrollOffset = _scrollController.offset;
            final timeInSeconds = (offset.dx + scrollOffset) / _pixelsPerSecond;
            _addMotionBlockAtTime(details.data, timeInSeconds);
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Stack(
            children: [
              if (candidateData.isNotEmpty)
                Container(
                  color: Colors.teal.withOpacity(0.1),
                ),
              ..._motionBlocks.asMap().entries.map((entry) {
                final index = entry.key;
                final block = entry.value;
                return _buildMotionBlockWidget(index, block);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMotionBlockWidget(int index, StoryMotionBlock block) {
    final left = block.startTime * _pixelsPerSecond;
    final width = (block.endTime - block.startTime) * _pixelsPerSecond;
    final isSelected = _selectedMotionBlockIndex == index;

    final motion = CharacterMotion.values.firstWhere((m) => m.name == block.motionId, orElse: () => CharacterMotion.idle);

    return Positioned(
      left: left,
      top: (_trackHeight - _blockHeight) / 2,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMotionBlockIndex = index;
            _selectedBlockIndex = null;
          });
        },
        onPanUpdate: (details) {
          _moveMotionBlock(index, details.delta.dx / _pixelsPerSecond);
        },
        child: Container(
          width: width,
          height: _blockHeight,
          decoration: BoxDecoration(
            color: Colors.teal.shade200,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? Colors.teal.shade800 : Colors.teal.shade400,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected ? [BoxShadow(color: Colors.teal.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  motion.arabicLabel,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSelected) ...[
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) => _updateMotionBlockStart(index, details.delta.dx / _pixelsPerSecond),
                    child: Container(width: 12, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.horizontal(left: Radius.circular(3)))),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onPanUpdate: (details) => _updateMotionBlockEnd(index, details.delta.dx / _pixelsPerSecond),
                    child: Container(width: 12, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.horizontal(right: Radius.circular(3)))),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
'''

if '_buildMotionTrack' not in text:
    text = text.replace(build_track_target, build_track_target + build_motion_track)

# UI Palette building
build_palette_target = '''  Widget _buildCharactersPalette() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: CharacterHelper.characters.keys.map((key) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Draggable<String>(
              data: key,
              feedback: Material(
                color: Colors.transparent,
                child: Opacity(
                  opacity: 0.7,
                  child: _buildPaletteItem(key),
                ),
              ),
              child: _buildPaletteItem(key),
            ),
          );
        }).toList(),
      ),
    );
  }'''

build_motion_palette = '''
  Widget _buildMotionsPalette() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: CharacterMotion.values.map((motion) {
          final isSelected = _selectedMotionBlockIndex != null && _motionBlocks.isNotEmpty && _selectedMotionBlockIndex! < _motionBlocks.length && _motionBlocks[_selectedMotionBlockIndex!].motionId == motion.name;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Draggable<String>(
              data: motion.name,
              feedback: Material(
                color: Colors.transparent,
                child: Opacity(
                  opacity: 0.7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.teal.shade300, borderRadius: BorderRadius.circular(8)),
                    child: Text(motion.arabicLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.teal.shade300 : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: Text(motion.arabicLabel, style: TextStyle(color: isSelected ? Colors.white : Colors.teal.shade800, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
'''
if '_buildMotionsPalette' not in text:
    text = text.replace(build_palette_target, build_palette_target + build_motion_palette)

# UI Build Method Updates
build_method_target = '''  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    final trackWidth = totalSeconds * _pixelsPerSecond;
    final currentTime =
        (widget.positionNotifier?.value.inMilliseconds ?? 0) / 1000.0;
    final activeCharacter = _getActiveCharacterAt(currentTime);
    _lastPreviewCharacter = activeCharacter ?? _lastPreviewCharacter;

    // Dark Mode Theme Wrapper'''
build_method_new = '''  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    final trackWidth = totalSeconds * _pixelsPerSecond;
    final currentTime =
        (widget.positionNotifier?.value.inMilliseconds ?? 0) / 1000.0;
    final activeCharacter = _getActiveCharacterAt(currentTime);
    _lastPreviewCharacter = activeCharacter ?? _lastPreviewCharacter;

    final activeMotion = _getActiveMotionAt(currentTime);
    _lastPreviewMotion = activeMotion ?? _lastPreviewMotion;
    final currentMotionObj = _lastPreviewMotion != null
        ? CharacterMotion.values.firstWhere(
            (m) => m.name == _lastPreviewMotion,
            orElse: () => CharacterMotion.idle,
          )
        : null;

    // Dark Mode Theme Wrapper'''
if 'final activeMotion = _getActiveMotionAt(currentTime);' not in text:
    text = text.replace(build_method_target, build_method_new)


smart_viewer_target = '''                                isSpeaking:
                                    widget.isPlaying &&
                                    widget.audioFile.existsSync(),
                                playbackPosition: widget.positionNotifier,
                              )'''
smart_viewer_new = '''                                isSpeaking:
                                    widget.isPlaying &&
                                    widget.audioFile.existsSync(),
                                playbackPosition: widget.positionNotifier,
                                motion: currentMotionObj,
                              )'''
if 'motion: currentMotionObj' not in text:
    text = text.replace(smart_viewer_target, smart_viewer_new)

toolbar_copy = 'onPressed: _selectedBlockIndex != null ? _duplicateBlock : null'
toolbar_copy_new = 'onPressed: (_selectedBlockIndex != null || _selectedMotionBlockIndex != null) ? _duplicateBlock : null'
text = text.replace(toolbar_copy, toolbar_copy_new)

toolbar_split = 'onPressed: _selectedBlockIndex != null ? _splitBlock : null'
toolbar_split_new = 'onPressed: (_selectedBlockIndex != null || _selectedMotionBlockIndex != null) ? _splitBlock : null'
text = text.replace(toolbar_split, toolbar_split_new)

toolbar_del = 'onPressed: _selectedBlockIndex != null ? _deleteBlock : null'
toolbar_del_new = 'onPressed: (_selectedBlockIndex != null || _selectedMotionBlockIndex != null) ? _deleteBlock : null'
text = text.replace(toolbar_del, toolbar_del_new)

# Modify Scrollview Stack
scrollview_target = '''                                  _buildTrack(
                                    math.max(
                                      trackWidth,
                                      MediaQuery.of(context).size.width,
                                    ),
                                    totalSeconds,
                                  ),
                                ],
                              ),
                            ),
                            _buildPlayhead(currentTime),'''
scrollview_new = '''                                  _buildTrack(
                                    math.max(
                                      trackWidth,
                                      MediaQuery.of(context).size.width,
                                    ),
                                    totalSeconds,
                                  ),
                                  const SizedBox(height: 5),
                                  _buildMotionTrack(
                                    math.max(
                                      trackWidth,
                                      MediaQuery.of(context).size.width,
                                    ),
                                    totalSeconds,
                                  ),
                                ],
                              ),
                            ),
                            _buildPlayhead(currentTime, 120),'''
if '_buildMotionTrack(' not in text[text.find('_buildWaveform'):text.find('_buildPlayhead')]:
    text = text.replace(scrollview_target, scrollview_new)
    text = text.replace('height: 120, // Reduced from 160 to make room for 3D', 'height: 180, // Expanded for two tracks')
    
    # Fix playhead signature if it does not have height
    if '_buildPlayhead(double time, [double containerHeight = 60])' not in text:
        text = text.replace('  Widget _buildPlayhead(double time) {', '  Widget _buildPlayhead(double time, [double containerHeight = 60]) {')
        text = text.replace('height: _trackHeight,', 'height: containerHeight,')


palette_target = '''                    // Character Palette
                    SizedBox(
                      height: 60,
                      child: _buildCharactersPalette(),
                    ),'''
palette_new = '''                    // Tool Palettes
                    SizedBox(
                      height: 120,
                      child: Column(
                        children: [
                          Expanded(child: _buildCharactersPalette()),
                          Expanded(child: _buildMotionsPalette()),
                        ],
                      ),
                    ),'''
if '_buildMotionsPalette()' not in text:
    text = text.replace(palette_target, palette_new)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)
