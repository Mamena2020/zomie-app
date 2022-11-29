import 'package:flutter/material.dart';
import 'package:zomie_app/Router/RouterService.dart';
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCMessageBloc.dart';
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
                .ShowConsumer(height: height, width: width),
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
            WRTCWidgets.ChatButton(onTap: () {
              setState(() {});
            })
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
}
