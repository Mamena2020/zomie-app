import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sdp_transform/sdp_transform.dart' as sdpt;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCConsumerBloc.dart';
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCMessageBloc.dart';
import 'package:zomie_app/Services/WebRTC/Config/WRTCConfig.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Models/ResponseApi.dart';
import 'package:zomie_app/Services/WebRTC/Models/Room.dart';
import 'package:zomie_app/Services/WebRTC/RTCConnection/WRTCConsumer2.dart';
import 'package:zomie_app/Services/WebRTC/RTCConnection/WRTCProducer.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/SocketEvent.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocket.dart';

class WRTCService {
  bool inCall = false;
  //------------------------------ room
  Room room = Room.init();
  //------------------------------ producer
  WRTCProducer? wrtcProducer;
  Producer producer = Producer.initGenerate();

  WRTCConsumer2? wrtcConsumer2 = WRTCConsumer2(currentProducerId: "");

  //------------------------------
  WRTCService._() {
    WRTCSocket.instance();
    WRTCSocketEvent.Listen();
    wrtcConsumer2 = WRTCConsumer2(currentProducerId: this.producer.id);
    wrtcConsumer2!.init();
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

  AddConsumers(
      {required List<Producer> producers, required String room_id}) async {
    try {
      if (producers.isNotEmpty && room_id == this.room.id) {
        print("UPDATE ROOM FROM SERVER");
        producers.forEach((e) {
          if (e.id != this.producer.id) {
            WRTCConsumerBloc.instance.input.add(new WRTCConsumerEvent(
                producer: Producer(
                    id: e.id,
                    name: e.name,
                    hasMedia: e.hasMedia,
                    stream_id: ''),
                type: RoomEventType.join_room));
          }
        });
      }
    } catch (e) {
      print(e);
      print("ERROR Parsing data CONSUMER");
    }
  }

  void SetProducerName({required String name}) {
    this.producer.name = name;
  }

  Future<Room> CreateRoom({String? room_password, int? room_life_time}) async {
    try {
      this.room.password = null;
      if (room_password != null) {
        this.room.password = room_password;
      }
      this.room.life_time_minutes = 1;
      if (room_life_time != null) {
        this.room.life_time_minutes = room_life_time;
      }
      Map bodyParam = {};
      if (this.room.password != null) {
        bodyParam.addAll({"password": this.room.password});
      }
      bodyParam.addAll({"life_time": this.room.life_time_minutes});
      final res =
          await http.Client().post(Uri.parse(WRTCCOnfig.host + "/create-room"),
              headers: {
                "Content-Type": "application/json",
              },
              body: jsonEncode(bodyParam));
      if (res.statusCode == 200) {
        final body = await jsonDecode(res.body);
        this.room.id = body["room_id"];
      }
    } catch (e) {
      print(e);
    }
    return this.room;
  }

  Future<ResponseApi> _checkRoomExist() async {
    ResponseApi responseApi = ResponseApi.init();
    try {
      Map bodyParam = {};
      if (this.room.password != null) {
        bodyParam.addAll({"password": this.room.password});
      }
      bodyParam.addAll({"room_id": this.room.id});

      var url = WRTCCOnfig.host + "/check-room";
      var bodyJson = await jsonEncode(bodyParam);

      final res = await http.Client()
          .post(Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
              },
              body: bodyJson)
          .catchError((e) {
        print("!!!!!! error call api");
      });
      print(res.body);
      var body = await jsonDecode(res.body);
      responseApi.status_code = res.statusCode;
      responseApi.message = body["message"];
    } catch (e) {
      print(e);
    }
    return responseApi;
  }

  Future<void> JoinCall(
      {required String room_id, String? room_password}) async {
    try {
      if (room_id != null) {
        this.room.id = room_id;
      }
      if (room_password != null) {
        this.room.password = room_password;
      }

      ResponseApi _roomExist = await _checkRoomExist();
      if (_roomExist.status_code != 200) {
        if (defaultTargetPlatform != TargetPlatform.windows) {
          Fluttertoast.showToast(
              msg: _roomExist.message,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        }
        return;
      }

      this.wrtcProducer = new WRTCProducer(
          room_id: this.room.id,
          producer: this.producer,
          callType: CallType.videoCall);
      await this.wrtcProducer!.CreateConnection();
      if (this.wrtcProducer!.producer.id != null) {
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
      await WRTCSocketEvent.UpdateDataToServer();
    }
  }

  bool get isVideoOn => this.producer.hasMedia.video;
  Future<void> CameraOnOff() async {
    if (this.wrtcProducer != null) {
      await this.wrtcProducer!.CameraOnOff();
      await WRTCSocketEvent.UpdateDataToServer();
    }
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
      if (this.wrtcConsumer2 != null) {
        await this.wrtcConsumer2!.Dispose();
        // this.wrtcConsumer2 = null;
      }

      if (this.wrtcProducer != null) {
        var data = {
          "room_id": this.room.id,
          "producer_id": this.wrtcProducer!.producer.id
        };
        WRTCSocket.instance().socket.emit("end-call", data);
        this.wrtcProducer!.Dispose();
        this.wrtcProducer = null;
      }
      await WRTCConsumerBloc.instance.RemoveAllConsumers();
      await WRTCMessageBloc.instance().Destroy();

      this.room = Room.init();
      this.inCall = false;
    } catch (e) {
      print(e);
    }
  }

  //------------------------------------------------------------------------------------------
  //------------------------------------------------------------------------------------------ static functions
  //------------------------------------------------------------------------------------------

}
