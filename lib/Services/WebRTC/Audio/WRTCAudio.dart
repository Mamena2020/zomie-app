import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WRTCAudio {
  final _player = AudioPlayer();
  WRTCAudio._() {
    _LoadAssets();
  }

  Future<void> _LoadAssets() async {
    try {
      print("load asset audio notif");
      // await _player.setSource(AssetSource('asset/audio/notif_1.wav'));
      _player.setVolume(0.5);
    } catch (e) {
      print(e);

      print("error load asset audio notif");
    }
  }

  static WRTCAudio? _singleton = WRTCAudio._();

  static WRTCAudio instance() {
    if (_singleton == null) {
      _singleton = new WRTCAudio._();
    }
    return _singleton!;
  }

  /**
   * audioName = "notif_1.wav"
   */
  Future<void> playNotif({required String audioName}) async {
    try {
      if (kIsWeb) {
        _player.play(DeviceFileSource('assets/assets/audio/' + audioName));
        // _player.play(DeviceFileSource('assets/assets/audio/notif_1.wav'));
      } else {
        // _player.play(DeviceFileSource('asset/audio/notif_1.wav'));
        _player.play(DeviceFileSource('audio/' + audioName));
      }
    } catch (e) {
      print(e);
      print("error play audio notif");
    }
  }
}
