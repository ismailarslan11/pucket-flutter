import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/settings_service.dart';
import 'app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => watch<SettingsService>().l10n;
}

extension L10nRead on BuildContext {
  AppLocalizations get l10nRead => read<SettingsService>().l10n;
}
