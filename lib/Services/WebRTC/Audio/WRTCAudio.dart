import 'package:audioplayers/audioplayers.dart';

class WRTCAudio {
  final _player = AudioPlayer();
  WRTCAudio._() {
    _LoadAssets();
  }

  Future<void> _LoadAssets() async {
    await _player.setSource(AssetSource('assets/audio/notif_1.wav'));
    await _player.setSource(AssetSource('assets/audio/notif_2.wav'));
    _player.setVolume(0.5);
  }

  static WRTCAudio? _singleton = WRTCAudio._();

  static WRTCAudio instance() {
    if (_singleton == null) {
      _singleton = new WRTCAudio._();
    }
    return _singleton!;
  }

  Future<void> playNotif() async {
    await _player.play(DeviceFileSource('assets/audio/notif_1.wav'));
  }
}
