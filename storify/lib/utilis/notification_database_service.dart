import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:storify/utilis/notificationModel.dart';

class NotificationDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  CollectionReference get notificationsCollection => _firestore.collection('notifications');
  
  // Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? 'anonymous';
  
  // Save notification to Firestore
  Future<void> saveNotification(NotificationItem notification) async {
    try {
      print('Saving notification to Firestore: ${notification.title}');
      
      await notificationsCollection.add({
        'id': notification.id,
        'title': notification.title,
        'message': notification.message,
        'isRead': notification.isRead,
        'userId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        'supplierId': notification.supplierId,
        'supplierName': notification.supplierName,
      });
      
      print('Successfully saved notification to Firestore');
    } catch (e) {
      print('Error saving notification to Firestore: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }
  
  // Get notifications from Firestore
  Stream<List<NotificationItem>> getNotificationsStream() {
    return notificationsCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Calculate time ago
            String timeAgo = 'Just now';
            if (data['createdAt'] != null) {
              final createdAt = DateTime.parse(data['createdAt']);
              timeAgo = _getTimeAgo(createdAt);
            }
            
            return NotificationItem(
              id: data['id'] ?? doc.id,
              title: data['title'] ?? 'Notification',
              message: data['message'] ?? '',
              timeAgo: timeAgo,
              isRead: data['isRead'] ?? false,
            );
          }).toList();
        });
  }
  
  // Get all notifications from Firestore
  Future<List<NotificationItem>> getAllNotifications() async {
    try {
      print('Fetching all notifications from Firestore for user: $currentUserId');
      
      final querySnapshot = await notificationsCollection
          .orderBy('timestamp', descending: true)
          .get();
          
      print('Firestore returned ${querySnapshot.docs.length} documents');
      
      final notifications = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        print('Processing Firestore document: ${doc.id}');
        print('Document data: $data');
        
        // Calculate time ago
        String timeAgo = 'Just now';
        if (data['createdAt'] != null) {
          final createdAt = DateTime.parse(data['createdAt']);
          timeAgo = _getTimeAgo(createdAt);
        }
        
        return NotificationItem(
          id: data['id'] ?? doc.id,
          title: data['title'] ?? 'Notification',
          message: data['message'] ?? '',
          timeAgo: timeAgo,
          isRead: data['isRead'] ?? false,
        );
      }).toList();
      
      print('Processed ${notifications.length} notifications from Firestore');
      return notifications;
    } catch (e) {
      print('Error getting all notifications from Firestore: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }
  
  // Mark notification as read in Firestore
  Future<void> markAsRead(String notificationId) async {
    try {
      // Find the document with this notification ID
      final querySnapshot = await notificationsCollection
          .where('id', isEqualTo: notificationId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await notificationsCollection.doc(docId).update({
          'isRead': true,
        });
        print('Marked notification as read in Firestore: $notificationId');
      }
    } catch (e) {
      print('Error marking notification as read in Firestore: $e');
    }
  }
  
  // Mark all notifications as read in Firestore
  Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      
      final querySnapshot = await notificationsCollection
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      print('Marked all notifications as read in Firestore');
    } catch (e) {
      print('Error marking all notifications as read in Firestore: $e');
    }
  }
  
  // Delete notification from Firestore
  Future<void> deleteNotification(String notificationId) async {
    try {
      final querySnapshot = await notificationsCollection
          .where('id', isEqualTo: notificationId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await notificationsCollection.doc(docId).delete();
        print('Deleted notification from Firestore: $notificationId');
      }
    } catch (e) {
      print('Error deleting notification from Firestore: $e');
    }
  }
  
  // Helper to calculate time ago
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Get notifications for a specific supplier
  Stream<List<NotificationItem>> getSupplierNotificationsStream(int supplierId) {
    return notificationsCollection
        .where('supplierId', isEqualTo: supplierId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Calculate time ago
            String timeAgo = 'Just now';
            if (data['createdAt'] != null) {
              final createdAt = DateTime.parse(data['createdAt']);
              timeAgo = _getTimeAgo(createdAt);
            }
            
            return NotificationItem(
              id: data['id'] ?? doc.id,
              title: data['title'] ?? 'Notification',
              message: data['message'] ?? '',
              timeAgo: timeAgo,
              isRead: data['isRead'] ?? false,
              supplierId: data['supplierId'],
              supplierName: data['supplierName'],
            );
          }).toList();
        });
  }
}