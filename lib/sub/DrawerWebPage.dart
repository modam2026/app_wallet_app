import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // 로컬용 비활성화. 스토어 배포 시 복구
import 'package:app_wallet_app/common/common_helper.dart';
import 'package:app_wallet_app/common/dic_service.dart';
import 'package:app_wallet_app/sub/drawer_callback.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app_wallet_app/common/sql_helper.dart';

/// 기존 웹 사이트를 수정하거나 삭제하는 Drawer(우측 패널) 페이지.
///
/// 작업 순서:
///   1. [initState]  - 부모로부터 전달받은 [captionItem] 으로 사이트명·URL 컨트롤러 초기값 셋팅
///   2. [build]      - 사이트명 입력 → URL 입력 → 수정 버튼 / 삭제 버튼 UI 구성
///   3. 수정 버튼 onPressed:
///       a. URL 형식 유효성 검사 (RegExp)
///       b. 사이트명·URL 미입력 여부 확인
///       c. [SQLHelper.chkCaption] 으로 중복 URL 확인
///       d. 이상 없으면 [SQLHelper.editWebInfo] 로 DB 수정
///       e. Drawer 닫기 + [onItemSelected] 콜백으로 부모 화면 갱신
///   4. 삭제 버튼 onPressed:
///       a. [SQLHelper.deleteWebUrl] 로 DB 에서 해당 항목 삭제
///       b. Drawer 닫기 + [onItemSelected] 콜백으로 부모 화면 갱신
///   5. [dispose]    - 컨트롤러 자원 해제 + [onItemSelected] 콜백 호출
class DrawerWebPage extends StatefulWidget {
  final CustomDrawerCallback? onItemSelected;
  final Map<String, dynamic> captionItem;

  const DrawerWebPage({
    Key? key,
    this.onItemSelected,
    required this.captionItem,
  }) : super(key: key);

  @override
  State<DrawerWebPage> createState() => _DrawerWebPageState();
}

class _DrawerWebPageState extends State<DrawerWebPage> {
  String? strSeletedClass = "";
  final CommonHelper _commonHelper = CommonHelper.instance;
  TextEditingController captionController = TextEditingController();
  TextEditingController webUrlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();

  // ----- AdMob: 로컬용 비활성화. 스토어 배포 시 주석 해제 -----
  // bool _isAdLoaded = false;
  // late BannerAd _bannerAd;
  // final String adUnitId = "ca-app-pub-1137307533515832/9543286599";
  // final String adUnitId = "ca-app-pub-3940256099942544/6300978111"; // 테스트

  @override
  void initState() {
    super.initState();
    captionController.text = widget.captionItem["caption"];
    webUrlController.text = widget.captionItem["web_url"];

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
    // _bannerAd.dispose(); // AdMob 비활성화 시 주석
    _urlFocusNode.dispose();
    webUrlController.dispose();
    captionController.dispose();
    super.dispose();

    if (widget.onItemSelected != null) {
      widget.onItemSelected!(); // onItemSelected가 null이 아닌 경우에만 콜백 함수를 호출합니다.
    }
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
                          "       웹 사이트 수정",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold, // 텍스트를 굵게 만듭니다.
                            color: Colors.red, // 텍스트 색상을 변경합니다.
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    focusNode: _urlFocusNode,
                    decoration: InputDecoration(
                      hintText: "사이트 URL을 입력하세요",
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
                        await SQLHelper.editWebInfo(
                          strWebUrlCtrl,
                          strTagCtrl,
                          widget.captionItem["id"],
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
                          '수정',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
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
                      await SQLHelper.deleteWebUrl(widget.captionItem["id"]);
                      Navigator.pop(context);
                      if (widget.onItemSelected != null) {
                        widget
                            .onItemSelected!(); // onItemSelected가 null이 아닌 경우에만 콜백 함수를 호출합니다.
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
                          '삭제',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  width: MediaQuery.of(context).size.width - 32,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.vpn_key, size: 22),
                    label: Text(
                      "로그인 정보",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.indigo.shade800,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final siteName = captionController.text.trim();
                      final siteUrl = webUrlController.text.trim();
                      if (siteName.isEmpty) {
                        dicService.showCheckItems("사이트명");
                        return;
                      }
                      if (siteUrl.isEmpty) {
                        dicService.showCheckItems("사이트 URL");
                        return;
                      }
                      if (!context.mounted) return;
                      await _commonHelper.showLoginInfoDialogForWeb(
                        context,
                        packageName: siteUrl,
                        appWebName: siteName,
                      );
                    },
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
