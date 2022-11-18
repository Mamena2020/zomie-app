import 'package:zomie_app/Services/WebRTC/Models/Room.dart';

class RoomInfo {
  String id;
  bool exist;
  String message;
  int participants;
  bool password;
  RoomInfo(
      {required this.id,
      required this.exist,
      required this.message,
      required this.participants,
      required this.password});
  factory RoomInfo.init() => RoomInfo(
      id: "", exist: false, message: "", participants: 0, password: false);

  factory RoomInfo.fromJson(Map<dynamic, dynamic> json) => RoomInfo(
      id: json["id"] ?? '',
      exist: false,
      message: json["message"] ?? '',
      participants: json["participants"] ?? 0,
      password: json["password"] != null
          ? (json["password"] == true || json["password"] == "true"
              ? true
              : false)
          : false);
}
