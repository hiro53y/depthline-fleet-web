import 'dart:convert';
import 'dart:html' as html;

import 'persisted_state.dart';
import 'save_store.dart';

SaveStore createSaveStore() => WebSaveStore();

class WebSaveStore implements SaveStore {
  static const String _key = 'depthline_fleet_state_v1';

  @override
  Future<PersistedState> load() async {
    final String? raw = html.window.localStorage[_key];
    if (raw == null || raw.isEmpty) {
      return const PersistedState();
    }

    final Object? decoded = jsonDecode(raw);
    if (decoded is Map) {
      return PersistedState.fromJson(Map<String, Object?>.from(decoded));
    }
    return const PersistedState();
  }

  @override
  Future<void> save(PersistedState state) async {
    html.window.localStorage[_key] = jsonEncode(state.toJson());
  }
}
