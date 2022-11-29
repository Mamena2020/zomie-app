import 'package:uuid/uuid.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/HasMedia.dart';
import 'package:zomie_app/Services/WebRTC/Utils/WRTCUtils.dart';

class Producer {
  String id;
  String user_id;
  String name;
  String stream_id;
  HasMedia hasMedia;
  ProducerType type;
  String platform;

  Producer(
      {required this.id,
      required this.user_id,
      required this.name,
      required this.hasMedia,
      required this.stream_id,
      required this.platform,
      required this.type});

  factory Producer.copy(Producer origin) => Producer(
        id: origin.id,
        user_id: origin.user_id,
        name: origin.name,
        stream_id: origin.stream_id,
        hasMedia: HasMedia.copy(origin.hasMedia),
        platform: origin.platform,
        type: origin.type,
      );

  static ProducerType _typeByName(String name_) {
    if (ProducerType.screen.name == name_)
      return ProducerType.screen;
    else
      return ProducerType.user;
  }

  factory Producer.fromJson(Map<dynamic, dynamic> json) => new Producer(
      id: json["id"] ?? '',
      user_id: json["user_id"] ?? '',
      name: json["name"] ?? '',
      stream_id: json['stream_id'] ?? '',
      hasMedia: HasMedia.fromJson(
          {"has_video": json["has_video"], "has_audio": json["has_audio"]}),
      platform: json["platform"] ?? "",
      type: _typeByName(json["type"]));

  factory Producer.init() => Producer(
      id: "",
      user_id: "",
      name: "",
      stream_id: '',
      hasMedia: HasMedia.init(),
      platform: "",
      type: ProducerType.user);
  factory Producer.initGenerate() => Producer(
      id: WRTCUtils.uuidV4(),
      user_id: WRTCUtils.uuidV4(),
      stream_id: '',
      name: "User-" + WRTCUtils.uuidV4().substring(0, 5),
      hasMedia: HasMedia.init(),
      platform: "",
      type: ProducerType.user);

  Map<String, dynamic> toJson() => {
        "id": this.id,
        "user_id": this.user_id,
        "name": this.name,
        "has_video": this.hasMedia.video,
        "has_audio": this.hasMedia.audio,
        "stream_id": this.stream_id,
        "platform": this.platform,
        "type": this.type.name
      };
}
