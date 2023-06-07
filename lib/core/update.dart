import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:r_upgrade/r_upgrade.dart';
import 'package:toolbox/core/extension/navigator.dart';

import '../data/model/app/update.dart';
import '../data/provider/app.dart';
import '../data/res/build_data.dart';
import '../data/service/app.dart';
import '../data/store/setting.dart';
import '../locator.dart';
import 'utils/platform.dart';
import 'utils/ui.dart';

final _logger = Logger('UPDATE');

const DEFAULT_HOUR_TIME = 60 * 60 * 1000;
const DEFAULT_DAY_TIME = DEFAULT_HOUR_TIME * 24;

String getLeftTime(int expiredTime) {
  DateTime currentTime = DateTime.now();
  if (currentTime.millisecondsSinceEpoch > expiredTime) {
    return "已过期";
  } else {
    int leftTime = expiredTime - currentTime.millisecondsSinceEpoch;

    if (leftTime / DEFAULT_DAY_TIME < 1) {
      return "剩余${(leftTime ~/ DEFAULT_HOUR_TIME).toInt()}小时";
    } else if (leftTime / DEFAULT_DAY_TIME < 370) {
      return "剩余${(leftTime / DEFAULT_DAY_TIME).toInt()}天";
    }
  }
  return "已过期";
}

Future<bool> handleRegistInfo(
    BuildContext context, RegistInfo registInfo, String? code) async {
  final _setting = locator<SettingStore>();
  _setting.maxServers.put(registInfo.serviceNumbers);
  _setting.registed.put(true);
  _setting.registType.put(registInfo.registType);
  _setting.expiredTime.put(registInfo.registTime);
  S s = S.of(context)!;

  switch (registInfo.registType) {
    case 0: //free
    case 1: //week
    case 2: //month
    case 3: //years
      DateTime currentTime = DateTime.now();
      if (currentTime.millisecondsSinceEpoch > registInfo.registTime) {
        _setting.registed.put(false);
        _setting.registType.put(0);
        _setting.maxServers.put(3);
        showRoundDialog(
          context: context,
          child: Text(s.registExpired),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(s.ok),
            )
          ],
        );
        //
        return false;
      } else if (code != null && code.isNotEmpty) {
        _setting.registKey.put(code!);
        return true;
      } else if (registInfo.registType != 0) {
        //not free
        return true;
      } else {
        return false;
      }
    case 4: //all day
      _setting.registKey.put(code!);
      return true;
    default:
      '';
  }
  return false;
}

Future<bool> checkRegistStatus(BuildContext context) async {
  final _setting = locator<SettingStore>();
  //final id = _setting.registed.fetch()! ? _setting.registinfo.fetch() : null;
  String? id = await PlatformDeviceId.getDeviceId;
  String? code = _setting.registKey.fetch();
  final registInfo = await locator<AppService>().getRegist(id, code);
  return handleRegistInfo(context, registInfo, code);
}

Future<bool> isFileAvailable(String url) async {
  try {
    final resp = await Dio().head(url);
    return resp.statusCode == 200;
  } catch (e) {
    _logger.warning('update file not available: $e');
    return false;
  }
}

int getPlatformType() {
  switch (platform) {
    case PlatformType.android:
      return 0;
    case PlatformType.ios:
      return 1;
    case PlatformType.linux:
      return 5;
    case PlatformType.macos:
      return 4;
    case PlatformType.windows:
      return 3;
    case PlatformType.web:
      return 2;
    case PlatformType.unknown:
      return -1;
  }
}

Future<void> doUpdate(BuildContext context, {bool force = false}) async {
  final update = await locator<AppService>()
      .getUpdate("${BuildData.versionCode}", getPlatformType());

  final newest = update.versionCode;
  if (update.versionName == null) {
    _logger.warning('Update not available on $platform');
    return;
  }

  locator<AppProvider>().setNewestBuild(newest);

  if (!force && newest <= BuildData.versionCode) {
    _logger.info('Update ignored due to current: ${BuildData.versionCode}, '
        'update: $newest');
    return;
  }
  _logger.info('Update available: $newest');

  final url = update.downloadLink;

  if (url == null) {
    _logger.warning('Android update file not available');
    return;
  }

  if (isAndroid && !await isFileAvailable(url!)) {
    _logger.warning('Android update file not available');
    return;
  }

  final s = S.of(context)!;

  if (update.versionCode > BuildData.versionCode) {
    showRoundDialog(
      context: context,
      child: Text(s.updateTipTooLow(newest)),
      actions: [
        TextButton(
          onPressed: () => _doUpdate(url!, context, s),
          child: Text(s.ok),
        )
      ],
    );
    return;
  }

  showSnackBarWithAction(
    context,
    '${s.updateTip(newest)} \n${update.updateMessage}',
    s.update,
    () => _doUpdate(url!, context, s),
  );
}

Future<void> _doUpdate(String url, BuildContext context, S s) async {
  if (isAndroid) {
    await RUpgrade.upgrade(
      url,
      fileName: url.split('/').last,
      isAutoRequestInstall: true,
    );
  } else if (isIOS) {
    await RUpgrade.upgradeFromAppStore(BuildData.IOS_APP_ID);
  } else {
    showRoundDialog(
      context: context,
      child: Text(s.platformNotSupportUpdate),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(s.ok),
        )
      ],
    );
  }
}
