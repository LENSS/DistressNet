
#include <stdio.h>
#include <lib6lowpan/ip.h>
#include <lib6lowpan/nwbyte.h>
#include <lib6lowpan/ip_malloc.h>
#include <dhcp6.h>

#include "pppipv6.h"
#include "blip_printf.h"

#include "../../DistressNet.h"
#include "../tos-utils.h"

	
module PppRouterP {
  provides { 
    interface IPForward;
  }
  uses {
    interface Boot;
    interface Leds;
    interface SplitControl as IPControl;
    interface SplitControl as PppControl;
    interface LcpAutomaton as Ipv6LcpAutomaton;
    interface PppIpv6;
    interface Ppp;

    interface UDP as myProxyComms;
    interface UDP as BtagCollectComms;
	interface UDP as BeaconComms;

	interface Timer<TMilli> as BeaconTimer;		
    
    interface ForwardingTable;
    interface RootControl;
    interface Dhcp6Info;
    interface IPPacket;
  }
  
} implementation {

struct sockaddr_in6 route_dest;
struct sockaddr_in6 pppend;
beacon_msg_t beacon;
struct sockaddr_in6 beaconbcast;

  event void PppIpv6.linkUp() {}
  event void PppIpv6.linkDown() {}

  event void Ipv6LcpAutomaton.transitionCompleted (LcpAutomatonState_e state) { }
  event void Ipv6LcpAutomaton.thisLayerUp () { }
  event void Ipv6LcpAutomaton.thisLayerDown () { }
  event void Ipv6LcpAutomaton.thisLayerStarted () { }
  event void Ipv6LcpAutomaton.thisLayerFinished () { }

  event void PppControl.startDone (error_t error) {  }
  event void PppControl.stopDone (error_t error) { }

  event void IPControl.startDone (error_t error) {
    struct in6_addr dhcp6_group;

    // add a route to the dhcp group on PPP, not the radio (which is the default)
    inet_pton6(DH6ADDR_ALLAGENT, &dhcp6_group);
    call ForwardingTable.addRoute(dhcp6_group.s6_addr, 128, NULL, ROUTE_IFACE_PPP);

    // add a default route through the PPP link
    call ForwardingTable.addRoute(NULL, 0, NULL, ROUTE_IFACE_PPP);
    
		inet_pton6("ff02::1a", &route_dest.sin6_addr);
		route_dest.sin6_port = htons(PORT_BTAG_PROGRAMMER);
		call myProxyComms.bind(PORT_BTAG_PROGRAMMER);
		
		inet_pton6("fec0::100", &pppend.sin6_addr);
		pppend.sin6_port = htons(PORT_BTAG_COLLECT_ON_VEHICLE);
		call BtagCollectComms.bind(PORT_BTAG_COLLECT_ON_VEHICLE);
		
		inet_pton6("ff02::1a", &beaconbcast.sin6_addr);
		beaconbcast.sin6_port = htons(PORT_VEHBEACON);
		
		beacon.beacon_cnt = 0;
		beacon.beacon_id = TOS_NODE_ID;
		
		call BeaconTimer.startPeriodic(TIMER_BEACON_BCAST);	
  }
  
  
event void 
BeaconTimer.fired() 
{
	call Leds.led0Toggle();
	beacon.beacon_cnt++;
	//call BeaconComms.bind(PORT_BEACON);
	call BeaconComms.sendto(&beaconbcast, &beacon, sizeof(beacon));
	printf("Sending beacon\n");
}


  event void IPControl.stopDone (error_t error) { }

  event void Boot.booted() {
    error_t rc;

#ifndef PRINTFUART_ENABLED
    rc = call Ipv6LcpAutomaton.open();
    rc = call PppControl.start();
#endif
#ifdef RPL_ROUTING
    call RootControl.setRoot();	//	TODO: decide about this
#endif
#ifndef IN6_PREFIX
    call Dhcp6Info.useUnicast(FALSE);
#endif

    call IPControl.start();
  }

  event error_t PppIpv6.receive(const uint8_t* data,
                                unsigned int len) {
    struct ip6_hdr *iph = (struct ip6_hdr *)data;
    void *payload = (iph + 1);
//     call Leds.led0Toggle();
    signal IPForward.recv(iph, payload, NULL);
    return SUCCESS;
  }

  command error_t IPForward.send(struct in6_addr *next_hop,
                                 struct ip6_packet *msg,
                                 void *data) {
    size_t len = iov_len(msg->ip6_data) + sizeof(struct ip6_hdr);
    error_t rc;
    frame_key_t key;
    const uint8_t* fpe;
    uint8_t* fp;
    
    if (!call PppIpv6.linkIsUp()) 
      return EOFF;

    // get an output frame
    fp = call Ppp.getOutputFrame(PppProtocol_Ipv6, &fpe, FALSE, &key);
    if ((! fp) || ((fpe - fp) < len)) {
      if (fp) {
	call Ppp.releaseOutputFrame(key);
      }
//       call Leds.led2Toggle();
      return ENOMEM;
    }

    // copy the header and body into the frame
    memcpy(fp, &msg->ip6_hdr, sizeof(struct ip6_hdr));
    iov_read(msg->ip6_data, 0, len, fp + sizeof(struct ip6_hdr));
    rc = call Ppp.fixOutputFrameLength(key, fp + len);
    if (SUCCESS == rc) {
      rc = call Ppp.sendOutputFrame(key);
    }

//     call Leds.led1Toggle();

    return rc;
  }

event void Ppp.outputFrameTransmitted (frame_key_t key, error_t err) { }


                                         
event void myProxyComms.recvfrom(struct sockaddr_in6 *from, void *data, 
								uint16_t len, struct ip6_metadata *meta) 
{
	//	DON'T PROXY FROM OTHER PPPROUTERS
	uint16_t frommer = getTOSNodeIDs(from);
	if ( frommer >= 50 && frommer <= 90)
	   return;
			
	call Leds.led2Toggle();
	call myProxyComms.sendto(&route_dest, data, len);
}

event void BtagCollectComms.recvfrom(struct sockaddr_in6 *from, void *data, 
								uint16_t len, struct ip6_metadata *meta)
{
	call Leds.led1Toggle();
	call BtagCollectComms.sendto(&pppend, data, len);
}


event void BeaconComms.recvfrom(struct sockaddr_in6 *from, void *data, 
								uint16_t len, struct ip6_metadata *meta) 
{}
}
