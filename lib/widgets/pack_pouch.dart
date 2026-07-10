import 'package:flutter/material.dart';

import '../models/pack.dart';

/// トレーディングカードの実物パックを模した「パック袋」の見た目。
/// 単なる角丸カード1枚ではなく、実物のブースターパックと同じ3段構成にする:
///   1. 上部: 銀ホロのヘッダー帯(ブランドの小さなロゴピル+ドット柄)
///   2. 中央: 大きなイラスト面(パックの絵文字+背後の光の爆発)
///   3. 下部: 色付きロゴプレート(パック名を縁取り文字で+ダイヤ形バッジ)
/// さらに縦に細長い比率・中央の折り目の陰影・斜めに流れるホロ光沢で、
/// 実アセット(パック用イラスト)投入までのプレースホルダ品質を底上げする。
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
    // 実物のブースターパックは縦に細長い(角丸カードより明確に縦長)。
    final height = width * 1.85;
    final pack = widget.pack;
    final radius = width * 0.09;

    const headerFraction = 0.17;
    const dividerFraction = 0.014;
    const plateFraction = 0.23;
    final headerHeight = height * headerFraction;
    final dividerHeight = height * dividerFraction;
    final plateHeight = height * plateFraction;
    final artTop = headerHeight + dividerHeight;
    final artHeight = height - artTop - plateHeight;

    final pouch = SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // --- 1. ヘッダー帯(銀ホロ) ---
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: headerHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(Colors.grey.shade100, pack.color, 0.12)!,
                      Color.lerp(Colors.grey.shade400, pack.color, 0.18)!,
                      Color.lerp(Colors.grey.shade200, pack.color, 0.12)!,
                    ],
                  ),
                ),
                child: ClipRect(
                  child: CustomPaint(
                    painter: _DotPatternPainter(
                      color: Colors.black.withValues(alpha: 0.07),
                    ),
                  ),
                ),
              ),
            ),
            // ヘッダーのブランドロゴピル
            Positioned(
              top: headerHeight * 0.28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.06,
                    vertical: width * 0.015,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFF7043)],
                    ),
                    borderRadius: BorderRadius.circular(width * 0.1),
                    border: Border.all(color: Colors.white, width: 1.4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 3),
                    ],
                  ),
                  child: Text(
                    '✨ ぱかっと',
                    style: TextStyle(
                      fontSize: width * 0.058,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // --- 2. 区切りの帯(色ライン) ---
            Positioned(
              top: headerHeight,
              left: 0,
              right: 0,
              height: dividerHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(pack.color, Colors.white, 0.3)!,
                      pack.color,
                      Color.lerp(pack.color, Colors.black, 0.2)!,
                    ],
                  ),
                ),
              ),
            ),
            // --- 3. イラスト面(大きな絵文字+背後の光) ---
            Positioned(
              top: artTop,
              left: 0,
              right: 0,
              height: artHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(pack.color, Colors.white, 0.15)!,
                      pack.color,
                      Color.lerp(pack.color, Colors.black, 0.35)!,
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 背後の光の爆発(ダイナミックな印象を出す)
                    Container(
                      width: width * 0.9,
                      height: width * 0.9,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.55),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                    Text(pack.emoji, style: TextStyle(fontSize: width * 0.5)),
                  ],
                ),
              ),
            ),
            // --- 4. 下部ロゴプレート(色付き)+パック名+ダイヤバッジ ---
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: plateHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(pack.color, Colors.black, 0.25)!,
                      Color.lerp(pack.color, Colors.black, 0.45)!,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OutlinedLogoText(text: pack.nameJa, fontSize: width * 0.16),
                      SizedBox(height: plateHeight * 0.1),
                      Transform.rotate(
                        angle: 0.785398, // 45度: ダイヤ形バッジ
                        child: Container(
                          width: width * 0.15,
                          height: width * 0.15,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: pack.color, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 3),
                            ],
                          ),
                          child: Transform.rotate(
                            angle: -0.785398,
                            child: Center(
                              child: Text(pack.emoji,
                                  style: TextStyle(fontSize: width * 0.075)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // --- 折り目の陰影(縦に細長い袋の丸みを表現) ---
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0, 0.4, 0.55, 1],
                    colors: [
                      Colors.black.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.02),
                      Colors.black.withValues(alpha: 0.14),
                    ],
                  ),
                ),
              ),
            ),
            // --- ホロの光沢: 斜めの帯が定期的に流れる ---
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shimmer,
                builder: (context, _) {
                  final dx = -width + _shimmer.value * (width * 2.6);
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Container(
                        width: width * 0.45,
                        height: height * 2.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.32),
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
            // --- 外枠(銀のフチ) ---
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9), width: 3),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final withShadow = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
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

/// ヘッダー帯に薄く敷く、規則的な小さいドット柄(箔押しの質感を出す)。
class _DotPatternPainter extends CustomPainter {
  const _DotPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 12.0;
    const dotRadius = 1.6;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// 白フチ(縁取り)付きの太字ロゴ風テキスト。実物パックのタイトル
/// レタリングのような「ぷっくり」した見た目にする。
class _OutlinedLogoText extends StatelessWidget {
  const _OutlinedLogoText({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.16
              ..color = Colors.black.withValues(alpha: 0.55),
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
