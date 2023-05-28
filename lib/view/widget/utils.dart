import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomDockedFloatingActionButtonLocation extends _DockedFloatingActionButtonLocation {
  const CustomDockedFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    //final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;
    //return Offset(fabX, getDockedY(scaffoldGeometry));
    return Offset((scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width*1.5),
        (scaffoldGeometry.scaffoldSize.height*0.9 - scaffoldGeometry.floatingActionButtonSize.height));
  }
}

abstract class _DockedFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _DockedFloatingActionButtonLocation();
  @protected
  double getDockedY(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double contentBottom = scaffoldGeometry.contentTop;
    final double appBarHeight = scaffoldGeometry.bottomSheetSize.height;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double snackBarHeight = scaffoldGeometry.snackBarSize.height;

    double fabY = contentBottom - fabHeight / 2.0;
    if (snackBarHeight > 0.0)
      fabY = math.min(fabY, contentBottom - snackBarHeight - fabHeight - kFloatingActionButtonMargin);
    if (appBarHeight > 0.0)
      fabY = math.min(fabY, contentBottom - appBarHeight - fabHeight / 2.0);

    final double maxFabY = scaffoldGeometry.scaffoldSize.height - fabHeight;
    return math.min(maxFabY, fabY);
  }
}