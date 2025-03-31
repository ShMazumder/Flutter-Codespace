import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addPoints(String userId, int points) async {
    await _firestore.collection('users').doc(userId).update({
      'points': FieldValue.increment(points),
    });
  }

  Future<int> updateDailyStreak(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final lastCompleted = userDoc.data()?['lastDailyTaskDate'] as Timestamp?;
    final currentStreak = userDoc.data()?['dailyStreak'] ?? 0;

    final now = DateTime.now();
    final lastDate = lastCompleted?.toDate();

    int newStreak = currentStreak;
    
    if (lastDate == null || now.difference(lastDate).inDays > 1) {
      newStreak = 1;
    } else if (now.difference(lastDate).inDays == 1) {
      newStreak = currentStreak + 1;
    }

    await _firestore.collection('users').doc(userId).update({
      'dailyStreak': newStreak,
      'lastDailyTaskDate': FieldValue.serverTimestamp(),
    });

    return newStreak;
  }
}