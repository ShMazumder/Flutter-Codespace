import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'task_card.dart';

class TaskList extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task) onTaskAction;

  const TaskList({
    required this.tasks,
    required this.onTaskAction,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onActionPressed: () => onTaskAction(task),
        );
      },
    );
  }
}