import 'package:app_wallet_app/common/AppCache.dart';
import 'package:app_wallet_app/common/common_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;
//import 'package:device_apps/device_apps.dart';

/// SQLite DB(db_app_management.db) 의 tbl_my_application_info 테이블에 대한
/// CRUD 및 초기화 작업을 담당하는 정적(static) 유틸리티 클래스.
///
/// 작업 순서:
///   1. [appMngmntDB]             - DB 파일 열기 (없으면 [createIntrnAppTables] 로 테이블 생성)
///   2. [hasMyApps]               - "나의 앱" 테이블에 데이터 존재 여부 확인
///   3. [makeIntrnAppListData]    - 패키지명을 분석하여 앱 분류(그룹) 데이터 생성
///   4. [initIntrnAppListData]    - 캐시된 전체 앱 목록을 분류별로 필터링하여 반환
///   5. [addMyIntrnAppInfo]       - "나의 앱" 목록에 앱 신규 추가 (중복 시 사용 이력 업데이트)
///   6. [isAppInDatabase]         - 특정 앱이 DB 에 저장되어 있는지 확인
///   7. [changeOpenStatusInfo]    - 앱 실행 시 사용 횟수(app_num)·사용 기간(app_use_period) 업데이트
///   8. [selectNumStatusInfo]     - 현재 최대 app_num 조회
///   9. [updateMyIntrnAppStts]    - is_first_input 플래그 일괄 업데이트
///  10. [getMyAppsFromDB]         - "나의 앱" 전체 목록 조회 (정렬: 고정 > 사용기간 > 사용횟수)
///  11. [getDistinctAppUserGroups]- 중복 제거된 app_user_group 목록 조회 (Drawer 그룹 목록용)
///  12. [fixMyIntrnAppInfo]       - 앱 고정/해제 토글 (is_fixed_app 0↔1)
///  13. [changeMyGroupInfo]       - 앱 그룹 변경 (app_order, app_kind, app_user_group 업데이트)
///  14. [deleteMyIntrnAppInfo]    - 특정 앱 데이터 삭제
class SQLHelper {
  /// DB 최초 생성 시 tbl_my_application_info, tbl_group_info 테이블을 생성.
  /// [appMngmntDB] 의 onCreate 콜백에서만 호출됨.
  static Future<void> createIntrnAppTables(sql.Database database) async {
    await database.execute("""CREATE TABLE tbl_my_application_info (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    	app_num            INTEGER NOT NULL ,
    	app_order          TEXT    NOT NULL ,
    	app_kind           TEXT    NOT NULL ,
    	app_user_group     TEXT    NOT NULL ,      
    	app_opening        INTEGER NOT NULL ,            
    	app_use_period     INTEGER NOT NULL ,            
    	app_name           TEXT    NOT NULL ,
    	package_name       TEXT    NOT NULL ,
    	package_part1      TEXT    NOT NULL ,
    	package_part2      TEXT    NOT NULL ,
    	package_part3      TEXT    NOT NULL ,      
    	package_part4      TEXT    NOT NULL ,      
    	package_part5      TEXT    NOT NULL ,  
      is_first_input     INTEGER NOT NULL ,      
      is_fixed_app       INTEGER NOT NULL ,      
      use_period_at      TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc')),
      createdAt          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc'))
    )
    """);

    await database.execute("""CREATE TABLE tbl_group_info (
      group_name         TEXT    NOT NULL PRIMARY KEY ,
      group_order        TEXT    NOT NULL ,
      app_order          TEXT    NOT NULL ,      
      group_code         TEXT    NOT NULL ,
      use_yn             TEXT    NOT NULL DEFAULT 'Y',      
      use_period_at      TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc')),
      createdAt          TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc'))
    )
    """);
  }

  // ******************* //
  // put application information to Sqlite
  // 2023.06.03
  // ******************* //

  // created_at: 2023.06.03
  /// DB 파일(db_app_management.db)을 열고 [sql.Database] 인스턴스를 반환.
  /// DB 파일이 없으면 [createIntrnAppTables] 를 호출하여 테이블을 자동 생성.
  /// 모든 DB 작업 함수의 첫 번째 단계로 반드시 호출됨.
  static Future<sql.Database> appMngmntDB() async {
    return sql.openDatabase(
      'db_app_management.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createIntrnAppTables(database);
      },
    );
  }

  // ================== webinfo.db (웹 사이트·로그인 정보) ================== //

  static Future<void> _createWebTables(sql.Database database) async {
    await database.execute("""CREATE TABLE tbl_web_info (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    	caption            TEXT    NOT NULL ,
    	web_url            TEXT    NULL DEFAULT NULL ,
    	tag                TEXT    NULL DEFAULT NULL ,
      used_cnt           INTEGER NOT NULL DEFAULT 0 ,
      createdAt    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP 
    )
    """);

    await database.execute("""CREATE TABLE tbl_app_web_info (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      web_url            TEXT    NOT NULL ,
      app_web_name       TEXT    NOT NULL ,
      username           TEXT    NULL DEFAULT NULL ,
      password           TEXT    NULL DEFAULT NULL ,
      memo               TEXT    NULL DEFAULT NULL ,
      createdAt          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc')),
      updatedAt          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc'))
    )
    """);
  }

  static Future<void> _createAppWebInfoTableIfMissing(
    sql.Database database,
  ) async {
    await database.execute("""CREATE TABLE IF NOT EXISTS tbl_app_web_info (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      web_url            TEXT    NOT NULL ,
      app_web_name       TEXT    NOT NULL ,
      username           TEXT    NULL DEFAULT NULL ,
      password           TEXT    NULL DEFAULT NULL ,
      memo               TEXT    NULL DEFAULT NULL ,
      createdAt          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc')),
      updatedAt          TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc'))
    )
    """);
  }

  /// webinfo.db 열기. tbl_web_info, tbl_onboard_info, tbl_app_web_info 사용.
  static Future<sql.Database> webDB() async {
    return sql.openDatabase(
      'webinfo.db',
      version: 3,
      onCreate: (sql.Database database, int version) async {
        await _createWebTables(database);
      },
      onUpgrade: (sql.Database database, int oldVersion, int newVersion) async {
        if (oldVersion < 3) {
          await _createAppWebInfoTableIfMissing(database);
        }
      },
    );
  }

  // ----- tbl_web_info -----
  static Future<int> createWebInfo(
    String? caption,
    String? webUrl,
    String? tag,
  ) async {
    final db = await SQLHelper.webDB();
    final id = await db.rawInsert(
      'INSERT OR REPLACE INTO tbl_web_info (caption, web_url, tag) VALUES (?, ?, ?)',
      [caption, webUrl, tag],
    );
    return id;
  }

  static Future<int> editWebInfo(String? webUrl, String? tag, int id) async {
    final db = await SQLHelper.webDB();
    return db.rawUpdate(
      'UPDATE tbl_web_info SET web_url = ?, tag = ? WHERE id = ?',
      [webUrl, tag, id],
    );
  }

  static Future<List<Map<String, dynamic>>> getWebInfos() async {
    final db = await SQLHelper.webDB();
    return db.rawQuery('''
      SELECT * FROM tbl_web_info
      ORDER BY used_cnt DESC,
        CASE tag WHEN 'g' THEN 0 WHEN 'd' THEN 1 WHEN 'w' THEN 2 WHEN 'm' THEN 3 WHEN 'e' THEN 4 ELSE 5 END ASC,
        createdAt DESC
    ''');
  }

  static Future<List<Map<String, dynamic>>> getWebInfo(int id) async {
    final db = await SQLHelper.webDB();
    return db.rawQuery('SELECT * FROM tbl_web_info WHERE id = ? LIMIT 1', [id]);
  }

  static Future<List<Map<String, dynamic>>> chkCaption(String pWebUrl) async {
    final db = await SQLHelper.webDB();
    return db.query(
      'tbl_web_info',
      where: 'web_url = ?',
      whereArgs: [pWebUrl],
      limit: 1,
    );
  }

  static Future<List<Map<String, dynamic>>> getMaxUsedCnt() async {
    final db = await SQLHelper.webDB();
    return db.rawQuery('SELECT Max(used_cnt) as max_order FROM tbl_web_info');
  }

  static Future<int> updateMaxUsedCnt(int id, int pMaxUsedCnt) async {
    final db = await SQLHelper.webDB();
    return db.rawUpdate(
      'UPDATE tbl_web_info SET used_cnt = ? + 1 WHERE id = ?',
      [pMaxUsedCnt, id],
    );
  }

  static Future<int> updateUsedCnt(int id) async {
    final db = await SQLHelper.webDB();
    return db.rawUpdate(
      'UPDATE tbl_web_info SET used_cnt = used_cnt + 1 WHERE id = ?',
      [id],
    );
  }

  static Future<void> deleteWebUrl(int id) async {
    final db = await SQLHelper.webDB();
    try {
      await db.rawDelete('DELETE FROM tbl_web_info WHERE id = ?', [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  // ----- tbl_onboard_info -----
  static Future<int> createOnboardInfo(int? pIsOnboard) async {
    final db = await SQLHelper.webDB();
    return db.rawInsert(
      'INSERT OR REPLACE INTO tbl_onboard_info (is_onboarded) VALUES (?)',
      [pIsOnboard],
    );
  }

  static Future<List<Map<String, dynamic>>> getOnboardInfo() async {
    final db = await SQLHelper.webDB();
    return db.rawQuery('SELECT is_onboarded FROM tbl_onboard_info LIMIT 1');
  }

  // ----- tbl_app_web_info (로그인 정보) -----
  static Future<List<Map<String, dynamic>>> getAppWebLoginInfos(
    String webUrl,
  ) async {
    final db = await SQLHelper.webDB();
    return db.query(
      'tbl_app_web_info',
      where: 'web_url = ?',
      whereArgs: [webUrl],
      orderBy: 'updatedAt DESC',
    );
  }

  static Future<void> saveAppWebLoginInfo({
    int? id,
    required String webUrl,
    required String appWebName,
    String? username,
    String? password,
    String? memo,
  }) async {
    final db = await SQLHelper.webDB();
    final now = DateTime.now().toUtc().toIso8601String().replaceFirst(
      '.000',
      '',
    );
    if (id != null && id > 0) {
      await db.update(
        'tbl_app_web_info',
        {
          'username': username ?? '',
          'password': password ?? '',
          'memo': memo ?? '',
          'updatedAt': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert('tbl_app_web_info', {
        'web_url': webUrl,
        'app_web_name': appWebName,
        'username': username ?? '',
        'password': password ?? '',
        'memo': memo ?? '',
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  static Future<void> deleteAppWebLoginInfo(int id) async {
    final db = await SQLHelper.webDB();
    await db.delete('tbl_app_web_info', where: 'id = ?', whereArgs: [id]);
  }

  // ================== //

  /// tbl_my_application_info 테이블에 데이터가 1건 이상 있으면 true, 없으면 false 반환.
  /// "나의 앱" 화면 최초 진입 시 DB 초기화 여부 확인에 사용.
  static Future<bool> hasMyApps() async {
    final db = await SQLHelper.appMngmntDB();

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS cnt
        FROM tbl_my_application_info
    ''');

    final cnt = (result.first['cnt'] as int?) ?? 0;
    return cnt > 0;
  }

  /// tbl_group_info 테이블에 데이터가 1건 이상 있으면 true, 없으면 false 반환.
  /// "나의 앱" 화면 최초 진입 시 DB 초기화 여부 확인에 사용.
  static Future<bool> hasMyGroups() async {
    final db = await SQLHelper.appMngmntDB();

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS cnt
        FROM tbl_group_info
    ''');

    final cnt = (result.first['cnt'] as int?) ?? 0;
    return cnt > 0;
  }

  /// 앱 이름과 패키지명을 분석하여 앱 분류(그룹) 정보가 담긴 Map 을 생성하여 반환.
  ///
  /// 작업 순서:
  ///   1. 패키지명을 '.' 기준으로 최대 5개 파트로 분리
  ///   2. 자사 앱(com.modamtech.app_wallet_app) 이면 빈 Map 반환 (목록 제외)
  ///   3. 패키지 파트를 분석하여 app_kind(U/I/S) 와 app_user_group 코드 결정
  ///      - I10: Google, I20: Samsung, I30: SEC, S1: Android 시스템
  ///      - U01: 정보기관, U11: 은행, U12: 카드, U20: Kakao, U30: KT/SNS ...
  ///   4. 분류 정보가 담긴 Map 반환 (app_num, app_order, app_kind, app_user_group 등)
  static Future<Map<String, dynamic>> makeIntrnAppListData(
    String pAppName,
    String pPackageName,
  ) async {
    Map<String, dynamic> item = {};

    String strAppOrder = "";
    String strAppKind = "";
    String strAppUserGroup = "";
    String strAppName = pAppName;
    String strPackageName = pPackageName;

    String strPackagePart1 = "";
    String strPackagePart2 = "";
    String strPackagePart3 = "";
    String strPackagePart4 = "";
    String strPackagePart5 = "";

    var arrPackageParts = strPackageName.split(".");

    if (strPackageName == "com.modamtech.app_wallet_app") {
      return item;
    }
    try {
      if (arrPackageParts.isNotEmpty) {
        strPackagePart1 = arrPackageParts[0].toLowerCase();
      }
      if (arrPackageParts.length > 1) {
        strPackagePart2 = arrPackageParts[1].toLowerCase();
      }
      if (arrPackageParts.length > 2) {
        strPackagePart3 = arrPackageParts[2].toLowerCase();
      }
      if (arrPackageParts.length > 3) {
        strPackagePart4 = arrPackageParts[3].toLowerCase();
      }
      if (arrPackageParts.length > 4) {
        strPackagePart5 = arrPackageParts[4].toLowerCase();
      }
    } catch (e) {
      print("ERROR");
      return item;
    }

    // 구글앱 (group_code = "G")
    if (strPackagePart1 == "com" && strPackagePart2 == "google") {
      strAppOrder = "1";
      strAppKind = "G";
      strAppUserGroup = "G01";

      // 삼성 일반앱 (group_code = "X", order 1)
    } else if (strPackagePart1 == "com" && strPackagePart2 == "samsung") {
      strAppOrder = "1";
      strAppKind = "X";
      strAppUserGroup = "X01";

      // 삼성 시스템앱 (group_code = "X", order 2)
    } else if (strPackagePart1 == "com" && strPackagePart2 == "sec") {
      strAppOrder = "2";
      strAppKind = "X";
      strAppUserGroup = "X02";

      // 안드로이드 시스템 (group_code = "S")
    } else if (strPackagePart1 == "com" && strPackagePart2 == "android") {
      strAppOrder = "1";
      strAppKind = "S";
      strAppUserGroup = "S01";

      // 정부기관 (group_code = "I") - kr.go.*
    } else if (strPackagePart1 == "kr" && strPackagePart2 == "go") {
      strAppOrder = "1";
      strAppKind = "I";
      strAppUserGroup = "I01";

      // 은행
    } else if (strPackagePart2.contains("bank") ||
        strPackagePart3.contains("bank") ||
        strPackagePart4.contains("bank") ||
        strPackagePart2 == "wr") {
      strAppOrder = "1";
      strAppKind = "B";
      strAppUserGroup = "B01";

      // 증권
    } else if (strPackagePart2.contains("sec") ||
        strPackagePart2.contains("securities") ||
        strPackagePart3.contains("securities") ||
        strPackagePart2.contains("stock") ||
        strPackagePart2.contains("invest")) {
      strAppOrder = "3";
      strAppKind = "B";
      strAppUserGroup = "B03";

      // 카드
    } else if (strPackagePart2.contains("card") ||
        strPackagePart3.contains("card") ||
        strPackagePart2.contains("pay")) {
      strAppOrder = "2";
      strAppKind = "B";
      strAppUserGroup = "B02";

      // SNS
    } else if (strPackagePart2.contains("instagram") ||
        strPackagePart2.contains("facebook") ||
        strPackagePart2.contains("twitter") ||
        strPackagePart2.contains("discord") ||
        strPackagePart2.contains("telegram") ||
        strPackagePart3.contains("telegram") ||
        strPackagePart2.contains("tiktok") ||
        strPackagePart2.contains("musically") || // 틱톡
        (strPackagePart2.contains("kakao") &&
            strPackagePart3.contains("talk")) ||
        (strPackagePart2.contains("naver") &&
            strPackagePart3.contains("line")) ||
        (strPackagePart2.contains("naver") &&
            strPackagePart3.contains("band"))) {
      strAppOrder = "1";
      strAppKind = "M"; // SNS (group_code = "M")
      strAppUserGroup = "M01";

      // 통신
    } else if (strPackagePart2.contains("kt") ||
        strPackagePart2 == "olleh" ||
        strPackagePart3.contains("kt")) {
      strAppOrder = "1";
      strAppKind = "C";
      strAppUserGroup = "C01";

      // SKT
    } else if (strPackagePart2.contains("skt") ||
        strPackagePart2.contains("sktelecom") ||
        strPackagePart2.contains("tms") ||
        strPackagePart3.contains("skt")) {
      strAppOrder = "2";
      strAppKind = "C";
      strAppUserGroup = "C02";

      // LGU+
    } else if (strPackagePart2.contains("lguplus") ||
        strPackagePart2.contains("lgu")) {
      strAppOrder = "3";
      strAppKind = "C";
      strAppUserGroup = "C03";

      // 기타 (group_code = "E")
    } else {
      strAppOrder = "1";
      strAppKind = "E";
      strAppUserGroup = "E01";
    }

    item["app_num"] = 0;
    item["app_order"] = strAppOrder;
    item["app_kind"] = strAppKind;
    item["app_user_group"] = strAppUserGroup;
    item["app_opening"] = 0;
    item["app_use_period"] = 0;
    item["is_fixed_app"] = 0;
    item["app_name"] = strAppName;
    item["package_name"] = strPackageName;
    item["package_part1"] = strPackagePart1;
    item["package_part2"] = strPackagePart2;
    item["package_part3"] = strPackagePart3;
    item["package_part4"] = strPackagePart4;
    item["package_part5"] = strPackagePart5;

    return item;
  }

  /// 캐시된 전체 앱 목록을 pKind 기준으로 필터링하여 분류 데이터 목록을 반환.
  /// DB 조회 없이 메모리(캐시) 기반으로 동작 (DB 방식에서 List 방식으로 변경된 함수).
  ///
  /// 작업 순서:
  ///   1. pAllApps(캐시 앱 목록) 를 순회하며 각 앱에 대해 [makeIntrnAppListData] 호출
  ///   2. pKind == 'A' 이면 전체 추가, 아니면 app_kind 가 pKind 와 일치하는 것만 추가
  ///   3. 필터링된 분류 데이터 목록 반환
  static Future<List<Map<String, dynamic>>> initIntrnAppListData(
    String pKind,
    String pUserGroup,
    List<CachedApplication> pAllApps,
  ) async {
    List<Map<String, dynamic>> makeAppsFromList = [];
    Map<String, dynamic> appFromMap = {};

    // List<Application> apps = await DeviceApps.getInstalledApplications(
    //   includeAppIcons: true,
    //   includeSystemApps: true,
    //   onlyAppsWithLaunchIntent: true,
    // );

    for (var app in pAllApps) {
      appFromMap = await makeIntrnAppListData(app.appName, app.packageName);

      if (pKind == 'A') {
        makeAppsFromList.add(appFromMap);
      } else if (appFromMap["app_kind"] == pKind) {
        makeAppsFromList.add(appFromMap);
      }
    }

    return makeAppsFromList;
  }

  /// tbl_my_application_info 에서 특정 앱(app_name + package_name) 레코드를 삭제.
  /// 삭제된 행 수를 반환 (성공 시 1, 없으면 0).
  static Future<int> deleteMyIntrnAppInfo(
    String pAppName,
    String pPackageName,
  ) async {
    final db = await SQLHelper.appMngmntDB();

    // Update SQL query string
    String sql = '''
    DELETE FROM tbl_my_application_info
     WHERE app_name = ? 
       AND package_name = ? 
    ''';

    // Execute the query and return the result
    int result = await db.rawUpdate(sql, [pAppName, pPackageName]);

    return result;
  }

  /// 특정 앱의 is_fixed_app 값을 0→1 또는 1→0 으로 토글하여 고정/해제 처리.
  /// 영향받은 행 수를 반환.
  static Future<int> fixMyIntrnAppInfo(
    String pAppName,
    String pPackageName,
  ) async {
    final db = await SQLHelper.appMngmntDB();

    // Update SQL query string
    String sql = '''
    UPDATE tbl_my_application_info
       SET is_fixed_app = CASE WHEN is_fixed_app = 0 THEN 1 ELSE 0 END
     WHERE app_name = ? 
       AND package_name = ? 
    ''';

    // Execute the query and return the result
    int result = await db.rawUpdate(sql, [pAppName, pPackageName]);

    return result;
  }

  /// 특정 앱의 그룹 정보(app_order, app_kind, app_user_group) 를 변경.
  /// 영향받은 행 수를 반환.
  static Future<int> changeMyGroupInfo(
    String pAppName,
    String pPackageName,
    String pAppOrder,
    String pAppKind,
    String pAppUserGroup,
  ) async {
    final db = await SQLHelper.appMngmntDB();

    // Update SQL query string
    String sql = '''
    UPDATE tbl_my_application_info
       SET app_order = ?
         , app_kind  = ? 
         , app_user_group  = ? 
     WHERE app_name = ? 
       AND package_name = ? 
    ''';

    // Execute the query and return the result
    int result = await db.rawUpdate(sql, [
      pAppOrder,
      pAppKind,
      pAppUserGroup,
      pAppName,
      pPackageName,
    ]);

    return result;
  }

  /// 앱 실행 시 사용 이력을 DB 에 업데이트하고 전체 앱의 사용 경과일을 재계산.
  ///
  /// 작업 순서:
  ///   1. 현재 최대 app_num 조회
  ///   2. 해당 앱의 app_num(최대값+1), app_opening=1, use_period_at=현재시각 으로 UPDATE
  ///   3. 전체 앱의 app_use_period = 오늘 - use_period_at 로 일괄 재계산
  ///   4. 전체 앱의 app_num·app_name·package_name·app_use_period·is_fixed_app 조회 후 반환
  static Future<List<Map<String, dynamic>>> changeOpenStatusInfo(
    String pAppName,
    String pPackageName,
  ) async {
    final db = await SQLHelper.appMngmntDB();

    List<Map<String, dynamic>> tmpMaxNum;
    List<Map<String, dynamic>> tmpAppUsePeriod;

    String sqlMaxNum = '''
            SELECT COALESCE(MAX(app_num), 0) as max_num
              FROM tbl_my_application_info
            ''';
    // Execute the query and return the result
    tmpMaxNum = await db.rawQuery(sqlMaxNum);

    int maxNum = tmpMaxNum[0]["max_num"];

    maxNum = maxNum + 1;

    // Update SQL query string
    String sql_update = '''
    UPDATE tbl_my_application_info
       SET app_num = ?,
           app_opening = ?,
           use_period_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc')
     WHERE app_name = ?
       AND package_name = ?
    ''';

    await db.rawUpdate(sql_update, [maxNum, 1, pAppName, pPackageName]);

    // Update SQL query string
    sql_update = '''
    UPDATE tbl_my_application_info
       SET app_use_period = ROUND(julianday(date('now')) - julianday(strftime('%Y-%m-%d', use_period_at)))
    ''';

    await db.rawUpdate(sql_update);

    String sqlAppUsePeriod = '''
            SELECT  app_num, app_name, package_name, app_use_period, is_fixed_app
              FROM tbl_my_application_info
            ''';
    // Execute the query and return the result
    tmpAppUsePeriod = await db.rawQuery(sqlAppUsePeriod);

    return tmpAppUsePeriod;
  }

  /// tbl_my_application_info 에서 현재 최대 app_num 값을 조회하여 반환.
  /// 데이터 없을 때는 0 반환 (COALESCE 처리).
  static Future<int> selectNumStatusInfo(
    String pAppName,
    String pPackageName,
  ) async {
    final db = await SQLHelper.appMngmntDB();

    List<Map<String, dynamic>> tmpMaxNum;

    // COALESCE 은 결과가 null 일때 0 으로 변경하는 기능
    String sqlMaxNum = '''
            SELECT COALESCE(MAX(app_num), 0) as max_num 
              FROM tbl_my_application_info
            ''';
    // Execute the query and return the result
    tmpMaxNum = await db.rawQuery(sqlMaxNum);

    int maxNum = tmpMaxNum[0]["max_num"];

    return maxNum;
  }

  /// is_first_input 플래그를 일괄 업데이트.
  /// pOrder == 0 이면 전체 is_first_input = 0, 그 외면 is_first_input = 1 로 설정.
  static Future<int> updateMyIntrnAppStts(int pOrder) async {
    final db = await SQLHelper.appMngmntDB();
    String sql = "";

    // Update SQL query string
    if (pOrder == 0) {
      sql = '''
      UPDATE tbl_my_application_info
        SET is_first_input = 0
      WHERE is_first_input = 1
      ''';
    } else {
      sql = '''
      UPDATE tbl_my_application_info
        SET is_first_input = 1
      WHERE is_first_input = 0
      ''';
    }

    // Execute the query and return the result
    int result = await db.rawUpdate(sql);

    return result;
  }

  /// "나의 앱" 목록 전체를 DB 에서 조회하여 반환.
  /// 정렬: is_fixed_app DESC → app_use_period ASC → app_num DESC → app_order → app_kind → app_user_group → app_name
  static Future<List<Map<String, dynamic>>> getMyAppsFromDB() async {
    final appMngmntDB = await SQLHelper.appMngmntDB();

    List<Map<String, dynamic>> result;
    String sql = "";

    // Create SQL query string
    // is_first_input 플래그와 상관없이 "나의 앱 리스트"에 저장된 모든 앱을 조회한다.
    sql = '''
          SELECT app_num, package_name, app_order, app_kind, app_user_group, app_opening, app_use_period, is_fixed_app
            FROM tbl_my_application_info
           ORDER BY is_fixed_app DESC, app_use_period, app_num  DESC, app_order, app_kind, app_user_group, app_name 
          ''';
    // Execute the query and return the result
    result = await appMngmntDB.rawQuery(sql);

    return result;
  }

  /// tbl_group_info 에서 group_name, group_code, group_order, app_order 목록을 group_order 오름차순으로 조회.
  /// use_yn = 'Y' 인 활성 그룹만 반환.
  /// app_order: 앱 필터링 시 tbl_my_application_info.app_order 와 매칭에 사용
  static Future<List<Map<String, dynamic>>> getAllGroupList() async {
    final db = await SQLHelper.appMngmntDB();
    const sql = '''
      SELECT group_name, group_code, group_order, app_order
        FROM tbl_group_info
       WHERE TRIM(group_name) != ''
         AND use_yn = 'Y'
       ORDER BY
         CASE
           WHEN group_code = 'A' AND CAST(app_order AS INTEGER) = 1 THEN 0
           WHEN group_code = 'A' AND CAST(app_order AS INTEGER) > 1 THEN 1
           ELSE 2
         END,
         CASE
           WHEN group_code = 'A' AND CAST(app_order AS INTEGER) > 1
             THEN CAST(app_order AS INTEGER)
           ELSE CAST(group_order AS INTEGER)
         END
    ''';
    final rows = await db.rawQuery(sql);
    return rows
        .map<Map<String, dynamic>>(
          (r) => {
            'group_name': r['group_name'] as String? ?? '',
            'group_code': r['group_code'] as String? ?? '',
            'group_order': r['group_order'],
            'app_order': r['app_order'],
          },
        )
        .toList();
  }

  /// tbl_group_info 에서 모든 그룹 조회 (use_yn 무관).
  /// 그룹 관리 Drawer에서 사용 안 함(use_yn='N') 그룹도 표시.
  static Future<List<Map<String, dynamic>>>
  getAllGroupListForManagement() async {
    final db = await SQLHelper.appMngmntDB();
    const sql = '''
      SELECT group_name, group_code, group_order, app_order, use_yn
        FROM tbl_group_info
       WHERE TRIM(group_name) != ''
       ORDER BY
         CASE
           WHEN group_code = 'A' AND CAST(app_order AS INTEGER) = 1 THEN 0
           WHEN group_code = 'A' AND CAST(app_order AS INTEGER) > 1 THEN 1
           ELSE 2
         END,
         CASE
           WHEN group_code = 'A' AND CAST(app_order AS INTEGER) > 1
             THEN CAST(app_order AS INTEGER)
           ELSE CAST(group_order AS INTEGER)
         END
    ''';
    final rows = await db.rawQuery(sql);
    return rows
        .map<Map<String, dynamic>>(
          (r) => {
            'group_name': r['group_name'] as String? ?? '',
            'group_code': r['group_code'] as String? ?? '',
            'group_order': r['group_order'],
            'app_order': r['app_order'],
            'use_yn': r['use_yn'] as String? ?? 'Y',
          },
        )
        .toList();
  }

  /// 사용자 정의 그룹(group_code='A') 삭제.
  /// group_code != 'A' 이면 삭제 불가. "전체" 그룹은 삭제 불가.
  /// 해당 그룹에 속한 앱이 1건이라도 있으면 삭제 불가.
  /// 반환: 'ok' 성공, 'not_user_group' A가 아님, 'has_apps' 앱 존재, 'not_found' 그룹 없음
  static Future<String> deleteUserGroup(String pGroupName) async {
    final db = await SQLHelper.appMngmntDB();
    final groupInfo = await getGroupInfoByName(pGroupName);
    if (groupInfo == null) return 'not_found';
    if (pGroupName.trim() == '전체') return 'not_user_group';
    final groupCode = groupInfo['group_code']?.toString() ?? '';
    if (groupCode != 'A') return 'not_user_group';
    final appOrder = groupInfo['app_order']?.toString() ?? '0';
    final appUserGroup = groupCode + appOrder.padLeft(2, '0');
    final cntResult = await db.rawQuery(
      '''
      SELECT COUNT(*) AS cnt FROM tbl_my_application_info
       WHERE app_user_group = ?
      ''',
      [appUserGroup],
    );
    final cnt = (cntResult.first['cnt'] as int?) ?? 0;
    if (cnt > 0) return 'has_apps';
    await db.rawDelete(
      'DELETE FROM tbl_group_info WHERE group_name = ? AND group_code = ?',
      [pGroupName, groupCode],
    );
    return 'ok';
  }

  /// "나의 앱" 목록에 앱을 신규 추가. 이미 존재하면 사용 이력만 업데이트.
  ///
  /// 작업 순서:
  ///   1. appDataWithAll 에서 해당 앱 탐색
  ///   2. DB 에 이미 존재하면 → [changeOpenStatusInfo] 호출 후 null 반환
  ///   3. 없으면 → 현재 최대 app_num+1 을 새 app_num 으로 설정
  ///   4. pType == "OPN" 이면 app_opening=1, 아니면 0 으로 INSERT
  ///   5. 신규 추가 시 appDataWithMine 에 넣을 Map 반환, 기존 존재 시 null 반환
  static Future<Map<String, dynamic>?> addMyIntrnAppInfo(
    String pAppName,
    String pPackageName,
    String pType,
  ) async {
    final appMngmntDB = await SQLHelper.appMngmntDB();

    List<Map<String, dynamic>> tmpMaxCnt;
    CommonHelper commonHelper = CommonHelper.instance;

    for (var _item in commonHelper.appDataWithAll) {
      if (_item["app_name"] == pAppName &&
          _item["package_name"] == pPackageName) {
        String sqlExist = '''
            SELECT count(app_num) as exist_cnt
              FROM tbl_my_application_info
             WHERE package_name = ? 
            ''';
        tmpMaxCnt = await appMngmntDB.rawQuery(sqlExist, [pPackageName]);

        final existCnt = tmpMaxCnt[0]["exist_cnt"] as int? ?? 0;

        if (existCnt > 0) {
          changeOpenStatusInfo(pAppName, pPackageName);
          return null;
        }

        String sql = '''
            SELECT COALESCE(MAX(app_num), 0) as max_num
              FROM tbl_my_application_info
            ''';
        tmpMaxCnt = await appMngmntDB.rawQuery(sql);

        final maxNum = tmpMaxCnt[0]["max_num"] as int? ?? 0;
        final tmpNum = maxNum + 1;

        if (pType == "OPN") {
          _item["app_opening"] = 1;
        } else {
          _item["app_opening"] = 0;
        }

        sql = '''
              INSERT INTO tbl_my_application_info
              (app_num, app_order, app_kind, app_user_group, app_opening, app_use_period, app_name, package_name, package_part1, package_part2, package_part3, package_part4, package_part5, is_first_input, is_fixed_app)
              VALUES
              (?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?, 0, 0)
            ''';

        await appMngmntDB.rawInsert(sql, [
          tmpNum,
          _item["app_order"],
          _item["app_kind"],
          _item["app_user_group"],
          _item["app_opening"],
          _item["app_name"],
          _item["package_name"],
          _item["package_part1"],
          _item["package_part2"],
          _item["package_part3"],
          _item["package_part4"],
          _item["package_part5"],
        ]);

        // appDataWithMine 에 추가할 Map 생성 (원본 _item 수정 방지를 위해 복사)
        final newMap = Map<String, dynamic>.from(_item);
        newMap["app_num"] = tmpNum;
        newMap["app_use_period"] = 0;
        newMap["is_fixed_app"] = 0;
        return newMap;
      }
    }

    return null;
  }

  /// tbl_group_info 테이블에 그룹 정보를 추가.
  /// [pGroupOrder] 순서(null 이면 자동), [pGroupName] 그룹명, [pGroupCode] 그룹 코드.
  static Future<void> addGroupInfo(
    int? pGroupOrder,
    String pGroupName,
    int? pAppOrder,
    String pGroupCode,
  ) async {
    final db = await SQLHelper.appMngmntDB();

    // pGroupOrder 가 null 이면 현재 등록된 그룹 수 + 1 로 자동 산출
    final int resolvedOrder;
    if (pGroupOrder != null) {
      resolvedOrder = pGroupOrder;
    } else {
      final cntResult = await db.rawQuery(
        'SELECT COUNT(*) AS cnt FROM tbl_group_info',
      );
      resolvedOrder = ((cntResult.first['cnt'] as int?) ?? 0) + 1;
    }

    const sql = '''
      INSERT INTO tbl_group_info
        (group_name, group_order, app_order, group_code, 
         use_period_at, createdAt)
      VALUES
        (?, ?, ?, ?, 
         strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc'),
         strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc'))
    ''';

    await db.rawInsert(sql, [
      pGroupName,
      resolvedOrder.toString(),
      pAppOrder?.toString() ?? resolvedOrder.toString(),
      pGroupCode,
    ]);
  }

  /// tbl_group_info 에서 MAX(app_order) 값을 조회. 없으면 0 반환.
  static Future<int> getMaxAppOrderFromGroupInfo() async {
    final db = await SQLHelper.appMngmntDB();
    final result = await db.rawQuery('''
      SELECT COALESCE(MAX(CAST(app_order AS INTEGER)), 0) AS max_order
        FROM tbl_group_info
      ''');
    return (result.first['max_order'] as int?) ?? 0;
  }

  /// group_name 에 해당하는 행의 use_yn 을 Y↔N 토글.
  /// 영향받은 행 수 반환 (0=해당 그룹 없음).
  static Future<int> toggleGroupUseYn(String pGroupName) async {
    final db = await SQLHelper.appMngmntDB();
    const sql = '''
      UPDATE tbl_group_info
         SET use_yn = CASE WHEN TRIM(use_yn) = 'Y' THEN 'N' ELSE 'Y' END
           , use_period_at = strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc')
       WHERE group_name = ?
    ''';
    return db.rawUpdate(sql, [pGroupName]);
  }

  /// 사용자 정의 그룹을 tbl_group_info 에 신규 추가.
  /// group_code='A', app_order=최대값+1, group_order=자동.
  static Future<void> createUserGroup(String pGroupName) async {
    final db = await SQLHelper.appMngmntDB();
    final maxAppOrder = await getMaxAppOrderFromGroupInfo();
    final newAppOrder = maxAppOrder + 1;

    final cntResult = await db.rawQuery(
      'SELECT COUNT(*) AS cnt FROM tbl_group_info',
    );
    final groupOrder = ((cntResult.first['cnt'] as int?) ?? 0) + 1;

    const sql = '''
      INSERT INTO tbl_group_info
        (group_name, group_order, app_order, group_code,
         use_period_at, createdAt)
      VALUES
        (?, ?, ?, 'A',
         strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc'),
         strftime('%Y-%m-%dT%H:%M:%fZ', 'now', 'utc'))
    ''';
    await db.rawInsert(sql, [
      pGroupName,
      groupOrder.toString(),
      newAppOrder.toString(),
    ]);
  }

  /// 특정 앱(app_name + package_name) 이 DB 에 존재하면 true, 없으면 false 반환.
  /// LIMIT 1 로 빠르게 존재 여부만 확인.
  static Future<bool> isAppInDatabase(
    String pAppName,
    String pPackageName,
  ) async {
    final appMngmntDB = await SQLHelper.appMngmntDB();

    // Create SQL query string
    String sql = '''
    SELECT 1 as is_exist 
      FROM tbl_my_application_info
     WHERE app_name = ? 
       AND package_name = ? 
    LIMIT 1
    ''';

    // Execute the query and return the result
    List<Map<String, dynamic>> result = await appMngmntDB.rawQuery(sql, [
      pAppName,
      pPackageName,
    ]);

    if (result.isEmpty) {
      return false;
    }

    if (result[0]["is_exist"] == 1) {
      return true;
    } else {
      return false;
    }
  }

  /// group_name 으로 tbl_group_info 를 조회하여 app_order, group_code, use_yn 반환.
  /// 일치하는 행이 없으면 null 반환.
  /// 그룹 변경 시 앱에 저장할 app_order 값으로 사용됨.
  static Future<Map<String, dynamic>?> getGroupInfoByName(
    String pGroupName,
  ) async {
    final db = await SQLHelper.appMngmntDB();

    final result = await db.rawQuery(
      '''
      SELECT app_order, group_code, use_yn
        FROM tbl_group_info
       WHERE group_name = ?
       LIMIT 1
      ''',
      [pGroupName],
    );

    if (result.isEmpty) return null;
    return result.first;
  }
}
