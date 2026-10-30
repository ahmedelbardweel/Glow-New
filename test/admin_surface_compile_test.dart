import 'package:Glow/features/content/data/services/sync_service.dart';
import 'package:Glow/features/content/data/repositories/content_repository_impl.dart';
import 'package:Glow/features/content/presentation/screens/add_world_screen.dart';
import 'package:Glow/features/content/presentation/screens/add_story_screen.dart';
import 'package:Glow/features/content/presentation/screens/add_mission_screen.dart';
import 'package:Glow/features/content/presentation/screens/add_question_screen.dart';
import 'package:Glow/features/dashboard/presentation/screens/content_packages_screen.dart';
import 'package:Glow/features/dashboard/presentation/screens/content_package_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Glow/features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:Glow/features/content/presentation/screens/world_missions_screen.dart';
import 'package:Glow/features/content/presentation/screens/mission_stories_screen.dart';
import 'package:Glow/features/content/presentation/screens/mission_questions_screen.dart';

void main() {
  test('admin screens and persistence dependencies compile together', () {
    expect(<Type>[
      SyncService,
      ContentRepositoryImpl,
      AddWorldScreen,
      AddStoryScreen,
      AddMissionScreen,
      AddQuestionScreen,
      ContentPackagesScreen,
      ContentPackageDetailScreen,
      AdminDashboardScreen,
      WorldMissionsScreen,
      MissionStoriesScreen,
      MissionQuestionsScreen,
    ], hasLength(12));
  });
}
