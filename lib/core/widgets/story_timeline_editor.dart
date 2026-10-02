import 'dart:io';
import 'dart:math';
import 'package:Glow/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../animation/story_motion.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/story_timeline.dart';
import '../utils/character_helper.dart';
import 'app_bottom_sheet.dart';
import 'smart_character_viewer.dart';
import 'story_transition_frame.dart';

class StoryTimelineEditor extends StatefulWidget {
  final File audioFile;
  final StoryTimeline? initialTimeline;
  final ValueChanged<StoryTimeline> onTimelineChanged;
  final ValueNotifier<Duration>? positionNotifier;
  final AudioPlayer? audioPlayer;
  final bool isPlaying;
  final VoidCallback? onTogglePlay;
  final int appliedMontage;

  const StoryTimelineEditor({
    super.key,
    required this.audioFile,
    this.initialTimeline,
    required this.onTimelineChanged,
    this.positionNotifier,
    this.audioPlayer,
    this.isPlaying = false,
    this.onTogglePlay,
    this.appliedMontage = 0,
  });

  @override
  State<StoryTimelineEditor> createState() => _StoryTimelineEditorState();
}

class _StoryTimelineEditorState extends State<StoryTimelineEditor> {
  late AudioPlayer _localAudioPlayer; 
  Duration _totalDuration = Duration.zero;
  List<StoryBlock> _blocks = [];
  List<StoryMotionBlock> _motionBlocks = [];
  List<StoryHatBlock> _hatBlocks = [];
  List<StoryGlassesBlock> _glassesBlocks = [];
  List<StoryMusclesBlock> _musclesBlocks = [];
  List<StoryJumpBlock> _jumpBlocks = [];
  List<StoryTransition> _transitions = [];
  final List<_TimelineHistory> _history = [];
  bool _editing = false;
  bool _isLoading = true;
  
  double _pixelsPerSecond = 80.0;
  final double _paletteChipHeight = 40.0;
  final double _trackHeight = 40.0;
  final double _waveformHeight = 26.0;
  final double _laneGap = 2.0;
  final double _characterGap = 48;
  final double _rulerSpace = 4.0;

  static const _hatPaletteColors = <Color>[
    Color(0xFF2C2C2E),
    Color(0xFF1A1A1A),
    Color(0xFF4A3728),
    Color(0xFF8B4513),
    Color(0xFFC0392B),
    Color(0xFF277A59),
    Color(0xFF2E86C1),
    Color(0xFFF5F5F5),
  ];
  
  final GlobalKey _trackKey = GlobalKey();
  final GlobalKey _motionTrackKey = GlobalKey();
  final GlobalKey _hatTrackKey = GlobalKey();
  final GlobalKey _glassesTrackKey = GlobalKey();
  final GlobalKey _musclesTrackKey = GlobalKey();
  final GlobalKey _jumpTrackKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  
  int? _selectedBlockIndex;
  int? _selectedMotionBlockIndex;
  int? _selectedHatBlockIndex;
  int? _selectedGlassesBlockIndex;
  int? _selectedMusclesBlockIndex;
  int? _selectedJumpBlockIndex;
  int? _selectedTransitionIndex;
  int _paletteCategory = 0;
  static const _paletteCategoryNames = ['الشخصية', 'الحركة', 'القبعة', 'النظارة', 'العضلات', 'التأثير'];
  String? _lastPreviewCharacter;
  String? _lastPreviewMotion;

  @override
  void initState() {
    super.initState();
    _localAudioPlayer = AudioPlayer();
    if (widget.initialTimeline != null) {
      if (widget.initialTimeline!.blocks.isNotEmpty) {
        _blocks = List.from(widget.initialTimeline!.blocks);
      }
      if (widget.initialTimeline!.motionBlocks.isNotEmpty) {
        _motionBlocks = List.from(widget.initialTimeline!.motionBlocks);
      }
      if (widget.initialTimeline!.hatBlocks.isNotEmpty) {
        _hatBlocks = List.from(widget.initialTimeline!.hatBlocks);
      }
      if (widget.initialTimeline!.glassesBlocks.isNotEmpty) {
        _glassesBlocks = List.from(widget.initialTimeline!.glassesBlocks);
      }
      if (widget.initialTimeline!.musclesBlocks.isNotEmpty) {
        _musclesBlocks = List.from(widget.initialTimeline!.musclesBlocks);
      }
      if (widget.initialTimeline!.jumpBlocks.isNotEmpty) {
        _jumpBlocks = List.from(widget.initialTimeline!.jumpBlocks);
      }
      if (widget.initialTimeline!.transitions.isNotEmpty) {
        _transitions = List.from(widget.initialTimeline!.transitions);
        _collapseTransitionSeams();
      }
    }
    _loadAudioDuration();
    
    widget.positionNotifier?.addListener(_onPositionChanged);
  }

  @override
  void didUpdateWidget(covariant StoryTimelineEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioFile.path != widget.audioFile.path) {
      _loadAudioDuration();
    }
    if (oldWidget.positionNotifier != widget.positionNotifier) {
      oldWidget.positionNotifier?.removeListener(_onPositionChanged);
      widget.positionNotifier?.addListener(_onPositionChanged);
    }
    final next = widget.initialTimeline;
    if (oldWidget.appliedMontage != widget.appliedMontage && next != null) {
      _editing = false;
      _armEdit();
      _motionBlocks = List.of(next.motionBlocks);
      _hatBlocks = List.of(next.hatBlocks);
      _glassesBlocks = List.of(next.glassesBlocks);
      _musclesBlocks = List.of(next.musclesBlocks);
      _jumpBlocks = List.of(next.jumpBlocks);
      _transitions = List.of(next.transitions);
      _selectedBlockIndex = null;
      _selectedMotionBlockIndex = null;
      _selectedHatBlockIndex = null;
      _selectedGlassesBlockIndex = null;
      _selectedMusclesBlockIndex = null;
      _selectedJumpBlockIndex = null;
      _selectedTransitionIndex = null;
      _editing = false;
      _previewLook = '';
    }
  }

  String _previewLook = '';

  void _onPositionChanged() {
    if (!mounted) return;
    if (_scrollController.hasClients && widget.positionNotifier != null) {
      final currentTime = widget.positionNotifier!.value.inMilliseconds / 1000.0;
      final playheadPos = currentTime * _pixelsPerSecond;
      final offset = _scrollController.offset;
      final width = _scrollController.position.viewportDimension;
      
      // Keep playhead within the visible 80% of the screen
      if (playheadPos > offset + width * 0.8) {
        _scrollController.jumpTo(playheadPos - width * 0.8);
      } else if (playheadPos < offset) {
        _scrollController.jumpTo(playheadPos);
      }
    }
    final time = (widget.positionNotifier?.value.inMilliseconds ?? 0) / 1000.0;
    final hat = _getActiveHatAt(time);
    final look = '${_getActiveCharacterAt(time)}|${_getActiveMotionAt(time)}|${hat?.colorHex ?? ''}|${_glassesOnAt(time)}|${_musclesOnAt(time)}';
    if (look == _previewLook) return;
    _previewLook = look;
    setState(() {});
  }

  Future<void> _loadAudioDuration() async {
    setState(() => _isLoading = true);
    try {
      await _localAudioPlayer.setSourceDeviceFile(widget.audioFile.path);
      final duration = await _localAudioPlayer.getDuration();
      if (duration != null && mounted) {
        setState(() {
          _totalDuration = duration;
          _isLoading = false;
        });
        
        final totalSeconds = duration.inMilliseconds / 1000.0;
        
        // Timeline starts empty by default
        if (_blocks.isEmpty) {
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
    widget.positionNotifier?.removeListener(_onPositionChanged);
    _localAudioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _armEdit() {
    if (_editing) return;
    _editing = true;
    _history.add(_TimelineHistory.capture(this));
    if (_history.length > 30) _history.removeAt(0);
  }

  void _finishEdit() {
    if (!_editing) return;
    _editing = false;
    setState(() {});
  }

  void _undo() {
    if (_history.isEmpty) return;
    final snap = _history.removeLast();
    _editing = false;
    setState(() {
      _blocks = List.of(snap.blocks);
      _motionBlocks = List.of(snap.motionBlocks);
      _hatBlocks = List.of(snap.hatBlocks);
      _glassesBlocks = List.of(snap.glassesBlocks);
      _musclesBlocks = List.of(snap.musclesBlocks);
      _jumpBlocks = List.of(snap.jumpBlocks);
      _transitions = List.of(snap.transitions);
      _selectedBlockIndex = null;
      _selectedMotionBlockIndex = null;
      _selectedHatBlockIndex = null;
      _selectedGlassesBlockIndex = null;
      _selectedMusclesBlockIndex = null;
      _selectedJumpBlockIndex = null;
      _selectedTransitionIndex = null;
    });
    _notifyChanged();
  }

  bool _picked(int? index, int length) => index != null && index >= 0 && index < length;

  (double, double)? _selectedSpan() {
    if (_picked(_selectedBlockIndex, _blocks.length)) {
      final block = _blocks[_selectedBlockIndex!];
      return (block.startTime, block.endTime);
    }
    if (_picked(_selectedMotionBlockIndex, _motionBlocks.length)) {
      final block = _motionBlocks[_selectedMotionBlockIndex!];
      return (block.startTime, block.endTime);
    }
    if (_picked(_selectedHatBlockIndex, _hatBlocks.length)) {
      final block = _hatBlocks[_selectedHatBlockIndex!];
      return (block.startTime, block.endTime);
    }
    if (_picked(_selectedGlassesBlockIndex, _glassesBlocks.length)) {
      final block = _glassesBlocks[_selectedGlassesBlockIndex!];
      return (block.startTime, block.endTime);
    }
    if (_picked(_selectedMusclesBlockIndex, _musclesBlocks.length)) {
      final block = _musclesBlocks[_selectedMusclesBlockIndex!];
      return (block.startTime, block.endTime);
    }
    if (_picked(_selectedJumpBlockIndex, _jumpBlocks.length)) {
      final block = _jumpBlocks[_selectedJumpBlockIndex!];
      return (block.startTime, block.endTime);
    }
    if (_picked(_selectedTransitionIndex, _transitions.length)) {
      final time = _transitions[_selectedTransitionIndex!].time;
      return (time, time);
    }
    return null;
  }

  double? _guideTime() {
    if (!_editing) return null;
    final span = _selectedSpan();
    if (span == null || _pixelsPerSecond <= 0) return null;
    final slack = 6 / _pixelsPerSecond;
    double? best;
    var bestDist = slack;
    for (var i = 0; i < _blocks.length; i++) {
      if (_selectedBlockIndex == i) continue;
      final block = _blocks[i];
      for (final edge in [block.startTime, block.endTime]) {
        for (final mine in [span.$1, span.$2]) {
          final dist = (mine - edge).abs();
          if (dist > bestDist) continue;
          bestDist = dist;
          best = edge;
        }
      }
    }
    return best;
  }

  bool get _canDuplicate =>
      _picked(_selectedBlockIndex, _blocks.length) ||
      _picked(_selectedMotionBlockIndex, _motionBlocks.length) ||
      _picked(_selectedHatBlockIndex, _hatBlocks.length) ||
      _picked(_selectedGlassesBlockIndex, _glassesBlocks.length) ||
      _picked(_selectedMusclesBlockIndex, _musclesBlocks.length) ||
      _picked(_selectedJumpBlockIndex, _jumpBlocks.length);

  bool get _canCopyLook {
    if (!_picked(_selectedBlockIndex, _blocks.length)) return false;
    final start = _blocks[_selectedBlockIndex!].startTime;
    return _blocks.any((block) => block.startTime > start + 0.01);
  }

  void _notifyChanged() {
    _collapseTransitionSeams();
    _blocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    _motionBlocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    _hatBlocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    _glassesBlocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    _musclesBlocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    _jumpBlocks.sort((a, b) => a.startTime.compareTo(b.startTime));
    _transitions.sort((a, b) => a.time.compareTo(b.time));
    widget.onTimelineChanged(StoryTimeline(
      blocks: _blocks,
      motionBlocks: _motionBlocks,
      hatBlocks: _hatBlocks,
      glassesBlocks: _glassesBlocks,
      musclesBlocks: _musclesBlocks,
      jumpBlocks: _jumpBlocks,
      transitions: _transitions,
      totalDuration: _totalDuration.inMilliseconds / 1000.0,
    ));
  }

  double _laneBlockHeight(bool selected) => selected ? _trackHeight + 8 : _trackHeight;

  double _laneBlockTop(bool selected) => selected ? -4 : 0;

  Widget _trackHint(String text) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(double seconds) {
    final d = Duration(milliseconds: (seconds * 1000).round());
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _addBlockAtTime(String characterId, double timeInSeconds) {
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (totalSeconds == 0) return;

    if (timeInSeconds < 0) timeInSeconds = 0;
    double end = timeInSeconds + 3.0;
    if (end > totalSeconds) end = totalSeconds;

    final List<StoryBlock> updatedBlocks = [];
    for (var b in _blocks) {
      if (b.endTime <= timeInSeconds || b.startTime >= end) {
        updatedBlocks.add(b);
      } else if (b.startTime < timeInSeconds && b.endTime > end) {
        updatedBlocks.add(StoryBlock(characterId: b.characterId, startTime: b.startTime, endTime: timeInSeconds));
        updatedBlocks.add(StoryBlock(characterId: b.characterId, startTime: end, endTime: b.endTime));
      } else if (b.startTime < timeInSeconds && b.endTime <= end) {
        updatedBlocks.add(StoryBlock(characterId: b.characterId, startTime: b.startTime, endTime: timeInSeconds));
      } else if (b.startTime >= timeInSeconds && b.endTime > end) {
        updatedBlocks.add(StoryBlock(characterId: b.characterId, startTime: end, endTime: b.endTime));
      }
    }
    updatedBlocks.add(StoryBlock(characterId: characterId, startTime: timeInSeconds, endTime: end));

    _armEdit();
    setState(() {
      _blocks = updatedBlocks;
      _selectedBlockIndex = _blocks.indexWhere((b) => b.startTime == timeInSeconds);
      _selectedMotionBlockIndex = null;
      _selectedHatBlockIndex = null;
      _selectedGlassesBlockIndex = null;
      _selectedMusclesBlockIndex = null;
    });
    _notifyChanged();
    _finishEdit();
  }

  void _updateBlockStart(int index, double deltaSeconds) {
    if (!_picked(index, _blocks.length)) return;
    final block = _blocks[index];
    double newStart = block.startTime + deltaSeconds;
    
    if (newStart < 0) newStart = 0;
    if (newStart > block.endTime - 0.5) newStart = block.endTime - 0.5;
    
    if (index > 0) {
      final prevBlock = _blocks[index - 1];
      if (newStart < prevBlock.endTime) newStart = prevBlock.endTime;
    }

    setState(() {
      _blocks[index] = StoryBlock(
        characterId: block.characterId,
        startTime: newStart,
        endTime: block.endTime,
      );
    });
    _notifyChanged();
  }

  void _updateBlockEnd(int index, double deltaSeconds) {
    if (!_picked(index, _blocks.length)) return;
    final block = _blocks[index];
    double newEnd = block.endTime + deltaSeconds;
    
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newEnd > totalSeconds) newEnd = totalSeconds;
    if (newEnd < block.startTime + 0.5) newEnd = block.startTime + 0.5;
    
    if (index < _blocks.length - 1) {
      final nextBlock = _blocks[index + 1];
      if (newEnd > nextBlock.startTime) newEnd = nextBlock.startTime;
    }

    setState(() {
      _blocks[index] = StoryBlock(
        characterId: block.characterId,
        startTime: block.startTime,
        endTime: newEnd,
      );
    });
    _notifyChanged();
  }

  void _moveBlock(int index, double deltaSeconds) {
    if (!_picked(index, _blocks.length)) return;
    final block = _blocks[index];
    double newStart = block.startTime + deltaSeconds;
    double duration = block.endTime - block.startTime;
    
    if (newStart < 0) newStart = 0;
    
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newStart + duration > totalSeconds) newStart = totalSeconds - duration;

    if (index > 0 && newStart < _blocks[index - 1].endTime) {
      newStart = _blocks[index - 1].endTime;
    }
    if (index < _blocks.length - 1 && (newStart + duration) > _blocks[index + 1].startTime) {
      newStart = _blocks[index + 1].startTime - duration;
    }

    setState(() {
      _blocks[index] = StoryBlock(
        characterId: block.characterId,
        startTime: newStart,
        endTime: newStart + duration,
      );
    });
    _notifyChanged();
  }

  void _splitBlock() {
    if (!_picked(_selectedBlockIndex, _blocks.length)) return;
    final time = (widget.positionNotifier?.value.inMilliseconds ?? 0) / 1000.0;
    final index = _selectedBlockIndex!;
    final block = _blocks[index];

    if (time > block.startTime + 0.1 && time < block.endTime - 0.1) {
      _armEdit();
      setState(() {
        _blocks[index] = StoryBlock(characterId: block.characterId, startTime: block.startTime, endTime: time);
        _blocks.insert(index + 1, StoryBlock(characterId: block.characterId, startTime: time, endTime: block.endTime));
        _selectedBlockIndex = index + 1;
      });
      _notifyChanged();
      _finishEdit();
    }
  }

  void _deleteBlock() {
    if (_picked(_selectedBlockIndex, _blocks.length)) {
      _armEdit();
      setState(() {
        _blocks.removeAt(_selectedBlockIndex!);
        _selectedBlockIndex = null;
      });
    } else if (_picked(_selectedMotionBlockIndex, _motionBlocks.length)) {
      _armEdit();
      setState(() {
        _motionBlocks.removeAt(_selectedMotionBlockIndex!);
        _selectedMotionBlockIndex = null;
      });
    } else if (_picked(_selectedHatBlockIndex, _hatBlocks.length)) {
      _armEdit();
      setState(() {
        _hatBlocks.removeAt(_selectedHatBlockIndex!);
        _selectedHatBlockIndex = null;
      });
    } else if (_picked(_selectedGlassesBlockIndex, _glassesBlocks.length)) {
      _armEdit();
      setState(() {
        _glassesBlocks.removeAt(_selectedGlassesBlockIndex!);
        _selectedGlassesBlockIndex = null;
      });
    } else if (_picked(_selectedMusclesBlockIndex, _musclesBlocks.length)) {
      _armEdit();
      setState(() {
        _musclesBlocks.removeAt(_selectedMusclesBlockIndex!);
        _selectedMusclesBlockIndex = null;
      });
    } else if (_picked(_selectedJumpBlockIndex, _jumpBlocks.length)) {
      _armEdit();
      setState(() {
        _jumpBlocks.removeAt(_selectedJumpBlockIndex!);
        _selectedJumpBlockIndex = null;
      });
    } else if (_picked(_selectedTransitionIndex, _transitions.length)) {
      _armEdit();
      setState(() {
        _transitions.removeAt(_selectedTransitionIndex!);
        _selectedTransitionIndex = null;
      });
    } else {
      return;
    }
    _notifyChanged();
    _finishEdit();
  }

  void _addTransitionAt(double seam, String type) {
    if (_transitions.any((item) => (item.time - seam).abs() < 0.2)) return;
    _transitions.add(StoryTransition(time: seam, type: type));
    _notifyChanged();
    setState(() {
      _selectedTransitionIndex = _transitions.indexWhere((item) => (item.time - seam).abs() < 0.05);
      _selectedBlockIndex = null;
      _selectedMotionBlockIndex = null;
      _selectedHatBlockIndex = null;
      _selectedGlassesBlockIndex = null;
      _selectedMusclesBlockIndex = null;
      _selectedJumpBlockIndex = null;
    });
  }

  int _seamIndexForTime(double time, List<double> seams) {
    if (seams.isEmpty) return -1;
    var best = 0;
    var bestDist = (time - seams[0]).abs();
    for (var i = 1; i < seams.length; i++) {
      final dist = (time - seams[i]).abs();
      if (dist < bestDist) {
        best = i;
        bestDist = dist;
      }
    }
    return best;
  }

  void _collapseTransitionSeams() {
    final seams = _characterSeams();
    if (seams.isEmpty) {
      _transitions = [];
      return;
    }
    final kept = <StoryTransition>[];
    for (var i = 0; i < seams.length; i++) {
      StoryTransition? chosen;
      var chosenDist = double.infinity;
      for (final item in _transitions) {
        if (_seamIndexForTime(item.time, seams) != i) continue;
        final dist = (item.time - seams[i]).abs();
        if (dist > chosenDist) continue;
        chosenDist = dist;
        chosen = StoryTransition(time: seams[i], duration: item.duration, type: item.type);
      }
      if (chosen != null) kept.add(chosen);
    }
    _transitions = kept;
  }

  void _placeTransition(double seam, String type) {
    _armEdit();
    _transitions.add(StoryTransition(time: seam, type: type));
    _collapseTransitionSeams();
    _notifyChanged();
    setState(() {
      _selectedTransitionIndex = _transitions.indexWhere((item) => (item.time - seam).abs() < 0.25);
      _selectedBlockIndex = null;
      _selectedMotionBlockIndex = null;
      _selectedHatBlockIndex = null;
      _selectedGlassesBlockIndex = null;
      _selectedMusclesBlockIndex = null;
      _selectedJumpBlockIndex = null;
    });
    _finishEdit();
  }

  Future<void> _openEffectSheet(double seam) async {
    final existing = _transitions.where((item) => (item.time - seam).abs() < 0.25);
    final picked = await showAppSheet<String>(
      context: context,
      heightFactor: 0.46,
      builder: (sheetContext) {
        return _EffectSheet(
          initial: existing.isEmpty ? StoryTransition.fade : existing.first.type,
          onAdd: (type) => Navigator.of(sheetContext).pop(type),
        );
      },
    );
    if (picked == null || !mounted) return;
    _placeTransition(seam, picked);
  }

  StoryTransitionPose _poseAt(double time) {
    return StoryTimeline(
      blocks: const [],
      transitions: _transitions,
      jumpBlocks: _jumpBlocks,
      totalDuration: 1,
    ).poseAt(time);
  }

  (double, double) _characterFrame(int index, StoryBlock block) {
    final rawLeft = block.startTime * _pixelsPerSecond;
    final rawRight = block.endTime * _pixelsPerSecond;
    var left = rawLeft;
    var right = rawRight;
    StoryBlock? previous;
    StoryBlock? following;
    for (var i = 0; i < _blocks.length; i++) {
      if (i == index) continue;
      final other = _blocks[i];
      if (other.endTime <= block.startTime + 0.05) {
        if (previous == null || other.endTime > previous.endTime) previous = other;
      }
      if (other.startTime >= block.endTime - 0.05) {
        if (following == null || other.startTime < following.startTime) following = other;
      }
    }
    if (previous != null) left += _characterGap / 2;
    if (following != null) right -= _characterGap / 2;
    if (right - left < 20) {
      final middle = (rawLeft + rawRight) / 2;
      left = middle - 10;
      right = middle + 10;
    }
    return (left, right - left);
  }

  List<double> _characterSeams() {
    final ordered = [..._blocks]..sort((a, b) => a.startTime.compareTo(b.startTime));
    final seams = <double>[];
    for (var i = 0; i < ordered.length - 1; i++) {
      final current = ordered[i];
      final next = ordered[i + 1];
      seams.add(current.endTime <= next.startTime
          ? (current.endTime + next.startTime) / 2
          : current.endTime);
    }
    return seams;
  }

  String? _getActiveCharacterAt(double time) {
    for (var b in _blocks) {
      if (time >= b.startTime && time <= b.endTime) return b.characterId;
    }
    return null;
  }

  String? _getActiveMotionAt(double time) {
    for (var b in _motionBlocks) {
      if (time >= b.startTime && time <= b.endTime) return b.motionId;
    }
    return null;
  }

  StoryHatBlock? _getActiveHatAt(double time) {
    for (var b in _hatBlocks) {
      if (time >= b.startTime && time <= b.endTime) return b;
    }
    return null;
  }

  bool _glassesOnAt(double time) {
    for (var b in _glassesBlocks) {
      if (time >= b.startTime && time <= b.endTime) return true;
    }
    return false;
  }

  bool _musclesOnAt(double time) {
    for (var b in _musclesBlocks) {
      if (time >= b.startTime && time <= b.endTime) return true;
    }
    return false;
  }

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

    _armEdit();
    setState(() {
      _motionBlocks = updatedBlocks;
      _selectedMotionBlockIndex = _motionBlocks.indexWhere((b) => b.startTime == timeInSeconds);
      _selectedBlockIndex = null;
      _selectedHatBlockIndex = null;
      _selectedGlassesBlockIndex = null;
      _selectedMusclesBlockIndex = null;
    });
    _notifyChanged();
    _finishEdit();
  }

  void _updateMotionBlockStart(int index, double deltaSeconds) {
    if (!_picked(index, _motionBlocks.length)) return;
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
    if (!_picked(index, _motionBlocks.length)) return;
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
    if (!_picked(index, _motionBlocks.length)) return;
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

  void _addHatBlockAtTime(String colorHex, double timeInSeconds) {
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (totalSeconds == 0) return;

    if (timeInSeconds < 0) timeInSeconds = 0;
    double end = timeInSeconds + 3.0;
    if (end > totalSeconds) end = totalSeconds;

    final List<StoryHatBlock> updatedBlocks = [];
    for (var b in _hatBlocks) {
      if (b.endTime <= timeInSeconds || b.startTime >= end) {
        updatedBlocks.add(b);
      } else if (b.startTime < timeInSeconds && b.endTime > end) {
        updatedBlocks.add(
          StoryHatBlock(colorHex: b.colorHex, startTime: b.startTime, endTime: timeInSeconds),
        );
        updatedBlocks.add(
          StoryHatBlock(colorHex: b.colorHex, startTime: end, endTime: b.endTime),
        );
      } else if (b.startTime < timeInSeconds && b.endTime <= end) {
        updatedBlocks.add(
          StoryHatBlock(colorHex: b.colorHex, startTime: b.startTime, endTime: timeInSeconds),
        );
      } else if (b.startTime >= timeInSeconds && b.endTime > end) {
        updatedBlocks.add(
          StoryHatBlock(colorHex: b.colorHex, startTime: end, endTime: b.endTime),
        );
      }
    }
    updatedBlocks.add(
      StoryHatBlock(colorHex: colorHex, startTime: timeInSeconds, endTime: end),
    );

    _armEdit();
    setState(() {
      _hatBlocks = updatedBlocks;
      _selectedHatBlockIndex = _hatBlocks.indexWhere((b) => b.startTime == timeInSeconds);
      _selectedBlockIndex = null;
      _selectedMotionBlockIndex = null;
      _selectedGlassesBlockIndex = null;
      _selectedMusclesBlockIndex = null;
    });
    _notifyChanged();
    _finishEdit();
  }

  void _updateHatBlockStart(int index, double deltaSeconds) {
    if (!_picked(index, _hatBlocks.length)) return;
    final block = _hatBlocks[index];
    double newStart = block.startTime + deltaSeconds;
    if (newStart < 0) newStart = 0;
    if (newStart > block.endTime - 0.5) newStart = block.endTime - 0.5;
    if (index > 0) {
      final prevBlock = _hatBlocks[index - 1];
      if (newStart < prevBlock.endTime) newStart = prevBlock.endTime;
    }
    setState(() {
      _hatBlocks[index] = StoryHatBlock(
        colorHex: block.colorHex,
        startTime: newStart,
        endTime: block.endTime,
      );
    });
    _notifyChanged();
  }

  void _updateHatBlockEnd(int index, double deltaSeconds) {
    if (!_picked(index, _hatBlocks.length)) return;
    final block = _hatBlocks[index];
    double newEnd = block.endTime + deltaSeconds;
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newEnd > totalSeconds) newEnd = totalSeconds;
    if (newEnd < block.startTime + 0.5) newEnd = block.startTime + 0.5;
    if (index < _hatBlocks.length - 1) {
      final nextBlock = _hatBlocks[index + 1];
      if (newEnd > nextBlock.startTime) newEnd = nextBlock.startTime;
    }
    setState(() {
      _hatBlocks[index] = StoryHatBlock(
        colorHex: block.colorHex,
        startTime: block.startTime,
        endTime: newEnd,
      );
    });
    _notifyChanged();
  }

  void _moveHatBlock(int index, double deltaSeconds) {
    if (!_picked(index, _hatBlocks.length)) return;
    final block = _hatBlocks[index];
    double newStart = block.startTime + deltaSeconds;
    double duration = block.endTime - block.startTime;
    if (newStart < 0) newStart = 0;
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newStart + duration > totalSeconds) newStart = totalSeconds - duration;
    if (index > 0 && newStart < _hatBlocks[index - 1].endTime) {
      newStart = _hatBlocks[index - 1].endTime;
    }
    if (index < _hatBlocks.length - 1 && (newStart + duration) > _hatBlocks[index + 1].startTime) {
      newStart = _hatBlocks[index + 1].startTime - duration;
    }
    setState(() {
      _hatBlocks[index] = StoryHatBlock(
        colorHex: block.colorHex,
        startTime: newStart,
        endTime: newStart + duration,
      );
    });
    _notifyChanged();
  }

  void _addGlassesBlockAtTime(double timeInSeconds) {
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (totalSeconds == 0) return;
    if (timeInSeconds < 0) timeInSeconds = 0;
    double end = timeInSeconds + 3.0;
    if (end > totalSeconds) end = totalSeconds;

    final updated = <StoryGlassesBlock>[];
    for (var b in _glassesBlocks) {
      if (b.endTime <= timeInSeconds || b.startTime >= end) {
        updated.add(b);
      } else if (b.startTime < timeInSeconds && b.endTime > end) {
        updated.add(StoryGlassesBlock(startTime: b.startTime, endTime: timeInSeconds));
        updated.add(StoryGlassesBlock(startTime: end, endTime: b.endTime));
      } else if (b.startTime < timeInSeconds && b.endTime <= end) {
        updated.add(StoryGlassesBlock(startTime: b.startTime, endTime: timeInSeconds));
      } else if (b.startTime >= timeInSeconds && b.endTime > end) {
        updated.add(StoryGlassesBlock(startTime: end, endTime: b.endTime));
      }
    }
    updated.add(StoryGlassesBlock(startTime: timeInSeconds, endTime: end));
    _armEdit();
    setState(() {
      _glassesBlocks = updated;
      _selectedGlassesBlockIndex = _glassesBlocks.indexWhere((b) => b.startTime == timeInSeconds);
      _selectedBlockIndex = null;
      _selectedMotionBlockIndex = null;
      _selectedHatBlockIndex = null;
      _selectedMusclesBlockIndex = null;
    });
    _notifyChanged();
    _finishEdit();
  }

  void _updateGlassesBlockStart(int index, double deltaSeconds) {
    if (!_picked(index, _glassesBlocks.length)) return;
    final block = _glassesBlocks[index];
    double newStart = block.startTime + deltaSeconds;
    if (newStart < 0) newStart = 0;
    if (newStart > block.endTime - 0.5) newStart = block.endTime - 0.5;
    if (index > 0 && newStart < _glassesBlocks[index - 1].endTime) {
      newStart = _glassesBlocks[index - 1].endTime;
    }
    setState(() {
      _glassesBlocks[index] = StoryGlassesBlock(startTime: newStart, endTime: block.endTime);
    });
    _notifyChanged();
  }

  void _updateGlassesBlockEnd(int index, double deltaSeconds) {
    if (!_picked(index, _glassesBlocks.length)) return;
    final block = _glassesBlocks[index];
    double newEnd = block.endTime + deltaSeconds;
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newEnd > totalSeconds) newEnd = totalSeconds;
    if (newEnd < block.startTime + 0.5) newEnd = block.startTime + 0.5;
    if (index < _glassesBlocks.length - 1 && newEnd > _glassesBlocks[index + 1].startTime) {
      newEnd = _glassesBlocks[index + 1].startTime;
    }
    setState(() {
      _glassesBlocks[index] = StoryGlassesBlock(startTime: block.startTime, endTime: newEnd);
    });
    _notifyChanged();
  }

  void _moveGlassesBlock(int index, double deltaSeconds) {
    if (!_picked(index, _glassesBlocks.length)) return;
    final block = _glassesBlocks[index];
    final duration = block.endTime - block.startTime;
    double newStart = block.startTime + deltaSeconds;
    if (newStart < 0) newStart = 0;
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newStart + duration > totalSeconds) newStart = totalSeconds - duration;
    if (index > 0 && newStart < _glassesBlocks[index - 1].endTime) {
      newStart = _glassesBlocks[index - 1].endTime;
    }
    if (index < _glassesBlocks.length - 1 &&
        (newStart + duration) > _glassesBlocks[index + 1].startTime) {
      newStart = _glassesBlocks[index + 1].startTime - duration;
    }
    setState(() {
      _glassesBlocks[index] = StoryGlassesBlock(
        startTime: newStart,
        endTime: newStart + duration,
      );
    });
    _notifyChanged();
  }

  void _addMusclesBlockAtTime(double timeInSeconds) {
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (totalSeconds == 0) return;
    if (timeInSeconds < 0) timeInSeconds = 0;
    double end = timeInSeconds + 3.0;
    if (end > totalSeconds) end = totalSeconds;

    final updated = <StoryMusclesBlock>[];
    for (var b in _musclesBlocks) {
      if (b.endTime <= timeInSeconds || b.startTime >= end) {
        updated.add(b);
      } else if (b.startTime < timeInSeconds && b.endTime > end) {
        updated.add(StoryMusclesBlock(startTime: b.startTime, endTime: timeInSeconds));
        updated.add(StoryMusclesBlock(startTime: end, endTime: b.endTime));
      } else if (b.startTime < timeInSeconds && b.endTime <= end) {
        updated.add(StoryMusclesBlock(startTime: b.startTime, endTime: timeInSeconds));
      } else if (b.startTime >= timeInSeconds && b.endTime > end) {
        updated.add(StoryMusclesBlock(startTime: end, endTime: b.endTime));
      }
    }
    updated.add(StoryMusclesBlock(startTime: timeInSeconds, endTime: end));
    _armEdit();
    setState(() {
      _musclesBlocks = updated;
      _selectedMusclesBlockIndex = _musclesBlocks.indexWhere((b) => b.startTime == timeInSeconds);
      _selectedBlockIndex = null;
      _selectedMotionBlockIndex = null;
      _selectedHatBlockIndex = null;
      _selectedGlassesBlockIndex = null;
    });
    _notifyChanged();
    _finishEdit();
  }

  void _updateMusclesBlockStart(int index, double deltaSeconds) {
    if (!_picked(index, _musclesBlocks.length)) return;
    final block = _musclesBlocks[index];
    double newStart = block.startTime + deltaSeconds;
    if (newStart < 0) newStart = 0;
    if (newStart > block.endTime - 0.5) newStart = block.endTime - 0.5;
    if (index > 0 && newStart < _musclesBlocks[index - 1].endTime) {
      newStart = _musclesBlocks[index - 1].endTime;
    }
    setState(() {
      _musclesBlocks[index] = StoryMusclesBlock(startTime: newStart, endTime: block.endTime);
    });
    _notifyChanged();
  }

  void _updateMusclesBlockEnd(int index, double deltaSeconds) {
    if (!_picked(index, _musclesBlocks.length)) return;
    final block = _musclesBlocks[index];
    double newEnd = block.endTime + deltaSeconds;
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newEnd > totalSeconds) newEnd = totalSeconds;
    if (newEnd < block.startTime + 0.5) newEnd = block.startTime + 0.5;
    if (index < _musclesBlocks.length - 1 && newEnd > _musclesBlocks[index + 1].startTime) {
      newEnd = _musclesBlocks[index + 1].startTime;
    }
    setState(() {
      _musclesBlocks[index] = StoryMusclesBlock(startTime: block.startTime, endTime: newEnd);
    });
    _notifyChanged();
  }

  void _moveMusclesBlock(int index, double deltaSeconds) {
    if (!_picked(index, _musclesBlocks.length)) return;
    final block = _musclesBlocks[index];
    final duration = block.endTime - block.startTime;
    double newStart = block.startTime + deltaSeconds;
    if (newStart < 0) newStart = 0;
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newStart + duration > totalSeconds) newStart = totalSeconds - duration;
    if (index > 0 && newStart < _musclesBlocks[index - 1].endTime) {
      newStart = _musclesBlocks[index - 1].endTime;
    }
    if (index < _musclesBlocks.length - 1 &&
        (newStart + duration) > _musclesBlocks[index + 1].startTime) {
      newStart = _musclesBlocks[index + 1].startTime - duration;
    }
    setState(() {
      _musclesBlocks[index] = StoryMusclesBlock(
        startTime: newStart,
        endTime: newStart + duration,
      );
    });
    _notifyChanged();
  }
  
  (double, double)? _fitCopy(double start, double end, double? nextStart) {
    final total = _totalDuration.inMilliseconds / 1000.0;
    if (total <= 0 || start >= total - 0.05) return null;
    var finish = end > total ? total : end;
    if (nextStart != null && finish > nextStart) finish = nextStart;
    if (finish - start < 0.2) return null;
    return (start, finish);
  }

  double? _followingStart(Iterable<double> starts, double after) {
    double? next;
    for (final start in starts) {
      if (start + 0.001 < after) continue;
      if (next == null || start < next) next = start;
    }
    return next;
  }

  int? _keep(int? index) => index != null && index >= 0 ? index : null;

  void _selectOnly({int? block, int? motion, int? hat, int? glasses, int? muscles, int? jump}) {
    _selectedBlockIndex = _keep(block);
    _selectedMotionBlockIndex = _keep(motion);
    _selectedHatBlockIndex = _keep(hat);
    _selectedGlassesBlockIndex = _keep(glasses);
    _selectedMusclesBlockIndex = _keep(muscles);
    _selectedJumpBlockIndex = _keep(jump);
    _selectedTransitionIndex = null;
  }

  void _duplicateBlock() {
    if (!_canDuplicate) return;
    final total = _totalDuration.inMilliseconds / 1000.0;
    if (_picked(_selectedBlockIndex, _blocks.length)) {
      final block = _blocks[_selectedBlockIndex!];
      if (block.endTime >= total) return;
      _addBlockAtTime(block.characterId, block.endTime);
      return;
    }

    late final void Function() add;
    if (_picked(_selectedMotionBlockIndex, _motionBlocks.length)) {
      final block = _motionBlocks[_selectedMotionBlockIndex!];
      final fit = _fitCopy(block.endTime, block.endTime + (block.endTime - block.startTime), _followingStart(_motionBlocks.map((item) => item.startTime), block.endTime));
      if (fit == null) return;
      add = () {
        _motionBlocks.add(StoryMotionBlock(motionId: block.motionId, startTime: fit.$1, endTime: fit.$2));
        _notifyChanged();
        _selectOnly(motion: _motionBlocks.lastIndexWhere((item) => (item.startTime - fit.$1).abs() < 0.001));
      };
    } else if (_picked(_selectedHatBlockIndex, _hatBlocks.length)) {
      final block = _hatBlocks[_selectedHatBlockIndex!];
      final fit = _fitCopy(block.endTime, block.endTime + (block.endTime - block.startTime), _followingStart(_hatBlocks.map((item) => item.startTime), block.endTime));
      if (fit == null) return;
      add = () {
        _hatBlocks.add(StoryHatBlock(colorHex: block.colorHex, startTime: fit.$1, endTime: fit.$2));
        _notifyChanged();
        _selectOnly(hat: _hatBlocks.lastIndexWhere((item) => (item.startTime - fit.$1).abs() < 0.001));
      };
    } else if (_picked(_selectedGlassesBlockIndex, _glassesBlocks.length)) {
      final block = _glassesBlocks[_selectedGlassesBlockIndex!];
      final fit = _fitCopy(block.endTime, block.endTime + (block.endTime - block.startTime), _followingStart(_glassesBlocks.map((item) => item.startTime), block.endTime));
      if (fit == null) return;
      add = () {
        _glassesBlocks.add(StoryGlassesBlock(startTime: fit.$1, endTime: fit.$2));
        _notifyChanged();
        _selectOnly(glasses: _glassesBlocks.lastIndexWhere((item) => (item.startTime - fit.$1).abs() < 0.001));
      };
    } else if (_picked(_selectedMusclesBlockIndex, _musclesBlocks.length)) {
      final block = _musclesBlocks[_selectedMusclesBlockIndex!];
      final fit = _fitCopy(block.endTime, block.endTime + (block.endTime - block.startTime), _followingStart(_musclesBlocks.map((item) => item.startTime), block.endTime));
      if (fit == null) return;
      add = () {
        _musclesBlocks.add(StoryMusclesBlock(startTime: fit.$1, endTime: fit.$2));
        _notifyChanged();
        _selectOnly(muscles: _musclesBlocks.lastIndexWhere((item) => (item.startTime - fit.$1).abs() < 0.001));
      };
    } else if (_picked(_selectedJumpBlockIndex, _jumpBlocks.length)) {
      final block = _jumpBlocks[_selectedJumpBlockIndex!];
      final fit = _fitCopy(block.endTime, block.endTime + (block.endTime - block.startTime), _followingStart(_jumpBlocks.map((item) => item.startTime), block.endTime));
      if (fit == null) return;
      add = () {
        _jumpBlocks.add(StoryJumpBlock(startTime: fit.$1, endTime: fit.$2));
        _notifyChanged();
        _selectOnly(jump: _jumpBlocks.lastIndexWhere((item) => (item.startTime - fit.$1).abs() < 0.001));
      };
    } else {
      return;
    }
    _armEdit();
    setState(add);
    _finishEdit();
  }

  (double, double)? _clipTo(double start, double end, double hostStart, double hostEnd) {
    final from = start < hostStart ? hostStart : start;
    final to = end > hostEnd ? hostEnd : end;
    if (to - from < 0.15) return null;
    return (from, to);
  }

  void _copyLook() {
    if (!_picked(_selectedBlockIndex, _blocks.length)) return;
    final source = _blocks[_selectedBlockIndex!];
    StoryBlock? next;
    for (final block in _blocks) {
      if (block.startTime <= source.startTime + 0.01) continue;
      if (next == null || block.startTime < next.startTime) next = block;
    }
    if (next == null) return;
    final target = next;
    final shift = target.startTime - source.startTime;
    bool onSource(double start, double end) => start < source.endTime && end > source.startTime;
    final motions = [for (final block in _motionBlocks) if (onSource(block.startTime, block.endTime)) block];
    final hats = [for (final block in _hatBlocks) if (onSource(block.startTime, block.endTime)) block];
    final glasses = [for (final block in _glassesBlocks) if (onSource(block.startTime, block.endTime)) block];
    final muscles = [for (final block in _musclesBlocks) if (onSource(block.startTime, block.endTime)) block];
    final jumps = [for (final block in _jumpBlocks) if (onSource(block.startTime, block.endTime)) block];
    if (motions.isEmpty && hats.isEmpty && glasses.isEmpty && muscles.isEmpty && jumps.isEmpty) return;

    bool onTarget(double start, double end) => start < target.endTime && end > target.startTime;
    _armEdit();
    setState(() {
      _motionBlocks.removeWhere((block) => onTarget(block.startTime, block.endTime));
      _hatBlocks.removeWhere((block) => onTarget(block.startTime, block.endTime));
      _glassesBlocks.removeWhere((block) => onTarget(block.startTime, block.endTime));
      _musclesBlocks.removeWhere((block) => onTarget(block.startTime, block.endTime));
      _jumpBlocks.removeWhere((block) => onTarget(block.startTime, block.endTime));
      for (final block in motions) {
        final clip = _clipTo(block.startTime + shift, block.endTime + shift, target.startTime, target.endTime);
        if (clip == null) continue;
        _motionBlocks.add(StoryMotionBlock(motionId: block.motionId, startTime: clip.$1, endTime: clip.$2));
      }
      for (final block in hats) {
        final clip = _clipTo(block.startTime + shift, block.endTime + shift, target.startTime, target.endTime);
        if (clip == null) continue;
        _hatBlocks.add(StoryHatBlock(colorHex: block.colorHex, startTime: clip.$1, endTime: clip.$2));
      }
      for (final block in glasses) {
        final clip = _clipTo(block.startTime + shift, block.endTime + shift, target.startTime, target.endTime);
        if (clip == null) continue;
        _glassesBlocks.add(StoryGlassesBlock(startTime: clip.$1, endTime: clip.$2));
      }
      for (final block in muscles) {
        final clip = _clipTo(block.startTime + shift, block.endTime + shift, target.startTime, target.endTime);
        if (clip == null) continue;
        _musclesBlocks.add(StoryMusclesBlock(startTime: clip.$1, endTime: clip.$2));
      }
      for (final block in jumps) {
        final clip = _clipTo(block.startTime + shift, block.endTime + shift, target.startTime, target.endTime);
        if (clip == null) continue;
        _jumpBlocks.add(StoryJumpBlock(startTime: clip.$1, endTime: clip.$2));
      }
    });
    _notifyChanged();
    _finishEdit();
  }

  void _zoom(double factor) {
    setState(() {
      _pixelsPerSecond = (_pixelsPerSecond * factor).clamp(20.0, 300.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    final trackWidth = totalSeconds * _pixelsPerSecond;
    final characterTop = _rulerSpace + _waveformHeight + _laneGap;
    final jumpTop = characterTop + _trackHeight + _laneGap;
    final motionTop = jumpTop + _trackHeight + _laneGap;
    final hatTop = motionTop + _trackHeight + _laneGap;
    final glassesTop = hatTop + _trackHeight + _laneGap;
    final musclesTop = glassesTop + _trackHeight + _laneGap;
    final timelineHeight = musclesTop + _trackHeight + 10;
    final currentTime = (widget.positionNotifier?.value.inMilliseconds ?? 0) / 1000.0;

    // Dark Mode Theme Wrapper
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          surface: Colors.white,
          primary: Colors.white,
        ),
      ),
      child: Builder(builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppColors.timeline_radius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Embedded 3D Viewer
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                        border: BoxBorder.all(color: AppColors.inputBorder)
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: widget.positionNotifier == null
                                ? _previewScene(currentTime)
                                : ValueListenableBuilder<Duration>(
                                    valueListenable: widget.positionNotifier!,
                                    builder: (context, position, child) {
                                      final time = position.inMilliseconds / 1000.0;
                                      if (_getActiveCharacterAt(time) == null) {
                                        return const Center(
                                          child: Text(
                                            'لا توجد شخصية في هذا الوقت',
                                            style: TextStyle(color: Colors.black, fontSize: 14),
                                          ),
                                        );
                                      }
                                      return StoryTransitionFrame(pose: _poseAt(time), child: child!);
                                    },
                                    child: _previewCharacter(currentTime),
                                  ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: widget.positionNotifier == null
                                ? _timeChip(currentTime, totalSeconds)
                                : ValueListenableBuilder<Duration>(
                                    valueListenable: widget.positionNotifier!,
                                    builder: (context, position, _) => _timeChip(
                                      position.inMilliseconds / 1000.0,
                                      totalSeconds,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
                            child: Row(
                              children: [
                                for (var i = 0; i < _paletteCategoryNames.length; i++)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3),
                                      child: GestureDetector(
                                        onTap: () => setState(() => _paletteCategory = i),
                                        child: Container(
                                          alignment: Alignment.center,
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _paletteCategory == i
                                                ? AppColors.secondary
                                                : AppColors.background,
                                            borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                            border: Border.all(
                                              color: _paletteCategory == i
                                                  ? AppColors.secondary
                                                  : AppColors.inputBorder,
                                            ),
                                          ),
                                          child: Text(
                                            _paletteCategoryNames[i],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: _paletteCategory == i
                                                  ? Colors.white
                                                  : AppColors.secondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_paletteCategory == 0)
                          _PaletteLane(
                            key: const ValueKey('character'),
                            labeled: false,
                            title: 'الشخصية',
                            children: CharacterHelper.characters.keys.map((key) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Draggable<String>(
                                  data: key,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      width: 72,
                                      height: _paletteChipHeight,
                                      decoration: BoxDecoration(
                                        color: CharacterHelper.getColor(key).withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                      ),
                                      child: Center(
                                        child: Text(
                                          CharacterHelper.getCleanName(key),
                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: _buildPaletteItem(key),
                                  ),
                                  child: _buildPaletteItem(key),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_paletteCategory == 1)
                          _PaletteLane(
                            key: const ValueKey('motion'),
                            labeled: false,
                            title: 'الحركة',
                            children: CharacterMotion.values.map((motion) {
                              final isSelected = _selectedMotionBlockIndex != null && _motionBlocks.isNotEmpty && _selectedMotionBlockIndex! < _motionBlocks.length && _motionBlocks[_selectedMotionBlockIndex!].motionId == motion.name;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Draggable<String>(
                                  data: motion.name,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      width: 72,
                                      height: _paletteChipHeight,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                        border: Border.all(color: AppColors.inputBorder),
                                      ),
                                      child: Center(child: Text(motion.arabicLabel, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: Container(
                                      width: 72,
                                      height: _paletteChipHeight,
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppColors.timeline_radius), border: Border.all(color: AppColors.inputBorder)),
                                      child: Center(child: Text(motion.arabicLabel, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
                                    ),
                                  ),
                                  child: Container(
                                    width: 72,
                                    height: _paletteChipHeight,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.teal.shade300 : Colors.white,
                                      borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                      border: Border.all(color: isSelected ? Colors.teal.shade300 : AppColors.inputBorder),
                                    ),
                                    child: Center(child: Text(motion.arabicLabel, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_paletteCategory == 2)
                          _PaletteLane(
                            key: const ValueKey('hat'),
                            labeled: false,
                            title: 'القبعة',
                            children: _hatPaletteColors.map((color) {
                              final dragData = StoryHatBlock.dragDataFor(color);
                              final selectedHex = _selectedHatBlockIndex != null &&
                                      _selectedHatBlockIndex! < _hatBlocks.length
                                  ? _hatBlocks[_selectedHatBlockIndex!].colorHex.toLowerCase()
                                  : null;
                              final isSelected = selectedHex ==
                                  ((color.toARGB32() & 0xFFFFFF)
                                      .toRadixString(16)
                                      .padLeft(6, '0'));
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Draggable<String>(
                                  data: dragData,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      width: 36,
                                      height: _paletteChipHeight,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                        border: Border.all(color: Colors.black26),
                                      ),
                                      child: const Icon(Icons.face_retouching_natural, color: Colors.white70, size: 22),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: _buildHatPaletteItem(color, false),
                                  ),
                                  child: _buildHatPaletteItem(color, isSelected),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_paletteCategory == 3)
                          _PaletteLane(
                            key: const ValueKey('glasses'),
                            labeled: false,
                            title: 'النظارة',
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Draggable<String>(
                                  data: StoryGlassesBlock.dragData,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: _glassesChip(false),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: _glassesChip(false),
                                  ),
                                  child: _glassesChip(_selectedGlassesBlockIndex != null),
                                ),
                              ),
                            ],
                          ),
                          if (_paletteCategory == 4)
                          _PaletteLane(
                            key: const ValueKey('muscles'),
                            labeled: false,
                            title: 'العضلات',
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Draggable<String>(
                                  data: StoryMusclesBlock.dragData,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: _musclesChip(false),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: _musclesChip(false),
                                  ),
                                  child: _musclesChip(_selectedMusclesBlockIndex != null),
                                ),
                              ),
                            ],
                          ),
                          if (_paletteCategory == 5)
                          _PaletteLane(
                            key: const ValueKey('transition'),
                            labeled: false,
                            title: 'التأثير',
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Draggable<String>(
                                  data: StoryJumpBlock.dragData,
                                  feedback: Material(
                                    color: Colors.transparent,
                                    child: _jumpChip(dragging: true),
                                  ),
                                  childWhenDragging: Opacity(opacity: 0.35, child: _jumpChip()),
                                  child: _jumpChip(),
                                ),
                              ),
                              for (final type in StoryTransition.types)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Draggable<String>(
                                    data: StoryTransition.dragDataFor(type),
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: _transitionChip(type, dragging: true),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.35,
                                      child: _transitionChip(type),
                                    ),
                                    child: _transitionChip(type),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        ),
                      ),
                    ),
                  ],
                ),

              // Toolbar & Playback Controls
              Container(
                margin: const EdgeInsets.fromLTRB(5, 0, 5, 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (widget.audioPlayer != null) ...[
                        _buildToolButton(
                          Icons.replay,
                          'إعادة',
                          () {
                            widget.audioPlayer?.seek(Duration.zero);
                            if (!widget.isPlaying && widget.onTogglePlay != null) widget.onTogglePlay!();
                          },
                        ),
                        const SizedBox(width: 5),
                        _buildToolButton(
                          widget.isPlaying ? Icons.pause : Icons.play_arrow,
                          widget.isPlaying ? 'إيقاف' : 'تشغيل',
                          widget.onTogglePlay,
                        ),
                        const SizedBox(width: 5),
                      ],
                      _buildToolButton(Icons.call_split, 'تقسيم', _picked(_selectedBlockIndex, _blocks.length) ? _splitBlock : null),
                      const SizedBox(width: 5),
                      _buildToolButton(Icons.copy, 'تكرار', _canDuplicate ? _duplicateBlock : null),
                      const SizedBox(width: 5),
                      _buildToolButton(Icons.auto_awesome, 'نسخ الشكل', _canCopyLook ? _copyLook : null),
                      const SizedBox(width: 5),
                      _buildToolButton(Icons.undo, 'تراجع', _history.isNotEmpty ? _undo : null),
                      const SizedBox(width: 5),
                      _buildToolButton(
                        Icons.delete_outline,
                        'حذف',
                        (_selectedBlockIndex != null ||
                                _selectedMotionBlockIndex != null ||
                                _selectedHatBlockIndex != null ||
                                _selectedGlassesBlockIndex != null ||
                                _selectedMusclesBlockIndex != null ||
                                _selectedJumpBlockIndex != null ||
                                _selectedTransitionIndex != null)
                            ? _deleteBlock
                            : null,
                        isDestructive: true,
                      ),
                      const SizedBox(width: 5),
                      _buildToolButton(Icons.zoom_out, 'تصغير', () => _zoom(0.8)),
                      const SizedBox(width: 5),
                      _buildToolButton(Icons.zoom_in, 'تكبير', () => _zoom(1.2)),
                    ],
                  ),
                ),
              ),

              // The lane card stays fixed. Only the timeline inside it scrolls.
              Directionality(
                textDirection: TextDirection.ltr,
                child: Container(
                  height: timelineHeight,
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: trackWidth,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Ruler marks
                            for (double s = 0; s <= totalSeconds; s += 1)
                              Positioned(
                                left: s * _pixelsPerSecond,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1,
                                  color: s % 5 == 0 ? Colors.white30 : Colors.white10,
                                  child: s % 5 == 0
                                      ? Transform.translate(
                                          offset: const Offset(4, 2),
                                          child: Text('${s.toInt()}s', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                        )
                                      : null,
                                ),
                              ),

                            // Audio Waveform Track
                            Positioned(
                              left: 0,
                              top: _rulerSpace,
                              width: trackWidth,
                              height: _waveformHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                  border: BoxBorder.all(
                                    color: AppColors.inputBorder
                                  )
                                ),
                                child: Stack(
                                  children: [
                                    CustomPaint(
                                      painter: _WaveformPainter(
                                        duration: totalSeconds,
                                        seed: widget.audioFile.path.hashCode,
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
                                    _trackHint('الصوت'),
                                  ],
                                ),
                              ),
                            ),

                            // Character Blocks Track
                            Positioned(
                              left: 0,
                              top: characterTop,
                              width: trackWidth,
                              height: _trackHeight,
                              child: DragTarget<String>(
                                onAcceptWithDetails: (details) {
                                  if (CharacterHelper.characters.keys.contains(details.data)) {
                                    if (_trackKey.currentContext != null) {
                                      final RenderBox box = _trackKey.currentContext!.findRenderObject() as RenderBox;
                                      final Offset localOffset = box.globalToLocal(details.offset);
                                      final double time = localOffset.dx / _pixelsPerSecond;
                                      _addBlockAtTime(details.data, time);
                                    }
                                  }
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return Container(
                                    key: _trackKey,
                                    decoration: BoxDecoration(
                                      color: candidateData.isNotEmpty ? AppColors.secondaryContainer : AppColors.background,
                                      borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                      border: Border.all(
                                        color: candidateData.isNotEmpty ? AppColors.secondary : AppColors.inputBorder,
                                        width: candidateData.isNotEmpty ? 2 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        if (_blocks.isEmpty) _trackHint('اسحب الشخصية إلى هنا'),
                                        ..._blocks.asMap().entries.map((entry) {
                                          return _buildTimelineBlock(entry.key, entry.value);
                                        }),
                                        ..._seamSlots(),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            Positioned(
                              left: 0,
                              top: jumpTop,
                              width: trackWidth,
                              height: _trackHeight,
                              child: DragTarget<String>(
                                onAcceptWithDetails: (details) {
                                  if (!StoryJumpBlock.isDrag(details.data)) return;
                                  if (_jumpTrackKey.currentContext != null) {
                                    final RenderBox box = _jumpTrackKey.currentContext!.findRenderObject() as RenderBox;
                                    final Offset localOffset = box.globalToLocal(details.offset);
                                    final double time = localOffset.dx / _pixelsPerSecond;
                                    _addJumpBlockAtTime(time);
                                  }
                                },
                                builder: (context, candidateData, rejectedData) {
                                  final canAccept = candidateData.whereType<String>().any(StoryJumpBlock.isDrag);
                                  return Container(
                                    key: _jumpTrackKey,
                                    decoration: BoxDecoration(
                                      color: canAccept ? AppColors.primaryContainer : AppColors.background,
                                      borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                      border: Border.all(
                                        color: canAccept ? AppColors.primary : AppColors.inputBorder,
                                        width: canAccept ? 2 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        if (_jumpBlocks.isEmpty) _trackHint('اسحب النطة إلى هنا'),
                                        ..._jumpBlocks.asMap().entries.map((entry) {
                                          return _buildJumpBlockWidget(entry.key, entry.value);
                                        }),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Motion Blocks Track
                            Positioned(
                              left: 0,
                              top: motionTop,
                              width: trackWidth,
                              height: _trackHeight,
                              child: DragTarget<String>(
                                onAcceptWithDetails: (details) {
                                  if (CharacterMotion.values.any((m) => m.name == details.data)) {
                                    if (_motionTrackKey.currentContext != null) {
                                      final RenderBox box = _motionTrackKey.currentContext!.findRenderObject() as RenderBox;
                                      final Offset localOffset = box.globalToLocal(details.offset);
                                      final double time = localOffset.dx / _pixelsPerSecond;
                                      _addMotionBlockAtTime(details.data, time);
                                    }
                                  }
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return Container(
                                    key: _motionTrackKey,
                                    decoration: BoxDecoration(
                                      color: candidateData.isNotEmpty ? AppColors.tertiaryContainer : AppColors.background,
                                      borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                      border: Border.all(
                                        color: candidateData.isNotEmpty ? AppColors.tertiary : AppColors.inputBorder,
                                        width: candidateData.isNotEmpty ? 2 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        if (_motionBlocks.isEmpty) _trackHint('اسحب الحركة إلى هنا'),
                                        ..._motionBlocks.asMap().entries.map((entry) {
                                          return _buildMotionBlockWidget(entry.key, entry.value);
                                        }),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Hat Blocks Track
                            Positioned(
                              left: 0,
                              top: hatTop,
                              width: trackWidth,
                              height: _trackHeight,
                              child: DragTarget<String>(
                                onAcceptWithDetails: (details) {
                                  final hex = StoryHatBlock.colorHexFromDrag(details.data);
                                  if (hex == null) return;
                                  if (_hatTrackKey.currentContext != null) {
                                    final RenderBox box = _hatTrackKey.currentContext!.findRenderObject() as RenderBox;
                                    final Offset localOffset = box.globalToLocal(details.offset);
                                    final double time = localOffset.dx / _pixelsPerSecond;
                                    _addHatBlockAtTime(hex, time);
                                  }
                                },
                                builder: (context, candidateData, rejectedData) {
                                  final canAccept = candidateData
                                      .whereType<String>()
                                      .any((d) => StoryHatBlock.colorHexFromDrag(d) != null);
                                  return Container(
                                    key: _hatTrackKey,
                                    decoration: BoxDecoration(
                                      color: canAccept ? AppColors.primaryContainer : AppColors.background,
                                      borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                      border: Border.all(
                                        color: canAccept ? AppColors.primary : AppColors.inputBorder,
                                        width: canAccept ? 2 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        if (_hatBlocks.isEmpty) _trackHint('اسحب القبعة إلى هنا'),
                                        ..._hatBlocks.asMap().entries.map((entry) {
                                          return _buildHatBlockWidget(entry.key, entry.value);
                                        }),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Glasses track, directly under the hat track.
                            Positioned(
                              left: 0,
                              top: glassesTop,
                              width: trackWidth,
                              height: _trackHeight,
                              child: DragTarget<String>(
                                onAcceptWithDetails: (details) {
                                  if (!StoryGlassesBlock.isDrag(details.data)) return;
                                  if (_glassesTrackKey.currentContext != null) {
                                    final RenderBox box = _glassesTrackKey.currentContext!.findRenderObject() as RenderBox;
                                    final Offset localOffset = box.globalToLocal(details.offset);
                                    final double time = localOffset.dx / _pixelsPerSecond;
                                    _addGlassesBlockAtTime(time);
                                  }
                                },
                                builder: (context, candidateData, rejectedData) {
                                  final canAccept = candidateData
                                      .whereType<String>()
                                      .any(StoryGlassesBlock.isDrag);
                                  return Container(
                                    key: _glassesTrackKey,
                                    decoration: BoxDecoration(
                                      color: canAccept ? AppColors.secondaryContainer : AppColors.background,
                                      borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                      border: Border.all(
                                        color: canAccept ? AppColors.secondary : AppColors.inputBorder,
                                        width: canAccept ? 2 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        if (_glassesBlocks.isEmpty) _trackHint('اسحب النظارة إلى هنا'),
                                        ..._glassesBlocks.asMap().entries.map((entry) {
                                          return _buildGlassesBlockWidget(entry.key, entry.value);
                                        }),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Muscles track, directly under the glasses track.
                            Positioned(
                              left: 0,
                              top: musclesTop,
                              width: trackWidth,
                              height: _trackHeight,
                              child: DragTarget<String>(
                                onAcceptWithDetails: (details) {
                                  if (!StoryMusclesBlock.isDrag(details.data)) return;
                                  if (_musclesTrackKey.currentContext != null) {
                                    final RenderBox box = _musclesTrackKey.currentContext!.findRenderObject() as RenderBox;
                                    final Offset localOffset = box.globalToLocal(details.offset);
                                    final double time = localOffset.dx / _pixelsPerSecond;
                                    _addMusclesBlockAtTime(time);
                                  }
                                },
                                builder: (context, candidateData, rejectedData) {
                                  final canAccept = candidateData
                                      .whereType<String>()
                                      .any(StoryMusclesBlock.isDrag);
                                  return Container(
                                    key: _musclesTrackKey,
                                    decoration: BoxDecoration(
                                      color: canAccept ? AppColors.secondaryContainer : AppColors.background,
                                      borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                      border: Border.all(
                                        color: canAccept ? AppColors.secondary : AppColors.inputBorder,
                                        width: canAccept ? 2 : 1,
                                      ),
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        if (_musclesBlocks.isEmpty) _trackHint('اسحب العضلات إلى هنا'),
                                        ..._musclesBlocks.asMap().entries.map((entry) {
                                          return _buildMusclesBlockWidget(entry.key, entry.value);
                                        }),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            if (_guideTime() != null)
                              Positioned(
                                left: _guideTime()! * _pixelsPerSecond - 1,
                                top: 0,
                                bottom: 0,
                                child: IgnorePointer(
                                  child: Container(width: 2, color: AppColors.primary),
                                ),
                              ),

                            // Playhead
                            if (widget.positionNotifier != null)
                              ValueListenableBuilder<Duration>(
                                valueListenable: widget.positionNotifier!,
                                builder: (context, position, child) => Positioned(
                                left: position.inMilliseconds / 1000.0 * _pixelsPerSecond,
                                top: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onHorizontalDragUpdate: (details) {
                                    if (widget.audioPlayer != null) {
                                      final RenderBox? box = _trackKey.currentContext?.findRenderObject() as RenderBox?;
                                      if (box != null) {
                                        final localOffset = box.globalToLocal(details.globalPosition);
                                        double time = localOffset.dx / _pixelsPerSecond;
                                        if (time < 0) time = 0;
                                        if (time > totalSeconds) time = totalSeconds;
                                        widget.audioPlayer!.seek(Duration(milliseconds: (time * 1000).toInt()));
                                      }
                                    }
                                  },
                                  child: child,
                                ),
                              ),
                              child: Container(
                                width: 60,
                                transform: Matrix4.translationValues(-30, 0, 0),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        width: 2.5,
                                        decoration: const BoxDecoration(
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ]
          )
        );
      }),
    );
  }

  Widget _timeChip(double time, double totalSeconds) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
        border: Border.all(color: AppColors.inputBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Text(
        '${_formatTime(time)} / ${_formatTime(totalSeconds)}',
        style: const TextStyle(color: Colors.black, fontSize: 12),
      ),
    );
  }

  Widget _previewScene(double time) {
    if (_getActiveCharacterAt(time) == null) {
      return const Center(
        child: Text(
          'لا توجد شخصية في هذا الوقت',
          style: TextStyle(color: Colors.black, fontSize: 14),
        ),
      );
    }
    return StoryTransitionFrame(
      pose: _poseAt(time),
      child: _previewCharacter(time),
    );
  }

  Widget _previewCharacter(double time) {
    final character = _getActiveCharacterAt(time);
    if (character == null) return const SizedBox.shrink();
    final motionName = _getActiveMotionAt(time);
    final hat = _getActiveHatAt(time);
    return SmartCharacterViewer(
      characterName: character,
      isPlaying: widget.isPlaying,
      isSpeaking: widget.isPlaying && widget.audioFile.existsSync(),
      playbackPosition: widget.positionNotifier,
      motion: motionName != null
          ? CharacterMotion.values.firstWhere((m) => m.name == motionName, orElse: () => CharacterMotion.idle)
          : null,
      showHat: hat != null,
      hatColor: hat?.color ?? const Color(0xFF2C2C2E),
      showGlasses: _glassesOnAt(time),
      showMuscles: _musclesOnAt(time),
    );
  }

  Widget _jumpChip({bool dragging = false}) {
    return Container(
      width: 64,
      height: _paletteChipHeight,
      decoration: BoxDecoration(
        color: dragging ? AppColors.secondary : AppColors.primary,
        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
      ),
      child: const Center(
        child: Text(
          'نطة',
          style: TextStyle(color: AppColors.onPrimary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _transitionChip(String type, {bool dragging = false}) {
    return Container(
      width: 64,
      height: _paletteChipHeight,
      decoration: BoxDecoration(
        color: dragging ? AppColors.primary : AppColors.secondary,
        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
      ),
      child: Center(
        child: Text(
          StoryTransition.label(type),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  IconData _transitionIcon(String type) {
    switch (type) {
      case StoryTransition.slide:
        return Icons.swap_horiz;
      case StoryTransition.pop:
        return Icons.open_in_full;
      default:
        return Icons.blur_on;
    }
  }

  List<Widget> _seamSlots() {
    final seams = _characterSeams();
    return [
      for (var i = 0; i < seams.length; i++)
        _buildSeamSlot(seams[i], _transitionIndexForSeam(i, seams)),
    ];
  }

  int _transitionIndexForSeam(int seamIndex, List<double> seams) {
    var best = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < _transitions.length; i++) {
      if (_seamIndexForTime(_transitions[i].time, seams) != seamIndex) continue;
      final dist = (_transitions[i].time - seams[seamIndex]).abs();
      if (dist >= bestDist) continue;
      bestDist = dist;
      best = i;
    }
    return best;
  }

  Widget _buildSeamSlot(double seam, int transitionIndex) {
    final filled = transitionIndex >= 0;
    final selected = filled && _selectedTransitionIndex == transitionIndex;
    return Positioned(
      left: seam * _pixelsPerSecond - 14,
      top: 4,
      width: 28,
      height: _trackHeight - 8,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) =>
            StoryTransition.isDrag(details.data) && !filled,
        onAcceptWithDetails: (details) {
          final type = StoryTransition.typeOf(details.data);
          if (type != null && !filled) _addTransitionAt(seam, type);
        },
        builder: (context, candidateData, rejectedData) {
          final hot = candidateData.any((data) => data != null && StoryTransition.isDrag(data));
          if (filled) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTransitionIndex = transitionIndex;
                  _selectedBlockIndex = null;
                  _selectedMotionBlockIndex = null;
                  _selectedHatBlockIndex = null;
                  _selectedGlassesBlockIndex = null;
                  _selectedMusclesBlockIndex = null;
                  _selectedJumpBlockIndex = null;
                });
                _openEffectSheet(seam);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.secondary,
                  borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                  border: Border.all(color: Colors.white, width: selected ? 2 : 1),
                ),
                child: Icon(
                  _transitionIcon(_transitions[transitionIndex].type),
                  size: 16,
                  color: Colors.white,
                ),
              ),
            );
          }
          return GestureDetector(
            onTap: () => _openEffectSheet(seam),
            child: Container(
              decoration: BoxDecoration(
                color: hot ? AppColors.primary.withValues(alpha: 0.35) : Colors.white,
                borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                border: Border.all(
                  color: hot ? AppColors.primary : AppColors.inputBorder,
                  width: hot ? 2 : 1,
                ),
              ),
              child: const Icon(Icons.add, size: 14, color: AppColors.secondary),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaletteItem(String key) {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: CharacterHelper.getColor(key),
        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Center(
        child: Text(
          CharacterHelper.getCleanName(key),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHatPaletteItem(Color color, bool isSelected) {
    return Container(
      width: 36,
      height: _paletteChipHeight,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
        border: Border.all(
          color: isSelected ? Colors.deepOrange : AppColors.inputBorder,
          width: isSelected ? 2.5 : 1,
        ),
      ),
      child: Icon(
        Icons.face_retouching_natural,
        color: color.computeLuminance() > 0.55 ? Colors.black54 : Colors.white70,
        size: 22,
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, VoidCallback? onPressed, {bool isDestructive = false}) {
    final color = onPressed == null 
        ? Colors.black
        : (isDestructive ? Colors.redAccent : Colors.black);
    
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppColors.timeline_radius),
      child: Container(
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(AppColors.timeline_radius),
         border: Border.all(color: AppColors.inputBorder),
       ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _edgeHandle({
    required bool start,
    required GestureDragUpdateCallback onDrag,
  }) {
    return Positioned(
      left: start ? -14 : null,
      right: start ? null : -14,
      top: 0,
      bottom: 0,
      width: 28,
      child: GestureDetector(
        onHorizontalDragStart: (_) => _armEdit(),
        onHorizontalDragUpdate: onDrag,
        onHorizontalDragEnd: (_) => _finishEdit(),
        onHorizontalDragCancel: _finishEdit,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppColors.timeline_radius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: const Icon(Icons.drag_indicator, size: 12, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildTimelineBlock(int index, StoryBlock block) {
    final frame = _characterFrame(index, block);
    final left = frame.$1;
    final width = frame.$2;
    final isSelected = _selectedBlockIndex == index;

    return Positioned(
      left: left,
      top: _laneBlockTop(isSelected),
      width: width,
      height: _laneBlockHeight(isSelected),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedBlockIndex = index;
            _selectedMotionBlockIndex = null;
            _selectedHatBlockIndex = null;
            _selectedGlassesBlockIndex = null;
            _selectedMusclesBlockIndex = null;
            _selectedJumpBlockIndex = null;
            _selectedTransitionIndex = null;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main Body
            GestureDetector(
              onHorizontalDragStart: (_) => _armEdit(),
              onHorizontalDragUpdate: (details) {
                _moveBlock(index, details.delta.dx / _pixelsPerSecond);
              },
              onHorizontalDragEnd: (_) => _finishEdit(),
              onHorizontalDragCancel: _finishEdit,
              child: Container(
                decoration: BoxDecoration(
                  color: CharacterHelper.getColor(block.characterId).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                  border: Border.all(
                    color: AppColors.inputBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Center(
                  child: Text(
                    CharacterHelper.getCleanName(block.characterId),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            
            if (isSelected) ...[
              _edgeHandle(
                start: true,
                onDrag: (details) => _updateBlockStart(index, details.delta.dx / _pixelsPerSecond),
              ),
              _edgeHandle(
                start: false,
                onDrag: (details) => _updateBlockEnd(index, details.delta.dx / _pixelsPerSecond),
              ),
            ]
          ],
        ),
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
      top: _laneBlockTop(isSelected),
      width: width,
      height: _laneBlockHeight(isSelected),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMotionBlockIndex = index;
            _selectedBlockIndex = null;
            _selectedHatBlockIndex = null;
            _selectedGlassesBlockIndex = null;
            _selectedMusclesBlockIndex = null;
            _selectedJumpBlockIndex = null;
            _selectedTransitionIndex = null;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main Body
            GestureDetector(
              onHorizontalDragStart: (_) => _armEdit(),
              onHorizontalDragUpdate: (details) {
                _moveMotionBlock(index, details.delta.dx / _pixelsPerSecond);
              },
              onHorizontalDragEnd: (_) => _finishEdit(),
              onHorizontalDragCancel: _finishEdit,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade300,
                  borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                  border: Border.all(
                    color: AppColors.inputBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: const [BoxShadow(color: Colors.teal, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: Center(
                  child: Text(
                    motion.arabicLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),

            if (isSelected) ...[
              _edgeHandle(
                start: true,
                onDrag: (details) => _updateMotionBlockStart(index, details.delta.dx / _pixelsPerSecond),
              ),
              _edgeHandle(
                start: false,
                onDrag: (details) => _updateMotionBlockEnd(index, details.delta.dx / _pixelsPerSecond),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHatBlockWidget(int index, StoryHatBlock block) {
    final left = block.startTime * _pixelsPerSecond;
    final width = (block.endTime - block.startTime) * _pixelsPerSecond;
    final isSelected = _selectedHatBlockIndex == index;
    final labelColor =
        block.color.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;

    return Positioned(
      left: left,
      top: _laneBlockTop(isSelected),
      width: width,
      height: _laneBlockHeight(isSelected),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedHatBlockIndex = index;
            _selectedBlockIndex = null;
            _selectedMotionBlockIndex = null;
            _selectedGlassesBlockIndex = null;
            _selectedMusclesBlockIndex = null;
            _selectedJumpBlockIndex = null;
            _selectedTransitionIndex = null;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onHorizontalDragStart: (_) => _armEdit(),
              onHorizontalDragUpdate: (details) {
                _moveHatBlock(index, details.delta.dx / _pixelsPerSecond);
              },
              onHorizontalDragEnd: (_) => _finishEdit(),
              onHorizontalDragCancel: _finishEdit,
              child: Container(
                decoration: BoxDecoration(
                  color: block.color,
                  borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                  border: Border.all(
                    color: AppColors.inputBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.face_retouching_natural, size: 14, color: labelColor),
                      const SizedBox(width: 4),
                      Text(
                        'قبعة',
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isSelected) ...[
              _edgeHandle(
                start: true,
                onDrag: (details) => _updateHatBlockStart(index, details.delta.dx / _pixelsPerSecond),
              ),
              _edgeHandle(
                start: false,
                onDrag: (details) => _updateHatBlockEnd(index, details.delta.dx / _pixelsPerSecond),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _glassesChip(bool selected) {
    return Container(
      width: 64,
      height: _paletteChipHeight,
      decoration: BoxDecoration(
        color: selected ? Colors.black87 : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
        border: Border.all(color: selected ? Colors.black : Colors.black26, width: selected ? 2 : 1),
      ),
      child: const Center(
        child: Text(
          'نظارة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildGlassesBlockWidget(int index, StoryGlassesBlock block) {
    final left = block.startTime * _pixelsPerSecond;
    final width = (block.endTime - block.startTime) * _pixelsPerSecond;
    final isSelected = _selectedGlassesBlockIndex == index;
    return Positioned(
      left: left,
      top: _laneBlockTop(isSelected),
      width: width,
      height: _laneBlockHeight(isSelected),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGlassesBlockIndex = index;
            _selectedBlockIndex = null;
            _selectedMotionBlockIndex = null;
            _selectedHatBlockIndex = null;
            _selectedMusclesBlockIndex = null;
            _selectedJumpBlockIndex = null;
            _selectedTransitionIndex = null;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onHorizontalDragStart: (_) => _armEdit(),
              onHorizontalDragUpdate: (details) {
                _moveGlassesBlock(index, details.delta.dx / _pixelsPerSecond);
              },
              onHorizontalDragEnd: (_) => _finishEdit(),
              onHorizontalDragCancel: _finishEdit,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                  border: Border.all(
                    color: AppColors.inputBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'نظارة',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (isSelected) ...[
              _edgeHandle(
                start: true,
                onDrag: (details) => _updateGlassesBlockStart(index, details.delta.dx / _pixelsPerSecond),
              ),
              _edgeHandle(
                start: false,
                onDrag: (details) => _updateGlassesBlockEnd(index, details.delta.dx / _pixelsPerSecond),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _musclesChip(bool selected) {
    return Container(
      width: 64,
      height: _paletteChipHeight,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF145C38) : const Color(0xFF1B7A4E),
        borderRadius: BorderRadius.circular(AppColors.timeline_radius),
        border: Border.all(color: selected ? Colors.black : Colors.black26, width: selected ? 2 : 1),
      ),
      child: const Center(
        child: Text(
          'عضلات',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildMusclesBlockWidget(int index, StoryMusclesBlock block) {
    final left = block.startTime * _pixelsPerSecond;
    final width = (block.endTime - block.startTime) * _pixelsPerSecond;
    final isSelected = _selectedMusclesBlockIndex == index;
    return Positioned(
      left: left,
      top: _laneBlockTop(isSelected),
      width: width,
      height: _laneBlockHeight(isSelected),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMusclesBlockIndex = index;
            _selectedBlockIndex = null;
            _selectedMotionBlockIndex = null;
            _selectedHatBlockIndex = null;
            _selectedGlassesBlockIndex = null;
            _selectedJumpBlockIndex = null;
            _selectedTransitionIndex = null;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onHorizontalDragStart: (_) => _armEdit(),
              onHorizontalDragUpdate: (details) {
                _moveMusclesBlock(index, details.delta.dx / _pixelsPerSecond);
              },
              onHorizontalDragEnd: (_) => _finishEdit(),
              onHorizontalDragCancel: _finishEdit,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1B7A4E),
                  borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                  border: Border.all(
                    color: AppColors.inputBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'عضلات',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (isSelected) ...[
              _edgeHandle(
                start: true,
                onDrag: (details) => _updateMusclesBlockStart(index, details.delta.dx / _pixelsPerSecond),
              ),
              _edgeHandle(
                start: false,
                onDrag: (details) => _updateMusclesBlockEnd(index, details.delta.dx / _pixelsPerSecond),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addJumpBlockAtTime(double timeInSeconds) {
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (totalSeconds == 0) return;
    if (timeInSeconds < 0) timeInSeconds = 0;
    double end = timeInSeconds + 1.2;
    if (end > totalSeconds) end = totalSeconds;
    final updated = <StoryJumpBlock>[];
    for (final block in _jumpBlocks) {
      if (block.endTime <= timeInSeconds || block.startTime >= end) {
        updated.add(block);
      } else if (block.startTime < timeInSeconds && block.endTime > end) {
        updated.add(StoryJumpBlock(startTime: block.startTime, endTime: timeInSeconds));
        updated.add(StoryJumpBlock(startTime: end, endTime: block.endTime));
      } else if (block.startTime < timeInSeconds && block.endTime <= end) {
        updated.add(StoryJumpBlock(startTime: block.startTime, endTime: timeInSeconds));
      } else if (block.startTime >= timeInSeconds && block.endTime > end) {
        updated.add(StoryJumpBlock(startTime: end, endTime: block.endTime));
      }
    }
    updated.add(StoryJumpBlock(startTime: timeInSeconds, endTime: end));
    _armEdit();
    setState(() {
      _jumpBlocks = updated;
      _selectedJumpBlockIndex = _jumpBlocks.indexWhere((block) => block.startTime == timeInSeconds);
      _selectedBlockIndex = null;
      _selectedMotionBlockIndex = null;
      _selectedHatBlockIndex = null;
      _selectedGlassesBlockIndex = null;
      _selectedMusclesBlockIndex = null;
      _selectedTransitionIndex = null;
    });
    _notifyChanged();
    _finishEdit();
  }

  void _moveJumpBlock(int index, double deltaSeconds) {
    if (!_picked(index, _jumpBlocks.length)) return;
    final block = _jumpBlocks[index];
    final duration = block.endTime - block.startTime;
    var newStart = block.startTime + deltaSeconds;
    if (newStart < 0) newStart = 0;
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newStart + duration > totalSeconds) newStart = totalSeconds - duration;
    if (index > 0 && newStart < _jumpBlocks[index - 1].endTime) {
      newStart = _jumpBlocks[index - 1].endTime;
    }
    if (index < _jumpBlocks.length - 1 && (newStart + duration) > _jumpBlocks[index + 1].startTime) {
      newStart = _jumpBlocks[index + 1].startTime - duration;
    }
    setState(() {
      _jumpBlocks[index] = StoryJumpBlock(startTime: newStart, endTime: newStart + duration);
    });
    _notifyChanged();
  }

  void _updateJumpBlockStart(int index, double deltaSeconds) {
    if (!_picked(index, _jumpBlocks.length)) return;
    final block = _jumpBlocks[index];
    var newStart = block.startTime + deltaSeconds;
    if (newStart < 0) newStart = 0;
    if (newStart > block.endTime - 0.4) newStart = block.endTime - 0.4;
    if (index > 0 && newStart < _jumpBlocks[index - 1].endTime) {
      newStart = _jumpBlocks[index - 1].endTime;
    }
    setState(() {
      _jumpBlocks[index] = StoryJumpBlock(startTime: newStart, endTime: block.endTime);
    });
    _notifyChanged();
  }

  void _updateJumpBlockEnd(int index, double deltaSeconds) {
    if (!_picked(index, _jumpBlocks.length)) return;
    final block = _jumpBlocks[index];
    var newEnd = block.endTime + deltaSeconds;
    final totalSeconds = _totalDuration.inMilliseconds / 1000.0;
    if (newEnd > totalSeconds) newEnd = totalSeconds;
    if (newEnd < block.startTime + 0.4) newEnd = block.startTime + 0.4;
    if (index < _jumpBlocks.length - 1 && newEnd > _jumpBlocks[index + 1].startTime) {
      newEnd = _jumpBlocks[index + 1].startTime;
    }
    setState(() {
      _jumpBlocks[index] = StoryJumpBlock(startTime: block.startTime, endTime: newEnd);
    });
    _notifyChanged();
  }

  Widget _buildJumpBlockWidget(int index, StoryJumpBlock block) {
    final left = block.startTime * _pixelsPerSecond;
    final width = (block.endTime - block.startTime) * _pixelsPerSecond;
    final isSelected = _selectedJumpBlockIndex == index;
    return Positioned(
      left: left,
      top: _laneBlockTop(isSelected),
      width: width,
      height: _laneBlockHeight(isSelected),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedJumpBlockIndex = index;
            _selectedBlockIndex = null;
            _selectedMotionBlockIndex = null;
            _selectedHatBlockIndex = null;
            _selectedGlassesBlockIndex = null;
            _selectedMusclesBlockIndex = null;
            _selectedTransitionIndex = null;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onHorizontalDragStart: (_) => _armEdit(),
              onHorizontalDragUpdate: (details) {
                _moveJumpBlock(index, details.delta.dx / _pixelsPerSecond);
              },
              onHorizontalDragEnd: (_) => _finishEdit(),
              onHorizontalDragCancel: _finishEdit,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                  border: Border.all(
                    color: AppColors.inputBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'نطة',
                    style: TextStyle(color: AppColors.onPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (isSelected) ...[
              _edgeHandle(
                start: true,
                onDrag: (details) => _updateJumpBlockStart(index, details.delta.dx / _pixelsPerSecond),
              ),
              _edgeHandle(
                start: false,
                onDrag: (details) => _updateJumpBlockEnd(index, details.delta.dx / _pixelsPerSecond),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineHistory {
  final List<StoryBlock> blocks;
  final List<StoryMotionBlock> motionBlocks;
  final List<StoryHatBlock> hatBlocks;
  final List<StoryGlassesBlock> glassesBlocks;
  final List<StoryMusclesBlock> musclesBlocks;
  final List<StoryJumpBlock> jumpBlocks;
  final List<StoryTransition> transitions;

  const _TimelineHistory({
    required this.blocks,
    required this.motionBlocks,
    required this.hatBlocks,
    required this.glassesBlocks,
    required this.musclesBlocks,
    required this.jumpBlocks,
    required this.transitions,
  });

  factory _TimelineHistory.capture(_StoryTimelineEditorState state) {
    return _TimelineHistory(
      blocks: List<StoryBlock>.of(state._blocks),
      motionBlocks: List<StoryMotionBlock>.of(state._motionBlocks),
      hatBlocks: List<StoryHatBlock>.of(state._hatBlocks),
      glassesBlocks: List<StoryGlassesBlock>.of(state._glassesBlocks),
      musclesBlocks: List<StoryMusclesBlock>.of(state._musclesBlocks),
      jumpBlocks: List<StoryJumpBlock>.of(state._jumpBlocks),
      transitions: List<StoryTransition>.of(state._transitions),
    );
  }
}

class _EffectSheet extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onAdd;

  const _EffectSheet({required this.initial, required this.onAdd});

  @override
  State<_EffectSheet> createState() => _EffectSheetState();
}

class _EffectSheetState extends State<_EffectSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'التأثيرات',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          for (final type in StoryTransition.types)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: _selected == type ? AppColors.secondary : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                  side: const BorderSide(color: AppColors.inputBorder),
                ),
                child: InkWell(
                  onTap: () => setState(() => _selected = type),
                  borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: Text(
                        StoryTransition.label(type),
                        style: TextStyle(
                          color: _selected == type ? Colors.white : AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppColors.timeline_radius),
            child: InkWell(
              onTap: () => widget.onAdd(_selected),
              borderRadius: BorderRadius.circular(AppColors.timeline_radius),
              child: const SizedBox(
                height: 46,
                child: Center(
                  child: Text(
                    'إضافة',
                    style: TextStyle(color: AppColors.onPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteLane extends StatefulWidget {
  final String title;
  final List<Widget> children;

  final bool labeled;

  const _PaletteLane({
    super.key,
    required this.title,
    required this.children,
    this.labeled = true,
  });

  @override
  State<_PaletteLane> createState() => _PaletteLaneState();
}

class _PaletteLaneState extends State<_PaletteLane> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dragBy(double dx, double width) {
    if (!_controller.hasClients || width <= 0) return;
    final max = _controller.position.maxScrollExtent;
    if (max <= 0) return;
    final sign = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final next = _controller.offset + sign * dx * (max / width);
    _controller.jumpTo(next.clamp(0.0, max));
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final max = _controller.hasClients ? _controller.position.maxScrollExtent : 0.0;
    final offset = _controller.hasClients ? _controller.offset : 0.0;
    final t = max <= 0 ? 0.0 : (offset / max).clamp(0.0, 1.0);
    final thumbX = rtl ? 1 - 2 * t : -1 + 2 * t;

    return SizedBox(
      height: 52,
      child: Row(
        children: [
          if (widget.labeled)
          SizedBox(
            width: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'اسحب للمسار',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
              ],
            ),
          ),
          if (widget.labeled)
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.inputBorder),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    children: widget.children,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 2),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (details) {
                          _dragBy(details.delta.dx, constraints.maxWidth);
                        },
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: Align(
                            alignment: Alignment(thumbX, 0),
                            child: Container(
                              width: 28,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppColors.timeline_radius),
                                border: Border.all(color: const Color(0xFF94A3B8)),
                              ),
                              child: const Icon(Icons.drag_handle, size: 12, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double duration;
  final int seed;

  _WaveformPainter({required this.duration, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final random = Random(seed);
    final int points = (size.width / 4).floor(); // 1 line every 4 pixels

    for (int i = 0; i < points; i++) {
      final x = i * 4.0;
      // Add a slight envelope based on sine wave to make it look like speech
      final envelope = (sin(i / points * pi * 8) + 1.0) / 2.0; 
      final noise = random.nextDouble();
      
      final magnitude = (noise * 0.8 + 0.2) * envelope * size.height;
      final y1 = (size.height - magnitude) / 2;
      final y2 = y1 + magnitude;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
