import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCMessageBloc.dart';
import 'package:zomie_app/Services/WebRTC/Config/WRTCConfig.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Models/ResponseApi.dart';
import 'package:zomie_app/Services/WebRTC/Models/Room.dart';
import 'package:zomie_app/Services/WebRTC/Models/RoomInfo.dart';
import 'package:zomie_app/Services/WebRTC/RTCConnection/WRTCProducer.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/SocketEvent.dart';
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
    producer.user_id = WRTCUtils.uuidV4();
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

  Future<RoomInfo> getRoom(String room_id) async {
    RoomInfo _room = RoomInfo.init();
    print("get room:" + room_id);
    var url = WRTCCOnfig.host + "/get-room?id=" + room_id;
    final response = await http.Client().get(Uri.parse(url)).catchError((e) {
      print("!!!!!! error get room");
    });
    if (response.statusCode == 200 || response.statusCode == 404) {
      _room = await RoomInfo.fromJson(jsonDecode(response.body));
      _room.exist = response.statusCode == 200 ? true : false;
    }
    return _room;
  }

  Future<ResponseApi> CheckRoom(
      {required String room_id, String? room_password}) async {
    ResponseApi responseApi = ResponseApi.init();
    try {
      if (room_id != null) {
        this.room.id = room_id;
      }
      if (room_password != null) {
        this.room.password = room_password;
      }

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

  Future<void> InitProducer({String? room_id, String? user_name}) async {
    if (room_id != null) {
      this.room.id = room_id;
    }
    if (user_name != null) {
      this.producer.name = user_name;
    }

    this.wrtcProducer = new WRTCProducer(
        room_id: this.room.id,
        producer: this.producer,
        producerType: ProducerType.user,
        callType: CallType.videoCall);
  }

  Future<void> JoinCall(
      {required String room_id, String? room_password}) async {
    try {
      if (this.wrtcProducer == null) {
        await InitProducer(room_id: room_id);
      }
      await this.wrtcProducer!.CreateConnection();
      // if (this.wrtcProducer!.isConnected) {
      //   this.inCall = true;
      //   print("Successful join room");
      // } else {
      //   print("failed to join the room");
      // }
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

  Future<void> StartShareScreen() async {
    if (this.wrtcShareScreen == null) {
      Producer _producer = Producer.copy(this.producer);
      _producer.id = WRTCUtils.uuidV4();
      this.wrtcShareScreen = WRTCProducer(
          producer: _producer,
          room_id: this.room.id,
          producerType: ProducerType.screen,
          callType: CallType.screenSharing);
    }
    await this.wrtcShareScreen!.CreateConnection();
    // if (this.wrtcShareScreen!.isConnected) {
    //   this.isShareScreen = true;
    // }
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
      // if (this.wrtcConsumer != null) {
      //   await this.wrtcConsumer!.Dispose();
      //   // this.wrtcConsumer = null;
      // }

      if (this.wrtcProducer != null) {
        var data = {
          "room_id": this.room.id,
          "producer_id": this.wrtcProducer!.producer.id
        };
        WRTCSocket.instance().socket.emit("end-call", data);
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
