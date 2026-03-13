import 'package:app_wallet_app/common/app_constants.dart';
import 'package:app_wallet_app/common/dic_service.dart';
import 'package:app_wallet_app/sub/PageAllGoogle.dart';
import 'package:flutter/material.dart';
import 'package:app_wallet_app/sub/PageAllUserDef.dart';
import 'package:app_wallet_app/sub/PageAllSystem.dart';
import 'package:provider/provider.dart';

/// "전체 앱" 탭 화면.
/// 폰에 설치된 모든 앱을 그룹별(전체/구글·삼성/시스템)로 분류하여 PageView 로 표시.
///
/// 작업 순서:
///   1. [initState]  - 그룹 드롭다운 목록 초기화, 하위 페이지 목록(_pages) 생성
///                     (PageAllUserDef·PageAllGoogle·PageAllSystem)
///   2. [build]      - 상단 드롭다운(그룹 선택) + PageView(하위 페이지) 레이아웃 구성
///   3. 드롭다운 변경 시 → [PageController.jumpToPage] 로 해당 페이지로 이동
///   4. PageView 스와이프 시 → 드롭다운 값 동기화
///   5. [dispose]    - PageController 자원 해제
class TabAllAppPage extends StatefulWidget {
  const TabAllAppPage({Key? key}) : super(key: key);

  @override
  State<TabAllAppPage> createState() => _TabAllAppPageState();
}

class _TabAllAppPageState extends State<TabAllAppPage> {
  final List<String> pageList = kAllAppGroupList;
  late String dropdownValue;
  final PageController _pageController = PageController(initialPage: 0);

  // ValueNotifier<int> _pageCountNotifier = ValueNotifier<int>(0);

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    dropdownValue = pageList[0];
    _pages = [PageAllUserDef(), PageAllGoogle(), PageAllSystem()];

    //   _pageController.addListener(() {
    //     int? nextPage = _pageController.page?.round();

    //     if (nextPage != null) {
    //       String newDropdownValue = pageList[nextPage];

    //       if (newDropdownValue != dropdownValue) {
    //         setState(() {
    //           dropdownValue = newDropdownValue;
    //         });
    //       }
    //     }
    //   });
  }

  @override
  void dispose() {
    _pageController.dispose();
    // _pageCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DicService dicService = Provider.of<DicService>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: <Widget>[
              Container(
                // Container 추가
                color: Colors.lightBlue[100], // 배경색을 변경합니다.
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
                    SizedBox(width: 40), // SizedBox 추가하여 공간 생성
                    Theme(
                      data: ThemeData(
                        canvasColor: Colors.blue[200],
                        iconTheme: IconThemeData(color: Colors.white),
                      ),
                      child: DropdownButton<String>(
                        value: dropdownValue,
                        icon: Icon(Icons.arrow_downward),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              dropdownValue = newValue;
                              _pageController.jumpToPage(
                                pageList.indexOf(newValue),
                              );
                            });
                          }
                        },
                        items: pageList.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
                      dropdownValue = pageList[pageIndex];
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
