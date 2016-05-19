##########################################
#	README FILE

#

#     ./trunk/code/mote
##########################################

1.Overview

Codes for sensors. 


2.Details

1) bldg_tag: 	
	Codes for Telosb mote, performing BTag functions. 
	Sensors form a multi-hop network. They perform leader election among themselves. When sensor that connected to routers on vehicle get close, the leader will communicate with the mote installed on routers. For communication with mote on router, see StaticWifiBridge.

2) delsar: codes for Delsar devices(Vibration sensing)

3) staticWifiBridge: 
	i) Code for mote that connected with router. This mote communicate with router using PPP protocol over USB (?), and it communicates with BTag sensor leaders (See bldg_tag) using RF. 
	ii) The mote’s ID (make telosb install.X, then X is the mote id) should correspond to the router it connects to. For router with ID=Y, then X=Y+51. (See code for detail)
 	iii) It seems that asio/mobilebeaconder_btagcollector is the corresponding program that runs on router. 



###########################################
# Updated after summer institute 2015
# Date: 07/28/2015 
#
###########################################

1. To compile,
	make blip telosb

2. To install, assume the mote is on /dev/ttyUSB0
	make blip telosb install.X bsl,/dev/ttyUSB0
where X is the mote id.

3. A working copy for tinyos-2.1.2 is included in the directory. Some code
in the tinyos-2.1.2 source code was modified to make everything work.
If the sudo apt-get tinyos cannot work, try this one.
