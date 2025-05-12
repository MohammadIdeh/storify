import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get notifications => _firestore.collection('notifications');

  // Save FCM token to user document
  Future<void> saveToken(String token) async {
    String userId = _auth.currentUser?.uid ?? 'anonymous';

    await users.doc(userId).set({
      'fcmToken': token,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get all notifications for current user
  Stream<QuerySnapshot> getUserNotifications() {
    String userId = _auth.currentUser?.uid ?? 'anonymous';
    print('Current user ID: $userId');
    
    // First try to get all notifications to see if there are any
    return notifications
        // .where('userId', isEqualTo: userId) // Temporarily comment this out to see all notifications
        .snapshots();
  }

  // Add a new notification
  Future<void> addNotification({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    String userId = _auth.currentUser?.uid ?? 'anonymous';

    await notifications.add({
      'userId': userId,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await notifications.doc(notificationId).update({'read': true});
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await notifications.doc(notificationId).delete();
  }

  // Sign in anonymously if not already signed in
  Future<void> signInAnonymously() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }
}