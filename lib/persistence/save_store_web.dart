import 'dart:convert';

import 'package:web/web.dart' as web;

import 'persisted_state.dart';
import 'save_store.dart';

SaveStore createSaveStore() => WebSaveStore();

class WebSaveStore implements SaveStore {
  static const String _key = 'depthline_fleet_state_v1';

  @override
  Future<PersistedState> load() async {
    try {
      final String? raw = web.window.localStorage.getItem(_key);
      if (raw == null || raw.isEmpty) {
        return const PersistedState();
      }

      final Object? decoded = jsonDecode(raw);
      if (decoded is Map) {
        return PersistedState.fromJson(Map<String, Object?>.from(decoded));
      }
      return const PersistedState();
    } catch (_) {
      // Corrupt or old localStorage data must not block startup.
      return const PersistedState();
    }
  }

  @override
  Future<void> save(PersistedState state) async {
    try {
      web.window.localStorage.setItem(_key, jsonEncode(state.toJson()));
    } catch (_) {
      // Storage can be unavailable in private mode or restricted browsers.
    }
  }
}
