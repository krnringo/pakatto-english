import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/master_data.dart';
import '../models/pack.dart';
import '../models/word_card.dart';
import '../services/audio_service.dart';
import '../state/game_state.dart';
import '../widgets/card_face.dart';

/// カード図鑑。パック別タブ(未購入パックも表示=購入導線)、
/// 未収集はシルエット、収集済みタップで拡大+音声再生。
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, this.initialPackId});

  final String? initialPackId;

  @override
  Widget build(BuildContext context) {
    final initialIndex = initialPackId == null
        ? 0
        : allPacks.indexWhere((p) => p.id == initialPackId).clamp(0, allPacks.length - 1);
    return DefaultTabController(
      length: allPacks.length,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8E1),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFB300),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('📖', style: TextStyle(fontSize: 28)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            tabs: [
              for (final pack in allPacks)
                Tab(
                  child: _PackTabLabel(pack: pack),
                ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final pack in allPacks) _PackGrid(pack: pack),
          ],
        ),
      ),
    );
  }
}

class _PackTabLabel extends StatelessWidget {
  const _PackTabLabel({required this.pack});

  final Pack pack;

  @override
  Widget build(BuildContext context) {
    final unlocked = context.watch<GameState>().isUnlocked(pack);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(pack.emoji, style: const TextStyle(fontSize: 24)),
        if (!unlocked) const Text(' 🔒', style: TextStyle(fontSize: 14)),
      ],
    );
  }
}

/// 1パック分のグリッド+進捗表示。未解放パックはシルエット一覧+購入導線。
class _PackGrid extends StatelessWidget {
  const _PackGrid({required this.pack});

  final Pack pack;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final unlocked = state.isUnlocked(pack);
    final collected = state.collectedCount(pack);
    final complete = state.isComplete(pack);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (complete) const Text('👑 ', style: TextStyle(fontSize: 24)),
              Text(
                '$collected / ${pack.totalCards}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        if (!unlocked)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              // 購入導線のプレースホルダ。実際の購入フローは
              // ペアレンタルゲート越し(別仕様)。
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🔒', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text('おとなのひとと いっしょにね',
                      style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: pack.cards.length,
            itemBuilder: (context, index) {
              final card = pack.cards[index];
              final owned = unlocked ? state.ownedCard(card.id) : null;
              if (owned == null) {
                // 未収集(または未解放パック)はシルエット。タップしても音は出ない
                return SilhouetteCard(card: card);
              }
              return GestureDetector(
                onTap: () => _showCardDetail(context, card),
                child: Stack(
                  children: [
                    Positioned.fill(child: CardFace(card: card, wordScale: 0.8)),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: _CountBadge(count: owned.count),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCardDetail(BuildContext context, WordCard card) {
    final audio = context.read<AudioService>();
    audio.speak(card);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final owned = context.read<GameState>().ownedCard(card.id);
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            // 再タップでもう一度音声再生
            onTap: () => audio.speak(card),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: AspectRatio(
                    aspectRatio: 0.75,
                    child: CardFace(card: card, wordScale: 1.6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '🃏 ×${owned?.count ?? 0}   🔁 ${owned?.reviewCount ?? 0}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 所持枚数バッジ(例: ×3)。
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '×$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
