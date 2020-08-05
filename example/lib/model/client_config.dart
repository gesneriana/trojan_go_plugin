class ClientConfig {
  String runType;
  String localAddr;
  int localPort;
  String remoteAddr;
  int remotePort;
  List<String> password;
  Websocket websocket;
  Mux mux;
  Router router;
  Ssl ssl;

  ClientConfig(
      {this.runType,
      this.localAddr,
      this.localPort,
      this.remoteAddr,
      this.remotePort,
      this.password,
      this.websocket,
      this.mux,
      this.router,
      this.ssl});

  ClientConfig.fromJson(Map<String, dynamic> json) {
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

class Websocket {
  bool enabled;
  String path;
  String hostname;

  Websocket({this.enabled, this.path, this.hostname});

  Websocket.fromJson(Map<String, dynamic> json) {
    enabled = json['enabled'];
    path = json['path'];
    hostname = json['hostname'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['enabled'] = this.enabled;
    data['path'] = this.path;
    data['hostname'] = this.hostname;
    return data;
  }
}

class Mux {
  bool enabled;

  Mux({this.enabled});

  Mux.fromJson(Map<String, dynamic> json) {
    enabled = json['enabled'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['enabled'] = this.enabled;
    return data;
  }
}

class Router {
  bool enabled;
  List<String> bypass;

  Router({this.enabled, this.bypass});

  Router.fromJson(Map<String, dynamic> json) {
    enabled = json['enabled'];
    bypass = json['bypass'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['enabled'] = this.enabled;
    data['bypass'] = this.bypass;
    return data;
  }
}

class Ssl {
  String fingerprint;
  String sni;

  Ssl({this.fingerprint, this.sni});

  Ssl.fromJson(Map<String, dynamic> json) {
    fingerprint = json['fingerprint'];
    sni = json['sni'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['fingerprint'] = this.fingerprint;
    data['sni'] = this.sni;
    return data;
  }
}
