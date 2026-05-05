import 'package:flutter/material.dart';

import '../gameplay/game_mode.dart';
import '../persistence/game_save_data.dart';
import '../stages/stage_catalog.dart';
import '../stages/stage_definition.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({
    required this.saveData,
    required this.selectedGameMode,
    required this.selectedStageId,
    required this.onGameModeSelected,
    required this.onStageSelected,
    required this.onStart,
    required this.onSettings,
    super.key,
  });

  final GameSaveData saveData;
  final GameMode selectedGameMode;
  final String selectedStageId;
  final ValueChanged<GameMode> onGameModeSelected;
  final ValueChanged<String> onStageSelected;
  final VoidCallback onStart;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final StageDefinition selectedStage = StageCatalog.byId(selectedStageId);
    final bool scoreAttack = selectedGameMode == GameMode.scoreAttack;
    return Scaffold(
      backgroundColor: const Color(0xFF020B11),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF061018),
                Color(0xFF0E2B33),
                Color(0xFF07131C),
              ],
            ),
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 780;
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 18 : 34,
                      vertical: compact ? 16 : 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _TitleHeader(
                          highScore: saveData.highScore,
                          scoreAttackHighScore: saveData.scoreAttackHighScore,
                          onSettings: onSettings,
                        ),
                        SizedBox(height: compact ? 18 : 30),
                        _ModeSelector(
                          selectedMode: selectedGameMode,
                          onSelected: onGameModeSelected,
                        ),
                        SizedBox(height: compact ? 16 : 22),
                        Text(
                          scoreAttack
                              ? 'やられるまで続く特別戦闘。出現方向、深度、速度、魚雷圧力が毎回変化します。'
                              : selectedStage.briefing,
                          style: const TextStyle(
                            color: Color(0xFFC6E8F2),
                            fontSize: 16,
                            height: 1.35,
                          ),
                        ),
                        if (!scoreAttack) ...<Widget>[
                          SizedBox(height: compact ? 16 : 22),
                          _StageGrid(
                            saveData: saveData,
                            selectedStageId: selectedStageId,
                            onStageSelected: onStageSelected,
                          ),
                        ],
                        SizedBox(height: compact ? 18 : 28),
                        FilledButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(scoreAttack ? 'スコアアタック開始' : '出撃'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2B8BA3),
                            foregroundColor: const Color(0xFFF4FCFF),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            textStyle: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TitleHeader extends StatelessWidget {
  const _TitleHeader({
    required this.highScore,
    required this.scoreAttackHighScore,
    required this.onSettings,
  });

  final int highScore;
  final int scoreAttackHighScore;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 720;
        final Widget titleBlock = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'DEPTHLINE FLEET',
              style: TextStyle(
                color: Color(0xFFF2FBFF),
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              '海上艦で深度レーンを制圧する短時間アクション',
              style: TextStyle(
                color: Color(0xFF8DC9D9),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
        final Widget settingsButton = IconButton.filledTonal(
          onPressed: onSettings,
          icon: const Icon(Icons.tune_rounded),
          tooltip: '設定',
        );
        final Widget scores = Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _HighScoreBadge(label: 'STAGE BEST', score: highScore),
            _HighScoreBadge(label: 'ATTACK BEST', score: scoreAttackHighScore),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: titleBlock),
                  const SizedBox(width: 12),
                  settingsButton,
                ],
              ),
              const SizedBox(height: 14),
              scores,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: titleBlock),
            const SizedBox(width: 18),
            scores,
            const SizedBox(width: 12),
            settingsButton,
          ],
        );
      },
    );
  }
}

class _HighScoreBadge extends StatelessWidget {
  const _HighScoreBadge({
    required this.label,
    required this.score,
  });

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x3310A7C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x553BB2D0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8BD5E7),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              score.toString(),
              style: const TextStyle(
                color: Color(0xFFFFD56B),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selectedMode,
    required this.onSelected,
  });

  final GameMode selectedMode;
  final ValueChanged<GameMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 680;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: <Widget>[
            for (final GameMode mode in GameMode.values)
              SizedBox(
                width: compact ? constraints.maxWidth : (constraints.maxWidth - 14) / 2,
                child: _ModeTile(
                  mode: mode,
                  selected: selectedMode == mode,
                  onTap: () => onSelected(mode),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final GameMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool scoreAttack = mode == GameMode.scoreAttack;
    return Material(
      color: selected ? const Color(0xFF123746) : const Color(0xFF0B1B25),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 112,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? (scoreAttack ? const Color(0xFFFFD56B) : const Color(0xFF6FE7FF))
                  : const Color(0x443BB2D0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                scoreAttack ? Icons.all_inclusive_rounded : Icons.flag_rounded,
                color: scoreAttack ? const Color(0xFFFFD56B) : const Color(0xFF9DE9FF),
                size: 36,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      mode.title,
                      style: const TextStyle(
                        color: Color(0xFFF2FBFF),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mode.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9BCFDC),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageGrid extends StatelessWidget {
  const _StageGrid({
    required this.saveData,
    required this.selectedStageId,
    required this.onStageSelected,
  });

  final GameSaveData saveData;
  final String selectedStageId;
  final ValueChanged<String> onStageSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 720;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: <Widget>[
            for (final StageDefinition stage in StageCatalog.allStages)
              SizedBox(
                width: compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 28) / 3,
                child: _StageTile(
                  stage: stage,
                  selected: selectedStageId == stage.id,
                  unlocked: saveData.isStageUnlocked(stage.id),
                  onTap: () => onStageSelected(stage.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.stage,
    required this.selected,
    required this.unlocked,
    required this.onTap,
  });

  final StageDefinition stage;
  final bool selected;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.48,
      child: Material(
        color: selected ? const Color(0xFF123746) : const Color(0xFF0B1B25),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: unlocked ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 132,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? const Color(0xFF6FE7FF) : const Color(0x443BB2D0),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      '0${stage.stageNumber}',
                      style: const TextStyle(
                        color: Color(0xFFFFD56B),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      unlocked ? Icons.radar_rounded : Icons.lock_rounded,
                      color: const Color(0xFF9DE9FF),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  stage.name,
                  style: const TextStyle(
                    color: Color(0xFFF2FBFF),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stage.briefing,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9BCFDC),
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
