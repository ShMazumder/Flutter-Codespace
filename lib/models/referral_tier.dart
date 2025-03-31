class ReferralTier {
  final int count;
  final int points;
  
  static const tiers = [
    ReferralTier(count: 1, points: 100),
    ReferralTier(count: 4, points: 350),
    ReferralTier(count: 14, points: 1500),
  ];

  const ReferralTier({required this.count, required this.points});
}