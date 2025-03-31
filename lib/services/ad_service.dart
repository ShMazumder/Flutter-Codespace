import 'package:flutter/foundation.dart';
import '../services/mobile_ad_service.dart';
import '../services/web_ad_service.dart';

abstract class AdService {
  static const int pointsPerAd = 150;
  static const int dailyAdLimit = 5;

  Future<void> loadAd();
  Future<bool> canShowAd();
  Future<void> showAd({
    required Function(int) onReward,
    required Function(String) onError,
  });
}

AdService getAdService() {
  if (kIsWeb) {
    return WebAdService();
  } else {
    return MobileAdService();
  }
}
