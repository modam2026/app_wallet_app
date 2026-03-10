import 'dart:async';
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
  late DateTime _now;
  late Timer _timer;

  /// AM/PM + 12시간 형식 hh:mm:ss
  String get _timeString {
    final h24 = _now.hour; // 0~23
    final prefix = h24 < 12 ? 'AM' : 'PM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$prefix ${h12.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';
  }

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
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
    _initAsync();
  }

  @override
  void dispose() {
    _timer.cancel();
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
          toolbarHeight: kToolbarHeight + 10,
          iconTheme: IconThemeData(color: Colors.black),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  text:
                      '${_now.year.toString()}년 ${_now.month.toString().padLeft(2, '0')}월 ${_now.day.toString().padLeft(2, '0')}일',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'DancingScript',
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 140,
                child: Text(
                  _timeString,
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'DancingScript',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
            preferredSize: const Size.fromHeight(kToolbarHeight + 12),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                color: Colors.indigo, // 배경색을 설정합니다.
                child: const TabBar(
                  indicatorColor: Colors.amberAccent,
                  labelColor: Colors.white, // 선택된 탭
                  unselectedLabelColor: Colors.white38, // 비선택 탭 (더 흐리게)
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(
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
        ),
        body: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              TabMyAppPage(),
              TabAllAppPage(),
              TabWebPage(),
            ],
          ),
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
