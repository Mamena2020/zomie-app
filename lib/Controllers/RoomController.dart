import 'package:flutter/material.dart';
import 'package:zomie_app/Router/RouterService.dart';
import 'package:zomie_app/Views/Room/RoomIndexView.dart';
import 'package:zomie_app/Views/Room/RoomView.dart';

class RoomController {
  static final String indexRouteName = "/room/:id";

  static Widget index() {
    return RoomIndexView();
  }
}
