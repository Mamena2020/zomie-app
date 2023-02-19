class Room {
  String id;

  int participants;
  bool password_required;
  int video_bitrate;
  int screen_bitrate;
  int life_time;
  String? password;

  Room({
    required this.id,
    required this.participants,
    required this.password_required,
    required this.video_bitrate,
    required this.screen_bitrate,
    required this.life_time,
    this.password,
  });

  factory Room.init() => Room(
        id: "",
        participants: 0,
        password_required: false,
        video_bitrate: 90,
        screen_bitrate: 250,
        life_time: 1,
      );

  factory Room.fromJson(Map<dynamic, dynamic> json) => Room(
        id: json["id"] ?? '',
        life_time: json["life_time"] ?? 1,
        participants: json["participants"] ?? 0,
        password: json["password"],
        password_required: json["password_required"] != null
            ? (json["password_required"] == true ||
                    json["password_required"] == "true"
                ? true
                : false)
            : false,
        video_bitrate: json["video_bitrate"] ?? 90,
        screen_bitrate: json["screen_bitrate"] ?? 250,
      );
}
