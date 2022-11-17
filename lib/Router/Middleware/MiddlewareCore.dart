import 'package:flutter/cupertino.dart';

class MiddlewareParams {
  bool status;
  Map<String, dynamic> params;

  MiddlewareParams({required this.status, required this.params});

  factory MiddlewareParams.init() =>
      new MiddlewareParams(params: {}, status: true);
}

abstract class MiddlewareHandling {
  Future<MiddlewareParams> action(MiddlewareParams handling) async {
    return handling;
  }
}

abstract class MiddlewareCore {
  MiddlewareParams params;
  MiddlewareCore({required this.params});
}
