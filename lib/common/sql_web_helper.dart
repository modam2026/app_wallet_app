import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLWebHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE tbl_web_info (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    	caption            TEXT    NOT NULL ,
    	web_url            TEXT    NULL DEFAULT NULL ,
    	tag                TEXT    NULL DEFAULT NULL ,
      used_cnt           INTEGER NOT NULL DEFAULT 0 ,
      createdAt    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP 
    )
    """);

    await database.execute("""CREATE TABLE tbl_onboard_info (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      is_onboarded INTEGER NOT NULL DEFAULT 0
    )
    """);
  }
// id: the id of a item
// title, description: name and description of your activity
// created_at: the time that the item was created. It will be automatically handled by SQLite

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'webinfo.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  // Create new voca
  static Future<int> createWebInfo(
      String? caption, String? webUrl, String? tag) async {
    final db = await SQLWebHelper.db();

    // Create SQL query string
    String sql = '''
    INSERT OR REPLACE INTO tbl_web_info (caption, web_url, tag)
    VALUES (?, ?, ?)
  ''';

    // Execute the query and return the id of the inserted row
    int id = await db.rawInsert(sql, [caption, webUrl, tag]);
    return id;
  }

  // Create new voca
  static Future<int> editWebInfo(String? webUrl, String? tag, int id) async {
    final db = await SQLWebHelper.db();

    // Create SQL query string
    String sql = '''
    UPDATE tbl_web_info
    SET web_url = ? 
      , tag     = ? 
    WHERE id = ?
    ''';

    // Execute the query and return the id of the inserted row
    int rcId = await db.rawUpdate(sql, [webUrl, tag, id]);
    return rcId;
  }

  // Read all voca
  static Future<List<Map<String, dynamic>>> getWebInfos() async {
    final db = await SQLWebHelper.db();

    // Create SQL query string
    String sql = '''
    SELECT * FROM tbl_web_info
    ORDER BY used_cnt DESC,
        CASE tag 
            WHEN 'g' THEN 0
            WHEN 'd' THEN 1
            WHEN 'w' THEN 2
            WHEN 'm' THEN 3
            WHEN 'e' THEN 4
            ELSE 5
        END ASC,
    createdAt DESC;
  ''';

    // Execute the query and return the result directly
    return await db.rawQuery(sql);
  }

  static Future<List<Map<String, dynamic>>> getWebInfo(int id) async {
    final db = await SQLWebHelper.db();

    // Create SQL query string
    String sql = '''
    SELECT * FROM tbl_web_info
    WHERE id = ?
    LIMIT 1
  ''';

    // Execute the query and return the result
    return await db.rawQuery(sql, [id]);
  }

  static Future<List<Map<String, dynamic>>> chkCaption(String pWebUrl) async {
    final db = await SQLWebHelper.db();
    return db.query('tbl_web_info',
        where: "web_url = ?", whereArgs: [pWebUrl], limit: 1);
  }

  static Future<List<Map<String, dynamic>>> getMaxUsedCnt() async {
    final db = await SQLWebHelper.db();

    // Create SQL query string
    String sql = '''
    SELECT Max(used_cnt) as max_order FROM tbl_web_info
  ''';

    // Execute the query and return the result
    return await db.rawQuery(sql);
  }

  // Update an item by id
  static Future<int> updateMaxUsedCnt(int id, int pMaxUsedCnt) async {
    final db = await SQLWebHelper.db();

    // Create SQL query string
    String sql = '''
    UPDATE tbl_web_info
    SET used_cnt = ? + 1
    WHERE id = ?
    ''';

    // Execute the query and return the result
    int result = await db.rawUpdate(sql, [pMaxUsedCnt, id]);
    return result;
  }

  // Update an item by id
  static Future<int> updateUsedCnt(int id) async {
    final db = await SQLWebHelper.db();

    // Create SQL query string
    String sql = '''
    UPDATE tbl_web_info
    SET used_cnt = used_cnt + 1
    WHERE id = ?
    ''';

    // Execute the query and return the result
    int result = await db.rawUpdate(sql, [id]);
    return result;
  }

  // Delete

  static Future<void> deleteWebUrl(int id) async {
    final db = await SQLWebHelper.db();
    try {
      // Create SQL query string
      String sql = '''
      DELETE FROM tbl_web_info
      WHERE id = ?
    ''';

      // Execute the query
      await db.rawDelete(sql, [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  // Create new voca
  static Future<int> createOnboardInfo(int? pIsOnboard) async {
    final db = await SQLWebHelper.db();

    // Create SQL query string
    String sql = '''
    INSERT OR REPLACE INTO tbl_onboard_info  (is_onboarded)
    VALUES (?)
  ''';

    // Execute the query and return the id of the inserted row
    int id = await db.rawInsert(sql, [pIsOnboard]);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getOnboardInfo() async {
    final db = await SQLWebHelper.db();

    // Create SQL query string
    String sql = '''
    SELECT is_onboarded FROM tbl_onboard_info 
    LIMIT 1
    ''';

    // Execute the query and return the result
    return await db.rawQuery(sql);
  }
}
