/// スタミナ状態(永続化対象)。
///
/// 現在値は保存値 + 経過時間からの回復分を都度計算する(タイマー不要)。
/// 仕様: 回復4時間/1回、上限2。最終消費日時からの経過で回復する。
class StaminaState {
  StaminaState({
    required this.storedStamina,
    required this.lastConsumedAt,
  });

  static const int maxStamina = 2;
  static const Duration recoveryInterval = Duration(hours: 4);

  /// 最終消費時点でのスタミナ値。
  final int storedStamina;

  /// 最終消費日時。一度も消費していない場合は null(=満タン)。
  final DateTime? lastConsumedAt;

  factory StaminaState.initial() =>
      StaminaState(storedStamina: maxStamina, lastConsumedAt: null);

  /// [now] 時点の実効スタミナ(回復分を加算し上限でクランプ)。
  int currentAt(DateTime now) {
    final last = lastConsumedAt;
    if (last == null) return maxStamina;
    final recovered =
        now.difference(last).inMinutes ~/ recoveryInterval.inMinutes;
    return (storedStamina + recovered).clamp(0, maxStamina);
  }

  /// [now] 時点の「次の1回復までの残り時間」。満タンなら null。
  Duration? timeToNextRecovery(DateTime now) {
    final last = lastConsumedAt;
    if (last == null || currentAt(now) >= maxStamina) return null;
    final elapsed = now.difference(last);
    final intervalMin = recoveryInterval.inMinutes;
    final remainderMin = elapsed.inMinutes % intervalMin;
    return Duration(minutes: intervalMin - remainderMin);
  }

  /// [now] 時点で1消費した新しい状態を返す。スタミナ0なら [StateError]。
  StaminaState consume(DateTime now) {
    final current = currentAt(now);
    if (current <= 0) {
      throw StateError('stamina is empty');
    }
    return StaminaState(storedStamina: current - 1, lastConsumedAt: now);
  }

  Map<String, dynamic> toJson() => {
        'storedStamina': storedStamina,
        'lastConsumedAt': lastConsumedAt?.toIso8601String(),
      };

  factory StaminaState.fromJson(Map<String, dynamic> json) => StaminaState(
        storedStamina: json['storedStamina'] as int,
        lastConsumedAt: json['lastConsumedAt'] == null
            ? null
            : DateTime.parse(json['lastConsumedAt'] as String),
      );
}
