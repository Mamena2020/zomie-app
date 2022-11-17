import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/Producer.dart';
import 'package:zomie_app/Services/WebRTC/RTCConnection/WRTCConsumer.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';

class WRTCConsumerEvent {
  RoomEventType type;
  Producer producer;
  WRTCConsumerEvent({required this.producer, required this.type});

  factory WRTCConsumerEvent.init() =>
      WRTCConsumerEvent(producer: Producer.init(), type: RoomEventType.none);
}

class WRTCConsumerBloc {
  // ----------------------------- data
  List<WRTCConsumer> rtcConsumers = [];
  // ----------------------------- output
  StreamController<List<WRTCConsumer>> _streamRTCConsumerOutput =
      StreamController<List<WRTCConsumer>>.broadcast();
  Stream<List<WRTCConsumer>> get output => _streamRTCConsumerOutput.stream;
  //----------------------------- input
  StreamController<WRTCConsumerEvent> _streamControllerInput =
      StreamController<WRTCConsumerEvent>.broadcast();
  StreamSink<WRTCConsumerEvent> get input => _streamControllerInput.sink;
  //-----------------------------

  WRTCConsumerBloc._() {
    _streamControllerInput.stream.listen((event) async {
      if (event.type == RoomEventType.join_room) {
        if (_isRTCConsumerExist(event.producer)) {
          await _LeaveRoom(producer: event.producer);
        }
        _JoinRoom(producer: event.producer);
      }
      if (event.type == RoomEventType.leave_room) {
        await _LeaveRoom(producer: event.producer);
      }
      if (event.type == RoomEventType.update_data) {
        _UpdateData(producer: event.producer);
      }
      _streamRTCConsumerOutput.sink.add(this.rtcConsumers);
    });
  }
  _JoinRoom({required Producer producer}) async {
    WRTCConsumer consumer = new WRTCConsumer(
        producer: producer,
        currentProducerId: WRTCService.instance().producer.id);
    consumer.CreateConnection();
    this.rtcConsumers.add(consumer);
  }

  _LeaveRoom({required Producer producer}) async {
    for (int i = 0; i < this.rtcConsumers.length; i++) {
      if (this.rtcConsumers[i].producer.id == producer.id) {
        await this.rtcConsumers[i].Dispose();
        await this.rtcConsumers.removeAt(i);
        i--;
      }
    }
  }

  _UpdateData({required Producer producer}) async {
    for (int i = 0; i < this.rtcConsumers.length; i++) {
      if (this.rtcConsumers[i].producer.id == producer.id) {
        this.rtcConsumers[i].producer = producer;
      }
    }
    print("new update from " + producer.name);
  }

  static final instance = WRTCConsumerBloc._();

  bool _isRTCConsumerExist(Producer producer) {
    for (var p in this.rtcConsumers) {
      if (p.producer.id == producer.id) {
        return true;
      }
    }
    return false;
  }

  RemoveAllConsumers() async {
    try {
      for (var _c in this.rtcConsumers) {
        await _c.Dispose();
      }
      this.rtcConsumers.clear();
      // _streamRTCConsumer.sink.add(this.rtcConsumers);
    } catch (e) {
      print(e);
    }
  }
}
