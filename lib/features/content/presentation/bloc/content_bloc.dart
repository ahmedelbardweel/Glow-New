import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/user_message.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/world_usecases.dart';
import '../../domain/usecases/mission_usecases.dart';
import '../../domain/usecases/story_usecases.dart';
import '../../domain/usecases/question_usecases.dart';
import 'content_event.dart';
import 'content_state.dart';

class ContentBloc extends Bloc<ContentEvent, ContentState> {
  final GetWorldsUseCase getWorlds;
  final AddWorldUseCase addWorld;
  final GetMissionsUseCase getMissions;
  final AddMissionUseCase addMission;
  final GetStoriesUseCase getStories;
  final AddStoryUseCase addStory;
  final GetQuestionsUseCase getQuestions;
  final AddQuestionUseCase addQuestion;
  final CompleteMissionUseCase completeMission;
  final GetCompletedMissionsUseCase getCompletedMissions;

  final UpdateWorldUseCase updateWorld;
  final DeleteWorldUseCase deleteWorld;
  final UpdateMissionUseCase updateMission;
  final DeleteMissionUseCase deleteMission;
  final UpdateStoryUseCase updateStory;
  final DeleteStoryUseCase deleteStory;
  final UpdateQuestionUseCase updateQuestion;
  final DeleteQuestionUseCase deleteQuestion;

  ContentBloc({
    required this.getWorlds,
    required this.addWorld,
    required this.getMissions,
    required this.addMission,
    required this.getStories,
    required this.addStory,
    required this.getQuestions,
    required this.addQuestion,
    required this.completeMission,
    required this.getCompletedMissions,
    required this.updateWorld,
    required this.deleteWorld,
    required this.updateMission,
    required this.deleteMission,
    required this.updateStory,
    required this.deleteStory,
    required this.updateQuestion,
    required this.deleteQuestion,
  }) : super(const ContentState.initial()) {
    on<ContentEvent>((event, emit) async {
      await event.map(
        getWorlds: (e) async {
          final keep = state.maybeWhen(
            worldsLoaded: (_) => true,
            orElse: () => false,
          );
          final result = await _keepOrWait(
            emit,
            getWorlds(GetWorldsParams(forceRefresh: e.forceRefresh)),
            keep: keep,
          );
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (worlds) => emit(ContentState.worldsLoaded(worlds)),
          );
        },
        addWorld: (e) async {
          emit(const ContentState.loading());
          final result = await addWorld(e.world);
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (world) => emit(ContentState.worldAdded(world)),
          );
        },
        updateWorld: (e) async {
          emit(const ContentState.loading());
          final result = await updateWorld(e.world);
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (_) => add(const ContentEvent.getWorlds()),
          );
        },
        deleteWorld: (e) async {
          emit(const ContentState.loading());
          final result = await deleteWorld(e.id);
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (_) => add(const ContentEvent.getWorlds()),
          );
        },
        getMissions: (e) async {
          final keep = state.maybeWhen(
            missionsLoaded: (_) => true,
            orElse: () => false,
          );
          final result = await _keepOrWait(
            emit,
            getMissions(GetMissionsParams(e.worldId, forceRefresh: e.forceRefresh)),
            keep: keep,
          );
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (missions) => emit(ContentState.missionsLoaded(missions)),
          );
        },
        addMission: (e) async {
          emit(const ContentState.loading());
          final result = await addMission(e.mission);
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (mission) => emit(ContentState.missionAdded(mission)),
          );
        },
        updateMission: (e) async {
          emit(const ContentState.loading());
          final result = await updateMission(e.mission);
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (_) => add(ContentEvent.getMissions(e.mission.worldId)),
          );
        },
        deleteMission: (e) async {
          // Note: we can't easily refetch missions without worldId, so we just emit a success state or a generic loaded.
          // Since we might be on a screen that needs refresh, we expect the UI to handle it or we can pass worldId in delete event.
          // For now we'll just emit loading then error or nothing (UI can re-trigger getMissions).
          emit(const ContentState.loading());
          final result = await deleteMission(e.id);
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (_) => emit(const ContentState.initial()), // UI should listen to this and refresh
          );
        },
        getStories: (e) async {
          final keep = state.maybeWhen(
            storiesLoaded: (_) => true,
            orElse: () => false,
          );
          final result = await _keepOrWait(
            emit,
            getStories(GetStoriesParams(e.missionId, forceRefresh: e.forceRefresh)),
            keep: keep,
          );
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (stories) => emit(ContentState.storiesLoaded(stories)),
          );
        },
        addStory: (e) async {
          emit(const ContentState.loading());
          final result = await addStory(AddStoryParams(e.story, audioFile: e.audioFile, characterFile: e.characterFile));
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (story) => emit(ContentState.storyAdded(story)),
          );
        },
        updateStory: (e) async {
          emit(const ContentState.loading());
          final result = await updateStory(AddStoryParams(e.story, audioFile: e.audioFile, characterFile: e.characterFile));
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (_) => add(ContentEvent.getStories(e.story.missionId)),
          );
        },
        deleteStory: (e) async {
          emit(const ContentState.loading());
          final result = await deleteStory(e.id);
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (_) => emit(const ContentState.initial()),
          );
        },
        getQuestions: (e) async {
          final keep = state.maybeWhen(
            questionsLoaded: (_) => true,
            orElse: () => false,
          );
          final result = await _keepOrWait(
            emit,
            getQuestions(GetQuestionsParams(e.missionId, forceRefresh: e.forceRefresh)),
            keep: keep,
          );
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (questions) => emit(ContentState.questionsLoaded(questions)),
          );
        },
        addQuestion: (e) async {
          emit(const ContentState.loading());
          final result = await addQuestion(e.question);
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (question) => emit(ContentState.questionAdded(question)),
          );
        },
        updateQuestion: (e) async {
          emit(const ContentState.loading());
          final result = await updateQuestion(e.question);
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (_) => add(ContentEvent.getQuestions(e.question.missionId)),
          );
        },
        deleteQuestion: (e) async {
          emit(const ContentState.loading());
          final result = await deleteQuestion(e.id);
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (_) => emit(const ContentState.initial()),
          );
        },
        completeMission: (e) async {
          emit(const ContentState.loading());
          final result = await completeMission(CompleteMissionParams(e.missionId, e.childId));
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (_) => emit(const ContentState.missionCompleted()),
          );
        },
        getCompletedMissions: (e) async {
          final keep = state.maybeWhen(
            completedMissionsLoaded: (_) => true,
            orElse: () => false,
          );
          final result = await _keepOrWait(
            emit,
            getCompletedMissions(e.childId),
            keep: keep,
          );
          result.fold(
            (failure) => emit(ContentState.error(userMessage(failure.message))),
            (progressList) => emit(ContentState.completedMissionsLoaded(progressList)),
          );
        },
      );
    });
  }

  static const _shimmerDelay = Duration(milliseconds: 160);

  /// Keeps a list that is already on screen. The shimmer waits briefly so a
  /// cached answer can appear without covering the page.
  Future<Either<Failure, T>> _keepOrWait<T>(
    Emitter<ContentState> emit,
    Future<Either<Failure, T>> pending, {
    required bool keep,
  }) async {
    if (keep) return pending;
    var settled = false;
    unawaited(pending.whenComplete(() => settled = true));
    await Future<void>.delayed(_shimmerDelay);
    if (!settled && !isClosed) emit(const ContentState.loading());
    return pending;
  }
}
