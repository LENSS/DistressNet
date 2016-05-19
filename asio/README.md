<!---
# ########################################
# 	Readme for Fogbox application
# 	Author: Chen Yang
#	Date: 07/28/2015 
##########################################
-->

# Readme for Fogbox/BTag application

## Fogbox

### Related files
- asio/fogbox_recv.cpp
- asio/fogbox_send.cpp
- asio/tftpd.cpp
- CVS/DistressNet/Fogbox android project

### Prerequisite
- ibrdtn version 0.8.0
- boost 1.35.0
- tftpd server
- TIME SYNCHRONIZATION ON ROUTER

### Functionality
- Fogbox tries to synchronize images among DTN routers. Using a 
	front-end Android application "fogbox", users can upload pictures
	to the router it is currently associated with. The uploaded pictures
	is put into the folder which fogbox periodically scans. When there's
	a new picture found, fogbox will send it to the DTN, destined to 
	all other routers using DTN multicast.

- fogbox_send: periodically scans the "/root/rsync/media/USERx" 
	folders, where x = 1..4. When there's a new image (.jpg) found, send
	it to "dtn://fogboxgroup/fogbox". In the same time, the file name is 
	put into a map data structure to monitor all files that have been sent.
	When the fogbox_send is terminated, this data is written to a meta
	data file "/root/rsync/media/.fogboxmeta". When the fogbox is restarted,
	this meta data is loaded to the map data structure.

- fogbox_recv: regiestered itself to dtnd daemon (see ibrdtn) and 
	receive bundles destined to "dtn://fogboxgroup/fogbox". The received file
	is first written to a temporary file. If the received file doesn't exist
	in the real folder, it is then written to the real file (at the correct 
	location). At the same time, a empty file with the exact same file name
	is created in "/root/rsync/media/USERx/recv/" folder. This is for the 
	fogbox_send program to check whether a file is a received file. If the file
	is received from others, fogbox_send will not send it again.

- tftpd: used as a server to receive pictures from android smart phones.

- fogbox on Android: this android project is in CVS/DistressNet. It uses
	the tftp_client c library. To use it to upload pictures to routers, run a 
	tftpd on the router with command: tftpd -P 10000 (specicy the port to 10000,
	and it must be 10000). Then associate the android smartphone to that router
	and open the fogbox app to upload picture. ATTENTION: THIS APP IS UNRELIABLE. 
	IT MAY GET THINGS DONE MOST OF TIME BUT STILL CRASHES OCCASSIONALLY AND SOMETIME
	THE PICTURE CANNOT BE UPLOADED. USE	DEBUG MODE OF TFTPD SERVER 
	(tftpd -d -P 10000) TO SEE WHAT'S GOING ON.
		
### Notes:
- This is a modified version of fogbox by myself during the Summer Institute
	2015. It's still not well designed, as I was trying to make minimal changes to 
	the original version, and can be optimized further, but it should get things done.
	
	The original version of fogbox is called "fogbox.cpp", both sending and
	reception is in one single program. The original one basically will not work
	due to too much traffic going on. It sends a picture to each of the other routers
	using unicast. But since Epidemic is used as routing, each unicast is also flooded
	to all routers, making it N^2 (N routers) transmissions for one file. Now since 
	the other router that receive this file sees it as a new file (yes, no state 
	monitoring in the original version), it sends the file to everyone again, making 
	it to N^3 transmissions. Therefore if there're K files, N routers, there will be 
	O(K*N^3) transmissions, in worst case. 

- Compiled binary for OpenWRT system is put in compiled_binary_openwrt_backfire_10.03.tar
	with the source code (the exact version for the binary). If everything is setup 
	well for the router, these binaries should work. Noticed that you should put all
	necessary libraries (boost and ibrdtn) in the right folder.

## BTag

### Related files
- asio/multicastforwarder.cpp
- asio/mobilebeaconer_btagcollector.cpp
- mote/bldg_tag/*
- mote/StaticWifiBridge/*
- iphone/*

### Prerequisite
- ibrdtn version 0.8.0
- tinyos-2.1.2
- ipv6 support on router
- usb and ftdi driver on router
- router firewall configure to accept ppp0 traffic

### Basic Setup
      _____________	
		 |_router-id-x_|
			    |
  				| usb
  				|
  			proxy_mote_id_(x+51)
  				|
  				| wireless
  				|
  			mote_id_1
  			  /		  \
    mote_id_2 -----	mote_id_3

- Router with id x should have wlan1 ip address 192.168.50.x. The 
	proxy mote is connected to router x through USB serial port, using pppd. 
	The proxy mote should have id x+51 . The router and the proxy mote 
	communicate using ipv6, where router has ip fec0::100 (no matter what x
	is), and the mote using ip fec0::(x+51), you need to translate x+51 to
	hex. For example, if router is 9, then proxy mote has id 60, using 
	ip address fec0::3c.

- Other motes running bldg_tag code, each with id >=0 and <= 50.

### Functionality:
- In general, the first responder uses the iOS app running on iPod or
	iPad to program the building tags. The iPod should first associate 
	with the router who has the proxy mote. Then use the iPod to program the
	mote (you need to know the mote id and enter it on the iPod to correctly
	program the desired mote). Once it successfully programmed the mote, 
	the proxy will forward it to the WSN and the mote with that ID will update
	its data. There will be a mote becoming the leader of the WSN, and 
	periodically transmit back data to the proxy mote. Then this data gets
	forwarded to the WiFi network, and you should be able to see the programmed
	data on the btag_view app.

- mobilebeaconer_btagcollector.cpp: broadcast beacons to nearby building
	tags periodically and collect data from the building tags. This program
	does not use DTN functionality, but require established ppp link, and thus
	also ipv6 setup on router. When a packet is received from the ppp link, 
	the data get transmit to all connected mesh routers (192.168.50.1-10) using 
	port 7011. It also listens to wlan1 on port 7010 for program data. When 
	received program data, it gets forwarded to ppp link.

- multicastforwarder.cpp: cache btag data, send them to DTN, broadcast them
	to AP networks. Thus it needs DTN functionality, but does not need ppp link.
		a. It listens to wlan0 for program data packets. Whenever a program data 
		packet is received, it got forwarded to all mesh routers (192.168.50.1-10) 
		using port 7010. 
		b. It also listens to wlan1 on port 7011 for btag data that is forwarded on
		the mesh network. If the received btag data is different than the cached data,
		it got sent to the DTN network, using a group name "dtn://btaggroup/btag" as 
		destination. 
		c. It periodically checks if there's new DTN bundle destined for the group
		"dtn://btaggroup/btag". If there's a new bundle, cached it. 
		d. During each bundle check in c, broadcast the cached btag data to wlan0

### Note:
- This is a modified version for multicastforwarder.cpp during Summer Institute
	2015. The main modification is the use of group name "dtn://btaggroup/btag", 
	and that it will not send to DTN if the received btag data is the same with the 
	cached data. This will reduce a lot of traffic. The original version takes so long
	before the btag_viewer gets updated for the new btag data, as it takes a lot of
	time to process earlier DTN bundles.

- For compiling mote code, see mote/ folder. You'll need tinyos-2.1.2, and some
	of the tinyos-2.1.2 code might need modification.
