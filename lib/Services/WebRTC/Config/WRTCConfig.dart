import 'package:flutter_dotenv/flutter_dotenv.dart';

class WRTCCOnfig {
  static String host = dotenv.get("MEDIA_SERVER_HOST", fallback: "");

  static Map<String, dynamic> configurationPeerConnection() {
    // Map<String, String> stun2 = {"urls": "stun:stun.l.google.com:19302"};

    var iceServers = [
      // //---------------------------- open relay
      {"urls": "stun:stun.stunprotocol.org"},
      {
        "urls": "stun:openrelay.metered.ca:80",
        "username": "openrelayproject",
        "credential": "openrelayproject",
      },
      {
        "urls": "turn:openrelay.metered.ca:80",
        "username": "openrelayproject",
        "credential": "openrelayproject",
      },
      {
        "urls": "turn:openrelay.metered.ca:443",
        "username": "openrelayproject",
        "credential": "openrelayproject",
      },
      {
        "urls": "turn:openrelay.metered.ca:80?transport=tcp",
        "username": "openrelayproject",
        "credential": "openrelayproject",
      },
      {
        "urls": "turn:openrelay.metered.ca:443?transport=tcp",
        "username": "openrelayproject",
        "credential": "openrelayproject",
      },
      {
        "urls": "turns:openrelay.metered.ca:443",
        "username": "openrelayproject",
        "credential": "openrelayproject",
      },
    ];

    String dotenvAllowTurnServer =
        dotenv.get("ALLOW_TURN_SERVER", fallback: "false");
    bool allowTurnServer =
        dotenvAllowTurnServer == "true" || dotenvAllowTurnServer == true
            ? true
            : false;

    String turnServerHost = dotenv.get("TURN_SERVER_HOST");
    String turnServerUsername = dotenv.get("TURN_SERVER_USERNAME");
    String turnServerPassword = dotenv.get("TURN_SERVER_PASSWORD");
    if (turnServerHost != "" && turnServerHost.length > 3 && allowTurnServer) {
      print("using turn server costume");
      var turn = {
        'urls': turnServerHost,
        'username': turnServerUsername,
        'credential': turnServerPassword
      };
      iceServers.add(turn);
    }
    return {"sdpSemantics": "unified-plan", 'iceServers': iceServers};
  }

  static const offerSdpConstraints = {
    "mandatory": {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    "optional": [],
  };
}
