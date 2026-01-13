import 'package:get/get.dart';
import '../helpers/route.dart';
import '../storage/session_manager.dart';

class SplashController extends GetxController {


  @override
  void onInit() async {
    super.onInit();
    await Future.delayed(const Duration(seconds: 2));
    checkSeenIntro();
  }

  void checkLoginStatus(){
    if(SessionManager.isLoggedIn()){
      RouteConfig.navigateToReplacePage("/home");
    }
    else{
      RouteConfig.navigateToReplacePage("/login");
    }
  }

  void checkSeenIntro(){
    if(SessionManager.isSeenIntro()){
      checkLoginStatus();
    }
    else{
      RouteConfig.navigateToReplacePage("/intro");
    }
  }

}
