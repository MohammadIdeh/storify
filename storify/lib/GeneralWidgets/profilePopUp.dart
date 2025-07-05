// lib/GeneralWidgets/profilePopUp.dart
// FIXED VERSION - Proper user data display and clean logout with localization
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:storify/GeneralWidgets/settingsWidget.dart';
import 'package:storify/Registration/Screens/loginScreen.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'package:storify/services/user_profile_service.dart';
import 'package:storify/l10n/generated/app_localizations.dart';
import 'package:storify/providers/LocalizationHelper.dart';

class Profilepopup extends StatefulWidget {
  final VoidCallback onCloseMenu;
  final Future<void> Function()? onLogout;

  const Profilepopup({
    super.key,
    required this.onCloseMenu,
    this.onLogout,
  });

  @override
  State<Profilepopup> createState() => _ProfilepopupState();
}

class _ProfilepopupState extends State<Profilepopup> {
  String? profilePictureUrl;
  String? userName;
  String? userRole;
  bool _isLoadingProfile = false;
  bool _isLoggingOut = false;
  bool _isDisposed = false;

  // Prevent multiple logout attempts
  static bool _logoutInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing ProfilePopup...');
    _isDisposed = true;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted && !_isLoggingOut && !_logoutInProgress) {
      try {
        setState(fn);
      } catch (e) {
        debugPrint('⚠️ setState failed safely: $e');
      }
    }
  }

  Future<void> _loadUserData() async {
    if (_isDisposed || _isLoggingOut || _logoutInProgress) return;

    _safeSetState(() {
      _isLoadingProfile = true;
    });

    try {
      final currentRole = await AuthService.getCurrentRole();
      if (currentRole == null || _isDisposed) return;

      final profileData =
          await UserProfileService.getRoleSpecificProfile(currentRole);

      if (profileData != null && !_isDisposed && mounted && !_isLoggingOut) {
        _safeSetState(() {
          profilePictureUrl = profileData['profilePicture'];
          userName = profileData['name'];
          userRole = currentRole;
          _isLoadingProfile = false;
        });
        debugPrint('✅ Profile data loaded: name=$userName, role=$userRole');
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (!_isDisposed && mounted && !_isLoggingOut) {
        _safeSetState(() {
          _isLoadingProfile = false;
          userName = 'Error loading';
          userRole = 'Unknown';
        });
      }
    }
  }

  void _logout() {
    if (_isDisposed || _isLoggingOut || _logoutInProgress) {
      debugPrint('🚪 Logout blocked - already in progress');
      return;
    }

    // Set flags immediately
    _logoutInProgress = true;
    _safeSetState(() {
      _isLoggingOut = true;
    });

    // Close popup immediately
    widget.onCloseMenu();

    // FIXED: Only use parent callback if available, don't do double cleanup
    if (widget.onLogout != null) {
      debugPrint('🔄 Delegating logout to parent...');
      _performParentLogout();
    } else {
      debugPrint('🚪 === STARTING PROFILE LOGOUT ===');
      _performOwnLogout();
    }
  }

  // Delegate to parent completely - no own cleanup
  Future<void> _performParentLogout() async {
    try {
      await widget.onLogout!();
      debugPrint('✅ Parent logout completed');
    } catch (e) {
      debugPrint('❌ Parent logout error: $e');
    } finally {
      Future.delayed(const Duration(seconds: 1), () {
        _logoutInProgress = false;
      });
    }
  }

  // Only for standalone usage (no parent callback)
  Future<void> _performOwnLogout() async {
    try {
      debugPrint('🧹 Clearing data...');
      await AuthService.logoutFromAllRoles();
      await UserProfileService.clearAllRoleData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ Data cleared');

      // Navigate directly
      if (mounted && context.mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _logoutInProgress = false;
      });
    }
  }

  void _openSettings() {
    if (_isDisposed || _isLoggingOut || _logoutInProgress) {
      debugPrint('⚠️ Cannot open settings - invalid state');
      return;
    }

    debugPrint('⚙️ Opening settings...');

    // Get root context BEFORE closing
    final BuildContext rootContext =
        Navigator.of(context, rootNavigator: true).context;

    // Close popup
    widget.onCloseMenu();

    // Show settings
    Future.delayed(const Duration(milliseconds: 100), () {
      if (rootContext.mounted) {
        showDialog<void>(
          context: rootContext,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return SettingsWidget(
              onClose: () {
                Navigator.of(dialogContext).pop();
              },
            );
          },
        ).then((_) {
          debugPrint('⚙️ Settings dialog closed');
        }).catchError((error) {
          debugPrint('❌ Settings error: $error');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations)!;
    final isRtl = LocalizationHelper.isRTL(context);

    // Return empty container if disposed or in bad state
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    // Show loading state if logging out
    if (_isLoggingOut) {
      return Container(
        width: 220.w,
        height: 290.h,
        padding: EdgeInsets.all(16.0.w),
        decoration: BoxDecoration(
          color: const Color(0xFF2D3C4E),
          borderRadius: BorderRadius.circular(16.0.w),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFF7B5CFA),
              ),
              SizedBox(height: 12.h),
              Text(
                l10n.loggingOut,
                style: LocalizationHelper.isArabic(context)
                    ? GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16.sp,
                      )
                    : GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal popup
    return Container(
      width: 220.w,
      height: 290.h,
      padding: EdgeInsets.all(16.0.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3C4E),
        borderRadius: BorderRadius.circular(16.0.w),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Image
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child:
                      profilePictureUrl != null && profilePictureUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: profilePictureUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFF7B5CFA).withOpacity(0.2),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF7B5CFA),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                return Image.asset(
                                  'assets/images/me.png',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/me.png',
                              fit: BoxFit.cover,
                            ),
                ),
              ),
              if (_isLoadingProfile)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF7B5CFA),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          Text(
            userName ?? l10n.loading,
            style: LocalizationHelper.isArabic(context)
                ? GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  )
                : GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
          ),
          Text(
            _formatRoleName(userRole, context) ?? l10n.loading,
            style: LocalizationHelper.isArabic(context)
                ? GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  )
                : GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
          ),
          SizedBox(height: 30.h),

          // Settings button
          Padding(
            padding: EdgeInsets.only(
                left: isRtl ? 0 : 40.0.w, right: isRtl ? 40.0.w : 0),
            child: InkWell(
              onTap:
                  (!_isLoggingOut && !_logoutInProgress) ? _openSettings : null,
              child: Opacity(
                opacity: (!_isLoggingOut && !_logoutInProgress) ? 1.0 : 0.5,
                child: Row(
                  children: [
                    SizedBox(width: 8.w),
                    SvgPicture.asset(
                      'assets/images/settings2.svg',
                      width: 24.w,
                      height: 24.h,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      l10n.settings,
                      style: LocalizationHelper.isArabic(context)
                          ? GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                            )
                          : GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w400,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // Logout button
          Padding(
            padding: EdgeInsets.only(
                left: isRtl ? 0 : 40.0.w, right: isRtl ? 40.0.w : 0),
            child: InkWell(
              onTap: (!_isLoggingOut && !_logoutInProgress) ? _logout : null,
              child: Row(
                children: [
                  SizedBox(width: 8.w),
                  SvgPicture.asset(
                    'assets/images/logout.svg',
                    width: 24.w,
                    height: 24.h,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    l10n.logout,
                    style: LocalizationHelper.isArabic(context)
                        ? GoogleFonts.cairo(
                            color: (!_isLoggingOut && !_logoutInProgress)
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                          )
                        : GoogleFonts.spaceGrotesk(
                            color: (!_isLoggingOut && !_logoutInProgress)
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatRoleName(String? role, BuildContext context) {
    if (role == null) return null;
    return LocalizationHelper.getRoleDisplayName(context, role);
  }
}
