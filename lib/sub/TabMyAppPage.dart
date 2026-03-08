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

class TabMyAppPage extends StatefulWidget {
  const TabMyAppPage({Key? key}) : super(key: key);

  @override
  State<TabMyAppPage> createState() => _TabMyAppPageState();
}

class _TabMyAppPageState extends State<TabMyAppPage> {
  List<String> pageList = [
    '전체',
    'SNS',
    '구글&폰앱',
    '사용자',
    '금융',
    '기관',
  ];
  late String dropdownValue;
  PageController _pageController = PageController(initialPage: 0);

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
                        items: pageList
                            .map<DropdownMenuItem<String>>((String value) {
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
