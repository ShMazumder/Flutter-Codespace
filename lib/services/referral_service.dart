import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/referral_tier.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getReferralCode(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['referralCode'] ?? '';
  }

  Future<void> handleReferral(
      String referredUserId, String referralCode) async {
    final query = await _firestore
        .collection('users')
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    final referrerId = query.docs.first.id;
    if (referrerId == referredUserId) return;

    await _firestore
        .collection('users')
        .doc(referrerId)
        .collection('referrals')
        .doc(referredUserId)
        .set({
      'referredUserId': referredUserId,
      'timestamp': FieldValue.serverTimestamp(),
      'pointsAwarded': false,
    });

    await _updateReferralCount(referrerId);
  }

  Future<void> _updateReferralCount(String userId) async {
    final referrals = await _firestore
        .collection('users')
        .doc(userId)
        .collection('referrals')
        .count()
        .get();

    final totalReferrals = referrals.count;
    await _firestore.collection('users').doc(userId).update({
      'totalReferrals': totalReferrals,
    });

    await _awardTieredPoints(userId, totalReferrals ?? 0);
  }

  Future<void> _awardTieredPoints(String userId, int totalReferrals) async {
    int pointsToAward = 0;
    int awardedUpTo = 0;

    for (final tier in ReferralTier.tiers) {
      if (totalReferrals >= tier.count) {
        pointsToAward = tier.points;
        awardedUpTo = tier.count;
      }
    }

    if (pointsToAward > 0) {
      final batch = _firestore.batch();
      final referrals = await _firestore
          .collection('users')
          .doc(userId)
          .collection('referrals')
          .where('pointsAwarded', isEqualTo: false)
          .limit(awardedUpTo)
          .get();

      for (final doc in referrals.docs) {
        batch.update(doc.reference, {'pointsAwarded': true});
      }

      batch.update(_firestore.collection('users').doc(userId), {
        'points': FieldValue.increment(pointsToAward),
      });

      await batch.commit();
    }
  }
}
