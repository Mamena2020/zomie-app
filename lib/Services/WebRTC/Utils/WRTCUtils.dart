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
                    "width": {"min": 320, "ideal": 320},
                    "height": {"min": 240},
                    "frameRate": 60,
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
      if (type == ShareScreenType.allScreen) {
        constraints = {
          'audio': false,
          'video': {'displaySurface': 'application'}
        };
      }
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

  static Future<RTCSessionDescription> SetBandwidthSdp(
      RTCSessionDescription desc, ProducerType type) async {
    RTCSessionDescription newDesc = desc;
    String sdp = desc.sdp!;

    String audioBandwidth = "";
    String videoBandwidth = "";
    if (type == ProducerType.user) {
      audioBandwidth = "50"; // kbps
      videoBandwidth = "100"; // kbps
    } else {
      audioBandwidth = "50"; // kbps
      videoBandwidth = "250"; // kbps
    }
    print("================================== BEFORE");
    print(sdp);
    //--------------------------------------------------------------------------
    // sdp = sdp.replaceAll('/a=mid:audio\r\n/g',
    //     'a=mid:audio\r\nb=AS:' + audioBandwidth.toString() + '\r\n');
    // sdp = sdp.replaceAll('/a=mid:video\r\n/g',
    //     'a=mid:video\r\nb=AS:' + videoBandwidth.toString() + '\r\n');
    sdp = sdp.replaceAll('m=audio ', "b=AS:${audioBandwidth}\r\n");
    sdp = sdp.replaceAll('m=video ', "b=AS:${videoBandwidth}\r\n");
    //--------------------------------------------------------------------------
    print("================================== AFTER ");
    print(sdp);
    newDesc = RTCSessionDescription(sdp, desc.type);

    return newDesc;
  }

  // setMediaBitrate(String sdp, String media, String bitrate) {
  //   var lines = sdp.split("\n");
  //   var line = -1;
  //   for (var i = 0; i < lines.length; i++) {
  //     if (lines[i].indexOf("m=" + media) == 0) {
  //       line = i;
  //       break;
  //     }
  //   }
  //   if (line == -1) {
  //     print("Could not find the m line for " + media);
  //     return sdp;
  //   }
  //   print("Found the m line for " + media + " at line " + line.toString());

  //   // Pass the m line
  //   line++;

  //   // Skip i and c lines
  //   while (lines[line].indexOf("i=") == 0 || lines[line].indexOf("c=") == 0) {
  //     line++;
  //   }

  //   // If we're on a b line, replace it
  //   if (lines[line].indexOf("b") == 0) {
  //     print("Replaced b line at line " + line.toString());
  //     lines[line] = "b=AS:" + bitrate;
  //     return lines.join("\n");
  //   }

  //   // Add a new b line
  //   print("Adding new b line before line " + line.toString());
  //   var newLines = lines.sublist(0, line);
  //   newLines.add("b=AS:" + bitrate.toString());
  //   newLines = newLines.addAll( lines.sublist(line, lines.length));
  //   return newLines.join("\n");
  // }

  static Future<void> setBitrate({required RTCPeerConnection peer}) async {
    try {
      int bandwidth = 75;
      var sender = await peer.getSenders();
      var parameters = sender.first.parameters;
      if (parameters.encodings == null || parameters.encodings!.isEmpty) {
        parameters.encodings = [RTCRtpEncoding()];
      }
      parameters.encodings!.first.maxBitrate = bandwidth * 1000;
      await sender.first.setParameters(parameters);
    } catch (e) {
      print(e);
      print("error set bitrate");
    }
  }
}
