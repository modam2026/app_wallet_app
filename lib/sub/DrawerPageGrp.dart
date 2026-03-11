import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // 로컬용 비활성화. 스토어 배포 시 복구
import 'package:app_wallet_app/common/dic_service.dart';
import 'package:app_wallet_app/sub/drawer_callback.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_wallet_app/common/sql_web_helper.dart';

class DrawerPageGrp extends StatefulWidget {
  final CustomDrawerCallback? onItemSelected;
  final List<GroupItem>? groupList;

  const DrawerPageGrp({Key? key, this.onItemSelected, this.groupList})
    : super(key: key);

  @override
  State<DrawerPageGrp> createState() => _DrawerPageGrpState();
}

class _DrawerPageGrpState extends State<DrawerPageGrp> {
  String? strSeletedClass = "";

  TextEditingController classController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  TextEditingController webUrlController = TextEditingController();

  /// 팝업 메뉴에 쓸 그룹 목록. DB에서 넘어온 groupList만 사용, 없으면 빈 목록
  List<GroupItem> get _menuGroupList =>
      (widget.groupList != null && widget.groupList!.isNotEmpty)
      ? widget.groupList!
      : [];

  // ----- AdMob: 로컬용 비활성화. 스토어 배포 시 주석 해제 -----
  // bool _isAdLoaded = false;
  // late BannerAd _bannerAd;
  // final String adUnitId = "ca-app-pub-1137307533515832/9543286599";
  // final String adUnitId = "ca-app-pub-3940256099942544/6300978111"; // 테스트

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   initAd();
    // });
  }

  // void initAd() async {
  //   final double screenWidth = MediaQuery.of(context).size.width * 0.75;
  //   final AdSize? adSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
  //       Orientation.portrait, screenWidth.toInt());
  //   if (adSize != null) {
  //     _bannerAd = BannerAd(
  //       adUnitId: adUnitId,
  //       size: adSize,
  //       request: AdRequest(),
  //       listener: BannerAdListener(
  //         onAdLoaded: (Ad ad) {
  //           print('$BannerAd loaded.');
  //           _isAdLoaded = true;
  //           setState(() {});
  //         },
  //         onAdFailedToLoad: (Ad ad, LoadAdError error) {
  //           print('$BannerAd failedToLoad: $error');
  //           _isAdLoaded = false;
  //           ad.dispose();
  //           Future.delayed(Duration(minutes: 1), () {
  //             if (!_isAdLoaded) {
  //               _bannerAd.load();
  //             }
  //           });
  //         },
  //         onAdOpened: (Ad ad) => print('$BannerAd onAdOpened.'),
  //         onAdClosed: (Ad ad) {
  //           print('$BannerAd onAdClosed.');
  //           ad.dispose();
  //         },
  //       ),
  //     );
  //     if (!_isAdLoaded) {
  //       _bannerAd.load();
  //     }
  //   }
  // }

  @override
  void dispose() {
    // _bannerAd.dispose(); // AdMob 비활성화 시 주석
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DicService>(
      builder: (context, dicService, child) {
        // FocusNode를 생성합니다.
        FocusNode focusNode = FocusNode();

        // TextField가 포커스를 잃었는지 확인하기 위한 리스너를 추가합니다.
        focusNode.addListener(() {
          if (!focusNode.hasFocus) {
            // TextField가 포커스를 잃었을 때 실행되는 코드입니다.
            String value = webUrlController.text;
            RegExp pattern = RegExp(
              r'^[^/\s]+\.\S{2,}$',
              caseSensitive: false,
              multiLine: false,
            );
            if (!pattern.hasMatch(value)) {
              webUrlController.text = "";
              dicService.showCheckUrl();
            }
          }
        });
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ----- AdMob 비활성화. 스토어 배포 시 아래 블록 주석 해제 -----
                // if (_isAdLoaded)
                //   Align(
                //     alignment: Alignment.centerLeft,
                //     child: Container(
                //       width: MediaQuery.of(context).size.width * 0.84,
                //       height: _bannerAd.size.height.toDouble(),
                //       child: AdWidget(ad: _bannerAd),
                //     ),
                //   ),
                Row(
                  children: [
                    /// 일자 입력창
                    SizedBox(
                      width: 250,
                      height: 50,
                      child: Center(
                        child: Text(
                          "그룹 관리",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold, // 텍스트를 굵게 만듭니다.
                            color: Colors.red, // 텍스트 색상을 변경합니다.
                          ),
                        ),
                      ),
                    ),

                    /// 새 사이트 & 게임 저장 버튼
                    SizedBox(
                      width: 40, // 원하는 너비 설정
                      height: 30, // 원하는 높이 설정
                      child: Container(margin: EdgeInsets.fromLTRB(0, 5, 0, 0)),
                    ),
                  ],
                ),
                SizedBox(width: 100, height: 10),
                Container(
                  margin: EdgeInsets.only(left: 10), // 왼쪽 마진을 10으로 설정
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 8, // 원의 크기를 조절합니다.
                        backgroundColor: Colors.red, // 원의 배경색을 설정합니다.
                        child: Text(
                          '1', // 원 안의 숫자를 설정합니다.
                          style: TextStyle(
                            color: Colors.white, // 숫자의 색상을 설정합니다.
                            fontSize: 12, // 숫자의 크기를 설정합니다.
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 230,
                        child: Text(
                          "그룹명",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold, // 텍스트를 굵게 만듭니다.
                            color: Colors.red, // 텍스트 색상을 변경합니다.
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 190,
                      height: 40,
                      margin: EdgeInsets.symmetric(horizontal: 10.0), // 마진 설정
                      child: TextField(
                        readOnly: true, // 사용자가 TextField를 편집하지 못하도록 설정합니다.
                        style: TextStyle(fontSize: 16.0),
                        controller: classController,
                        decoration: InputDecoration(hintText: "분류를 선택하세요"),
                        onTap: () {
                          dicService.showChkClckTxt();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: PopupMenuButton<String>(
                        child: ElevatedButton(
                          onPressed:
                              null, // PopupMenuButton이 자동으로 onTap을 처리하므로 null로 설정합니다.
                          child: Text(
                            '선택',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        onSelected: (String result) {
                          debugPrint(
                            'DrawerPageGrp onSelected result: $result',
                          );
                          // value 형식: "code|codeName" (DB 그룹/기본 그룹 공통)
                          final parts = result.split('|');
                          final code = parts.isNotEmpty ? parts[0] : '';
                          final codeName = parts.length > 1 ? parts[1] : code;
                          setState(() {
                            classController.text = codeName;
                            strSeletedClass = code;
                          });
                        },
                        itemBuilder: (BuildContext context) => _menuGroupList
                            .map(
                              (GroupItem item) => PopupMenuItem<String>(
                                value: '${item.code}|${item.codeName}',
                                child: Text(
                                  item.codeName,
                                  style: TextStyle(fontSize: 15.0),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
                /*
              Divider(
                thickness: 1, // Divider 두께 설정
                color: Colors.black54, // Divider 색상 설정
              ),
              */
                SizedBox(width: 100, height: 20),
                Container(
                  margin: EdgeInsets.only(left: 10), // 왼쪽 마진을 10으로 설정
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 8, // 원의 크기를 조절합니다.
                        backgroundColor: Colors.red, // 원의 배경색을 설정합니다.
                        child: Text(
                          '2', // 원 안의 숫자를 설정합니다.
                          style: TextStyle(
                            color: Colors.white, // 숫자의 색상을 설정합니다.
                            fontSize: 12, // 숫자의 크기를 설정합니다.
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 230,
                        child: Text(
                          "사이트명",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold, // 텍스트를 굵게 만듭니다.
                            color: Colors.red, // 텍스트 색상을 변경합니다.
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: TextField(
                    style: TextStyle(fontSize: 15.0),
                    controller: captionController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "사이트명을 입력해주세요.",
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 1,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 100, height: 20),
                Container(
                  margin: EdgeInsets.only(left: 10), // 왼쪽 마진을 10으로 설정
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 8, // 원의 크기를 조절합니다.
                        backgroundColor: Colors.red, // 원의 배경색을 설정합니다.
                        child: Text(
                          '3', // 원 안의 숫자를 설정합니다.
                          style: TextStyle(
                            color: Colors.white, // 숫자의 색상을 설정합니다.
                            fontSize: 12, // 숫자의 크기를 설정합니다.
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 230,
                        child: Text(
                          "사이트 URL",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold, // 텍스트를 굵게 만듭니다.
                            color: Colors.red, // 텍스트 색상을 변경합니다.
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: TextField(
                    style: TextStyle(fontSize: 16.0),
                    controller: webUrlController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    focusNode: focusNode, // 여기에 생성한 FocusNode를 지정합니다.
                    decoration: InputDecoration(
                      hintText:
                          "사이트 URL을 입력시 http 생략해 주세요 \n ex) https://www.google.com -> \n        www.google.com",
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 1,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  width: MediaQuery.of(context).size.width - 32,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.fromLTRB(
                        10,
                        0,
                        0,
                        0,
                      ), // 버튼 내부의 정렬을 중앙으로 설정
                    ),
                    onPressed: () async {
                      String strCaptionCtrl = captionController.text;
                      String strWebUrlCtrl = webUrlController.text;
                      // 선택된 그룹 코드 사용 (DB 그룹 포함, 기본 매일/매주/매월/가끔/게임도 code로 저장됨)
                      String? strTagCtrl = strSeletedClass ?? "";

                      final chkData = await SQLWebHelper.chkCaption(
                        strWebUrlCtrl,
                      );

                      RegExp pattern = RegExp(
                        r'^[^/\s]+\.\S{2,}$',
                        caseSensitive: false,
                        multiLine: false,
                      );

                      if (!pattern.hasMatch(strWebUrlCtrl)) {
                        dicService.showCheckUrl();
                      } else if (strTagCtrl.isEmpty) {
                        dicService.showCheckItems("그룹명");
                      } else if (strCaptionCtrl.isEmpty) {
                        dicService.showCheckItems("사이트명");
                      } else if (strWebUrlCtrl.isEmpty) {
                        dicService.showCheckItems("사이트URL");
                      } else if (chkData.isNotEmpty) {
                        dicService.showExistStatus(strCaptionCtrl);
                      } else {
                        // 새로운 웹사이트 최초 등록
                        await SQLWebHelper.createWebInfo(
                          strCaptionCtrl,
                          strWebUrlCtrl,
                          strTagCtrl,
                        );
                        captionController.text = "";

                        Navigator.pop(context);
                        if (widget.onItemSelected != null) {
                          widget
                              .onItemSelected!(); // onItemSelected가 null이 아닌 경우에만 콜백 함수를 호출합니다.
                        }
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/done-svgrepo-com.svg', // 저장 아이콘 파일 경로
                          width: 24,
                          height: 24,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '추가',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
