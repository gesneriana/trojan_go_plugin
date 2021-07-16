package com.kizuna.trojangoplugin

import android.app.Activity
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat.startActivityForResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import trojangolib.Trojangolib

/** TrojangopluginPlugin */
public class TrojangopluginPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  // / The MethodChannel that will the communication between Flutter and native Android
  // /
  // / This local reference serves to register the plugin with the Flutter Engine and unregister it
  // / when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private lateinit var activity: Activity
  private var isAttacehd: Boolean = false

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.getFlutterEngine().getDartExecutor(), "trojangoplugin")
    channel.setMethodCallHandler(this)
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "trojangoplugin")
      channel.setMethodCallHandler(TrojangopluginPlugin())
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "start") {
      Log.i("TrojangopluginPlugin", "trojan go proxy is start")
      val dir = call.argument<String>("configRootDir")
      Trojangolib.start(dir) // 此函数可以多次调用, goroutine有检测重入的代码

      result.success(true)
    } else if (call.method == "startVpn") {
      if (!isAttacehd) {
        Log.i("TrojangopluginPlugin", "activity is null")
        result.success(false)
        return
      }

      val dir = call.argument<String>("configRootDir")
      Trojangolib.start(dir) // 此函数可以多次调用, goroutine有检测重入的代码
      var intent = ProxyService.prepare(this.activity)
      if (intent != null) {
        intent.putExtra("data_dir", dir)
        startActivityForResult(this.activity, intent, 0, null)
      } else {
        val intentStart = Intent(this.activity, ProxyService::class.java)
        intentStart.putExtra("data_dir", dir)
        // ContextCompat.startForegroundService(this.activity, intentStart)
        Log.d("TrojangopluginPlugin", "start ProxyService vpn")
        this.activity.startService(intentStart)
      }

      result.success(true)
    } else if (call.method == "stop") {
      Log.i("TrojangopluginPlugin", "trojan go proxy is stop")
      Trojangolib.stop()
      result.success(true)
    } else if (call.method == "stopVpn") {
      Log.i("TrojangopluginPlugin", "stop ProxyService vpn")
      val intent = Intent(ProxyService.StopTag)
      intent.setPackage(this.activity.getPackageName())
      this.activity.sendBroadcast(intent)
      Trojangolib.stop()
      result.success(true)
    } else if (call.method == "getPlatformInfo") {
      var platform = Trojangolib.getPlatformInfo()
      result.success(platform)
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onDetachedFromActivity() {
    this.isAttacehd = false
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    this.activity = binding.activity
    this.isAttacehd = true
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.activity = binding.activity
    this.isAttacehd = true
  }

  override fun onDetachedFromActivityForConfigChanges() {
    this.isAttacehd = false
  }
}
