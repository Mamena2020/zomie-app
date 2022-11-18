import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zomie_app/Models/RoomLifeTime.dart';
import 'package:zomie_app/StateManagement/Providers/proSet.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  ProSet? proSet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Load();
    });
  }

  bool isLoad = false;
  RoomLifeTime roomLifeTimeSelected = RoomLifeTime.roomLifeTimes.first;
  Load() {
    int i = RoomLifeTime.GetRoomInstance(proSet!.setting.roomLifeTime.lifeTime);
    if (i >= 0) {
      roomLifeTimeSelected = RoomLifeTime.roomLifeTimes[i];
    }
    setState(() {
      isLoad = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    proSet = Provider.of<ProSet>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Setting"),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: !isLoad
            ? SizedBox()
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var a in ApplicationSection()) a,
                    for (var s in SupportSection()) s
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> ApplicationSection() {
    return [
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          "Application",
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: Colors.teal.shade800),
        ),
      ),
      CheckboxListTile(
        title: Text(
          "Use password when create room",
          style: TextStyle(fontSize: 13),
        ),
        value: proSet!.setting.passwordRequired,
        onChanged: (newValue) {
          setState(() {
            proSet!.setting.passwordRequired = newValue!;
          });
        },
        controlAffinity:
            ListTileControlAffinity.leading, //  <-- leading Checkbox
      ),
      CheckboxListTile(
        title: Text(
          "Ask when user join room",
          style: TextStyle(fontSize: 13),
        ),
        value: proSet!.setting.askWhenJoin,
        onChanged: (newValue) {
          setState(() {
            proSet!.setting.askWhenJoin = newValue!;
          });
        },
        controlAffinity:
            ListTileControlAffinity.leading, //  <-- leading Checkbox
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Room life time after created",
                style: TextStyle(fontSize: 13),
              ),
              _RoomLifeTimeOption(),
            ],
          ),
        ),
      )
    ];
  }

  Widget _RoomLifeTimeOption() {
    return DropdownButton<RoomLifeTime>(
      hint: Text("Select item"),
      value: roomLifeTimeSelected,
      onChanged: (value) {
        setState(() {
          roomLifeTimeSelected = value!;
          proSet!.setting.roomLifeTime = value;
        });
      },
      items: RoomLifeTime.roomLifeTimes.map((_lifeTime) {
        return DropdownMenuItem<RoomLifeTime>(
          value: _lifeTime,
          child: Text(
            _lifeTime.name,
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> SupportSection() {
    return [
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          "Support",
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: Colors.teal.shade800),
        ),
      ),
      InkWell(
        onTap: () {
          // Widgets.TheAlertDialog(
          //     color_cancel: proSet.color.color_1,
          //     text_cancel: proSet.lan["close"],
          //     context: context,
          //     height: proSet.width * 0.7,
          //     width: proSet.width * 0.7,
          //     text: "Version App:" + Config.version_app);
        },
        child: ListTile(
          leading: Icon(Icons.info),
          title: Text(
            "About",
          ),
          trailing: RotationTransition(
              turns: new AlwaysStoppedAnimation(45 / 360),
              child: Icon(Icons.arrow_upward_outlined)),
        ),
      ),
    ];
  }
}
