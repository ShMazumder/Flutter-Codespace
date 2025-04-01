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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.checkAdminStatus();
    } catch (e) {
      debugPrint('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              title: const Text('Daily Tasks'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: _showNotifications,
                ),
              ],
            )
          : null,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
        onPageChanged: (index) => setState(() => _currentIndex = index),
      ),
      bottomNavigationBar: MainNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No tasks available'));
        }

        final tasks =
            snapshot.data!.docs.map((doc) => Task.fromFirestore(doc)).toList();

        return RefreshIndicator(
          onRefresh: () => _initializeData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                PointsDisplay(),
                const SizedBox(height: 16),
                const AdRewardCard(),
                const SizedBox(height: 16),
                ReferralSection(),
                const SizedBox(height: 16),
                // TaskList(
                //   tasks: tasks,
                //   onTaskAction: (task) => _handleTaskAction(task, user.id),
                // ),
                TaskList(
                  tasks: tasks,
                  user: user, // Make sure to pass the UserModel
                  taskService: _taskService, // Pass the TaskService instance
                  userService: _userService, // Pass the UserService instance
                  onTaskAction: (task) {
                    // This can remain for any parent-level handling
                    // Though most logic is now in TaskCard
                  },
                ),
                _buildSpecialTasksSection(user, user.dailyStreak),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminScreen() {
    return AdminScreen();
  }

  Widget _buildRewardsScreen() {
    return const Center(child: Text('Rewards Screen'));
  }

  Widget _buildReferralScreen() {
    return const Center(child: Text('Referral Screen'));
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
            child: user.photoUrl == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(user.email),
          const SizedBox(height: 16),
          Text('Points: ${user.points}', style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _confirmSignOut,
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialTasksSection(UserModel user, int streak) {
    if (streak < 3) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: _taskService.getAvailableTasks(user.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final specialTasks = snapshot.data!.docs
            .map((doc) => Task.fromFirestore(doc))
            .where((t) => t.type == TaskType.dailyVisit)
            .toList();

        if (specialTasks.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Text(
                'Special Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // TaskList(
            //   tasks: specialTasks,
            //   onTaskAction: (task) => _handleTaskAction(task, userId),
            // ),
            TaskList(
              tasks: specialTasks,
              user: user, // Make sure to pass the UserModel
              taskService: _taskService, // Pass the TaskService instance
              userService: _userService, // Pass the UserService instance
              onTaskAction: (task) {
                // This can remain for any parent-level handling
                // Though most logic is now in TaskCard
              },
            )
          ],
        );
      },
    );
  }

  // Widget _buildSpecialTasksSection(String userId, int streak) {
  //   if (streak < 3) return const SizedBox();

  //   return StreamBuilder<QuerySnapshot>(
  //     stream: _taskService.getAvailableTasks(userId),
  //     builder: (context, snapshot) {
  //       if (snapshot.hasError) return const SizedBox();
  //       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();

  //       final specialTasks = snapshot.data!.docs
  //           .map((doc) => Task.fromFirestore(doc))
  //           .where((t) => t.type == TaskType.special)
  //           .toList();

  //       if (specialTasks.isEmpty) return const SizedBox();

  //       return Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Padding(
  //             padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
  //             child: Text(
  //               'Special Tasks',
  //               style: TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //           TaskList(
  //             tasks: specialTasks,
  //             onTaskAction: (task) => _handleTaskAction(task, userId),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    }
  }

  void _showNotifications() {
    // Implement notification logic
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
    }
  }
}
