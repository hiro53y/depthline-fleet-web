import '../gameplay/wave_definition.dart';

abstract class StageDefinition {
  String get name;
  double get worldWidth;
  double get worldHeight;
  double get waterlineY;
  double get playBottomY;
  double get playerStartX;
  List<double> get depthLanes;
  List<WaveDefinition> get waves;
}
