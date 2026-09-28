import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'state/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFFAF9F5),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  final auth = AuthProvider();
  auth.restoreSession();
  runApp(TrustLandApp(auth: auth));
}
