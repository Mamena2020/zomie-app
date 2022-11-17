import 'package:uuid/uuid.dart';
import 'package:zomie_app/Services/WebRTC/Models/HasMedia.dart';

class Producer {
  String id;
  String name;
  String stream_id;
  HasMedia hasMedia;

  Producer(
      {required this.id,
      required this.name,
      required this.hasMedia,
      required this.stream_id});

  factory Producer.copy(Producer origin) => Producer(
      id: origin.id,
      name: origin.name,
      stream_id: '',
      hasMedia: HasMedia.copy(origin.hasMedia));

  factory Producer.fromJson(Map<dynamic, dynamic> json) => Producer(
      id: json["id"],
      name: json["name"],
      stream_id: json['stream_id'] ?? '',
      hasMedia: HasMedia.fromJson(
          {"has_video": json["has_video"], "has_audio": json["has_audio"]}));

  factory Producer.init() =>
      Producer(id: "", name: "", stream_id: '', hasMedia: HasMedia.init());
  factory Producer.initGenerate() => Producer(
      id: _uuid.v4(),
      stream_id: '',
      name: "User-" + _uuid.v4().substring(0, 5),
      hasMedia: HasMedia.init());

  static Uuid _uuid = Uuid();

  Map<String, dynamic> toJson() => {
        "id": this.id,
        "name": this.name,
        "has_video": this.hasMedia.video,
        "has_audio": this.hasMedia.audio,
        "stream_id": this.stream_id
      };
}
