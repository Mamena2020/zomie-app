import 'package:flutter/material.dart';
import 'package:zomie_app/Services/WebRTC/Models/ResponseApi.dart';
import 'package:zomie_app/Services/WebRTC/Models/RoomInfo.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';

class LobbyView extends StatefulWidget {
  RoomInfo roomInfo;
  Function onJoin;

  LobbyView({super.key, required this.roomInfo, required this.onJoin});
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
    WRTCService.instance().InitProducer(room_id: this.widget.roomInfo.id);
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
        _size = Size(400, 600);
      } else {
        _size = Size(width * 0.8, (width * 1.2));
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
            WRTCService.instance().wrtcProducer!.ShowMedia(),
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
                this.widget.roomInfo.participants.toString() + " partisipants"),
          ),
          !this.widget.roomInfo.password
              ? SizedBox()
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 150.0,
                    height: 60,
                    child: SizedBox(
                      height: 50,
                      child: TextField(
                        controller: tecPassword,
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
    if (!this.widget.roomInfo.password) {
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
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 40,
        width: 100,
        child: ElevatedButton(
          onPressed: () async {
            if (!joinPressing) {
              setState(() {
                joinPressing = true;
              });
              responseRoom = await WRTCService.instance().CheckRoom(
                  room_id: widget.roomInfo.id,
                  room_password:
                      widget.roomInfo.password ? tecPassword.text : null);
              if (responseRoom.status_code == 200) {
                await WRTCService.instance().JoinCall(
                    room_id: widget.roomInfo.id,
                    room_password:
                        widget.roomInfo.password ? tecPassword.text : null);
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
