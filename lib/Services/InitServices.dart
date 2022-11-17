import 'package:flutter/material.dart';
import 'package:zomie_app/Router/RouterService.dart';
import 'package:zomie_app/Services/Socket/SocketService.dart';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

class InitServices {
  InitServices._() {
    WidgetsFlutterBinding.ensureInitialized();
  }
  Future<void> LoadAllServices() async {
    await _RouteServices();
    // await _SocketIo();
  }

  static final instance = InitServices._();
  // --------------------------------------------------------------------------- Routes
  Future<void> _RouteServices() async {
    await RouteService.setupRouter();
  }

  // --------------------------------------------------------------------------- Socket Io
  Future<void> _SocketIo() async {
    await SocketService.instance;
  }
  // ---------------------------------------------------------------------------

}
