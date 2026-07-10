import 'package:flutter/material.dart';

import '../models/stamina_state.dart';

/// スタミナ表示(例: ⚡⚡ = 満タン)。ホーム・パック袋選択画面で共用。
class StaminaChip extends StatelessWidget {
  const StaminaChip({super.key, required this.stamina});

  final int stamina;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < StaminaState.maxStamina; i++)
            Opacity(
              opacity: i < stamina ? 1 : 0.2,
              child: const Text('⚡', style: TextStyle(fontSize: 24)),
            ),
        ],
      ),
    );
  }
}
