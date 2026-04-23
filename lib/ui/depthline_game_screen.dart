import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/game_constants.dart';
import '../gameplay/depthline_game.dart';
import '../gameplay/retry_controller.dart';
import '../gameplay/weapon_side.dart';
import '../radar/radar_strip.dart';
import '../stages/sea_stage_definition.dart';
import 'control_overlay.dart';
import 'hud_overlay.dart';
import 'movement_input_overlay.dart';
import 'session_overlay.dart';
import 'web_rotate_banner.dart';

class DepthlineGameScreen extends StatefulWidget {
  const DepthlineGameScreen({super.key});

  @override
  State<DepthlineGameScreen> createState() => _DepthlineGameScreenState();
}

class _DepthlineGameScreenState extends State<DepthlineGameScreen> {
  late DepthlineGame _game;
  late RetryController _retryController;
  bool _hasActiveGame = false;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  void _createSession() {
    final DepthlineGame? previousGame = _hasActiveGame ? _game : null;
    _game = DepthlineGame(stageDefinition: const SeaStageDefinition());
    _hasActiveGame = true;
    if (previousGame != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previousGame.disposeState();
      });
    }
    _retryController = RetryController(
      onRetryRequested: () {
        setState(_createSession);
      },
    );
  }

  @override
  void dispose() {
    if (_hasActiveGame) {
      _game.disposeState();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewPadding = MediaQuery.viewPaddingOf(context);
    final double bottomInset = viewPadding.bottom.clamp(0, 24);
    final double topInset = viewPadding.top.clamp(0, 16);
    final double sideInset =
        (viewPadding.left > viewPadding.right ? viewPadding.left : viewPadding.right)
            .clamp(0, 24);

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool showRotateBanner =
              kIsWeb && constraints.maxHeight > constraints.maxWidth;

          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(sideInset, topInset, sideInset, bottomInset),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: GameConstants.logicalWidth,
                      height: GameConstants.logicalHeight,
                      child: Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: GameWidget<DepthlineGame>(game: _game),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: GameConstants.hudHeight,
                            child: HudOverlay(
                              sessionListenable: _game.sessionNotifier,
                              stageName: _game.stageName,
                            ),
                          ),
                          Positioned(
                            top: GameConstants.hudHeight,
                            left: 0,
                            right: 0,
                            bottom: GameConstants.radarHeight + GameConstants.controlHeight,
                            child: MovementInputOverlay(
                              onDirectionChanged: (double direction) {
                                if (direction == 0) {
                                  _game.stopMovement();
                                  return;
                                }
                                _game.setMovementDirection(direction);
                              },
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: GameConstants.controlHeight,
                            height: GameConstants.radarHeight,
                            child: RadarStrip(
                              contactsListenable: _game.radarNotifier,
                              mapper: _game.radarMapper,
                              sessionListenable: _game.sessionNotifier,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: GameConstants.controlHeight,
                            child: ControlOverlay(
                              sessionListenable: _game.sessionNotifier,
                              onDropLeft: () => _game.tryDropDepthCharge(WeaponSide.left),
                              onDropRight: () => _game.tryDropDepthCharge(WeaponSide.right),
                            ),
                          ),
                          Positioned.fill(
                            child: SessionOverlay(
                              sessionListenable: _game.sessionNotifier,
                              onRetry: _retryController.retry,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (showRotateBanner) const WebRotateBanner(),
            ],
          ),
        },
      ),
    );
  }
}
