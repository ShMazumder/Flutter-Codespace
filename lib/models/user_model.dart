class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final int points;
  final int dailyStreak;
  final int adsViewedToday;
  final int totalReferrals;
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
}