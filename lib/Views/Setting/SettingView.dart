import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zomie_app/Services/WebRTC/Models/RoomBitrate.dart';
import 'package:zomie_app/Services/WebRTC/Models/RoomLifeTime.dart';
import 'package:zomie_app/StateManagement/Providers/proSet.dart';
import 'package:zomie_app/Widgets/Widgets.dart';

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
  RoomBitrate roomBitrateVideoSelected =
      RoomBitrate.RoomBitrates[RoomBitrate.GetBitrateIndex(75)];
  RoomBitrate roomBitrateScreenSelected =
      RoomBitrate.RoomBitrates[RoomBitrate.GetBitrateIndex(125)];
  Load() {
    //----------------------------- lifetime
    int i =
        RoomLifeTime.GetLifeTimeIndex(proSet!.setting.roomLifeTime.lifeTime);
    if (i >= 0) {
      roomLifeTimeSelected = RoomLifeTime.roomLifeTimes[i];
    }
    //----------------------------- bitrate
    i = RoomBitrate.GetBitrateIndex(proSet!.setting.video_bitrate);
    if (i >= 0) {
      roomBitrateVideoSelected = RoomBitrate.RoomBitrates[i];
    }
    i = RoomBitrate.GetBitrateIndex(proSet!.setting.screen_bitrate);
    if (i >= 0) {
      roomBitrateScreenSelected = RoomBitrate.RoomBitrates[i];
    }

    setState(() {
      isLoad = true;
    });
  }

  Size size = Size.zero;

  @override
  Widget build(BuildContext context) {
    proSet = Provider.of<ProSet>(context);
    size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text("Setting"),
        flexibleSpace: Widgets.AppbarBg(),
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
      // CheckboxListTile(
      //   title: Text(
      //     "Ask when user join room",
      //     style: TextStyle(fontSize: 13),
      //   ),
      //   value: proSet!.setting.askWhenJoin,
      //   onChanged: (newValue) {
      //     setState(() {
      //       proSet!.setting.askWhenJoin = newValue!;
      //     });
      //   },
      //   controlAffinity:
      //       ListTileControlAffinity.leading, //  <-- leading Checkbox
      // ),
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
                "Video bitrate on the room",
                style: TextStyle(fontSize: 13),
              ),
              _VideoBitrateOption(),
            ],
          ),
        ),
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
                "Screen share bitrate on the room",
                style: TextStyle(fontSize: 13),
              ),
              _ScreenBitrateOption(),
            ],
          ),
        ),
      )
    ];
  }

  Widget _RoomLifeTimeOption() {
    return DropdownButton<RoomLifeTime>(
      hint: Text("Select lifetime"),
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

  Widget _VideoBitrateOption() {
    return DropdownButton<RoomBitrate>(
      hint: Text("Select bitrate"),
      value: roomBitrateVideoSelected,
      onChanged: (value) {
        setState(() {
          roomBitrateVideoSelected = value!;
          proSet!.setting.video_bitrate = value.bitrate;
        });
      },
      items: RoomBitrate.RoomBitrates.map((_bitrate) {
        return DropdownMenuItem<RoomBitrate>(
          value: _bitrate,
          child: Text(
            _bitrate.unit,
            style: TextStyle(color: Colors.black, fontSize: 13),
          ),
        );
      }).toList(),
    );
  }

  Widget _ScreenBitrateOption() {
    return DropdownButton<RoomBitrate>(
      hint: Text("Select bitrate"),
      value: roomBitrateScreenSelected,
      onChanged: (value) {
        setState(() {
          roomBitrateScreenSelected = value!;
          proSet!.setting.screen_bitrate = value.bitrate;
        });
      },
      items: RoomBitrate.RoomBitrates.map((_bitrate) {
        return DropdownMenuItem<RoomBitrate>(
          value: _bitrate,
          child: Text(
            _bitrate.unit,
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
          Widgets.ShowDialog(
              context: context,
              width: size.width * 0.7,
              height: size.height * 0.7,
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView(
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                                text:
                                    'MIT License \n\nCopyright (c) 2022 Andre Aipassa '),
                            TextSpan(
                              text:
                                  '\n\nPermission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:',
                            ),
                            TextSpan(
                                text:
                                    '\n\nThe above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.'),
                            TextSpan(
                                text:
                                    '\n\nTHE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE'),
                          ],
                        ),
                      ),
                    ],
                  )));
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
