import 'persisted_state.dart';
import 'save_store.dart';

SaveStore createSaveStore() => MemorySaveStore();

class MemorySaveStore implements SaveStore {
  PersistedState _state = const PersistedState();

  @override
  Future<PersistedState> load() async => _state;

  @override
  Future<void> save(PersistedState state) async {
    _state = state;
  }
}
