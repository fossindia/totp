import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:totp/src/app.dart';
import 'package:totp/src/features/widgets/totp_widget_provider.dart';
import 'package:totp/src/core/utils/encryption_util.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';
import 'package:totp/src/blocs/totp_bloc/totp_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EncryptionUtil.init();
  if (!kIsWeb) {
    HomeWidget.setAppGroupId('group.com.fossindia.totp');
    HomeWidget.registerInteractivityCallback(backgroundCallback);
  }
  runApp(
    BlocProvider(
      create: (context) => TotpBloc(TotpManager()),
      child: const TotpApp(),
    ),
  );
}
