import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notification_service.dart';

class NotificationPopup extends StatefulWidget {
  final Function() onCloseMenu;
  final List<NotificationItem> notifications;

  const NotificationPopup({
    Key? key,
    required this.onCloseMenu,
    required this.notifications,
  }) : super(key: key);

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup> {
  late List<NotificationItem> _notifications;
  
  @override
  void initState() {
    super.initState();
    _notifications = widget.notifications;
    
    // Register for notification updates
    NotificationService().registerNotificationsListChangedCallback(_updateNotifications);
  }
  
  @override
  void dispose() {
    // Unregister when the widget is disposed
    NotificationService().unregisterNotificationsListChangedCallback(_updateNotifications);
    super.dispose();
  }
  
  void _updateNotifications(List<NotificationItem> notifications) {
    if (mounted) {
      setState(() {
        _notifications = notifications;
        print('NotificationPopup updated with ${_notifications.length} notifications');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380.w,
      constraints: BoxConstraints(maxHeight: 500.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 29, 41, 57),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (_notifications.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      NotificationService().markAllAsRead();
                      widget.onCloseMenu();
                    },
                    child: Text(
                      'Mark all as read',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),

          // Notification List
          _notifications.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48.sp,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No notifications yet',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16.sp,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Add a test button for debugging
                      ElevatedButton(
                        onPressed: () async {
                          await NotificationService().addManualNotification(
                            'Test Notification',
                            'This is a test notification added manually'
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 105, 65, 198),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        ),
                        child: Text(
                          'Add Test Notification',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      ElevatedButton(
                        onPressed: () async {
                          await NotificationService().testDatabaseConnection();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 46, 123, 231),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        ),
                        child: Text(
                          'Test Database',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey.withOpacity(0.2),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index]);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return InkWell(
      onTap: () {
        // Handle notification tap - navigate or perform action
        if (notification.onTap != null) {
          notification.onTap!();
        }
        
        // Mark as read when tapped
        NotificationService().markAsRead(notification.id);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        color: notification.isRead
            ? Colors.transparent
            : const Color.fromARGB(40, 105, 65, 198),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon or image
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: notification.iconBackgroundColor ??
                    const Color.fromARGB(255, 105, 65, 198),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.icon ?? Icons.notifications,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.message,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14.sp,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    notification.timeAgo,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.sp,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 10.w,
                height: 10.h,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 105, 65, 198),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}