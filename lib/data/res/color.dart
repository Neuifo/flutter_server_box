import 'package:flutter/material.dart';
import 'package:toolbox/data/store/setting.dart';
import 'package:toolbox/locator.dart';

import '../model/app/dynamic_color.dart';

Color primaryColor = Color(locator<SettingStore>().primaryColor.fetch()!);

final contentColor = DynamicColor(Colors.black87, Colors.white70);
final bgColor = DynamicColor(Colors.white, Colors.black);
final progressColor = DynamicColor(Colors.black12, Colors.white10);

final SERVER_STATUS_COLOR = <List<Color>>[
  [
    const Color.fromRGBO(223, 250, 92, 1),
    const Color.fromRGBO(129, 250, 112, 1),
  ],
];
