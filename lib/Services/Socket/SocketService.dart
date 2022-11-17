import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static const _host = "http://192.168.1.5:5000";
  late IO.Socket socket;
  SocketService._() {
    // Uri _uri = Uri.parse);
    socket = IO.io(
        _host,
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
  static final instance = SocketService._();
}
