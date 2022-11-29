import 'package:flutter/material.dart';
import 'package:zomie_app/Router/RouterService.dart';
import 'package:zomie_app/Services/WebRTC/Controller/WRTCRoomController.dart';
import 'package:zomie_app/Services/WebRTC/Models/Room.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';
import 'package:zomie_app/Views/Room/LobbyView.dart';
import 'package:zomie_app/Views/Room/RoomView.dart';
import 'package:zomie_app/Widgets/Widgets.dart';

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

  Room room = Room.init();
  bool isLoad = false;
  GetRoom() async {
    room = await WRTCRoomController.getRoom(RouteService.params["id"] ?? '');

    setState(() {
      isLoad = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return !isLoad
        ? template(child: CircularProgressIndicator())
        : room.id == ""
            ? template(child: Text("Room not found"), showAppbar: true)
            : roomExist();
  }

  Widget template({required Widget child, bool showAppbar = false}) {
    return Scaffold(
        appBar: showAppbar
            ? AppBar(
                flexibleSpace: Widgets.AppbarBg(),
              )
            : null,
        body: Container(
          child: Center(child: child),
        ));
  }

  Widget roomExist() {
    if (WRTCService.instance().inCall) {
      return RoomView();
    }
    return LobbyView(
      room: room,
      onJoin: () {
        setState(() {});
      },
    );
  }
}
