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
import 'package:device_apps/device_apps.dart';
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
  List<GroupItem> _groupListForDrawer = const [];
  List<GroupItem> _groupListForGroupManagement = const [];
  int _groupDrawerOpenKey = 0;

  /// 요일(일~토) + AM/PM + 12시간제(hh:mm:ss) 형식의 문자열로 반환.
  /// 예: "(일) AM 11:51:55"
  /// AppBar 타이틀에 1초마다 갱신되어 표시됨.
  String get _timeString {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[_now.weekday - 1]; // 1=월, 7=일
    final h24 = _now.hour; // 0~23
    final prefix = h24 < 12 ? 'AM' : 'PM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final timePart =
        '$prefix ${h12.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}:${_now.second.toString().padLeft(2, '0')}';
    return '($weekday) $timePart';
  }

  /// 그룹 관리 Drawer용 전체 그룹 목록 로드 (use_yn='N' 포함).
  Future<void> _loadGroupListForGroupManagement() async {
    final groups = await SQLHelper.getAllGroupListForManagement();
    if (!mounted) return;
    final list = groups
        .map(
          (g) => GroupItem(
            g['group_code'] as String? ?? '',
            g['group_name'] as String? ?? '',
            int.tryParse(g['app_order']?.toString() ?? '1') ?? 1,
            g['my_app_yn']?.toString().toUpperCase(),
            g['use_yn']?.toString().toUpperCase(),
          ),
        )
        .toList();
    setState(() => _groupListForGroupManagement = list);
  }

  /// Drawer 작업 완료 후 그룹 목록 재로드 및 DicService 갱신.
  void refreshThisPage() async {
    await _loadGroupNamesForTab(_tabController.index);
    await _loadGroupListForGroupManagement();
    if (!mounted) return;
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

    // tbl_group_info 가 비어 있을 때만 기본 그룹 삽입 (중복 방지)
    // group_code 는 makeIntrnAppListData 의 app_kind 값과 반드시 일치해야 함
    final hasGroups = await SQLHelper.hasMyGroups();
    if (!hasGroups) {
      await SQLHelper.addGroupInfo(1, "전체", 1, "A");
      await SQLHelper.addGroupInfo(2, "구글앱", 1, "G"); // com.google.*
      await SQLHelper.addGroupInfo(3, "SNS", 1, "M"); // 인스타, 카카오톡 등
      await SQLHelper.addGroupInfo(4, "삼성일반앱", 1, "X"); // com.samsung.*
      await SQLHelper.addGroupInfo(5, "삼성시스템앱", 2, "X"); // com.sec.*
      await SQLHelper.addGroupInfo(6, "시스템", 1, "S"); // com.android.*
      await SQLHelper.addGroupInfo(7, "기관", 1, "I"); // kr.go.*
      await SQLHelper.addGroupInfo(8, "은행", 1, "B"); // B01
      await SQLHelper.addGroupInfo(9, "카드", 2, "B"); // B02
      await SQLHelper.addGroupInfo(10, "증권", 3, "B"); // B03
      await SQLHelper.addGroupInfo(11, "KT", 1, "C"); // C01
      await SQLHelper.addGroupInfo(12, "SKT", 2, "C"); // C02
      await SQLHelper.addGroupInfo(13, "LGU+", 1, "C"); // C03
      await SQLHelper.addGroupInfo(14, "기타", 1, "E");
    }

    // 그룹 삽입 완료 후 Drawer 그룹 목록 로드 (타이밍 문제 방지)
    await _loadGroupNamesForTab(0);
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
    _initAsync(); // 내부에서 완료 후 _loadGroupNamesForTab(0) 호출
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
      // 나의 앱 탭: 사용자 정의 그룹 + my_app_yn='Y' / 전체 앱 탭: 전체 그룹
      final groups = tabIndex == 0
          ? await SQLHelper.getAllGroupListForMyApp()
          : await SQLHelper.getAllGroupList();
      list = groups.isEmpty
          ? [const GroupItem('', '그룹 없음')]
          : groups
                .map(
                  (g) => GroupItem(
                    g['group_code'] ?? '', // code  → DB 저장용
                    g['group_name'] ?? '', // codeName → 화면 표시용
                    (int.tryParse(g['app_order']?.toString() ?? '1') ?? 1),
                  ),
                )
                .toList();
    } else {
      list = const [];
    }
    if (mounted) {
      setState(() {
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
        title: GestureDetector(
          onTap: () async {
            await DeviceApps.openApp('com.samsung.android.calendar');
          },
          child: Column(
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
              onPressed: () async {
                await _loadGroupListForGroupManagement();
                if (!mounted) return;
                setState(() {
                  _isGroupDrawer = true;
                  _groupDrawerOpenKey++;
                });
                Scaffold.of(context).openEndDrawer();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ),
          // 상단 웹등록 버튼: 아래 서브헤더의 웹 등록 버튼으로 대체
          // Builder(
          //   builder: (context) => TextButton.icon(
          //     icon: const Icon(Icons.add_box, color: Colors.white70),
          //     label: const Text(
          //       '웹등록',
          //       style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          //     ),
          //     onPressed: () {
          //       setState(() {
          //         _isGroupDrawer = false;
          //       });
          //       Scaffold.of(context).openEndDrawer();
          //     },
          //     style: TextButton.styleFrom(foregroundColor: Colors.white70),
          //   ),
          // ),
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
      body: Builder(
        builder: (context) => TabBarView(
          controller: _tabController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            TabMyAppPage(
              // _initAsync() 완료 후 채워진 GroupItem 목록을 직접 전달
              groups: _groupListForDrawer.isEmpty
                  ? const [GroupItem('A', '전체')]
                  : _groupListForDrawer,
            ),
            TabAllAppPage(
              groups: _groupListForDrawer.isEmpty
                  ? const [GroupItem('A', '전체')]
                  : _groupListForDrawer,
            ),
            TabWebPage(
              onWebRegisterRequested: () {
                setState(() => _isGroupDrawer = false);
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ],
        ),
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _isGroupDrawer
                    ? grp.DrawerPageGrp(
                        onItemSelected: refreshThisPage,
                        groupList: _groupListForGroupManagement,
                        openKey: _groupDrawerOpenKey,
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
    setState(() {});
  }
}
