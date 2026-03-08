import 'dart:convert';
//import 'package:app_wallet_app/common/dic_service.dart';
import 'package:device_apps/device_apps.dart';
//import 'package:flutter/material.dart';
//import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachedApplication {
  String appNum;
  String appName;
  String packageName;
  String icon;
  String isOpening;
  String appUsePeriod;
  String isFixedApp;

  CachedApplication({
    required this.appNum,
    required this.appName,
    required this.packageName,
    required this.icon,
    required this.isOpening,
    required this.appUsePeriod,
    required this.isFixedApp,
  });

  Map<String, dynamic> toJson() {
    return {
      'appNum': appNum,
      'appName': appName,
      'packageName': packageName,
      'icon': icon,
      'isOpening': isOpening,
      'appUsePeriod': appUsePeriod,
      'isFixedApp': isFixedApp,
    };
  }

  factory CachedApplication.fromJson(Map<String, dynamic> json) {
    return CachedApplication(
      appNum: json['appNum'],
      appName: json['appName'],
      packageName: json['packageName'],
      icon: json['icon'],
      isOpening: json['isOpening'],
      appUsePeriod: json['appUsePeriod'],
      isFixedApp: json['isFixedApp'],
    );
  }
}

class AppCache {
  static const String keyCachedApps = 'cached_apps';

  static Future<List<CachedApplication>> getCachedApps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic cachedAppsData = prefs.get(keyCachedApps);

    // 캐시가 전혀 없는 최초 실행 시점에는 여기에서 한 번만 전체 앱 캐시를 생성한다.
    if (cachedAppsData == null) {
      return await cacheAllApps();
    }

    try {
      if (cachedAppsData is String) {
        List<dynamic> cachedAppJsonList = jsonDecode(cachedAppsData);
        return cachedAppJsonList
            .map<CachedApplication>(
              (appJson) => CachedApplication.fromJson(appJson),
            )
            .toList();
      } else if (cachedAppsData is List<String>) {
        return cachedAppsData
            .map<CachedApplication>(
              (appString) => CachedApplication.fromJson(jsonDecode(appString)),
            )
            .toList();
      } else if (cachedAppsData is List) {
        return cachedAppsData
            .map<CachedApplication>(
              (appJson) => CachedApplication.fromJson(jsonDecode(appJson)),
            )
            .toList();
      } else {
        // Print or log the type of cachedAppsData
        print('Type of cachedAppsData is ${cachedAppsData.runtimeType}');

        // 데이터의 유형이 일치하지 않으므로 해당 키의 데이터를 삭제
        await prefs.remove(keyCachedApps);
        return [];
      }
    } catch (e) {
      await prefs.remove(keyCachedApps);
      return [];
    }
  }

  static Future<void> cacheApps(List<CachedApplication> apps) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> appStrings = apps
        .map((app) => jsonEncode(app.toJson()))
        .toList();
    await prefs.setStringList(keyCachedApps, appStrings);
  }

  static Future<List<CachedApplication>> cacheAllApps() async {
    List<Application> userApps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: true,
      onlyAppsWithLaunchIntent: true,
    );

    List<CachedApplication> cachedApps = [];
    for (var app in userApps) {
      String icon = '';
      try {
        var appWithIcon = app as ApplicationWithIcon;
        final iconBytes = appWithIcon.icon;
        icon = base64Encode(iconBytes);
      } catch (e) {
        print('Error encoding icon: $e');
      }

      CachedApplication cachedApp = CachedApplication(
        appNum: "0",
        appName: app.appName,
        packageName: app.packageName,
        icon: icon,
        isOpening: "",
        appUsePeriod: "0",
        isFixedApp: "0",
      );
      cachedApps.add(cachedApp);
    }

    await cacheApps(cachedApps);
    return cachedApps;
  }

  static Future<bool> isAllAppsCached() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic cachedData = prefs.get(keyCachedApps);

    return cachedData != null;
  }

  static Future<void> updateCacheOnAppChange() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
    await updateCachedAppList(apps);
  }

  static Future<void> updateCachedAppList(List<Application> apps) async {
    List<CachedApplication> cachedApps = await getCachedApps();
    List<String> cachedAppPackageNames = cachedApps
        .map((app) => app.packageName)
        .toList();

    for (var app in apps) {
      if (!cachedAppPackageNames.contains(app.packageName)) {
        String icon = '';
        try {
          var appWithIcon = app as ApplicationWithIcon;
          final iconBytes = appWithIcon.icon;
          icon = base64Encode(iconBytes);
        } catch (e) {
          print('Error encoding icon: $e');
        }
        CachedApplication cachedApp = CachedApplication(
          appNum: "0",
          appName: app.appName,
          packageName: app.packageName,
          icon: icon,
          isOpening: "",
          appUsePeriod: "0",
          isFixedApp: "0",
        );
        cachedApps.add(cachedApp);
      }
    }

    await cacheApps(cachedApps);
  }
}
