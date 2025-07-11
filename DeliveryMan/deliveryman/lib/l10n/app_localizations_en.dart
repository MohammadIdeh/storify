// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Delivery App';

  @override
  String get deliveryLogin => 'Delivery Login';

  @override
  String get loginSubtitle => 'Login to access your delivery assignments';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get login => 'Log In';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get validEmailError => 'Please enter a valid email';

  @override
  String get map => 'Map';

  @override
  String get orders => 'Orders';

  @override
  String get history => 'History';

  @override
  String get deliveryOverview => 'Delivery Overview';

  @override
  String get total => 'Total';

  @override
  String get active => 'Active';

  @override
  String get navigatingToCustomer => 'Navigating to Customer';

  @override
  String get eta => 'ETA';

  @override
  String get distance => 'Distance';

  @override
  String get elapsed => 'Elapsed';

  @override
  String get viewDetails => 'View Details';

  @override
  String get complete => 'Complete';

  @override
  String get startDelivery => 'Start Delivery';

  @override
  String get markDelivered => 'Mark Delivered';

  @override
  String get customer => 'Customer';

  @override
  String get phone => 'Phone';

  @override
  String get deliveryAddress => 'Delivery Address';

  @override
  String get amount => 'Amount';

  @override
  String get items => 'Items';

  @override
  String get orderNotes => 'Order Notes';

  @override
  String get assigned => 'Assigned';

  @override
  String get inProgress => 'In Progress';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get pending => 'Pending';

  @override
  String get ready => 'Ready';

  @override
  String get waiting => 'Waiting';

  @override
  String get noActiveDeliveries => 'No Active Deliveries';

  @override
  String get checkOrdersTab => 'Check the Orders tab for new assignments';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get orderInformation => 'Order Information';

  @override
  String get customerSignature => 'Customer Signature';

  @override
  String get completeDelivery => 'Complete Delivery';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cashPayment => 'Cash Payment';

  @override
  String get partialPayment => 'Partial Payment';

  @override
  String get addToAccount => 'Add to Account';

  @override
  String get deliveryNotes => 'Delivery Notes';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get refresh => 'Refresh';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get noOrdersAvailable => 'No Active Deliveries';

  @override
  String get noOrdersSubtitle =>
      'You don\'t have any assigned deliveries at the moment.\nCheck back later for new assignments.';

  @override
  String get refreshOrders => 'Refresh Orders';

  @override
  String get batchDelivery => 'Batch Delivery';

  @override
  String get selectAll => 'Select All';

  @override
  String get multiSelect => 'Multi-Select';

  @override
  String get exitSelection => 'Exit Selection';

  @override
  String startBatch(int count) {
    return 'Start $count';
  }
}
