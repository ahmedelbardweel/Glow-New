import 'package:Glow/core/di/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logout_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../content/domain/repositories/content_repository.dart';
import '../../../content/domain/entities/child_progress_entity.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  bool _isLoading = true;
  String? _childId;
  String? _childName;

  int _totalStars = 0;
  int _totalMissions = 0;
  int _totalBadges = 0;

  List<ChildProgressEntity> _recentProgress = [];
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final parentId = Supabase.instance.client.auth.currentUser?.id;

      if (parentId != null) {
        // Query child linked to this parent
        final childrenData = await Supabase.instance.client
            .from('children_profiles')
            .select()
            .eq('parent_id', parentId)
            .limit(1);

        if (childrenData.isNotEmpty) {
          final childData = childrenData.first;
          _childId = childData['id'];
          _childName = childData['name'];
          
          if (mounted) {
            setState(() {
              _totalStars = childData['total_stars'] ?? 0;
              _totalBadges = childData['total_badges'] ?? 0;
              _totalMissions = childData['total_missions'] ?? 0;
            });
          }
        } else {
          debugPrint('childData is null for parent_id: $parentId');
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('لم يتم العثور على طفل مرتبط بهذا الحساب في قاعدة البيانات.')),
             );
          }
        }
      }

      if (_childId != null) {
        final result = await sl<ContentRepository>().getCompletedMissions(
          _childId!,
        );

        result.fold(
          (failure) {
            debugPrint(
              "Error fetching parent dashboard data: ${failure.message}",
            );
          },
          (progressList) {
            int stars = 0;
            int badges = 0;
            for (var p in progressList) {
              stars += (p.starsReward ?? 0).toInt();
              if (p.badgeName != null && p.badgeName!.isNotEmpty) {
                badges++;
              }
            }

            // Sort by recent
            progressList.sort((a, b) => b.completedAt.compareTo(a.completedAt));

            setState(() {
              // Only override stats if progressList actually has data
              if (progressList.isNotEmpty) {
                _totalStars = stars;
                _totalBadges = badges;
              }
              _totalMissions = progressList.length;
              _recentProgress = progressList;
            });
          },
        );
      }
    } catch (e) {
      debugPrint("Parent Dashboard Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('خطأ في جلب البيانات: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _linkChild() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final parentId = Supabase.instance.client.auth.currentUser?.id;
      if (parentId != null) {
        await Supabase.instance.client.rpc('link_parent_to_child', params: {
          'p_parent_id': parentId,
          'p_child_code': code,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم ربط حساب طفلك بنجاح!')),
          );
        }
        await _fetchData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في ربط الحساب، تأكد من صحة الكود.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.4),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text(
          'لوحة تحكم ولي الأمر',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF34495E)),
            onPressed: () => showLogoutBottomSheet(context),
            tooltip: 'الخيارات',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: const Color(0xFF9B59B6),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF9B59B6)),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_childId == null)
                          _buildLinkChildView()
                        else ...[
                          _buildInsightsBanner(),
                          const SizedBox(height: 24),
                          _buildMetricsGrid(),
                          const SizedBox(height: 32),
                          const Text(
                            'أحدث الإنجازات',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildRecentAchievements(),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLinkChildView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.border_radius),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.child_care_rounded,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'لم تقم بربط حساب طفلك بعد!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'أدخل كود طفلك التعريفي (مثال: CH-1234) للبدء في متابعة تطوره.',
            style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              hintText: 'كود الطفل',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppColors.border_radius),
              ),
              prefixIcon: const Icon(Icons.vpn_key_rounded),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _linkChild,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                ),
              ),
              child: const Text(
                'ربط الحساب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsBanner() {
    // Dynamic insight message based on engagement
    String message = 'لم يبدأ البطل أي مهمات بعد. شجعه على الانطلاق!';
    IconData icon = Icons.wb_incandescent_rounded;
    Color color = const Color(0xFFF39C12); // Orange

    if (_totalMissions > 10) {
      message = 'رائع جداً! بطلنا يتقدم بشكل ممتاز ومنتظم في إنجاز التحديات.';
      icon = Icons.emoji_events_rounded;
      color = const Color(0xFF2ECC71); // Green
    } else if (_totalMissions > 0) {
      message = 'بداية موفقة! بطلنا يكتسب مهارات جديدة مع كل مهمة.';
      icon = Icons.star_rounded;
      color = const Color(0xFF9B59B6); // Purple
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.border_radius),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رسالة تشجيعية',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF34495E),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'المهمات',
            value: _totalMissions.toString(),
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF3498DB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'النقاط',
            value: _totalStars.toString(),
            icon: Icons.star_rounded,
            color: const Color(0xFFF39C12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'الأوسمة',
            value: _totalBadges.toString(),
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF9B59B6),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColors.border_radius),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements() {
    if (_recentProgress.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 60, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'لا توجد إنجازات بعد',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentProgress.length > 5
          ? 5
          : _recentProgress.length, // Show up to 5 recent
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final progress = _recentProgress[index];
        final bool hasBadge =
            progress.badgeName != null && progress.badgeName!.isNotEmpty;

        // Format date manually without intl package
        final d = progress.completedAt;
        final dateStr =
            '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} - ${d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour)}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'م' : 'ص'}';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppColors.border_radius),
            border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: hasBadge
                      ? const Color(0xFF9B59B6).withOpacity(0.1)
                      : const Color(0xFF3498DB).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasBadge
                      ? Icons.workspace_premium_rounded
                      : Icons.task_alt_rounded,
                  color: hasBadge
                      ? const Color(0xFF9B59B6)
                      : const Color(0xFF3498DB),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasBadge
                          ? 'حصل على ${progress.badgeName}'
                          : 'أكمل المهمة',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.missionTitle ?? 'مهمة مجهولة',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7F8C8D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        '+${progress.starsReward ?? 0}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE67E22), // Deep orange
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFBDC3C7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
