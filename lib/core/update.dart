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

Future<bool> handleRegistInfo(
    BuildContext context, RegistInfo registInfo, String? code) async {
  final _setting = locator<SettingStore>();
  await _setting.maxServers.put(registInfo.serviceNumbers);
  await _setting.registed.put(true);
  await _setting.registType.put(registInfo.registType);
  S s = S.of(context)!;

  switch (registInfo.registType) {
    case 0: //week
    case 1: //month
    case 2: //years
      DateTime currentTime = DateTime.now();
      if (currentTime.millisecondsSinceEpoch > registInfo.registTime) {
        await _setting.registed.put(false);
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
        return false;
      } else {
        await _setting.registKey.put(code!);
        return true;
      }
      break;
    case 3: //all day
      await _setting.registKey.put(code!);
      return true;
      break;
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

Future<void> doUpdate(BuildContext context, {bool force = false}) async {
  final update = await locator<AppService>().getUpdate();

  final newest = update.build.last.current;
  if (newest == null) {
    _logger.warning('Update not available on $platform');
    return;
  }

  locator<AppProvider>().setNewestBuild(newest);

  if (!force && newest <= BuildData.build) {
    _logger.info('Update ignored due to current: ${BuildData.build}, '
        'update: $newest');
    return;
  }
  _logger.info('Update available: $newest');

  final url = update.url.current!;

  if (isAndroid && !await isFileAvailable(url)) {
    _logger.warning('Android update file not available');
    return;
  }

  final s = S.of(context)!;

  if (update.build.min.current! > BuildData.build) {
    showRoundDialog(
      context: context,
      child: Text(s.updateTipTooLow(newest)),
      actions: [
        TextButton(
          onPressed: () => _doUpdate(url, context, s),
          child: Text(s.ok),
        )
      ],
    );
    return;
  }

  showSnackBarWithAction(
    context,
    '${s.updateTip(newest)} \n${update.changelog.current}',
    s.update,
    () => _doUpdate(url, context, s),
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
