import 'package:app_wallet_app/common/dic_service.dart';
import 'package:app_wallet_app/sub/PageMyApps.dart';
import 'package:app_wallet_app/sub/drawer_callback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "나의 앱" 탭 화면.
/// MgrAppWebPage 에서 전달받은 [groups](GroupItem 목록)을 기반으로
/// PageView 를 동적으로 구성한다.
///
/// 작업 순서:
///   1. [initState]       - 드롭다운 목록·PageView 페이지 목록 초기화
///   2. [_buildPages]     - groups 로부터 PageMyApps 위젯 목록 생성
///                          (첫 번째 페이지만 isFirst: true → DB 초기화 수행)
///   3. [build]           - 상단 드롭다운 + PageView 레이아웃 구성
///   4. 드롭다운 변경 시  → PageController.jumpToPage 로 해당 페이지 이동
///   5. PageView 스와이프 → 드롭다운 값 동기화
///   6. [didUpdateWidget] - 부모에서 groups 가 바뀐 경우 드롭다운·페이지 갱신
///   7. [dispose]         - PageController 자원 해제
class TabMyAppPage extends StatefulWidget {
  /// MgrAppWebPage 에서 tbl_group_info 로드 완료 후 전달하는 그룹 목록
  final List<GroupItem> groups;

  const TabMyAppPage({Key? key, this.groups = const [GroupItem('A', '전체')]})
    : super(key: key);

  @override
  State<TabMyAppPage> createState() => _TabMyAppPageState();
}

class _TabMyAppPageState extends State<TabMyAppPage> {
  late List<GroupItem> _groups;
  late String _dropdownValue;
  final PageController _pageController = PageController(initialPage: 0);
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _groups = widget.groups;
    _dropdownValue = _groups.first.codeName;
    _buildPages();
  }

  /// groups 목록으로부터 PageMyApps 위젯 목록을 생성.
  /// 인덱스 0(첫 번째) 페이지만 isFirst: true 로 설정해 DB 초기화를 수행.
  void _buildPages() {
    _pages = _groups.asMap().entries.map((entry) {
      return PageMyApps(
        groupCode: entry.value.code,
        groupName: entry.value.codeName,
        appOrder: entry.value.order,
        isFirst: entry.key == 0,
      );
    }).toList();
  }

  /// 부모(MgrAppWebPage)가 새 groups 를 전달할 때 드롭다운·페이지 목록 갱신.
  /// 그룹 코드 목록이 실제로 바뀐 경우에만 갱신.
  @override
  void didUpdateWidget(TabMyAppPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCodes = oldWidget.groups.map((g) => g.code).toList();
    final newCodes = widget.groups.map((g) => g.code).toList();
    if (!listEquals(oldCodes, newCodes) && widget.groups.isNotEmpty) {
      setState(() {
        _groups = widget.groups;
        _buildPages();
        // 현재 선택된 그룹명이 새 목록에 없으면 첫 번째로 초기화
        if (!_groups.any((g) => g.codeName == _dropdownValue)) {
          _dropdownValue = _groups.first.codeName;
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DicService dicService = Provider.of<DicService>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 그룹 드롭다운 바 ──────────────────────────
            Container(
              color: Colors.lightBlue[100],
              child: Row(
                children: [
                  SizedBox(
                    width: 250,
                    height: 50,
                    child: Center(
                      child: Text(
                        "나의 앱 리스트",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    child: Theme(
                      data: ThemeData(
                        canvasColor: Colors.blue[200],
                        iconTheme: const IconThemeData(color: Colors.white),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: false,
                        value: _dropdownValue,
                        icon: const Icon(Icons.arrow_downward),
                        onChanged: (String? newValue) {
                          if (newValue == null) return;
                          final idx = _groups.indexWhere(
                            (g) => g.codeName == newValue,
                          );
                          if (idx < 0) return;
                          setState(() {
                            _dropdownValue = newValue;
                            _pageController.jumpToPage(idx);
                          });
                        },
                        items: _groups
                            .map(
                              (g) => DropdownMenuItem<String>(
                                value: g.codeName,
                                child: Text(
                                  g.codeName,
                                  style: TextStyle(color: Colors.blue[900]),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            // ── PageView ────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  dicService.totPage = _pages.length;
                  dicService.currentPage = index;
                  return _pages[index];
                },
                onPageChanged: (int pageIndex) {
                  setState(() {
                    _dropdownValue = _groups[pageIndex].codeName;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
