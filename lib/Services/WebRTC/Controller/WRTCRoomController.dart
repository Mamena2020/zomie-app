import 'dart:convert';

import 'package:zomie_app/Services/WebRTC/Config/WRTCConfig.dart';
import 'package:zomie_app/Services/WebRTC/Models/ResponseApi.dart';
import 'package:zomie_app/Services/WebRTC/Models/Room.dart';
import 'package:http/http.dart' as http;

class WRTCRoomController {
  static Future<Room> CreateRoom(
      {String? password,
      int life_time = 1,
      required int video_bitrate,
      required int screen_bitrate}) async {
    Room room = Room.init();
    try {
      Map bodyParam = {};
      if (password != null) {
        bodyParam.addAll({"password": password});
      }
      bodyParam.addAll({
        "life_time": life_time,
        "video_bitrate": video_bitrate,
        "screen_bitrate": screen_bitrate
      });
      final res = await http.Client()
          .post(Uri.parse(WRTCCOnfig.host + "/api/create-room"),
              headers: {
                "Content-Type": "application/json",
              },
              body: jsonEncode(bodyParam));
      if (res.statusCode == 200) {
        final body = await jsonDecode(res.body);
        room.id = body["room_id"];
      }
    } catch (e) {
      print(e);
    }
    return room;
  }

  static Future<Room> getRoom(String room_id) async {
    Room room = Room.init();
    print("get room:" + room_id);
    var url = WRTCCOnfig.host + "/api/get-room?id=" + room_id;
    final response = await http.Client().get(Uri.parse(url)).catchError((e) {
      print("!!!!!! error get room");
    });
    if (response.statusCode == 200) {
      var body = await jsonDecode(response.body);
      room = await Room.fromJson(body["data"]);
    }
    return room;
  }

  static Future<ResponseApi> CheckRoom(
      {required String room_id, String? password}) async {
    ResponseApi responseApi = ResponseApi.init();
    try {
      Map bodyParam = {};
      if (password != null) {
        bodyParam.addAll({"password": password});
      }
      bodyParam.addAll({"room_id": room_id});

      var url = WRTCCOnfig.host + "/api/check-room";
      var bodyJson = await jsonEncode(bodyParam);

      final res = await http.Client()
          .post(Uri.parse(url),
              headers: {
                "Content-Type": "application/json",
              },
              body: bodyJson)
          .catchError((e) {
        print("!!!!!! error call api");
      });
      print(res.body);
      var body = await jsonDecode(res.body);
      responseApi.status_code = res.statusCode;
      responseApi.message = body["message"];
    } catch (e) {
      print(e);
    }
    return responseApi;
  }
}
