import 'package:app_wallet_app/sub/DrawerWebPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // 로컬용 비활성화. 스토어 배포 시 복구
import 'package:provider/provider.dart';
import 'package:app_wallet_app/common/dic_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_wallet_app/common/sql_web_helper.dart';

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

  void refreshThisPage() async {
    final dicService = Provider.of<DicService>(context, listen: false);
    setState(() {
      dicService.callbackStatus = true;
      dicService.callNotifyListeners();
    });
  }

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
    String? _captionsTag = "";

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
                        _captionsTag = _captions[index]['tag'];

                        AssetImage assetImage;
                        Color? cardColor;
                        switch (_captionsTag) {
                          case 'd':
                            assetImage =
                                AssetImage('assets/images/web_address_d.png');
                            cardColor = Colors.blue[100];
                            break;
                          case 'w':
                            assetImage =
                                AssetImage('assets/images/web_address_w.png');
                            cardColor = Color.fromARGB(255, 207, 208, 248);
                            break;
                          case 'm':
                            assetImage =
                                AssetImage('assets/images/web_address_m.png');
                            cardColor = Color.fromARGB(255, 255, 211, 130);
                            break;
                          case 'g':
                            assetImage =
                                AssetImage('assets/images/web_address_g.png');
                            cardColor = Color.fromARGB(255, 238, 241, 204);
                            break;
                          default:
                            assetImage =
                                AssetImage('assets/images/web_address_e.png');
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
                                style: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.vertical_align_top,
                                      ),
                                      onPressed: () async {
                                        final objMaxOdr =
                                            await SQLWebHelper.getMaxUsedCnt();

                                        int iMaxOrder = 0;

                                        if (objMaxOdr.isNotEmpty) {
                                          iMaxOrder = objMaxOdr[0]['max_order'];
                                        }

                                        SQLWebHelper.updateMaxUsedCnt(
                                            _captions[index]['id'], iMaxOrder);

                                        refreshWebUrls();
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                          CupertinoIcons.pencil_circle_fill),
                                      onPressed: () {
                                        Scaffold.of(context).openEndDrawer();
                                        dicService.dicCaptionItem =
                                            _captions[index];
                                        refreshWebUrls();
                                      },
                                    ),
                                  ]),
                              onTap: () async {
                                SQLWebHelper.updateUsedCnt(
                                    _captions[index]['id']);
                                dicService.webData = _captions[index];
                                _launchUrl(context,
                                    "http://${_captions[index]['web_url']}");

                                refreshWebUrls();
                              },
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return Divider(
                            height: 2, thickness: 2, color: Colors.white);
                      },
                    ),
                  ),
                ),
                Container(
                  height: 90,
                  child: Container(), // AdMob 비활성화. 스토어 배포 시 AdWidget(ad: _bannerAd) 복구
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
                        captionItem: dicService.dicCaptionItem),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _launchUrl(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      final snackBar = SnackBar(content: Text('Could not launch $url'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}
