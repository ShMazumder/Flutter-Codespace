import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../components/points_display.dart';
import '../components/task_list.dart';
import '../components/main_nav_bar.dart';
import '../components/referral_section.dart';
import '../components/ad_reward_card.dart';
import '../admin_provider.dart';
import '../models/task_model.dart';
import 'admin_screen.dart';
import '../auth_provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.checkAdminStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    final adminProvider = Provider.of<AdminProvider>(context);

    final List<Widget> _screens = [
      _buildTaskScreen(user),
      if (adminProvider.isAdmin) _buildAdminScreen(),
      _buildRewardsScreen(),
      _buildReferralScreen(),
      _buildProfileScreen(user),
    ];

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: Text('Daily Tasks'),
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: _screens,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
      ),
      bottomNavigationBar: MainNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // if (index == 1 && adminProvider.isAdmin) {
          //   // go to admin
          //   return;
          // }
          
          _pageController.jumpToPage(index);
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Widget _buildTaskScreen(UserModel user) {
    return StreamBuilder<QuerySnapshot>(
      stream: _taskService.getAvailableTasks(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No tasks available'));
        }

        final tasks =
            snapshot.data!.docs.map((doc) => Task.fromFirestore(doc)).toList();

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                PointsDisplay(),
                SizedBox(height: 16),
                AdRewardCard(),
                SizedBox(height: 16),
                ReferralSection(),
                SizedBox(height: 16),
                TaskList(
                  tasks: tasks,
                  onTaskAction: (task) => _handleTaskAction(task, user.id),
                ),
                _buildSpecialTasksSection(user.id, user.dailyStreak),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminScreen() {
    return AdminScreen(); // Your existing AdminScreen widget
  }

  Widget _buildRewardsScreen() {
    return Center(child: Text('Rewards Screen'));
  }

  Widget _buildReferralScreen() {
    return Center(child: Text('Referral Screen'));
  }

  Widget _buildProfileScreen(UserModel user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null ? Icon(Icons.person, size: 50) : null,
          ),
          SizedBox(height: 16),
          Text(user.name, style: TextStyle(fontSize: 24)),
          SizedBox(height: 8),
          Text(user.email),
          SizedBox(height: 16),
          Text('Points: ${user.points}', style: TextStyle(fontSize: 20)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                Provider.of<AuthProvider>(context, listen: false).signOut(),
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialTasksSection(String userId, int streak) {
    if (streak < 3) return SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: _taskService.getAvailableTasks(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return SizedBox();

        final specialTasks = snapshot.data!.docs
            .map((doc) => Task.fromFirestore(doc))
            .where((t) => t.type == TaskType.special)
            .toList();

        if (specialTasks.isEmpty) return SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Text(
                'Special Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TaskList(
              tasks: specialTasks,
              onTaskAction: (task) => _handleTaskAction(task, userId),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleTaskAction(Task task, String userId) async {
    try {
      if (task.status == TaskStatus.available) {
        await _taskService.updateTaskStatus(
          userId: userId,
          taskId: task.id,
          status: TaskStatus.participated,
        );
      } else if (task.status == TaskStatus.participated) {
        await _taskService.updateTaskStatus(
          userId: userId,
          taskId: task.id,
          status: TaskStatus.completed,
        );

        await _userService.addPoints(userId, task.points);

        if (task.isDaily) {
          final newStreak = await _userService.updateDailyStreak(userId);
          await _taskService.checkAndUnlockSpecialTasks(userId, newStreak);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $e')),
      );
    }
  }
}
