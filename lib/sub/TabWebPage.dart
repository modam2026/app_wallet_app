import 'package:app_wallet_app/sub/DrawerWebPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // 로컬용 비활성화. 스토어 배포 시 복구
import 'package:provider/provider.dart';
import 'package:app_wallet_app/common/dic_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_wallet_app/common/sql_web_helper.dart';

/// "웹" 탭 화면.
/// 사용자가 등록한 웹 사이트 목록을 카드 형태로 표시하고, 접속·순서 변경·수정 기능을 제공.
///
/// 작업 순서:
///   1. [initState]        - [refreshWebUrls] 호출하여 DB 에서 웹사이트 목록 초기 로딩
///   2. [refreshWebUrls]   - [SQLWebHelper.getWebInfos] 로 DB 조회 후 _captions 갱신 및 화면 재빌드
///   3. [build]            - 웹사이트 카드 ListView 구성 (태그별 색상·이미지 다르게 표시)
///   4. 카드 탭 시          - [SQLWebHelper.updateUsedCnt] 로 사용 횟수 업데이트 + [_launchUrl] 로 브라우저 실행
///   5. 상단 이동 버튼 탭 시  - [SQLWebHelper.updateMaxUsedCnt] 로 해당 항목을 목록 맨 위로 이동
///   6. 수정 버튼 탭 시      - endDrawer 열기 + [DrawerWebPage] 에 선택 항목 전달
///   7. [refreshThisPage]  - DicService 콜백 상태 갱신으로 전체 화면 재빌드 유도
///   8. [_launchUrl]       - url_launcher 로 외부 브라우저 실행
///   9. [dispose]          - TextEditingController 자원 해제
class TabWebPage extends StatefulWidget {
  const TabWebPage({Key? key}) : super(key: key);

  @override
  State<TabWebPage> createState() => _TabWebPageState();
}

class _TabWebPageState extends State<TabWebPage> {
  TextEditingController testController = TextEditingController();
  double progress = 0.0;
  String curPostTime = "";
  String endPostTime = "";
  List<Map<String, dynamic>> _captions = [];

  // ----- AdMob: 로컬용 비활성화. 스토어 배포 시 주석 해제 -----
  // bool _isAdLoaded = false;
  // late BannerAd _bannerAd;
  // final String adUnitId = "ca-app-pub-1137307533515832/4573396484";
  // final String adUnitId = "ca-app-pub-3940256099942544/6300978111"; // 테스트

  /// DicService 의 callbackStatus 를 true 로 설정하여 웹 탭 화면 전체를 갱신.
  /// Drawer(DrawerWebPage) 작업 완료 후 콜백으로 호출됨.
  void refreshThisPage() async {
    final dicService = Provider.of<DicService>(context, listen: false);
    setState(() {
      dicService.callbackStatus = true;
      dicService.callNotifyListeners();
    });
  }

  /// DB 에서 웹사이트 목록을 다시 조회하여 _captions 를 갱신하고 화면을 재빌드.
  ///
  /// 작업 순서:
  ///   1. [SQLWebHelper.getWebInfos] 로 DB 에서 웹사이트 목록 조회
  ///   2. 위젯이 마운트 상태인지 확인 후 setState 로 _captions 갱신
  void refreshWebUrls() async {
    var data = await SQLWebHelper.getWebInfos();
    if (!mounted) return;
    setState(() {
      _captions = data;
    });
  }

  @override
  void initState() {
    super.initState();

    // ----- AdMob: 로컬용 비활성화. 스토어 배포 시 주석 해제 -----
    // _bannerAd = BannerAd(
    //   adUnitId: adUnitId,
    //   size: AdSize.smartBanner,
    //   request: AdRequest(),
    //   listener: BannerAdListener(
    //     onAdLoaded: (Ad ad) {
    //       print('$BannerAd loaded.');
    //       _isAdLoaded = true;
    //     },
    //     onAdFailedToLoad: (Ad ad, LoadAdError error) {
    //       print('$BannerAd failedToLoad: $error');
    //       _isAdLoaded = false;
    //       ad.dispose();
    //     },
    //     onAdOpened: (Ad ad) => print('$BannerAd onAdOpened.'),
    //     onAdClosed: (Ad ad) {
    //       print('$BannerAd onAdClosed.');
    //       ad.dispose();
    //     },
    //   ),
    // );
    // if (!_isAdLoaded) {
    //   _bannerAd.load();
    // }

    refreshWebUrls();
  }

  @override
  void dispose() {
    testController.dispose();
    // _bannerAd.dispose(); // AdMob 비활성화 시 주석
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dicService = Provider.of<DicService>(context, listen: false);
    String? captionsTag = "";

    if (dicService.callbackStatus == true) {
      dicService.callbackStatus = false;
      refreshWebUrls();
    }
    return Consumer<DicService>(
      builder: (context, dicService, child) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  width: 400,
                  height: 50,
                  child: Center(
                    child: Text(
                      "사이트 등록을 위해 상단 왼쪽에 위치한 버튼을 클릭하세요!\nClick on the button located at the top left.",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold, // 텍스트를 굵게 만듭니다.
                        color: Colors.red, // 텍스트 색상을 변경합니다.
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Center(
                    child: ListView.separated(
                      itemCount: _captions.length,
                      itemBuilder: (BuildContext context, index) {
                        captionsTag = _captions[index]['tag'];

                        AssetImage assetImage;
                        Color? cardColor;
                        switch (captionsTag) {
                          case 'd':
                            assetImage = AssetImage(
                              'assets/images/web_address_d.png',
                            );
                            cardColor = Colors.blue[100];
                            break;
                          case 'w':
                            assetImage = AssetImage(
                              'assets/images/web_address_w.png',
                            );
                            cardColor = Color.fromARGB(255, 207, 208, 248);
                            break;
                          case 'm':
                            assetImage = AssetImage(
                              'assets/images/web_address_m.png',
                            );
                            cardColor = Color.fromARGB(255, 255, 211, 130);
                            break;
                          case 'g':
                            assetImage = AssetImage(
                              'assets/images/web_address_g.png',
                            );
                            cardColor = Color.fromARGB(255, 238, 241, 204);
                            break;
                          default:
                            assetImage = AssetImage(
                              'assets/images/web_address_e.png',
                            );
                            cardColor = Color.fromARGB(255, 200, 216, 214);
                            break;
                        }

                        return Card(
                          color: cardColor,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ListTile(
                              leading: Image(
                                image: assetImage,
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                              ),
                              title: Text(
                                _captions[index]['caption'],
                                style: TextStyle(fontSize: 20),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.vertical_align_top),
                                    onPressed: () async {
                                      final objMaxOdr =
                                          await SQLWebHelper.getMaxUsedCnt();

                                      int iMaxOrder = 0;

                                      if (objMaxOdr.isNotEmpty) {
                                        iMaxOrder = objMaxOdr[0]['max_order'];
                                      }

                                      SQLWebHelper.updateMaxUsedCnt(
                                        _captions[index]['id'],
                                        iMaxOrder,
                                      );

                                      refreshWebUrls();
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      CupertinoIcons.pencil_circle_fill,
                                    ),
                                    onPressed: () {
                                      Scaffold.of(context).openEndDrawer();
                                      dicService.dicCaptionItem =
                                          _captions[index];
                                      refreshWebUrls();
                                    },
                                  ),
                                ],
                              ),
                              onTap: () async {
                                SQLWebHelper.updateUsedCnt(
                                  _captions[index]['id'],
                                );
                                dicService.webData = _captions[index];
                                _launchUrl(
                                  context,
                                  "http://${_captions[index]['web_url']}",
                                );

                                refreshWebUrls();
                              },
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider(
                          height: 2,
                          thickness: 2,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: 90,
                  child:
                      Container(), // AdMob 비활성화. 스토어 배포 시 AdWidget(ad: _bannerAd) 복구
                  // child: _bannerAd != null ? AdWidget(ad: _bannerAd) : Container(),
                ),
              ],
            ),
          ),
          endDrawer: Drawer(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DrawerWebPage(
                      onItemSelected: refreshThisPage,
                      captionItem: dicService.dicCaptionItem,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// url_launcher 를 이용하여 외부 브라우저로 URL 을 실행.
  /// 실행 불가 시 SnackBar 로 오류 메시지 표시.
  void _launchUrl(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      final snackBar = SnackBar(content: Text('Could not launch $url'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}
