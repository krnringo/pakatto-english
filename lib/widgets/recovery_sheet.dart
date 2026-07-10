import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/game_state.dart';

/// スタミナ0のとき: 次の回復までの残り時間を絵的に表示する(文字最小限)。
/// ホーム・パック袋選択画面の両方から呼ばれる共通処理。
void showStaminaRecoverySheet(BuildContext context) {
  final state = context.read<GameState>();
  final remaining = state.timeToNextRecovery;
  if (remaining == null) return;
  final h = remaining.inHours;
  final m = remaining.inMinutes % 60;
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            '⚡ あと ${h > 0 ? '$h:' : ''}${m.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('😴💤', style: TextStyle(fontSize: 32)),
        ],
      ),
    ),
  );
}
