import 'package:flutter_dotenv/flutter_dotenv.dart';

class WRTCCOnfig {
  static String host = dotenv.get("MEDIA_SERVER_HOST", fallback: "");

  // static const configurationPeerConnection = {
  //   "sdpSemantics": "unified-plan", // Add this line for support windows
  //   "iceServers": [
  //     {
  //       "urls": "stun:stun.stunprotocol.org"
  //       // urls: "stun:stun.l.google.com:19302?transport=tcp"
  //     },
  //     // {
  //     //   // "urls": "stun:stun.stunprotocol.org"
  //     //   "urls": "stun:stun.l.google.com:19302?transport=tcp"
  //     // }
  //   ]
  // };

  static Map<String, dynamic> configurationPeerConnection() {
    bool allowTurnServer =
        dotenv.get("ALLOW_TURN_SERVER", fallback: "false") == "true"
            ? true
            : false;
    Map<String, String> stun = {"urls": "stun:stun.stunprotocol.org"};

    if (allowTurnServer) {
      print("using turn server");
      String turnServerHost = dotenv.get("TURN_SERVER_HOST", fallback: "");
      String turnServerUsername =
          dotenv.get("TURN_SERVER_USERNAME", fallback: "");
      String turnServerPassword =
          dotenv.get("TURN_SERVER_PASSWORD", fallback: "");
      print(turnServerHost);
      print(turnServerUsername);
      print(turnServerPassword);

      return {
        "sdpSemantics": "unified-plan",
        'iceServers': [
          stun,
          {
            'url': turnServerHost,
            'username': turnServerUsername,
            'credential': turnServerPassword
          },
        ]
      };
    }
    return {
      "sdpSemantics": "unified-plan",
      'iceServers': [stun]
    };
  }

  // static const configurationPeerConnection = {
  //   'iceServers': [
  //     {'url': 'stun:stun.l.google.com:19302'},
  //     /*
  //      * turn server configuration example.
  //     {
  //       'url': 'turn:123.45.67.89:3478',
  //       'username': 'change_to_real_user',
  //       'credential': 'change_to_real_secret'
  //     },
  //     */
  //   ]
  // };

  static const offerSdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };
}
