import 'dart:convert';
import 'package:app_wallet_app/common/AppCache.dart';
import 'package:app_wallet_app/common/common_helper.dart';
//import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

class DataSearch extends SearchDelegate<CachedApplication?> {
  List<CachedApplication> pApps;

  DataSearch(this.pApps);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    CommonHelper commonHelper = CommonHelper.instance;
    final suggestionList = query.isEmpty
        ? pApps
        : pApps
              .where(
                (app) =>
                    app.appName.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

    // Here we get the height of the screen using MediaQuery
    double screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height:
          screenHeight * 1.0, // Assigning 60% of the height to the Container
      child: ListView.builder(
        itemBuilder: (context, index) => ListTile(
          leading: Image(
            image: MemoryImage(base64Decode(suggestionList[index].icon)),
            width: 50,
            height: 50,
          ),
          title: Text(suggestionList[index].appName),
          //subtitle: Text(suggestionList[index].packageName),
          onTap: () {
            commonHelper.openApp(suggestionList[index]);
            Navigator.pop(context);
          },
        ),
        itemCount: suggestionList.length,
      ),
    );
  }
}
