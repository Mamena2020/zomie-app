import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCMessageBloc.dart';
import 'package:zomie_app/Services/WebRTC/Config/WRTCConfig.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Models/ResponseApi.dart';
import 'package:zomie_app/Services/WebRTC/Models/Room.dart';
import 'package:zomie_app/Services/WebRTC/RTCConnection/WRTCProducer.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocketEvent.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocketFunction.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocket.dart';
import 'package:zomie_app/Services/WebRTC/Utils/WRTCUtils.dart';

class WRTCService {
  bool inCall = false;
  bool isShareScreen = false;
  //------------------------------ room
  Room room = Room.init();
  //------------------------------ producer
  WRTCProducer? wrtcProducer;
  WRTCProducer? wrtcShareScreen;

  Producer producer = Producer.initGenerate();

  WRTCService._() {
    WRTCSocket.instance();
    WRTCSocketEvent.Listen();
  }
  static WRTCService? _singleton = new WRTCService._();

  static WRTCService instance() {
    if (_singleton == null) {
      _singleton = new WRTCService._();
    }
    return _singleton!;
  }

  Future<void> Destroy() async {
    await EndCall();
    await WRTCSocket.instance().destroy();
    _singleton = null;
  }

  Future<void> SetProducerName({required String name}) async {
    this.producer.name = name;
  }

  Future<void> InitProducer({required Room room}) async {
    this.room = room;

    this.wrtcProducer = new WRTCProducer(
        room: this.room,
        producer: this.producer,
        producerType: ProducerType.user,
        callType: CallType.videoCall);
  }

  Future<void> JoinCall({required Room room}) async {
    try {
      if (this.wrtcProducer == null) {
        await InitProducer(room: room);
      }
      await this.wrtcProducer!.CreateConnection();
      if (this.wrtcProducer!.isConnected.value) {
        this.inCall = true;
      }
    } catch (e) {
      print(e);
    }
  }

  bool get isAudioOn => this.producer.hasMedia.audio;
  Future<void> MuteUnMuted() async {
    if (this.wrtcProducer != null) {
      await this.wrtcProducer!.MuteUnMute();
      await WRTCSocketFunction.UpdateDataToServer();
    }
  }

  bool get isVideoOn => this.producer.hasMedia.video;
  Future<void> CameraOnOff() async {
    if (this.wrtcProducer != null) {
      await this.wrtcProducer!.CameraOnOff();
      await WRTCSocketFunction.UpdateDataToServer();
    }
  }

  Future<void> StartShareScreen() async {
    Producer _producerScreen = await Producer.initGenerate();
    _producerScreen.user_id == this.producer.user_id;
    _producerScreen.name == this.producer.name;

    this.wrtcShareScreen = new WRTCProducer(
        producer: _producerScreen,
        room: this.room,
        producerType: ProducerType.screen,
        callType: CallType.screenSharing);

    await this.wrtcShareScreen!.CreateConnection();
    if (this.wrtcShareScreen!.isConnected.value) {
      this.isShareScreen = true;
    }
  }

  Future<void> StopShareScreen() async {
    await this.wrtcShareScreen!.Dispose();
    this.wrtcShareScreen = null;
    this.isShareScreen = false;
  }

  Widget ShareScreenButton({Function? onChange}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: InkWell(
            onTap: () async {
              if (this.wrtcShareScreen != null) {
                await StopShareScreen();
              } else {
                await StartShareScreen();
              }
              if (onChange != null) {
                onChange();
              }
            },
            child: new Container(
              width: 35.0,
              height: 35.0,
              decoration: new BoxDecoration(
                color: !this.isShareScreen
                    ? Colors.grey.shade200.withOpacity(0.3)
                    : Colors.blue.shade800.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  new BoxShadow(
                      color: isShareScreen
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.black.withOpacity(0.5),
                      blurRadius: 10.0,
                      spreadRadius: 10),
                ],
              ),
              child: new Center(
                child: Icon(
                  Icons.screen_share,
                  color: isShareScreen ? Colors.blue.shade700 : Colors.white,
                  size: 17,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Using this in dispose
  /// ```dart
  /// @override
  /// void dispose() {
  ///   super.dispose();
  ///   if (mounted) {
  ///      WRTCService.instance.EndCall();
  ///   }
  /// }
  /// ```
  Future<void> EndCall() async {
    try {
      if (this.wrtcProducer != null) {
        if (this.wrtcShareScreen != null) {
          await this.wrtcShareScreen!.Dispose();
        }

        this.wrtcProducer!.Dispose();
        // this.wrtcProducer = null;
      }
      await WRTCMessageBloc.instance().Destroy();

      // this.room = Room.init();
      this.inCall = false;
    } catch (e) {
      print(e);
    }
  }

  //------------------------------------------------------------------------------------------
  //------------------------------------------------------------------------------------------ static functions
  //------------------------------------------------------------------------------------------

}
