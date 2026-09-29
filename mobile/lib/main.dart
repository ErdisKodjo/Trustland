import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/push_service.dart';
import 'state/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFFFAF9F5),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  // Handler de messages FCM en arrière-plan
  // (no-op tant que Firebase n'est pas configuré — voir mobile/README.md).
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final auth = AuthProvider();
  auth.restoreSession();
  runApp(TrustLandApp(auth: auth));
}
