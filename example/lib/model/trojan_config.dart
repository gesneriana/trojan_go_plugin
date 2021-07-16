import 'client_config.dart';

class TrojanClientConfig {
  Map<String, ClientConfig> configMaps;

  String currentNodeLable;

  TrojanClientConfig({this.configMaps});

  TrojanClientConfig.fromJson(Map<String, dynamic> json) {
    if (configMaps == null) {
      configMaps = new Map<String, ClientConfig>();
    }

    json.forEach((key, value) {
      if (key == "current_node_lable") {
        this.currentNodeLable = value;
      } else {
        configMaps[key] =
            json[key] != null ? ClientConfig.fromJson(json[key]) : null;
      }
    });
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    configMaps.forEach((key, value) {
      data[key] = value.toJson();
    });
    data["current_node_lable"] = this.currentNodeLable;
    return data;
  }
}

class ClientLableConfig extends ClientConfig {
  String lable;

  bool isDeleted;

  ClientLableConfig.fromJson(Map<String, dynamic> json) {
    runType = json['run_type'];
    localAddr = json['local_addr'];
    localPort = json['local_port'];
    remoteAddr = json['remote_addr'];
    remotePort = json['remote_port'];
    password = json['password'].cast<String>();
    websocket = json['websocket'] != null
        ? new Websocket.fromJson(json['websocket'])
        : null;
    mux = json['mux'] != null ? new Mux.fromJson(json['mux']) : null;
    router =
        json['router'] != null ? new Router.fromJson(json['router']) : null;
    ssl = json['ssl'] != null ? new Ssl.fromJson(json['ssl']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['run_type'] = this.runType;
    data['local_addr'] = this.localAddr;
    data['local_port'] = this.localPort;
    data['remote_addr'] = this.remoteAddr;
    data['remote_port'] = this.remotePort;
    data['password'] = this.password;
    if (this.websocket != null) {
      data['websocket'] = this.websocket.toJson();
    }
    if (this.mux != null) {
      data['mux'] = this.mux.toJson();
    }
    if (this.router != null) {
      data['router'] = this.router.toJson();
    }
    if (this.ssl != null) {
      data['ssl'] = this.ssl.toJson();
    }
    return data;
  }
}
