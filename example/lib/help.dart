import "package:flutter/material.dart";

class HelpApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Trojan Go example help'),
        ),
        body: SingleChildScrollView(
          child: Container(
            child: Text(
              '''  支持开启本地代理服务,
  默认是监听在127.0.0.1:1082,

  如果是webview使用,
  无须开启全局的vpn.
  请考虑使用第三方\n  支持设置代理的webview，
  
  官方webview不支持设置http代理，
  第三方实现可以参考NetCipher源码：
  https://github.com/\n  guardianproject/NetCipher

  相关建议: 部分手机\n  开启mux选项后下载速度变慢
  可以考虑关闭mux和\n  清除websocket的path试试''',
              style: TextStyle(fontSize: 20),
              maxLines: 100,
              textAlign: TextAlign.left,
              overflow: TextOverflow.visible,
              softWrap: false,
            ),
            margin: EdgeInsets.fromLTRB(10, 10, 5, 5),
          ),
        ),
      ),
    );
  }
}
