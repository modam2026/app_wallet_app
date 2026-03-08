import 'dart:convert'; // base64Decode 관련
import 'package:app_wallet_app/common/AppCache.dart';
import 'package:app_wallet_app/common/common_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:device_apps/device_apps.dart';

class PageMyUserSns extends StatefulWidget {
  const PageMyUserSns({Key? key}) : super(key: key);

  @override
  State<PageMyUserSns> createState() => _PageMyUserSnsState();
}

class _PageMyUserSnsState extends State<PageMyUserSns> {
  CommonHelper commonHelper = CommonHelper.instance;

  Future<List<CachedApplication>> _getInstalledApplications() async {
    List<CachedApplication> tmpAllApps = [];

    for (var myApp in commonHelper.appDataWithMine) {
      if (myApp["app_user_group"] == "U20" ||
          myApp["app_user_group"] == "U21" ||
          myApp["app_user_group"] == "U22" ||
          myApp["app_user_group"] == "U23" ||
          myApp["app_user_group"] == "U30") {
        tmpAllApps.add(myApp["cached_application"]);
      }
    }

    return tmpAllApps;
  }

  void _showConfirmationDialog(
      CachedApplication appWithIcon, BuildContext context) {
    commonHelper.showConfirmationDialog(appWithIcon, context, () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("SNS&OTT 리스트(2/6)"),
        ),
        body: FutureBuilder<List<CachedApplication>>(
          future: _getInstalledApplications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.error != null) {
              return Center(child: Text('An error occurred!'));
            } else {
              var apps = snapshot.data!;

              return ListView.separated(
                itemCount: apps.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.grey[350],
                  height: 1,
                  thickness: 1.0,
                ),
                itemBuilder: (context, index) {
                  var appWithIcon = apps[index] as CachedApplication;
                  ImageProvider icon =
                      MemoryImage(base64Decode(appWithIcon.icon));
                  return ListTile(
                    leading: Image(image: icon, width: 50, height: 50),
                    title: Text(appWithIcon.appName),
                    // subtitle: Text(appWithIcon.packageName),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: Icon(CupertinoIcons.ellipsis_vertical),
                        onPressed: () {
                          _showConfirmationDialog(appWithIcon, context);
                        },
                      ),
                    ]),
                    onTap: () {
                      commonHelper.openApp(appWithIcon);
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
