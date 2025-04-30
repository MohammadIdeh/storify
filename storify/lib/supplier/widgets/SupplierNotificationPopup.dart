// lib/supplier/widgets/SupplierNotificationPopup.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storify/utilis/notificationModel.dart';
import 'package:storify/utilis/notification_service.dart';

class SupplierNotificationPopup extends StatefulWidget {
  final VoidCallback onCloseMenu;
  final List<NotificationItem> notifications;

  const SupplierNotificationPopup({
    Key? key,
    required this.onCloseMenu,
    required this.notifications,
  }) : super(key: key);

  @override
  State<SupplierNotificationPopup> createState() =>
      _SupplierNotificationPopupState();
}

class _SupplierNotificationPopupState extends State<SupplierNotificationPopup> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380.w,
      constraints: BoxConstraints(maxHeight: 500.h),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 50, 69),
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
                if (widget.notifications.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      // Mark all as read
                      await NotificationService().markAllAsRead();
                      // Refresh UI
                      setState(() {});
                    },
                    child: Text(
                      'Mark all as read',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14.sp,
                        color: const Color.fromARGB(255, 105, 65, 198),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(color: Colors.grey.withOpacity(0.2), height: 1),

          // Notification List
          widget.notifications.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Center(
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
                      ],
                    ),
                  ),
                )
              : Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: widget.notifications.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey.withOpacity(0.2),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(
                          widget.notifications[index]);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    IconData icon = notification.icon ?? Icons.notifications;
    Color iconBackgroundColor = notification.iconBackgroundColor ??
        const Color.fromARGB(255, 105, 65, 198);

    // Check notification type and set appropriate icon
    if (notification.title.contains('Order')) {
      icon = Icons.shopping_bag;
      if (notification.title.contains('created') ||
          notification.title.contains('new')) {
        iconBackgroundColor = const Color.fromARGB(255, 0, 196, 255); // cyan
      } else if (notification.title.contains('accepted') ||
          notification.message.contains('accepted')) {
        icon = Icons.check_circle;
        iconBackgroundColor = const Color.fromARGB(178, 0, 224, 116); // green
      } else if (notification.title.contains('declined') ||
          notification.message.contains('declined')) {
        icon = Icons.cancel;
        iconBackgroundColor = const Color.fromARGB(255, 229, 62, 62); // red
      }
    }

    return InkWell(
      onTap: () async {
        // Mark as read
        await NotificationService().markAsRead(notification.id);

        // Execute any specific action for the notification
        if (notification.onTap != null) {
          notification.onTap!();
        }

        // Refresh UI
        setState(() {});
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
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
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
