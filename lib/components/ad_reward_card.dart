import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AdRewardCard extends StatefulWidget {
  final AdService adService;

  const AdRewardCard({required this.adService, Key? key}) : super(key: key);

  @override
  _AdRewardCardState createState() => _AdRewardCardState();
}

class _AdRewardCardState extends State<AdRewardCard> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.adService.loadAd();
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    final user = Provider.of<UserModel>(context);

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.play_circle_filled, size: 40, color: Colors.red),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
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
            SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                primary: Colors.green,
              ),
              onPressed: _isLoading ? null : () => _showAd(user, userService),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
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

    await widget.adService.showAd(
      onReward: (points) async {
        await userService.addPoints(user.id, points);
        setState(() => _isLoading = false);
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _error = error;
        });
      },
    );
  }
}