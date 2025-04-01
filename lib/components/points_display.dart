import 'package:flutter/material.dart';
import '../models/user_model.dart';

class PointsDisplay extends StatelessWidget {
  final UserModel user;
  const PointsDisplay({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // final user = Provider.of<UserModel>(context);
    print("${user.points}");

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Points',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${user.points}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '≈ \$${(user.points / 2440).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
