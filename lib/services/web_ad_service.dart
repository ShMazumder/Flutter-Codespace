import 'package:shared_preferences/shared_preferences.dart';
import 'ad_service.dart';

class WebAdService implements AdService {
  @override
  Future<void> loadAd() async {
    // No need to load ads for web implementation
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<bool> canShowAd() async {
    // For web, we'll use the same daily limit logic
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
    if (!(await canShowAd())) {
      onError('Daily limit reached (${AdService.dailyAdLimit} ads)');
      return;
    }

    // Simulate ad view with a dialog
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('adCount', (prefs.getInt('adCount') ?? 0) + 1);
    
    // In a real app, you would show an actual ad here
    // For demo purposes, we'll just reward points after a delay
    await Future.delayed(const Duration(seconds: 2));
    onReward(AdService.pointsPerAd);
  }
}