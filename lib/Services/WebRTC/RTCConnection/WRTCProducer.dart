import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zomie_app/Services/WebRTC/Config/WRTCConfig.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Candidate.dart';
import 'package:zomie_app/Services/WebRTC/Models/ConsumerM.dart';
import 'package:zomie_app/Services/WebRTC/Models/HasMedia.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Models/Room.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocketFunction.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocket.dart';
import 'package:zomie_app/Services/WebRTC/Utils/WRTCUtils.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

class WRTCProducer {
  Producer producer;
  CallType callType;
  Room room;
  ProducerType producerType;
  RTCPeerConnection? peer;
  ValueNotifier<bool> isConnected = ValueNotifier(false);

  MediaStream? stream;
  RTCVideoRenderer videoRenderer = new RTCVideoRenderer();
  StreamController<MediaStream> _streamController =
      StreamController<MediaStream>.broadcast();

  List<ConsumerM> consumers = [];
  bool _isPined = false;
  ConsumerM consumerPined = ConsumerM.init();

  StreamController<List<ConsumerM>> consumerStream =
      StreamController<List<ConsumerM>>.broadcast();

  WRTCProducer(
      {required this.room,
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
      await WRTCUtils.setBitrate(
          peer: this.peer!,
          bitrate: this.producerType == ProducerType.user
              ? this.room.video_bitrate
              : this.room.screen_bitrate);
    }
  }

  List<Candidate> candidates = [];

  bool firstConnect = false;

  GetUserMedia() async {
    print("p-get user media");
    producer.hasMedia = HasMedia.init();
    MediaStream? newStream = await WRTCUtils.GetUserMedia(callType);
    if (newStream != null) {
      this.stream = newStream;
      this.videoRenderer.srcObject = this.stream!;
    }
  }

  GetDisplayMedia() async {
    print("p-get user display");
    producer.hasMedia = HasMedia.init();
    MediaStream? newStream = await WRTCUtils.GetDisplayMedia();
    if (newStream != null) {
      this.stream = newStream;
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
    onStopLocalStream();

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
    // var offerWithBandwidth =
    //     await WRTCUtils.SetBandwidthSdp(offer, this.producerType);
    await this.peer!.setLocalDescription(offer);

    var _desc = await peer!.getLocalDescription();
    var sdp = await WRTCUtils.sdpToJsonString(desc: _desc!);
    // print("================ JSON STR");
    // print(sdp);
    String bodyParams = "";
    String url = "";
    url = WRTCCOnfig.host + "/api/join-room";
    bodyParams = await jsonEncode({
      "socket_id": WRTCSocket.instance().socket.id,
      "sdp": sdp,
      "room_id": this.room.id,
      "use_sdp_transform": true,
      "type": this.producerType.name,
      "producer_id": this.producer.id,
      "user_id": this.producer.user_id,
      "user_name": this.producer.name,
      "has_video": this.producer.hasMedia.video,
      "has_audio": this.producer.hasMedia.audio,
      "platform": _platform
    });

    print(bodyParams);

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

      await WRTCUtils.setBitrate(
          peer: this.peer!,
          bitrate: this.producerType == ProducerType.user
              ? this.room.video_bitrate
              : this.room.screen_bitrate);

      await _AddCandidatesToServer();
      WRTCSocketFunction.NotifyServer(
          type: NotifyType.join,
          producer_id: this.producer.id,
          room_id: this.room.id);
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

  bool _isMinimizeMedia = false;
  Widget ShowMedia(
      {required Size size, bool allowResize = false, Function? onResize}) {
    return AnimatedContainer(
      height: _isMinimizeMedia && allowResize ? 40 : size.height,
      width: _isMinimizeMedia && allowResize ? 40 : size.width,
      duration: Duration(milliseconds: 300),
      child: Stack(
        children: [
          Center(
            child: Container(
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
              child: _isMinimizeMedia
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          new BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20.0,
                          ),
                        ],
                      ),
                    )
                  : StreamBuilder<MediaStream>(
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
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                            ),
                          );
                        }
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
            ),
          ),
          !allowResize
              ? SizedBox()
              : Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: new BackdropFilter(
                        filter:
                            new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: InkWell(
                          onTap: () async {
                            _isMinimizeMedia = !_isMinimizeMedia;
                            if (onResize != null) {
                              onResize();
                            }
                          },
                          child: new Container(
                            width: 25.0,
                            height: 25.0,
                            decoration: new BoxDecoration(
                              color: Colors.grey.shade200.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: new Center(
                              child: !_isMinimizeMedia
                                  ? Icon(
                                      Icons.pin_invoke,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : RotatedBox(
                                      quarterTurns: 2,
                                      child: Icon(
                                        Icons.pin_invoke,
                                        color: _isMinimizeMedia
                                            ? Colors.black
                                            : Colors.white,
                                        size: 20,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ))
        ],
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

  Widget ShowConsumers({required double height, required double width}) {
    return SizedBox(
      height: height,
      width: width,
      child: StreamBuilder<List<ConsumerM>>(
          initialData: this.consumers,
          stream: consumerStream.stream,
          builder: (_, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              if (snapshot.data!.length == 1) {
                return snapshot.data!.first.Show(
                    size: Size(width, height),
                    isShowPined: false,
                    onPined: () {
                      _PinedConsumer(consumer_: snapshot.data!.first);
                    });
              }
              return _ShowConsumerMoreThanOne(height: height, width: width);
            }
            return SizedBox(
              child: Center(child: Text("Invite others to join you :)")),
            );
          }),
    );
  }

  Widget _ShowConsumerMoreThanOne(
      {required double height, required double width}) {
    if (this._isPined) {
      return _ShowConsumerPinedMode(height: height, width: width);
    }

    if (this.consumers.length == 2) {
      if (height > width) {
        return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: this
                .consumers
                .map((e) => e.Show(
                    size: Size(height * 0.45, height * 0.45),
                    isShowPined: true,
                    onPined: () {
                      _PinedConsumer(consumer_: e);
                    }))
                .toList());
      }
      return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: this
              .consumers
              .map((e) => e.Show(
                  size: Size(width * 0.45, width * 0.45),
                  isShowPined: true,
                  onPined: () {
                    _PinedConsumer(consumer_: e);
                  }))
              .toList());
    } else if (this.consumers.length > 2) {
      return GridView.count(
        crossAxisCount: height > width ? 2 : 3,
        children: this
            .consumers
            .map((e) => e.Show(
                size: Size(width, height),
                isShowPined: true,
                onPined: () {
                  _PinedConsumer(consumer_: e);
                }))
            .toList(),
      );
    }
    return Center(child: Text("Something wrong"));
  }

  Widget _ShowConsumerPinedMode(
      {required double height, required double width}) {
    if (height > width) {
      return Column(
        children: [
          SizedBox(
            height: (height * 0.7) - 56,
            width: width,
            child: this.consumerPined.Show(
                size: Size(width, height),
                isShowPined: true,
                onPined: () {
                  int i = this.consumers.indexWhere(
                      (e) => e.producer.id == this.consumerPined.producer.id);
                  if (i >= 0) {
                    _PinedConsumer(consumer_: this.consumers[i]);
                  }
                }),
          ),
          SizedBox(
              height: height * 0.25,
              width: width,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: this.consumers.length,
                itemBuilder: (_, i) {
                  if (this.consumers[i].producer.id !=
                      this.consumerPined.producer.id) {
                    return this.consumers[i].Show(
                          size: Size(height * 0.20, height * 0.20),
                          isShowPined: false,
                          // onPined: () {
                          //   _PinedConsumer(consumer_: this.consumers[i]);
                          // }
                        );
                  }
                  return SizedBox();
                },
              ))
        ],
      );
    } else {
      return Row(
        children: [
          SizedBox(
            height: height,
            width: width * 0.75,
            child: this.consumerPined.Show(
                size: Size(width * 0.75, height),
                isShowPined: true,
                onPined: () {
                  int i = this.consumers.indexWhere(
                      (e) => e.producer.id == this.consumerPined.producer.id);
                  if (i >= 0) {
                    _PinedConsumer(consumer_: this.consumers[i]);
                  }
                }),
          ),
          SizedBox(
              height: height,
              width: width * 0.25,
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: this.consumers.length,
                itemBuilder: (_, i) {
                  if (this.consumers[i].producer.id !=
                      this.consumerPined.producer.id) {
                    return this.consumers[i].Show(
                          size: Size(width * 0.20, width * 0.20),
                          isShowPined: false,
                          // onPined: () {
                          //   _PinedConsumer(consumer_: this.consumers[i]);
                          // }
                        );
                  }
                  return SizedBox();
                },
              ))
        ],
      );
    }
  }

  void _PinedConsumer({required ConsumerM consumer_}) async {
    if (this.consumerPined.producer.id == consumer_.producer.id) {
      await this.consumerPined.Dispose();
      this.consumerPined = ConsumerM.init();
      print("un pined");
      int i = this
          .consumers
          .indexWhere((e) => e.producer.id == consumer_.producer.id);
      if (i >= 0) {
        this.consumers[i].isPined = false;
      }

      _isPined = false;
    } else {
      print("pined");

      if (this.consumerPined.producer.id != "") {
        await this.consumerPined.Dispose();
      }
      this.consumerPined = ConsumerM.init();
      consumer_.isPined = true;
      this.consumerPined.producer = Producer.copy(consumer_.producer);
      consumerPined.isPined = true;

      await this.consumerPined.AddMediaStream(consumer_.mediaStream!);
      _isPined = true;
    }
    print("consumer_.:" + consumer_.producer.id);
    print("consumerPined.:" + consumerPined.producer.id);
    SetStreamEvent();
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
    print("new from server producers:" + producers.length.toString());
    //-------------------------------------------- remove current producer
    List<ConsumerM> newConsumersM =
        await _filterIncomingProducers(producers: producers);
    print("after filter newConsumersM:" + newConsumersM.length.toString());
    _shouldAdded(newConsumersM);
    _shouldRemove(newConsumersM);
    SetStreamEvent();
    //--------------------------------------------
  }

  _filterIncomingProducers({required List<Producer> producers}) async {
    List<ConsumerM> newConsumersM = [];
    for (int i = 0; i < producers.length; i++) {
      // remove self if exist in producers list
      if (producers[i].id == this.producer.id) {
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
    print("_shouldRemove");
    print(newConsumersM.length);
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

  onStopLocalStream() {
    if (this.producerType == ProducerType.screen) {
      this.stream!.getVideoTracks()[0].onEnded = () {
        WRTCService.instance().StopShareScreen();
      };
    }
  }

/**
   * call this before destroy this instance
   */
  Dispose() async {
    try {
      await consumerPined.Dispose();
      consumerPined = ConsumerM.init();

      WRTCSocketFunction.endCall(
          producer_id: this.producer.id, room_id: this.room.id);

      this._streamController.close();

      if (this.stream != null) {
        this.stream!.getTracks().forEach((e) {
          e.stop();
        });
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
