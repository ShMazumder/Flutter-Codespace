import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reward App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;

  Future<void> _signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    setState(() {
      _user = userCredential.user;
    });
    if (_user != null) {
      _firestore.collection('users').doc(_user!.uid).set({
        'name': _user!.displayName,
        'email': _user!.email,
        'points': 0,
        'completedDailyTasks': 0,
        'watchedAds': 0,
        'invitedFriends': 0,
      }, SetOptions(merge: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: _user == null
            ? ElevatedButton(
                onPressed: _signInWithGoogle,
                child: Text('Sign in with Google'),
              )
            : HomeScreen(user: _user!),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final User user;
  HomeScreen({required this.user});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  Future<void> _participateInTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).update({'status': 'claim'});
  }

  Future<void> _claimTaskPoints(String taskId, int points) async {
    await _firestore.collection('tasks').doc(taskId).update({'status': 'claimed'});
    await _firestore.collection('users').doc(user.uid).update({
      'points': FieldValue.increment(points),
      'completedDailyTasks': FieldValue.increment(1),
    });
  }

  Future<void> _watchAd() async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    int watchedAds = userDoc['watchedAds'] ?? 0;
    if (watchedAds < 5) {
      await _firestore.collection('users').doc(user.uid).update({
        'points': FieldValue.increment(150),
        'watchedAds': FieldValue.increment(1),
      });
    }
  }

  Future<void> _inviteFriend() async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    int invitedFriends = userDoc['invitedFriends'] ?? 0;
    int pointsToAdd = 0;
    if (invitedFriends == 0) {
      pointsToAdd = 100;
    } else if (invitedFriends < 4) {
      pointsToAdd = 350;
    } else if (invitedFriends < 14) {
      pointsToAdd = 1500;
    }
    await _firestore.collection('users').doc(user.uid).update({
      'points': FieldValue.increment(pointsToAdd),
      'invitedFriends': FieldValue.increment(1),
    });
  }

  Future<void> _buyCherag(int cost, List<int> rewards) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    int currentPoints = userDoc['points'] ?? 0;
    if (currentPoints >= cost) {
      int rewardPoints = rewards[_random.nextInt(rewards.length)];
      await _firestore.collection('users').doc(user.uid).update({
        'points': FieldValue.increment(rewardPoints - cost),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('tasks').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                var tasks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var task = tasks[index];
                    return ListTile(
                      leading: Icon(Icons.task),
                      title: Text(task['title']),
                      subtitle: Text(task['description']),
                      trailing: ElevatedButton(
                        onPressed: () {
                          if (task['status'] == 'participate') {
                            _participateInTask(task.id);
                          } else if (task['status'] == 'claim') {
                            _claimTaskPoints(task.id, task['points']);
                          }
                        },
                        child: Text(task['status'] == 'participate' ? 'Participate' : task['status'] == 'claim' ? 'Claim Points' : 'Claimed'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _watchAd,
            child: Text('Watch Ad (Earn 150 Points)'),
          ),
          ElevatedButton(
            onPressed: _inviteFriend,
            child: Text('Invite Friend (Earn Points)'),
          ),
          ElevatedButton(
            onPressed: () => _buyCherag(50, [60, 100, 150]),
            child: Text('Buy One Cherag (50 Points)'),
          ),
          ElevatedButton(
            onPressed: () => _buyCherag(90, [110, 180, 250]),
            child: Text('Buy Double Cherag (90 Points)'),
          ),
          ElevatedButton(
            onPressed: () => _buyCherag(120, [140, 250, 350]),
            child: Text('Buy Three Cherag (120 Points)'),
          ),
        ],
      ),
    );
  }
}
