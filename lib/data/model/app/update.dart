/*
{
    "changelog": {
        "mac": "xxx",
        "ios": "xxx",
        "android": ""
    },
    "build": {
        "min": {
            "mac": 1,
            "ios": 1,
            "android": 1
        },
        "last": {
            "mac": 1,
            "ios": 1,
            "android": 1
        }
    },
    "url": {
        "mac": "https://apps.apple.com/app/id1586449703",
        "ios": "https://apps.apple.com/app/id1586449703",
        "android": "https://cdn3.cust.app/uploads/ServerBox_262_Arm64.apk"
    }
}
*/

import 'dart:convert';

import '/core/utils/platform.dart';

class RegistInfo {
  RegistInfo({
    required this.registName,
    required this.registType,
    required this.registTime,
    required this.serviceNumbers,
  });

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        "registName": registName,
        "registType": registType,
        "registTime": registTime,
        "serviceNumbers": serviceNumbers
      };

  factory RegistInfo.fromJson(Map<String, dynamic> json) => RegistInfo(
      registName: json["registName"],
      registType: json["registType"],
      registTime: json["registTime"],
      serviceNumbers: json["serviceNumbers"]);

  final String registName;
  final int registType;
  final int registTime;
  final int serviceNumbers;
}

class AppInfo {
  AppInfo({
    required this.versionCode,
    this.versionName,
    this.downloadLink,
    //0 weak 1 normal 2 force
    this.updateType,
    this.updateMessage,
    this.updateMessageTitle,
    this.signatureType,
    this.signature,
  });

  final int versionCode;
  String? versionName;
  String? downloadLink;
  int? updateType;
  String? updateMessage;
  String? updateMessageTitle;
  int? signatureType;
  String? signature;

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        "versionCode": versionCode,
        "versionName": versionName,
        "downloadLink": downloadLink,
        "updateType": updateType,
        "updateMessage": updateMessage,
        "updateMessageTitle": updateMessageTitle,
        "signatureType": signatureType,
        "signature": signature,
      };

  factory AppInfo.fromJson(Map<String, dynamic> json) => AppInfo(
      versionCode: json["versionCode"],
      versionName: json["versionName"],
      downloadLink: json["downloadLink"],
      updateType: json["updateType"],
      updateMessage: json["updateMessage"],
      updateMessageTitle: json["updateMessageTitle"],
      signatureType: json["signatureType"],
      signature: json["signature"]);
}
