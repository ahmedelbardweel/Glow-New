import 'package:flutter_bloc/flutter_bloc.dart';
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
  }) : super(const ContentState.initial()) {
    on<ContentEvent>((event, emit) async {
      await event.map(
        getWorlds: (e) async {
          emit(const ContentState.loading());
          final result = await getWorlds(NoParams());
          result.fold(
            (failure) => emit(ContentState.error(failure.message)),
            (worlds) => emit(ContentState.worldsLoaded(worlds)),
          );
        },
        addWorld: (e) async {
          emit(const ContentState.loading());
          final result = await addWorld(e.world);
          result.fold(
            (failure) => emit(ContentState.error(failure.message)),
            (world) => emit(ContentState.worldAdded(world)),
          );
        },
        getMissions: (e) async {
          emit(const ContentState.loading());
          final result = await getMissions(e.worldId);
          result.fold(
            (failure) => emit(ContentState.error(failure.message)),
            (missions) => emit(ContentState.missionsLoaded(missions)),
          );
        },
        addMission: (e) async {
          emit(const ContentState.loading());
          final result = await addMission(e.mission);
          result.fold(
            (failure) => emit(ContentState.error(failure.message)),
            (mission) => emit(ContentState.missionAdded(mission)),
          );
        },
        getStories: (e) async {
          emit(const ContentState.loading());
          final result = await getStories(e.missionId);
          result.fold(
            (failure) => emit(ContentState.error(failure.message)),
            (stories) => emit(ContentState.storiesLoaded(stories)),
          );
        },
        addStory: (e) async {
          emit(const ContentState.loading());
          final result = await addStory(AddStoryParams(e.story, audioFile: e.audioFile));
          result.fold(
            (failure) => emit(ContentState.error(failure.message)),
            (story) => emit(ContentState.storyAdded(story)),
          );
        },
        getQuestions: (e) async {
          emit(const ContentState.loading());
          final result = await getQuestions(e.missionId);
          result.fold(
            (failure) => emit(ContentState.error(failure.message)),
            (questions) => emit(ContentState.questionsLoaded(questions)),
          );
        },
        addQuestion: (e) async {
          emit(const ContentState.loading());
          final result = await addQuestion(e.question);
          result.fold(
            (failure) => emit(ContentState.error(failure.message)),
            (question) => emit(ContentState.questionAdded(question)),
          );
        },
        completeMission: (e) async {
          emit(const ContentState.loading());
          final result = await completeMission(CompleteMissionParams(e.missionId, e.childId));
          result.fold(
            (failure) => emit(ContentState.error(failure.message)),
            (_) => emit(const ContentState.missionCompleted()),
          );
        },
        getCompletedMissions: (e) async {
          emit(const ContentState.loading());
          final result = await getCompletedMissions(e.childId);
          result.fold(
            (failure) => emit(ContentState.error(failure.message)),
            (progressList) => emit(ContentState.completedMissionsLoaded(progressList)),
          );
        },
      );
    });
  }
}
