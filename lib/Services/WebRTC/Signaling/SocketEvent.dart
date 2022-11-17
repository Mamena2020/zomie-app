import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCConsumerBloc.dart';
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCMessageBloc.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Candidate.dart';
import 'package:zomie_app/Services/WebRTC/Models/ConsumerM.dart';
import 'package:zomie_app/Services/WebRTC/Models/HasMedia.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Models/RTCMessage.dart';
import 'package:zomie_app/Services/WebRTC/RTCConnection/WRTCConsumer.dart';
import 'package:zomie_app/Services/WebRTC/RTCConnection/WRTCConsumer2.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocket.dart';
import 'package:zomie_app/Services/WebRTC/Utils/WRTCUtils.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';

class WRTCSocketEvent {
  static Future<void> Listen() async {
    // ------------------------------------------------------------------------- consumer sdp from server
    WRTCSocket.instance().socket.on("consumer-sdp-from-server", (data) async {
      try {
        print("consumer-sdp-from-server");
        // print(data["sdp"]);
        if (WRTCService.instance().wrtcConsumer2! != null) {
          WRTCService.instance()
              .wrtcConsumer2!
              .RenegotiationNeeded(sdpRemote: data["sdp"]);
        }
      } catch (e) {
        print("error producer-sdp-from-server");
        print(e);
      }
    });
    // ------------------------------------------------------------------------- candidate producer
    WRTCSocket.instance().socket.on("producer-candidate-from-server", (data) {
      try {
        if (WRTCService.instance().wrtcProducer! != null &&
            WRTCService.instance().wrtcProducer!.peer != null &&
            data["producer_id"] ==
                WRTCService.instance().wrtcProducer!.producer.id) {
          WRTCService.instance().wrtcProducer!.peer!.addCandidate(
              new RTCIceCandidate(
                  data["candidate"]["candidate"].toString(),
                  data["candidate"]["sdpMid"].toString(),
                  int.parse(data["candidate"]["sdpMLineIndex"].toString())));
        }
      } catch (e) {
        print("error set candidate from server");
        print(e);
      }
    });
    // ------------------------------------------------------------------------- candidate consumers
    WRTCSocket.instance().socket.on("consumer-candidate-from-server", (data) {
      try {
        if (WRTCService.instance().wrtcConsumer2 != null) {
          print("candidate consumer");
          WRTCService.instance().wrtcConsumer2!.peer!.addCandidate(
              new RTCIceCandidate(
                  data["candidate"]["candidate"].toString(),
                  data["candidate"]["sdpMid"].toString(),
                  int.parse(data["candidate"]["sdpMLineIndex"].toString())));
        }
      } catch (e) {
        print("error set candidate consumer from server");
        print(e);
      }
    });

    // ------------------------------------------------------------------------- socket event from server...
    // type of notify: "join" | "leave" | "update" | "message" | "start_screen" | "stop_screen"
    WRTCSocket.instance().socket.on("producer-event", (data) async {
      try {
        print("event " + data["type"]);
        if (data["room_id"] == WRTCService.instance().room.id) {}

        Producer producer = Producer.fromJson(data["producer"]);
        WRTCConsumerEvent wrtcConsumerEvent = WRTCConsumerEvent.init();
        RTCMessage rtcMessage = RTCMessage.init();
        // --------------------------------------------------- join room
        if (data["type"] == "join") {
          // wrtcConsumerEvent = new WRTCConsumerEvent(
          //     producer: producer, type: RoomEventType.join_room);
          rtcMessage = RTCMessage(
              producer: producer,
              messsage: producer.name + " join the room",
              type: WRTCMessageType.join_room);

          newProducerJoin(data['producers']);
        }
        // --------------------------------------------------- leave room
        if (data["type"] == "leave") {
          // wrtcConsumerEvent = new WRTCConsumerEvent(
          //     producer: producer, type: RoomEventType.leave_room);
          rtcMessage = RTCMessage(
              producer: producer,
              messsage: producer.name + " leave the room",
              type: WRTCMessageType.leave_room);

          newProducerJoin(data['producers']);
        }
        // --------------------------------------------------- update data
        if (data["type"] == "update") {
          // wrtcConsumerEvent = new WRTCConsumerEvent(
          //     producer: producer, type: RoomEventType.update_data);
          WRTCService.instance()
              .wrtcConsumer2!
              .UpdateConsumer(producer: producer);
        }
        // --------------------------------------------------- seed message
        if (data["type"] == "message") {
          rtcMessage = RTCMessage.fromJson(data);
        }

        // ---------------- Adding event
        if (wrtcConsumerEvent.type != RoomEventType.none) {
          WRTCConsumerBloc.instance.input.add(wrtcConsumerEvent);
        }
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

  static Future<void> _AddCandidateToConsumers(
      {required Candidate candidate, required String consumer_id}) async {
    try {
      for (int i = 0; i < WRTCConsumerBloc.instance.rtcConsumers.length; i++) {
        if (WRTCConsumerBloc.instance.rtcConsumers[i].id == consumer_id &&
            WRTCConsumerBloc.instance.rtcConsumers[i].peer != null) {
          print("@@@@@@@@@@@@@@@@ add consumer candidate from server");
          await WRTCConsumerBloc.instance.rtcConsumers[i].peer!.addCandidate(
              new RTCIceCandidate(candidate.candidate, candidate.sdpMid,
                  candidate.sdpMLineIndex));
          print("----------------------------------");
          break;
        }
      }
    } catch (e) {
      print(e);
    }
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

  static Future<RTCMessage> SendMessage({required String message}) async {
    RTCMessage rtcMessage = RTCMessage.init();
    try {
      if (WRTCService.instance().wrtcProducer != null &&
          WRTCService.instance().inCall) {
        Map _data = {
          "room_id": WRTCService.instance().room.id,
          "producer_id": WRTCService.instance().producer.id,
          "message": message
        };
        rtcMessage.producer = Producer.copy(WRTCService.instance().producer);
        rtcMessage.messsage = message;
        rtcMessage.type = WRTCMessageType.message;
        WRTCSocket.instance().socket.emit("send-message", _data);
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

  static Future<void> newProducerJoin(dynamic data) async {
    if (!WRTCService.instance().inCall) {
      return;
    }

    if (WRTCService.instance().wrtcConsumer2 == null) {
      WRTCService.instance().wrtcConsumer2 = new WRTCConsumer2(
          currentProducerId: WRTCService.instance().producer.id);
    }
    if (WRTCService.instance().wrtcConsumer2!.peer == null) {
      await WRTCService.instance().wrtcConsumer2!.init();
    }

    List<Producer> producers = await List<Producer>.from(
        data.map((e) => Producer.fromJson(e)).toList());

    await WRTCService.instance()
        .wrtcConsumer2!
        .UpdateConsumers(producers: producers);

    WRTCSocket.instance().socket.emit(
        "consumer-update", {"producer_id": WRTCService.instance().producer.id});
  }

  static bool isExist(List<ConsumerM> list, producer_id) {
    for (var p in list) {
      if (p.producer.id == producer_id) {
        return true;
      }
    }
    return false;
  }
}
