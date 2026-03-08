import 'package:app_wallet_app/common/sql_web_helper.dart';
//import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DicService extends ChangeNotifier {
  var ansStatus = "L";
  bool callbackStatus = false;
  Map<String, dynamic> dicCaptionItem = Map();

  //2023.06.04 추가
  List<Map<String, dynamic>> captions = [];

  // All Words
  Map<String, dynamic> webData = {};

  int totPage = 0;
  int currentPage = 0;

  Future<void> callbackRefreshWebUrls() async {
    var data = await SQLWebHelper.getWebInfos();
    captions = data;
    data = [];
    notifyListeners();
  }

  void showExistStatus(String pCaption) {
    Fluttertoast.showToast(
        msg: "$pCaption 은 존재합니다. \nURL을 확인하세요.",
        toastLength: Toast.LENGTH_LONG,
        fontSize: 14,
        backgroundColor: Colors.green);
  }

  void showCheckItems(String pItem) {
    Fluttertoast.showToast(
        msg: "$pItem 항목이 비웠습니다.",
        toastLength: Toast.LENGTH_LONG,
        fontSize: 14,
        backgroundColor: Colors.green);
  }

  void showCheckUrl() {
    Fluttertoast.showToast(
        msg: "입력된 값이 URL 형식이 아닙니다.",
        toastLength: Toast.LENGTH_LONG,
        fontSize: 14,
        backgroundColor: Colors.green);
  }

  void showChkClckTxt() {
    Fluttertoast.showToast(
        msg: "직접입력불가, 분류버튼을 클릭하세요.",
        toastLength: Toast.LENGTH_LONG,
        fontSize: 14,
        backgroundColor: Colors.green);
  }

  void callNotifyListeners() {
    notifyListeners();
  }
}
