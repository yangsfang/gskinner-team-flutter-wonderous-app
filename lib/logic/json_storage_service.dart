import 'package:firebase_core/firebase_core.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/common/json_prefs_file.dart';
import 'package:wonders/logic/common/throttler.dart';

// Manages how Json is stored - as a file and sync'ed to the server.
class JsonStorageManagerService {
  JsonStorageManagerService({required this.fileStorageFilename, required this.firebaseKeyName});

  final String fileStorageFilename;
  final String firebaseKeyName;

  late final file = FileBasedJsonStorageService(fileName: fileStorageFilename);
  late final fire = FirebaseJsonStorageService(key: firebaseKeyName);

  AuthLogic get firebaseAuth => GetIt.I.get<AuthLogic>();

  Future<Map<String, dynamic>> load() {
    if (firebaseAuth.isLoggedIn()) {
      return fire.load();
    } else {
      return file.load();
    }
  }

  Future<void> save(Map<String, dynamic> value) async {
    if (firebaseAuth.isLoggedIn()) {
      return fire.scheduleSave(value);
    } else {
      return file.scheduleSave(value);
    }
  }
}

/// Represents a Json storage service that stores to one destination.
abstract class JsonStorageService {
  Future<Map<String, dynamic>> load();

  Future<void> save(Map<String, dynamic> value);

  Future<void> scheduleSave(Map<String, dynamic> value);
}

mixin ThrottledSaveMixin {
  final _throttle = Throttler(const Duration(seconds: 2));

  Future<void> save(Map<String, dynamic> value);

  Future<void> scheduleSave(Map<String, dynamic> value) async => _throttle.call(() => save(value));
}

class FileBasedJsonStorageService with ThrottledSaveMixin implements JsonStorageService {
  FileBasedJsonStorageService({required this.fileName});

  final String fileName;
  late final _file = JsonPrefsFile(fileName);

  @override
  Future<Map<String, dynamic>> load() async {
    final results = await _file.load();
    return results;
  }

  @override
  Future<void> save(Map<String, dynamic> value) async {
    debugPrint('Saving...');
    try {
      await _file.save(value);
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}

class FirebaseJsonStorageService with ThrottledSaveMixin implements JsonStorageService {
  FirebaseJsonStorageService({required this.key});

  FireDatabaseLogic get database => GetIt.I.get<FireDatabaseLogic>();

  final String key;

  @override
  Future<Map<String, dynamic>> load() async {
    debugPrint('Getting $key from Firebase...');
    try {
      final loadedValue = await database.getJsonInUser(key) ?? {};
      return loadedValue;
    } on FirebaseException catch (e) {
      debugPrint(e.toString());
      return {};
    }
  }

  @override
  Future<void> save(Map<String, dynamic> value) async {
    debugPrint('Saving $key to Firebase ...');
    try {
      await database.saveJsonInUser(key, value);
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }
}
