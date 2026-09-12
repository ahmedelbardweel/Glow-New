import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/mission_entity.dart';

class ChildMissionCompleteScreen extends StatelessWidget {
  final MissionEntity mission;

  const ChildMissionCompleteScreen({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA), // Light Blue
              Color(0xFFF3E5F5), // Light Purple
              Color(0xFFFFF3E0), // Light Orange
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Icon / Illustration
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 120,
                    color: Colors.amber,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Title
                const Text(
                  'أحسنت يا بطل! 🌟',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2ECC71),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                const Text(
                  'لقد أتممت المهمة بالكامل وأجبت على جميع التحديات بنجاح. لقد ربحت أوسمة ونقاطاً جديدة!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Earned Badge Card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppColors.border_radius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFF3498DB).withOpacity(0.3), width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'الوسام المكتسب',
                              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              mission.badgeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2C3E50),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Divider
                      Container(
                        height: 60,
                        width: 2,
                        color: Colors.grey.withOpacity(0.2),
                      ),
                      // Points
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 48),
                            const SizedBox(height: 8),
                            const Text(
                              'النقاط',
                              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '+${mission.starsReward}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE67E22),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // See Badges Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () {
                      context.push('/child/badges');
                    },
                    icon: const Icon(Icons.workspace_premium_rounded, size: 28),
                    label: const Text(
                      'رؤية أوسمتي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.border_radius),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF9B59B6).withOpacity(0.5),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Go to Dashboard Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      context.go('/child-dashboard');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3498DB), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppColors.border_radius),
                      ),
                    ),
                    child: const Text(
                      'العودة للرئيسية',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3498DB),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
