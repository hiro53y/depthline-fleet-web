import '../gameplay/wave_definition.dart';

abstract class StageDefinition {
  String get id;
  String get name;
  String get briefing;
  int get stageNumber;
  double get worldWidth;
  double get worldHeight;
  double get waterlineY;
  double get playBottomY;
  double get playerStartX;
  List<double> get depthLanes;
  List<WaveDefinition> get waves;
}
