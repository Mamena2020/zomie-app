import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zomie_app/Services/WebRTC/Config/WRTCConfig.dart';
import 'package:zomie_app/Services/WebRTC/Models/ConsumerM.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocket.dart';
import 'package:zomie_app/Services/WebRTC/Utils/WRTCUtils.dart';

class WRTCConsumer {
  String currentProducerId;

  RTCPeerConnection? peer;

  List<ConsumerM> consumers = [];

  StreamController<List<ConsumerM>> consumerStream =
      StreamController<List<ConsumerM>>.broadcast();

  WRTCConsumer({required this.currentProducerId}) {}

  init() async {
    this.peer = await createPeerConnection(
        WRTCCOnfig.configurationPeerConnection, WRTCCOnfig.offerSdpConstraints);
    this.peer!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly));
    this.peer!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly));
    getTrack();
  }

  /**
   * create peer connection to server
   */
  Future<void> CreateConnection() async {
    await RenegotiationNeeded();
    //----------------- process handshake
    this.peer!.onRenegotiationNeeded = () async {
      RenegotiationNeeded();
    };
    this.peer!.onIceConnectionState = (e) {
      try {
        if (this.peer != null) {
          var connectionStatus2 = this.peer!.iceConnectionState;
          print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Consumer: - " +
              connectionStatus2.toString());
        }
      } catch (e) {
        print(e);
      }
    };
  }

  RenegotiationNeeded({String? sdpRemote}) async {
    try {
      if (sdpRemote == null) return;

      await WRTCUtils.SetRemoteDescriptionFromJson(
          peer: this.peer!, sdpRemote: sdpRemote);
      var answer = await this.peer!.createAnswer({'offerToReceiveVideo': 1});

      await this.peer!.setLocalDescription(answer);

      var _desc = await this.peer!.getLocalDescription();
      var sdp = await WRTCUtils.sdpToJsonString(desc: _desc!);
      // print(sdp);
      var data = {
        "producer_id": this.currentProducerId,
        "sdp": sdp,
      };

      WRTCSocket.instance().socket.emit("consumer-sdp", data);
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

  UpdateConsumer({required Producer producer}) {
    for (int i = 0; i < this.consumers.length; i++) {
      if (this.consumers[i].producer.id == producer.id) {
        this.consumers[i].UpdateData(producer);
        SetStreamEvent();
      }
    }
  }

  UpdateConsumers({required List<Producer> producers}) async {
    print("update consumers");
    //-------------------------------------------- remove current producer
    List<ConsumerM> newConsumersM = [];
    for (int i = 0; i < producers.length; i++) {
      if (producers[i].id == this.currentProducerId) {
        await producers.removeAt(i);
        i--;
      } else {
        newConsumersM.add(ConsumerM(
          producer: producers[i],
        ));
      }
    }
    _shouldAdded(newConsumersM);
    _shouldRemove(newConsumersM);
    SetStreamEvent();

    //--------------------------------------------
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
      print("clear all consumers");
      return;
    }
    print("show remove");

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
        print("remove old");
        this.consumers[i].Dispose();
        this.consumers.removeAt(i);
        i--;
      }
    }
  }

  getTrack() {
    try {
      // this.peer!.onAddStream = (e) {
      //   print("on add stream");
      //   setTrack(e);
      // };
      // this.peer!.onRemoveStream = (e) async {
      //   print("on remove stream");
      //   this.consumers.removeWhere((c) => c.StreamId() == e.id);
      //   await _streamEvent();
      // };

      this.peer!.onTrack = (e) {
        print("on track");
        e.streams[0].onAddTrack = (e2) {
          print("on add track");
        };
        e.streams[0].onRemoveTrack = (e2) {
          print("on add track");
        };
      };
      this.peer!.onAddTrack = (stream, track) {
        print("on add track");
        setTrack(stream);
      };

      this.peer!.onRemoveTrack = (stream, track) async {
        print("on remove track");
        this.consumers.removeWhere((e) => e.StreamId() == stream.id);
        await SetStreamEvent();
      };
    } catch (e) {
      print("!!!!!!!!!!! error get track media stream");
      print(e);
    }
  }

  setTrack(MediaStream e) async {
    int i = this.consumers.indexWhere((c) => c.producer.stream_id == e.id);
    if (i >= 0) {
      await this.consumers[i].AddMediaStream(e);
      await SetStreamEvent();
    }
  }

  SetStreamEvent() async {
    if (consumerStream.isClosed) {
      consumerStream = new StreamController<List<ConsumerM>>.broadcast();
    }
    consumerStream.sink.add(this.consumers);
    print("consumers stream");
    print(this.consumers.length);
  }

  Widget Show({required double height, required double width}) {
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
            child: Center(child: Text("There is no one but you")),
          );
        });
  }

/**
   * call this before destroy this instance
   */
  Dispose() async {
    try {
      if (this.consumers.isNotEmpty) {
        for (var c in this.consumers) {
          await c.Dispose();
        }
        this.consumers.clear();
      }
      // this.consumerStream.close();
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
