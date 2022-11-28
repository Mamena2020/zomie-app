import 'package:flutter_dotenv/flutter_dotenv.dart';

class WRTCCOnfig {
  static String host = dotenv.env['MEDIA_SERVER_HOST'] ?? '';

  static const configurationPeerConnection = {
    "sdpSemantics": "unified-plan", // Add this line for support windows
    "iceServers": [
      {
        "urls": "stun:stun.stunprotocol.org"
        // urls: "stun:stun.l.google.com:19302?transport=tcp"
      },
      // {
      //   // "urls": "stun:stun.stunprotocol.org"
      //   "urls": "stun:stun.l.google.com:19302?transport=tcp"
      // }
    ]
  };
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
