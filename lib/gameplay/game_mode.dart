enum GameMode {
  campaign,
  scoreAttack,
}

extension GameModeLabel on GameMode {
  String get title {
    switch (this) {
      case GameMode.campaign:
        return '3ステージ攻略';
      case GameMode.scoreAttack:
        return 'スコアアタック';
    }
  }

  String get description {
    switch (this) {
      case GameMode.campaign:
        return '3つの海域を順番に攻略し、クリア状況を保存します。';
      case GameMode.scoreAttack:
        return '撃沈されるまで続く無限戦闘。敵の出現は毎回変化します。';
    }
  }
}
