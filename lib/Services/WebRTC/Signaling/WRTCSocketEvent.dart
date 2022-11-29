import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCMessageBloc.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Candidate.dart';
import 'package:zomie_app/Services/WebRTC/Models/ConsumerM.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Models/RTCMessage.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocketFunction.dart';
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
    // -------------------------------------------------------------------------  sdp from server

    WRTCSocket.instance().socket.on("sdp-from-server", (data) async {
      try {
        print("sdp-from-server " + data["producer_id"]);
        if (data["type"] == "user" &&
            WRTCService.instance().wrtcProducer != null &&
            WRTCService.instance().wrtcProducer!.peer != null &&
            WRTCService.instance().wrtcProducer!.producer.id ==
                data["producer_id"]) {
          WRTCService.instance().wrtcProducer!.handleSdpFromServer(data["sdp"]);
        }
        if (data["type"] == "screen" &&
            WRTCService.instance().wrtcShareScreen != null &&
            WRTCService.instance().wrtcShareScreen!.peer != null &&
            WRTCService.instance().wrtcShareScreen!.producer.id ==
                data["producer_id"]) {
          WRTCService.instance()
              .wrtcShareScreen!
              .handleSdpFromServer(data["sdp"]);
        }
      } catch (e) {
        print("error sdp-from-server");
        print(e);
      }
    });
    // ------------------------------------------------------------------------- candidate
    WRTCSocket.instance().socket.on("candidate-to-client", (data) {
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

    // ------------------------------------------------------------------------- notify from server...
    // type of notify: "join" | "leave" | "update" | "message" | "start_screen" | "stop_screen"
    WRTCSocket.instance().socket.on("notify-from-server", (data) async {
      try {
        print("event " + data["type"]);
        if (data["room_id"] != WRTCService.instance().room.id) {
          return;
        }

        Producer producer = Producer.fromJson(data["producer"]);
        RTCMessage rtcMessage = RTCMessage.init();
        List<Producer> producers = [];
        if (data["producers"] != null) {
          producers = await List<Producer>.from(
              data["producers"].map((e) => Producer.fromJson(e)).toList());
          print("data[producers] exist: " + producers.length.toString());
        } else {
          print("data[producers] is empty");
        }

        // --------------------------------------------------- join room
        if (data["type"] == "join") {
          String _message = producer.name + " join the room";
          WRTCMessageType _messageType = WRTCMessageType.join_room;
          if (producer.type == ProducerType.screen) {
            _message = producer.name + " start screen share";
            _messageType = WRTCMessageType.start_screen;
          }

          rtcMessage = RTCMessage(
              producer: producer, messsage: _message, type: _messageType);
        }
        // --------------------------------------------------- leave room
        if (data["type"] == "leave") {
          String _message = producer.name + " leave the room";
          WRTCMessageType _messageType = WRTCMessageType.leave_room;
          if (producer.type == ProducerType.screen) {
            _message = producer.name + " stop screen share";
            _messageType = WRTCMessageType.stop_screen;
          }
          rtcMessage = RTCMessage(
              producer: producer, messsage: _message, type: _messageType);
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
        // ---------------------------------------------------  message
        if (data["type"] == "message") {
          rtcMessage = RTCMessage.fromJson(data);
        }

        // ---------------- Adding Message
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
      WRTCSocketFunction.UpdateDataToServer();
    });
    // -------------------------------------------------------------------------
  }
}
