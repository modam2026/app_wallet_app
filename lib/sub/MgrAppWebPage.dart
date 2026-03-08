import 'package:app_wallet_app/common/common_helper.dart';
import 'package:app_wallet_app/common/dic_service.dart';
import 'package:app_wallet_app/sub/DrawerPage.dart';
import 'package:app_wallet_app/sub/TabAllAppPage.dart';
import 'package:app_wallet_app/sub/TabMyAppPage.dart';
import 'package:app_wallet_app/sub/TabWebPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MgrAppWebPage extends StatefulWidget {
  const MgrAppWebPage({Key? key}) : super(key: key);

  @override
  State<MgrAppWebPage> createState() => _MgrAppWebPageState();
}

class _MgrAppWebPageState extends State<MgrAppWebPage> {
  CommonHelper commonHelper = CommonHelper.instance;

  void refreshThisPage() async {
    final dicService = Provider.of<DicService>(context, listen: false);
    setState(() {
      dicService.callbackStatus = true;
      dicService.callNotifyListeners();
    });
  }

  Future<void> _initAsync() async {
    await _initInternalAppInfo();
  }

  @override
  void initState() {
    super.initState();
    _initAsync();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.grey,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          title: Text(
            "모담(募淡)테크",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'DancingScript',
            ),
          ),
          // leading: TextButton(
          //   child: FittedBox(
          //     fit: BoxFit.scaleDown,
          //     child: Text(
          //       "예정",
          //       style: TextStyle(
          //         fontSize: 34,
          //         fontWeight: FontWeight.bold,
          //         color: Colors.white,
          //       ),
          //     ),
          //   ),
          //   onPressed: () {},
          // ),
          actions: [
            Builder(
              builder: (context) => TextButton.icon(
                icon: Icon(Icons.add_box, color: Colors.white70),
                label: Text(
                  '웹등록',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: Container(
              color: Colors.indigo, // 배경색을 설정합니다.
              child: TabBar(
                      indicatorColor: Colors.amberAccent,
                      labelColor: Colors.white,              // 선택된 탭
                      unselectedLabelColor: Colors.white38,  // 비선택 탭 (더 흐리게)
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                      ),
                      tabs: [
                        Tab(icon: Icon(Icons.apps), text: '나의 앱'),
                        Tab(icon: Icon(Icons.apps), text: '전체 앱'),
                        Tab(icon: Icon(Icons.web), text: '웹'),
                      ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            TabMyAppPage(),
            TabAllAppPage(),
            TabWebPage(),
          ],
        ),
        endDrawer: Drawer(
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DrawerPage(onItemSelected: refreshThisPage),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _initInternalAppInfo() async {
    // 전체 앱/분류별 캐시 데이터를 먼저 로딩해 둔다.
    await commonHelper.initIntrnAppInfo();

    // 가져온 파일 목록을 화면에 업데이트
    setState(() {
      print("OK");
    });
  }
}
