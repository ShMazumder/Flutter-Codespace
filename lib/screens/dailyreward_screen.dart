import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/task_list.dart';
import 'package:flutter_app/models/task_model.dart';
import 'package:flutter_app/models/user_model.dart';
import 'package:flutter_app/services/task_service.dart';
import 'package:flutter_app/services/user_service.dart';

class DailyRewardScreen extends StatefulWidget {
  final TaskService taskService;
  final UserModel user;
  final UserService userService;
  final Future<void> Function() callback;

  const DailyRewardScreen(
      {super.key,
      required this.taskService,
      required this.user,
      required this.userService,
      required this.callback});

  @override
  DailyRewardScreenState createState() => DailyRewardScreenState();
}

class DailyRewardScreenState extends State<DailyRewardScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daily Reward')),
      body: StreamBuilder<QuerySnapshot>(
        stream: widget.taskService.getAvailableTasks(widget.user.id),
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

          final tasks = snapshot.data!.docs
              .map((doc) => Task.fromFirestore(doc))
              .toList();

          return RefreshIndicator(
            onRefresh: () => widget.callback(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // PointsDisplay(),
                  const SizedBox(height: 16),
                  TaskList(
                    tasks: tasks,
                    user: widget.user, // Make sure to pass the UserModel
                    taskService:
                        widget.taskService, // Pass the TaskService instance
                    userService:
                        widget.userService, // Pass the UserService instance
                    onTaskAction: (task) {
                      // This can remain for any parent-level handling
                      // Though most logic is now in TaskCard
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
