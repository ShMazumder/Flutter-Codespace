import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getAvailableTasks(String userId) {
    return _firestore
        // .collection('users')
        // .doc(userId)
        .collection('tasks')
        .where('status', isEqualTo: 'available')
        .snapshots();
    // .map((snapshot) => snapshot.docs
    //     .map((doc) => Task.fromFirestore(doc))
    //     .toList());
  }

  Future<void> updateTaskStatus({
    required String userId,
    required String taskId,
    required TaskStatus status,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .set({
      'status': status.name,
      if (status == TaskStatus.completed)
        'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> checkAndUnlockSpecialTasks(
      String userId, int currentStreak) async {
    final specialTasks = await _firestore
        .collection('tasks')
        .where('type', isEqualTo: 'dailyVisit')
        .where('requiredStreak', isLessThanOrEqualTo: currentStreak)
        .get();

    for (var task in specialTasks.docs) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(task.id)
          .set({
        ...task.data(),
        'status': 'available',
      });
    }
  }

  //   Future<void> checkAndUnlockSpecialTasks(
  //     String userId, int currentStreak) async {
  //   final specialTasks = await _firestore
  //       .collection('tasks')
  //       .where('type', isEqualTo: 'special')
  //       .where('requiredStreak', isLessThanOrEqualTo: currentStreak)
  //       .get();

  //   for (var task in specialTasks.docs) {
  //     await _firestore
  //         .collection('users')
  //         .doc(userId)
  //         .collection('tasks')
  //         .doc(task.id)
  //         .set({
  //       ...task.data(),
  //       'status': 'available',
  //     });
  //   }
  // }

  Stream<QuerySnapshot> getAvailableRewardTasks(String userId) {
    return _firestore
        // .collection('users')
        // .doc(userId)
        .collection('tasks')
        .where('status', isEqualTo: 'available')
        .snapshots();
    // .map((snapshot) => snapshot.docs
    //     .map((doc) => Task.fromFirestore(doc))
    //     .toList());
  }

    Stream<QuerySnapshot> getAvailableRefferalTasks(String userId) {
    return _firestore
        // .collection('users')
        // .doc(userId)
        .collection('tasks')
        .where('status', isEqualTo: 'available')
        .snapshots();
    // .map((snapshot) => snapshot.docs
    //     .map((doc) => Task.fromFirestore(doc))
    //     .toList());
  }
}
