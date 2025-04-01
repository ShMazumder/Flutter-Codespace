import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/task_model.dart';

class AdminProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isAdmin = false;

  bool get isAdmin => _isAdmin;

  Future<void> checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      _isAdmin = doc.exists;
      notifyListeners();
    }
  }

  Future<void> addTask({
    required String title,
    required String description,
    required int points,
    required TaskType type, // 'ad', 'visit', 'invite'
    String? link, // Required for 'visit' tasks
  }) async {
    await _firestore.collection('tasks').add({
      'title': title,
      'description': description,
      'points': points,
      'type': type.name,
      'link': type == TaskType.dailyVisit ? link : null, // Store link only for visit tasks
      'isDefault': true,
      'status': 'available',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
