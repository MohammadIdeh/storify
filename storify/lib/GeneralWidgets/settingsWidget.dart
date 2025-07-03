// lib/GeneralWidgets/settingsWidget.dart
// Fixed version with role-specific data handling and improved stability
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:storify/customer/widgets/mapPopUp.dart';
import 'package:storify/GeneralWidgets/snackBar.dart';
import 'package:storify/services/user_profile_service.dart';
import 'package:storify/Registration/Widgets/auth_service.dart';
import 'dart:typed_data';
import 'dart:html' as html;

class SettingsWidget extends StatefulWidget {
  final VoidCallback onClose;

  const SettingsWidget({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? userRole;
  bool _darkMode = true;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Arabic', 'Spanish', 'French'];

  // Profile form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Password form controllers
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Profile data
  String? _currentProfilePicture;
  String? _currentUserId;

  // Image upload states
  bool _isUploadingImage = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  // Form keys
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();

  // Loading states
  bool _isLoadingProfile = false;
  bool _isChangingPassword = false;
  bool _isSavingProfile = false;

  // Password visibility
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Disposal flag
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserRole();
    _loadProfileData();
  }

  @override
  void dispose() {
    print('🧹 Disposing SettingsWidget...');
    _isDisposed = true;
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Safe setState to prevent errors
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      try {
        setState(fn);
      } catch (e) {
        print('⚠️ setState failed in settings: $e');
      }
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final currentRole = await AuthService.getCurrentRole();
      if (!_isDisposed && mounted) {
        _safeSetState(() {
          userRole = currentRole;
        });
      }
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  Future<void> _loadProfileData() async {
    if (_isDisposed) return;

    _safeSetState(() {
      _isLoadingProfile = true;
    });

    try {
      final currentRole = await AuthService.getCurrentRole();
      if (currentRole == null || _isDisposed) return;

      print('📋 Loading profile data for role: $currentRole');

      // Try to get fresh data from API first
      final profileData =
          await UserProfileService.getRoleSpecificProfile(currentRole);

      if (profileData != null && !_isDisposed) {
        _updateFormControllers(profileData);
      } else {
        // Fallback to local data
        final localData = await UserProfileService.getLocalProfileData();
        _updateFormControllersFromLocal(localData);
      }
    } catch (e) {
      print('Error loading profile data: $e');
      if (!_isDisposed && mounted) {
        showCustomSnackBar(
            context, 'Failed to load profile data', 'assets/images/error.svg');
      }
    } finally {
      if (!_isDisposed) {
        _safeSetState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _updateFormControllers(Map<String, dynamic> profileData) {
    if (_isDisposed) return;

    _safeSetState(() {
      _nameController.text = profileData['name']?.toString() ?? '';
      _emailController.text = profileData['email']?.toString() ?? '';
      _phoneController.text = profileData['phoneNumber']?.toString() ?? '';
      userRole = profileData['roleName']?.toString();
      _currentProfilePicture = profileData['profilePicture']?.toString();
      _currentUserId = profileData['userId']?.toString();
    });

    print('✅ Form controllers updated for role: $userRole');
  }

  void _updateFormControllersFromLocal(Map<String, String> localData) {
    if (_isDisposed) return;

    _safeSetState(() {
      _nameController.text = localData['name'] ?? '';
      _emailController.text = localData['email'] ?? '';
      _phoneController.text = localData['phoneNumber'] ?? '';
      userRole = localData['currentRole'];
      _currentProfilePicture = localData['profilePicture'];
      _currentUserId = localData['userId'];
    });

    print('✅ Form controllers updated from local data for role: $userRole');
  }

  Future<void> _handlePasswordChange() async {
    if (_isDisposed || !_passwordFormKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      showCustomSnackBar(
          context, 'New passwords do not match', 'assets/images/error.svg');
      return;
    }

    _safeSetState(() {
      _isChangingPassword = true;
    });

    try {
      final result = await UserProfileService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!_isDisposed && mounted) {
        if (result['success']) {
          // Clear password fields
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();

          showCustomSnackBar(context, 'Password changed successfully',
              'assets/images/success.svg');
        } else {
          showCustomSnackBar(
              context,
              result['message'] ?? 'Failed to change password',
              'assets/images/error.svg');
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        showCustomSnackBar(
            context, 'Error changing password: $e', 'assets/images/error.svg');
      }
    } finally {
      if (!_isDisposed) {
        _safeSetState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  Future<void> _handleProfileSave() async {
    if (_isDisposed || !_profileFormKey.currentState!.validate()) {
      return;
    }

    _safeSetState(() {
      _isSavingProfile = true;
    });

    try {
      final result = await UserProfileService.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
      );

      if (!_isDisposed && mounted) {
        if (result['success']) {
          showCustomSnackBar(context, 'Profile updated successfully',
              'assets/images/success.svg');
          // Refresh the form data after successful update
          await _loadProfileData();
        } else {
          showCustomSnackBar(
              context,
              result['message'] ?? 'Failed to update profile',
              'assets/images/error.svg');
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        showCustomSnackBar(
            context, 'Error updating profile: $e', 'assets/images/error.svg');
      }
    } finally {
      if (!_isDisposed) {
        _safeSetState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  // Handle image file selection for Flutter Web
  Future<void> _handleImageSelection() async {
    if (_isDisposed) return;

    try {
      final html.FileUploadInputElement fileInput =
          html.FileUploadInputElement();
      fileInput.accept = 'image/*';
      fileInput.click();

      await fileInput.onChange.first;

      if (fileInput.files!.isNotEmpty) {
        final file = fileInput.files!.first;

        if (!UserProfileService.isValidImageFile(file.name)) {
          if (!_isDisposed && mounted) {
            showCustomSnackBar(
                context,
                'Please select a valid image file (JPG, PNG, GIF, WebP)',
                'assets/images/error.svg');
          }
          return;
        }

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        await reader.onLoad.first;

        final Uint8List bytes = Uint8List.fromList(reader.result as List<int>);

        if (!UserProfileService.isValidImageSize(bytes, maxSizeInMB: 5)) {
          if (!_isDisposed && mounted) {
            showCustomSnackBar(context, 'Image size must be less than 5MB',
                'assets/images/error.svg');
          }
          return;
        }

        if (!_isDisposed) {
          _safeSetState(() {
            _selectedImageBytes = bytes;
            _selectedImageName = file.name;
          });

          if (mounted) {
            showCustomSnackBar(
                context,
                'Image selected. Click "Upload Photo" to save',
                'assets/images/info.svg');
          }
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        showCustomSnackBar(
            context, 'Error selecting image: $e', 'assets/images/error.svg');
      }
    }
  }

  // Handle image upload with role-specific storage
  Future<void> _handleImageUpload() async {
    if (_isDisposed) return;

    if (_selectedImageBytes == null || _selectedImageName == null) {
      await _handleImageSelection();
      return;
    }

    _safeSetState(() {
      _isUploadingImage = true;
    });

    try {
      print('🖼️ Uploading image for role: $userRole');

      final result = await UserProfileService.uploadProfilePicture(
        _selectedImageBytes!,
        _selectedImageName!,
      );

      if (!_isDisposed && mounted) {
        if (result['success']) {
          _safeSetState(() {
            _selectedImageBytes = null;
            _selectedImageName = null;
          });

          showCustomSnackBar(context, 'Profile picture updated successfully',
              'assets/images/success.svg');

          // Refresh profile data to get the new image URL
          await _loadProfileData();
        } else {
          showCustomSnackBar(
              context,
              result['message'] ?? 'Failed to upload image',
              'assets/images/error.svg');
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        showCustomSnackBar(
            context, 'Error uploading image: $e', 'assets/images/error.svg');
      }
    } finally {
      if (!_isDisposed) {
        _safeSetState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // Handle image removal
  Future<void> _handleImageRemoval() async {
    if (_isDisposed) return;

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1D2939),
          title: Text(
            'Remove Profile Picture',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to remove your profile picture?',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.grey[400],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Remove',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && !_isDisposed) {
      _safeSetState(() {
        _isUploadingImage = true;
      });

      try {
        final result = await UserProfileService.removeProfilePicture();

        if (!_isDisposed && mounted) {
          if (result['success']) {
            _safeSetState(() {
              _selectedImageBytes = null;
              _selectedImageName = null;
            });

            showCustomSnackBar(context, 'Profile picture removed successfully',
                'assets/images/success.svg');

            await _loadProfileData();
          } else {
            showCustomSnackBar(
                context,
                result['message'] ?? 'Failed to remove image',
                'assets/images/error.svg');
          }
        }
      } catch (e) {
        if (!_isDisposed && mounted) {
          showCustomSnackBar(
              context, 'Error removing image: $e', 'assets/images/error.svg');
        }
      } finally {
        if (!_isDisposed) {
          _safeSetState(() {
            _isUploadingImage = false;
          });
        }
      }
    }
  }

  void _showLocationSelectionDialog() {
    if (_isDisposed) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocationSelectionPopup(
        onLocationSaved: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Return minimal widget if disposed
    if (_isDisposed) {
      return Container(
        width: 200,
        height: 200,
        color: const Color(0xFF1D2939),
        child: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF7B5CFA),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Container(
        width: 800.w,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1D2939),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with title and close button
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        "Settings${userRole != null ? ' ($userRole)' : ''}",
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoadingProfile) ...[
                        SizedBox(width: 12.w),
                        SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFF7B5CFA),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs for different settings categories
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[800]!,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF7B5CFA),
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 16.sp,
                ),
                tabs: [
                  Tab(
                    icon: Icon(Icons.person, size: 24.sp),
                    text: "Profile",
                  ),
                  Tab(
                    icon: Icon(Icons.palette, size: 24.sp),
                    text: "Appearance",
                  ),
                  Tab(
                    icon: Icon(Icons.notifications, size: 24.sp),
                    text: "Notifications",
                  ),
                  Tab(
                    icon: Icon(Icons.help_outline, size: 24.sp),
                    text: "About",
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Profile Settings
                  SingleChildScrollView(
                    child: _buildProfileSettings(),
                  ),

                  // Appearance Settings
                  SingleChildScrollView(
                    child: _buildAppearanceSettings(),
                  ),

                  // Notification Settings
                  SingleChildScrollView(
                    child: _buildNotificationSettings(),
                  ),

                  // About/Help
                  SingleChildScrollView(
                    child: _buildAboutSection(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Profile settings section with role-specific data
  Widget _buildProfileSettings() {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile info card
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: const Color(0xFF283548),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80.w, // Use same unit for both width and height
                        height: 80
                            .w, // Changed from 80.h to 80.w to ensure perfect square
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF7B5CFA),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          // Changed from ClipRRect to ClipOval for perfect circle
                          child: _selectedImageBytes != null
                              ? Image.memory(
                                  _selectedImageBytes!,
                                  width: 80.w, // Use same unit
                                  height: 80.w, // Use same unit
                                  fit: BoxFit.cover,
                                )
                              : _currentProfilePicture != null &&
                                      _currentProfilePicture!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: _currentProfilePicture!,
                                      width: 80.w, // Use same unit
                                      height: 80.w, // Use same unit
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 80.w,
                                        height: 80.w, // Use same unit
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF7B5CFA)
                                              .withOpacity(0.2),
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: const Color(0xFF7B5CFA),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) {
                                        print(
                                            'Error loading profile image: $error');
                                        return Container(
                                          width: 80.w,
                                          height: 80.w, // Use same unit
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF7B5CFA)
                                                .withOpacity(0.2),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.person,
                                              color: const Color(0xFF7B5CFA),
                                              size: 40.sp,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 80.w,
                                      height: 80.w, // Use same unit
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF7B5CFA)
                                            .withOpacity(0.2),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.person,
                                          color: const Color(0xFF7B5CFA),
                                          size: 40.sp,
                                        ),
                                      ),
                                    ),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Profile Picture",
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              _selectedImageBytes != null
                                  ? "New image selected: $_selectedImageName"
                                  : _nameController.text.isNotEmpty
                                      ? "Picture for ${_nameController.text} ($userRole)"
                                      : "Upload a new profile picture for $userRole",
                              style: GoogleFonts.spaceGrotesk(
                                color: _selectedImageBytes != null
                                    ? const Color(0xFF7B5CFA)
                                    : Colors.grey[400],
                                fontSize: 14.sp,
                                fontWeight: _selectedImageBytes != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _isUploadingImage
                                      ? null
                                      : () async {
                                          if (_selectedImageBytes != null) {
                                            await _handleImageUpload();
                                          } else {
                                            await _handleImageSelection();
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7B5CFA),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 12.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  child: _isUploadingImage
                                      ? SizedBox(
                                          width: 16.w,
                                          height: 16.h,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          _selectedImageBytes != null
                                              ? "Upload Photo"
                                              : "Select Photo",
                                          style: GoogleFonts.spaceGrotesk(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                                SizedBox(width: 12.w),
                                if (_selectedImageBytes != null) ...[
                                  TextButton(
                                    onPressed: _isUploadingImage
                                        ? null
                                        : () {
                                            _safeSetState(() {
                                              _selectedImageBytes = null;
                                              _selectedImageName = null;
                                            });
                                          },
                                    child: Text(
                                      "Cancel",
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ] else if (_currentProfilePicture != null &&
                                    _currentProfilePicture!.isNotEmpty) ...[
                                  TextButton(
                                    onPressed: _isUploadingImage
                                        ? null
                                        : _handleImageRemoval,
                                    child: Text(
                                      "Remove",
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.red[400],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Account information form
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Account Information",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _isLoadingProfile ? null : _loadProfileData,
                  icon: Icon(
                    Icons.refresh,
                    color: _isLoadingProfile
                        ? Colors.grey[600]
                        : const Color(0xFF7B5CFA),
                    size: 20.sp,
                  ),
                  tooltip: 'Refresh Profile Data',
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Form fields
            _buildSettingsTextField("Full Name", _nameController,
                validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              }
              return null;
            }),
            SizedBox(height: 16.h),
            _buildSettingsTextField("Email", _emailController,
                validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            }),
            SizedBox(height: 16.h),
            _buildSettingsTextField("Phone Number", _phoneController,
                keyboardType: TextInputType.number, validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              if (!RegExp(r'^[0-9\s\-\(\)]+$').hasMatch(value)) {
                return 'Phone number must contain only numbers';
              }
              return null;
            }),
            SizedBox(height: 16.h),

            // Readonly fields for user info
            Row(
              children: [
                Expanded(
                  child:
                      _buildReadOnlyField("User ID", _currentUserId ?? 'N/A'),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildReadOnlyField(
                      "Role", _formatRoleName(userRole) ?? 'N/A'),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // Password section
            Form(
              key: _passwordFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Change Password",
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _buildPasswordTextField(
                    "Current Password",
                    _currentPasswordController,
                    _showCurrentPassword,
                    (value) =>
                        _safeSetState(() => _showCurrentPassword = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Current password is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildPasswordTextField(
                    "New Password",
                    _newPasswordController,
                    _showNewPassword,
                    (value) => _safeSetState(() => _showNewPassword = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'New password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildPasswordTextField(
                    "Confirm New Password",
                    _confirmPasswordController,
                    _showConfirmPassword,
                    (value) =>
                        _safeSetState(() => _showConfirmPassword = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24.h),

                  // Change Password Button
                  Center(
                    child: ElevatedButton(
                      onPressed:
                          _isChangingPassword ? null : _handlePasswordChange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5CFA),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 40.w,
                          vertical: 16.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: _isChangingPassword
                          ? SizedBox(
                              width: 20.w,
                              height: 20.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Change Password",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Location section (only for customers)
            if (userRole == 'Customer') ...[
              Text(
                "Delivery Location",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF283548),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: const Color(0xFF7B5CFA),
                      size: 32.sp,
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Your Delivery Address",
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "Your current location is set for deliveries",
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.grey[400],
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    ElevatedButton(
                      onPressed: _showLocationSelectionDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B5CFA),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        "Change Location",
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],

            // Save Profile button
            Center(
              child: ElevatedButton(
                onPressed: _isSavingProfile ? null : _handleProfileSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5CFA),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 40.w,
                    vertical: 16.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _isSavingProfile
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        "Save Profile Changes",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods (same as before but with _safeSetState)
  Widget _buildSettingsTextField(String label, TextEditingController controller,
      {String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.grey[400],
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF283548),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[700]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[700]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: const Color(0xFF7B5CFA),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTextField(String label, TextEditingController controller,
      bool isVisible, Function(bool) onVisibilityChanged,
      {String? Function(String?)? validator}) {
    List<String> autofillHints = [];
    if (label.toLowerCase().contains('current')) {
      autofillHints = [AutofillHints.password];
    } else if (label.toLowerCase().contains('new') ||
        label.toLowerCase().contains('confirm')) {
      autofillHints = [AutofillHints.newPassword];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.grey[400],
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          validator: validator,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: autofillHints,
          textInputAction: label.toLowerCase().contains('confirm')
              ? TextInputAction.done
              : TextInputAction.next,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF283548),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[700]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.grey[700]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: const Color(0xFF7B5CFA),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey[400],
              ),
              onPressed: () => onVisibilityChanged(!isVisible),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.grey[400],
            fontSize: 14.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF283548).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.grey[700]!.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.grey[300],
              fontSize: 16.sp,
            ),
          ),
        ),
      ],
    );
  }

  String? _formatRoleName(String? role) {
    if (role == null) return null;

    switch (role) {
      case 'DeliveryEmployee':
        return 'Delivery Employee';
      case 'WareHouseEmployee':
        return 'Warehouse Employee';
      case 'Customer':
        return 'Customer';
      case 'Supplier':
        return 'Supplier';
      case 'Admin':
        return 'Admin';
      default:
        return role;
    }
  }

  Widget _buildAppearanceSettings() {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Theme",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              "Appearance settings coming soon...",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.grey[400],
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Notification Settings",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              "Notification settings coming soon...",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.grey[400],
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About Storify",
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              "About section coming soon...",
              style: GoogleFonts.spaceGrotesk(
                color: Colors.grey[400],
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
