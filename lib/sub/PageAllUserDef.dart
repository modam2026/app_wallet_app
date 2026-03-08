import 'dart:convert';
import 'package:app_wallet_app/common/AppCache.dart';
import 'package:app_wallet_app/common/DataSearch.dart';
import 'package:app_wallet_app/common/sql_helper.dart';
import 'package:app_wallet_app/common/common_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:device_apps/device_apps.dart';

class PageAllUserDef extends StatefulWidget {
  const PageAllUserDef({Key? key}) : super(key: key);

  @override
  State<PageAllUserDef> createState() => _PageAllUserDefState();
}

class _PageAllUserDefState extends State<PageAllUserDef> {
  CommonHelper commonHelper = CommonHelper.instance;
  List<CachedApplication> apps_search = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("사용자 앱 리스트(1/3)"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              padding: EdgeInsets.fromLTRB(0, 0, 26, 0),
              onPressed: () {
                showSearch(context: context, delegate: DataSearch(apps_search));
              },
            ),
          ],
        ),
        body: FutureBuilder<List<CachedApplication>>(
          future: commonHelper
              .getListCachedApplication(commonHelper.appDataWithUser),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.error != null) {
              return Center(child: Text('An error occurred!'));
            } else {
              var apps = snapshot.data!;
              apps_search.clear();
              apps_search = List.from(apps);

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
                  return FutureBuilder<bool>(
                    future: SQLHelper.isAppInDatabase(
                        appWithIcon.appName, appWithIcon.packageName),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.error != null) {
                        return Text('An error occurred!');
                      } else {
                        bool isAppInDatabase = snapshot.data!;
                        return ListTile(
                          // tileColor: isAppInDatabase
                          //     ? Color.fromARGB(255, 223, 239, 247)
                          //     : null,
                          leading: Image(image: icon, width: 50, height: 50),
                          title: Text(appWithIcon.appName),
                          subtitle: Text(appWithIcon.packageName),
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(
                              icon: Icon(isAppInDatabase
                                  ? CupertinoIcons.minus_circled
                                  : CupertinoIcons.add_circled_solid),
                              onPressed: () async {
                                if (isAppInDatabase) {
                                  await SQLHelper.deleteMyIntrnAppInfo(
                                      appWithIcon.appName,
                                      appWithIcon.packageName);
                                  commonHelper.deleteApp(appWithIcon);
                                } else {
                                  await SQLHelper.addMyIntrnAppInfo(
                                      appWithIcon.appName,
                                      appWithIcon.packageName,
                                      "All");
                                }
                                setState(() {});
                              },
                            ),
                          ]),
                          onTap: () {
                            commonHelper.openApp(appWithIcon);
                          },
                        );
                      }
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
