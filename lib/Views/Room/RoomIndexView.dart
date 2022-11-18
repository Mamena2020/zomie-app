import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:zomie_app/Router/RouterService.dart';
import 'package:zomie_app/Services/WebRTC/Models/RoomInfo.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';
import 'package:zomie_app/Views/Room/LobbyView.dart';
import 'package:zomie_app/Views/Room/RoomView.dart';

class RoomIndexView extends StatefulWidget {
  const RoomIndexView({super.key});

  @override
  State<RoomIndexView> createState() => _RoomIndexViewState();
}

class _RoomIndexViewState extends State<RoomIndexView> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WRTCService.instance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GetRoom();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (mounted) {
      WRTCService.instance().EndCall();
    }
  }

  RoomInfo roomInfo = RoomInfo.init();
  bool init = false;
  GetRoom() async {
    roomInfo =
        await WRTCService.instance().getRoom(RouteService.params["id"] ?? '');
    print(roomInfo.message);

    setState(() {
      init = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            // IconButton(
            //     onPressed: () async {
            //       if (room_id != "") {
            //         await Clipboard.setData(ClipboardData(text: room_id));
            //       }
            //     },
            //     icon: Icon(Icons.copy))
          ],
        ),
        body: Container(
            color: Colors.white,
            child: Center(
              child: !init
                  ? CircularProgressIndicator()
                  : roomInfo.exist
                      ? WRTCService.instance().inCall
                          ? RoomView(
                              room: WRTCService.instance().room,
                              // onEndCall: () {
                              //   setState(() {});
                              // },
                            )
                          : LobbyView(
                              roomInfo: roomInfo,
                              onJoin: () {
                                setState(() {});
                              },
                            )
                      : Text("Room not found"),
            )));
  }
}
