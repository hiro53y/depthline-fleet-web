import 'persisted_state.dart';

abstract class SaveStore {
  Future<PersistedState> load();

  Future<void> save(PersistedState state);
}
