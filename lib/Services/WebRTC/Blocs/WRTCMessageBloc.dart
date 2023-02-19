import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zomie_app/Services/WebRTC/Enums/enums.dart';
import 'package:zomie_app/Services/WebRTC/Models/RTCMessage.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocketEvent.dart';
import 'package:zomie_app/Services/WebRTC/Signaling/WRTCSocketFunction.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';

class WRTCMessageBloc {
  List<RTCMessage> messages = [];

  // ------------------------------------- input
  StreamController<RTCMessage> _streamControllerInput =
      StreamController<RTCMessage>.broadcast();
  StreamSink<RTCMessage> get input => _streamControllerInput.sink;

  // ------------------------------------- output
  StreamController<List<RTCMessage>> _streamControllerOutput =
      StreamController<List<RTCMessage>>.broadcast();
  Stream<List<RTCMessage>> get output => _streamControllerOutput.stream;
  // -------------------------------------

  WRTCMessageBloc._() {
    _streamControllerInput.stream.listen((event) {
      this.messages.add(event);
      this._streamControllerOutput.add(this.messages);
    });
  }
  static WRTCMessageBloc? _singleton = new WRTCMessageBloc._();
  static WRTCMessageBloc instance() {
    if (_singleton == null) {
      _singleton = new WRTCMessageBloc._();
    }
    return _singleton!;
  }

  TextEditingController _tecMessage = TextEditingController();

  bool isShow = false;

  /**
   * Widget show messages
   */
  Widget Show({required double screenWidth, required Function closeClick}) {
    return AnimatedContainer(
      height: double.infinity,
      width: WRTCMessageBloc.instance().isShow
          ? (screenWidth > 300 ? 300 : screenWidth * 0.85)
          : 0,
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
        boxShadow: [
          new BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20.0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
        child: Column(
          children: [
            _MessageHeader(closeClick: closeClick),
            // ---------------------------------------------------- list messages
            Expanded(
              child: StreamBuilder<List<RTCMessage>>(
                initialData: this.messages,
                stream: this.output,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                        itemCount: this.messages.length,
                        itemBuilder: (_, i) {
                          if (this.messages[i].type ==
                              WRTCMessageType.message) {
                            return ListTile(
                              title: SelectableText(
                                this.messages[i].producer.name,
                                toolbarOptions: ToolbarOptions(
                                  copy: true,
                                  selectAll: true,
                                ),
                                showCursor: true,
                                cursorWidth: 2,
                                cursorColor: Colors.blue.shade100,
                                cursorRadius: Radius.circular(5),
                                style: TextStyle(fontSize: 13),
                              ),
                              subtitle: SelectableText(
                                this.messages[i].messsage,
                                toolbarOptions: ToolbarOptions(
                                  copy: true,
                                  selectAll: true,
                                ),
                                showCursor: true,
                                cursorWidth: 2,
                                cursorColor: Colors.blue.shade100,
                                cursorRadius: Radius.circular(5),
                                style: TextStyle(fontSize: 13),
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: SelectableText(
                                  this.messages[i].messsage,
                                  toolbarOptions: ToolbarOptions(
                                    copy: true,
                                    selectAll: true,
                                  ),
                                  showCursor: true,
                                  cursorWidth: 2,
                                  cursorColor: Colors.blue.shade100,
                                  cursorRadius: Radius.circular(5),
                                  style: _MessageStyle(this.messages[i].type),
                                ),
                              ),
                            );
                          }
                        });
                  }
                  return SizedBox();
                },
              ),
            ),
            // ---------------------------------------------------- textfiled

            AnimatedContainer(
              duration: Duration(microseconds: 100),
              // height: 60,
              width: isShow ? double.infinity : 0,
              decoration: BoxDecoration(color: Colors.grey.shade100),
              child: !isShow
                  ? SizedBox()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: _tecMessage,
                              maxLength: 1000,
                              keyboardType: TextInputType.multiline,
                              minLines: 1,
                              maxLines: 7,
                              decoration: InputDecoration(
                                  counterText: '',
                                  labelText: "Write your message",
                                  labelStyle: TextStyle(
                                    fontSize: 13,
                                  )),
                              onSubmitted: (v) {
                                _SendMessage();
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, bottom: 8),
                          child: InkWell(
                            onTap: () async {
                              _SendMessage();
                            },
                            child: new Container(
                              width: 35.0,
                              height: 35.0,
                              decoration: new BoxDecoration(
                                color: Colors.teal.shade700,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  new BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10.0,
                                      spreadRadius: 10),
                                ],
                              ),
                              child: new Center(
                                child: RotationTransition(
                                  turns: new AlwaysStoppedAnimation(-45 / 360),
                                  child: Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            )
          ],
        ),
      ),
    );
  }

  TextStyle _MessageStyle(WRTCMessageType type) {
    return TextStyle(
        color: type == WRTCMessageType.join_room
            ? Colors.blue.shade600
            : type == WRTCMessageType.leave_room
                ? Colors.red.shade600
                : type == WRTCMessageType.info ||
                        type == WRTCMessageType.start_screen
                    ? Colors.green.shade600
                    : type == WRTCMessageType.stop_screen
                        ? Colors.yellow.shade800
                        : Colors.white,
        fontSize: 10);
  }

  Widget _MessageHeader({required Function closeClick}) {
    return !WRTCMessageBloc.instance().isShow
        ? SizedBox()
        : Container(
            height: 56,
            decoration: BoxDecoration(
                color: Colors.teal.shade700,
                boxShadow: [
                  new BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20.0,
                  ),
                ],
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.teal.shade900,
                      Colors.teal.shade700,
                      Colors.teal.shade500,
                      Colors.teal.shade300,
                      Colors.teal.shade700
                    ])),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                      onPressed: () {
                        this.isShow = false;
                        closeClick();
                      },
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                      )),
                ),
                Center(
                  child: Text(
                    "Messages",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          );
  }

  _SendMessage() async {
    if (_tecMessage.text.isNotEmpty) {
      var event = await WRTCSocketFunction.NotifyServer(
          message: _tecMessage.text,
          type: NotifyType.message,
          producer_id: WRTCService.instance().producer.id,
          room_id: WRTCService.instance().room.id);
      if (event.messsage != "") {
        input.add(event);
        _tecMessage.clear();
      }
    }
  }

  Destroy() {
    this.messages.clear();
    this._streamControllerInput.close();
    this._streamControllerOutput.close();
    _singleton = null;
  }
}
