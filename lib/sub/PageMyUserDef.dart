import 'dart:convert';
import 'package:app_wallet_app/common/AppCache.dart';
import 'package:app_wallet_app/common/DataSearch.dart';
import 'package:app_wallet_app/common/common_helper.dart';
import 'package:app_wallet_app/common/sql_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:device_apps/device_apps.dart';
import 'package:provider/provider.dart';

class PageMyUserDef extends StatefulWidget {
  const PageMyUserDef({Key? key}) : super(key: key);

  @override
  State<PageMyUserDef> createState() => _PageMyUserDefState();
}

class _PageMyUserDefState extends State<PageMyUserDef> {
  List<CachedApplication> apps_search = [];

  // DropdownButton<String> 위젯의 상태를 저장하기 위한 변수를 추가합니다.
  String dropdownValue = '전체';

  // DropdownButton<String>에서 사용할 항목을 선언합니다.
  final List<String> pageList = [
    '전체',
    // '사용앱',
    'SNS',
    '구글&폰앱',
    '사용자',
    '금융',
    '기관'
  ];

  CommonHelper commonHelper = CommonHelper.instance;

  Future<List<CachedApplication>> _getInstalledApplications() async {
    List<CachedApplication> tmpAllApps = [];
    String kind = "A";

    // 메모리에 유지되는 "나의 앱" 리스트는 매번 다시 구성하므로 먼저 비워준다.
    commonHelper.appDataWithMine.clear();

    // 전체 앱 캐시가 비어 있으면 한 번 로딩해 둔다.
    if (commonHelper.appDataWithAll.isEmpty) {
      commonHelper.appDataWithAll =
          await commonHelper.getCachedApplications(kind, "");
    }

    // DB에 "나의 앱 리스트" 데이터가 하나도 없을 때만 기본 앱을 최초 한 번 등록
    final hasMyApps = await SQLHelper.hasMyApps();
    if (!hasMyApps) {
      await SQLHelper.addMyIntrnAppInfo("카카오톡", "com.kakao.talk", "OPN");
      await SQLHelper.addMyIntrnAppInfo(
          "YouTube", "com.google.android.youtube", "OPN");
      await SQLHelper.addMyIntrnAppInfo(
          "네이버지도", "com.nhn.android.nmap", "OPN");
    }

    final app_data = await SQLHelper.getMyAppsFromDB();

    for (var _item in app_data) {
      var app = commonHelper.appDataWithAll
          .where((inApp) => inApp["package_name"] == _item["package_name"])
          .toList();

      if (app.length > 0) {
        Map<String, dynamic> rsltApp = app[0];
        rsltApp["app_num"] = _item["app_num"];
        rsltApp["app_order"] = _item["app_order"];
        rsltApp["app_kind"] = _item["app_kind"];
        rsltApp["app_user_group"] = _item["app_user_group"];
        rsltApp["app_opening"] = _item["app_opening"];
        rsltApp["app_use_period"] = _item["app_use_period"];
        rsltApp["is_fixed_app"] = _item["is_fixed_app"];
        commonHelper.appDataWithMine.add(rsltApp);
      }
    }

    // is_first_input 플래그는 더 이상 사용하지 않는다.
    commonHelper.appDataWithMine.sort((a, b) {
      // Compare 'is_fixed_app' first
      int isFixedAppComparison = b['is_fixed_app'].compareTo(a['is_fixed_app']);

      // If 'is_fixed_app' values are equal, compare 'app_use_period'
      if (isFixedAppComparison == 0) {
        // Compare 'app_use_period'
        int usePeriodComparison =
            a['app_use_period'].compareTo(b['app_use_period']);

        // If 'app_use_period' values are equal, compare 'num'
        if (usePeriodComparison == 0) {
          // Compare 'app_num'
          return b['app_num'].compareTo(a['app_num']);
        }

        return usePeriodComparison;
      }

      return isFixedAppComparison;
    });

    for (var myApp in commonHelper.appDataWithMine) {
      CachedApplication tmpCachedApp = myApp["cached_application"];
      tmpCachedApp.appNum = myApp['app_num'].toString();
      tmpCachedApp.isOpening = myApp['app_opening'].toString();
      tmpCachedApp.appUsePeriod = myApp['app_use_period'].toString();
      tmpCachedApp.isFixedApp = myApp['is_fixed_app'].toString();

      tmpAllApps.add(tmpCachedApp);
    }

    return tmpAllApps;
  }

  void _showConfirmationDialog(
      CachedApplication appWithIcon, BuildContext context) {
    commonHelper.showConfirmationDialog(appWithIcon, context, () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("전체 리스트(1/6)"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              padding: EdgeInsets.fromLTRB(0, 0, 26, 0),
              onPressed: () {
                showSearch(context: context, delegate: DataSearch(apps_search));
              },
            ),
          ],
        ),
        body: FutureBuilder(
          future: _getInstalledApplications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.error != null) {
              return Center(child: Text('An error occurred!'));
            } else {
              var apps = snapshot.data!;
              apps_search.clear();
              apps_search = List.from(apps);

              return ListView.separated(
                separatorBuilder: (context, index) => Divider(
                  color: Colors.grey[350],
                  height: 1,
                  thickness: 1.0,
                ),
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  var app = apps[index];
                  var appWithIcon = app as CachedApplication;
                  //search 창으로 아이콘앱을 넘기기
                  //ImageProvider icon = MemoryImage(appWithIcon.icon);
                  ImageProvider icon =
                      MemoryImage(base64Decode(appWithIcon.icon));
                  bool isAppInDatabase = false;
                  if (appWithIcon.isOpening == "1") {
                    isAppInDatabase = true;
                  } else {
                    isAppInDatabase = false;
                  }
                  return ListTile(
                    tileColor: appWithIcon.isFixedApp == '1'
                        ? Color.fromARGB(255, 227, 227, 235)
                        : null,
                    leading: Image(image: icon, width: 50, height: 50),
                    title: Text(appWithIcon.appName),
                    // subtitle: Text(appWithIcon.packageName),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: Icon(CupertinoIcons.ellipsis_vertical),
                        onPressed: () {
                          _showConfirmationDialog(appWithIcon, context);
                        },
                      ),
                    ]),
                    onTap: () async {
                      await commonHelper.openApp(appWithIcon);
                      setState(() {});
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
