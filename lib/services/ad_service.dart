import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  static const int pointsPerAd = 150;
  static const int dailyAdLimit = 5;
  
  RewardedAd? _rewardedAd;
  final String adUnitId;

  AdService({required this.adUnitId});

  Future<void> loadAd() async {
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<bool> canShowAd() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('lastAdDate');
    final count = prefs.getInt('adCount') ?? 0;
    
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (lastDate != today) {
      await prefs.setString('lastAdDate', today);
      await prefs.setInt('adCount', 0);
      return true;
    }
    
    return count < dailyAdLimit;
  }

  Future<void> showAd({
    required Function(int) onReward,
    required Function(String) onError,
  }) async {
    if (_rewardedAd == null) await loadAd();
    
    if (!(await canShowAd())) {
      onError('Daily limit reached (5 ads)');
      return;
    }

    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        onError(error.message);
        loadAd();
      },
    );

    _rewardedAd?.show(
      onUserEarnedReward: (ad, reward) async {
        final prefs = await SharedPreferences.getInstance();
        final count = (prefs.getInt('adCount') ?? 0) + 1;
        await prefs.setInt('adCount', count);
        
        onReward(pointsPerAd);
      },
    );
  }
}