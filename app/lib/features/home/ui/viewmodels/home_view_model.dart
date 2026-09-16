import 'package:get/get.dart';

class HomeViewModel extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }
}
