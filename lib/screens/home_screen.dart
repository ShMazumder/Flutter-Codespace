import 'package:flutter/material.dart';
import 'package:flutter_app/screens/dailyreward_screen.dart';
import 'package:flutter_app/screens/dailyvisit_screen.dart';
import 'package:flutter_app/screens/invite_screen.dart';
import 'package:provider/provider.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../components/main_nav_bar.dart';
import '../admin_provider.dart';
import 'admin_screen.dart';
import '../auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
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

    final List<Widget> screens = [
      _buildTaskScreen(user),
      if (adminProvider.isAdmin) _buildAdminScreen(),
      _buildRewardsScreen(user),
      _buildReferralScreen(user),
      _buildProfileScreen(user),
    ];

    return Scaffold(
      // appBar: _currentIndex == 0
      //     ? AppBar(
      //         title: const Text('Daily Tasks'),
      //         actions: [
      //           IconButton(
      //             icon: const Icon(Icons.notifications),
      //             onPressed: _showNotifications,
      //           ),
      //         ],
      //       )
      //     : null,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: screens,
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
    return DailyVisitScreen(
      user: user,
      taskService: _taskService,
      userService: _userService,
      callback: _initializeData,
    );
  }

  Widget _buildAdminScreen() {
    return AdminScreen();
  }

  Widget _buildRewardsScreen(UserModel user) {
    return DailyRewardScreen(
      user: user,
      taskService: _taskService,
      userService: _userService,
      callback: _initializeData,
    );
  }

  Widget _buildReferralScreen(UserModel user) {
    return DailyInviteScreen(
      taskService: _taskService,
      user: user,
      userService: _userService,
      callback: _initializeData,
    );
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

  // Future<void> _handleTaskAction(Task task, String userId) async {
  //   try {
  //     if (task.status == TaskStatus.available) {
  //       await _taskService.updateTaskStatus(
  //         userId: userId,
  //         taskId: task.id,
  //         status: TaskStatus.participated,
  //       );
  //     } else if (task.status == TaskStatus.participated) {
  //       await _taskService.updateTaskStatus(
  //         userId: userId,
  //         taskId: task.id,
  //         status: TaskStatus.completed,
  //       );

  //       await _userService.addPoints(userId, task.points);

  //       if (task.isDaily) {
  //         final newStreak = await _userService.updateDailyStreak(userId);
  //         await _taskService.checkAndUnlockSpecialTasks(userId, newStreak);
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to update task: $e')),
  //       );
  //     }
  //   }
  // }

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
