import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/common/platform_info.dart';
import 'package:wonders/logic/json_storage_service.dart';

class SettingsLogic {
  JsonStorageManagerService get storage => GetIt.I.get<JsonStorageManagerService>(instanceName: 'settings');

  late final hasCompletedOnboarding = ValueNotifier<bool>(false)..addListener(scheduleSave);
  late final hasDismissedSearchMessage = ValueNotifier<bool>(false)..addListener(scheduleSave);
  late final isSearchPanelOpen = ValueNotifier<bool>(true)..addListener(scheduleSave);
  late final currentLocale = ValueNotifier<String?>(null)..addListener(scheduleSave);

  final bool useBlurs = !PlatformInfo.isAndroid;

  /// Disables schedule save to avoid it being called when copying value
  bool _copyingFromJson = false;

  Future<void> load() async {
    final loadedValue = await storage.load();
    _copyFromJson(loadedValue);
  }

  Future<void> sync() async {
    final loadedValue = await storage.load();
    if (loadedValue.isNotEmpty) {
      final oldLocale = currentLocale.value;
      _copyFromJson(loadedValue);
      if (oldLocale != currentLocale.value) {
        final newLocale = Locale(currentLocale.value == 'en' ? 'zh' : 'en');
        await settingsLogic.changeLocale(newLocale);
      }
    } else {
      scheduleSave();
    }
  }

  Future<void> scheduleSave() async {
    if (!_copyingFromJson) {
      final valueToSave = _toJson();
      await storage.save(valueToSave);
    }
  }

  void _copyFromJson(Map<String, dynamic> value) {
    _copyingFromJson = true;
    hasCompletedOnboarding.value = value['hasCompletedOnboarding'] ?? false;
    hasDismissedSearchMessage.value = value['hasDismissedSearchMessage'] ?? false;
    currentLocale.value = value['currentLocale'];
    isSearchPanelOpen.value = value['isSearchPanelOpen'] ?? false;
    _copyingFromJson = false;
  }

  Map<String, dynamic> _toJson() {
    return {
      'hasCompletedOnboarding': hasCompletedOnboarding.value,
      'hasDismissedSearchMessage': hasDismissedSearchMessage.value,
      'currentLocale': currentLocale.value,
      'isSearchPanelOpen': isSearchPanelOpen.value,
    };
  }

  Future<void> changeLocale(Locale value) async {
    currentLocale.value = value.languageCode;
    await localeLogic.loadIfChanged(value);
    // Re-init controllers that have some cached data that is localized
    wondersLogic.init();
    timelineLogic.init();
  }
}
