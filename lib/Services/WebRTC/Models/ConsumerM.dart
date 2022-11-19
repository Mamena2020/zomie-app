import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';

class ConsumerM {
  Producer producer;
  RTCVideoRenderer _videoRenderer = RTCVideoRenderer();

  MediaStream? _mediaStream;

  StreamController<MediaStream> _streamController =
      StreamController<MediaStream>.broadcast();

  ConsumerM({
    required this.producer,
  }) {
    this._videoRenderer.initialize();
  }

  factory ConsumerM.init() => ConsumerM(
        producer: Producer.init(),
      );

  UpdateData(Producer newProducer) {
    this.producer.hasMedia = newProducer.hasMedia;
    if (_mediaStream != null) {
      _streamController.sink.add(_mediaStream!);
    }
  }

  AddMediaStream(MediaStream mediaStream) {
    if (_streamController.isClosed) {
      _streamController = StreamController<MediaStream>.broadcast();
    }
    _mediaStream = mediaStream;
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

  Widget Show() {
    return Flexible(
      fit: FlexFit.tight,
      flex: 1,
      child: Stack(
        children: [
          Container(
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
                      return Center(child: CircularProgressIndicator());
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
    return Stack(
      children: [
        this.producer.hasMedia.video
            ? RTCVideoView(this._videoRenderer)
            : Center(
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
}
