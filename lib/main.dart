import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zomie_app/Services/InitServices.dart';
import 'package:zomie_app/Services/WebRtc/WRTCService.dart';
import 'StateManagement/Providers/proSet.dart';
import 'Router/RouterService.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

Future<void> main() async {
  await InitServices.instance.LoadAllServices();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      print("detached");
      await WRTCService.instance().Destroy();
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<ProSet>(
            create: (context) => ProSet(),
          ),
        ],
        child: Builder(
            builder: (context) => MaterialApp(
                  title: 'zomie',
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(
                    primarySwatch: Colors.teal,
                    textTheme: Theme.of(context)
                        .textTheme
                        .apply(fontFamily: 'Open Sans'),
                  ),
                  initialRoute: RouteService.path,
                  onGenerateRoute: RouteService.router.generator,
                )));
  }
}
