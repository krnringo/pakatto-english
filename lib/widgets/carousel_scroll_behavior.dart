import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// タッチ(実機)に加えマウス・トラックパッドのドラッグでもスクロールを
/// 許可する(flutter run -d chrome やデスクトップでの操作・検証のため)。
class DragEverywhereScrollBehavior extends MaterialScrollBehavior {
  const DragEverywhereScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
