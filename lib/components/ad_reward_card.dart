import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AdRewardCard extends StatefulWidget {
  const AdRewardCard({super.key});

  @override
  AdRewardCardState createState() => AdRewardCardState();
}

class AdRewardCardState extends State<AdRewardCard> {
  late final AdService _adService;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _adService = getAdService();
    _adService.loadAd();
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final user = Provider.of<UserModel>(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.play_circle_filled, size: 40, color: Colors.red),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Watch Ad for Points',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Earn ${AdService.pointsPerAd} points per ad'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.green,
              ),
              onPressed: _isLoading ? null : () => _showAd(user, userService),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Watch Ad (+${AdService.pointsPerAd} pts)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAd(UserModel user, UserService userService) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _adService.showAd(
      onReward: (points) async {
        await userService.addPoints(user.id, points);
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = error;
          });
        }
      },
    );
  }
}