import 'dart:convert';
import 'package:app_wallet_app/common/AppCache.dart';
import 'package:app_wallet_app/common/common_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:device_apps/device_apps.dart';

class PageMyUserGov extends StatefulWidget {
  const PageMyUserGov({Key? key}) : super(key: key);

  @override
  State<PageMyUserGov> createState() => _PageMyUserGovState();
}

class _PageMyUserGovState extends State<PageMyUserGov> {
  CommonHelper commonHelper = CommonHelper.instance;

  Future<List<CachedApplication>> _getInstalledApplications() async {
    List<CachedApplication> tmpAllApps = [];

    for (var myApp in commonHelper.appDataWithMine) {
      if (myApp["app_user_group"] == "U01") {
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
          title: Text("기관 리스트(6/6)"),
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
