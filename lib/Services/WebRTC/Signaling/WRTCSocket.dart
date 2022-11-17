import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:zomie_app/Services/WebRTC/Config/WRTCConfig.dart';

class WRTCSocket {
  late IO.Socket socket;
  WRTCSocket._() {
    socket = IO.io(
        WRTCCOnfig.host,
        IO.OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .setExtraHeaders({'foo': 'bar'}) // optional
            .build());
    // Dart client
    socket.onConnect((_) {
      print('connect');
    });
    socket.onDisconnect((_) => print('disconnect'));
    print("init socket");
  }
  static WRTCSocket? _singeton = new WRTCSocket._();

  static WRTCSocket instance() {
    if (_singeton == null) {
      _singeton = new WRTCSocket._();
    }
    return _singeton!;
  }

  destroy() {
    socket.destroy();
    _singeton = null;
  }

  close() {
    socket.close();
  }

  connect() {
    socket.connect();
  }
}
