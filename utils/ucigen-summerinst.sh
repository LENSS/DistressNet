#!/bin/bash

echo "
#!/bin/sh
#####################################################################
/sbin/uci set system.@system[0].hostname=router$1
/sbin/uci set system.@system[0].zonename=America/Chicago
/sbin/uci set system.@system[0].timezone=CST6CDT,M3.2.0,M11.1.0
/sbin/uci set system.@rdate[0].server=192.168.1.150
/sbin/uci set ntpclient.@ntpserver[0].hostname=192.168.1.150

/sbin/uci set network.lan.ipaddr=10.10.$1.1
/sbin/uci set network.lan.netmask=255.255.255.0
/sbin/uci set network.lan.dns=128.194.254.1

/sbin/uci set network.wifi=interface
/sbin/uci set network.wifi.proto=static
/sbin/uci set network.wifi.ifname=wlan1
/sbin/uci set network.wifi.ipaddr=10.10.11.$1
/sbin/uci set network.wifi.netmask=255.255.255.0

/sbin/uci set wireless.radio0.disabled=0
/sbin/uci set wireless.radio1.disabled=0

/sbin/uci set wireless.radio0.channel=6
/sbin/uci set wireless.radio1.channel=36

/sbin/uci set wireless.radio0.txpower=12
/sbin/uci set wireless.radio1.txpower=12

/sbin/uci set wireless.radio1.htmode=HT40+
/sbin/uci set wireless.radio1.noscan=1

/sbin/uci set wireless.@wifi-iface[0]=wifi-iface
/sbin/uci set wireless.@wifi-iface[0].device=radio0
/sbin/uci set wireless.@wifi-iface[0].network=lan
#/sbin/uci set wireless.@wifi-iface[0].mode=adhoc
#/sbin/uci set wireless.@wifi-iface[0].ssid=324-cjh-adhoc
#/sbin/uci set wireless.@wifi-iface[0].encryption=none

/sbin/uci set wireless.@wifi-iface[0].mode=ap
/sbin/uci set wireless.@wifi-iface[0].ssid=324-cjh-ap
/sbin/uci set wireless.@wifi-iface[0].encryption=psk+tkip+ccmp
/sbin/uci set wireless.@wifi-iface[0].key=abbcccdddd

/sbin/uci set wireless.@wifi-iface[0].bssid=12:34:56:78:90:AB

/sbin/uci set wireless.@wifi-iface[1]=wifi-iface
/sbin/uci set wireless.@wifi-iface[1].device=radio1
/sbin/uci set wireless.@wifi-iface[1].network=wifi
/sbin/uci set wireless.@wifi-iface[1].mode=adhoc
/sbin/uci set wireless.@wifi-iface[1].ssid=meshlium-X
/sbin/uci set wireless.@wifi-iface[1].encryption=none
/sbin/uci set wireless.@wifi-iface[1].bssid=AA:AA:AA:AA:AA:AA

/sbin/uci set ibrdtn.main.uri=dtn://\`/sbin/uci get system.@system[0].hostname\`.dtn
/sbin/uci set ibrdtn.main.routing=epidemic
/sbin/uci set ibrdtn.@network[0].interface=wlan1
/sbin/uci set ibrdtn.statistic=daemon
/sbin/uci set ibrdtn.statistic.type=csv
/sbin/uci set ibrdtn.statistic.interval=1
/sbin/uci set ibrdtn.statistic.address=127.0.0.1
/sbin/uci set ibrdtn.statistic.port=1234
/sbin/uci set ibrdtn.security.level=0
/sbin/uci set ibrdtn.security.bab_key=/root/my.bab
/sbin/uci set ibrdtn.security.key_path=/root
/sbin/uci commit

/etc/init.d/firewall disable

#(echo \"src/gz mypackages http://192.168.1.150/packages\"; cat /etc/opkg.conf) > /tmp/opkg.conf
#mv /tmp/opkg.conf /etc

#route add default gw 192.168.1.150
#echo \"nameserver 8.8.8.8\" > /etc/resolv.conf

#opkg update
#opkg install olsrd

/sbin/uci set olsrd.@Interface[0]=Interface
/sbin/uci set olsrd.@Interface[0].interface=wifi
/sbin/uci set olsrd.@Interface[0].ignore=0

/sbin/uci add olsrd Hna4
/sbin/uci set olsrd.@Hna4[-1].netaddr=192.168.$1.0
/sbin/uci set olsrd.@Hna4[-1].netmask=255.255.255.0
/sbin/uci commit

/etc/init.d/olsrd enable
###############################################################################
#/sbin/uci set ibrdtn.main.logfile=/tmp/sandisk/ibrdtn.log
#/sbin/uci set ibrdtn.main.errfile=/tmp/sandisk/ibrdtn.err
#/sbin/uci delete ibrdtn.storage.blobs
#/sbin/uci delete ibrdtn.storage.bundles
#/sbin/uci set ibrdtn.storage.container=/tmp/ibrdtn/container.img
#/sbin/uci set ibrdtn.storage.container_size=10
#/sbin/uci set ibrdtn.storage.path=/tmp/ibrdtn/container
#/sbin/uci set ibrdtn.statistic.file=/tmp/sandisk/ibrdtn.stats


#mkdir /tmp/sandisk
#/sbin/uci set fstab.@mount[0].device=/dev/sda1
#/sbin/uci set fstab.@mount[0].options=rw,sync
#/sbin/uci set fstab.@mount[0].enabled_fsck=0
#/sbin/uci set fstab.@mount[0].enabled=1
#/sbin/uci set fstab.@mount[0].target=/tmp/sandisk
#/sbin/uci set fstab.@mount[0].fstype=ext3
#/sbin/uci commit fstab

#/sbin/uci set wireless.radio0.macaddr=\`/sbin/ifconfig wlan0 | grep 'wlan0' | tr -s ' ' | cut -d ' ' -f5\`
#/sbin/uci set wireless.radio1.macaddr=\`/sbin/ifconfig wlan1 | grep 'wlan1' | tr -s ' ' | cut -d ' ' -f5\`

"
