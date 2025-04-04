import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, dynamic> userModel;

  Stream<User?> get user => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        await _initializeUserData(userCredential.user!);
        return userCredential.user;
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        await _initializeUserData(userCredential.user!);
        return userCredential.user;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> _initializeUserData(User user) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      userModel = {
        'name': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'points': 0,
        'dailyStreak': 0,
        'adsViewedToday': 0,
        'totalReferrals': 0,
        'referralCode': _generateReferralCode(),
      };
      await _firestore.collection('users').doc(user.uid).set(userModel);
      await _addDefaultTasks(user.uid);
    } else {
      userModel = userDoc.data() ?? {};
    }
  }

  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (index) => chars[Random().nextInt(chars.length)])
        .join();
  }

  Future<void> _addDefaultTasks(String userId) async {
    final defaultTasks = await _firestore
        .collection('tasks')
        .where('isDefault', isEqualTo: true)
        .get();

    for (var task in defaultTasks.docs) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(task.id)
          .set(task.data());
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
