import 'package:flutter/material.dart';
import 'package:zomie_app/Router/RouterService.dart';
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCMessageBloc.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';

class RoomView extends StatefulWidget {
  RoomView({
    super.key,
  });

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("audio status:" + WRTCService.instance().isAudioOn.toString());
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (mounted) {
      WRTCService.instance().EndCall();
    }
  }

  double height = 0;
  double width = 0;

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        body: Container(
          color: Colors.white,
          child: Stack(children: [
            WRTCService.instance()
                .wrtcConsumer!
                .Show(height: height, width: width),
            Actions(),
            width > 550
                ? Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: producerMedia(),
                        ),
                      ),
                      WRTCMessageBloc.instance().Show(
                          screenWidth: width,
                          closeClick: () {
                            setState(() {});
                          })
                    ],
                  )
                : Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: producerMedia(),
                      ),
                      Align(
                          alignment: Alignment.centerRight,
                          child: WRTCMessageBloc.instance().Show(
                              screenWidth: width,
                              closeClick: () {
                                setState(() {});
                              }))
                    ],
                  ),
            Chat()
          ]),
        ),
      ),
    );
  }

  Widget Chat() {
    return !WRTCMessageBloc.instance().isShow
        ? Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    WRTCMessageBloc.instance().isShow = true;
                  });
                },
                child: Icon(Icons.chat_bubble, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(20),
                  backgroundColor: Colors.teal, // <-- Button color
                  // foregroundColor: Colors.red, // <-- Splash color
                ),
              ),
            ),
          )
        : SizedBox();
  }

  Widget Actions() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // -------------------------------------------------------------------- mic
            WRTCService.instance().wrtcProducer!.ShowMicIcon(onChange: () {
              setState(() {});
            }),
            // -------------------------------------------------------------------- endcall
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  onTap: () async {
                    String destination =
                        "/room/" + WRTCService.instance().room.id;
                    await WRTCService.instance().EndCall();
                    RouteService.router
                        .navigateTo(context, destination, replace: true);
                  },
                  child: new Container(
                    width: 50.0,
                    height: 40.0,
                    decoration: new BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        new BoxShadow(
                            color: Colors.black,
                            blurRadius: 10.0,
                            spreadRadius: 10),
                      ],
                    ),
                    child: new Center(
                      child: Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // -------------------------------------------------------------------- camera
            WRTCService.instance().wrtcProducer!.ShowCameraIcon(onChange: () {
              setState(() {});
            }),
            IconButton(
                onPressed: () async {
                  await WRTCService.instance().StartShareScreen();
                },
                icon: Icon(Icons.screen_share))
          ],
        ),
      ),
    );
  }

  TextEditingController tecRoomID = TextEditingController();

  Widget TextfieldRoom() {
    return WRTCService.instance().inCall
        ? SizedBox()
        : Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                height: 60,
                width: MediaQuery.of(context).size.width > 300
                    ? 300
                    : MediaQuery.of(context).size.width * 0.9,
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: TextField(
                          controller: tecRoomID,
                          onChanged: (c) {
                            setState(() {});
                          },
                          decoration: InputDecoration(hintText: 'Room id'),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (tecRoomID.text.isNotEmpty) {
                          await WRTCService.instance()
                              .JoinCall(room_id: tecRoomID.text);
                          setState(() {});
                        }
                      },
                      child: Text(
                        "JOIN NOW",
                      ),
                      style: ElevatedButton.styleFrom(
                        // shape: CircleBorder(),
                        padding: EdgeInsets.all(17),
                        backgroundColor: Colors.teal, // <-- Button color
                        // foregroundColor: Colors.red, // <-- Splash color
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
  }

  Widget producerMedia() {
    double _size = width > height ? width : height;
    if (WRTCService.instance().wrtcConsumer!.consumers.length > 2) {
      _size = _size * 0.1;
    } else {
      _size = _size * 0.15;
    }
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          // height: _size + _size * 0.5,
          height: _size,
          width: _size,
          child: WRTCService.instance().inCall
              ? WRTCService.instance().wrtcProducer!.ShowMedia()
              : SizedBox(),
        ),
      ),
    );
  }
}
