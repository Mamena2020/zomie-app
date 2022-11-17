import 'package:zomie_app/Views/Call/RoomView.dart';

import '/Controllers/HomeController.dart';

import '/Router/Models/SetupModel.dart';

class RegisterRouter {
  static List<SetRouter> Routers() {
    return [
      SetRouter(path: "/", child: HomeController().index()),
      SetRouter(path: RoomView.routeName, child: RoomView()),
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
