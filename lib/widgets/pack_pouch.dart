import 'package:flutter/material.dart';

import '../models/pack.dart';

/// トレーディングカードの実物パックを模した「パック袋」の見た目。
///
/// 名前欄/イラスト窓/テキスト欄を別々の色帯に分ける「カード」レイアウトでは
/// なく、1枚の絵が全面(edge-to-edge)に広がり、ロゴ・タイトルはその上に
/// オーバーレイで乗る「パック」の構造にする。さらに正面から完全に平らに
/// 見せず、わずかに遠近感をつけて「3D物体を撮った写真」に見せることで、
/// 平面のアイコンに見える(=カードっぽく見える)のを避ける
/// (2026-07-11 デザイン確認: temp/pack-pouch-mockup.png のv3で確定)。
class PackPouch extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // 実物のブースターパックは縦に細長い。
    final height = width * 1.91;
    final topRadius = width * 0.136;
    final bottomRadius = width * 0.091;
    final cLight = Color.lerp(pack.color, Colors.white, 0.5)!;
    final cDarker = Color.lerp(pack.color, Colors.black, 0.5)!;
    final plateColor = Color.lerp(pack.color, Colors.black, 0.62)!;
    final plateColorDark = Color.lerp(pack.color, Colors.black, 0.78)!;

    final pouch = SizedBox(
      width: width,
      height: height,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateY(-0.175) // -10度: 正面から少し傾け、3D物体に見せる
          ..rotateX(0.052), // 3度
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(topRadius),
            topRight: Radius.circular(topRadius),
            bottomLeft: Radius.circular(bottomRadius),
            bottomRight: Radius.circular(bottomRadius),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- 1. ベース: 全面に広がる1枚のグラデーション(継ぎ目なし) ---
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.48, 1],
                    colors: [cLight, pack.color, cDarker],
                  ),
                ),
              ),
              // 背後の光の爆発(ダイナミックな印象、ベースの上に重ねる)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.08, -0.16),
                    radius: 0.52,
                    colors: [
                      Colors.white.withValues(alpha: 0.5),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              // --- 2. 大きな絵文字(全面ブリードの「アートワーク」扱い) ---
              Padding(
                padding: EdgeInsets.only(top: height * 0.06),
                child: Center(
                  child: Text(
                    pack.emoji,
                    style: TextStyle(
                      fontSize: width * 0.673,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // --- 3. 立体感(円柱状の体積を感じさせる明暗、傾きに合わせ右を暗く) ---
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: const [0, 0.22, 0.46, 0.72, 1],
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.white.withValues(alpha: 0.16),
                      Colors.black.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0.24),
                      Colors.black.withValues(alpha: 0.42),
                    ],
                  ),
                ),
              ),
              // --- 4. 上端の熱シール(封をした光沢の帯) ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: height * 0.055,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: height * 0.055 - 1.5,
                left: 0,
                right: 0,
                height: 1.5,
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(color: Colors.black.withValues(alpha: 0.15)),
                ),
              ),
              // --- 5. 下部スクリム(板ではなく「透明→暗」でベースと地続き)+タイトル ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: height * 0.3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.35, 0.78, 1],
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.12),
                        plateColor.withValues(alpha: 0.85),
                        plateColorDark.withValues(alpha: 0.97),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: height * 0.05),
                      child: _OutlinedLogoText(
                        text: pack.nameJa,
                        fontSize: width * 0.145,
                      ),
                    ),
                  ),
                ),
              ),
              // --- 6. 箔のぎらつき: 輪郭のはっきりした細い光の筋を3本 ---
              _Glare(xFraction: 0.30, widthFraction: 0.10, opacity: 0.55,
                  width: width, height: height),
              _Glare(xFraction: 0.72, widthFraction: 0.08, opacity: 0.32,
                  width: width, height: height),
              _Glare(xFraction: 0.10, widthFraction: 0.06, opacity: 0.2,
                  width: width, height: height),
              // --- 7. 薄い内フチ(太い白枠ではなく、素材の縁のハイライトのみ) ---
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final withShadow = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(topRadius),
        boxShadow: [
          BoxShadow(
            color: pack.color.withValues(alpha: enabled ? 0.5 : 0.2),
            blurRadius: 20,
            // 傾きの方向(右に少し傾く)に合わせた非対称な影で、置かれた
            // 3D物体らしさを補強する。
            offset: const Offset(10, 14),
          ),
        ],
      ),
      child: pouch,
    );

    if (enabled) return withShadow;
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

/// 輪郭のはっきりした斜めの光の筋。ぼんやりした帯ではなく箔のぎらつきに
/// 近づけるため、幅を狭くピーク不透明度を高くする。
class _Glare extends StatelessWidget {
  const _Glare({
    required this.xFraction,
    required this.widthFraction,
    required this.opacity,
    required this.width,
    required this.height,
  });

  final double xFraction;
  final double widthFraction;
  final double opacity;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final streakWidth = width * widthFraction;
    return Positioned(
      left: width * xFraction - streakWidth / 2,
      top: -height * 0.3,
      child: Transform.rotate(
        angle: -0.5,
        child: Container(
          width: streakWidth,
          height: height * 1.6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: opacity),
                Colors.white.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
