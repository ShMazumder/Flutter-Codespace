import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/task_service.dart';
import '../services/user_service.dart';
import 'task_card.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final UserModel user;
  final TaskService taskService;
  final UserService userService;
  final Function(Task) onTaskAction;

  const TaskList({
    required this.tasks,
    required this.user,
    required this.taskService,
    required this.userService,
    required this.onTaskAction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          user: user,
          taskService: taskService,
          userService: userService,
          // The onActionPressed is now handled internally by TaskCard
        );
      },
    );
  }
}