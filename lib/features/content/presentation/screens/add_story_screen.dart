import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/built_in_habit_audio.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/user_message.dart';
import '../../../content/domain/entities/mission_entity.dart';
import '../../../content/domain/entities/story_entity.dart';
import '../../../content/presentation/bloc/content_bloc.dart';
import '../../../content/presentation/bloc/content_event.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:convert';
import '../../../content/presentation/bloc/content_state.dart';
import '../../../../core/utils/character_helper.dart';
import '../../../../core/models/story_timeline.dart';
import '../../../../core/widgets/story_timeline_editor.dart';
import '../../../../core/audio/story_sentence_voice.dart';
import '../../../../core/services/resource_manager.dart';
import '../../../../core/widgets/admin_voice_field.dart';
import '../../../../core/montage/montage_gemini.dart';
import '../../../../core/montage/montage_plan.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../data/models/custom_character_model.dart';
import '../../data/repositories/custom_character_repository.dart';

class _SentenceLine {
  _SentenceLine() {
    controller.addListener(_onText);
  }

  final controller = TextEditingController();
  String characterId = 'fort';
  String spokenText = '';
  File? audio;
  double seconds = 0;
  bool busy = false;

  void _onText() {
    if (audio != null && controller.text.trim() != spokenText) {
      audio = null;
      seconds = 0;
      spokenText = '';
    }
  }

  void dispose() => controller.dispose();
}

const _sceneCharacters = <(String, String)>[
  ('fort', 'فورت'),
  ('sort', 'سورت'),
  ('lort', 'لورت'),
  ('mort', 'مورت'),
  ('port', 'بورت'),
  ('qort', 'كورت'),
];

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
  final _scriptController = TextEditingController();

  File? _audioFile;
  StoryTimeline? _timeline;
  late ContentBloc _contentBloc;

  AudioPlayer? _audioPlayer;
  AudioPlayer? _linePlayer;
  bool _isPlaying = false;
  int _step = 0;
  bool _joining = false;
  bool _scriptBusy = false;
  bool _preparingEdit = false;
  bool _audioRebuilt = false;
  bool _montageBusy = false;
  int _appliedMontage = 0;
  String _montageCacheKey = '';
  Map<String, dynamic>? _montageCache;
  String? _sceneSignature;
  String _savedSceneKey = '';
  final List<_SentenceLine> _lines = [];
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier(Duration.zero);
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;

  List<CustomCharacterModel> _customCharacters = [];
  bool _isOpeningCharacterSheet = false;
  String _previousScriptText = '';

  void _loadCustomCharacters() {
    try {
      final repo = sl<CustomCharacterRepository>();
      _customCharacters = repo.getCachedCharacters();
      repo.fetchCharacters().then((list) {
        if (mounted) {
          setState(() {
            _customCharacters = list;
          });
        }
      }).catchError((_) {});
    } catch (_) {}
  }

  void _onScriptChanged() {
    if (!mounted) return;
    setState(() {});
    if (_isOpeningCharacterSheet) return;

    final text = _scriptController.text;
    final selection = _scriptController.selection;
    if (text.length > _previousScriptText.length && selection.isValid && selection.isCollapsed) {
      final cursor = selection.baseOffset;
      if (cursor > 0 && text[cursor - 1] == '/') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openCharacterPickerBottomSheet(isAutoSlash: true);
        });
      }
    }
    _previousScriptText = text;
  }

  @override
  void initState() {
    super.initState();
    _contentBloc = sl<ContentBloc>();
    _loadCustomCharacters();
    _previousScriptText = _scriptController.text;
    _scriptController.addListener(_onScriptChanged);
    final story = widget.storyToEdit;
    if (story == null) return;
    _titleController.text = story.title;
    _contentController.text = story.content;
    if (story.timelineData != null) {
      try {
        _timeline = StoryTimeline.fromJson(jsonDecode(story.timelineData!));
      } catch (_) {}
    }
    _hydrateLines(story);
    _scriptController.text = _scriptFromLines(_lines);
    _previousScriptText = _scriptController.text;
    final url = story.audioUrl?.trim() ?? '';
    if (url.isNotEmpty || BuiltInHabitAudio.assetForSource(story.id, url) != null) {
      _preparingEdit = true;
      unawaited(_loadExistingAudio(url));
    }
  }

  void _hydrateLines(StoryEntity story) {
    final texts = story.content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final blocks = _timeline?.blocks ?? const <StoryBlock>[];
    for (var i = 0; i < texts.length; i++) {
      final line = _SentenceLine();
      line.controller.text = texts[i];
      final fromBlock = i < blocks.length ? blocks[i].characterId : '';
      if (_sceneCharacters.any((character) => character.$1 == fromBlock) || fromBlock.startsWith('custom|')) {
        line.characterId = fromBlock;
      } else if (_sceneCharacters.any(
        (character) => character.$1 == story.characterName,
      ) || story.characterName.startsWith('custom|')) {
        line.characterId = story.characterName;
      }
      line.controller.addListener(() {
        if (mounted) setState(() {});
      });
      _lines.add(line);
    }
    _savedSceneKey = _sceneKey(_lines);
  }

  String _sceneKey(List<_SentenceLine> lines) {
    return lines
        .map((line) => '${line.characterId}|${line.controller.text.trim()}')
        .join('\n');
  }

  Future<void> _loadExistingAudio(String url) async {
    try {
      final bundled = BuiltInHabitAudio.assetForSource(widget.storyToEdit!.id, url);
      if (bundled != null) {
        final bytes = await rootBundle.load('assets/$bundled');
        final directory = await getTemporaryDirectory();
        final extension = bundled.substring(bundled.lastIndexOf('.'));
        final file = File('${directory.path}/${widget.storyToEdit!.id}_launch$extension');
        await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);
        if (!mounted) return;
        _audioFile = file;
        await _initAudio(DeviceFileSource(file.path));
        return;
      }
      final resources = sl<ResourceManager>();
      final path = resources.getLocalFilePath(url) ??
          await resources.downloadAndCacheFile(url, folder: 'audio');
      if (!mounted) return;
      if (path != null && File(path).existsSync()) {
        _audioFile = File(path);
        await _initAudio(DeviceFileSource(path));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('صوت القصة المحفوظ مش موجود على الجهاز. ولّد الجمل من جديد.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ما قدرنا نفتح صوت القصة المحفوظ. ${StorySentenceVoice.explain(error)}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _preparingEdit = false;
          if (_audioFile != null) _step = 1;
        });
      }
    }
  }

  StoryTimeline _keepLanes(List<StoryBlock> blocks, double seconds) {
    final previous = _timeline;
    double fit(double start, double end) {
      final capped = end > seconds ? seconds : end;
      return capped > start ? capped : start;
    }

    return StoryTimeline(
      blocks: blocks,
      totalDuration: seconds,
      motionBlocks: [
        for (final block in previous?.motionBlocks ?? const <StoryMotionBlock>[])
          if (block.startTime < seconds)
            StoryMotionBlock(
              motionId: block.motionId,
              startTime: block.startTime,
              endTime: fit(block.startTime, block.endTime),
            ),
      ].where((block) => block.endTime > block.startTime).toList(),
      hatBlocks: [
        for (final block in previous?.hatBlocks ?? const <StoryHatBlock>[])
          if (block.startTime < seconds)
            StoryHatBlock(
              colorHex: block.colorHex,
              startTime: block.startTime,
              endTime: fit(block.startTime, block.endTime),
            ),
      ].where((block) => block.endTime > block.startTime).toList(),
      glassesBlocks: [
        for (final block in previous?.glassesBlocks ?? const <StoryGlassesBlock>[])
          if (block.startTime < seconds)
            StoryGlassesBlock(
              startTime: block.startTime,
              endTime: fit(block.startTime, block.endTime),
            ),
      ].where((block) => block.endTime > block.startTime).toList(),
      musclesBlocks: [
        for (final block in previous?.musclesBlocks ?? const <StoryMusclesBlock>[])
          if (block.startTime < seconds)
            StoryMusclesBlock(
              startTime: block.startTime,
              endTime: fit(block.startTime, block.endTime),
            ),
      ].where((block) => block.endTime > block.startTime).toList(),
      jumpBlocks: [
        for (final block in previous?.jumpBlocks ?? const <StoryJumpBlock>[])
          if (block.startTime < seconds)
            StoryJumpBlock(
              startTime: block.startTime,
              endTime: fit(block.startTime, block.endTime),
            ),
      ].where((block) => block.endTime > block.startTime).toList(),
      transitions: [
        for (final item in previous?.transitions ?? const <StoryTransition>[])
          if (item.time < seconds) item,
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scriptController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    _contentBloc.close();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer?.dispose();
    _linePlayer?.dispose();
    _positionNotifier.dispose();
    super.dispose();
  }

  Future<void> _initAudio(Source source) async {
    _audioPlayer?.dispose();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();

    _audioPlayer = AudioPlayer();

    _playerStateSubscription = _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
        if (!_isPlaying && state == PlayerState.completed) {
          _positionNotifier.value = Duration.zero;
        }
      }
    });

    _positionSubscription = _audioPlayer!.onPositionChanged.listen((position) {
      if (mounted) {
        _positionNotifier.value = position;
      }
    });

    await _audioPlayer!.setReleaseMode(ReleaseMode.stop);
    await _audioPlayer!.setSource(source);
    setState(() {
      _isPlaying = false;
      _positionNotifier.value = Duration.zero;
    });
  }

  void _togglePlayPause() async {
    if (_audioPlayer == null) return;
    if (_isPlaying) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.resume();
    }
  }

  String _scriptFromLines(List<_SentenceLine> lines) {
    return lines
        .where((line) => line.controller.text.trim().isNotEmpty)
        .map((line) => '${line.controller.text.trim()} /${_characterName(line.characterId)}')
        .join('\n');
  }

  String _characterName(String characterId) {
    if (characterId.startsWith('custom|')) {
      final parts = characterId.split('|');
      if (parts.length >= 3 && parts[2].trim().isNotEmpty) return parts[2].trim();
      final c = sl<CustomCharacterRepository>().getCharacterById(parts.length > 1 ? parts[1] : '');
      if (c != null) return c.name;
    }
    for (final character in _sceneCharacters) {
      if (character.$1 == characterId) return character.$2;
    }
    return 'كورت';
  }

  String? _characterId(String name) {
    final cleaned = name.trim();
    for (final character in _sceneCharacters) {
      if (character.$2 == cleaned || character.$1 == cleaned) return character.$1;
    }
    for (final c in _customCharacters) {
      if (c.name.trim() == cleaned || c.id == cleaned) {
        return 'custom|${c.id}|${c.name}';
      }
    }
    try {
      final cached = sl<CustomCharacterRepository>().getCachedCharacters();
      for (final c in cached) {
        if (c.name.trim() == cleaned || c.id == cleaned) {
          return 'custom|${c.id}|${c.name}';
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _openCharacterPickerBottomSheet({bool isAutoSlash = false}) async {
    if (_isOpeningCharacterSheet) return;
    _isOpeningCharacterSheet = true;
    _loadCustomCharacters();

    final selectedName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(top: false, child: _CharacterPickerSheet(
          customCharacters: _customCharacters,
          onOpenCreator: () async {
            Navigator.pop(sheetContext);
            await context.push('/custom-character-creator');
            _loadCustomCharacters();
          },
          onEditCharacter: (character) async {
            Navigator.pop(sheetContext);
            await context.push('/custom-character-creator', extra: character);
            _loadCustomCharacters();
          },
        ));
      },
    );

    _isOpeningCharacterSheet = false;

    if (selectedName != null && mounted) {
      _insertCharacterTag(selectedName, hadSlashAlready: isAutoSlash);
    }
  }

  void _insertCharacterTag(String characterName, {required bool hadSlashAlready}) {
    final text = _scriptController.text;
    final selection = _scriptController.selection;
    final cursor = selection.isValid ? selection.baseOffset : text.length;

    String before;
    String after;

    if (hadSlashAlready) {
      if (cursor > 0 && text[cursor - 1] == '/') {
        before = '${text.substring(0, cursor)}$characterName\n';
        after = text.substring(cursor);
      } else {
        before = '${text.substring(0, cursor)}/$characterName\n';
        after = text.substring(cursor);
      }
    } else {
      final space = (cursor > 0 && text[cursor - 1] != ' ' && text[cursor - 1] != '\n') ? ' ' : '';
      before = '${text.substring(0, cursor)}$space/$characterName\n';
      after = text.substring(cursor);
    }

    final newText = before + after;
    _previousScriptText = newText;
    _scriptController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: before.length),
    );
  }

  List<({String text, String characterId})>? _parseScript(String raw) {
    final pieces = <({String text, String characterId})>[];
    final pattern = RegExp(r'([^/\n]+?)\s*/\s*([^\n\r]+)');
    final lines = raw.split('\n');
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index].trim();
      if (line.isEmpty) continue;
      final matches = pattern.allMatches(line).toList();
      if (matches.isEmpty) {
        _scriptError('السطر ${index + 1} يحتاج / واسم الشخصية في آخره');
        return null;
      }
      var consumed = 0;
      for (final match in matches) {
        final spoken = match.group(1)!.trim();
        final name = match.group(2)!.replaceAll(RegExp(r'[.،,!！?؟:]+$'), '').trim();
        final characterId = _characterId(name);
        if (spoken.isEmpty || characterId == null) {
          _scriptError('السطر ${index + 1}: الشخصية «$name» غير معروفة');
          return null;
        }
        pieces.add((text: spoken, characterId: characterId));
        consumed = match.end;
      }
      if (line.substring(consumed).trim().isNotEmpty) {
        _scriptError('السطر ${index + 1} فيه كلام بعد اسم الشخصية');
        return null;
      }
    }
    if (pieces.isEmpty) {
      _scriptError('اكتب جملة واحدة على الأقل في الوصف');
      return null;
    }
    return pieces;
  }

  void _scriptError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  _SentenceLine _makeLine(String text, String characterId) {
    final line = _SentenceLine();
    line.controller.text = text;
    line.characterId = characterId;
    line.controller.addListener(() {
      if (mounted) setState(() {});
    });
    return line;
  }

  bool get _scriptReady {
    final pieces = _parseScriptQuiet(_scriptController.text);
    if (pieces == null) return false;
    final ready = _lines.where((line) => line.controller.text.trim().isNotEmpty).toList();
    if (ready.length != pieces.length) return false;
    for (var index = 0; index < pieces.length; index++) {
      final line = ready[index];
      final piece = pieces[index];
      if (line.audio == null || line.spokenText != piece.text || line.characterId != piece.characterId) {
        return false;
      }
    }
    return true;
  }

  List<({String text, String characterId})>? _parseScriptQuiet(String raw) {
    final pieces = <({String text, String characterId})>[];
    final pattern = RegExp(r'([^/\n]+?)\s*/\s*([^\n\r]+)');
    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final matches = pattern.allMatches(line).toList();
      if (matches.isEmpty) return null;
      var consumed = 0;
      for (final match in matches) {
        final spoken = match.group(1)!.trim();
        final name = match.group(2)!.replaceAll(RegExp(r'[.،,!！?؟:]+$'), '').trim();
        final characterId = _characterId(name);
        if (spoken.isEmpty || characterId == null) return null;
        pieces.add((text: spoken, characterId: characterId));
        consumed = match.end;
      }
      if (line.substring(consumed).trim().isNotEmpty) return null;
    }
    if (pieces.isEmpty) return null;
    return pieces;
  }

  Future<void> _speakScript() async {
    if (_scriptBusy) return;
    final pieces = _parseScript(_scriptController.text);
    if (pieces == null) return;
    final ready = _lines.where((line) => line.controller.text.trim().isNotEmpty).toList();
    final same = ready.length == pieces.length &&
        List.generate(pieces.length, (index) {
          final line = ready[index];
          return line.audio != null &&
              line.spokenText == pieces[index].text &&
              line.characterId == pieces[index].characterId;
        }).every((matches) => matches);
    if (same) {
      await _playLines(ready);
      return;
    }

    setState(() => _scriptBusy = true);
    final next = <_SentenceLine>[];
    try {
      for (final piece in pieces) {
        final clip = await StorySentenceVoice.speak(
          characterId: piece.characterId,
          text: piece.text,
        );
        final line = _makeLine(piece.text, piece.characterId);
        line.audio = clip.file;
        line.seconds = clip.seconds;
        line.spokenText = piece.text;
        next.add(line);
      }
      if (!mounted) {
        for (final line in next) {
          line.dispose();
        }
        return;
      }
      final previous = List<_SentenceLine>.of(_lines);
      setState(() {
        _lines
          ..clear()
          ..addAll(next);
        _scriptBusy = false;
      });
      for (final line in previous) {
        line.dispose();
      }
      next.clear();
      await _playLines(_lines);
    } catch (error) {
      for (final line in next) {
        line.dispose();
      }
      if (!mounted) return;
      setState(() => _scriptBusy = false);
      _scriptError(StorySentenceVoice.explain(error));
    }
  }

  Future<void> _playLines(List<_SentenceLine> lines) async {
    _linePlayer ??= AudioPlayer();
    for (final line in lines) {
      final file = line.audio;
      if (file == null || !mounted) return;
      await _linePlayer!.stop();
      await _linePlayer!.play(DeviceFileSource(file.path));
      await _linePlayer!.onPlayerComplete.first;
    }
  }

  void _addLine() {
    final line = _SentenceLine();
    line.controller.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() => _lines.add(line));
  }

  Future<void> _playLine(File file) async {
    _linePlayer ??= AudioPlayer();
    await _linePlayer!.stop();
    await _linePlayer!.setVolume(1);
    await _linePlayer!.play(DeviceFileSource(file.path));
  }

  Future<void> _speakLine(_SentenceLine line) async {
    final text = line.controller.text.trim();
    if (text.isEmpty || line.busy) return;
    if (line.audio != null && line.spokenText == text) {
      await _playLine(line.audio!);
      return;
    }
    setState(() => line.busy = true);
    try {
      final clip = await StorySentenceVoice.speak(
        characterId: line.characterId,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        line.audio = clip.file;
        line.seconds = clip.seconds;
        line.spokenText = text;
        line.busy = false;
      });
      await _playLine(clip.file);
    } catch (error) {
      if (!mounted) return;
      setState(() => line.busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(StorySentenceVoice.explain(error))),
      );
    }
  }

  Future<void> _openTimeline() async {
    if (_joining) return;
    final ready = _lines.where((line) => line.controller.text.trim().isNotEmpty).toList();
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب عنوان القصة أولاً')),
      );
      return;
    }
    if (ready.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف جملة واحدة على الأقل')),
      );
      return;
    }

    final sceneKey = _sceneKey(ready);
    final sameScene = _audioFile != null &&
        _timeline != null &&
        (sceneKey == _sceneSignature ||
            (!_audioRebuilt && sceneKey == _savedSceneKey && _savedSceneKey.isNotEmpty));
    if (sameScene) {
      _contentController.text = ready.map((line) => line.controller.text.trim()).join('\n');
      setState(() => _step = 1);
      return;
    }

    if (ready.any((line) => line.audio == null || line.seconds <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ولّد صوت كل جملة قبل التالي')),
      );
      return;
    }

    setState(() => _joining = true);
    try {
      final merged = await StorySentenceVoice.join(ready.map((line) => line.audio!).toList());
      final spoken = ready.fold<double>(0, (sum, line) => sum + line.seconds);
      final scale = spoken > 0 ? merged.seconds / spoken : 1.0;
      var cursor = 0.0;
      final blocks = <StoryBlock>[];
      for (final line in ready) {
        final end = cursor + (line.seconds * scale);
        blocks.add(
          StoryBlock(
            characterId: line.characterId,
            startTime: cursor,
            endTime: end,
          ),
        );
        cursor = end;
      }
      if (blocks.isNotEmpty) {
        final last = blocks.last;
        blocks[blocks.length - 1] = StoryBlock(
          characterId: last.characterId,
          startTime: last.startTime,
          endTime: merged.seconds,
        );
      }
      _contentController.text = ready.map((line) => line.controller.text.trim()).join('\n');
      _timeline = _keepLanes(blocks, merged.seconds);
      _audioFile = merged.file;
      _audioRebuilt = true;
      _sceneSignature = sceneKey;
      await _initAudio(DeviceFileSource(merged.file.path));
      if (!mounted) return;
      setState(() => _step = 1);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ما قدرنا نجمع الجمل في مشهد. ${StorySentenceVoice.explain(error)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Widget _sentenceRow(_SentenceLine line, int index) {
    final ready = line.audio != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: line.controller,
            maxLines: 2,
            decoration: InputDecoration(hintText: 'الجملة ${index + 1}'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: line.characterId,
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    for (final character in _sceneCharacters)
                      DropdownMenuItem(
                        value: character.$1,
                        child: Text(
                          character.$2,
                          style: TextStyle(
                            color: CharacterHelper.getColor(character.$1),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    for (final custom in _customCharacters)
                      DropdownMenuItem(
                        value: 'custom|${custom.id}|${custom.name}',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: custom.bodyColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              custom.name,
                              style: TextStyle(
                                color: custom.bodyColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (line.characterId.startsWith('custom|') &&
                        !_customCharacters.any((c) => 'custom|${c.id}|${c.name}' == line.characterId))
                      DropdownMenuItem(
                        value: line.characterId,
                        child: Text(
                          _characterName(line.characterId),
                          style: TextStyle(
                            color: CharacterHelper.getColor(line.characterId),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                  onChanged: line.busy
                      ? null
                      : (value) {
                          if (value == null || value == line.characterId) return;
                          setState(() {
                            line.characterId = value;
                            line.audio = null;
                            line.seconds = 0;
                            line.spokenText = '';
                          });
                        },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: line.busy ? null : () => _speakLine(line),
                child: line.busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(ready ? 'اسمع' : 'اعمل الصوت'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      String charName = 'qort';

      if (_timeline != null && _timeline!.blocks.isNotEmpty) {
        charName = _timeline!.blocks.first.characterId;
      } else if (widget.storyToEdit != null && widget.storyToEdit!.characterName.isNotEmpty) {
        charName = widget.storyToEdit!.characterName;
      }

      final story = StoryEntity(
        id: widget.storyToEdit?.id ?? '',
        missionId: widget.mission.id,
        title: _titleController.text.trim(),
        characterName: charName,
        content: _contentController.text.trim(),
        imageUrl: widget.storyToEdit?.imageUrl ?? '',
        audioUrl: widget.storyToEdit?.audioUrl,
        orderIndex: widget.storyToEdit?.orderIndex ?? 0,
        timelineData: _timeline != null ? jsonEncode(_timeline!.toJson()) : null,
      );
      final audioFile = widget.storyToEdit == null || _audioRebuilt ? _audioFile : null;
      if (widget.storyToEdit != null) {
        _contentBloc.add(
          ContentEvent.updateStory(
            story,
            audioFile: audioFile,
          ),
        );
      } else {
        _contentBloc.add(
          ContentEvent.addStory(
            story,
            audioFile: audioFile,
          ),
        );
      }
    }
  }

  bool _retryMontage(String code) {
    return code == 'gemini_failed' ||
        code == 'bad_response' ||
        code == 'timeout' ||
        code == 'request_failed';
  }

  Future<Map<String, dynamic>> _loadMontagePlan(List<Map<String, dynamic>> sentences) async {
    MontageGeminiException? last;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await MontageGemini().plan(sentences);
      } on MontageGeminiException catch (error) {
        last = error;
        if (!_retryMontage(error.code) || attempt == 1) throw error;
      }
      await Future.delayed(Duration(milliseconds: 900 * (attempt + 1)));
    }
    throw last ?? const MontageGeminiException('request_failed');
  }

  String _montageMessage(MontageGeminiException error) {
    final base = switch (error.code) {
      'signed_out' => 'سجّل الدخول أولاً ثم أعد تحليل المونتاج.',
      'missing_key' => 'مفتاح الموديل ناقص أو مرفوض. حطه من إعدادات الأدمن.',
      'empty_script' => 'اكتب نص المشهد أولاً.',
      'jwt' => 'جلسة الدخول انتهت. سجّل الدخول من جديد ثم أعد المحاولة.',
      'quota' => 'خلص رصيد هذا الموديل. بدّله من إعدادات الأدمن.',
      'unavailable' => 'الموديل المختار مش متاح. بدّله من إعدادات الأدمن.',
      'timeout' => 'الموديل تأخر بالرد. اضغط الأيقونة مرة ثانية.',
      'bad_response' => 'الموديل رد، بس الرد ما فيه حركات نقدر نستخدمها.',
      'gemini_failed' => 'الموديل رفض الطلب.',
      'request_failed' => 'الطلب ما وصل للموديل.',
      _ => 'تحليل المونتاج وقف قبل ما يخلص.',
    };
    final detail = error.detail.trim();
    if (detail.isEmpty) return base;
    return '$base $detail';
  }

  String _plainProblem(Object error) {
    if (error is TimeoutException) return 'الطلب تأخر أكثر من اللازم.';
    if (error is SocketException) return 'ما في نت، فما وصل الطلب.';
    if (error is FormatException) return 'الرد وصل بنص مش مفهوم.';
    if (error is FileSystemException) return 'ما قدرنا نقرأ ملف الصوت من الجهاز.';
    return 'صار خطأ غير متوقع.';
  }

  void _montageSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  bool _montageLanesFilled(StoryTimeline timeline) {
    return timeline.motionBlocks.isNotEmpty ||
        timeline.jumpBlocks.isNotEmpty ||
        timeline.hatBlocks.isNotEmpty ||
        timeline.glassesBlocks.isNotEmpty ||
        timeline.musclesBlocks.isNotEmpty ||
        timeline.transitions.isNotEmpty;
  }

  Future<void> _analyzeMontage() async {
    if (_montageBusy) return;
    final timeline = _timeline;
    if (timeline == null || timeline.blocks.isEmpty) {
      _montageSnack('جهّز المونتاج أولاً');
      return;
    }
    final ready = _lines.where((line) => line.controller.text.trim().isNotEmpty).toList();
    if (ready.isEmpty) {
      _montageSnack('أضف جملة واحدة على الأقل');
      return;
    }
    if (ready.length != timeline.blocks.length) {
      _montageSnack('عدد الجمل ما يطابق الشخصيات. ولّد الصوت وافتح المونتاج من جديد.');
      return;
    }
    final count = ready.length;
    if (_montageLanesFilled(timeline)) {
      final replace = await showAppSheet<bool>(
        context: context,
        heightFactor: 0.34,
        builder: (sheetContext) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'استبدال المونتاج',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text('الذكاء يقرأ معنى الكلمات ويستبدل الحركة والنطة والقبعة والنظارة والعضلات والتأثير. بلوكات الشخصيات تبقى.'),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  child: const Text('استبدال'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          );
        },
      );
      if (replace != true || !mounted) return;
    }

    final sentences = <MontageSentence>[
      for (var i = 0; i < count; i++)
        MontageSentence(
          text: ready[i].controller.text.trim(),
          characterName: _characterName(ready[i].characterId),
          start: timeline.blocks[i].startTime,
          end: timeline.blocks[i].endTime,
        ),
    ];
    setState(() => _montageBusy = true);
    try {
      final key = '2\n${sentences.map((sentence) => '${sentence.characterName}|${sentence.text}').join('\n')}';
      final Map<String, dynamic> plan;
      if (_montageCacheKey == key && _montageCache != null) {
        plan = _montageCache!;
      } else {
        plan = await _loadMontagePlan(montageRequestSentences(sentences));
      }
      if (!mounted) return;
      final apply = placeMontage(
        characters: timeline.blocks,
        sentences: sentences,
        plan: plan,
        totalDuration: timeline.totalDuration,
      );
      if (apply.placed == 0) {
        _montageCacheKey = '';
        _montageCache = null;
        _montageSnack('ما لقى كلمة معناها يستاهل حركة');
        return;
      }
      _montageCacheKey = key;
      _montageCache = plan;
      setState(() {
        _timeline = apply.timeline;
        _appliedMontage++;
      });
      _montageSnack(
        apply.missed == 0
            ? 'حط الحركة على معنى الكلمات'
            : 'حط الحركة، وترك ${apply.missed} كلمة ما لقاها في النص',
      );
    } on MontageGeminiException catch (error) {
      if (!mounted) return;
      _montageSnack(_montageMessage(error));
    } catch (error) {
      if (!mounted) return;
      _montageSnack('تحليل المونتاج وقف. ${_plainProblem(error)}');
    } finally {
      if (mounted) setState(() => _montageBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.storyToEdit != null;
    return BlocProvider.value(
      value: _contentBloc,
      child: Stack(
        children: [
      Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          leading: _step == 1
              ? TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('رجوع'),
                )
              : null,
          title: Text(
            _step == 1
                ? 'المونتاج'
                : editing
                    ? 'تعديل القصة'
                    : 'كتابة المشهد',
          ),
          elevation: 0,
          surfaceTintColor: Colors.white,
          actions: [
            if (_step == 1)
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _montageBusy ? null : _analyzeMontage,
                child: const Text('تحليل المعنى'),
              ),
          ],
        ),
        body: BlocConsumer<ContentBloc, ContentState>(
          listener: (context, state) {
            state.maybeWhen(
              storyAdded: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت إضافة القصة بنجاح!')),
                );
                context.pop(true);
              },
              storiesLoaded: (_) {
                if (editing) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تحديث القصة بنجاح!')),
                  );
                  context.pop(true);
                }
              },
              error: (msg) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(userMessage(msg))));
              },
              orElse: () {},
            );
          },
          builder: (context, state) {
            final isLoading = _joining ||
                _scriptBusy ||
                _preparingEdit ||
                state.maybeWhen(
                  loading: () => true,
                  orElse: () => false,
                );

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: _preparingEdit
                            ? const ShimmerLoading(type: ShimmerType.form, itemCount: 4)
                            : ListView(
                                children: [
                                  if (_step == 0) ...[
                                    AdminVoiceField(
                                      controller: _titleController,
                                      hint: 'عنوان القصة',
                                      beside: FilledButton.tonal(
                                        onPressed: _addLine,
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          minimumSize: const Size(0, 36),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('إضافة جملة'),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _scriptController,
                                            minLines: 4,
                                            maxLines: 8,
                                            decoration: InputDecoration(
                                              hintText: 'الوصف. كل جملة تنتهي بـ /اسم_الشخصية\nمثال: في يوم من الأيام كان الأصدقاء يلعبون /سورت',
                                              alignLabelWithHint: true,
                                              suffixIcon: TextButton(
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  minimumSize: const Size(0, 36),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                onPressed: () => _openCharacterPickerBottomSheet(isAutoSlash: false),
                                                child: const Text(
                                                  'شخصية',
                                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton.tonal(
                                          onPressed: _scriptBusy ? null : _speakScript,
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                          ),
                                          child: _scriptBusy
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                )
                                              : Text(_scriptReady ? 'اسمع' : 'اعمل الصوت'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        ActionChip(
                                          label: const Text(
                                            'اختر شخصية للسطر (/)',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                                          onPressed: () => _openCharacterPickerBottomSheet(isAutoSlash: false),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'اكتب / مباشرة في النص لفتح قائمة الشخصيات',
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    for (var i = 0; i < _lines.length; i++)
                                      _sentenceRow(_lines[i], i),
                                  ] else if (_audioFile != null) ...[
                                    StoryTimelineEditor(
                                      key: ValueKey(_audioFile!.path),
                                      audioFile: _audioFile!,
                                      initialTimeline: _timeline,
                                      appliedMontage: _appliedMontage,
                                      positionNotifier: _positionNotifier,
                                      audioPlayer: _audioPlayer,
                                      isPlaying: _isPlaying,
                                      onTogglePlay: _togglePlayPause,
                                      onTimelineChanged: (val) => _timeline = val,
                                    ),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isLoading
                              ? null
                              : _step == 0
                                  ? _openTimeline
                                  : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _step == 0
                                      ? 'التالي'
                                      : editing
                                          ? 'تحديث القصة'
                                          : 'نشر القصة الآن',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
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
          if (_step == 1 && _montageBusy) const Positioned.fill(child: _MontageAiVeil()),
        ],
      ),
    );
  }
}

class _MontageAiVeil extends StatefulWidget {
  const _MontageAiVeil();

  @override
  State<_MontageAiVeil> createState() => _MontageAiVeilState();
}

class _MontageAiVeilState extends State<_MontageAiVeil> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: SizedBox.expand(
        child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: ColoredBox(
          color: const Color(0x47FFFFFF),
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_pulse.value);
                return Opacity(
                  opacity: 0.45 + (0.55 * t),
                  child: Transform.scale(scale: 0.92 + (0.16 * t), child: child),
                );
              },
              child: const Text(
                'جاري التحضير...',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondary),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _CharacterPickerSheet extends StatelessWidget {
  final List<CustomCharacterModel> customCharacters;
  final VoidCallback onOpenCreator;
  final ValueChanged<CustomCharacterModel>? onEditCharacter;

  const _CharacterPickerSheet({
    required this.customCharacters,
    required this.onOpenCreator,
    this.onEditCharacter,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppColors.border_radius);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppColors.sheet_radius),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: radius,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ربط الجملة بشخصية (/)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      'اختر الشخصية التي ستنطق وتمثل هذه الجملة',
                      style: TextStyle(fontSize: 12, color: AppColors.onSurface),
                    ),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق', style: TextStyle(color: AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'شخصيات Glow الأساسية',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sceneCharacters.map((char) {
                    final color = CharacterHelper.getColor(char.$1);
                    return InkWell(
                      onTap: () => Navigator.pop(context, char.$2),
                      borderRadius: radius,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: radius,
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: radius,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              char.$2,
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'الشخصيات الجاهزة (المصممة)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    if (kIsWeb)
                      FilledButton.tonal(
                        onPressed: onOpenCreator,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: radius),
                        ),
                        child: const Text(
                          'اصنع شخصية +',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (customCharacters.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: radius,
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Text(
                            'لم تصنع شخصيات خاصة بعد',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (kIsWeb) ...[
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: onOpenCreator,
                              child: const Text(
                                'اضغط هنا لتصميم شخصيتك الأولى ثلاثية الأبعاد',
                                style: TextStyle(color: AppColors.secondary),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: customCharacters.map((c) {
                      return InkWell(
                        onTap: () => Navigator.pop(context, c.name),
                        borderRadius: radius,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: radius,
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: c.bodyColor,
                                  borderRadius: radius,
                                  border: Border.all(
                                    color: AppColors.inputBorder,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: c.bellyColor,
                                    borderRadius: radius,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c.name,
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (c.hasHat || c.hasGlasses)
                                Text(
                                  ' · ${[if (c.hasHat) 'قبعة', if (c.hasGlasses) 'نظارة'].join(' · ')}',
                                  style: TextStyle(
                                    color: AppColors.secondary.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              if (onEditCharacter != null) ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => onEditCharacter!(c),
                                  borderRadius: radius,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryContainer,
                                      borderRadius: radius,
                                    ),
                                    child: const Text(
                                      'تعديل',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onSecondaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
