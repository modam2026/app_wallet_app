import 'dart:convert';
//import 'package:app_wallet_app/common/dic_service.dart';
import 'package:device_apps/device_apps.dart';
//import 'package:flutter/material.dart';
//import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 설치된 앱 하나의 정보를 담는 데이터 모델 클래스.
///
/// 작업 순서:
///   1. [AppCache.cacheAllApps] 또는 [AppCache.getCachedApps] 에서 생성
///   2. [toJson] 으로 JSON 문자열로 변환 후 SharedPreferences 에 저장
///   3. [fromJson] 으로 SharedPreferences 에서 읽어올 때 복원
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

  /// 이 객체의 필드를 Map<String, dynamic> 으로 변환하여 반환.
  /// SharedPreferences 저장 전 JSON 직렬화 단계에서 호출됨.
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

  /// Map<String, dynamic>(JSON) 으로부터 [CachedApplication] 인스턴스를 생성하는 팩토리 생성자.
  /// SharedPreferences 에서 읽어온 JSON 문자열을 복원할 때 호출됨.
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

/// SharedPreferences 를 이용해 폰에 설치된 앱 목록을 캐시로 관리하는 클래스.
///
/// 작업 순서:
///   1. [getCachedApps]    - SharedPreferences 캐시 조회
///                           캐시 없으면 → [cacheAllApps] 호출하여 최초 생성
///   2. [cacheAllApps]     - DeviceApps 로 전체 설치 앱을 읽어 캐시 생성 후 저장
///   3. [cacheApps]        - [CachedApplication] 목록을 JSON 직렬화하여 SharedPreferences 에 저장
///   4. [isAllAppsCached]  - 캐시 존재 여부 확인 (true/false)
///   5. [updateCacheOnAppChange] - 앱 설치/삭제 이벤트 발생 시 캐시 갱신
///   6. [updateCachedAppList]    - 기존 캐시에 없는 신규 앱만 추가하여 캐시 업데이트
class AppCache {
  static const String keyCachedApps = 'cached_apps';

  /// SharedPreferences 에서 캐시된 앱 목록을 읽어 반환.
  ///
  /// 작업 순서:
  ///   1. SharedPreferences 인스턴스 획득
  ///   2. 'cached_apps' 키로 저장된 데이터 조회
  ///   3. 데이터 없으면 → [cacheAllApps] 호출하여 최초 캐시 생성 후 반환
  ///   4. 데이터 있으면 → 타입에 따라 JSON 역직렬화하여 [CachedApplication] 목록 반환
  ///   5. 타입 불일치 또는 예외 발생 시 → 해당 키 삭제 후 빈 목록 반환
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

  /// [CachedApplication] 목록을 JSON 문자열 목록으로 직렬화하여 SharedPreferences 에 저장.
  ///
  /// 작업 순서:
  ///   1. SharedPreferences 인스턴스 획득
  ///   2. 각 [CachedApplication] 을 [toJson] → jsonEncode 로 문자열 변환
  ///   3. 문자열 목록을 'cached_apps' 키로 저장
  static Future<void> cacheApps(List<CachedApplication> apps) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> appStrings = apps
        .map((app) => jsonEncode(app.toJson()))
        .toList();
    await prefs.setStringList(keyCachedApps, appStrings);
  }

  /// 폰에 설치된 전체 앱을 DeviceApps 로 읽어 캐시를 최초 생성하고 저장.
  ///
  /// 작업 순서:
  ///   1. DeviceApps.getInstalledApplications 로 전체 설치 앱 목록 조회
  ///      (시스템 앱 포함, 아이콘 포함, 런처 인텐트 있는 것만)
  ///   2. 각 앱의 아이콘을 base64 인코딩하여 문자열로 변환
  ///   3. [CachedApplication] 객체 생성 후 목록에 추가
  ///   4. [cacheApps] 호출하여 SharedPreferences 에 저장
  ///   5. 생성된 목록 반환
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

  /// SharedPreferences 에 앱 캐시가 존재하는지 여부를 반환.
  /// true = 캐시 있음, false = 캐시 없음 (최초 실행 또는 캐시 삭제 후)
  static Future<bool> isAllAppsCached() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic cachedData = prefs.get(keyCachedApps);

    return cachedData != null;
  }

  /// 앱 설치/삭제 이벤트 발생 시 사용자 앱(시스템 앱 제외)만 다시 읽어 캐시 갱신.
  ///
  /// 작업 순서:
  ///   1. DeviceApps.getInstalledApplications 로 사용자 앱 목록 조회 (시스템 앱 제외)
  ///   2. [updateCachedAppList] 호출하여 기존 캐시에 신규 앱 추가
  static Future<void> updateCacheOnAppChange() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );
    await updateCachedAppList(apps);
  }

  /// 전달받은 앱 목록 중 기존 캐시에 없는 앱만 추가하여 캐시 업데이트.
  ///
  /// 작업 순서:
  ///   1. [getCachedApps] 로 현재 캐시 목록 조회
  ///   2. 기존 캐시의 packageName 목록 추출
  ///   3. 전달받은 앱 목록을 순회하며 캐시에 없는 앱만 [CachedApplication] 으로 변환 후 추가
  ///   4. [cacheApps] 호출하여 갱신된 목록 저장
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
