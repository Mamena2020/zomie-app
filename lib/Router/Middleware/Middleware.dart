import '/Router/Middleware/MiddlewareCore.dart';
import 'package:flutter/cupertino.dart';

class Middleware extends MiddlewareCore implements MiddlewareHandling {
  Middleware({required super.params});

  @override
  Future<MiddlewareParams> action(MiddlewareParams handling) async {
    // TODO: implement action
    return handling;
  }
}
