import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Storify'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember for 30 days'**
  String get rememberMe;

  /// No description provided for @loginToAccount.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account'**
  String get loginToAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please enter your details.'**
  String get welcomeBack;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get enterPassword;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInGoogle;

  /// No description provided for @signInApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInApple;

  /// No description provided for @noWorries.
  ///
  /// In en, this message translates to:
  /// **'No worries, we\'ll send you reset Code.'**
  String get noWorries;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @checkEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get checkEmail;

  /// No description provided for @resetCodeSent.
  ///
  /// In en, this message translates to:
  /// **'We have sent a password reset code to'**
  String get resetCodeSent;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the Code?'**
  String get didntReceiveCode;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get setNewPassword;

  /// No description provided for @newPasswordDifferent.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different to previously used passwords.'**
  String get newPasswordDifferent;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your New Password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your New Password'**
  String get confirmNewPassword;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @passwordReset.
  ///
  /// In en, this message translates to:
  /// **'Password reset'**
  String get passwordReset;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been successfully reset. Click below to log in magically.'**
  String get passwordResetSuccess;

  /// No description provided for @returnToLogin.
  ///
  /// In en, this message translates to:
  /// **'Return to Login page'**
  String get returnToLogin;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @profilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile Picture'**
  String get profilePicture;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userId;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @saveProfileChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Profile Changes'**
  String get saveProfileChanges;

  /// No description provided for @deliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocation;

  /// No description provided for @yourDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Your Delivery Address'**
  String get yourDeliveryAddress;

  /// No description provided for @currentLocationSet.
  ///
  /// In en, this message translates to:
  /// **'Your current location is set for deliveries'**
  String get currentLocationSet;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change Location'**
  String get changeLocation;

  /// No description provided for @uploadPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadPhoto;

  /// No description provided for @selectPhoto.
  ///
  /// In en, this message translates to:
  /// **'Select Photo'**
  String get selectPhoto;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Remove Profile Picture'**
  String get removeProfilePicture;

  /// No description provided for @removeProfilePictureConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove your profile picture?'**
  String get removeProfilePictureConfirm;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @roleManagement.
  ///
  /// In en, this message translates to:
  /// **'Role Management'**
  String get roleManagement;

  /// No description provided for @tracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tracking;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @deliveryEmployee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Employee'**
  String get deliveryEmployee;

  /// No description provided for @warehouseEmployee.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Employee'**
  String get warehouseEmployee;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Phone number must contain only numbers'**
  String get phoneInvalid;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get newPasswordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @selectValidImage.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid image file (JPG, PNG, GIF, WebP)'**
  String get selectValidImage;

  /// No description provided for @imageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image size must be less than 5MB'**
  String get imageTooLarge;

  /// No description provided for @imageSelected.
  ///
  /// In en, this message translates to:
  /// **'Image selected. Click \"Upload Photo\" to save'**
  String get imageSelected;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccess;

  /// No description provided for @profilePictureUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully'**
  String get profilePictureUpdatedSuccess;

  /// No description provided for @profilePictureRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile picture removed successfully'**
  String get profilePictureRemovedSuccess;

  /// No description provided for @languageChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChangedSuccess;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @choosePreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get choosePreferredLanguage;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'This will change the language for your current role'**
  String get languageDescription;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @aboutStorify.
  ///
  /// In en, this message translates to:
  /// **'About Storify'**
  String get aboutStorify;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon...'**
  String get comingSoon;

  /// No description provided for @appearanceSettings.
  ///
  /// In en, this message translates to:
  /// **'Appearance settings coming soon...'**
  String get appearanceSettings;

  /// No description provided for @notificationSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Notification settings coming soon...'**
  String get notificationSettingsDesc;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About section coming soon...'**
  String get aboutSection;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @orderCount.
  ///
  /// In en, this message translates to:
  /// **'Order Count'**
  String get orderCount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @ordersByCustomers.
  ///
  /// In en, this message translates to:
  /// **'Orders By Customers'**
  String get ordersByCustomers;

  /// No description provided for @ordersOverview.
  ///
  /// In en, this message translates to:
  /// **'Orders Overview'**
  String get ordersOverview;

  /// No description provided for @selectDates.
  ///
  /// In en, this message translates to:
  /// **'Select Dates'**
  String get selectDates;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRange;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @errorLoadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Error loading products'**
  String get errorLoadingProducts;

  /// No description provided for @productId.
  ///
  /// In en, this message translates to:
  /// **'Product ID'**
  String get productId;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @vendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// No description provided for @totalSold.
  ///
  /// In en, this message translates to:
  /// **'Total Sold'**
  String get totalSold;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'total items'**
  String get totalItems;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @errorLoadingOrderCounts.
  ///
  /// In en, this message translates to:
  /// **'Error loading order counts'**
  String get errorLoadingOrderCounts;

  /// No description provided for @errorLoadingOrdersChart.
  ///
  /// In en, this message translates to:
  /// **'Error loading orders chart'**
  String get errorLoadingOrdersChart;

  /// No description provided for @errorLoadingProfitData.
  ///
  /// In en, this message translates to:
  /// **'Error loading profit data'**
  String get errorLoadingProfitData;

  /// No description provided for @loadingOrdersChart.
  ///
  /// In en, this message translates to:
  /// **'Loading orders chart...'**
  String get loadingOrdersChart;

  /// No description provided for @loadingProfitData.
  ///
  /// In en, this message translates to:
  /// **'Loading profit data...'**
  String get loadingProfitData;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @noOrderCountDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No order count data available'**
  String get noOrderCountDataAvailable;

  /// No description provided for @noProfitDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No profit data available'**
  String get noProfitDataAvailable;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @offf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get offf;

  /// No description provided for @quickSelect.
  ///
  /// In en, this message translates to:
  /// **'Quick Select'**
  String get quickSelect;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get lastMonth;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @selectStart.
  ///
  /// In en, this message translates to:
  /// **'Select start'**
  String get selectStart;

  /// No description provided for @selectEnd.
  ///
  /// In en, this message translates to:
  /// **'Select end'**
  String get selectEnd;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Top products'**
  String get topProducts;

  /// No description provided for @totalPaidOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Paid Orders'**
  String get totalPaidOrders;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get totalCustomers;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @addTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Add Test Notification'**
  String get addTestNotification;

  /// No description provided for @testDatabase.
  ///
  /// In en, this message translates to:
  /// **'Test Database'**
  String get testDatabase;

  /// No description provided for @testNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Notification'**
  String get testNotificationTitle;

  /// No description provided for @testNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'This is a test notification added manually'**
  String get testNotificationMessage;

  /// No description provided for @tapToViewLowStockItems.
  ///
  /// In en, this message translates to:
  /// **'• Tap to view low stock items'**
  String get tapToViewLowStockItems;

  /// No description provided for @pleaseNavigateToOrdersScreen.
  ///
  /// In en, this message translates to:
  /// **'Please navigate to the Orders screen to view low stock items'**
  String get pleaseNavigateToOrdersScreen;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @productOverview.
  ///
  /// In en, this message translates to:
  /// **'Product Overview'**
  String get productOverview;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @suppliersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} suppliers'**
  String suppliersCount(Object count);

  /// No description provided for @noSuppliersAssigned.
  ///
  /// In en, this message translates to:
  /// **'No suppliers assigned to this product'**
  String get noSuppliersAssigned;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get noPhone;

  /// No description provided for @unknownId.
  ///
  /// In en, this message translates to:
  /// **'Unknown ID'**
  String get unknownId;

  /// No description provided for @supplierId.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String supplierId(Object id);

  /// No description provided for @sellingHistory.
  ///
  /// In en, this message translates to:
  /// **'Selling History'**
  String get sellingHistory;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @activeProducts.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeProducts;

  /// No description provided for @inactiveProducts.
  ///
  /// In en, this message translates to:
  /// **'Not Active'**
  String get inactiveProducts;

  /// No description provided for @totalCategories.
  ///
  /// In en, this message translates to:
  /// **'Total Categories'**
  String get totalCategories;

  /// No description provided for @failedToLoadDashboardStats.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard stats: {error}'**
  String failedToLoadDashboardStats(Object error);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @accepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @requestedProducts.
  ///
  /// In en, this message translates to:
  /// **'Requested Products'**
  String get requestedProducts;

  /// No description provided for @productList.
  ///
  /// In en, this message translates to:
  /// **'Product List'**
  String get productList;

  /// No description provided for @mustBeLoggedInToAddProducts.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to add products'**
  String get mustBeLoggedInToAddProducts;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @bulkExport.
  ///
  /// In en, this message translates to:
  /// **'Bulk Export'**
  String get bulkExport;

  /// No description provided for @notAuthorizedToAccessFeature.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to access this feature.'**
  String get notAuthorizedToAccessFeature;

  /// No description provided for @failedToLoadSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load suppliers: {error}'**
  String failedToLoadSuppliers(String error);

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get networkError;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @pleaseSelectAtLeastOneSupplier.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one supplier'**
  String get pleaseSelectAtLeastOneSupplier;

  /// No description provided for @authenticationTokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication token is required'**
  String get authenticationTokenRequired;

  /// No description provided for @productAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully'**
  String get productAddedSuccessfully;

  /// No description provided for @failedToAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to add product: {statusCode}'**
  String failedToAddProduct(Object statusCode);

  /// No description provided for @selectedSuppliersNotFound.
  ///
  /// In en, this message translates to:
  /// **'Selected suppliers not found. Please refresh and try again.'**
  String get selectedSuppliersNotFound;

  /// No description provided for @refreshSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Refresh Suppliers'**
  String get refreshSuppliers;

  /// No description provided for @notAuthorizedToAddProducts.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to add products'**
  String get notAuthorizedToAddProducts;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get costPrice;

  /// No description provided for @sellPrice.
  ///
  /// In en, this message translates to:
  /// **'Sell Price'**
  String get sellPrice;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @unitHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., kg, pieces, liters'**
  String get unitHint;

  /// No description provided for @lowStockThreshold.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Threshold'**
  String get lowStockThreshold;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @notActive.
  ///
  /// In en, this message translates to:
  /// **'Not Active'**
  String get notActive;

  /// No description provided for @barcodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Barcode (Optional)'**
  String get barcodeOptional;

  /// No description provided for @productionDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Production Date (Optional)'**
  String get productionDateOptional;

  /// No description provided for @expiryDateOptional.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date (Optional)'**
  String get expiryDateOptional;

  /// No description provided for @suppliersRequired.
  ///
  /// In en, this message translates to:
  /// **'Suppliers (Required)'**
  String get suppliersRequired;

  /// No description provided for @selectSuppliersForProduct.
  ///
  /// In en, this message translates to:
  /// **'Select suppliers for this product:'**
  String get selectSuppliersForProduct;

  /// No description provided for @noSuppliersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No suppliers available'**
  String get noSuppliersAvailable;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get idLabel;

  /// No description provided for @selectedSuppliersCount.
  ///
  /// In en, this message translates to:
  /// **'Selected suppliers ({count}):'**
  String selectedSuppliersCount(Object count);

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @enterProductDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter product description'**
  String get enterProductDescription;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @pleaseEnterProductName.
  ///
  /// In en, this message translates to:
  /// **'Please enter product name'**
  String get pleaseEnterProductName;

  /// No description provided for @pleaseEnterCostPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter cost price'**
  String get pleaseEnterCostPrice;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @pleaseEnterSellPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter sell price'**
  String get pleaseEnterSellPrice;

  /// No description provided for @pleaseEnterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter quantity'**
  String get pleaseEnterQuantity;

  /// No description provided for @pleaseEnterUnit.
  ///
  /// In en, this message translates to:
  /// **'Please enter unit'**
  String get pleaseEnterUnit;

  /// No description provided for @pleaseEnterLowStockThreshold.
  ///
  /// In en, this message translates to:
  /// **'Please enter low stock threshold'**
  String get pleaseEnterLowStockThreshold;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @noItemsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No items available'**
  String get noItemsAvailable;

  /// No description provided for @selectItem.
  ///
  /// In en, this message translates to:
  /// **'Select {item}'**
  String selectItem(Object item);

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @pleaseChooseAtLeastOneFilterCriterion.
  ///
  /// In en, this message translates to:
  /// **'Please choose at least one filter criterion to export.'**
  String get pleaseChooseAtLeastOneFilterCriterion;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @enterExcelFileName.
  ///
  /// In en, this message translates to:
  /// **'Enter Excel File Name'**
  String get enterExcelFileName;

  /// No description provided for @fileNameWithoutExtension.
  ///
  /// In en, this message translates to:
  /// **'File name (without extension)'**
  String get fileNameWithoutExtension;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @dataInfo.
  ///
  /// In en, this message translates to:
  /// **'Data Info'**
  String get dataInfo;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @priceFrom.
  ///
  /// In en, this message translates to:
  /// **'Price From'**
  String get priceFrom;

  /// No description provided for @priceTo.
  ///
  /// In en, this message translates to:
  /// **'Price To'**
  String get priceTo;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @productInformation.
  ///
  /// In en, this message translates to:
  /// **'Product Information'**
  String get productInformation;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @enterProductName.
  ///
  /// In en, this message translates to:
  /// **'Enter product name'**
  String get enterProductName;

  /// No description provided for @enterCostPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter cost price'**
  String get enterCostPrice;

  /// No description provided for @enterSellPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter sell price'**
  String get enterSellPrice;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @enterThreshold.
  ///
  /// In en, this message translates to:
  /// **'Enter threshold'**
  String get enterThreshold;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @productionDate.
  ///
  /// In en, this message translates to:
  /// **'Production Date:'**
  String get productionDate;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date:'**
  String get expiryDate;

  /// No description provided for @dropOrImport.
  ///
  /// In en, this message translates to:
  /// **'Drop or Import'**
  String get dropOrImport;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @notLoggedInAdminOnlyEdit.
  ///
  /// In en, this message translates to:
  /// **'Not logged in. Only admin users can edit products.'**
  String get notLoggedInAdminOnlyEdit;

  /// No description provided for @productUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully'**
  String get productUpdatedSuccessfully;

  /// No description provided for @productUpdatedSuccessfullyWithoutImageChanges.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully (without image changes)'**
  String get productUpdatedSuccessfullyWithoutImageChanges;

  /// No description provided for @authenticationFailedPleaseLoginAsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please log in as admin.'**
  String get authenticationFailedPleaseLoginAsAdmin;

  /// No description provided for @failedToUpdateProductWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to update product: {statusCode}\n{body}'**
  String failedToUpdateProductWithDetails(Object body, Object statusCode);

  /// No description provided for @failedToUpdateProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to update product.'**
  String get failedToUpdateProduct;

  /// No description provided for @productSales.
  ///
  /// In en, this message translates to:
  /// **'Product Sales'**
  String get productSales;

  /// No description provided for @loadingSalesData.
  ///
  /// In en, this message translates to:
  /// **'Loading sales data...'**
  String get loadingSalesData;

  /// No description provided for @errorLoadingSalesData.
  ///
  /// In en, this message translates to:
  /// **'Error loading sales data'**
  String get errorLoadingSalesData;

  /// No description provided for @noSalesDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No sales data available'**
  String get noSalesDataAvailable;

  /// No description provided for @unitsSold.
  ///
  /// In en, this message translates to:
  /// **'{count} units sold'**
  String unitsSold(Object count);

  /// No description provided for @unitsTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count} units'**
  String unitsTooltip(Object count);

  /// No description provided for @failedToLoadSalesData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load sales data'**
  String get failedToLoadSalesData;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'barcode'**
  String get barcode;

  /// No description provided for @invalidDataFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid data format'**
  String get invalidDataFormat;

  /// No description provided for @failedToLoadProductsWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products. Error: {statusCode}'**
  String failedToLoadProductsWithError(Object statusCode);

  /// No description provided for @networkErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Network error occurred'**
  String get networkErrorOccurred;

  /// No description provided for @imageAndName.
  ///
  /// In en, this message translates to:
  /// **'Image & Name'**
  String get imageAndName;

  /// No description provided for @qtyShort.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qtyShort;

  /// No description provided for @totalItemsCount.
  ///
  /// In en, this message translates to:
  /// **'Total {count} items'**
  String totalItemsCount(Object count);

  /// No description provided for @totalProductsCard.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProductsCard;

  /// No description provided for @activeProductsCard.
  ///
  /// In en, this message translates to:
  /// **'Active Products'**
  String get activeProductsCard;

  /// No description provided for @inactiveProductsCard.
  ///
  /// In en, this message translates to:
  /// **'Inactive Products'**
  String get inactiveProductsCard;

  /// No description provided for @totalCategoriesCard.
  ///
  /// In en, this message translates to:
  /// **'Total Categories'**
  String get totalCategoriesCard;

  /// No description provided for @lowStockProductsCard.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Products'**
  String get lowStockProductsCard;

  /// No description provided for @outOfStockProductsCard.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock Products'**
  String get outOfStockProductsCard;

  /// No description provided for @productRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Request Details'**
  String get productRequestDetails;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @supplierInformation.
  ///
  /// In en, this message translates to:
  /// **'Supplier Information'**
  String get supplierInformation;

  /// No description provided for @loadingSellingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading selling history...'**
  String get loadingSellingHistory;

  /// No description provided for @errorLoadingSellingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading selling history'**
  String get errorLoadingSellingHistory;

  /// No description provided for @noSellingHistoryAvailable.
  ///
  /// In en, this message translates to:
  /// **'No selling history available for this product'**
  String get noSellingHistoryAvailable;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @orderPrice.
  ///
  /// In en, this message translates to:
  /// **'Order Price'**
  String get orderPrice;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDate;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @onTheWay.
  ///
  /// In en, this message translates to:
  /// **'On The Way'**
  String get onTheWay;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @errorLoadingRequestedProducts.
  ///
  /// In en, this message translates to:
  /// **'Error loading requested products'**
  String get errorLoadingRequestedProducts;

  /// No description provided for @accountBalance.
  ///
  /// In en, this message translates to:
  /// **'Account Balance'**
  String get accountBalance;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @requestDate.
  ///
  /// In en, this message translates to:
  /// **'Request Date'**
  String get requestDate;

  /// No description provided for @warranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get warranty;

  /// No description provided for @adminNote.
  ///
  /// In en, this message translates to:
  /// **'Admin Note'**
  String get adminNote;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @adminNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Admin Note (Optional)'**
  String get adminNoteOptional;

  /// No description provided for @addNoteToSupplier.
  ///
  /// In en, this message translates to:
  /// **'Add a note to the supplier...'**
  String get addNoteToSupplier;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @productRequestHasBeen.
  ///
  /// In en, this message translates to:
  /// **'Product request has been'**
  String get productRequestHasBeen;

  /// No description provided for @failedToProcessRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to process request'**
  String get failedToProcessRequest;

  /// No description provided for @adminNoteColon.
  ///
  /// In en, this message translates to:
  /// **'Admin Note:'**
  String get adminNoteColon;

  /// No description provided for @dateRequested.
  ///
  /// In en, this message translates to:
  /// **'Date Requested'**
  String get dateRequested;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @failedToLoadCategories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get failedToLoadCategories;

  /// No description provided for @errorFetchingCategories.
  ///
  /// In en, this message translates to:
  /// **'Error fetching categories'**
  String get errorFetchingCategories;

  /// No description provided for @invalidResponseFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid response format'**
  String get invalidResponseFormat;

  /// No description provided for @failedToLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products: {error}'**
  String failedToLoadProducts(String error);

  /// No description provided for @errorFetchingProducts.
  ///
  /// In en, this message translates to:
  /// **'Error fetching products'**
  String get errorFetchingProducts;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get loadingProducts;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required. Please log in again.'**
  String get authenticationRequired;

  /// No description provided for @failedToUpdateCategoryStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update category status'**
  String get failedToUpdateCategoryStatus;

  /// No description provided for @imageSizeExceedsLimit.
  ///
  /// In en, this message translates to:
  /// **'Image size exceeds 5MB limit. Please choose a smaller image.'**
  String get imageSizeExceedsLimit;

  /// No description provided for @errorProcessingImage.
  ///
  /// In en, this message translates to:
  /// **'Error processing image'**
  String get errorProcessingImage;

  /// No description provided for @requestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Request timed out'**
  String get requestTimedOut;

  /// No description provided for @failedToAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to add category'**
  String get failedToAddCategory;

  /// No description provided for @networkIssueRetrying.
  ///
  /// In en, this message translates to:
  /// **'Network issue. Retrying...'**
  String get networkIssueRetrying;

  /// No description provided for @attempt.
  ///
  /// In en, this message translates to:
  /// **'Attempt'**
  String get attempt;

  /// No description provided for @checkInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again.'**
  String get checkInternetConnection;

  /// No description provided for @clickToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Click to upload an image'**
  String get clickToUploadImage;

  /// No description provided for @retrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying...'**
  String get retrying;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @enterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Enter category name...'**
  String get enterCategoryName;

  /// No description provided for @categoryNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Category name is required'**
  String get categoryNameRequired;

  /// No description provided for @enterDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter Description (Optional)'**
  String get enterDescriptionOptional;

  /// No description provided for @pleaseUploadImage.
  ///
  /// In en, this message translates to:
  /// **'* Please upload an image for the category'**
  String get pleaseUploadImage;

  /// No description provided for @publishCategory.
  ///
  /// In en, this message translates to:
  /// **'Publish Category'**
  String get publishCategory;

  /// No description provided for @categoryNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty'**
  String get categoryNameCannotBeEmpty;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get failedToUpdate;

  /// No description provided for @failedToUpdateCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to update category'**
  String get failedToUpdateCategory;

  /// No description provided for @errorUpdatingCategory.
  ///
  /// In en, this message translates to:
  /// **'Error updating category'**
  String get errorUpdatingCategory;

  /// No description provided for @noProductsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No products in this category'**
  String get noProductsInCategory;

  /// No description provided for @productsAddedWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Products added to this category will appear here'**
  String get productsAddedWillAppearHere;

  /// No description provided for @productNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Product name cannot be empty'**
  String get productNameCannotBeEmpty;

  /// No description provided for @costPriceMustBeValid.
  ///
  /// In en, this message translates to:
  /// **'Cost price must be a valid number'**
  String get costPriceMustBeValid;

  /// No description provided for @sellingPriceMustBeValid.
  ///
  /// In en, this message translates to:
  /// **'Selling price must be a valid number'**
  String get sellingPriceMustBeValid;

  /// No description provided for @cannotUpdateProductWithoutId.
  ///
  /// In en, this message translates to:
  /// **'Cannot update product without ID'**
  String get cannotUpdateProductWithoutId;

  /// No description provided for @sessionExpiredLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpiredLoginAgain;

  /// No description provided for @errorUpdatingProduct.
  ///
  /// In en, this message translates to:
  /// **'Error updating product'**
  String get errorUpdatingProduct;

  /// No description provided for @cannotDeleteProductWithoutId.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete product without ID'**
  String get cannotDeleteProductWithoutId;

  /// No description provided for @failedToDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete product'**
  String get failedToDeleteProduct;

  /// No description provided for @errorDeletingProduct.
  ///
  /// In en, this message translates to:
  /// **'Error deleting product'**
  String get errorDeletingProduct;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @areYouSureDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this product?'**
  String get areYouSureDeleteProduct;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletingProduct.
  ///
  /// In en, this message translates to:
  /// **'Deleting product...'**
  String get deletingProduct;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPrice;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @supplierOrders.
  ///
  /// In en, this message translates to:
  /// **'Supplier Orders'**
  String get supplierOrders;

  /// No description provided for @customerOrders.
  ///
  /// In en, this message translates to:
  /// **'Customer Orders'**
  String get customerOrders;

  /// No description provided for @orderFromSupplier.
  ///
  /// In en, this message translates to:
  /// **'Order From Supplier'**
  String get orderFromSupplier;

  /// No description provided for @customerHistory.
  ///
  /// In en, this message translates to:
  /// **'Customer History'**
  String get customerHistory;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalOrders;

  /// No description provided for @activeOrders.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeOrders;

  /// No description provided for @completedOrders.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedOrders;

  /// No description provided for @cancelledOrders.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledOrders;

  /// No description provided for @allStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get statusAssigned;

  /// No description provided for @statusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get statusPreparing;

  /// No description provided for @statusPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get statusPrepared;

  /// No description provided for @statusOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On The Way'**
  String get statusOnTheWay;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get statusShipped;

  /// No description provided for @statusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @statusDeclinedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Declined by Admin'**
  String get statusDeclinedByAdmin;

  /// No description provided for @statusPartiallyAccepted.
  ///
  /// In en, this message translates to:
  /// **'Partially Accepted'**
  String get statusPartiallyAccepted;

  /// No description provided for @allOrders.
  ///
  /// In en, this message translates to:
  /// **'All Orders'**
  String get allOrders;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @searchId.
  ///
  /// In en, this message translates to:
  /// **'Search ID'**
  String get searchId;

  /// No description provided for @checkingLowStockItems.
  ///
  /// In en, this message translates to:
  /// **'Checking for low stock items...'**
  String get checkingLowStockItems;

  /// No description provided for @noLowStockItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No low stock items found at this time'**
  String get noLowStockItemsFound;

  /// No description provided for @errorFetchingLowStock.
  ///
  /// In en, this message translates to:
  /// **'Error fetching low stock items'**
  String get errorFetchingLowStock;

  /// No description provided for @unexpectedCustomerOrdersFormat.
  ///
  /// In en, this message translates to:
  /// **'Unexpected customer orders response format'**
  String get unexpectedCustomerOrdersFormat;

  /// No description provided for @errorFetchingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error fetching orders'**
  String get errorFetchingOrders;

  /// No description provided for @criticalStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Critical Stock Alert!'**
  String get criticalStockAlert;

  /// No description provided for @lowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert'**
  String get lowStockAlert;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @printInvoice.
  ///
  /// In en, this message translates to:
  /// **'Print Invoice'**
  String get printInvoice;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get item;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantity;

  /// No description provided for @prodDate.
  ///
  /// In en, this message translates to:
  /// **'Prod Date'**
  String get prodDate;

  /// No description provided for @expDate.
  ///
  /// In en, this message translates to:
  /// **'Exp Date'**
  String get expDate;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @orderInfo.
  ///
  /// In en, this message translates to:
  /// **'Order Info'**
  String get orderInfo;

  /// No description provided for @deliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery Date'**
  String get deliveryDate;

  /// No description provided for @orderTime.
  ///
  /// In en, this message translates to:
  /// **'Order Time'**
  String get orderTime;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @systemOrder.
  ///
  /// In en, this message translates to:
  /// **'System Order'**
  String get systemOrder;

  /// No description provided for @orderActions.
  ///
  /// In en, this message translates to:
  /// **'Order Actions'**
  String get orderActions;

  /// No description provided for @addNoteForDeclining.
  ///
  /// In en, this message translates to:
  /// **'Add a note (required for declining)...'**
  String get addNoteForDeclining;

  /// No description provided for @addNoteForOrder.
  ///
  /// In en, this message translates to:
  /// **'Add a note for this order (optional)...'**
  String get addNoteForOrder;

  /// No description provided for @acceptEntireOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept Entire Order'**
  String get acceptEntireOrder;

  /// No description provided for @declineOrder.
  ///
  /// In en, this message translates to:
  /// **'Decline Order'**
  String get declineOrder;

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Accept Order'**
  String get acceptOrder;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @supplierInfo.
  ///
  /// In en, this message translates to:
  /// **'Supplier info'**
  String get supplierInfo;

  /// No description provided for @customerInfo.
  ///
  /// In en, this message translates to:
  /// **'Customer info'**
  String get customerInfo;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @errorFetchingOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Error fetching order details'**
  String get errorFetchingOrderDetails;

  /// No description provided for @failedToLoadOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load order details'**
  String get failedToLoadOrderDetails;

  /// No description provided for @statusCode.
  ///
  /// In en, this message translates to:
  /// **'Status code'**
  String get statusCode;

  /// No description provided for @failedToLoadCustomerOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load customer order details'**
  String get failedToLoadCustomerOrderDetails;

  /// No description provided for @errorFetchingCustomerOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Error fetching customer order details'**
  String get errorFetchingCustomerOrderDetails;

  /// No description provided for @orderDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order data not found in response'**
  String get orderDataNotFound;

  /// No description provided for @orderAcceptedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order accepted successfully'**
  String get orderAcceptedSuccessfully;

  /// No description provided for @failedToAcceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept order'**
  String get failedToAcceptOrder;

  /// No description provided for @errorAcceptingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error accepting order'**
  String get errorAcceptingOrder;

  /// No description provided for @provideReasonForDeclining.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for declining this order'**
  String get provideReasonForDeclining;

  /// No description provided for @orderDeclinedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order declined successfully'**
  String get orderDeclinedSuccessfully;

  /// No description provided for @failedToDeclineOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to decline order'**
  String get failedToDeclineOrder;

  /// No description provided for @errorDecliningOrder.
  ///
  /// In en, this message translates to:
  /// **'Error declining order'**
  String get errorDecliningOrder;

  /// No description provided for @provideReasonForRejecting.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejecting this order'**
  String get provideReasonForRejecting;

  /// No description provided for @orderRejectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order rejected successfully'**
  String get orderRejectedSuccessfully;

  /// No description provided for @failedToRejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject order'**
  String get failedToRejectOrder;

  /// No description provided for @errorRejectingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting order'**
  String get errorRejectingOrder;

  /// No description provided for @assignOrdersToDelivery.
  ///
  /// In en, this message translates to:
  /// **'Assign Orders to Delivery'**
  String get assignOrdersToDelivery;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @preparedOrders.
  ///
  /// In en, this message translates to:
  /// **'Prepared Orders'**
  String get preparedOrders;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @noPreparedOrdersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No prepared orders available'**
  String get noPreparedOrdersAvailable;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @assignmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Assignment Details'**
  String get assignmentDetails;

  /// No description provided for @selectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select Employee'**
  String get selectEmployee;

  /// No description provided for @estimatedTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time (minutes)'**
  String get estimatedTimeMinutes;

  /// No description provided for @enterMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter minutes'**
  String get enterMinutes;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional):'**
  String get notesOptional;

  /// No description provided for @addDeliveryNotes.
  ///
  /// In en, this message translates to:
  /// **'Add delivery notes...'**
  String get addDeliveryNotes;

  /// No description provided for @selectedOrders.
  ///
  /// In en, this message translates to:
  /// **'Selected Orders'**
  String get selectedOrders;

  /// No description provided for @ordersSelected.
  ///
  /// In en, this message translates to:
  /// **'orders selected'**
  String get ordersSelected;

  /// No description provided for @assignOrders.
  ///
  /// In en, this message translates to:
  /// **'Assign Orders'**
  String get assignOrders;

  /// No description provided for @assigning.
  ///
  /// In en, this message translates to:
  /// **'Assigning...'**
  String get assigning;

  /// No description provided for @selectAtLeastOneOrder.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one order to assign'**
  String get selectAtLeastOneOrder;

  /// No description provided for @selectDeliveryEmployee.
  ///
  /// In en, this message translates to:
  /// **'Please select a delivery employee'**
  String get selectDeliveryEmployee;

  /// No description provided for @enterValidEstimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid estimated time'**
  String get enterValidEstimatedTime;

  /// No description provided for @invalidOrderIds.
  ///
  /// In en, this message translates to:
  /// **'Invalid order IDs'**
  String get invalidOrderIds;

  /// No description provided for @errorAssigningOrders.
  ///
  /// In en, this message translates to:
  /// **'Error assigning orders'**
  String get errorAssigningOrders;

  /// No description provided for @assignmentResult.
  ///
  /// In en, this message translates to:
  /// **'Assignment Result'**
  String get assignmentResult;

  /// No description provided for @successfullyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Successfully assigned'**
  String get successfullyAssigned;

  /// No description provided for @failedToAssign.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign'**
  String get failedToAssign;

  /// No description provided for @customerOrdersHistory.
  ///
  /// In en, this message translates to:
  /// **'Customer Orders History'**
  String get customerOrdersHistory;

  /// No description provided for @viewDetailedCustomerInfo.
  ///
  /// In en, this message translates to:
  /// **'View detailed customer information and order history'**
  String get viewDetailedCustomerInfo;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get searchCustomers;

  /// No description provided for @avgOrders.
  ///
  /// In en, this message translates to:
  /// **'Avg Orders'**
  String get avgOrders;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @since.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get since;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @customerOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'\'s Order History'**
  String get customerOrderHistory;

  /// No description provided for @selectACustomer.
  ///
  /// In en, this message translates to:
  /// **'Select a customer'**
  String get selectACustomer;

  /// No description provided for @chooseCustomerFromList.
  ///
  /// In en, this message translates to:
  /// **'Choose a customer from the list to view their order history'**
  String get chooseCustomerFromList;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// No description provided for @customerHasntPlacedOrders.
  ///
  /// In en, this message translates to:
  /// **'This customer hasn\'t placed any orders yet'**
  String get customerHasntPlacedOrders;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @viewItems.
  ///
  /// In en, this message translates to:
  /// **'View Items'**
  String get viewItems;

  /// No description provided for @deliveryBy.
  ///
  /// In en, this message translates to:
  /// **'Delivery by'**
  String get deliveryBy;

  /// No description provided for @failedToLoadCustomers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load customers'**
  String get failedToLoadCustomers;

  /// No description provided for @failedToLoadCustomerHistory.
  ///
  /// In en, this message translates to:
  /// **'Failed to load customer history'**
  String get failedToLoadCustomerHistory;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @lowStockAlertAdvancedOrderGeneration.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert - Advanced Order Generation'**
  String get lowStockAlertAdvancedOrderGeneration;

  /// No description provided for @itemsNeedRestocking.
  ///
  /// In en, this message translates to:
  /// **'{count} items need restocking'**
  String itemsNeedRestocking(int count);

  /// No description provided for @useSameSupplierForAllItems.
  ///
  /// In en, this message translates to:
  /// **'Use same supplier for all items:'**
  String get useSameSupplierForAllItems;

  /// No description provided for @selectGlobalSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select Global Supplier'**
  String get selectGlobalSupplier;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @currentMin.
  ///
  /// In en, this message translates to:
  /// **'Current/Min'**
  String get currentMin;

  /// No description provided for @orderQty.
  ///
  /// In en, this message translates to:
  /// **'Order Qty'**
  String get orderQty;

  /// No description provided for @suppliersAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} suppliers available'**
  String suppliersAvailable(int count);

  /// No description provided for @need.
  ///
  /// In en, this message translates to:
  /// **'Need: {amount}'**
  String need(int amount);

  /// No description provided for @noSuppliers.
  ///
  /// In en, this message translates to:
  /// **'No suppliers'**
  String get noSuppliers;

  /// No description provided for @selectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select Supplier'**
  String get selectSupplier;

  /// No description provided for @errorLoadingSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Error loading suppliers'**
  String get errorLoadingSuppliers;

  /// No description provided for @selectAtLeastOneItem.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one item to generate orders'**
  String get selectAtLeastOneItem;

  /// No description provided for @errorGeneratingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error generating orders: {error}'**
  String errorGeneratingOrders(String error);

  /// No description provided for @itemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} items selected'**
  String itemsSelected(int selected, int total);

  /// No description provided for @globalSupplier.
  ///
  /// In en, this message translates to:
  /// **'Global supplier: {name}'**
  String globalSupplier(String name);

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @generateOrders.
  ///
  /// In en, this message translates to:
  /// **'Generate Orders'**
  String get generateOrders;

  /// No description provided for @pendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get pendingOrders;

  /// No description provided for @activeSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Active Suppliers'**
  String get activeSuppliers;

  /// No description provided for @lowStockItems.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Items'**
  String get lowStockItems;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get monthlyRevenue;

  /// No description provided for @noOrdersToDisplay.
  ///
  /// In en, this message translates to:
  /// **'There are no orders to display'**
  String get noOrdersToDisplay;

  /// No description provided for @noOrdersMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No orders match your filter'**
  String get noOrdersMatchFilter;

  /// No description provided for @adjustFilterCriteria.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filter criteria'**
  String get adjustFilterCriteria;

  /// No description provided for @noOrdersWithStatus.
  ///
  /// In en, this message translates to:
  /// **'No orders with status \"{status}\"'**
  String noOrdersWithStatus(String status);

  /// No description provided for @supplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get supplierName;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @totalOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'Total {count} Orders'**
  String totalOrdersCount(int count);

  /// No description provided for @orderStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get orderStatusAccepted;

  /// No description provided for @orderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderStatusPending;

  /// No description provided for @orderStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderStatusShipped;

  /// No description provided for @orderStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get orderStatusDeclined;

  /// No description provided for @orderStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get orderStatusRejected;

  /// No description provided for @orderStatusDeclinedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Declined by Admin'**
  String get orderStatusDeclinedByAdmin;

  /// No description provided for @orderStatusPartiallyAccepted.
  ///
  /// In en, this message translates to:
  /// **'Partially Accepted'**
  String get orderStatusPartiallyAccepted;

  /// No description provided for @orderStatusPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get orderStatusPrepared;

  /// No description provided for @orderStatusOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the Way'**
  String get orderStatusOnTheWay;

  /// No description provided for @orderStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get orderStatusAssigned;

  /// No description provided for @orderStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get orderStatusPreparing;

  /// No description provided for @placeOrderFromSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Place Order from Suppliers'**
  String get placeOrderFromSuppliers;

  /// No description provided for @pleaseChooseSupplier.
  ///
  /// In en, this message translates to:
  /// **'Please choose a supplier'**
  String get pleaseChooseSupplier;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @cartItemsCount.
  ///
  /// In en, this message translates to:
  /// **'({count} items)'**
  String cartItemsCount(int count);

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @addProductsToCart.
  ///
  /// In en, this message translates to:
  /// **'Add products from the list to place an order'**
  String get addProductsToCart;

  /// No description provided for @unknownSupplier.
  ///
  /// In en, this message translates to:
  /// **'Unknown Supplier'**
  String get unknownSupplier;

  /// No description provided for @confirmAllOrders.
  ///
  /// In en, this message translates to:
  /// **'Confirm All Orders'**
  String get confirmAllOrders;

  /// No description provided for @processingOrders.
  ///
  /// In en, this message translates to:
  /// **'Processing Orders...'**
  String get processingOrders;

  /// No description provided for @productsWithCount.
  ///
  /// In en, this message translates to:
  /// **'Products ({count})'**
  String productsWithCount(int count);

  /// No description provided for @noProductsToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No products to display'**
  String get noProductsToDisplay;

  /// No description provided for @selectSupplierFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a supplier first'**
  String get selectSupplierFirst;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get noProductsAvailable;

  /// No description provided for @supplierNoProducts.
  ///
  /// In en, this message translates to:
  /// **'This supplier has no products listed'**
  String get supplierNoProducts;

  /// No description provided for @noProductSelected.
  ///
  /// In en, this message translates to:
  /// **'No product selected'**
  String get noProductSelected;

  /// No description provided for @selectProductFromList.
  ///
  /// In en, this message translates to:
  /// **'Select a product from the list to see details'**
  String get selectProductFromList;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock: {quantity}'**
  String inStock(int quantity);

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @betterPriceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Better Price Available!'**
  String get betterPriceAvailable;

  /// No description provided for @productAvailableAtLowerPrice.
  ///
  /// In en, this message translates to:
  /// **'This product is available at a lower price:'**
  String get productAvailableAtLowerPrice;

  /// No description provided for @currentSupplier.
  ///
  /// In en, this message translates to:
  /// **'Current: {name}'**
  String currentSupplier(String name);

  /// No description provided for @betterSupplier.
  ///
  /// In en, this message translates to:
  /// **'Better: {name}'**
  String betterSupplier(String name);

  /// No description provided for @youSave.
  ///
  /// In en, this message translates to:
  /// **'You Save:'**
  String get youSave;

  /// No description provided for @savingsAmount.
  ///
  /// In en, this message translates to:
  /// **'\${amount} ({percentage}%)'**
  String savingsAmount(String amount, String percentage);

  /// No description provided for @switchSuppliersQuestion.
  ///
  /// In en, this message translates to:
  /// **'Would you like to switch suppliers for this product?'**
  String get switchSuppliersQuestion;

  /// No description provided for @keepCurrent.
  ///
  /// In en, this message translates to:
  /// **'Keep Current'**
  String get keepCurrent;

  /// No description provided for @switchSupplier.
  ///
  /// In en, this message translates to:
  /// **'Switch Supplier'**
  String get switchSupplier;

  /// No description provided for @newOrderReceived.
  ///
  /// In en, this message translates to:
  /// **'New Order Received'**
  String get newOrderReceived;

  /// No description provided for @orderReceivedFrom.
  ///
  /// In en, this message translates to:
  /// **'You have received a new order from {supplierName}'**
  String orderReceivedFrom(String supplierName);

  /// No description provided for @orderPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully for {supplierName}'**
  String orderPlacedSuccessfully(String supplierName);

  /// No description provided for @failedToPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order: {error}'**
  String failedToPlaceOrder(String error);

  /// No description provided for @failedToPlaceOrderForSupplier.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order for supplier #{supplierId}'**
  String failedToPlaceOrderForSupplier(int supplierId);

  /// No description provided for @errorPlacingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error placing order: {error}'**
  String errorPlacingOrder(String error);

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @quantityPrice.
  ///
  /// In en, this message translates to:
  /// **'{quantity} × \${price}'**
  String quantityPrice(int quantity, String price);

  /// No description provided for @allUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get allUsers;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @management.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get management;

  /// No description provided for @manageAndMonitorAllUserAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage and monitor all user accounts'**
  String get manageAndMonitorAllUserAccounts;

  /// No description provided for @searchByUserIdOrUserName.
  ///
  /// In en, this message translates to:
  /// **'Search by User ID or User Name...'**
  String get searchByUserIdOrUserName;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @addNewUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addNewUser;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address (Required)'**
  String get addressRequired;

  /// No description provided for @addressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get addressOptional;

  /// No description provided for @roleCannotBeChangedDuringEdit.
  ///
  /// In en, this message translates to:
  /// **'Note: Role cannot be changed during edit'**
  String get roleCannotBeChangedDuringEdit;

  /// No description provided for @accountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// No description provided for @updateUser.
  ///
  /// In en, this message translates to:
  /// **'Update User'**
  String get updateUser;

  /// No description provided for @createUser.
  ///
  /// In en, this message translates to:
  /// **'Create User'**
  String get createUser;

  /// No description provided for @userInfo.
  ///
  /// In en, this message translates to:
  /// **'User Info'**
  String get userInfo;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @usersOverview.
  ///
  /// In en, this message translates to:
  /// **'Users Overview'**
  String get usersOverview;

  /// No description provided for @loadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Loading users...'**
  String get loadingUsers;

  /// No description provided for @pleaseWaitWhileWeFetchUserData.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we fetch the user data'**
  String get pleaseWaitWhileWeFetchUserData;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @tryAdjustingYourSearchCriteria.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search criteria'**
  String get tryAdjustingYourSearchCriteria;

  /// No description provided for @noUsersHaveBeenAddedYet.
  ///
  /// In en, this message translates to:
  /// **'No users have been added yet'**
  String get noUsersHaveBeenAddedYet;

  /// No description provided for @showing.
  ///
  /// In en, this message translates to:
  /// **'Showing'**
  String get showing;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'users'**
  String get users;

  /// No description provided for @pleaseFillAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillAllRequiredFields;

  /// No description provided for @addressIsRequiredForCustomers.
  ///
  /// In en, this message translates to:
  /// **'Address is required for customers'**
  String get addressIsRequiredForCustomers;

  /// No description provided for @pleaseEnterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmailAddress;

  /// No description provided for @userAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User added successfully'**
  String get userAddedSuccessfully;

  /// No description provided for @userUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully'**
  String get userUpdatedSuccessfully;

  /// No description provided for @userStatusUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User status updated successfully'**
  String get userStatusUpdatedSuccessfully;

  /// No description provided for @userDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get userDeletedSuccessfully;

  /// No description provided for @failedToUpdateUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to update user'**
  String get failedToUpdateUser;

  /// No description provided for @failedToDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete user'**
  String get failedToDeleteUser;

  /// No description provided for @errorDeletingUser.
  ///
  /// In en, this message translates to:
  /// **'Error deleting user'**
  String get errorDeletingUser;

  /// No description provided for @failedToFetchUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch users'**
  String get failedToFetchUsers;

  /// No description provided for @failedToLoadUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load users'**
  String get failedToLoadUsers;

  /// No description provided for @failedToAddUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to add user'**
  String get failedToAddUser;

  /// No description provided for @apiDidNotReturnExpectedJsonStructure.
  ///
  /// In en, this message translates to:
  /// **'The API did not return the expected JSON structure.'**
  String get apiDidNotReturnExpectedJsonStructure;

  /// No description provided for @deliveryMan.
  ///
  /// In en, this message translates to:
  /// **'Delivery Man'**
  String get deliveryMan;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @unknownCustomer.
  ///
  /// In en, this message translates to:
  /// **'Unknown Customer'**
  String get unknownCustomer;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// No description provided for @unknownAddress.
  ///
  /// In en, this message translates to:
  /// **'Unknown Address'**
  String get unknownAddress;

  /// No description provided for @monitoring.
  ///
  /// In en, this message translates to:
  /// **'Monitoring'**
  String get monitoring;

  /// No description provided for @activeDeliveries.
  ///
  /// In en, this message translates to:
  /// **'active deliveries'**
  String get activeDeliveries;

  /// No description provided for @yourCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Your current location'**
  String get yourCurrentLocation;

  /// No description provided for @adminControlCenter.
  ///
  /// In en, this message translates to:
  /// **'Admin Control Center'**
  String get adminControlCenter;

  /// No description provided for @liveRouteSummary.
  ///
  /// In en, this message translates to:
  /// **'Live Route Summary'**
  String get liveRouteSummary;

  /// No description provided for @realRoutes.
  ///
  /// In en, this message translates to:
  /// **'REAL ROUTES'**
  String get realRoutes;

  /// No description provided for @activeRoutes.
  ///
  /// In en, this message translates to:
  /// **'Active Routes'**
  String get activeRoutes;

  /// No description provided for @avgDistance.
  ///
  /// In en, this message translates to:
  /// **'Avg Distance'**
  String get avgDistance;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @routePriorityBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Route Priority Breakdown'**
  String get routePriorityBreakdown;

  /// No description provided for @routeControls.
  ///
  /// In en, this message translates to:
  /// **'Route Controls'**
  String get routeControls;

  /// No description provided for @allRoutes.
  ///
  /// In en, this message translates to:
  /// **'All Routes'**
  String get allRoutes;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @refreshRoutes.
  ///
  /// In en, this message translates to:
  /// **'Refresh Routes'**
  String get refreshRoutes;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get highPriority;

  /// No description provided for @mediumPriority.
  ///
  /// In en, this message translates to:
  /// **'Medium Priority'**
  String get mediumPriority;

  /// No description provided for @lowPriority.
  ///
  /// In en, this message translates to:
  /// **'Low Priority'**
  String get lowPriority;

  /// No description provided for @noActiveRoutes.
  ///
  /// In en, this message translates to:
  /// **'No Active Routes'**
  String get noActiveRoutes;

  /// No description provided for @real.
  ///
  /// In en, this message translates to:
  /// **'REAL'**
  String get real;

  /// No description provided for @processingCancellation.
  ///
  /// In en, this message translates to:
  /// **'Processing cancellation for Order'**
  String get processingCancellation;

  /// No description provided for @failedToLoadRoutes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load routes'**
  String get failedToLoadRoutes;

  /// No description provided for @failedToLoadTrackingData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tracking data'**
  String get failedToLoadTrackingData;

  /// No description provided for @realRoads.
  ///
  /// In en, this message translates to:
  /// **'REAL ROADS'**
  String get realRoads;

  /// No description provided for @routes.
  ///
  /// In en, this message translates to:
  /// **'ROUTES'**
  String get routes;

  /// No description provided for @routeLegend.
  ///
  /// In en, this message translates to:
  /// **'ROUTE LEGEND'**
  String get routeLegend;

  /// No description provided for @googleDirectionsRoutes.
  ///
  /// In en, this message translates to:
  /// **'Google Directions Routes'**
  String get googleDirectionsRoutes;

  /// No description provided for @routeInformation.
  ///
  /// In en, this message translates to:
  /// **'Route Information'**
  String get routeInformation;

  /// No description provided for @deliveryAgent.
  ///
  /// In en, this message translates to:
  /// **'Delivery Agent'**
  String get deliveryAgent;

  /// No description provided for @routeStatus.
  ///
  /// In en, this message translates to:
  /// **'Route Status'**
  String get routeStatus;

  /// No description provided for @priorityLevel.
  ///
  /// In en, this message translates to:
  /// **'Priority Level'**
  String get priorityLevel;

  /// No description provided for @estimatedDistance.
  ///
  /// In en, this message translates to:
  /// **'Estimated Distance'**
  String get estimatedDistance;

  /// No description provided for @deliveryDestination.
  ///
  /// In en, this message translates to:
  /// **'Delivery Destination'**
  String get deliveryDestination;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer Phone'**
  String get customerPhone;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @itemsCountt.
  ///
  /// In en, this message translates to:
  /// **'Items Count'**
  String get itemsCountt;

  /// No description provided for @followRoute.
  ///
  /// In en, this message translates to:
  /// **'Follow Route'**
  String get followRoute;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @totalShipment.
  ///
  /// In en, this message translates to:
  /// **'Total Shipment'**
  String get totalShipment;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please login again.'**
  String get authenticationFailed;

  /// No description provided for @errorFetchingTrackingData.
  ///
  /// In en, this message translates to:
  /// **'Error fetching tracking data'**
  String get errorFetchingTrackingData;

  /// No description provided for @failedToLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders'**
  String get failedToLoadOrders;

  /// No description provided for @cancelingOrder.
  ///
  /// In en, this message translates to:
  /// **'Canceling order...'**
  String get cancelingOrder;

  /// No description provided for @orderCanceledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order has been canceled successfully'**
  String get orderCanceledSuccessfully;

  /// No description provided for @failedToCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel order'**
  String get failedToCancelOrder;

  /// No description provided for @errorCancelingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error canceling order'**
  String get errorCancelingOrder;

  /// No description provided for @provideCancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for canceling this order:'**
  String get provideCancellationReason;

  /// No description provided for @enterCancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Enter cancellation reason...'**
  String get enterCancellationReason;

  /// No description provided for @cancellationReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason is required'**
  String get cancellationReasonRequired;

  /// No description provided for @reasonMinLength.
  ///
  /// In en, this message translates to:
  /// **'Reason must be at least 10 characters'**
  String get reasonMinLength;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'⚠️ This action cannot be undone'**
  String get actionCannotBeUndone;

  /// No description provided for @keepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep Order'**
  String get keepOrder;

  /// No description provided for @ordersHistory.
  ///
  /// In en, this message translates to:
  /// **'Orders History'**
  String get ordersHistory;

  /// No description provided for @allOrdersFilter.
  ///
  /// In en, this message translates to:
  /// **'All Orders'**
  String get allOrdersFilter;

  /// No description provided for @shipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get shipped;

  /// No description provided for @orderIdHeader.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderIdHeader;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @cancelledByTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by {name}\nClick \"View Details\" for more info'**
  String cancelledByTooltip(Object name);

  /// No description provided for @administrativeDecision.
  ///
  /// In en, this message translates to:
  /// **'Administrative Decision'**
  String get administrativeDecision;

  /// No description provided for @customerRequest.
  ///
  /// In en, this message translates to:
  /// **'Customer Request'**
  String get customerRequest;

  /// No description provided for @inventoryIssue.
  ///
  /// In en, this message translates to:
  /// **'Inventory Issue'**
  String get inventoryIssue;

  /// No description provided for @deliveryProblem.
  ///
  /// In en, this message translates to:
  /// **'Delivery Problem'**
  String get deliveryProblem;

  /// No description provided for @paymentIssue.
  ///
  /// In en, this message translates to:
  /// **'Payment Issue'**
  String get paymentIssue;

  /// No description provided for @systemError.
  ///
  /// In en, this message translates to:
  /// **'System Error'**
  String get systemError;

  /// No description provided for @invalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid Date'**
  String get invalidDate;

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetailsTitle;

  /// No description provided for @unknownEmail.
  ///
  /// In en, this message translates to:
  /// **'Unknown Email'**
  String get unknownEmail;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @deliveryPerson.
  ///
  /// In en, this message translates to:
  /// **'Delivery Person'**
  String get deliveryPerson;

  /// No description provided for @unknownDeliveryPerson.
  ///
  /// In en, this message translates to:
  /// **'Unknown Delivery Person'**
  String get unknownDeliveryPerson;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @cancellationDetails.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Details'**
  String get cancellationDetails;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @cancelledAt.
  ///
  /// In en, this message translates to:
  /// **'Cancelled At'**
  String get cancelledAt;

  /// No description provided for @cancelledByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by Administrator'**
  String get cancelledByAdmin;

  /// No description provided for @adminName.
  ///
  /// In en, this message translates to:
  /// **'Admin Name'**
  String get adminName;

  /// No description provided for @adminEmail.
  ///
  /// In en, this message translates to:
  /// **'Admin Email'**
  String get adminEmail;

  /// No description provided for @adminId.
  ///
  /// In en, this message translates to:
  /// **'Admin ID'**
  String get adminId;

  /// No description provided for @unknownAdmin.
  ///
  /// In en, this message translates to:
  /// **'Unknown Admin'**
  String get unknownAdmin;

  /// No description provided for @cancelledBy.
  ///
  /// In en, this message translates to:
  /// **'Cancelled By'**
  String get cancelledBy;

  /// No description provided for @adminIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin ID'**
  String get adminIdLabel;

  /// No description provided for @unknownProduct.
  ///
  /// In en, this message translates to:
  /// **'Unknown Product'**
  String get unknownProduct;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @orderManagement.
  ///
  /// In en, this message translates to:
  /// **'Order Management'**
  String get orderManagement;

  /// No description provided for @ordersList.
  ///
  /// In en, this message translates to:
  /// **'Orders list'**
  String get ordersList;

  /// No description provided for @searchOrderId.
  ///
  /// In en, this message translates to:
  /// **'Search ID'**
  String get searchOrderId;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please log in again.'**
  String get authenticationError;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @failedToRefreshOrders.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh orders'**
  String get failedToRefreshOrders;

  /// No description provided for @productManagement.
  ///
  /// In en, this message translates to:
  /// **'Product Management'**
  String get productManagement;

  /// No description provided for @productsList.
  ///
  /// In en, this message translates to:
  /// **'Products list'**
  String get productsList;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allProducts;

  /// No description provided for @allRequests.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allRequests;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingRequests;

  /// No description provided for @acceptedRequests.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get acceptedRequests;

  /// No description provided for @declinedRequests.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declinedRequests;

  /// No description provided for @searchProductByNameOrId.
  ///
  /// In en, this message translates to:
  /// **'Search Product by name or id'**
  String get searchProductByNameOrId;

  /// No description provided for @requestedProductsList.
  ///
  /// In en, this message translates to:
  /// **'Requested products'**
  String get requestedProductsList;

  /// No description provided for @searchRequestByNameOrId.
  ///
  /// In en, this message translates to:
  /// **'Search request by name or id'**
  String get searchRequestByNameOrId;

  /// No description provided for @orderInformation.
  ///
  /// In en, this message translates to:
  /// **'Order Information'**
  String get orderInformation;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderIdLabel;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @paymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentLabel;

  /// No description provided for @deliveryAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddressLabel;

  /// No description provided for @productsLabel.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsLabel;

  /// No description provided for @tapToEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Tap to edit details'**
  String get tapToEditDetails;

  /// No description provided for @selectProductsToDecline.
  ///
  /// In en, this message translates to:
  /// **'Select products to decline'**
  String get selectProductsToDecline;

  /// No description provided for @idPrefix.
  ///
  /// In en, this message translates to:
  /// **'ID: '**
  String get idPrefix;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @acceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get acceptedStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @deliveredStatus.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveredStatus;

  /// No description provided for @declinedStatus.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declinedStatus;

  /// No description provided for @partiallyAcceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'Partially Accepted'**
  String get partiallyAcceptedStatus;

  /// No description provided for @editProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Product Details'**
  String get editProductDetails;

  /// No description provided for @productPrefix.
  ///
  /// In en, this message translates to:
  /// **'Product: '**
  String get productPrefix;

  /// No description provided for @pricePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Price per unit:'**
  String get pricePerUnit;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Fresh dairy batch, Organic certified...'**
  String get notesHint;

  /// No description provided for @newTotal.
  ///
  /// In en, this message translates to:
  /// **'New Total:'**
  String get newTotal;

  /// No description provided for @resetTo.
  ///
  /// In en, this message translates to:
  /// **'Reset to'**
  String get resetTo;

  /// No description provided for @originalData.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalData;

  /// No description provided for @defaultData.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultData;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @updateDetails.
  ///
  /// In en, this message translates to:
  /// **'Update Details'**
  String get updateDetails;

  /// No description provided for @priceValidationError.
  ///
  /// In en, this message translates to:
  /// **'Price must be greater than zero'**
  String get priceValidationError;

  /// No description provided for @validPriceError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get validPriceError;

  /// No description provided for @prodDatePrefix.
  ///
  /// In en, this message translates to:
  /// **'Prod: '**
  String get prodDatePrefix;

  /// No description provided for @expDatePrefix.
  ///
  /// In en, this message translates to:
  /// **'Exp: '**
  String get expDatePrefix;

  /// No description provided for @priceModified.
  ///
  /// In en, this message translates to:
  /// **'Price Modified'**
  String get priceModified;

  /// No description provided for @acceptPartially.
  ///
  /// In en, this message translates to:
  /// **'Accept Partially'**
  String get acceptPartially;

  /// No description provided for @withChanges.
  ///
  /// In en, this message translates to:
  /// **'with Changes'**
  String get withChanges;

  /// No description provided for @declineButton.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButton;

  /// No description provided for @acceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptButton;

  /// No description provided for @partiallyAcceptOrder.
  ///
  /// In en, this message translates to:
  /// **'Partially Accept Order'**
  String get partiallyAcceptOrder;

  /// No description provided for @partialAcceptanceDescription.
  ///
  /// In en, this message translates to:
  /// **'You are about to accept this order partially.'**
  String get partialAcceptanceDescription;

  /// No description provided for @productsWillBeDeclined.
  ///
  /// In en, this message translates to:
  /// **'{declinedCount} out of {totalProducts} products will be declined.'**
  String productsWillBeDeclined(Object declinedCount, Object totalProducts);

  /// No description provided for @pricesModified.
  ///
  /// In en, this message translates to:
  /// **'{count} product prices have been modified.'**
  String pricesModified(Object count);

  /// No description provided for @datesHaveBeenSet.
  ///
  /// In en, this message translates to:
  /// **'Production and expiry dates have been set for products.'**
  String get datesHaveBeenSet;

  /// No description provided for @providePartialReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for partial acceptance:'**
  String get providePartialReason;

  /// No description provided for @partialReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Some products are out of stock, dates updated for freshness'**
  String get partialReasonHint;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @partialReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for partial acceptance'**
  String get partialReasonRequired;

  /// No description provided for @declineOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline Order'**
  String get declineOrderTitle;

  /// No description provided for @provideDeclineReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for declining this order:'**
  String get provideDeclineReason;

  /// No description provided for @enterReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Enter reason...'**
  String get enterReasonHint;

  /// No description provided for @declineReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for declining'**
  String get declineReasonRequired;

  /// No description provided for @partiallyAcceptedMessage.
  ///
  /// In en, this message translates to:
  /// **'partially accepted'**
  String get partiallyAcceptedMessage;

  /// No description provided for @acceptedWithChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'accepted with changes'**
  String get acceptedWithChangesMessage;

  /// No description provided for @orderStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Order {orderId} has been {status}'**
  String orderStatusUpdated(Object orderId, Object status);

  /// No description provided for @failedToUpdateOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update order status'**
  String get failedToUpdateOrderStatus;

  /// No description provided for @errorUpdatingOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Error updating order status: {error}'**
  String errorUpdatingOrderStatus(Object error);

  /// No description provided for @orderPartiallyAcceptedNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Partially Accepted'**
  String get orderPartiallyAcceptedNotificationTitle;

  /// No description provided for @orderPartiallyAcceptedNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Order {orderId} has been partially accepted by supplier.'**
  String orderPartiallyAcceptedNotificationMessage(Object orderId);

  /// No description provided for @orderAcceptedWithChangesNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Accepted with Changes'**
  String get orderAcceptedWithChangesNotificationTitle;

  /// No description provided for @orderAcceptedWithChangesNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Order {orderId} has been accepted by supplier with changes.'**
  String orderAcceptedWithChangesNotificationMessage(Object orderId);

  /// No description provided for @orderAcceptedNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Accepted'**
  String get orderAcceptedNotificationTitle;

  /// No description provided for @orderAcceptedNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Order {orderId} has been accepted by supplier.'**
  String orderAcceptedNotificationMessage(Object orderId);

  /// No description provided for @orderDeclinedNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Declined'**
  String get orderDeclinedNotificationTitle;

  /// No description provided for @orderDeclinedNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Order {orderId} has been declined by supplier.'**
  String orderDeclinedNotificationMessage(Object orderId);

  /// No description provided for @orderDeliveredNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Delivered'**
  String get orderDeliveredNotificationTitle;

  /// No description provided for @orderDeliveredNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Order {orderId} has been marked as delivered.'**
  String orderDeliveredNotificationMessage(Object orderId);

  /// No description provided for @reasonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Reason: '**
  String get reasonPrefix;

  /// No description provided for @orderDateHeader.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDateHeader;

  /// No description provided for @totalProductsHeader.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProductsHeader;

  /// No description provided for @totalAmountHeader.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmountHeader;

  /// No description provided for @statusHeader.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusHeader;

  /// No description provided for @loadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingText;

  /// No description provided for @errorLoadingCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Categories'**
  String get errorLoadingCategoriesTitle;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeLabel;

  /// No description provided for @pleaseEnterBarcode.
  ///
  /// In en, this message translates to:
  /// **'Please enter barcode'**
  String get pleaseEnterBarcode;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @addProductButton.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductButton;

  /// No description provided for @enterFieldHint.
  ///
  /// In en, this message translates to:
  /// **'Enter {field}'**
  String enterFieldHint(Object field);

  /// No description provided for @pleaseSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Please select an image for the product'**
  String get pleaseSelectImage;

  /// No description provided for @invalidCategoriesData.
  ///
  /// In en, this message translates to:
  /// **'Invalid categories data structure'**
  String get invalidCategoriesData;

  /// No description provided for @errorLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get errorLoadingCategories;

  /// No description provided for @failedToSubmitProductRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit product request'**
  String get failedToSubmitProductRequest;

  /// No description provided for @errorSubmittingProductRequest.
  ///
  /// In en, this message translates to:
  /// **'Error submitting product request'**
  String get errorSubmittingProductRequest;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorPrefix;

  /// No description provided for @supplierPrice.
  ///
  /// In en, this message translates to:
  /// **'Supplier Price'**
  String get supplierPrice;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @currentSupplierPrice.
  ///
  /// In en, this message translates to:
  /// **'Current Supplier Price'**
  String get currentSupplierPrice;

  /// No description provided for @enterNewPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter new price'**
  String get enterNewPrice;

  /// No description provided for @productStatus.
  ///
  /// In en, this message translates to:
  /// **'Product Status'**
  String get productStatus;

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @setProductActive.
  ///
  /// In en, this message translates to:
  /// **'Set Product Active:'**
  String get setProductActive;

  /// No description provided for @productWillBeVisible.
  ///
  /// In en, this message translates to:
  /// **'Product will be visible to customers'**
  String get productWillBeVisible;

  /// No description provided for @productWillBeHidden.
  ///
  /// In en, this message translates to:
  /// **'Product will be hidden from customers'**
  String get productWillBeHidden;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @noChangesWereMade.
  ///
  /// In en, this message translates to:
  /// **'No changes were made'**
  String get noChangesWereMade;

  /// No description provided for @priceUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Price updated successfully'**
  String get priceUpdatedSuccessfully;

  /// No description provided for @errorUpdatingPrice.
  ///
  /// In en, this message translates to:
  /// **'Error updating price'**
  String get errorUpdatingPrice;

  /// No description provided for @errorProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Error: Product not found'**
  String get errorProductNotFound;

  /// No description provided for @statusUpdatedFrom.
  ///
  /// In en, this message translates to:
  /// **'Status updated from'**
  String get statusUpdatedFrom;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get to;

  /// No description provided for @warningStatusMayNotBeSaved.
  ///
  /// In en, this message translates to:
  /// **'Warning: Status may not be saved on server'**
  String get warningStatusMayNotBeSaved;

  /// No description provided for @productAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'{productName} added to cart'**
  String productAddedToCart(Object productName);

  /// No description provided for @customerOrdersNewOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get customerOrdersNewOrderTitle;

  /// No description provided for @customerOrdersRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get customerOrdersRefreshTooltip;

  /// No description provided for @customerOrdersSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get customerOrdersSearchPlaceholder;

  /// No description provided for @customerOrdersCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get customerOrdersCategoriesTitle;

  /// No description provided for @customerOrdersProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get customerOrdersProductsTitle;

  /// No description provided for @customerOrdersItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String customerOrdersItemsCount(Object count);

  /// No description provided for @customerOrdersNoProductsMessage.
  ///
  /// In en, this message translates to:
  /// **'No products in this Category\navailable'**
  String get customerOrdersNoProductsMessage;

  /// No description provided for @customerOrdersAddToCartButton.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get customerOrdersAddToCartButton;

  /// No description provided for @customerOrdersItemAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'{productName} added to cart'**
  String customerOrdersItemAddedToCart(Object productName);

  /// No description provided for @customerOrdersCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get customerOrdersCartEmpty;

  /// No description provided for @customerOrdersOrderPlacedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get customerOrdersOrderPlacedSuccess;

  /// No description provided for @customerOrdersPlaceOrderError.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order: '**
  String get customerOrdersPlaceOrderError;

  /// No description provided for @customerOrdersLoadCategoriesError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories: '**
  String get customerOrdersLoadCategoriesError;

  /// No description provided for @customerOrdersLoadProductsError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products: '**
  String get customerOrdersLoadProductsError;

  /// No description provided for @customerOrdersInsufficientStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Stock'**
  String get customerOrdersInsufficientStockTitle;

  /// No description provided for @customerOrdersStockDialogProduct.
  ///
  /// In en, this message translates to:
  /// **'Product: {productName}'**
  String customerOrdersStockDialogProduct(Object productName);

  /// No description provided for @customerOrdersStockDialogAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available: {available}'**
  String customerOrdersStockDialogAvailable(Object available);

  /// No description provided for @customerOrdersStockDialogRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested: {requested}'**
  String customerOrdersStockDialogRequested(Object requested);

  /// No description provided for @customerOrdersStockDialogUpdateQuestion.
  ///
  /// In en, this message translates to:
  /// **'Would you like to update the quantity to the maximum available?'**
  String get customerOrdersStockDialogUpdateQuestion;

  /// No description provided for @customerOrdersStockDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get customerOrdersStockDialogCancel;

  /// No description provided for @customerOrdersStockDialogUpdateQuantity.
  ///
  /// In en, this message translates to:
  /// **'Update Quantity'**
  String get customerOrdersStockDialogUpdateQuantity;

  /// No description provided for @customerHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get customerHistoryTitle;

  /// No description provided for @customerHistoryRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get customerHistoryRefreshTooltip;

  /// No description provided for @customerHistoryFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date Range'**
  String get customerHistoryFilterTitle;

  /// No description provided for @customerHistoryStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get customerHistoryStartDate;

  /// No description provided for @customerHistoryEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get customerHistoryEndDate;

  /// No description provided for @customerHistoryApplyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get customerHistoryApplyFilter;

  /// No description provided for @customerHistoryClearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get customerHistoryClearFilter;

  /// No description provided for @customerHistoryNoOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get customerHistoryNoOrdersFound;

  /// No description provided for @customerHistoryAdjustFilter.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filter criteria'**
  String get customerHistoryAdjustFilter;

  /// No description provided for @customerHistoryOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{orderId}'**
  String customerHistoryOrderNumber(Object orderId);

  /// No description provided for @customerHistoryOrderDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String customerHistoryOrderDate(Object date);

  /// No description provided for @customerHistoryItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String customerHistoryItemsCount(Object count);

  /// No description provided for @customerHistorySelectOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'Select an order to view details'**
  String get customerHistorySelectOrderMessage;

  /// No description provided for @customerHistoryOrderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get customerHistoryOrderDetailsTitle;

  /// No description provided for @customerHistoryPrintInvoice.
  ///
  /// In en, this message translates to:
  /// **'Print Invoice'**
  String get customerHistoryPrintInvoice;

  /// No description provided for @customerHistoryOrderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get customerHistoryOrderIdLabel;

  /// No description provided for @customerHistoryOrderDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get customerHistoryOrderDateLabel;

  /// No description provided for @customerHistoryPreparationStarted.
  ///
  /// In en, this message translates to:
  /// **'Preparation Started'**
  String get customerHistoryPreparationStarted;

  /// No description provided for @customerHistoryPreparationCompleted.
  ///
  /// In en, this message translates to:
  /// **'Preparation Completed'**
  String get customerHistoryPreparationCompleted;

  /// No description provided for @customerHistoryOrderItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get customerHistoryOrderItemsTitle;

  /// No description provided for @customerHistoryUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price: {price}'**
  String customerHistoryUnitPrice(Object price);

  /// No description provided for @customerHistoryTotalQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total Qty: {quantity}'**
  String customerHistoryTotalQuantity(Object quantity);

  /// No description provided for @customerHistoryBatchInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Batch Information'**
  String get customerHistoryBatchInfoTitle;

  /// No description provided for @customerHistoryBatchDescription.
  ///
  /// In en, this message translates to:
  /// **'This order contains products from {count} different batch(es):'**
  String customerHistoryBatchDescription(Object count);

  /// No description provided for @customerHistoryBatchNumber.
  ///
  /// In en, this message translates to:
  /// **'Batch #{batchId}'**
  String customerHistoryBatchNumber(Object batchId);

  /// No description provided for @customerHistoryBatchQuantity.
  ///
  /// In en, this message translates to:
  /// **'Qty: {quantity}'**
  String customerHistoryBatchQuantity(Object quantity);

  /// No description provided for @customerHistoryProductionDate.
  ///
  /// In en, this message translates to:
  /// **'Production Date'**
  String get customerHistoryProductionDate;

  /// No description provided for @customerHistoryExpirationDate.
  ///
  /// In en, this message translates to:
  /// **'Expiration Date'**
  String get customerHistoryExpirationDate;

  /// No description provided for @customerHistoryUnknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get customerHistoryUnknownDate;

  /// No description provided for @customerHistoryNoBatchInfo.
  ///
  /// In en, this message translates to:
  /// **'Batch information not found'**
  String get customerHistoryNoBatchInfo;

  /// No description provided for @customerHistoryCheckLogs.
  ///
  /// In en, this message translates to:
  /// **'Check console logs for debugging information.'**
  String get customerHistoryCheckLogs;

  /// No description provided for @customerHistoryRawData.
  ///
  /// In en, this message translates to:
  /// **'Raw data: {data}'**
  String customerHistoryRawData(Object data);

  /// No description provided for @customerHistorySubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get customerHistorySubtotal;

  /// No description provided for @customerHistoryDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get customerHistoryDiscount;

  /// No description provided for @customerHistoryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get customerHistoryTotal;

  /// No description provided for @customerHistoryAmountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get customerHistoryAmountPaid;

  /// No description provided for @customerHistoryPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get customerHistoryPaymentMethod;

  /// No description provided for @customerHistoryPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get customerHistoryPaymentStatus;

  /// No description provided for @customerHistoryNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get customerHistoryNotSpecified;

  /// No description provided for @customerHistoryPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get customerHistoryPaid;

  /// No description provided for @customerHistoryPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get customerHistoryPending;

  /// No description provided for @customerHistoryOrderNote.
  ///
  /// In en, this message translates to:
  /// **'Order Note'**
  String get customerHistoryOrderNote;

  /// No description provided for @customerHistoryLoadOrdersError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load order history: '**
  String get customerHistoryLoadOrdersError;

  /// No description provided for @customerHistoryStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get customerHistoryStatusDelivered;

  /// No description provided for @customerHistoryStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get customerHistoryStatusPending;

  /// No description provided for @customerHistoryStatusPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get customerHistoryStatusPrepared;

  /// No description provided for @customerHistoryStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get customerHistoryStatusCancelled;

  /// No description provided for @customerHistoryStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get customerHistoryStatusRejected;

  /// No description provided for @customerHistoryStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get customerHistoryStatusAccepted;

  /// No description provided for @locationPopupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Your Location'**
  String get locationPopupTitle;

  /// No description provided for @locationPopupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your location on the map or use your current location'**
  String get locationPopupSubtitle;

  /// No description provided for @locationPopupUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get locationPopupUseCurrentLocation;

  /// No description provided for @locationPopupUseCurrentLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get locationPopupUseCurrentLocationTooltip;

  /// No description provided for @locationPopupSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Location'**
  String get locationPopupSaveButton;

  /// No description provided for @locationPopupServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationPopupServicesDisabled;

  /// No description provided for @locationPopupPermissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied'**
  String get locationPopupPermissionsDenied;

  /// No description provided for @locationPopupPermissionsPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied'**
  String get locationPopupPermissionsPermanentlyDenied;

  /// No description provided for @locationPopupErrorGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error getting location: {error}'**
  String locationPopupErrorGettingLocation(Object error);

  /// No description provided for @locationPopupSelectLocationFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a location first'**
  String get locationPopupSelectLocationFirst;

  /// No description provided for @locationPopupAuthError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please login again.'**
  String get locationPopupAuthError;

  /// No description provided for @locationPopupSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Location saved successfully'**
  String get locationPopupSavedSuccessfully;

  /// No description provided for @locationPopupErrorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving location: {statusCode}'**
  String locationPopupErrorSaving(Object statusCode);

  /// No description provided for @locationPopupErrorSavingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error saving location: {error}'**
  String locationPopupErrorSavingLocation(Object error);

  /// No description provided for @categoryWidgetsNoProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available in this category'**
  String get categoryWidgetsNoProductsAvailable;

  /// No description provided for @categoryWidgetsAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get categoryWidgetsAddToCart;

  /// No description provided for @categoryWidgetsYourCart.
  ///
  /// In en, this message translates to:
  /// **'Your Cart'**
  String get categoryWidgetsYourCart;

  /// No description provided for @categoryWidgetsCartItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String categoryWidgetsCartItemCount(Object count);

  /// No description provided for @categoryWidgetsCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get categoryWidgetsCartEmpty;

  /// No description provided for @categoryWidgetsAddItemsToStart.
  ///
  /// In en, this message translates to:
  /// **'Add items to get started'**
  String get categoryWidgetsAddItemsToStart;

  /// No description provided for @categoryWidgetsPriceEach.
  ///
  /// In en, this message translates to:
  /// **'\${price} each'**
  String categoryWidgetsPriceEach(Object price);

  /// No description provided for @categoryWidgetsQuantityMultiplier.
  ///
  /// In en, this message translates to:
  /// **'× {quantity}'**
  String categoryWidgetsQuantityMultiplier(Object quantity);

  /// No description provided for @categoryWidgetsSubtotalItems.
  ///
  /// In en, this message translates to:
  /// **'Subtotal ({count} items)'**
  String categoryWidgetsSubtotalItems(Object count);

  /// No description provided for @categoryWidgetsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get categoryWidgetsTotal;

  /// No description provided for @categoryWidgetsPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get categoryWidgetsPlaceOrder;

  /// No description provided for @navbarAppName.
  ///
  /// In en, this message translates to:
  /// **'Storify'**
  String get navbarAppName;

  /// No description provided for @navbarOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navbarOrders;

  /// No description provided for @navbarHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navbarHistory;

  /// No description provided for @orderHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistoryTitle;

  /// No description provided for @orderHistoryRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get orderHistoryRetryButton;

  /// No description provided for @orderHistoryTotalActivity.
  ///
  /// In en, this message translates to:
  /// **'Total Activity'**
  String get orderHistoryTotalActivity;

  /// No description provided for @orderHistorySupplierOrders.
  ///
  /// In en, this message translates to:
  /// **'Supplier Orders'**
  String get orderHistorySupplierOrders;

  /// No description provided for @orderHistoryCustomerOrders.
  ///
  /// In en, this message translates to:
  /// **'Customer Orders'**
  String get orderHistoryCustomerOrders;

  /// No description provided for @orderHistoryViewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get orderHistoryViewed;

  /// No description provided for @orderHistoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get orderHistoryUpdated;

  /// No description provided for @orderHistoryOrderType.
  ///
  /// In en, this message translates to:
  /// **'Order Type:'**
  String get orderHistoryOrderType;

  /// No description provided for @orderHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Action:'**
  String get orderHistoryAction;

  /// No description provided for @orderHistoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get orderHistoryFilterAll;

  /// No description provided for @orderHistoryFilterSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get orderHistoryFilterSupplier;

  /// No description provided for @orderHistoryFilterCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get orderHistoryFilterCustomer;

  /// No description provided for @orderHistoryFilterViewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get orderHistoryFilterViewed;

  /// No description provided for @orderHistoryFilterUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get orderHistoryFilterUpdated;

  /// No description provided for @orderHistorySearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search Order ID'**
  String get orderHistorySearchPlaceholder;

  /// No description provided for @orderHistoryNoHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No order history found'**
  String get orderHistoryNoHistoryFound;

  /// No description provided for @orderHistoryNoHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'There are no processed orders to display'**
  String get orderHistoryNoHistoryDescription;

  /// No description provided for @orderHistoryTableTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get orderHistoryTableTime;

  /// No description provided for @orderHistoryTableOrderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderHistoryTableOrderId;

  /// No description provided for @orderHistoryTableType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get orderHistoryTableType;

  /// No description provided for @orderHistoryTableAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get orderHistoryTableAction;

  /// No description provided for @orderHistoryTableBeforeStatus.
  ///
  /// In en, this message translates to:
  /// **'Before Status'**
  String get orderHistoryTableBeforeStatus;

  /// No description provided for @orderHistoryTableAfterStatus.
  ///
  /// In en, this message translates to:
  /// **'After Status'**
  String get orderHistoryTableAfterStatus;

  /// No description provided for @orderHistoryTableEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get orderHistoryTableEmployee;

  /// No description provided for @orderHistoryTableNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get orderHistoryTableNote;

  /// No description provided for @orderHistoryTypeSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get orderHistoryTypeSupplier;

  /// No description provided for @orderHistoryTypeCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get orderHistoryTypeCustomer;

  /// No description provided for @orderHistoryTotalRecords.
  ///
  /// In en, this message translates to:
  /// **'Total {totalItems} Records'**
  String orderHistoryTotalRecords(Object totalItems);

  /// No description provided for @orderHistoryStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get orderHistoryStatusAccepted;

  /// No description provided for @orderHistoryStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get orderHistoryStatusPending;

  /// No description provided for @orderHistoryStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderHistoryStatusDelivered;

  /// No description provided for @orderHistoryStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get orderHistoryStatusShipped;

  /// No description provided for @orderHistoryStatusPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get orderHistoryStatusPrepared;

  /// No description provided for @orderHistoryStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get orderHistoryStatusRejected;

  /// No description provided for @orderHistoryStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get orderHistoryStatusDeclined;

  /// No description provided for @orderHistoryStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get orderHistoryStatusPreparing;

  /// No description provided for @orderHistoryActionViewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get orderHistoryActionViewed;

  /// No description provided for @orderHistoryActionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get orderHistoryActionUpdated;

  /// No description provided for @ordersSupplierOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier Orders'**
  String get ordersSupplierOrdersTitle;

  /// No description provided for @ordersCustomerOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Orders'**
  String get ordersCustomerOrdersTitle;

  /// No description provided for @ordersSuppliersTab.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get ordersSuppliersTab;

  /// No description provided for @ordersCustomersTab.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get ordersCustomersTab;

  /// No description provided for @ordersLoadErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders: {error}'**
  String ordersLoadErrorMessage(Object error);

  /// No description provided for @ordersRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get ordersRetryButton;

  /// No description provided for @ordersTotalOrdersCard.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get ordersTotalOrdersCard;

  /// No description provided for @ordersActiveOrdersCard.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get ordersActiveOrdersCard;

  /// No description provided for @ordersCompletedOrdersCard.
  ///
  /// In en, this message translates to:
  /// **'Completed Orders'**
  String get ordersCompletedOrdersCard;

  /// No description provided for @ordersAllOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'All Orders'**
  String get ordersAllOrdersTitle;

  /// No description provided for @ordersActiveOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get ordersActiveOrdersTitle;

  /// No description provided for @ordersCompletedOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed Orders'**
  String get ordersCompletedOrdersTitle;

  /// No description provided for @ordersSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search ID'**
  String get ordersSearchPlaceholder;

  /// No description provided for @ordersNoOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get ordersNoOrdersFound;

  /// No description provided for @ordersNoOrdersDescription.
  ///
  /// In en, this message translates to:
  /// **'There are no orders to display'**
  String get ordersNoOrdersDescription;

  /// No description provided for @ordersTableOrderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get ordersTableOrderId;

  /// No description provided for @ordersTableSupplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get ordersTableSupplierName;

  /// No description provided for @ordersTableCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get ordersTableCustomerName;

  /// No description provided for @ordersTablePhoneNo.
  ///
  /// In en, this message translates to:
  /// **'Phone No'**
  String get ordersTablePhoneNo;

  /// No description provided for @ordersTableOrderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get ordersTableOrderDate;

  /// No description provided for @ordersTableTotalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get ordersTableTotalProducts;

  /// No description provided for @ordersTableTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get ordersTableTotalAmount;

  /// No description provided for @ordersTableStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ordersTableStatus;

  /// No description provided for @ordersTotalOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'Total {count} Orders'**
  String ordersTotalOrdersCount(Object count);

  /// No description provided for @ordersStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get ordersStatusAccepted;

  /// No description provided for @ordersStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get ordersStatusPending;

  /// No description provided for @ordersStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get ordersStatusDelivered;

  /// No description provided for @ordersStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get ordersStatusShipped;

  /// No description provided for @ordersStatusPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get ordersStatusPrepared;

  /// No description provided for @ordersStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get ordersStatusRejected;

  /// No description provided for @ordersStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get ordersStatusDeclined;

  /// No description provided for @ordersStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get ordersStatusPreparing;

  /// No description provided for @viewOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get viewOrderTitle;

  /// No description provided for @viewOrderBackButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get viewOrderBackButton;

  /// No description provided for @viewOrderPrintInvoice.
  ///
  /// In en, this message translates to:
  /// **'Print Invoice'**
  String get viewOrderPrintInvoice;

  /// No description provided for @viewOrderPrintingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Printing invoice...'**
  String get viewOrderPrintingInvoice;

  /// No description provided for @viewOrderRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get viewOrderRetryButton;

  /// No description provided for @viewOrderGoBackButton.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get viewOrderGoBackButton;

  /// No description provided for @viewOrderDataRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Order data refreshed'**
  String get viewOrderDataRefreshed;

  /// No description provided for @viewOrderMustBeAcceptedToStart.
  ///
  /// In en, this message translates to:
  /// **'Order must be in Accepted status to start preparation'**
  String get viewOrderMustBeAcceptedToStart;

  /// No description provided for @viewOrderPreparationStartedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order preparation started successfully'**
  String get viewOrderPreparationStartedSuccess;

  /// No description provided for @viewOrderPreparationStartedCritical.
  ///
  /// In en, this message translates to:
  /// **'Order preparation started successfully - Critical alerts detected!'**
  String get viewOrderPreparationStartedCritical;

  /// No description provided for @viewOrderPreparationStartedAlerts.
  ///
  /// In en, this message translates to:
  /// **'Order preparation started successfully - {count} alerts to review'**
  String viewOrderPreparationStartedAlerts(Object count);

  /// No description provided for @viewOrderMustBePreparingToComplete.
  ///
  /// In en, this message translates to:
  /// **'Order must be in Preparing status to complete'**
  String get viewOrderMustBePreparingToComplete;

  /// No description provided for @viewOrderCompletedManualBatch.
  ///
  /// In en, this message translates to:
  /// **'with manual batch selection'**
  String get viewOrderCompletedManualBatch;

  /// No description provided for @viewOrderCompletedAutoFifo.
  ///
  /// In en, this message translates to:
  /// **'using auto FIFO'**
  String get viewOrderCompletedAutoFifo;

  /// No description provided for @viewOrderCompletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order completed successfully {mode}'**
  String viewOrderCompletedSuccess(Object mode);

  /// No description provided for @viewOrderAlreadyInStatus.
  ///
  /// In en, this message translates to:
  /// **'Order is already in {status} status'**
  String viewOrderAlreadyInStatus(Object status);

  /// No description provided for @viewOrderUpdatedToStatus.
  ///
  /// In en, this message translates to:
  /// **'Order updated to {status} successfully'**
  String viewOrderUpdatedToStatus(Object status);

  /// No description provided for @viewOrderBatchManagement.
  ///
  /// In en, this message translates to:
  /// **'Batch Management'**
  String get viewOrderBatchManagement;

  /// No description provided for @viewOrderBatchSummary.
  ///
  /// In en, this message translates to:
  /// **'{totalItems} items, {alertCount} alerts'**
  String viewOrderBatchSummary(Object alertCount, Object totalItems);

  /// No description provided for @viewOrderHideDetails.
  ///
  /// In en, this message translates to:
  /// **'Hide Details'**
  String get viewOrderHideDetails;

  /// No description provided for @viewOrderShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Details'**
  String get viewOrderShowDetails;

  /// No description provided for @viewOrderMoreAlerts.
  ///
  /// In en, this message translates to:
  /// **'... and {count} more alerts'**
  String viewOrderMoreAlerts(Object count);

  /// No description provided for @viewOrderManualBatchMode.
  ///
  /// In en, this message translates to:
  /// **'Manual batch selection mode'**
  String get viewOrderManualBatchMode;

  /// No description provided for @viewOrderAutoFifoMode.
  ///
  /// In en, this message translates to:
  /// **'Auto FIFO mode (recommended)'**
  String get viewOrderAutoFifoMode;

  /// No description provided for @viewOrderBatchSelection.
  ///
  /// In en, this message translates to:
  /// **'Batch Selection:'**
  String get viewOrderBatchSelection;

  /// No description provided for @viewOrderBatchRequiredAvailable.
  ///
  /// In en, this message translates to:
  /// **'Required: {required} | Available: {available}'**
  String viewOrderBatchRequiredAvailable(Object available, Object required);

  /// No description provided for @viewOrderFifoLabel.
  ///
  /// In en, this message translates to:
  /// **'FIFO'**
  String get viewOrderFifoLabel;

  /// No description provided for @viewOrderBatchDates.
  ///
  /// In en, this message translates to:
  /// **'Prod: {prodDate} | Exp: {expDate} | Available: {available}'**
  String viewOrderBatchDates(Object available, Object expDate, Object prodDate);

  /// No description provided for @viewOrderNoItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get viewOrderNoItemsFound;

  /// No description provided for @viewOrderNoItemsDescription.
  ///
  /// In en, this message translates to:
  /// **'This order doesn\'t contain any items'**
  String get viewOrderNoItemsDescription;

  /// No description provided for @viewOrderUnitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get viewOrderUnitPriceLabel;

  /// No description provided for @viewOrderQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get viewOrderQuantityLabel;

  /// No description provided for @viewOrderPageInfo.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String viewOrderPageInfo(Object current, Object total);

  /// No description provided for @viewOrderSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal:'**
  String get viewOrderSubtotal;

  /// No description provided for @viewOrderGrandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total:'**
  String get viewOrderGrandTotal;

  /// No description provided for @viewOrderQuantityChangesDetected.
  ///
  /// In en, this message translates to:
  /// **'Quantity Changes Detected'**
  String get viewOrderQuantityChangesDetected;

  /// No description provided for @viewOrderChangesWillBeApplied.
  ///
  /// In en, this message translates to:
  /// **'Your changes will be applied when updating the order status.'**
  String get viewOrderChangesWillBeApplied;

  /// No description provided for @viewOrderItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get viewOrderItemsTitle;

  /// No description provided for @viewOrderItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String viewOrderItemsCount(Object count);

  /// No description provided for @viewOrderInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Information'**
  String get viewOrderInformationTitle;

  /// No description provided for @viewOrderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get viewOrderIdLabel;

  /// No description provided for @viewOrderDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get viewOrderDateLabel;

  /// No description provided for @viewOrderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Type'**
  String get viewOrderTypeLabel;

  /// No description provided for @viewOrderPaymentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get viewOrderPaymentStatusLabel;

  /// No description provided for @viewOrderPaymentPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get viewOrderPaymentPaid;

  /// No description provided for @viewOrderPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get viewOrderPaymentPending;

  /// No description provided for @viewOrderStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get viewOrderStatusLabel;

  /// No description provided for @viewOrderActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Actions:'**
  String get viewOrderActionsTitle;

  /// No description provided for @viewOrderNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a note about this action (optional)...'**
  String get viewOrderNotePlaceholder;

  /// No description provided for @viewOrderStartPreparingButton.
  ///
  /// In en, this message translates to:
  /// **'Start Preparing'**
  String get viewOrderStartPreparingButton;

  /// No description provided for @viewOrderCompletePreparationButton.
  ///
  /// In en, this message translates to:
  /// **'Complete Preparation'**
  String get viewOrderCompletePreparationButton;

  /// No description provided for @viewOrderMarkAsDeliveredButton.
  ///
  /// In en, this message translates to:
  /// **'Mark as Delivered'**
  String get viewOrderMarkAsDeliveredButton;

  /// No description provided for @viewOrderSupplierInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier Info'**
  String get viewOrderSupplierInfoTitle;

  /// No description provided for @viewOrderCustomerInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Info'**
  String get viewOrderCustomerInfoTitle;

  /// No description provided for @viewOrderNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get viewOrderNameLabel;

  /// No description provided for @viewOrderPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get viewOrderPhoneLabel;

  /// No description provided for @viewOrderErrorDisplaying.
  ///
  /// In en, this message translates to:
  /// **'Error displaying order details: {error}'**
  String viewOrderErrorDisplaying(Object error);

  /// No description provided for @viewOrderStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get viewOrderStatusAccepted;

  /// No description provided for @viewOrderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get viewOrderStatusPending;

  /// No description provided for @viewOrderStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get viewOrderStatusDelivered;

  /// No description provided for @viewOrderStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get viewOrderStatusShipped;

  /// No description provided for @viewOrderStatusPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get viewOrderStatusPrepared;

  /// No description provided for @viewOrderStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get viewOrderStatusRejected;

  /// No description provided for @viewOrderStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get viewOrderStatusDeclined;

  /// No description provided for @viewOrderStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get viewOrderStatusPreparing;

  /// No description provided for @navBarOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navBarOrders;

  /// No description provided for @navBarHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navBarHistory;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
