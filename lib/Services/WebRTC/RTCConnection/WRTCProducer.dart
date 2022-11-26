import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:universal_html/html.dart' as uhtml;
import 'package:zomie_app/Services/WebRTC/Config/WRTCConfig.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Candidate.dart';
import 'package:zomie_app/Services/WebRTC/Models/ConsumerM.dart';
import 'package:zomie_app/Services/WebRTC/Models/HasMedia.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocketEvent.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocketFunction.dart';
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
  ValueNotifier<bool> isConnected = ValueNotifier(false);

  MediaStream? stream;
  RTCVideoRenderer videoRenderer = new RTCVideoRenderer();
  StreamController<MediaStream> _streamController =
      StreamController<MediaStream>.broadcast();

  List<ConsumerM> consumers = [];

  StreamController<List<ConsumerM>> consumerStream =
      StreamController<List<ConsumerM>>.broadcast();

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
    print("p-get user display");
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

    // onTrack();

    await _setTrack();

    //----------------- process handshake
    // renegitiaion needed allways call wen setTrack it trigger to addtrack
    await _sdpProccess();
    // this.peer!.onRenegotiationNeeded = () async {
    //   // if (!firstConnect) {
    //   await _sdpProccess();
    //   firstConnect = true;
    //   // }
    // };
    _onIceCandidate();

    this.peer!.onIceConnectionState = (e) {
      try {
        if (this.peer != null) {
          var connectionStatus2 = this.peer!.iceConnectionState;
          print("Connection state: " +
              this.producer.id +
              " - " +
              connectionStatus2.toString());
          if (connectionStatus2 ==
              RTCIceConnectionState.RTCIceConnectionStateConnected) {
            UpdateConsumerStream();
          }
        }
      } catch (e) {
        print(e);
      }
    };
  }

  _sdpProccess() async {
    // try {

    String _platform = "";
    isConnected.value = false;
    if (kIsWeb) {
      _platform = "web";
    } else {
      _platform = defaultTargetPlatform.name;
    }

    var offer = await this.peer!.createOffer({'offerToReceiveVideo': 1});
    // var offer = await this.peer!.createOffer();
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
      await _AddCandidatesToServer();
      WRTCSocketFunction.NotifyServer(
          type: this.producerType == ProducerType.screen
              ? NotifyType.start_screen
              : NotifyType.join,
          producer_id: this.producer.id,
          room_id: this.room_id);
    }
    // } catch (e) {
    //   print("p-error _onRenegotiationNeeded");
    //   print(e);
    // }
  }

  // onTrack() {
  //   try {
  //     // this.peer!.onTrack = (e) {
  //     //   e.track.onEnded = () async {
  //     //     // removeTrack(e.streams.first);
  //     //   };
  //     // };
  //     print("ON TRACK media stream");
  //   } catch (e) {
  //     print("c-!!!!!!!!!!! error on track media stream");
  //     print(e);
  //   }
  // }

  _setTrack() async {
    try {
      print("p-~~~~~~~~~~set track: stream id: " + this.stream!.id);
      if (this.stream != null) {
        for (var track in this.stream!.getTracks()) {
          print("Add track for " + this.producerType.name);
          await this.peer!.addTrack(track, this.stream!).catchError((er) {
            print("error set track");
          });
        }
        await _addStreamCoroller();
      }
    } catch (e) {
      print("p-!!!!!!!!!!! error set track media stream");
      print(e);
    }
  }

  handleSdpFromServer(
    dynamic sdp,
  ) async {
    try {
      await WRTCUtils.SetRemoteDescriptionFromJson(peer: peer!, sdpRemote: sdp);

      var answer = await this.peer!.createAnswer();
      await this.peer!.setLocalDescription(answer);

      var _desc = await this.peer!.getLocalDescription();
      var localSdp = await WRTCUtils.sdpToJsonString(desc: _desc!);
      WRTCSocketFunction.sdpToServer(
          producer_id: this.producer.id, sdp: localSdp);
    } catch (e) {
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

  _AddCandidatesToServer() async {
    for (var c in this.candidates) {
      print("p-add candidate to server");
      await WRTCSocketFunction.addCandidateToServer(
          producer_id: this.producer.id, candidate: c);
      this.candidates.clear();
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

  Widget ShowConsumer({required double height, required double width}) {
    return StreamBuilder<List<ConsumerM>>(
        initialData: this.consumers,
        stream: consumerStream.stream,
        builder: (_, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            if (snapshot.data!.length == 1) {
              return Container(
                  height: height,
                  width: width,
                  child: Column(
                    children: [snapshot.data!.first.Show()],
                  ));
            } else if (snapshot.data!.length == 2) {
              if (height > width) {
                return Column(
                    children: snapshot.data!.map((e) => e.Show()).toList());
              }
              return Row(
                  children: snapshot.data!.map((e) => e.Show()).toList());
            } else if (snapshot.data!.length > 2) {
              return GridView.count(
                crossAxisCount: height > width ? 2 : 3,
                children: snapshot.data!.map((e) => e.Show()).toList(),
              );
            }
            return Center(child: Text("Something wrong"));
          }
          return SizedBox(
            child: Center(child: Text("Invite others to join you :)")),
          );
        });
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

  // ===================================================================================================
  UpdateConsumer({required Producer producer}) {
    for (int i = 0; i < this.consumers.length; i++) {
      if (this.consumers[i].producer.id == producer.id) {
        this.consumers[i].UpdateData(producer);
        SetStreamEvent();
      }
    }
  }

  UpdateConsumers({required List<Producer> producers}) async {
    print("c-update consumers");
    //-------------------------------------------- remove current producer
    List<ConsumerM> newConsumersM =
        await _filterIncomingProducers(producers: producers);
    _shouldAdded(newConsumersM);
    _shouldRemove(newConsumersM);
    SetStreamEvent();
    //--------------------------------------------
  }

  _filterIncomingProducers({required List<Producer> producers}) async {
    List<ConsumerM> newConsumersM = [];
    for (int i = 0; i < producers.length; i++) {
      // if (producers[i].id == this.currentProducerId ||  producers[i].user_id == ) {
      if (producers[i].user_id == this.producer.user_id) {
        await producers.removeAt(i);
        i--;
      } else {
        newConsumersM.add(ConsumerM(
          producer: producers[i],
        ));
      }
    }
    return newConsumersM;
  }

  _shouldAdded(List<ConsumerM> newConsumersM) async {
    bool exist = false;
    for (var p in newConsumersM) {
      exist = false;
      for (var pLocal in this.consumers) {
        if (p.producer.id == pLocal.producer.id) {
          exist = true;
          break;
        }
      }
      if (!exist) {
        this.consumers.add(p);
      }
    }
  }

  _shouldRemove(List<ConsumerM> newConsumersM) async {
    if (newConsumersM.isEmpty) {
      for (int i = 0; i < this.consumers.length; i++) {
        this.consumers[i].Dispose();
      }

      this.consumers.clear();
      print("c-clear all consumers");
      return;
    }
    print("c-should remove");

    bool exist = false;
    String _id = "";

    for (int i = 0; i < this.consumers.length; i++) {
      exist = false;
      _id = "";
      for (var p in newConsumersM) {
        if (p.producer.id == this.consumers[i].producer.id) {
          exist = true;
          _id = p.producer.id;
          break;
        }
      }
      if (!exist) {
        print("c-remove old");
        this.consumers[i].Dispose();
        this.consumers.removeAt(i);
        i--;
      }
    }
  }

  Future<void> UpdateConsumerStream() async {
    try {
      if (this.peer != null) {
        print("starting get remote streams1");
        var _remoteStream = await this.peer!.getRemoteStreams();
        if (_remoteStream != null) {
          print("starting get remote streams2");
          _remoteStream.forEach((e) {
            if (e != null) {
              print("c- update consumer streams");
              setTrack(e);
            }
          });
        }
      }
    } catch (e) {
      print(e);
      print("c-!!!!!!!!!!! error update consumers media stream");
    }
  }

  setTrack(MediaStream e) async {
    print("stream id:" + e.id);
    int i = this.consumers.indexWhere((c) => c.producer.stream_id == e.id);
    if (i >= 0) {
      print("c-add track");
      await this.consumers[i].AddMediaStream(e);
      await SetStreamEvent();
    }
  }

  // removeTrack(MediaStream e) async {
  //   this.consumers.removeWhere((c) => c.StreamId() == e.id);
  //   await SetStreamEvent();
  // }

  SetStreamEvent() async {
    if (consumerStream.isClosed) {
      consumerStream = new StreamController<List<ConsumerM>>.broadcast();
    }
    consumerStream.sink.add(this.consumers);
    print("c-consumers stream");
    print(this.consumers.length);
  }

  // ===================================================================================================

/**
   * call this before destroy this instance
   */
  Dispose() async {
    try {
      this._streamController.close();

      if (this.stream != null) {
        this.stream!.dispose();
        this.stream = null;
      }

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
