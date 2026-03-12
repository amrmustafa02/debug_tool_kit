import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SystemInfoCollector {
  String? _environment;

  void setEnvironment(String env) => _environment = env;

  Future<Map<String, String>> collect() async {
    final info = <String, String>{};

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      info['App Name'] = packageInfo.appName;
      info['Version'] = packageInfo.version;
      info['Build Number'] = packageInfo.buildNumber;
      info['Package Name'] = packageInfo.packageName;
    } catch (_) {}

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          final android = await deviceInfo.androidInfo;
          info['Device'] = '${android.manufacturer} ${android.model}';
          info['OS'] = 'Android ${android.version.release} (SDK ${android.version.sdkInt})';
        } else if (Platform.isIOS) {
          final ios = await deviceInfo.iosInfo;
          info['Device'] = ios.utsname.machine;
          info['Model'] = ios.model;
          info['OS'] = '${ios.systemName} ${ios.systemVersion}';
        } else if (Platform.isMacOS) {
          final mac = await deviceInfo.macOsInfo;
          info['Device'] = mac.model;
          info['OS'] = 'macOS ${mac.majorVersion}.${mac.minorVersion}.${mac.patchVersion}';
        } else if (Platform.isWindows) {
          final win = await deviceInfo.windowsInfo;
          info['Device'] = win.computerName;
          info['OS'] = 'Windows ${win.majorVersion}.${win.minorVersion}';
        } else if (Platform.isLinux) {
          final linux = await deviceInfo.linuxInfo;
          info['Device'] = linux.prettyName;
          info['OS'] = linux.versionId ?? 'Linux';
        }
      } else {
        final web = await deviceInfo.webBrowserInfo;
        info['Browser'] = web.browserName.name;
        info['Platform'] = web.platform ?? 'Web';
      }
    } catch (_) {}

    if (_environment != null) {
      info['Environment'] = _environment!;
    }

    info['Debug Mode'] = kDebugMode ? 'Yes' : 'No';

    return info;
  }
}
