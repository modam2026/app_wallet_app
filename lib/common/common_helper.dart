import 'package:app_wallet_app/common/AppCache.dart';
import 'package:app_wallet_app/common/app_constants.dart';
import 'package:app_wallet_app/common/sql_helper.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

class CommonHelper {
  List<Map<String, dynamic>> appDataWithAll = [];
  List<Map<String, dynamic>> appDataWithMine = [];
  List<Map<String, dynamic>> appDataWithUser = [];
  List<Map<String, dynamic>> appDataWithInst = [];
  List<Map<String, dynamic>> appDataWithSys = [];

  static CommonHelper? _instance;
  CommonHelper._();
  static CommonHelper get instance {
    return _instance ??= CommonHelper._();
  }

  Future<List<CachedApplication>> getListCachedApplication(
    List<Map<String, dynamic>> appData,
  ) async {
    List<CachedApplication> tmpAllApps = [];

    for (var _item in appData) {
      tmpAllApps.add(_item["cached_application"]);
    }
    return tmpAllApps;
  }

  Future<List<Map<String, dynamic>>> getCachedApplications(
    String pKind,
    String pUserGroup,
  ) async {
    List<Map<String, dynamic>> appDataWithApplication = [];

    List<CachedApplication> allApps = await AppCache.getCachedApps();

    // Convert allApps to a Map for quick lookup
    Map<String, CachedApplication> allAppsMap = {};
    for (var app in allApps) {
      allAppsMap[app.packageName] = app;
    }

    List<dynamic> appData;

    // 파일 목록을 LIST방식으로 생성하는 비동기 작업
    appData = await SQLHelper.initIntrnAppListData(pKind, pUserGroup, allApps);

    for (var _itemImmutable in appData) {
      Map<String, dynamic> appDataMap = Map.from(
        _itemImmutable,
      ); // _itemImmutable을 변경 가능한 Map으로 변환

      // Now we look up the app in the map, which is an O(1) operation
      var app = allAppsMap[appDataMap["package_name"]];
      if (app != null) {
        // 이제 _item은 변경 가능하므로, 아래 코드는 오류를 발생시키지 않습니다.
        appDataMap["cached_application"] = app;
        appDataWithApplication.add(appDataMap);
      }
    }

    allApps = [];
    appData = [];
    allAppsMap = {};

    return appDataWithApplication;
  }

  Future<int> initIntrnAppInfo() async {
    // 전체 앱 기준 데이터 (나의 앱/전체 앱 공통으로 사용)
    appDataWithAll = await getCachedApplications("A", "");
    // 분류별 데이터 (화면별 리스트용)
    appDataWithUser = await getCachedApplications("U", "");
    appDataWithInst = await getCachedApplications("I", "");
    appDataWithSys = await getCachedApplications("S", "");

    return 0;
  }

  Future<int> openApp(CachedApplication app) async {
    changeOpenStatus(app);
    await DeviceApps.openApp(app.packageName);
    return 0;
  }

  void deleteApp(CachedApplication appWithIcon) {
    SQLHelper.deleteMyIntrnAppInfo(
      appWithIcon.appName,
      appWithIcon.packageName,
    );

    int indexToRemove = appDataWithMine.indexWhere(
      (app) => app["cached_application"].packageName == appWithIcon.packageName,
    );
    if (indexToRemove != -1) {
      appDataWithMine.removeAt(indexToRemove);
    }
  }

  void fixingApp(CachedApplication appWithIcon) {
    SQLHelper.fixMyIntrnAppInfo(appWithIcon.appName, appWithIcon.packageName);

    int indexToFix = appDataWithMine.indexWhere(
      (app) => app["cached_application"].packageName == appWithIcon.packageName,
    );

    if (indexToFix != -1) {
      if (appDataWithMine[indexToFix]["is_fixed_app"] == 0) {
        appDataWithMine[indexToFix]["is_fixed_app"] = 1;
      } else {
        appDataWithMine[indexToFix]["is_fixed_app"] = 0;
      }
    }
  }

  void changeGroup(
    CachedApplication appWithIcon,
    String pAppOrder,
    String pAppKind,
    String pAppUserGroup,
  ) async {
    SQLHelper.changeMyGroupInfo(
      appWithIcon.appName,
      appWithIcon.packageName,
      pAppOrder,
      pAppKind,
      pAppUserGroup,
    );

    int indexToChange = appDataWithMine.indexWhere(
      (app) => app["cached_application"].packageName == appWithIcon.packageName,
    );

    if (indexToChange != -1) {
      appDataWithMine[indexToChange]["app_order"] = pAppOrder;
      appDataWithMine[indexToChange]["app_kind"] = pAppKind;
      appDataWithMine[indexToChange]["app_user_group"] = pAppUserGroup;
    }
  }

  void changeOpenStatus(CachedApplication appWithIcon) async {
    final appData = await SQLHelper.changeOpenStatusInfo(
      appWithIcon.appName,
      appWithIcon.packageName,
    );

    for (var _item in appData) {
      int indexToPeriod = appDataWithMine.indexWhere(
        (app) => app["cached_application"].packageName == _item["package_name"],
      );

      if (indexToPeriod != -1) {
        appDataWithMine[indexToPeriod]["app_num"] = _item["app_num"];
        appDataWithMine[indexToPeriod]["app_use_period"] =
            _item["app_use_period"];
        appDataWithMine[indexToPeriod]["is_fixed_app"] = _item["is_fixed_app"];
      }
    }

    int iNum = await SQLHelper.selectNumStatusInfo(
      appWithIcon.appName,
      appWithIcon.packageName,
    );

    int indexToChange = appDataWithMine.indexWhere(
      (app) => app["cached_application"].packageName == appWithIcon.packageName,
    );

    if (indexToChange != -1) {
      appDataWithMine[indexToChange]["app_num"] = iNum;
      appDataWithMine[indexToChange]["app_opening"] = 1;
    } else {
      await SQLHelper.addMyIntrnAppInfo(
        appWithIcon.appName,
        appWithIcon.packageName,
        "OPN",
      );
    }

    appDataWithMine.sort((a, b) {
      // Compare 'is_fixed_app' first
      int isFixedAppComparison = b['is_fixed_app'].compareTo(a['is_fixed_app']);

      // If 'is_fixed_app' values are equal, compare 'app_use_period'
      if (isFixedAppComparison == 0) {
        // Compare 'app_use_period'
        int usePeriodComparison = a['app_use_period'].compareTo(
          b['app_use_period'],
        );

        // If 'app_use_period' values are equal, compare 'num'
        if (usePeriodComparison == 0) {
          // Compare 'num'
          return b['app_num'].compareTo(a['app_num']);
        }

        return usePeriodComparison;
      }

      return isFixedAppComparison;
    });
  }

  void showConfirmationDialog(
    CachedApplication appWithIcon,
    BuildContext context,
    VoidCallback notifyStateChanged,
  ) {
    // DropdownButton<String> 위젯의 상태를 저장하기 위한 변수를 추가합니다.
    String dropdownValue = '전체';
    // DropdownButton<String>에서 사용할 항목을 선언합니다.
    final List<String> pageList = kMyAppGroupList;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            titlePadding: EdgeInsets.all(0),
            title: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('   + 변경사항 ', style: TextStyle(fontSize: 20)),
                      CloseButton(onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
                Divider(color: Colors.blueGrey),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      "그룹",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 1.0,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: dropdownValue,
                            icon: Icon(Icons.arrow_downward),
                            iconSize: 24,
                            elevation: 16,
                            onChanged: (String? newValue) {
                              setState(() {
                                dropdownValue = newValue ?? '전체';
                              });
                            },
                            items: pageList
                                .map<DropdownMenuItem<String>>(
                                  (String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.white38, // 버튼의 배경색을 변경
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ).copyWith(
                          foregroundColor: WidgetStateProperty.all<Color>(
                            Colors.black87,
                          ), // 버튼의 텍스트 및 아이콘 색상을 변경
                        ),
                    child: Text("그룹 변경", style: TextStyle(fontSize: 18)),
                    onPressed: () async {
                      String strAppOrder = "";
                      String strAppKind = "";
                      String strAppUserGroup = "";

                      if (dropdownValue == 'SNS') {
                        strAppOrder = "1";
                        strAppKind = "U";
                        strAppUserGroup = "U30";
                        // 정보기관
                      } else if (dropdownValue == '기관') {
                        strAppOrder = "1";
                        strAppKind = "U";
                        strAppUserGroup = "U01";
                        // 금융
                      } else if (dropdownValue == '금융') {
                        strAppOrder = "1";
                        strAppKind = "U";
                        strAppUserGroup = "U11";
                        // 구글&폰앱
                      } else if (dropdownValue == '구글&폰앱') {
                        strAppOrder = "3";
                        strAppKind = "I";
                        strAppUserGroup = "I10";
                        // 사용자(기타)
                      } else if (dropdownValue == '사용자') {
                        strAppOrder = "1";
                        strAppKind = "U";
                        strAppUserGroup = "U90";
                      }
                      changeGroup(
                        appWithIcon,
                        strAppOrder,
                        strAppKind,
                        strAppUserGroup,
                      );
                      notifyStateChanged(); // state를 변경했음을 알림
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.white54, // 버튼의 배경색을 변경
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ).copyWith(
                          foregroundColor: WidgetStateProperty.all<Color>(
                            Colors.black87,
                          ), // 버튼의 텍스트 및 아이콘 색상을 변경
                        ),
                    child: appWithIcon.isFixedApp == '1'
                        ? Text("앱 풀기", style: TextStyle(fontSize: 18))
                        : Text("앱 고정", style: TextStyle(fontSize: 18)),
                    onPressed: () async {
                      fixingApp(appWithIcon);
                      notifyStateChanged(); // state를 변경했음을 알림
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.white60, // 버튼의 배경색을 변경
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ).copyWith(
                          foregroundColor: WidgetStateProperty.all<Color>(
                            Colors.black87,
                          ), // 버튼의 텍스트 및 아이콘 색상을 변경
                        ),
                    child: Text("앱 삭제", style: TextStyle(fontSize: 18)),
                    onPressed: () async {
                      deleteApp(appWithIcon);
                      notifyStateChanged(); // state를 변경했음을 알림
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: Colors.white70, // 버튼의 배경색을 변경
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ).copyWith(
                          foregroundColor: WidgetStateProperty.all<Color>(
                            Colors.black87,
                          ), // 버튼의 텍스트 및 아이콘 색상을 변경
                        ),
                    child: Text("닫기", style: TextStyle(fontSize: 18)),
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    notifyStateChanged(); // state를 변경했음을 알림
  } // 메소드 끝
} // 클래스 끝
