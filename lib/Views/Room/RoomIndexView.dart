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
  bool isLoad = false;
  GetRoom() async {
    roomInfo =
        await WRTCService.instance().getRoom(RouteService.params["id"] ?? '');
    print(roomInfo.message);

    setState(() {
      isLoad = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return !isLoad
        ? template(child: CircularProgressIndicator())
        : !roomInfo.exist
            ? template(child: Text("Room not found"), showAppbar: true)
            : roomExist();
  }

  Widget template({required Widget child, bool showAppbar = false}) {
    return Scaffold(
        appBar: showAppbar ? AppBar() : null,
        body: Container(
          child: Center(child: child),
        ));
  }

  Widget roomExist() {
    if (WRTCService.instance().inCall) {
      return RoomView();
    }
    return LobbyView(
      roomInfo: roomInfo,
      onJoin: () {
        setState(() {});
      },
    );
  }
}
