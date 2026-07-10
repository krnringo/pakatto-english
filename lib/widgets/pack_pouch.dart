import 'package:flutter/material.dart';

import '../models/pack.dart';

/// ポケポケ準拠の「パック袋」の見た目。単色の平坦なカードではなく、
/// 光沢グラデーション+上部の折り返し(襟)+エンブレムバッジ+斜めに流れる
/// ホロの光沢(shimmer)で安っぽさを補う。実アセット(パック用イラスト)
/// 投入までのプレースホルダ品質を底上げする目的。
class PackPouch extends StatefulWidget {
  const PackPouch({
    super.key,
    required this.pack,
    required this.enabled,
    this.width = 200,
  });

  final Pack pack;
  final bool enabled;
  final double width;

  @override
  State<PackPouch> createState() => _PackPouchState();
}

class _PackPouchState extends State<PackPouch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = width * 1.42;
    final pack = widget.pack;

    final pouch = SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 本体: 3階調グラデーションで立体感のある光沢を出す
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0, 0.55, 1],
                    colors: [
                      Color.lerp(pack.color, Colors.white, 0.45)!,
                      pack.color,
                      Color.lerp(pack.color, Colors.black, 0.3)!,
                    ],
                  ),
                ),
              ),
            ),
            // ホロの光沢: 斜めの帯が定期的に流れる
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmer,
                builder: (context, _) {
                  final dx = -width + _shimmer.value * (width * 2.6);
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: Transform.rotate(
                      angle: -0.55,
                      child: Container(
                        width: width * 0.55,
                        height: height * 2.4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.38),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // 上部の折り返し(襟)+シーム線
            Positioned(
              top: 0,
              left: width * 0.1,
              right: width * 0.1,
              child: Container(
                height: height * 0.14,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                  border: const Border(
                    bottom: BorderSide(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ),
            // エンブレムバッジ(絵文字を白い丸バッジに載せて質感を上げる)
            Positioned(
              top: height * 0.22,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: width * 0.48,
                  height: width * 0.48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: pack.color, width: 3),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3)),
                    ],
                  ),
                  child: Center(
                    child:
                        Text(pack.emoji, style: TextStyle(fontSize: width * 0.24)),
                  ),
                ),
              ),
            ),
            // パック名(下部)
            Positioned(
              bottom: height * 0.1,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  pack.nameJa,
                  style: TextStyle(
                    fontSize: width * 0.09,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
            // 外枠(白フチ)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 4),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final withShadow = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: pack.color.withValues(alpha: widget.enabled ? 0.5 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: pouch,
    );

    if (widget.enabled) return withShadow;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0, 0, 0, 1, 0,
      ]),
      child: withShadow,
    );
  }
}
