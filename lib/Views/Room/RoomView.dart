import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:zomie_app/Router/RouterService.dart';
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCMessageBloc.dart';
import 'package:zomie_app/Services/WebRTC/Config/WRTCConfig.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';
import 'package:zomie_app/Services/WebRTC/Widgets/WIdgets.dart';

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
    WRTCService.instance().isShareScreen.addListener(() {
      if (mounted) {
        setState(() {});
      }
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
                .wrtcProducer!
                .ShowConsumers(height: height, width: width),
            Actions(),
            roomInfoIcon(),
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
            // Chat
          ]),
        ),
      ),
    );
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
            // -------------------------------------------------------------------- camera
            WRTCService.instance().wrtcProducer!.ShowCameraIcon(onChange: () {
              setState(() {});
            }),
            // -------------------------------------------------------------------- endcall
            WRTCWidgets.EndCallButton(context: context),
            // -------------------------------------------------------------------- screen share
            WRTCService.instance().ShareScreenButton(),
            // -------------------------------------------------------------------- message button
            WRTCWidgets.ChatButton(onTap: () {
              setState(() {});
            })
            // -------------------------------------------------------------------- message button
          ],
        ),
      ),
    );
  }

  Widget producerMedia() {
    double _size = width > height ? width : height;
    if (WRTCService.instance().wrtcProducer!.consumers.length > 2) {
      _size = _size * 0.1;
    } else {
      _size = _size * 0.15;
    }
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: WRTCService.instance().inCall
            ? WRTCService.instance().wrtcProducer!.ShowMedia(
                size: Size(_size, _size),
                allowResize: true,
                onResize: () {
                  setState(() {});
                })
            : SizedBox(),
      ),
    );
  }

  bool isShowRoomInfo = false;

  Widget roomInfoIcon() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: new BackdropFilter(
                  filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: InkWell(
                    onTap: () async {
                      setState(() {
                        isShowRoomInfo = !isShowRoomInfo;
                      });
                    },
                    child: new Container(
                      width: 25.0,
                      height: 25.0,
                      decoration: new BoxDecoration(
                        color: isShowRoomInfo
                            ? Colors.grey.shade200.withOpacity(0.3)
                            : Colors.blue.shade800.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          new BoxShadow(
                              color: isShowRoomInfo
                                  ? Colors.blue.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.5),
                              blurRadius: 10.0,
                              spreadRadius: 10),
                        ],
                      ),
                      child: new Center(
                        child: Icon(
                          MdiIcons.dotsVertical,
                          color: isShowRoomInfo
                              ? Colors.blue.shade700
                              : Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(alignment: Alignment.bottomRight, child: roomInfo())
        ],
      ),
    );
  }

  static String roomInfoText = "Room ID: " +
      WRTCService.instance().room.id +
      (WRTCService.instance().room.password_required
          ? "\nPassword: " + WRTCService.instance().room.password!
          : "") +
      "\nLink: " +
      WRTCCOnfig.host +
      "/room/" +
      WRTCService.instance().room.id;

  Widget roomInfo() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: AnimatedContainer(
        height: isShowRoomInfo ? 200 : 0,
        width: isShowRoomInfo ? 250 : 0,
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            new BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 10.0,
                spreadRadius: 10),
          ],
        ),
        child: !isShowRoomInfo
            ? SizedBox()
            : ListView(
                // mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                        onPressed: () {
                          setState(() {
                            isShowRoomInfo = false;
                          });
                        },
                        icon: Icon(Icons.close)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, right: 10),
                    child: Row(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            // boxShadow: [
                            //   new BoxShadow(
                            //       color: Colors.grey.withOpacity(0.3),
                            //       blurRadius: 10.0,
                            //       spreadRadius: 10),
                            // ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SelectableText(
                              roomInfoText,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  wordSpacing: 2, height: 2, fontSize: 12),
                            ),
                          ),
                        )),
                        IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: roomInfoText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Room info copied to clipboard")));
                            },
                            icon: Icon(
                              Icons.copy,
                              size: 17,
                            ))
                      ],
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
