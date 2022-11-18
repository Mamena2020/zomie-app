import 'package:zomie_app/Controllers/RoomController.dart';
import 'package:zomie_app/Controllers/SettingController.dart';
import 'package:zomie_app/Views/Room/RoomView.dart';

import '/Controllers/HomeController.dart';

import '/Router/Models/SetupModel.dart';

class RegisterRouter {
  static List<SetRouter> Routers() {
    return [
      SetRouter(path: "/", child: HomeController().index()),
      SetRouter(
          path: RoomController.indexRouteName, child: RoomController.index()),
      SetRouter(
          path: SettingController.indexRouteName,
          child: SettingController.index()),
      // SetRouter(path: RoomView.routeName + ":roomId", child: RoomView()),

      // SetRouter(path: DesignView.routeName + "/:uid/edit", child: DesignView()),
      // SetRouter(
      //     path: DetailView.routeName + "/:id",
      //     child: DetailView(),
      //     transitionType: TransitionType.inFromRight,
      //     transitionDuration: Duration(milliseconds: 200)),
    ];
  }
}
