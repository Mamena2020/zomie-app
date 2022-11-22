import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zomie_app/Services/WebRTC/Config/WRTCConfig.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Candidate.dart';
import 'package:zomie_app/Services/WebRTC/Models/HasMedia.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/SocketEvent.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocket.dart';
import 'package:zomie_app/Services/WebRTC/Utils/WRTCUtils.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

class WRTCProducer {
  Producer producer;
  CallType callType;
  String room_id;
  ProducerType producerType;
  RTCPeerConnection? peer;
  // bool isConnected = false;
  ValueNotifier<bool> isConnected = ValueNotifier(false);

  MediaStream? stream;
  RTCVideoRenderer videoRenderer = new RTCVideoRenderer();
  StreamController<MediaStream> _streamController =
      StreamController<MediaStream>.broadcast();

  WRTCProducer(
      {required this.room_id,
      required this.producer,
      required this.producerType,
      required this.callType}) {
    this.videoRenderer.initialize();
  }

  Future<void> MuteUnMute() async {
    if (this.stream != null) {
      this.stream!.getAudioTracks()[0].enabled =
          !(this.stream!.getAudioTracks()[0].enabled);
      producer.hasMedia.audio = this.stream!.getAudioTracks()[0].enabled;
    }
  }

  Future<void> CameraOnOff() async {
    if (producer.hasMedia.video) {
      try {
        print("p-disabled video");
        if (this.stream!.getVideoTracks().isNotEmpty) {
          if (kIsWeb || TargetPlatform.windows == defaultTargetPlatform) {
            this.stream!.getVideoTracks()[0].enabled = false;
            await this.stream!.getVideoTracks()[0].stop();
          } else {
            this.stream!.getVideoTracks()[0].enabled = false;
          }
        }
        producer.hasMedia.video = false;
      } catch (e) {
        print(e);
        print("p-///////////////////// - error disabled video");
      }
    } else {
      try {
        print("p-enable video");
        if (kIsWeb || TargetPlatform.windows == defaultTargetPlatform) {
          var newStream = await WRTCUtils.GetUserMedia(callType);
          this.stream = newStream;
          newStream!.getAudioTracks()[0].enabled = producer.hasMedia.audio;
          newStream.getTracks().forEach((track) async {
            await this.peer!.getSenders().then((sender) {
              sender.forEach((e) async {
                await e.replaceTrack(track);
              });
            });
            await this.stream!.addTrack(track);
          });
        } else {
          this.stream!.getVideoTracks()[0].enabled = true;
        }
        producer.hasMedia.video = true;
        await _addStreamCoroller();
      } catch (e) {
        print(e);
        print("p-///////////////////// - error enabled video");
      }
    }
  }

  List<Candidate> candidates = [];

  bool firstConnect = false;

  GetUserMedia() async {
    print("p-get user media");
    producer.hasMedia = HasMedia.init();
    this.stream = await WRTCUtils.GetUserMedia(callType);
    if (this.stream != null) {
      this.videoRenderer.srcObject = this.stream!;
    }
  }

  GetDisplayMedia() async {
    print("p-get user media");
    producer.hasMedia = HasMedia.init();
    this.stream = await WRTCUtils.GetDisplayMedia();
    if (this.stream != null) {
      this.videoRenderer.srcObject = this.stream!;
    }
  }

  /**
   * create peer connection to server
   */
  Future<void> CreateConnection() async {
    candidates.clear();
    if (this.stream == null) {
      if (this.callType == CallType.screenSharing) {
        await GetDisplayMedia();
      } else {
        await GetUserMedia();
      }
    }
    if (this.stream == null) {
      return;
    }

    this.peer = await createPeerConnection(
        WRTCCOnfig.configurationPeerConnection, WRTCCOnfig.offerSdpConstraints);

    this.peer!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv));
    this.peer!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv));

    _setTrack();

    //----------------- process handshake
    // renegitiaion needed allways call wen setTrack it trigger to addtrack
    // await _onRenegotiationNeeded();
    this.peer!.onRenegotiationNeeded = () async {
      // if (!firstConnect) {
      await _onRenegotiationNeeded();
      firstConnect = true;
      // }
    };
    _onIceCandidate();

    this.peer!.onIceConnectionState = (e) {
      try {
        if (this.peer != null) {
          var connectionStatus2 = this.peer!.iceConnectionState;
          print("p-Producer: " +
              this.producer.id +
              " - " +
              connectionStatus2.toString());
        }
      } catch (e) {
        print(e);
      }
    };
  }

  _onRenegotiationNeeded() async {
    // try {

    String _platform = "";
    isConnected.value = false;
    if (kIsWeb) {
      _platform = "web";
    } else {
      _platform = defaultTargetPlatform.name;
    }

    var offer = await this.peer!.createOffer({'offerToReceiveVideo': 1});
    await this.peer!.setLocalDescription(offer);

    var _desc = await peer!.getLocalDescription();
    var sdp = await WRTCUtils.sdpToJsonString(desc: _desc!);

    String bodyParams = "";
    String url = "";
    url = WRTCCOnfig.host + "/join-room";
    bodyParams = await jsonEncode({
      "socket_id": WRTCSocket.instance().socket.id,
      "sdp": sdp,
      "room_id": this.room_id,
      "use_sdp_transform": true,
      "type": this.producerType.name,
      "producer_id": this.producer.id,
      "user_id": this.producer.user_id,
      "user_name": this.producer.name,
      "has_video": this.producer.hasMedia.video,
      "has_audio": this.producer.hasMedia.audio,
      "platform": _platform
    });
    final res = await http.Client()
        .post(Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
            },
            body: bodyParams)
        .catchError((e) {
      print("p-!!!!!! error call api");
    });

    if (res.statusCode == 200) {
      isConnected.value = true;

      var body = await jsonDecode(res.body);
      await WRTCUtils.SetRemoteDescriptionFromJson(
          peer: peer!, sdpRemote: body["data"]["sdp"]);
      print("p-@@@ success set remote producer");
      _AddCandidatesToServer();
      // List<dynamic> _prodDynamic =
      //     await body["data"]["producers"] as List<dynamic>;
      // List<Producer> producers = await List<Producer>.from(
      //     _prodDynamic.map((e) => Producer.fromJson(e)));
      // WRTCService.instance()
      //     .AddConsumers(producers: producers, room_id: room_id);
    }
    // } catch (e) {
    //   print("p-error _onRenegotiationNeeded");
    //   print(e);
    // }
  }

  _setTrack() {
    try {
      print("p-~~~~~~~~~~set track: stream id: " + this.stream!.id);
      this.stream!.getTracks().forEach((track) async {
        await this.peer!.addTrack(track, this.stream!);
        _addStreamCoroller();
      });
    } catch (e) {
      print("p-!!!!!!!!!!! error set track media stream");
      print(e);
    }
  }

  _addStreamCoroller() {
    if (_streamController.isClosed) {
      _streamController = StreamController<MediaStream>.broadcast();
    }
    _streamController.sink.add(this.stream!);
    this.videoRenderer.srcObject = this.stream!;
  }

  _onIceConnectionState() {
    try {
      var connectionStatus = this.peer!.connectionState;
      if (["disconnected", "failed", "closed"].contains(connectionStatus)) {
        print("p-disconnected");
      } else {
        print("p-Connected");
        if (defaultTargetPlatform != TargetPlatform.windows) {
          Fluttertoast.showToast(
              msg: "Connected",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.green,
              textColor: Colors.white,
              fontSize: 16.0);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  _onIceCandidate() {
    this.peer!.onIceCandidate = (e) {
      if (e.candidate != null) {
        print("p-fire candidate to stored in candidates");

        candidates.add(Candidate(
            candidate: e.candidate!,
            sdpMid: e.sdpMid!,
            sdpMLineIndex: e.sdpMLineIndex!));
      }
    };
  }

  _AddCandidatesToServer() {
    for (var c in this.candidates) {
      print("p-add candidate to server");
      WRTCSocketEvent.addProducerCandidateToServer(
          producer_id: this.producer.id, candidate: c);
    }
  }

  Widget ShowMedia() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          new BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20.0,
          ),
        ],
      ),
      child: StreamBuilder<MediaStream>(
        initialData: this.videoRenderer.srcObject,
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (!producer.hasMedia.video) {
            return Center(
              child: Icon(
                Icons.videocam_off,
                color: Colors.red,
              ),
            );
          }
          if (snapshot.hasData) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: RTCVideoView(
                this.videoRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            );
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget ShowMicIcon({Function? onChange}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: InkWell(
            onTap: () async {
              await WRTCService.instance().MuteUnMuted();
              if (onChange != null) {
                print("p-audio status:" +
                    WRTCService.instance().isAudioOn.toString());
                onChange();
              }
            },
            child: new Container(
              width: 35.0,
              height: 35.0,
              decoration: new BoxDecoration(
                color: Colors.grey.shade200.withOpacity(0.3),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  new BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10.0,
                      spreadRadius: 10),
                ],
              ),
              child: new Center(
                child: Icon(
                  this.producer.hasMedia.audio ? Icons.mic : Icons.mic_off,
                  color: this.producer.hasMedia.audio
                      ? Colors.white
                      : Colors.red.shade800,
                  size: 17,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget ShowCameraIcon({Function? onChange}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: InkWell(
            onTap: () async {
              await WRTCService.instance().CameraOnOff();
              if (onChange != null) {
                onChange();
              }
            },
            child: new Container(
              width: 35.0,
              height: 35.0,
              decoration: new BoxDecoration(
                color: Colors.grey.shade200.withOpacity(0.3),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  new BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10.0,
                      spreadRadius: 10),
                ],
              ),
              child: new Center(
                child: Icon(
                  this.producer.hasMedia.video
                      ? Icons.videocam
                      : Icons.videocam_off,
                  color: this.producer.hasMedia.video
                      ? Colors.white
                      : Colors.red.shade800,
                  size: 17,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  StopMediaStream() async {
    if (this.stream != null) {
      this.stream!.getTracks().forEach((element) async {
        await element.stop();
      });
      this.stream!.dispose();
      this.stream = null;
    }
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
      await StopMediaStream();
      if (this.peer != null) {
        await this.peer!.close();
        this.peer = null;
      }
    } catch (e) {
      print("p-error on dispose");
      print(e);
    }
  }
}
