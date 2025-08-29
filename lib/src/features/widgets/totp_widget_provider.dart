import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';
import 'package:totp/src/features/totp_generation/totp_service.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';

/// This function is the entry point for the background widget update.
/// It must be a top-level function.
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'update_widget') {
    await updateTotpWidget();
  }
}

Future<void> updateTotpWidget() async {
  final totpManager = TotpManager();
  final totpService = TotpService();
  final prefs = await SharedPreferences.getInstance();
  final int totpRefreshInterval = prefs.getInt('totpRefreshInterval') ?? 30;

  List<TotpItem> totpItems = await totpManager.loadTotpItems();

  if (totpItems.isNotEmpty) {
    // For simplicity, we'll display the first TOTP item
    final TotpItem firstItem = totpItems.first;
    final String otp = totpService.generateTotp(
      firstItem.secret,
      totpRefreshInterval,
    );
    final int remainingSeconds = totpService.getRemainingSeconds(
      totpRefreshInterval,
    );

    await HomeWidget.saveWidgetData('serviceName', firstItem.serviceName);
    await HomeWidget.saveWidgetData('username', firstItem.username);
    await HomeWidget.saveWidgetData('otp', otp);
    await HomeWidget.saveWidgetData('remainingSeconds', remainingSeconds);

    await HomeWidget.updateWidget(
      name: 'TotpWidget', // This should match the name in your native code
      iOSName: 'TotpWidgetExtension', // For iOS
    );
  }
}
