import 'package:dio/dio.dart';

import '../model/app/update.dart';
import '../res/url.dart';

class AppService {
  Future<AppUpdate> getUpdate() async {
    final resp = await Dio().get('$baseUrl/update.json');
    return AppUpdate.fromJson(resp.data);
  }
}
