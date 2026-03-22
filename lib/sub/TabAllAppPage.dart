import 'package:app_wallet_app/common/dic_service.dart';
import 'package:app_wallet_app/sub/PageAllApps.dart';
import 'package:app_wallet_app/sub/drawer_callback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "전체 앱" 탭 화면.
/// MgrAppWebPage 에서 전달받은 [groups](GroupItem 목록)을 기반으로
/// PageView 를 동적으로 구성한다.
///
/// 작업 순서:
///   1. [initState]       - 드롭다운 목록·PageView 페이지 목록 초기화
///   2. [_buildPages]     - groups 로부터 PageAllApps 위젯 목록 생성
///   3. [build]           - 상단 드롭다운 + PageView 레이아웃 구성
///   4. 드롭다운 변경 시  → PageController.jumpToPage 로 해당 페이지 이동
///   5. PageView 스와이프 → 드롭다운 값 동기화
///   6. [didUpdateWidget] - 부모에서 groups 가 바뀐 경우 드롭다운·페이지 갱신
///   7. [dispose]         - PageController 자원 해제
class TabAllAppPage extends StatefulWidget {
  /// MgrAppWebPage 에서 tbl_group_info 로드 완료 후 전달하는 그룹 목록
  final List<GroupItem> groups;

  const TabAllAppPage({Key? key, this.groups = const [GroupItem('A', '전체')]})
    : super(key: key);

  @override
  State<TabAllAppPage> createState() => _TabAllAppPageState();
}

class _TabAllAppPageState extends State<TabAllAppPage> {
  late List<GroupItem> _groups;
  late String _dropdownValue;
  final PageController _pageController = PageController(initialPage: 0);
  List<Widget> _pages = [];

  /// 사용자 정의 그룹(code=='A', order>1) 제외. "전체"와 기본 그룹만 드롭다운에 표시
  List<GroupItem> get _filteredGroups => widget.groups
      .where((g) => g.code != 'A' || g.order == 1)
      .toList();

  @override
  void initState() {
    super.initState();
    _groups = _filteredGroups.isNotEmpty ? _filteredGroups : widget.groups;
    _dropdownValue = _groups.first.codeName;
    _buildPages();
  }

  /// groups 목록으로부터 PageAllApps 위젯 목록을 생성.
  /// appOrder 전달로 은행·카드·증권 등 동일 group_code 내 구분
  void _buildPages() {
    _pages = _groups
        .map(
          (g) => PageAllApps(
            groupCode: g.code,
            groupName: g.codeName,
            appOrder: g.order,
          ),
        )
        .toList();
  }

  /// 부모(MgrAppWebPage)가 새 groups 를 전달할 때 드롭다운·페이지 목록 갱신.
  @override
  void didUpdateWidget(TabAllAppPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCodes = oldWidget.groups.map((g) => g.code).toList();
    final newCodes = widget.groups.map((g) => g.code).toList();
    if (!listEquals(oldCodes, newCodes) && widget.groups.isNotEmpty) {
      setState(() {
        _groups = _filteredGroups.isNotEmpty ? _filteredGroups : widget.groups;
        _buildPages();
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
    final dicService = Provider.of<DicService>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.lightBlue[100],
              child: Row(
                children: [
                  SizedBox(
                    width: 250,
                    height: 50,
                    child: Center(
                      child: Text(
                        "전체 앱 리스트",
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
