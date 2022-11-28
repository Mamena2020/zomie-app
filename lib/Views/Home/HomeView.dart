import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zomie_app/Controllers/SettingController.dart';
import 'package:zomie_app/Router/RouterService.dart';
import 'package:zomie_app/Services/WebRTC/Controller/WRTCRoomController.dart';
import 'package:zomie_app/Services/WebRTC/Models/Room.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';
import 'package:zomie_app/StateManagement/Providers/proSet.dart';
import 'package:zomie_app/Views/Room/RoomView.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  TextEditingController tecRoomID = TextEditingController();
  double width = 0;
  double height = 0;
  ProSet? proSet;

  @override
  Widget build(BuildContext context) {
    proSet = Provider.of<ProSet>(context);
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text("Zomie"),
        actions: [
          IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                RouteService.router.navigateTo(
                  context,
                  SettingController.indexRouteName,
                );
              }),
        ],
      ),
      body: Container(
          color: Colors.white,
          child: Center(
              child: SizedBox(
                  height: width > 300 ? 60 : 200,
                  width: width * 0.9,
                  child: Center(
                      child: Wrap(children: [
                    CreateRoom(),
                    for (var a in Actions()) a
                  ]))))),
    );
  }

  Widget CreateRoom() {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () async {
          if (proSet!.setting.passwordRequired) {
            PasswordDialog();
          } else {
            Room room = await WRTCRoomController.CreateRoom(
                life_time: proSet!.setting.roomLifeTime.lifeTime,
                video_bitrate: proSet!.setting.video_bitrate,
                screen_bitrate: proSet!.setting.screen_bitrate);
            tecRoomID.text = room.id;
            setState(() {});
          }
          // after create, then jump to room immediately
        },
        child: Text(
          "Create Room",
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          // shape: CircleBorder(),
          padding: EdgeInsets.all(10),
          backgroundColor: Colors.teal, // <-- Button color
          // foregroundColor: Colors.red, // <-- Splash color
        ),
      ),
    );
  }

  List<Widget> Actions() {
    return [
      SizedBox(
        width: 150.0,
        height: 50,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            child: TextField(
              controller: tecRoomID,
              onChanged: (c) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Room id or link',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: EdgeInsets.symmetric(vertical: 15.0),
              ),
            ),
          ),
        ),
      ),
      SizedBox(
        height: 40,
        child: InkWell(
          onTap: () async {
            if (tecRoomID.text.isNotEmpty) {
              RouteService.router
                  .navigateTo(context, "/room/" + tecRoomID.text);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              "Join",
              style: TextStyle(
                  color: tecRoomID.text.isEmpty
                      ? Colors.grey.withOpacity(0.5)
                      : Colors.teal),
            ),
          ),
        ),
      )
    ];
  }

  Future<void> PasswordDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext _context) {
        var _tecPassword = TextEditingController();
        var _isValidPassword = true;
        var _isValidPasswordMsg = "";
        bool _isVisiblePassword = false;
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
                  height: 60,
                  width: width > 250 ? 250 : width * 0.9,
                  child: Theme(
                    data: new ThemeData(
                        primaryColor: Colors
                            .blueGrey[100], // warna ketika click textfield
                        hintColor: Colors.white // warna border awal textfield
                        ),
                    child: SizedBox(
                      //  height: 50,
                      child: TextField(
                        controller: _tecPassword,
                        onChanged: (c) {
                          setstate(() {
                            if (_tecPassword.text.isNotEmpty) {
                              _isValidPassword = true;
                            }
                          });
                        },
                        obscureText: _isVisiblePassword ? false : true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          contentPadding: EdgeInsets.symmetric(vertical: 18.0),
                          errorStyle: TextStyle(
                              fontSize: 10, color: Colors.red.shade600),
                          errorText:
                              _isValidPassword ? null : _isValidPasswordMsg,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setstate(() {
                                _isVisiblePassword = !_isVisiblePassword;
                              });
                            },
                            icon: Icon(
                              _isVisiblePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off_rounded,
                              color: _isVisiblePassword
                                  ? Colors.teal
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  onPressed: () async {
                    Navigator.of(_context).pop();
                  },
                ),
                TextButton(
                  child: Text(
                    "Create",
                    style: TextStyle(color: Colors.teal.shade800),
                  ),
                  onPressed: () async {
                    if (_tecPassword.text.isEmpty) {
                      _isValidPassword = false;
                      _isValidPasswordMsg = "Required";
                    } else if (_tecPassword.text.length < 5) {
                      _isValidPassword = false;
                      _isValidPasswordMsg = "Must be more than 4 characters";
                    }
                    setstate(() {});
                    if (_isValidPassword) {
                      Room room = await WRTCRoomController.CreateRoom(
                          password: _tecPassword.text,
                          life_time: proSet!.setting.roomLifeTime.lifeTime,
                          video_bitrate: proSet!.setting.video_bitrate,
                          screen_bitrate: proSet!.setting.screen_bitrate);
                      tecRoomID.text = room.id;
                      setState(() {});
                      Navigator.of(_context).pop();
                    }
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
