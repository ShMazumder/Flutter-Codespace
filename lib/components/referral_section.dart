import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_model.dart';
import '../services/referral_service.dart';
import '../models/referral_tier.dart';

class ReferralSection extends StatelessWidget {
  const ReferralSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final referralService = ReferralService();

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite Friends',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Get bonus points for each friend who joins!',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: FutureBuilder<String>(
                      future: referralService.getReferralCode(user.id),
                      builder: (context, snapshot) {
                        return Text(
                          snapshot.data ?? 'Loading...',
                          style: TextStyle(fontSize: 16),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () async {
                    final code = await referralService.getReferralCode(user.id);
                    Share.share(
                      'Join me on Task Rewards App! Use my referral code: $code',
                      subject: 'Task Rewards Invitation',
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildTierList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTierList() {
    return Column(
      children: ReferralTier.tiers.map((tier) => Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber,
              ),
              child: Center(
                child: Text(tier.count.toString()),
              ),
            ),
            SizedBox(width: 16),
            Text('= ${tier.points} points'),
          ],
        ),
      )).toList(),
    );
  }
}