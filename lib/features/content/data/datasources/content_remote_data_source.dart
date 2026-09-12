import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/world_model.dart';
import '../models/mission_model.dart';
import '../models/story_model.dart';
import '../models/question_model.dart';
import '../models/child_progress_model.dart';

abstract class ContentRemoteDataSource {
  // Worlds
  Future<List<WorldModel>> getWorlds();
  Future<WorldModel> addWorld(WorldModel world);
  
  // Missions
  Future<List<MissionModel>> getMissions(String worldId);
  Future<MissionModel> addMission(MissionModel mission);
  
  // Stories
  Future<List<StoryModel>> getStories(String missionId);
  Future<StoryModel> addStory(StoryModel story, {File? audioFile});
  
  // Questions
  Future<List<QuestionModel>> getQuestions(String missionId);
  Future<QuestionModel> addQuestion(QuestionModel question);

  // Progress
  Future<void> completeMission(String missionId, String childId);
  Future<List<ChildProgressModel>> getCompletedMissions(String childId);
}

class ContentRemoteDataSourceImpl implements ContentRemoteDataSource {
  final SupabaseClient supabaseClient;

  ContentRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<WorldModel>> getWorlds() async {
    final response = await supabaseClient.from('worlds').select().order('created_at', ascending: true);
    return response.map((json) => WorldModel.fromJson(json)).toList();
  }

  @override
  Future<WorldModel> addWorld(WorldModel world) async {
    final response = await supabaseClient.from('worlds').insert(world.toJson()).select().single();
    return WorldModel.fromJson(response);
  }

  @override
  Future<List<MissionModel>> getMissions(String worldId) async {
    final response = await supabaseClient
        .from('missions')
        .select()
        .eq('world_id', worldId)
        .order('order_index', ascending: true);
    return response.map((json) => MissionModel.fromJson(json)).toList();
  }

  @override
  Future<MissionModel> addMission(MissionModel mission) async {
    final response = await supabaseClient.from('missions').insert(mission.toJson()).select().single();
    return MissionModel.fromJson(response);
  }

  @override
  Future<List<StoryModel>> getStories(String missionId) async {
    final response = await supabaseClient
        .from('stories')
        .select()
        .eq('mission_id', missionId)
        .order('order_index', ascending: true);
    return response.map((json) => StoryModel.fromJson(json)).toList();
  }

  @override
  Future<StoryModel> addStory(StoryModel story, {File? audioFile}) async {
    String? audioUrl = story.audioUrl;
    
    if (audioFile != null) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${audioFile.path.split('/').last}';
      await supabaseClient.storage.from('story_audio').upload(
        fileName,
        audioFile,
      );
      audioUrl = supabaseClient.storage.from('story_audio').getPublicUrl(fileName);
    }
    
    final storyToSave = StoryModel(
      id: story.id,
      missionId: story.missionId,
      title: story.title,
      content: story.content,
      characterName: story.characterName,
      imageUrl: story.imageUrl,
      orderIndex: story.orderIndex,
      audioUrl: audioUrl,
    );

    final response = await supabaseClient.from('stories').insert(storyToSave.toJson()).select().single();
    return StoryModel.fromJson(response);
  }

  @override
  Future<List<QuestionModel>> getQuestions(String missionId) async {
    final response = await supabaseClient
        .from('questions')
        .select()
        .eq('mission_id', missionId);
    return response.map((json) => QuestionModel.fromJson(json)).toList();
  }

  @override
  Future<QuestionModel> addQuestion(QuestionModel question) async {
    final response = await supabaseClient.from('questions').insert(question.toJson()).select().single();
    return QuestionModel.fromJson(response);
  }

  @override
  Future<void> completeMission(String missionId, String childId) async {
    // Insert progress, handling unique constraint violations silently if already completed
    await supabaseClient.from('child_progress').upsert(
      {
        'child_id': childId,
        'mission_id': missionId,
      },
      onConflict: 'child_id, mission_id',
    );
  }

  @override
  Future<List<ChildProgressModel>> getCompletedMissions(String childId) async {
    final response = await supabaseClient
        .from('child_progress')
        .select('*, missions(title, badge_name, stars_reward)')
        .eq('child_id', childId)
        .order('completed_at', ascending: false);
    
    return response.map((json) => ChildProgressModel.fromJson(json)).toList();
  }
}
