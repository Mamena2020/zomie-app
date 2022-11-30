import 'package:zomie_app/Models/RoomLifeTime.dart';

class Setting {
  bool passwordRequired;
  bool askWhenJoin;
  RoomLifeTime roomLifeTime;

  int video_bitrate;
  int screen_bitrate;

  Setting({
    required this.passwordRequired,
    required this.askWhenJoin,
    required this.roomLifeTime,
    required this.video_bitrate,
    required this.screen_bitrate,
  });

  factory Setting.init() => Setting(
      passwordRequired: false,
      askWhenJoin: false,
      roomLifeTime: RoomLifeTime.init(),
      screen_bitrate: 125,
      video_bitrate: 75);

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
          : RoomLifeTime.init(),
      video_bitrate: json["video_bitrate"] ?? 90,
      screen_bitrate: json["screen_bitrate"] ?? 250);

  Map<String, dynamic> toJson() => {
        "passwordRequired": this.passwordRequired,
        "askWhenJoin": this.askWhenJoin,
        "roomLifeTime": this.roomLifeTime.toJson(),
        "video_bitrate": this.video_bitrate,
        "screen_bitrate": this.screen_bitrate,
      };
}
