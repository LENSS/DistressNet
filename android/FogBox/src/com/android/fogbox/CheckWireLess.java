package com.android.fogbox;

import android.content.Context; 
import android.net.DhcpInfo; 
import android.net.wifi.WifiInfo; 
import android.net.wifi.WifiManager; 
import android.text.format.Formatter; 
import android.util.Log;

public class CheckWireLess { 
    private static WifiManager wifiManager; 
    private static DhcpInfo dhcpInfo; 
    private static WifiInfo wifiInfo; 
     
    //get IP address  
    public static String getIp(Context context){ 
     wifiManager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE); 
     dhcpInfo = wifiManager.getDhcpInfo(); 
     wifiInfo = wifiManager.getConnectionInfo(); 
     int ip = wifiInfo.getIpAddress(); 
     return FormatIP(ip); 
    } 
     
    //get gateway address
    public static String getGateWay(Context context){ 
        wifiManager = (WifiManager) context.getSystemService(Context.WIFI_SERVICE); 
        dhcpInfo = wifiManager.getDhcpInfo();
        Log.d("CheckWireless","The server is "+FormatIP(dhcpInfo.gateway));  
     return FormatIP(dhcpInfo.gateway);      
    } 
     
    // IP to String
    public static String FormatIP(int IpAddress) { 
     return Formatter.formatIpAddress(IpAddress); 
     } 
    
} 
