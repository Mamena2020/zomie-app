import 'package:flutter/cupertino.dart';
import 'package:zomie_app/Models/Setting.dart';

class ProSet with ChangeNotifier {
  Setting _setting = Setting.init();
  Setting get setting => _setting;
  set setting(Setting input) {
    try {
      _setting = input;
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}
