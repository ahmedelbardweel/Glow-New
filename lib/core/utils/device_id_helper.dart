import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceIdHelper {
  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor ?? 'unknown_ios_device';
    } else if (Platform.isAndroid) {
      final androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id;
    } else {
      return 'unsupported_platform';
    }
  }

  static String generateDeviceEmail(String deviceId) {
    return '$deviceId@glow.app';
  }

  static String generateDevicePassword(String deviceId) {
    return '${deviceId}_secret_glow_2026';
  }
}
