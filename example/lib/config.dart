import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'model/trojan_config.dart';

// 读取trojan配置文件列表, 选择配置
class TrojanClientConfigPage extends StatefulWidget {
  @override
  _TrojanClientConfigPageState createState() => _TrojanClientConfigPageState();
}

class _TrojanClientConfigPageState extends State<TrojanClientConfigPage> {
  var trojanAllConfigs = TrojanClientConfig();
  var clientLableConfigs = List<ClientLableConfig>();

  @override
  void initState() {
    initConfigData();
    super.initState();
  }

  Future<void> initConfigData() async {
    var dir = await getApplicationDocumentsDirectory();
    var trojantConfigFile = File("${dir.path}/trojan_config.json");
    if (trojantConfigFile.existsSync()) {
      var allTrojanConfigsJson = await trojantConfigFile.readAsString();
      trojanAllConfigs =
          TrojanClientConfig.fromJson(jsonDecode(allTrojanConfigsJson));

      if (!mounted) return;

      if (trojanAllConfigs.configMaps != null &&
          trojanAllConfigs.configMaps.length >= 0) {
        trojanAllConfigs.configMaps.forEach((key, value) {
          var config =
              ClientLableConfig.fromJson(jsonDecode(jsonEncode(value)));
          config.lable = key;
          config.isDeleted = false;
          clientLableConfigs.add(config);
        });
        setState(() {});
      }
    }
  }

  Future<void> saveTrojanClientConfig() async {
    var clientConfig =
        trojanAllConfigs.configMaps[trojanAllConfigs.currentNodeLable];
    // 保存配置到文件
    var trojanClientConfigJson = jsonEncode(clientConfig);
    print(trojanClientConfigJson);
    var dir = await getApplicationDocumentsDirectory();
    var clientConfigFile = File("${dir.path}/config.json");
    await clientConfigFile.writeAsString(trojanClientConfigJson);

    // 保存到节点列表文件中
    var allTrojanConfigsJson = jsonEncode(trojanAllConfigs);
    var trojantConfigFile = File("${dir.path}/trojan_config.json");
    await trojantConfigFile.writeAsString(allTrojanConfigsJson);
    print(allTrojanConfigsJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trojan Go config"),
      ),
      body: Container(
        child: ListView.builder(
          itemBuilder: (bc, i) {
            var config = clientLableConfigs[i];
            if (config.lable == trojanAllConfigs.currentNodeLable) {
              return ListTile(
                title: Text(config.lable),
                leading:
                    IconButton(icon: Icon(Icons.check_box), onPressed: null),
                subtitle: Text("${config.remoteAddr}:${config.remotePort}"),
              );
            }
            return ListTile(
              title: Text(config.lable),
              leading: IconButton(
                icon: Icon(Icons.check_box_outline_blank),
                onPressed: config.isDeleted
                    ? null
                    : () async {
                        trojanAllConfigs.currentNodeLable = config.lable;
                        // 写入文件, 同时更新config.json, 然后重启vpn
                        await saveTrojanClientConfig();
                        setState(() {});
                        Scaffold.of(bc).showSnackBar(SnackBar(
                          content: Text("保存成功,请手动重启VPN"),
                        ));
                      },
              ),
              subtitle: Text("${config.remoteAddr}:${config.remotePort}"),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: config.isDeleted
                    ? null
                    : () async {
                        // 删除配置, 返回到上一页的时候可能需要刷新数据
                        trojanAllConfigs.configMaps.remove(config.lable);
                        // 写入文件, 同时更新config.json, 然后重启vpn
                        await saveTrojanClientConfig();
                        setState(() {
                          config.isDeleted = true;
                        });
                        Scaffold.of(bc).showSnackBar(
                          SnackBar(
                            content: Text("删除成功"),
                          ),
                        );
                      },
              ),
              enabled: config.isDeleted == false,
            );
          },
          itemCount: clientLableConfigs.length,
        ),
      ),
    );
  }
}
