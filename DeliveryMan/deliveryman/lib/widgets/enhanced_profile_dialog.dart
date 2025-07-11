// lib/widgets/enhanced_profile_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/profile.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/LanguageService.dart';
import '../l10n/app_localizations.dart';

class EnhancedProfileDialog extends StatefulWidget {
  const EnhancedProfileDialog({Key? key}) : super(key: key);

  @override
  State<EnhancedProfileDialog> createState() => _EnhancedProfileDialogState();
}

class _EnhancedProfileDialogState extends State<EnhancedProfileDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeProfile() async {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    // Set token for profile service
    profileService.updateToken(authService.token);

    // Fetch profile data
    await profileService.fetchProfile();

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _updateProfilePicture() async {
    final profileService = Provider.of<ProfileService>(context, listen: false);

    final success = await profileService.updateProfilePicture();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.profilePictureUpdated,
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      } else if (profileService.lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              profileService.lastError!,
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16), // Wider margins
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 500, // Maximum width for tablets
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF304050),
              const Color(0xFF304050).withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF6941C6).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 15),
              spreadRadius: 5,
            ),
            BoxShadow(
              color: const Color(0xFF6941C6).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Consumer<ProfileService>(
          builder: (context, profileService, child) {
            if (!_isInitialized || profileService.isLoading) {
              return _buildLoadingState(localizations);
            }

            if (profileService.lastError != null) {
              return _buildErrorState(profileService.lastError!, localizations);
            }

            if (profileService.profile == null) {
              return _buildErrorState(
                  localizations.noProfileData, localizations);
            }

            return _buildProfileContent(profileService.profile!, localizations);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(AppLocalizations localizations) {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6941C6)),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.loadingProfile,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, AppLocalizations localizations) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.errorLoadingProfile,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: const Color(0xAAFFFFFF),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: Text(localizations.close),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _initializeProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6941C6),
                  ),
                  child: Text(localizations.retry),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
      DeliveryProfile profile, AppLocalizations localizations) {
    return Column(
      children: [
        // Header with close button
        _buildHeader(localizations),

        // Profile picture and basic info
        _buildProfileHeader(profile, localizations),

        // Tab bar
        _buildTabBar(localizations),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonalTab(profile, localizations),
              _buildLanguagesTab(localizations),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF6941C6),
            Color(0xFF7C66B9),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              localizations.deliveryProfile,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
      DeliveryProfile profile, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile picture with edit functionality
          GestureDetector(
            onTap: _updateProfilePicture,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6941C6),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6941C6).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: profile.user.profilePicture != null &&
                            profile.user.profilePicture!.isNotEmpty
                        ? Image.network(
                            profile.user.profilePicture!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(),
                          )
                        : _buildDefaultAvatar(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6941C6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Name and status
          Text(
            profile.user.name,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Status badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusBadge(
                profile.isAvailable
                    ? localizations.available
                    : localizations.unavailable,
                profile.isAvailable
                    ? const Color(0xFF4CAF50)
                    : Colors.redAccent,
                profile.isAvailable ? Icons.check_circle : Icons.pause_circle,
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(
                localizations.deliveryEmployee,
                const Color(0xFF6941C6),
                Icons.local_shipping,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF6941C6).withOpacity(0.1),
      child: const Icon(
        Icons.person,
        color: Color(0xFF6941C6),
        size: 60,
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6941C6).withOpacity(0.3),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF6941C6),
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xAAFFFFFF),
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(
            icon: const Icon(Icons.person_outline, size: 20),
            text: localizations.personalInfo,
          ),
          Tab(
            icon: const Icon(Icons.language, size: 20),
            text: localizations.languages,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalTab(
      DeliveryProfile profile, AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            localizations.contactInformation,
            Icons.contact_phone,
            [
              _buildInfoItem(localizations.email, profile.user.email,
                  Icons.email_outlined),
              _buildInfoItem(localizations.phone, profile.user.phoneNumber,
                  Icons.phone_outlined),
              _buildInfoItem(localizations.employeeId,
                  profile.userId.toString(), Icons.badge_outlined),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoSection(
            localizations.locationAndStatus,
            Icons.location_on,
            [
              _buildInfoItem(
                  localizations.currentLocation,
                  '${double.parse(profile.currentLatitude).toStringAsFixed(6)}, ${double.parse(profile.currentLongitude).toStringAsFixed(6)}',
                  Icons.my_location),
              _buildInfoItem(
                  localizations.availability,
                  profile.isAvailable
                      ? localizations.availableForDeliveries
                      : localizations.currentlyUnavailable,
                  profile.isAvailable
                      ? Icons.check_circle
                      : Icons.pause_circle),
              _buildInfoItem(
                  localizations.lastUpdate,
                  DateFormat('MMM dd, yyyy • hh:mm a')
                      .format(profile.lastLocationUpdate),
                  Icons.access_time),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoSection(
            localizations.accountInformation,
            Icons.account_circle,
            [
              _buildInfoItem(
                  localizations.joined,
                  DateFormat('MMM dd, yyyy').format(profile.createdAt),
                  Icons.calendar_today),
              _buildInfoItem(localizations.profileId, profile.id.toString(),
                  Icons.fingerprint),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesTab(AppLocalizations localizations) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final availableLanguages = languageService.getAvailableLanguages();
        final currentLanguage = languageService.currentLanguageCode;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language selection header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6941C6).withOpacity(0.1),
                      const Color(0xFF6941C6).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6941C6).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.language,
                          color: Color(0xFF6941C6),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          localizations.languageSettings,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizations.selectLanguageDescription,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        color: const Color(0xAAFFFFFF),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Language options
              Text(
                localizations.availableLanguages,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Language selection cards
              ...availableLanguages.map((language) {
                final isSelected = currentLanguage == language['code'];

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () async {
                      if (!isSelected) {
                        final success = await languageService
                            .changeLanguage(language['code']!);
                        if (success && mounted) {
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations.languageChanged,
                                style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white),
                              ),
                              backgroundColor: const Color(0xFF4CAF50),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6941C6).withOpacity(0.1)
                            : const Color(0xFF1D2939),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF6941C6)
                              : const Color(0xFF6941C6).withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Language flag or icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6941C6).withOpacity(0.1)
                                  : const Color(0xFF6941C6).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              language['code'] == 'ar' ? '🇸🇦' : '🇺🇸',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  language['name']!,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  language['nativeName']!,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    color: const Color(0xAAFFFFFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6941C6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              // Current language info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.currentLanguage,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: const Color(0xFF4CAF50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            languageService.getLanguageName(currentLanguage),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D2939),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6941C6).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6941C6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF6941C6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xAAFFFFFF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xAAFFFFFF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
