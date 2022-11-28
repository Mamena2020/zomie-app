import 'package:flutter/material.dart';

class Widgets {
  static Future<void> ShowDialog(
      {required BuildContext context,
      required double width,
      required double height,
      required Widget child}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext _context) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.of(_context).pop();
            return false;
          },
          child: StatefulBuilder(builder: (context, setstate) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0))),
              content: Container(
                  height: height,
                  width: width,
                  child: Theme(
                    data: new ThemeData(
                        primaryColor: Colors
                            .blueGrey[100], // warna ketika click textfield
                        hintColor: Colors.white // warna border awal textfield
                        ),
                    child: SizedBox(
                        //  height: 50,
                        child: child),
                  )),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    "Close",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  onPressed: () async {
                    Navigator.of(_context).pop();
                  },
                ),
              ],
            );
          }),
        );
      },
    );
  }
}
