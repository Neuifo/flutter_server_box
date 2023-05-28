import 'dart:convert';

import 'package:dio/dio.dart';

import '../model/app/update.dart';
import '../res/url.dart';

class AppService {
  Future<AppUpdate> getUpdate() async {
    final resp = await Dio().get('$baseUrl/update.json');
    return AppUpdate.fromJson(resp.data);
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
