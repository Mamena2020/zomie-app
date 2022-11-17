import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCConsumerBloc.dart';
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCMessageBloc.dart';
import 'package:zomie_app/Services/WebRTC/Models/ConsumerM.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/RTCConnection/WRTCConsumer.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';
import 'package:http/http.dart' as http;
import 'package:sdp_transform/sdp_transform.dart' as sdpt;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;

class RoomView extends StatefulWidget {
  static const routeName = "call";

  const RoomView({super.key});

  @override
  State<RoomView> createState() => _RoomViewState();
}

class _RoomViewState extends State<RoomView> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WRTCService.instance();
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
        child: Stack(children: [
          WRTCService.instance()
              .wrtcConsumer2!
              .Show(height: height, width: width),
          TextfieldRoom(),
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
          !WRTCMessageBloc.instance().isShow
              ? WRTCService.instance().inCall
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
                  : SizedBox()
              : SizedBox()
        ]),
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
            !WRTCService.instance().inCall
                ? ElevatedButton(
                    onPressed: () async {
                      await WRTCService.instance().CreateRoom();
                      tecRoomID.text = WRTCService.instance().room.id;
                      setState(() {});
                    },
                    child: Text(
                      "CREATE ROOM",
                      style: TextStyle(color: Colors.teal),
                    ),
                    style: ElevatedButton.styleFrom(
                      // shape: CircleBorder(),
                      padding: EdgeInsets.all(17),
                      backgroundColor: Colors.white, // <-- Button color
                      // foregroundColor: Colors.red, // <-- Splash color
                    ),
                  )
                : SizedBox(),

            // -------------------------------------------------------------------- mic
            WRTCService.instance().inCall
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: new BackdropFilter(
                        filter:
                            new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: InkWell(
                          onTap: () async {
                            await WRTCService.instance().MuteUnMuted();
                            setState(() {});
                          },
                          child: new Container(
                            width: 35.0,
                            height: 35.0,
                            decoration: new BoxDecoration(
                              color: Colors.grey.shade200.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                new BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 10.0,
                                    spreadRadius: 10),
                              ],
                            ),
                            child: new Center(
                              child: Icon(
                                WRTCService.instance().isAudioOn
                                    ? Icons.mic
                                    : Icons.mic_off,
                                color: WRTCService.instance().isAudioOn
                                    ? Colors.white
                                    : Colors.red.shade800,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : SizedBox(),
            // -------------------------------------------------------------------- endcall
            WRTCService.instance().inCall
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        onTap: () async {
                          await WRTCService.instance().EndCall();
                          setState(() {});
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
                  )
                : SizedBox(),
            // -------------------------------------------------------------------- camera
            WRTCService.instance().inCall
                ? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: new BackdropFilter(
                        filter:
                            new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: InkWell(
                          onTap: () async {
                            await WRTCService.instance().CameraOnOff();
                            setState(() {});
                          },
                          child: new Container(
                            width: 35.0,
                            height: 35.0,
                            decoration: new BoxDecoration(
                              color: Colors.grey.shade200.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                new BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 10.0,
                                    spreadRadius: 10),
                              ],
                            ),
                            child: new Center(
                              child: Icon(
                                WRTCService.instance().isVideoOn
                                    ? Icons.videocam
                                    : Icons.videocam_off,
                                color: WRTCService.instance().isVideoOn
                                    ? Colors.white
                                    : Colors.red.shade800,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : SizedBox(),
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
    if (WRTCConsumerBloc.instance.rtcConsumers.length > 2) {
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

  // Widget consumerMedia() {
  //   return StreamBuilder<List<WRTCConsumer>>(
  //       stream: WRTCConsumerBloc.instance.output,
  //       builder: (_, snapshot) {
  //         if (snapshot.hasData) {
  //           if (snapshot.data!.length == 1) {
  //             return Container(
  //                 height: height,
  //                 width: width,
  //                 child: Column(
  //                   children: [
  //                     snapshot.data!.first.ShowMedia(),
  //                   ],
  //                 ));
  //           } else if (snapshot.data!.length == 2) {
  //             if (height > width) {
  //               return Column(
  //                   children:
  //                       snapshot.data!.map((e) => e.ShowMedia()).toList());
  //             }
  //             return Row(
  //                 children: snapshot.data!.map((e) => e.ShowMedia()).toList());
  //           } else if (snapshot.data!.length > 2) {
  //             return GridView.count(
  //               crossAxisCount: height > width ? 2 : 3,
  //               children: snapshot.data!.map((e) => e.ShowMedia()).toList(),
  //             );
  //           }
  //           return SizedBox();
  //         }
  //         return SizedBox();
  //       });
  // }
}
