import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class UserModel with ChangeNotifier {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  int points;
  int dailyStreak;
  int adsViewedToday;
  int totalReferrals;
  final String referralCode;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.points = 0,
    this.dailyStreak = 0,
    this.adsViewedToday = 0,
    this.totalReferrals = 0,
    required this.referralCode,
  });

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      points: 0,
      dailyStreak: 0,
      adsViewedToday: 0,
      totalReferrals: 0,
      referralCode: _generateReferralCode(),
    );
  }

  static String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (index) => chars[Random().nextInt(chars.length)])
        .join();
  }

  // Add your methods to update user data
  void addPoints(int newPoints) {
    points += newPoints;
    notifyListeners();
  }
}
