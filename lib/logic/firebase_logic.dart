import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/firebase_options.dart';

class FirebaseService {
  Future<FirebaseApp>? app;

  Future<void> init() async {
    if (app == null) {
      app = Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Initialized default firebase app $app');
    }
    await app;
  }
}

class AnalyticsLogic {
  FirebaseService get service => GetIt.I.get<FirebaseService>();

  late final FirebaseAnalytics analyticsInstance;

  void logScreenView({required String screenName, String? screenClass}) {
    unawaited(
      analyticsInstance.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      ),
    );
  }

  Future<void> init() async {
    await service.init();
    final app = await service.app!;
    analyticsInstance = FirebaseAnalytics.instanceFor(app: app);
  }
}

class AuthLogic {
  FirebaseService get service => GetIt.I.get<FirebaseService>();

  late final FirebaseAuth auth;

  String? getUid() {
    return auth.currentUser?.uid;
  }

  bool isLoggedIn() {
    return !(auth.currentUser?.isAnonymous ?? true);
  }

  Future<void> init() async {
    await service.init();
    final app = await service.app!;
    auth = FirebaseAuth.instanceFor(app: app);
  }
}

class CrashlyticsLogic {
  FirebaseService get service => GetIt.I.get<FirebaseService>();

  late final bool Function(Object, StackTrace)? chain;

  Future<void> init() async {
    await service.init();
    await service.app!;
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    chain = PlatformDispatcher.instance.onError;
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return chain != null ? chain!(error, stack) : true;
    };
  }
}

class FireDatabaseLogic {
  FirebaseService get service => GetIt.I.get<FirebaseService>();
  AuthLogic get authLogic => GetIt.I.get<AuthLogic>();

  late final FirebaseDatabase instance;

  DatabaseReference getUserRef() {
    final userId = authLogic.getUid();
    assert(userId != null);
    return instance.ref('users/$userId');
  }

  Future<void> saveUserSettings(Map<String, dynamic> values) async {
    await getUserRef().update({'setting': values});
  }

  Future<Map<String, dynamic>?> getUserSettings() async {
    final snapshot = await getUserRef().child('setting').get();
    if (snapshot.exists) {
      debugPrint(snapshot.value?.toString());
      return snapshot.value as Map<String, dynamic>?;
    } else {
      debugPrint('No data available.');
      return null;
    }
  }

  Future<void> saveJsonInUser(String key, Map<String, dynamic> values) async {
    await getUserRef().update({key: values});
  }

  Future<Map<String, dynamic>?> getJsonInUser(String key) async {
    final snapshot = await getUserRef().child(key).get();
    if (snapshot.exists) {
      debugPrint(snapshot.value?.toString());
      final value = snapshot.value as Map<Object?, Object?>?;
      return value?.cast();
    } else {
      debugPrint('No data available.');
      return null;
    }
  }

  Future<void> init() async {
    await service.init();
    final app = await service.app!;
    instance = FirebaseDatabase.instanceFor(app: app)..setPersistenceEnabled(true);
  }
}
