import 'dart:ui';
import 'package:Glow/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final Color? color;
  
  /// إذا كان اللودر بداخل زر أو مساحة صغيرة جداً، نعرض نسخة مصغرة وحديثة
  final bool isSmall;

  const CustomLoader({
    super.key,
    this.size = 20,
    this.color,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSmall) {
      // لودر مصغر للأزرار
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color ?? Colors.white,
          strokeCap: StrokeCap.round,
        ),
      );
    }

    final loaderColor = color ?? AppColors.primary; // لون بنفسجي أنيق افتراضي

    // اللودر الحديث بتأثير الزجاج (Glassmorphism)
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.border_radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7), // خلفية بيضاء شفافة لتوضيح النص
                borderRadius: BorderRadius.circular(AppColors.border_radius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      strokeWidth: 4.5,
                      color: loaderColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'جاري التحميل...',
                    style: TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
