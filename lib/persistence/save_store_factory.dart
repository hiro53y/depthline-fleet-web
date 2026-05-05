import 'save_store.dart';
import 'save_store_memory.dart'
    if (dart.library.html) 'save_store_web.dart' as platform;

SaveStore createPlatformSaveStore() => platform.createSaveStore();
