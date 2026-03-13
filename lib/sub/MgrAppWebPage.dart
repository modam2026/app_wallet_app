import 'dart:async';
import 'package:app_wallet_app/common/common_helper.dart';
import 'package:app_wallet_app/common/dic_service.dart';
import 'package:app_wallet_app/common/sql_helper.dart';
import 'package:app_wallet_app/sub/DrawerPage.dart';
import 'package:app_wallet_app/sub/drawer_callback.dart';
import 'package:app_wallet_app/sub/DrawerPageGrp.dart' as grp;
import 'package:app_wallet_app/sub/TabAllAppPage.dart';
import 'package:app_wallet_app/sub/TabMyAppPage.dart';
import 'package:app_wallet_app/sub/TabWebPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 앱 전체의 최상위 관리 페이지 (루트 화면).
///
/// 작업 순서:
///   1. [initState]               - TabController 생성, 1초 타이머 시작, 앱 데이터 초기화
///   2. [_initAsync]              - [_initInternalAppInfo] 를 비동기로 호출
///   3. [_initInternalAppInfo]    - CommonHelper 로 전체/분류별 앱 캐시 데이터 메모리 로딩
///   4. [_loadGroupNamesForTab]   - 현재 선택 탭에 따라 DB 에서 그룹 목록을 읽어 Drawer 에 셋팅
///   5. [_onTabChanged]           - 탭 전환 시 [_loadGroupNamesForTab] 재호출
///   6. [build]                   - AppBar(날짜/시간/탭바) + TabBarView(나의앱·전체앱·웹) + endDrawer 구성
///   7. [refreshThisPage]         - Drawer 작업 완료 후 DicService 를 통해 화면 전체 갱신
///   8. [dispose]                 - TabController, Timer 자원 해제
class MgrAppWebPage extends StatefulWidget {
  const MgrAppWebPage({Key? key}) : super(key: key);

  @override
  State<MgrAppWebPage> createState() => _MgrAppWebPageState();
}

class _MgrAppWebPageState extends State<MgrAppWebPage>
    with SingleTickerProviderStateMixin {
  CommonHelper commonHelper = CommonHelper.instance;
  late DateTime _now;
  late Timer _timer;
  bool _isGroupDrawer = false;
  late TabController _tabController;
  List<GroupItem> _groupListForDrawer = const [
    GroupItem('d', '매일'),
    GroupItem('w', '매주'),
    GroupItem('m', '매월'),
    GroupItem('e', '가끔'),
    GroupItem('g', '게임'),
  ];

  /// 현재 시각을 AM/PM + 12시간제(hh:mm:ss) 형식의 문자열로 반환.
  /// AppBar 타이틀에 1초마다 갱신되어 표시됨.
  String get _timeString {
    final h24 = _now.hour; // 0~23
    final prefix = h24 < 12 ? 'AM' : 'PM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$prefix ${h12.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';
  }

  /// Drawer 작업 완료 후 DicService 의 callbackStatus 를 true 로 설정하여 전체 화면을 갱신.
  void refreshThisPage() async {
    final dicService = Provider.of<DicService>(context, listen: false);
    setState(() {
      dicService.callbackStatus = true;
      dicService.callNotifyListeners();
    });
  }

  /// initState 에서 비동기 초기화를 호출하기 위한 래퍼 함수.
  /// [_initInternalAppInfo] 를 await 로 순차 실행.
  Future<void> _initAsync() async {
    await _initInternalAppInfo();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
    _initAsync();
    _loadGroupNamesForTab(0);
  }

  /// TabController 의 탭 전환 이벤트 리스너.
  /// 탭 전환이 완료되고 위젯이 마운트 상태일 때 [_loadGroupNamesForTab] 을 호출.
  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      _loadGroupNamesForTab(_tabController.index);
    }
  }

  /// 선택된 탭(나의 앱=0, 전체 앱=1, 웹=2)에 따라 그룹 코드/코드명 목록을 가져와 _groupListForDrawer 에 셋팅
  Future<void> _loadGroupNamesForTab(int tabIndex) async {
    List<GroupItem> list;
    if (tabIndex == 0 || tabIndex == 1) {
      final names = await SQLHelper.getDistinctAppUserGroups();
      list = names.isEmpty
          ? [const GroupItem('', '그룹 없음')]
          : names.map((s) => GroupItem(s, s)).toList();
    } else {
      list = const [];
    }
    if (mounted) {
      setState(() {
        print("list: $list");
        _groupListForDrawer = list;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              icon: const Icon(Icons.add_box, color: Colors.white70),
              label: const Text(
                '그룹관리',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                setState(() {
                  _isGroupDrawer = true;
                });
                Scaffold.of(context).openEndDrawer();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ),
          Builder(
            builder: (context) => TextButton.icon(
              icon: const Icon(Icons.add_box, color: Colors.white70),
              label: const Text(
                '웹등록',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                setState(() {
                  _isGroupDrawer = false;
                });
                Scaffold.of(context).openEndDrawer();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 12),
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              color: Colors.indigo,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.amberAccent,
                labelColor: Colors.white, // 선택된 탭
                unselectedLabelColor: Colors.white38, // 비선택 탭 (더 흐리게)
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
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
      body: TabBarView(
        controller: _tabController,
        physics: NeverScrollableScrollPhysics(),
        children: [TabMyAppPage(), TabAllAppPage(), TabWebPage()],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _isGroupDrawer
                    ? grp.DrawerPageGrp(
                        onItemSelected: refreshThisPage,
                        groupList: _groupListForDrawer,
                      )
                    : DrawerPage(onItemSelected: refreshThisPage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// CommonHelper 를 통해 전체/분류별 앱 데이터를 메모리에 로딩하고 화면을 갱신.
  ///
  /// 작업 순서:
  ///   1. [CommonHelper.initIntrnAppInfo] 로 앱 캐시 데이터 로딩
  ///   2. setState 로 화면 재빌드
  Future<void> _initInternalAppInfo() async {
    // 전체 앱/분류별 캐시 데이터를 먼저 로딩해 둔다.
    await commonHelper.initIntrnAppInfo();

    // 가져온 파일 목록을 화면에 업데이트
    setState(() {
      print("OK");
    });
  }
}
