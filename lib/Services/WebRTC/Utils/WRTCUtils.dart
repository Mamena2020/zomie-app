import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart' as sdpt;
import 'package:uuid/uuid.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';

class WRTCUtils {
  static String uuidV4() {
    var _uuid = Uuid();
    return _uuid.v4();
  }

  static Future<MediaStream?> GetUserMedia(CallType callType,
      {bool video = true, bool audio = true}) async {
    final Map<String, dynamic> constraints = callType == CallType.videoCall
        ? {
            'audio': audio,
            'video': video
                ? {
                    'facingMode': 'user',
                    // "width": {"min": 320, "ideal": 320},
                    // "height": {"min": 240},
                    // "frameRate": 60,
                  }
                : false
          }
        : {
            'audio': true,
            'video': false,
          };

    MediaStream? stream;
    try {
      stream = await navigator.mediaDevices.getUserMedia(constraints);
    } catch (e) {
      print(e);
    }

    return stream;
  }

  static Future<MediaStream?> GetDisplayMedia(
      {bool video = true,
      bool audio = false,
      ShareScreenType type = ShareScreenType.allScreen}) async {
    Map<String, dynamic> constraints = {'audio': audio, 'video': video};
    MediaStream? stream;

    try {
      // if (type == ShareScreenType.allScreen) {
      //   constraints = {
      //     'audio': false,
      //     // 'video': {'displaySurface': 'application'}
      //     'video': true
      //   };
      // }
      stream = await navigator.mediaDevices.getDisplayMedia(constraints);
    } catch (e) {
      print(e);
    }
    return stream;
  }

  // static Future<String> sdpToJsonString(
  //     {required String sdp, required SdpType type}) async {

  static Future<String> sdpToJsonString(
      {required RTCSessionDescription desc}) async {
    var session = await sdpt.parse(desc.sdp.toString());
    var data = {"type": desc.type, "sdp": session};
    return await jsonEncode(data);
  }

  static sdpFromJsonString({required String sdp}) async {
    // print("==============sdp from json");
    var session = await jsonDecode(sdp);
    var _sdp = await sdpt.write(session["sdp"], null);
    var newSdp = {"type": session["type"], "sdp": _sdp};
    return newSdp;
  }

  static Future<void> SetRemoteDescriptionFromJson(
      {required RTCPeerConnection peer, required String sdpRemote}) async {
    final sdp = await sdpFromJsonString(sdp: sdpRemote);
    final session = await RTCSessionDescription(sdp["sdp"], sdp["type"]);

    await peer.setRemoteDescription(session).whenComplete(() {
      print("complete set remote desc");
    }).onError((error, stackTrace) {
      print("error when set remote desc");
      print(error);
    }).catchError((e) {
      print("catch error when set remote desc");
      print(e);
    });
  }

  static Future<void> setBitrate(
      {required RTCPeerConnection peer, required int bitrate}) async {
    try {
      var sender = await peer.getSenders();
      var parameters = sender.first.parameters;
      if (parameters.encodings == null || parameters.encodings!.isEmpty) {
        parameters.encodings = [RTCRtpEncoding()];
      }
      parameters.encodings!.first.maxBitrate = bitrate * 1000;
      await sender.first.setParameters(parameters);
    } catch (e) {
      print(e);
      print("error set bitrate");
    }
  }
}
