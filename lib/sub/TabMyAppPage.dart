import 'package:app_wallet_app/common/app_constants.dart';
import 'package:app_wallet_app/common/dic_service.dart';
//import 'package:app_wallet_app/sub/PageMyCfgList.dart';
import 'package:app_wallet_app/sub/PageMyUserBank.dart';
import 'package:app_wallet_app/sub/PageMyUserDef.dart';
import 'package:app_wallet_app/sub/PageMyUserEtc.dart';
import 'package:app_wallet_app/sub/PageMyUserGov.dart';
import 'package:app_wallet_app/sub/PageMyUserInstSys.dart';
import 'package:app_wallet_app/sub/PageMyUserSns.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "나의 앱" 탭 화면.
/// 사용자가 직접 추가한 앱을 그룹별(전체/SNS/구글&폰앱/사용자/금융/기관)로 분류하여 PageView 로 표시.
///
/// 작업 순서:
///   1. [initState]  - 그룹 드롭다운 목록 초기화, 하위 페이지 목록(_pages) 생성
///                     (PageMyUserDef·PageMyUserSns·PageMyUserInstSys·PageMyUserEtc·PageMyUserBank·PageMyUserGov)
///   2. [build]      - 상단 드롭다운(그룹 선택) + PageView(하위 페이지) 레이아웃 구성
///   3. 드롭다운 변경 시 → [PageController.jumpToPage] 로 해당 페이지로 이동
///   4. PageView 스와이프 시 → 드롭다운 값 동기화
///   5. [dispose]    - PageController 자원 해제
class TabMyAppPage extends StatefulWidget {
  const TabMyAppPage({Key? key}) : super(key: key);

  @override
  State<TabMyAppPage> createState() => _TabMyAppPageState();
}

class _TabMyAppPageState extends State<TabMyAppPage> {
  final List<String> pageList = kMyAppGroupList;
  late String dropdownValue;
  final PageController _pageController = PageController(initialPage: 0);

  // ValueNotifier<int> _pageCountNotifier = ValueNotifier<int>(0);

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    dropdownValue = pageList[0];
    _pages = [
      PageMyUserDef(),
      //      PageMyCfgList(),
      PageMyUserSns(),
      PageMyUserInstSys(),
      PageMyUserEtc(),
      PageMyUserBank(),
      PageMyUserGov(),
    ];

    // _pageController.addListener(() {
    //   int? nextPage = _pageController.page?.round();

    //   if (nextPage != null) {
    //     String newDropdownValue = pageList[nextPage];

    //     if (newDropdownValue != dropdownValue) {
    //       setState(() {
    //         dropdownValue = newDropdownValue;
    //       });
    //     }
    //   }
    // });
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
                          "나의 앱 리스트",
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
