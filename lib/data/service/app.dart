import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/app/update.dart';
import '../res/url.dart';

class AppService {
  Future<AppInfo> getUpdate(String versionCode, int mobileType) async {
    final resp = await Dio().get('$baseUrl/api/checkUpdate', queryParameters: {
      'versionCode': versionCode,
      'mobileType': mobileType
    });
    return AppInfo.fromJson(json.decode(resp.data));
  }

  Future<RegistInfo> getRegist(String? id, String? code) async {
    final registInfo = await Dio().get('$baseUrl/api/get',
        queryParameters: code == null || code.isEmpty
            ? id == null || id.isEmpty
                ? null
                : {'id': id}
            : {'id': id, 'code': code});
    return RegistInfo.fromJson(json.decode(registInfo.data));
  }
}
