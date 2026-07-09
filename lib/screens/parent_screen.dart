import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/master_data.dart';
import '../state/game_state.dart';

/// 親向け簡易進捗画面(v1はこれだけ: パック別収集数・総開封回数・総復習回数)。
class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    return Scaffold(
      appBar: AppBar(title: const Text('おうちのかた向け')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('あつめたカード',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          for (final pack in allPacks)
            Card(
              child: ListTile(
                leading: Text(pack.emoji, style: const TextStyle(fontSize: 28)),
                title: Text('${pack.nameJa}(${pack.nameEn})'),
                trailing: Text(
                  state.isUnlocked(pack)
                      ? '${state.collectedCount(pack)} / ${pack.totalCards}'
                      : '未購入',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Text('🎁', style: TextStyle(fontSize: 28)),
              title: const Text('パックをひらいた回数'),
              trailing: Text(
                '${state.totalOpenCount} 回',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Text('🔁', style: TextStyle(fontSize: 28)),
              title: const Text('ふくしゅうした回数'),
              subtitle: const Text('同じカードをもう一度ひいて聞き返した回数'),
              trailing: Text(
                '${state.totalReviewCount} 回',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
