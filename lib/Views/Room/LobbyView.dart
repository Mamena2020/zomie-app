import 'package:flutter/material.dart';
import 'package:zomie_app/Services/WebRTC/Controller/WRTCRoomController.dart';
import 'package:zomie_app/Services/WebRTC/Models/ResponseApi.dart';
import 'package:zomie_app/Services/WebRTC/Models/Room.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';
import 'package:zomie_app/Widgets/Widgets.dart';

class LobbyView extends StatefulWidget {
  Room room;
  Function onJoin;

  LobbyView({super.key, required this.room, required this.onJoin});
  @override
  State<LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<LobbyView> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PrepareForMeeting();
      ListenToJoinRoom();
    });
  }

  bool isLoad = false;
  PrepareForMeeting() async {
    await WRTCService.instance().InitProducer(room: this.widget.room);

    tecName.text = WRTCService.instance().producer.name;

    await WRTCService.instance().wrtcProducer!.GetUserMedia();
    setState(() {
      isLoad = true;
    });
  }

  ListenToJoinRoom() {
    WRTCService.instance().wrtcProducer!.isConnected.addListener(() {
      if (WRTCService.instance().wrtcProducer!.isConnected.value) {
        WRTCService.instance().inCall = true;
      }
      if (widget.onJoin != null) {
        widget.onJoin();
      }
    });
  }

  double height = 0;
  double width = 0;

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Lobby"),
        flexibleSpace: Widgets.AppbarBg(),
      ),
      body: Container(
        child: Center(
          child: !isLoad
              ? Text("Give permision camera & microphone")
              : WRTCService.instance().wrtcProducer!.stream == null
                  ? Text("You have to give permision camera & microphone")
                  : width > height
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            producerMedia(),
                            SizedBox(
                                height: width > height
                                    ? (width * 0.5) * 0.5
                                    : width * 0.9,
                                child: info())
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [producerMedia(), info()],
                          ),
                        ),
        ),
      ),
    );
  }

  Size _producerMediaSize() {
    Size _size = Size.zero;
    // landscape
    if (width > height) {
      _size = Size(width * 0.5, (width * 0.5) * 0.5);
    } else {
      if (width > 400) {
        _size = Size(350, 550);
      } else {
        _size = Size(width * 0.75, (width * 1.2));
      }
    }

    return _size;
  }

  Widget producerMedia() {
    return SizedBox(
        width: _producerMediaSize().width,
        height: _producerMediaSize().height,
        child: Stack(
          children: [
            WRTCService.instance().wrtcProducer!.ShowMedia(
                size: Size(
                    _producerMediaSize().width, _producerMediaSize().height)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WRTCService.instance().wrtcProducer!.ShowMicIcon(
                      onChange: () {
                    setState(() {});
                  }),
                  WRTCService.instance().wrtcProducer!.ShowCameraIcon(
                      onChange: () {
                    setState(() {});
                  }),
                ],
              ),
            )
          ],
        ));
  }

  TextEditingController tecPassword = TextEditingController();
  TextEditingController tecName = TextEditingController();
  ResponseApi responseName = ResponseApi.init();

  Widget info() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
                this.widget.room.participants.toString() + " partisipants"),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: 200.0,
              height: 60,
              child: SizedBox(
                height: 50,
                child: TextField(
                  controller: tecName,
                  maxLines: 1,
                  maxLength: 50,
                  onChanged: (c) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                      hintText: 'Name',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(vertical: 18.0),
                      errorText: responseName.status_code != 200
                          ? responseName.message
                          : null),
                ),
              ),
            ),
          ),
          !this.widget.room.password_required
              ? SizedBox()
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 200.0,
                    height: 60,
                    child: SizedBox(
                      height: 50,
                      child: TextField(
                        controller: tecPassword,
                        maxLines: 1,
                        maxLength: 50,
                        onChanged: (c) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 18.0),
                            errorText: responseRoom.status_code != 200
                                ? responseRoom.message
                                : null),
                      ),
                    ),
                  ),
                ),
          Center(child: JoinWidget())
        ],
      ),
    );
  }

  Widget JoinWidget() {
    if (!this.widget.room.password_required) {
      return JoinButton();
    } else {
      if (this.tecPassword.text.isNotEmpty) {
        return JoinButton();
      }
    }
    return SizedBox();
  }

  ResponseApi responseRoom = ResponseApi.init();
  bool joinPressing = false;
  Widget JoinButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 12),
      child: SizedBox(
        height: 40,
        width: 100,
        child: ElevatedButton(
          onPressed: () async {
            if (!joinPressing) {
              setState(() {
                joinPressing = true;
              });

              if (tecName.text.isEmpty || tecName.text.length < 4) {
                responseName = ResponseApi(
                    status_code: 403,
                    message: "Must be more than 4 characters");
              } else {
                responseName = ResponseApi.init();
              }

              responseRoom = await WRTCRoomController.CheckRoom(
                  room_id: widget.room.id,
                  password:
                      widget.room.password_required ? tecPassword.text : null);
              if (responseRoom.status_code == 200 &&
                  responseName.status_code == 200) {
                await WRTCService.instance()
                    .SetProducerName(name: tecName.text);
                await WRTCService.instance().JoinCall(
                  room: widget.room,
                );
                if (WRTCService.instance().inCall) {
                  print("JOIN SUCCESS");
                  widget.onJoin();
                }
              }
              if (mounted) {
                setState(() {
                  joinPressing = false;
                });
              }
            }
          },
          child: joinPressing
              ? Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : Text(
                  "Join now",
                  style: TextStyle(color: Colors.white),
                ),
          style: ElevatedButton.styleFrom(
            // shape: CircleBorder(),
            padding: EdgeInsets.all(10),
            backgroundColor: Colors.teal, // <-- Button color
            // foregroundColor: Colors.red, // <-- Splash color
          ),
        ),
      ),
    );
  }
}
