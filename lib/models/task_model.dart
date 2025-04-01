import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { available, participated, completed }

enum TaskType {
  // daily, special, referral, ad,
  dailyWatchAd,
  dailyVisit,
  invite
}

class Task {
  final String id;
  final String title;
  final String description;
  final int points;
  final IconData icon;
  final Color color;
  final TaskType type;
  TaskStatus status;
  final DateTime? completedAt;
  final bool isDaily;
  final int requiredStreak;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.icon,
    required this.color,
    required this.type,
    this.status = TaskStatus.available,
    this.completedAt,
    this.isDaily = true,
    this.requiredStreak = 0,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      points: data['points'] ?? 0,
      icon: _getIcon(data['icon']),
      color: _getColor(data['color']),
      type: _getType(data['type']),
      status: _getStatus(data['status']),
      completedAt: data['completedAt']?.toDate(),
      isDaily: data['isDaily'] ?? true,
      requiredStreak: data['requiredStreak'] ?? 0,
    );
  }

  static IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'play':
        return Icons.play_circle_fill;
      case 'people':
        return Icons.people;
      case 'star':
        return Icons.star;
      case 'watch':
        return Icons.play_circle_filled;
      case 'visit':
        return Icons.open_in_browser;
      case 'invite':
        return Icons.share;
      default:
        return Icons.task;
    }
  }

  static Color _getColor(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'amber':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  static TaskType _getType(String type) {
    switch (type) {
      case 'dailyWatchAd':
        return TaskType.dailyWatchAd;
      case 'dailyVisit':
        return TaskType.dailyVisit;
      case 'invite':
        return TaskType.invite;
      // case 'special':
      //   return TaskType.special;
      // case 'referral':
      //   return TaskType.referral;
      // case 'ad':
      //   return TaskType.ad;
      default:
        return TaskType.dailyWatchAd;
    }
  }

  static TaskStatus _getStatus(String status) {
    switch (status) {
      case 'participated':
        return TaskStatus.participated;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.available;
    }
  }
}
