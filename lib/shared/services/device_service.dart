import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final _uuid = const Uuid();
  
  Future<String> getDeviceId() async {
    const deviceIdKey = 'device_id';
    String? deviceId = await _secureStorage.read(key: deviceIdKey);
    
    if (deviceId == null) {
      deviceId = _uuid.v4();
      await _secureStorage.write(key: deviceIdKey, value: deviceId);
    }
    
    return deviceId;
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (await _isAndroid()) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'version': androidInfo.version.release,
          'sdk': androidInfo.version.sdkInt,
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
        };
      } else if (await _isIOS()) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'version': iosInfo.systemVersion,
          'name': iosInfo.name,
          'model': iosInfo.model,
        };
      } else {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return {
          'platform': 'web',
          'browserName': webInfo.browserName,
          'platform': webInfo.platform,
          'userAgent': webInfo.userAgent,
        };
      }
    } catch (e) {
      return {
        'platform': 'unknown',
        'error': e.toString(),
      };
    }
  }

  Future<bool> _isAndroid() async {
    try {
      await _deviceInfo.androidInfo;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isIOS() async {
    try {
      await _deviceInfo.iosInfo;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }
} 