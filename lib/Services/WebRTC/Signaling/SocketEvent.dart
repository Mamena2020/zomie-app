import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCMessageBloc.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Candidate.dart';
import 'package:zomie_app/Services/WebRTC/Models/ConsumerM.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Models/RTCMessage.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocket.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';

class WRTCSocketEvent {
  static Future<void> Listen() async {
    // ------------------------------------------------------------------------- consumers update streams

    WRTCSocket.instance().socket.on("update-consumers", (data) async {
      try {
        print("update-consumers");
        if (WRTCService.instance().wrtcProducer != null &&
            WRTCService.instance().wrtcProducer!.peer != null &&
            WRTCService.instance().wrtcProducer!.producer.id ==
                data["producer_id"]) {
          List<Producer> producers = await List<Producer>.from(
              data["producers"].map((e) => Producer.fromJson(e)).toList());
          await WRTCService.instance()
              .wrtcProducer!
              .UpdateConsumers(producers: producers);
          await WRTCService.instance().wrtcProducer!.UpdateConsumerStream();
        }
      } catch (e) {
        print("error update-consumers");
        print(e);
      }
    });
    // ------------------------------------------------------------------------- consumer sdp from server

    WRTCSocket.instance().socket.on("new-user-join-from-server", (data) async {
      try {
        print("new-user-join-from-server " + data["producer_id"]);
        if (WRTCService.instance().wrtcProducer != null &&
            WRTCService.instance().wrtcProducer!.peer != null &&
            WRTCService.instance().wrtcProducer!.producer.id ==
                data["producer_id"]) {
          WRTCService.instance().wrtcProducer!.handleNewUserJoin(data["sdp"]);
        }
      } catch (e) {
        print("error new-user-join-from-server");
        print(e);
      }
    });
    // ------------------------------------------------------------------------- candidate producer
    WRTCSocket.instance().socket.on("producer-candidate-from-server", (data) {
      try {
        var _candidate = new RTCIceCandidate(
            data["candidate"]["candidate"].toString(),
            data["candidate"]["sdpMid"].toString(),
            int.parse(data["candidate"]["sdpMLineIndex"].toString()));

        if (data["type"] == "user" &&
            WRTCService.instance().wrtcProducer != null &&
            WRTCService.instance().wrtcProducer!.peer != null &&
            WRTCService.instance().wrtcProducer!.producer.id ==
                data["producer_id"]) {
          WRTCService.instance().wrtcProducer!.peer!.addCandidate(_candidate);
        }
        if (data["type"] == "screen" &&
            WRTCService.instance().wrtcShareScreen != null &&
            WRTCService.instance().wrtcShareScreen!.peer != null &&
            WRTCService.instance().wrtcShareScreen!.producer.id ==
                data["producer_id"]) {
          WRTCService.instance()
              .wrtcShareScreen!
              .peer!
              .addCandidate(_candidate);
        }
      } catch (e) {
        print("error set candidate from server");
        print(e);
      }
    });

    // ------------------------------------------------------------------------- socket event from server...
    // type of notify: "join" | "leave" | "update" | "message" | "start_screen" | "stop_screen"
    WRTCSocket.instance().socket.on("producer-event", (data) async {
      try {
        print("event " + data["type"]);
        if (data["room_id"] != WRTCService.instance().room.id) {
          return;
        }

        Producer producer = Producer.fromJson(data["producer"]);
        RTCMessage rtcMessage = RTCMessage.init();
        List<Producer> producers = [];
        if (data["producers"] != null) {
          List<Producer> producers = await List<Producer>.from(
              data["producers"].map((e) => Producer.fromJson(e)).toList());
        }

        // --------------------------------------------------- join room
        if (data["type"] == "join") {
          rtcMessage = RTCMessage(
              producer: producer,
              messsage: producer.name + " join the room",
              type: WRTCMessageType.join_room);
        }
        // --------------------------------------------------- leave room
        if (data["type"] == "leave") {
          rtcMessage = RTCMessage(
              producer: producer,
              messsage: producer.name + " leave the room",
              type: WRTCMessageType.leave_room);
          if (WRTCService.instance().wrtcProducer!.peer != null) {
            WRTCService.instance()
                .wrtcProducer!
                .UpdateConsumers(producers: producers);
          }
        }
        // --------------------------------------------------- update data
        if (data["type"] == "update") {
          WRTCService.instance()
              .wrtcProducer!
              .UpdateConsumer(producer: producer);
        }
        // --------------------------------------------------- receive message
        if (data["type"] == "message") {
          rtcMessage = RTCMessage.fromJson(data);
        }

        // ---------------- Adding event
        if (rtcMessage.type != WRTCMessageType.none) {
          WRTCMessageBloc.instance().input.add(rtcMessage);
        }
      } catch (e) {
        print(e);
        print("error event from server");
      }
    });

    // ------------------------------------------------------------------------- detect if socket reconnect
    WRTCSocket.instance().socket.on("connect", (_) {
      UpdateDataToServer();
    });
    // -------------------------------------------------------------------------
  }

  static Future<void> UpdateDataToServer() async {
    try {
      if (WRTCService.instance().wrtcProducer != null &&
          WRTCService.instance().inCall) {
        Map _data = {
          "socket_id": WRTCSocket.instance().socket.id,
          "room_id": WRTCService.instance().room.id,
          "producer": WRTCService.instance().producer.toJson(),
        };
        print(_data);
        WRTCSocket.instance().socket.emit("update-data", _data);
      }
    } catch (e) {
      print(e);
    }
  }

  static Future<RTCMessage> NotifyServer({
    String message = "",
    required NotifyType type,
  }) async {
    RTCMessage rtcMessage = RTCMessage.init();
    try {
      if (WRTCService.instance().wrtcProducer != null &&
          WRTCService.instance().inCall) {
        Map _data = {
          "room_id": WRTCService.instance().room.id,
          "producer_id": WRTCService.instance().producer.id,
          "message": message,
          "type": type.name
        };
        rtcMessage.producer = Producer.copy(WRTCService.instance().producer);
        rtcMessage.messsage = message;
        rtcMessage.type = WRTCMessageType.message;
        WRTCSocket.instance().socket.emit("notify-server", _data);
      }
    } catch (e) {
      print(e);
    }
    return rtcMessage;
  }

  static Future<void> addProducerCandidateToServer(
      {required String producer_id, required Candidate candidate}) async {
    Map _data = {"producer_id": producer_id, "candidate": candidate};
    WRTCSocket.instance().socket.emit("producer-candidate-from-client", _data);
  }
}
