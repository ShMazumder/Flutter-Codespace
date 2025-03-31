import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_service.dart';

class MobileAdService implements AdService {
  RewardedAd? _rewardedAd;
  final String adUnitId;

  MobileAdService({this.adUnitId = 'ca-app-pub-3940256099942544/5224354917'});

  @override
  Future<void> loadAd() async {
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
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

  @override
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
    
    return count < AdService.dailyAdLimit;
  }

  @override
  Future<void> showAd({
    required Function(int) onReward,
    required Function(String) onError,
  }) async {
    if (_rewardedAd == null) await loadAd();
    
    if (!(await canShowAd())) {
      onError('Daily limit reached (${AdService.dailyAdLimit} ads)');
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
        
        onReward(AdService.pointsPerAd);
      },
    );
  }
}