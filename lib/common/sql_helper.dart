import 'package:app_wallet_app/common/AppCache.dart';
import 'package:app_wallet_app/common/common_helper.dart';
import 'package:sqflite/sqflite.dart' as sql;
//import 'package:device_apps/device_apps.dart';

class SQLHelper {
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
  }

  // ******************* //
  // put application information to Sqlite
  // 2023.06.03
  // ******************* //

  // created_at: 2023.06.03
  static Future<sql.Database> appMngmntDB() async {
    return sql.openDatabase(
      'db_app_management.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createIntrnAppTables(database);
      },
    );
  }

  // 현재 "나의 앱 리스트" 테이블에 데이터가 있는지 여부를 반환
  static Future<bool> hasMyApps() async {
    final db = await SQLHelper.appMngmntDB();

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS cnt
        FROM tbl_my_application_info
    ''');

    final cnt = (result.first['cnt'] as int?) ?? 0;
    return cnt > 0;
  }

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
    //COMPANY / INST
    if (strPackagePart1 == "com" && strPackagePart2 == "google") {
      strAppOrder = "3";
      strAppKind = "I";
      strAppUserGroup = "I10";
    } else if (strPackagePart1 == "com" && strPackagePart2 == "samsung") {
      strAppOrder = "4";
      strAppKind = "I";
      strAppUserGroup = "I20";
    } else if (strPackagePart1 == "com" && strPackagePart2 == "sec") {
      strAppOrder = "4";
      strAppKind = "I";
      strAppUserGroup = "I30";
      // SYSTEM
    } else if (strPackagePart1 == "com" && strPackagePart2 == "android") {
      strAppOrder = "9";
      strAppKind = "S";
      strAppUserGroup = "S1";
      // 정보기관
    } else if (strPackagePart1.contains("go") ||
        strPackagePart2.contains("go")) {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U01";
      // 금융
    } else if (strPackagePart2.contains("bank") ||
        strPackagePart2 == "wr" ||
        strPackagePart3.contains("bank") ||
        strPackagePart4.contains("bank")) {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U11";
    } else if (strPackagePart2.contains("card") ||
        strPackagePart3.contains("card") ||
        strPackagePart4.contains("card")) {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U12";
    } else if (strPackagePart2.contains("kbsec")) {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U10";
      // 커뮤니티
    } else if (strPackagePart2.contains("kakao")) {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U20";
    } else if (strPackagePart2.contains("nhn")) {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U21";
    } else if (strPackagePart2.contains("daum")) {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U22";
    } else if (strPackagePart2.contains("netflix")) {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U23";
      // 통신
    } else if (strPackagePart2.contains("kt") ||
        strPackagePart3.contains("kt")) {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U30";
    } else if (strPackagePart2.contains("skt") ||
        strPackagePart2.contains("tms") ||
        strPackagePart3.contains("skt")) {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U40";
      // Microsoft
    } else if (strPackagePart2.contains("microsoft") ||
        strPackagePart3.contains("microsoft")) {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U40";
      // 사용자
    } else if (strPackagePart2 != "google" &&
        strPackagePart2 != "samsung" &&
        strPackagePart2 != "android") {
      strAppOrder = "1";
      strAppKind = "U";
      strAppUserGroup = "U90";
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

  // DB 방식이 아닌 List 객체 방식으로 변경된 함수
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

    // Execute the query and return the result
    int result = await db.rawUpdate(sql_update, [
      maxNum,
      1,
      pAppName,
      pPackageName,
    ]);

    // Update SQL query string
    sql_update = '''
    UPDATE tbl_my_application_info
       SET app_use_period = ROUND(julianday(date('now')) - julianday(strftime('%Y-%m-%d', use_period_at)))
    ''';

    // Execute the query and return the result
    result = await db.rawUpdate(sql_update);

    String sqlAppUsePeriod = '''
            SELECT  app_num, app_name, package_name, app_use_period, is_fixed_app
              FROM tbl_my_application_info
            ''';
    // Execute the query and return the result
    tmpAppUsePeriod = await db.rawQuery(sqlAppUsePeriod);

    return tmpAppUsePeriod;
  }

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

  // Create new sentence
  static Future<int> addMyIntrnAppInfo(
    String pAppName,
    String pPackageName,
    String pType,
  ) async {
    final appMngmntDB = await SQLHelper.appMngmntDB();

    int result = 0;
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
        // Execute the query and return the result
        tmpMaxCnt = await appMngmntDB.rawQuery(sqlExist, [pPackageName]);

        int existCnt = tmpMaxCnt[0]["exist_cnt"];

        if (existCnt > 0) {
          print("pPackageName is existing $pPackageName");
          changeOpenStatusInfo(pAppName, pPackageName);
          break;
        }

        String sql = '''
            SELECT COALESCE(MAX(app_num), 0) as max_num
              FROM tbl_my_application_info
            ''';
        // Execute the query and return the result
        tmpMaxCnt = await appMngmntDB.rawQuery(sql);

        int tmpNum = 0;
        int maxNum = tmpMaxCnt[0]["max_num"];

        if (pType == "OPN") {
          _item["app_opening"] = 1;
        } else {
          _item["app_opening"] = 0;
        }

        tmpNum = maxNum + 1;

        // Create SQL query string
        sql = '''
              INSERT INTO tbl_my_application_info
              (app_num, app_order, app_kind, app_user_group, app_opening, app_use_period, app_name, package_name, package_part1, package_part2, package_part3, package_part4, package_part5, is_first_input, is_fixed_app)
              VALUES
              (?, ?, ?, ?, ?, 0, ?, ?, ?, ?, ?, ?, ?, 0, 0)
            ''';

        // Execute the query and return the id of the inserted row
        result = await appMngmntDB.rawInsert(sql, [
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

        break;
      }
    }

    return result;
  }

  // Create new sentence
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
}
