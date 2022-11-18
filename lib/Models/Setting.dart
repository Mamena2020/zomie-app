import 'package:zomie_app/Models/RoomLifeTime.dart';

class Setting {
  bool passwordRequired;
  bool askWhenJoin;
  RoomLifeTime roomLifeTime;

  Setting(
      {required this.passwordRequired,
      required this.askWhenJoin,
      required this.roomLifeTime});

  factory Setting.init() => Setting(
      passwordRequired: false,
      askWhenJoin: false,
      roomLifeTime: RoomLifeTime.init());

  factory Setting.fromJson(Map<dynamic, dynamic> json) => Setting(
      passwordRequired: json["passwordRequired"] != null
          ? json["passwordRequired"] == true ||
              json["passwordRequired"] == "true"
          : false,
      askWhenJoin: json["askWhenJoin"] != null
          ? json["askWhenJoin"] == true || json["askWhenJoin"] == "true"
          : false,
      roomLifeTime: json["roomLifeTime"] != null
          ? RoomLifeTime.fromJson(json["roomLifeTime"])
          : RoomLifeTime.init());

  Map<String, dynamic> toJson() => {
        "passwordRequired": this.passwordRequired,
        "askWhenJoin": this.askWhenJoin,
        "roomLifeTime": this.roomLifeTime.toJson()
      };
}
