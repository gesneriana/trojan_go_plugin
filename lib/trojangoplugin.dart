import 'dart:async';
import 'dart:io';
import "package:path_provider/path_provider.dart";
import 'package:flutter/services.dart';

class Trojangoplugin {
  static const MethodChannel _channel = const MethodChannel('trojangoplugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<bool> get start async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String dir = appDocDir.path;
    var args = {"configRootDir": dir};
    return await _channel.invokeMethod('start', args);
  }

  static Future<bool> get startVpn async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String dir = appDocDir.path;
    var args = {"configRootDir": dir};
    return await _channel.invokeMethod('startVpn', args);
  }

  static Future<bool> get stop async {
    return await _channel.invokeMethod('stop');
  }

  static Future<bool> get stopVpn async {
    return await _channel.invokeMethod('stopVpn');
  }

  static Future<String> get platformInfo async {
    final String platform = await _channel.invokeMethod('getPlatformInfo');
    return platform;
  }
}
