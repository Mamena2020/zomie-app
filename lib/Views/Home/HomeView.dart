import 'package:flutter/material.dart';
import 'package:zomie_app/Controllers/SettingController.dart';
import 'package:zomie_app/Router/RouterService.dart';
import 'package:zomie_app/Services/WebRTC/WRTCService.dart';
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
  }

  TextEditingController tecRoomID = TextEditingController();

  double width = 0;
  double height = 0;

  @override
  Widget build(BuildContext context) {
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
          await WRTCService.instance().CreateRoom();
          tecRoomID.text = WRTCService.instance().room.id;
          setState(() {});
          // after create, then jump to room immediately
        },
        child: Text(
          "Create Room",
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          // shape: CircleBorder(),
          padding: EdgeInsets.all(17),
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
                contentPadding: EdgeInsets.symmetric(vertical: 18.0),
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
}
