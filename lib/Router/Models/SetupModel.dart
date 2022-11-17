import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';

class SetRouter {
  String path;

  TransitionType? transitionType;
  Duration? transitionDuration;
  Widget child;

  SetRouter(
      {required this.path,
      required this.child,
      this.transitionType,
      this.transitionDuration});
}
