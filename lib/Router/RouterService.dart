import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:universal_html/html.dart' as html;
import '/Router/RegisterRouter.dart';

class RouteService {
  static final router = FluroRouter();

  static const String _basePath = "/";

  static late final String path;

  static Map<String, dynamic> params = {};

  /**
   * Setup router
   */
  static Future<void> setupRouter() async {
    _CoreConfig();
    //---------------------------------------------------------------------
    for (var _router in RegisterRouter.routers) {
      router.define(
        _router.path,
        transitionType: _router.transitionType,
        transitionDuration:
            _router.transitionDuration ?? Duration(milliseconds: 200),
        handler: _Handler(
          child: _router.child,
        ),
      );
    }
  }

  static void _CoreConfig() {
    path = html.window.location.pathname ?? _basePath;
    setPathUrlStrategy(); // remove char # in url flutter web
    //---------------------------------------------------------------------
    router.notFoundHandler = _Handler(
        child: NotFoundPage(
      basePath: _basePath,
    ));
    //---------------------------------------------------------------------
  }

  /**
   *  get in any view with params["key"]
   */

  static Handler _Handler({required Widget child}) {
    return Handler(
        handlerFunc: (BuildContext? context, Map<String, dynamic>? _params) {
      params = Params(params: _params);
      return child;
    });
  }

  static Map<String, dynamic> Params({Map<String, dynamic>? params}) {
    Map<String, dynamic> result = {};
    if (params != null) {
      params.forEach((key, v) {
        if (v != null && key != null) {
          Map<String, dynamic> d = {
            key: v[0] != null
                ? Uri.decodeComponent(v[0])
                : Uri.decodeComponent(v)
          };
          result.addEntries(d.entries);
        }
      });
    }
    return result;
  }
}

class NotFoundPage extends StatelessWidget {
  String basePath;

  NotFoundPage({super.key, required this.basePath});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextButton(
                  onPressed: () {
                    RouteService.router.navigateTo(context, basePath);
                  },
                  child: Text("Back")),
            ),
            Text("Url not found. 404"),
          ],
        )),
      ),
    );
  }
}

class ForbiddenPage extends StatelessWidget {
  String basePath;

  ForbiddenPage({super.key, required this.basePath});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextButton(
                  onPressed: () {
                    RouteService.router.navigateTo(context, basePath);
                  },
                  child: Text("Back")),
            ),
            Text("Forbidden. 403"),
          ],
        )),
      ),
    );
  }
}
