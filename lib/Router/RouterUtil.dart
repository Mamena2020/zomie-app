// import 'dart:html' as html;
import 'package:universal_html/html.dart' as html;

class RouterUtil {
  static void changeUrl({String? title, required String url}) {
    // html.window.history.pushState(null, 'home', '/home/other');
    html.window.history.pushState(null, title ?? '', url);
  }

  static void redirect({required String url}) {
    html.window.location.href = Uri.parse(url).toString();
  }
}
