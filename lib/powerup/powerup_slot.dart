abstract class PowerupSlot {
  bool get isActive;

  void reset();
}

class InactivePowerupSlot implements PowerupSlot {
  @override
  bool get isActive => false;

  @override
  void reset() {
    // TODO: Replace with actual power-up state when the MVP expands.
  }
}
