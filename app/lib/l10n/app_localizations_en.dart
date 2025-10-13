// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RentTracker';

  @override
  String get properties => 'Properties';

  @override
  String get contracts => 'Contracts';

  @override
  String get payments => 'Payments';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get addProperty => 'Add Property';

  @override
  String get addContract => 'Add Contract';

  @override
  String get addPayment => 'Record Payment';

  @override
  String get overdue => 'Overdue';

  @override
  String get dueSoon => 'Due Soon';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get markPaid => 'Mark Paid';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';
}
