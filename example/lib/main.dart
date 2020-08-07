import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:trojangoplugin/trojangoplugin.dart';
import "package:path_provider/path_provider.dart";
import 'package:trojangoplugin_example/model/client_config.dart';
import 'config.dart';
import 'help.dart';
import 'model/trojan_config.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String nodeLable = "";
  var trojanAllConfigs = TrojanClientConfig();
  ClientConfig clientConfig;
  String trojanClientConfigJson = "";
  String listenInfo = "";
  bool isOpenVpnService = false;
  Color vpnButtonColor = Colors.lightBlue;
  bool isStartedProxy = false;

  @override
  void initState() {
    initPlatformState();
    super.initState();
  }

  void changeMuxState(bool val) {
    setState(() {
      clientConfig?.mux?.enabled = val;
    });
  }

  Future<void> saveTrojanClientConfig(BuildContext c) async {
    if (nodeLable == null || nodeLable.trim().length == 0) {
      final snackBar = new SnackBar(content: new Text('节点名称不能为空'));
      Scaffold.of(c).showSnackBar(snackBar);
      return;
    }

    // 保存配置到文件
    trojanClientConfigJson = jsonEncode(clientConfig);
    print(trojanClientConfigJson);
    var dir = await getApplicationDocumentsDirectory();
    var clientConfigFile = File("${dir.path}/config.json");
    await clientConfigFile.writeAsString(trojanClientConfigJson);

    // 保存到节点列表文件中
    if (trojanAllConfigs.configMaps == null) {
      trojanAllConfigs.configMaps = new Map<String, ClientConfig>();
    }
    trojanAllConfigs.currentNodeLable = nodeLable;
    trojanAllConfigs.configMaps[nodeLable] = clientConfig;
    var allTrojanConfigsJson = jsonEncode(trojanAllConfigs);
    var trojantConfigFile = File("${dir.path}/trojan_config.json");
    await trojantConfigFile.writeAsString(allTrojanConfigsJson);
    print(allTrojanConfigsJson);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Trojangoplugin.platformInfo;

      trojanClientConfigJson =
          await DefaultAssetBundle.of(context).loadString("assets/config.json");
      clientConfig = ClientConfig.fromJson(jsonDecode(trojanClientConfigJson));

      var dir = await getApplicationDocumentsDirectory();
      var clientConfigFile = File("${dir.path}/config.json");
      // 启动代理之前必须先把配置文件写入到app包的文档目录, assets中的资源文件libgojni.so无法读取
      if (!clientConfigFile.existsSync()) {
        await clientConfigFile.writeAsString(trojanClientConfigJson);

        var geoipConfig =
            await DefaultAssetBundle.of(context).load("assets/geoip.dat");
        var geoipDataFile = File("${dir.path}/geoip.dat");
        await geoipDataFile.writeAsBytes(geoipConfig.buffer.asUint8List(0));

        var geositeConfig =
            await DefaultAssetBundle.of(context).load("assets/geosite.dat");
        var geositeDataFile = File("${dir.path}/geosite.dat");
        await geositeDataFile.writeAsBytes(geositeConfig.buffer.asUint8List(0));
      } else {
        trojanClientConfigJson = await clientConfigFile.readAsString();
        clientConfig =
            ClientConfig.fromJson(jsonDecode(trojanClientConfigJson));
      }

      var trojantConfigFile = File("${dir.path}/trojan_config.json");
      if (trojantConfigFile.existsSync()) {
        var allTrojanConfigsJson = await trojantConfigFile.readAsString();
        trojanAllConfigs =
            TrojanClientConfig.fromJson(jsonDecode(allTrojanConfigsJson));
        nodeLable = trojanAllConfigs.currentNodeLable;
      }
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Trojan Go example app'),
          actions: <Widget>[
            Builder(
              builder: (icoCtx) => IconButton(
                icon: Icon(Icons.link),
                tooltip: "导入Trojan URL",
                onPressed: () async {
                  var data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data != null) {
                    // 分析trojan url, trojan go 格式url以trojan-go://开头
                    var uri = data.text;
                    if (uri.startsWith("trojan://")) {
                      // 禁用mux和websocket等trojan go特性
                      log(uri);
                      var urlString = uri
                          .replaceFirst(new RegExp(r'trojan://'), "")
                          .split("?")
                          .first;
                      log(urlString);

                      setState(() {
                        clientConfig.password[0] = urlString.split('@').first;
                        clientConfig.mux.enabled = false;
                        clientConfig.websocket.enabled = false;
                        clientConfig.websocket.path = "";
                        clientConfig.websocket.hostname = "";
                        var hostPortString = urlString.split('@').last;
                        clientConfig.remoteAddr =
                            hostPortString.split(":").first;
                        clientConfig.remotePort =
                            int.tryParse(hostPortString.split(":").last);
                        clientConfig.ssl.sni = clientConfig.remoteAddr;
                        nodeLable = hostPortString;
                      });
                      await saveTrojanClientConfig(icoCtx);
                    } else if (uri.startsWith("trojan-go://")) {
                      // 默认启用mux, 服务器端默认开启, 客户端可以自己选择是否启用
                      log(uri);
                      var urlString = uri
                          .replaceFirst(new RegExp(r'trojan-go://'), "")
                          .split("?")
                          .first;
                      log(urlString);
                      var pathString = uri
                          .replaceFirst(new RegExp(r'trojan-go://'), "")
                          .split("?")
                          .last;
                      log(pathString);

                      setState(() {
                        clientConfig.password[0] = urlString.split('@').first;
                        clientConfig.mux.enabled = true;

                        var hostPortString = urlString.split('@').last;
                        clientConfig.remoteAddr =
                            hostPortString.split(":").first;
                        clientConfig.remotePort =
                            int.tryParse(hostPortString.split(":").last);
                        clientConfig.ssl.sni = clientConfig.remoteAddr;

                        pathString.split("&").forEach((element) {
                          if (element.startsWith("type")) {
                            var protocolType = element.split("=").last;
                            if (protocolType == "ws") {
                              clientConfig.websocket.enabled = true;
                              clientConfig.websocket.hostname =
                                  clientConfig.remoteAddr;
                            }
                          } else if (element.startsWith("path")) {
                            var path = element.split("=").last;
                            clientConfig.websocket.path =
                                Uri.decodeComponent(path);
                          }
                        });
                        if (clientConfig.websocket.path.length == 0 ||
                            clientConfig.websocket.hostname.length == 0) {
                          clientConfig.websocket.enabled = false;
                          clientConfig.websocket.path = "";
                          clientConfig.websocket.hostname = "";
                        }

                        nodeLable = hostPortString;
                      });
                      await saveTrojanClientConfig(icoCtx);
                    } else {
                      Scaffold.of(icoCtx).showSnackBar(SnackBar(
                        content: Text("请先复制trojan://或者trojan-go://开头的资源定位URI"),
                      ));
                    }
                  } else {
                    log("粘贴板内容为null");
                  }
                },
              ),
            ),
            Builder(
              builder: (menuCtx) => Container(
                margin: EdgeInsets.fromLTRB(0, 0, 30, 0),
                child: GestureDetector(
                  child: Icon(Icons.menu),
                  onTap: () {
                    // 弹出菜单, 切换配置(跳转到列表页), 导出当前配置为trojan:// uri, 生成配置为二维码, 管理订阅链接等等
                    showMenu(
                      context: menuCtx,
                      position: RelativeRect.fromLTRB(500, 76, 10, 10),
                      items: [
                        PopupMenuItem(
                          child: FlatButton(
                            child: Text("切换配置"),
                            onPressed: () {
                              print('打开切换配置页面');
                              // 打开配置列表页面
                              Navigator.push(
                                menuCtx,
                                MaterialPageRoute(
                                  builder: (c) => TrojanClientConfigPage(),
                                ),
                              ).then((value) async {
                                Navigator.pop(menuCtx);
                                await initPlatformState();
                              });
                            },
                          ),
                        ),
                        PopupMenuItem(
                          child: FlatButton(
                            child: Text(isStartedProxy ? "停止代理" : "启动代理"),
                            onPressed: isOpenVpnService
                                ? null
                                : () async {
                                    print('使用代理模式上网');
                                    // 启动代理
                                    if (isStartedProxy) {
                                      await Trojangoplugin.stop;
                                      listenInfo = "";
                                    } else {
                                      await Trojangoplugin.start;
                                      listenInfo =
                                          " ${clientConfig.localAddr}:${clientConfig.localPort} ";
                                    }
                                    Navigator.pop(menuCtx);
                                    setState(() {
                                      isStartedProxy = !isStartedProxy;
                                    });
                                  },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: <Widget>[
                Container(
                  child: Row(
                    children: <Widget>[
                      Text(
                        'platform: $_platformVersion ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        "\tlisten: $listenInfo",
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  margin: EdgeInsets.fromLTRB(10, 10, 5, 5),
                ),
                Container(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '节点名称(标签),例如: 日本1号节点',
                      icon: Icon(Icons.label),
                    ),
                    controller: TextEditingController.fromValue(
                      TextEditingValue(text: nodeLable),
                    ),
                    onChanged: (value) {
                      nodeLable = value;
                    },
                  ),
                  margin: EdgeInsets.fromLTRB(10, 10, 5, 5),
                ),
                Container(
                  child: TextField(
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: '主机名,不包含https://',
                      icon: Icon(Icons.domain),
                    ),
                    controller: TextEditingController.fromValue(
                      TextEditingValue(text: clientConfig?.remoteAddr ?? ""),
                    ),
                    onChanged: (value) {
                      clientConfig.remoteAddr = value;
                      clientConfig.websocket?.hostname = value;
                      clientConfig.ssl?.sni = value;
                    },
                  ),
                  margin: EdgeInsets.fromLTRB(10, 10, 5, 5),
                ),
                Container(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          inputFormatters: [
                            WhitelistingTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            hintText: '远程端口',
                            icon: Icon(Icons.fiber_manual_record),
                          ),
                          controller: TextEditingController.fromValue(
                            TextEditingValue(
                                text: "${clientConfig?.remotePort}"),
                          ),
                          onChanged: (value) {
                            clientConfig.remotePort = int.tryParse(value);
                          },
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          inputFormatters: [
                            WhitelistingTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            hintText: '本地端口',
                            icon: Icon(Icons.fiber_manual_record),
                          ),
                          controller: TextEditingController.fromValue(
                            TextEditingValue(
                                text: "${clientConfig?.localPort}"),
                          ),
                          onChanged: (value) {
                            clientConfig.localPort = int.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  margin: EdgeInsets.fromLTRB(10, 10, 5, 5),
                ),
                Container(
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '密码',
                      icon: Icon(Icons.account_circle),
                    ),
                    onTap: () => {print("开始编辑")},
                    onEditingComplete: () => {print('编辑完成')},
                    controller: TextEditingController.fromValue(
                      TextEditingValue(
                          text: clientConfig?.password != null
                              ? clientConfig?.password[0]
                              : ""),
                    ),
                    onChanged: (value) {
                      clientConfig?.password[0] = value;
                    },
                  ),
                  margin: EdgeInsets.fromLTRB(10, 10, 5, 5),
                ),
                Container(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: ListTile(
                          title: Switch(
                            value: clientConfig?.mux?.enabled ?? true,
                            onChanged: changeMuxState,
                          ),
                          leading: Text("mux"),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'ws path : /web',
                            icon: Icon(Icons.web),
                          ),
                          controller: TextEditingController.fromValue(
                            TextEditingValue(
                                text: "${clientConfig?.websocket?.path}"),
                          ),
                          onChanged: (value) {
                            if (value == null ||
                                value.trim().length == 0 ||
                                value.trim() == "/") {
                              clientConfig?.websocket?.enabled =
                                  false; // oppo手机清空输入框, 但是value会是 / , 可能是flutter框架导致的
                            } else {
                              clientConfig?.websocket?.enabled = true;
                              clientConfig?.websocket?.path = value;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  margin: EdgeInsets.fromLTRB(10, 10, 5, 5),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      RaisedButton(
                        color: vpnButtonColor,
                        onPressed: () async {
                          if (isOpenVpnService) {
                            await Trojangoplugin.stopVpn;
                            vpnButtonColor = Colors.lightBlue;
                            listenInfo = "";
                          } else {
                            await Trojangoplugin.startVpn;
                            vpnButtonColor = Colors.redAccent;
                            listenInfo =
                                " ${clientConfig.localAddr}:${clientConfig.localPort} ";
                          }

                          setState(() {
                            isOpenVpnService = !isOpenVpnService;
                          });
                        },
                        child: Text(isOpenVpnService ? "停止VPN" : "启动VPN"),
                      ),
                      Builder(
                        builder: (c) => RaisedButton(
                          color: Colors.blueGrey,
                          onPressed: () async {
                            await saveTrojanClientConfig(c);
                          },
                          child: Text("保存"),
                        ),
                      ),
                      Builder(
                        builder: (ctx) => RaisedButton(
                          color: Colors.green,
                          onPressed: () {
                            // 打开help页面
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(builder: (c) => HelpApp()),
                            );
                          },
                          child: Text("使用说明"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
