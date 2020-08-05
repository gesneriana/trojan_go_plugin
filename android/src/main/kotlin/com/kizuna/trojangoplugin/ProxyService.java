package com.kizuna.trojangoplugin;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.net.VpnService;
import android.os.Build;
import android.os.IBinder;
import android.os.ParcelFileDescriptor;
import android.os.RemoteCallbackList;
import android.os.RemoteException;
import android.util.Log;

import androidx.annotation.IntDef;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;

import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

import trojangolib.*;

public class ProxyService extends VpnService {
    private static final String TAG = "ProxyService";
    public static final int STATE_NONE = -1;
    public static final int STARTING = 0;
    public static final int STARTED = 1;
    public static final int STOPPING = 2;
    public static final int STOPPED = 3;
    public static final int IGNITER_STATUS_NOTIFY_MSG_ID = 114514;
    public long tun2socksPort;
    public static final String StopTag = "stop_vpn";

    @IntDef({STATE_NONE, STARTING, STARTED, STOPPING, STOPPED})
    public @interface ProxyState {
    }

    private static final int VPN_MTU = 1500;
    private static final String PRIVATE_VLAN4_CLIENT = "172.19.0.1";
    //private static final String PRIVATE_VLAN4_ROUTER = "172.19.0.2";
    private static final String PRIVATE_VLAN6_CLIENT = "fdfe:dcba:9876::1";
    //private static final String PRIVATE_VLAN6_ROUTER = "fdfe:dcba:9876::2";
    private static final String TUN2SOCKS5_SERVER_HOST = "127.0.0.1";
    private @ProxyState
    int state = STATE_NONE;
    private ParcelFileDescriptor pfd;

    /**
     * Receives stop event.
     */
    private BroadcastReceiver mStopBroadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String stopAction = StopTag;
            final String action = intent.getAction();
            if (stopAction.equals(action)) {
                Log.d(TAG,"stop the ProxyService");
                stop();
            }
        }
    };

    private void setState(int state) {
        Log.i(TAG, "setState: " + state);
        this.state = state;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.i(TAG, "onCreate");
        IntentFilter filter = new IntentFilter();
        filter.addAction(StopTag);
        registerReceiver(mStopBroadcastReceiver, filter);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.i(TAG, "onDestroy");
        setState(STOPPED);
        unregisterReceiver(mStopBroadcastReceiver);
        pfd = null;
    }

    @Override
    public void onRevoke() {
        // Calls to this method may not happen on the main thread
        // of the process.
        stop();
    }


    @Override
    public IBinder onBind(Intent intent) {
        return super.onBind(intent);
    }


    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if(this.state==STARTING||this.state==STARTED){
            Log.i(TAG, "already started vpn server and local proxy");
            return START_NOT_STICKY;
        }
        Log.i(TAG, "onStartCommand");

        setState(STARTING);

        // 读取配置文件, 设置某些APP不使用代理服务
        Set<String> exemptAppPackageNames = new HashSet<String>();

        VpnService.Builder b = new VpnService.Builder();
        try {
            b.addDisallowedApplication(getPackageName());
        } catch (PackageManager.NameNotFoundException e) {
            e.printStackTrace();
            setState(STOPPED);
            // todo: stop foreground notification and return here?
        }
        for (String packageName : exemptAppPackageNames) {
            try {
                b.addDisallowedApplication(packageName);
            } catch (PackageManager.NameNotFoundException e) {
                e.printStackTrace();
            }
        }

        boolean enable_ipv6 = false;
        long trojanPort = 1082;

        String data_dir = intent.getStringExtra("data_dir");
        if (data_dir == null || data_dir.length() == 0) {
            Log.e(TAG, "intent args data_dir is null");
            return START_NOT_STICKY;
        }

        File file = new File(data_dir, "config.json");
        if (file.exists()) {
            try {
                try (FileInputStream fis = new FileInputStream(file)) {
                    byte[] content = new byte[(int) file.length()];
                    fis.read(content);
                    JSONObject json = new JSONObject(new String(content));
                    if (json.has("enable_ipv6")) {
                        enable_ipv6 = json.getBoolean("enable_ipv6");
                    }
                    if (json.has("local_port")) {
                        trojanPort = json.getLong("local_port");
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        b.setSession("trojan-go-plugin-example");
        b.setMtu(VPN_MTU);
        b.addAddress(PRIVATE_VLAN4_CLIENT, 30);
        b.addRoute("0.0.0.0", 0);

        if (enable_ipv6) {
            b.addAddress(PRIVATE_VLAN6_CLIENT, 126);
            b.addRoute("::", 0);
        }

        b.addDnsServer("8.8.8.8");
        b.addDnsServer("8.8.4.4");
        b.addDnsServer("1.1.1.1");
        b.addDnsServer("1.0.0.1");
        if (enable_ipv6) {
            b.addDnsServer("2001:4860:4860::8888");
            b.addDnsServer("2001:4860:4860::8844");
        }
        pfd = b.establish();
        Log.i("VPN", "pfd established");

        if (pfd == null) {
            stop();
            return START_NOT_STICKY;
        }
        int fd = pfd.detachFd();

        Log.i("Igniter", "trojan port is " + trojanPort);

        long clashSocksPort = 1080; // default value in case fail to get free port

        tun2socksPort = trojanPort;

        Log.i("igniter", "tun2socks port is " + tun2socksPort);


        trojangolib.Tun2socksStartOptions opt = new trojangolib.Tun2socksStartOptions();
        opt.setTunFd(fd);
        opt.setSocks5Server(TUN2SOCKS5_SERVER_HOST + ":" + tun2socksPort);
        opt.setEnableIPv6(enable_ipv6);
        opt.setMTU(VPN_MTU);
        opt.setFakeIPRange("198.168.0.1/16");
        Trojangolib.startTun(opt);
        Log.i(TAG, opt.toString());

        setState(STARTED);

        return START_STICKY;
    }

    private void shutdown() {
        Log.i(TAG, "shutdown");
        setState(STOPPING);
        Trojangolib.stop();
        Trojangolib.stopTun();
        stopSelf();
        setState(STOPPED);
        stopForeground(true);
    }

    public void stop() {
        shutdown();
        // this is essential for gomobile aar
        // android.os.Process.killProcess(android.os.Process.myPid());
    }
}
