import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';

class RTCMessage {
  String messsage;
  Producer producer;
  WRTCMessageType type;
  RTCMessage(
      {required this.producer, required this.messsage, required this.type});

  factory RTCMessage.fromJson(Map<dynamic, dynamic> json) => RTCMessage(
      producer: Producer.fromJson(json["producer"]),
      messsage: json["message"],
      type: WRTCMessageType.message);

  factory RTCMessage.init() => RTCMessage(
      producer: Producer.init(), messsage: "", type: WRTCMessageType.none);
}
