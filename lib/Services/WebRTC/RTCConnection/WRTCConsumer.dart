import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zomie_app/Services/WebRTC/Config/WRTCConfig.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocket.dart';
import 'package:zomie_app/Services/WebRTC/Utils/WRTCUtils.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

/**
   * @param producer_id only 
   */
class WRTCConsumer {
  String? id;
  Producer producer; // target producer thats will be consumer of this peer
  String currentProducerId;

  RTCPeerConnection? peer;
  RTCVideoRenderer videoRenderer = new RTCVideoRenderer();

  StreamController<MediaStream> _streamController =
      StreamController<MediaStream>.broadcast();

  WRTCConsumer({required this.producer, required this.currentProducerId}) {
    this.videoRenderer.initialize();
  }

  /**
   * create peer connection to server
   */
  Future<void> CreateConnection() async {
    this.peer = await createPeerConnection(
        WRTCCOnfig.configurationPeerConnection, WRTCCOnfig.offerSdpConstraints);
    this.peer!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly));
    this.peer!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly));
    _getTrack();
    //----------------- process handshake
    this.peer!.onRenegotiationNeeded = () async {
      await _onRenegotiationNeeded();
    };
    // _onIceCandidate();
    this.peer!.onIceConnectionState = (e) {
      // _onIceConnectionState();
      try {
        if (this.peer != null) {
          var connectionStatus2 = this.peer!.iceConnectionState;
          print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Consumer: " +
              this.id! +
              " - " +
              connectionStatus2.toString());
        }
      } catch (e) {
        print(e);
      }
    };
  }

  _onRenegotiationNeeded() async {
    try {
      var offer = await this.peer!.createOffer({'offerToReceiveVideo': 1});
      await this.peer!.setLocalDescription(offer);

      var _desc = await this.peer!.getLocalDescription();
      var sdp = await WRTCUtils.sdpToJsonString(desc: _desc!);
      // print(sdp);
      String bodyParams = await jsonEncode({
        "socket_id": WRTCSocket.instance().socket.id,
        "sdp": sdp,
        "producer_id": this.producer.id,
        "use_sdp_transform": true,
        "owner_producer_id": this.currentProducerId
      });
      final res = await http.Client()
          .post(Uri.parse(WRTCCOnfig.host + "/consumer"),
              headers: {
                "Content-Type": "application/json",
              },
              body: bodyParams)
          .catchError((e) {
        print("!!!!!! error call api");
      });
      if (res.statusCode == 200) {
        print("@@@@@@@@@@ -> res body");
        // print(res.body);
        var body = await jsonDecode(res.body);
        this.id = body["consumer_id"] ?? '';
        await WRTCUtils.SetRemoteDescriptionFromJson(
            peer: this.peer!, sdpRemote: body["sdp"]);
        print("@@@ success set remote consumer");

        // await _SendCandidateToServer();
      }
    } catch (e) {
      print("error _onRenegotiationNeeded");
      print(e);
    }
  }

  // _onIceCandidate() {
  //   try {
  //     print(".................................<<<");
  //     this.peer!.onIceCandidate = (e) async {
  //       if (e.candidate != null) {
  //         _candidateClient.add({
  //           'candidate': e.candidate.toString(),
  //           'sdpMid': e.sdpMid.toString(),
  //           'sdpMLineIndex': e.sdpMLineIndex,
  //         });
  //         // var candidate = {
  //         //   "consumer_id": this.id,
  //         //   "candidate": {
  //         //     'candidate': e.candidate.toString(),
  //         //     'sdpMid': e.sdpMid.toString(),
  //         //     'sdpMlineIndex': e.sdpMLineIndex,
  //         //   }
  //         // };
  //         // var json = await jsonEncode(candidate);
  //         // print("consumer candidate from client");
  //         // print(json);
  //         // print("end -consumer candidate from client");

  //         // SocketService.instance.socket
  //         //     .emit("consumer-candidate-from-client", json);
  //       }
  //     };
  //   } catch (e) {
  //     print("error local candidate");
  //     print(e);
  //   }
  // }

  _getTrack() {
    try {
      print("media streamm000000000000000000000000000");
      this.peer!.onTrack = (e) {
        if (e.streams.isNotEmpty) {
          // if (e.streams[0].getVideoTracks().isNotEmpty)
          //   this.producer.hasMedia.video = true;
          // if (e.streams[0].getAudioTracks().isNotEmpty) {
          //   if (!e.streams[0].getAudioTracks()[0].enabled) {
          //     this.producer.hasMedia.audio = true;
          //   }
          // }
          // print(e.streams[0]);
          this.videoRenderer.srcObject = e.streams[0];
          if (_streamController.isClosed) {
            _streamController = StreamController<MediaStream>.broadcast();
          }
          _streamController.sink.add(e.streams[0]);
        }
      };
    } catch (e) {
      print("!!!!!!!!!!! error get track media stream");
      print(e);
    }
  }

  // _onIceConnectionState() {
  //   try {
  //     var connectionStatus = this.peer!.connectionState;
  //     if (["disconnected", "failed", "closed"].contains(connectionStatus)) {
  //       print("disconnected");
  //     } else {
  //       print("Connected");
  //       if (defaultTargetPlatform != TargetPlatform.windows) {
  //         Fluttertoast.showToast(
  //             msg: "Connected",
  //             toastLength: Toast.LENGTH_LONG,
  //             gravity: ToastGravity.CENTER,
  //             timeInSecForIosWeb: 1,
  //             backgroundColor: Colors.green,
  //             textColor: Colors.white,
  //             fontSize: 16.0);
  //       }
  //     }
  //   } catch (e) {
  //     print(e);
  //   }
  // }
  // _SendCandidateToServer() async {
  //   print("send candidate from client to server");
  //   var _json = await jsonEncode(
  //       {"consumer_id": this.id, "candidate": _candidateClient});
  //   SocketService.instance.socket.emit("consumer-candidate-from-client", _json);
  // }

  Widget ShowMedia() {
    return Flexible(
      fit: FlexFit.tight,
      flex: 1,
      child: Stack(
        children: [
          new Container(
              margin: new EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: new BoxDecoration(color: Colors.black),
              child: StreamBuilder<MediaStream>(
                  initialData: this.videoRenderer.srcObject,
                  stream: _streamController.stream,
                  builder: (_, snapshot) {
                    if (!this.producer.hasMedia.video) {
                      return Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.videocam_off,
                              color: Colors.red,
                            ),
                          ),
                          this.producer.hasMedia.audio
                              ? SizedBox()
                              : Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.mic_off,
                                      color: Colors.red,
                                    ),
                                  ),
                                )
                        ],
                      );
                    }

                    if (snapshot.hasData) {
                      return Stack(
                        children: [
                          RTCVideoView(this.videoRenderer),
                          this.producer.hasMedia.audio
                              ? SizedBox()
                              : Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Icon(
                                      Icons.mic_off,
                                      color: Colors.red,
                                    ),
                                  ),
                                )
                        ],
                      );
                    }
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  })),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Text(
                    this.producer.name,
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

/**
   * call this before destroy this instance
   */
  Dispose() async {
    try {
      this._streamController.close();
      if (this.videoRenderer != null) {
        this.videoRenderer.srcObject = null;
      }
      if (this.peer != null) {
        await this.peer!.close();
        this.peer = null;
      }
    } catch (e) {
      print("error on dispose");
      print(e);
    }
  }
}
