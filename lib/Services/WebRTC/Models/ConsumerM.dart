import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';

class ConsumerM {
  Producer producer;
  RTCVideoRenderer _videoRenderer = RTCVideoRenderer();

  MediaStream? _mediaStream;
  MediaStream? get mediaStream => _mediaStream;

  StreamController<MediaStream> _streamController =
      StreamController<MediaStream>.broadcast();

  bool isPined = false;

  ConsumerM({
    required this.producer,
  }) {
    this._videoRenderer.initialize();
  }

  factory ConsumerM.init() => ConsumerM(
        producer: Producer.init(),
      );
  factory ConsumerM.copy(ConsumerM origin) => ConsumerM(
        producer: Producer.copy(origin.producer),
      );

  UpdateData(Producer newProducer) {
    this.producer.hasMedia = newProducer.hasMedia;
    if (_mediaStream != null) {
      _streamController.sink.add(_mediaStream!);
    }
  }

  AddMediaStream(MediaStream mediaStream_) async {
    if (_streamController.isClosed) {
      _streamController = StreamController<MediaStream>.broadcast();
    }
    _mediaStream = mediaStream_;

    await this._videoRenderer.initialize();
    this._videoRenderer.srcObject = _mediaStream;
    _streamController.sink.add(_mediaStream!);
    print("Add Stream to Consumer..........................");
  }

  StreamId() {
    return this._mediaStream == null ? '' : this._mediaStream!.id;
  }

  Dispose() {
    _videoRenderer.srcObject = null;
    _streamController.close();
    this._mediaStream = null;
  }

  Widget Show(
      {Function? onPined, required bool isShowPined, required Size size}) {
    return SizedBox(
      height: size.height,
      width: size.width,
      child: Stack(
        children: [
          Container(
              // height: constraint.hei,
              // width: constraint.minWidth,
              margin: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 5.0),
              decoration: BoxDecoration(color: Colors.black),
              child: StreamBuilder<MediaStream>(
                  initialData: this._mediaStream,
                  stream: this._streamController.stream,
                  builder: (_, snapshot) {
                    if (kIsWeb) {
                      if (snapshot.hasData && snapshot.data != null) {
                        // this._mediaStream = snapshot.data!;
                        this._videoRenderer.srcObject = snapshot.data!;
                        return _show();
                      }
                      return Center(
                          child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Text(
                          //   this._mediaStream == null ? "NULL" : "EXIST",
                          //   style: TextStyle(color: Colors.teal),
                          // ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        ],
                      ));
                    } else {
                      if (snapshot.hasData) {
                        this._mediaStream = snapshot.data!;
                        this._videoRenderer.srcObject = snapshot.data!;
                        return _show();
                      }
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  })),

          // ---------------------------------------------------------- pined
          isShowPined
              ? Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        if (onPined != null) {
                          onPined();
                        }
                      },
                      child: Container(
                        width: 30.0,
                        height: 30.0,
                        decoration: new BoxDecoration(
                          color: isPined
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey.shade200.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            new BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 5.0,
                                spreadRadius: 5),
                          ],
                        ),
                        child: Icon(
                          Icons.push_pin,
                          color: isPined ? Colors.blue.shade700 : Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ),
                )
              : SizedBox(),
          // ---------------------------------------------------------- audio
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
                ),
          // ---------------------------------------------------------- name
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

  Widget _show() {
    return this.producer.hasMedia.video
        ? RTCVideoView(this._videoRenderer)
        : Center(
            child: Icon(
              Icons.videocam_off,
              color: Colors.white,
            ),
          );
  }
}
