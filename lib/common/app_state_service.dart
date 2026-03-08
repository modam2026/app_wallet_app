import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';

class AppStateService with ChangeNotifier {
  ApplicationWithIcon _app;

  AppStateService(this._app);

  ApplicationWithIcon get app => _app;

  set app(ApplicationWithIcon value) {
    _app = value;
    notifyListeners();
  }
}
