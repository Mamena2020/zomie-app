import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Candidate.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Models/RTCMessage.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocket.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';

class WRTCSocketFunction {
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
    required String room_id,
    required String producer_id,
  }) async {
    RTCMessage rtcMessage = RTCMessage.init();
    try {
      Map _data = {
        "room_id": room_id,
        "producer_id": producer_id,
        "message": message,
        "type": type.name
      };
      rtcMessage.producer = Producer.copy(WRTCService.instance().producer);
      rtcMessage.messsage = message;
      rtcMessage.type = WRTCMessageType.message;
      WRTCSocket.instance().socket.emit("notify-to-server", _data);
    } catch (e) {
      print(e);
    }
    return rtcMessage;
  }

  static Future<void> sdpToServer(
      {required String producer_id, required String sdp}) async {
    Map<String, String> _data = {"producer_id": producer_id, "sdp": sdp};

    WRTCSocket.instance().socket.emit("sdp-to-server", _data);
  }

  static Future<void> addCandidateToServer(
      {required String producer_id, required Candidate candidate}) async {
    Map _data = {"producer_id": producer_id, "candidate": candidate};
    WRTCSocket.instance().socket.emit("candidate-to-server", _data);
  }

  static Future<void> endCall(
      {required String producer_id, required String room_id}) async {
    Map _data = {"producer_id": producer_id, "room_id": room_id};

    WRTCSocket.instance().socket.emit("end-call", _data);
  }
}
