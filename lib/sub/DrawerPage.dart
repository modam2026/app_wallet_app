import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // 로컬용 비활성화. 스토어 배포 시 복구
import 'package:app_wallet_app/common/dic_service.dart';
import 'package:app_wallet_app/sub/drawer_callback.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_wallet_app/common/sql_helper.dart';

/// 웹 사이트를 신규 등록하는 Drawer(우측 패널) 페이지.
///
/// 작업 순서:
///   1. [initState]  - 초기 상태 설정 (컨트롤러 초기화)
///   2. [build]      - 분류 선택(팝업) → 사이트명 입력 → URL 입력 → 추가 버튼 UI 구성
///   3. 추가 버튼 onPressed:
///       a. URL 형식 유효성 검사 (RegExp)
///       b. 분류·사이트명·URL 미입력 여부 확인
///       c. [SQLHelper.chkCaption] 으로 중복 URL 확인
///       d. 이상 없으면 [SQLHelper.createWebInfo] 로 DB 저장
///       e. Drawer 닫기 + [onItemSelected] 콜백으로 부모 화면 갱신
///   4. [dispose]    - 자원 해제
class DrawerPage extends StatefulWidget {
  final CustomDrawerCallback? onItemSelected;

  const DrawerPage({Key? key, this.onItemSelected}) : super(key: key);

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  String? strSeletedClass = "";

  TextEditingController classController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  TextEditingController webUrlController = TextEditingController();

  /// URL 입력란 포커스. build() 내부에서 생성하면 리빌드 시 포커스가 유지되지 않음.
  late FocusNode _webUrlFocusNode;

  // ----- AdMob: 로컬용 비활성화. 스토어 배포 시 주석 해제 -----
  // bool _isAdLoaded = false;
  // late BannerAd _bannerAd;
  // final String adUnitId = "ca-app-pub-1137307533515832/9543286599";
  // final String adUnitId = "ca-app-pub-3940256099942544/6300978111"; // 테스트

  @override
  void initState() {
    super.initState();
    _webUrlFocusNode = FocusNode();
    _webUrlFocusNode.addListener(_onWebUrlFocusChange);
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   initAd();
    // });
  }

  void _onWebUrlFocusChange() {
    if (!_webUrlFocusNode.hasFocus) {
      final raw = webUrlController.text.trim();
      final normalized = _normalizeUrl(raw);
      if (!_urlPattern.hasMatch(normalized)) {
        if (raw.isNotEmpty) {
          webUrlController.text = "";
          if (mounted) {
            Provider.of<DicService>(context, listen: false).showCheckUrl();
          }
        }
      } else {
        webUrlController.text = normalized;
      }
    }
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

  /// URL 문자열 정규화 (전각 문자, Zero-Width 문자 제거).
  static String _normalizeUrl(String raw) => raw
      .trim()
      .replaceAll('\uFF0E', '.')
      .replaceAll('\u3000', ' ')
      .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u200E\u202A-\u202E]'), '')
      .trim();

  static final RegExp _urlPattern = RegExp(
    r'^(https?://)?[^/\s]+\.\S{2,}$',
    caseSensitive: false,
    multiLine: false,
  );

  @override
  void dispose() {
    _webUrlFocusNode.removeListener(_onWebUrlFocusChange);
    _webUrlFocusNode.dispose();
    // _bannerAd.dispose(); // AdMob 비활성화 시 주석
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DicService>(
      builder: (context, dicService, child) {
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
                          "웹 사이트 관리",
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
                          "분류",
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
                          setState(() {
                            classController.text = result;
                            strSeletedClass = result.trim();
                          });
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: '  매일',
                                child: Text(
                                  '매일',
                                  style: TextStyle(fontSize: 15.0), // 글꼴 크기 조절
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: '  매주',
                                child: Text(
                                  '매주',
                                  style: TextStyle(fontSize: 15.0),
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: '  매월',
                                child: Text(
                                  '매월',
                                  style: TextStyle(fontSize: 15.0),
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: '  가끔',
                                child: Text(
                                  '가끔',
                                  style: TextStyle(fontSize: 15.0),
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: '  게임',
                                child: Text(
                                  '게임',
                                  style: TextStyle(fontSize: 15.0),
                                ),
                              ),
                            ],
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
                    focusNode: _webUrlFocusNode,
                    decoration: InputDecoration(
                      hintText: "ex) www.google.com",
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
                      String strCaptionCtrl = captionController.text.trim();
                      String strWebUrlCtrl = _normalizeUrl(
                        webUrlController.text,
                      );
                      String? strTagCtrl = "";

                      switch (strSeletedClass) {
                        case "매일":
                          strTagCtrl = "d";
                          break;
                        case "매주":
                          strTagCtrl = "w";
                          break;
                        case "매월":
                          strTagCtrl = "m";
                          break;
                        case "게임":
                          strTagCtrl = "g";
                          break;
                        default:
                          strTagCtrl = "e";
                          break;
                      }

                      final chkData = await SQLHelper.chkCaption(strWebUrlCtrl);

                      if (!_urlPattern.hasMatch(strWebUrlCtrl)) {
                        dicService.showCheckUrl();
                      } else if (strTagCtrl.isEmpty) {
                        dicService.showCheckItems("분류");
                      } else if (strCaptionCtrl.isEmpty) {
                        dicService.showCheckItems("사이트명");
                      } else if (strWebUrlCtrl.isEmpty) {
                        dicService.showCheckItems("사이트URL");
                      } else if (chkData.isNotEmpty) {
                        dicService.showExistStatus(strCaptionCtrl);
                      } else {
                        // https:// 또는 http:// 접두사 제거 (indexOf로 위치 찾아 이후 문자열만 사용)
                        final idxHttps = strWebUrlCtrl.indexOf('https://');
                        final idxHttp = strWebUrlCtrl.indexOf('http://');
                        if (idxHttps >= 0) {
                          strWebUrlCtrl = strWebUrlCtrl.substring(idxHttps + 8);
                        } else if (idxHttp >= 0) {
                          strWebUrlCtrl = strWebUrlCtrl.substring(idxHttp + 7);
                        }
                        // 새로운 웹사이트 최초 등록
                        await SQLHelper.createWebInfo(
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
