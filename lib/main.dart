import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:totp/src/app.dart';
import 'package:totp/src/features/widgets/totp_widget_provider.dart';
import 'package:totp/src/core/utils/encryption_util.dart';
import 'package:totp/src/core/di/service_locator.dart';
import 'package:totp/src/core/services/settings_service.dart';
import 'package:totp/src/core/services/cloud_backup_service.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize service locator
  ServiceLocator.setup();

  // Initialize settings service
  await ServiceLocator.get<SettingsService>().init();

  // Initialize encryption utility
  await EncryptionUtil.init();

  // Initialize cloud backup service
  await ServiceLocator.get<CloudBackupService>().initialize();

  if (!kIsWeb) {
    HomeWidget.setAppGroupId('group.com.fossindia.totp');
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  }

  runApp(
    BlocProvider(
      create: (context) => TotpBloc(ServiceLocator.get<TotpManager>()),
      child: const TotpApp(),
    ),
  );
}
