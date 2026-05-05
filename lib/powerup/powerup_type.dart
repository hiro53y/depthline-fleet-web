enum PowerupType {
  rapidReload,
  shield,
  repair,
}

extension PowerupTypeLabel on PowerupType {
  String get label {
    switch (this) {
      case PowerupType.rapidReload:
        return 'RAPID';
      case PowerupType.shield:
        return 'SHIELD';
      case PowerupType.repair:
        return 'REPAIR';
    }
  }
}
