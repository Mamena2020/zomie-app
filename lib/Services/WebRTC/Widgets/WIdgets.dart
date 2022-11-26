import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zomie_app/Router/RouterService.dart';
import 'package:zomie_app/Services/WebRTC/Blocs/WRTCMessageBloc.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';

class WRTCWidgets {
  static Widget EndCallButton({required BuildContext context}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () async {
            String destination = "/room/" + WRTCService.instance().room.id;
            await WRTCService.instance().EndCall();
            RouteService.router.navigateTo(context, destination, replace: true);
          },
          child: new Container(
            width: 50.0,
            height: 40.0,
            decoration: new BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                new BoxShadow(
                    color: Colors.black, blurRadius: 10.0, spreadRadius: 10),
              ],
            ),
            child: new Center(
              child: Icon(
                Icons.call_end,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget ChatButton({required Function onTap}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: InkWell(
            onTap: () async {
              WRTCMessageBloc.instance().isShow =
                  !WRTCMessageBloc.instance().isShow;
              onTap();
            },
            child: new Container(
              width: 35.0,
              height: 35.0,
              decoration: new BoxDecoration(
                color: !WRTCMessageBloc.instance().isShow
                    ? Colors.grey.shade200.withOpacity(0.3)
                    : Colors.blue.shade800.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  new BoxShadow(
                      color: WRTCMessageBloc.instance().isShow
                          ? Colors.blue.withOpacity(0.5)
                          : Colors.black.withOpacity(0.5),
                      blurRadius: 10.0,
                      spreadRadius: 10),
                ],
              ),
              child: new Center(
                child: Icon(
                  Icons.chat_bubble,
                  color: WRTCMessageBloc.instance().isShow
                      ? Colors.blue.shade700
                      : Colors.white,
                  size: 17,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
