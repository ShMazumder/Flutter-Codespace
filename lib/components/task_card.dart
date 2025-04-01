import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task_model.dart';
import '../services/ad_service.dart';
import '../services/referral_service.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../components/referral_section.dart';
import '../components/ad_reward_card.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final UserModel user;
  final TaskService taskService;
  final UserService userService;

  const TaskCard({
    required this.task,
    required this.user,
    required this.taskService,
    required this.userService,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    switch (task.type) {
      case TaskType.dailyWatchAd:
        return AdRewardCard();
      case TaskType.invite:
        return ReferralSection();
      case TaskType.dailyVisit:
      default:
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: task.color.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(task.icon, color: task.color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionButton(context),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildActionButton(BuildContext context) {
    switch (task.status) {
      case TaskStatus.completed:
        return _buildCompletedButton();
      case TaskStatus.participated:
        return _buildClaimButton(context);
      case TaskStatus.available:
        return _buildTaskSpecificButton(context);
    }
  }

  Widget _buildTaskSpecificButton(BuildContext context) {
    switch (task.type) {
      case TaskType.dailyWatchAd:
        return _buildAdTaskButton(context);
      case TaskType.dailyVisit:
        return _buildVisitTaskButton(context);
      case TaskType.invite:
        return _buildInviteTaskButton(context);
      default:
        return Center();
    }
  }

  Widget _buildAdTaskButton(BuildContext context) {
    return ElevatedButton(
      style: _buttonStyle(Colors.blue),
      onPressed: () => _handleAdTask(context),
      child: Text('Watch Ad (+${task.points} pts)'),
    );
  }

  Widget _buildVisitTaskButton(BuildContext context) {
    return ElevatedButton(
      style: _buttonStyle(Colors.green),
      onPressed: () => _handleVisitTask(context),
      child: Text('Visit Site (+${task.points} pts)'),
    );
  }

  Widget _buildInviteTaskButton(BuildContext context) {
    return ElevatedButton(
      style: _buttonStyle(Colors.purple),
      onPressed: () => _handleInviteTask(context),
      child: Text('Invite (+${task.points} pts)'),
    );
  }

  Widget _buildClaimButton(BuildContext context) {
    return ElevatedButton(
      style: _buttonStyle(Colors.orange),
      onPressed: () => _completeTask(context, task.points),
      child: const Text('Claim'),
    );
  }

  Widget _buildCompletedButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Claimed',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Future<void> _handleAdTask(BuildContext context) async {
    try {
      await taskService.updateTaskStatus(
        userId: user.id,
        taskId: task.id,
        status: TaskStatus.participated,
      );

      final adService = getAdService();
      await adService.showAd(
        onReward: (_) => _completeTask(context, task.points),
        onError: (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ad Error: $error')),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handleVisitTask(BuildContext context) async {
    try {
      await taskService.updateTaskStatus(
        userId: user.id,
        taskId: task.id,
        status: TaskStatus.participated,
      );

      const url = 'https://your-site.com'; // Replace with your URL
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        _completeTask(context, task.points);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _handleInviteTask(BuildContext context) async {
    try {
      final referralCode = await ReferralService().getReferralCode(user.id);
      await Share.share(
        'Join me on this awesome app! Use my referral code: $referralCode\n\nhttps://yourapp.com', // Replace with your app link
        subject: 'Join me!',
      );

      // Mark as participated when shared
      await taskService.updateTaskStatus(
        userId: user.id,
        taskId: task.id,
        status: TaskStatus.participated,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  Future<void> _completeTask(BuildContext context, int points) async {
    try {
      await taskService.updateTaskStatus(
        userId: user.id,
        taskId: task.id,
        status: TaskStatus.completed,
      );
      await userService.addPoints(user.id, points);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing task: $e')),
      );
    }
  }
}
