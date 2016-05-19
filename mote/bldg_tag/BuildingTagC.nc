#include "../DistressNet.h"
#include "lib6lowpan/ip.h"
//#include "blip_printf.h"
#include <stdio.h>

#define BE_NORMALIZE 5 //normalise the battery voltage to beacon count.
#define CAR_NORMALIZE 2 //10/5
#define BV_NORMALIZE 409 //normalise the battery voltage to beacon count.
//#define BV_NORMALIZE 3.2 //normalise the battery voltage to beacon count.

#define CAR_MAX_ID 10
#define MAX_BUFFER 10
#define MAX_NEIGHS_ID 15

// led 0 -
// led 1 -
// led 2 -

module BuildingTagC
{
	uses
	{
		interface Boot;
		interface Leds;
		interface SplitControl;
//		interface UartStream;

		interface RPLRoutingEngine as RPLRoute;
		interface RootControl;
		interface StdControl as RoutingControl;
		interface RPLDAORoutingEngine as RPLDAO;
		interface ForwardingTable as RoutingTable;

		interface UDP as BtagDataUDP;
		interface UDP as ElectionUDP;
		interface UDP as BeaconRecvUDP;
		interface UDP as ProgrammerUDP;
		interface UDP as RootSelectUDP;

		interface Timer<TMilli> as ElectionTimer;
		interface Timer<TMilli> as BatteryVoltageTimer; //  for sampling battery
		interface Timer<TMilli> as DataTimer; //  for generating data
		interface Timer<TMilli> as BroadTimer;  //
		interface Timer<TMilli> as SendTimer; //
// 		interface Timer<TMilli> as TestTimer;
		interface Timer<TMilli> as ResetBeaconTimer; //
		interface Timer<TMilli> as RootSelectionTimer;

		interface Read<uint16_t> as BatteryVoltageRead;
		interface Random;
	}
}

implementation
{

	struct in6_addr MULTICAST_ADDR;

	btagloc_t temp_btagloc;	// IS ALWAYS IN NETWORK BYTE ORDER
	btagloc_t btagloc_table[MAX_BUFFER];
	uint16_t btag_table_in = 0;
	uint16_t btag_table_out = 0;

	uint16_t sink_id;   //keeps the real dest...initially sets each node as sink
	uint16_t rpl_root_addr;   //keeps the real dest...initially sets each node as sink_id

//  local state storage
	uint32_t score = 0;
	uint32_t battery_voltage = 0;
	uint16_t beacon_count = 0;
	uint16_t car_count = 0;
	uint16_t cars[CAR_MAX_ID];
	uint32_t sink_score = 0;
	uint16_t election_iter = 0;
	uint16_t data_iter = 0;
	uint16_t elecsfilter[MAX_NEIGHS_ID]; // restricted flooding for election channel
	uint8_t election_timer_started = 0;

	uint8_t root_age = 0;
	uint16_t root_sequence = 0;

	rootelection_msg_t rootelecmsg;
	struct sockaddr_in6 rootelec_dest;

	event void
	Boot.booted()
	{
		sink_id = TOS_NODE_ID;	//	everyone send to themselves initially
		rpl_root_addr = 999;

		memset( MULTICAST_ADDR.s6_addr, 0, 16 );
		MULTICAST_ADDR.s6_addr[0] = 0xFF;
		MULTICAST_ADDR.s6_addr[1] = 0x2;
		MULTICAST_ADDR.s6_addr[15] = 0x1A;

		memset( &rootelec_dest.sin6_addr, 0, sizeof( struct in6_addr ) );
		memcpy( &rootelec_dest.sin6_addr, &MULTICAST_ADDR, sizeof( struct in6_addr ) );
		rootelec_dest.sin6_port = htons( PORT_ROOTELEC );

		memset( &temp_btagloc, 0x00, sizeof( btagloc_t ) );

		memset( cars, 0x00, CAR_MAX_ID*sizeof( uint16_t ) );

		call RoutingControl.start();
		call SplitControl.start();

		call BtagDataUDP.bind( PORT_BTAG_COLLECT_ON_SINK );
		call BeaconRecvUDP.bind( PORT_VEHBEACON );
		call ProgrammerUDP.bind( PORT_BTAG_PROGRAMMER );
		call ElectionUDP.bind( PORT_SINKELECTION );

		call RootSelectUDP.bind( PORT_ROOTELEC );
		
		//	setup the btag
	
		temp_btagloc.the_btag.mote_id = htons(TOS_NODE_ID);
		strcpy(temp_btagloc.the_btag.address, "BLDG 118");
		strcpy(temp_btagloc.the_btag.task_force, "TX-TF1");
		strcpy(temp_btagloc.the_btag.date_entered, "120514");
		strcpy(temp_btagloc.the_btag.time_entered, "0800");
		strcpy(temp_btagloc.the_btag.date_exited, "120518");
		strcpy(temp_btagloc.the_btag.time_exited, "1700");
		strcpy(temp_btagloc.the_btag.hazards, "CHEMICAL");
		temp_btagloc.the_btag.living = 2;
		temp_btagloc.the_btag.dead = 2;
		
		temp_btagloc.location.id = htons(TOS_NODE_ID);
		temp_btagloc.location.loc_x = htonl(f2u(30.678));
		temp_btagloc.location.loc_y = htonl(f2u(-96.345));


	}

	event void
	SplitControl.startDone( error_t err )
	{
		while( call RPLDAO.startDAO() != SUCCESS );

		call BatteryVoltageRead.read();
		call ElectionTimer.startOneShot( TIMER_RUN_ELECTION );
		election_timer_started = 1;

		call DataTimer.startOneShot( TIMER_BLDG_TAG_GEN );

		call RootSelectionTimer.startOneShot( call Random.rand16() % ( 1024L * 5 ) );
	}

	event void
	RootSelectionTimer.fired()
	{
		int rank;
		struct in6_addr * rootaddr;

		rank = call RPLRoute.getRank();
		rootaddr = call RPLRoute.getDodagId();

		printf( "------------my rank is %d root is %d rootid is %d\n", rank, ntohs( rootaddr->s6_addr16[7] ), rpl_root_addr );
		//printfflush();

		if ( rpl_root_addr == 999 ) // initialization
		{
			// i need to be a rpl root now
			call RootControl.setRoot();
			call Leds.led0On();
			rpl_root_addr = TOS_NODE_ID;
		}

		if ( rpl_root_addr == TOS_NODE_ID ) //	i am the root, so send my message
		{
			rootelecmsg.root_id = rpl_root_addr;
			rootelecmsg.seq = root_sequence++;
			call RootSelectUDP.sendto( &rootelec_dest, &rootelecmsg, sizeof( rootelection_msg_t ) );
		}
		else // i have a root, i am not the root
		{
			root_age++;
			if ( root_age > 10 ) // haven't heard from the root in a while
			{
				// reset root
				root_age = 0;
				rpl_root_addr = 999;
				root_sequence = 0;
			}

		}

		call RootSelectionTimer.startOneShot( 3*1024L );
	}

	event void
	RootSelectUDP.recvfrom( struct sockaddr_in6 *from, void *payload, uint16_t len, struct ip6_metadata *meta )
	{

		rootelection_msg_t* temper = ( rootelection_msg_t* ) payload;
		root_sequence = temper->seq;

		if ( rpl_root_addr == TOS_NODE_ID ) //	if i think i am a root
		{
			if ( temper->root_id < rpl_root_addr )	//	there is another root, he wins
			{
				call RootControl.unsetRoot();
				call Leds.led0Off();

				//	act like a regular node
				rpl_root_addr = temper->root_id;
				root_sequence = temper->seq;
				root_age = 0;
			}
		}
		else //	i am a regular node
		{
			if ( rpl_root_addr == 999 ) //	if i don't have a root
			{
				rpl_root_addr = temper->root_id;
				root_sequence = temper->seq;
				root_age = 0;
			}
			else if ( temper->root_id > rpl_root_addr ) // this guy is an impostor
			{
				//	ignore this message, send the real root's msg TODO
			}
			else if ( temper->root_id == rpl_root_addr ) // i know this guy, so rebroad
			{
				if ( temper->seq > root_sequence )
				{
					root_sequence = temper->seq;
					root_age = 0;
					call RootSelectUDP.sendto( &rootelec_dest, payload, sizeof( rootelection_msg_t ) );
				}

			}
			else //	i have a root, but this guy wins
			{
				rpl_root_addr = temper->root_id;
				root_sequence = temper->seq;
				root_age = 0;
				call RootSelectUDP.sendto( &rootelec_dest, payload, sizeof( rootelection_msg_t ) );
			}



		}



	}

	event void
	BatteryVoltageRead.readDone( error_t result, uint16_t data )
	{
		if ( result == SUCCESS )
		{
			battery_voltage = data;
		}
		call BatteryVoltageTimer.startOneShot( TIMER_BATTERYVOLTAGE );
	}


	event void
	BatteryVoltageTimer.fired()
	{
		call BatteryVoltageRead.read();
	}

	event void
	ElectionTimer.fired()
	{
		election_iter++;
		score = 2*beacon_count/BE_NORMALIZE +
		        3*car_count*CAR_NORMALIZE +
		        battery_voltage/BV_NORMALIZE;

 	printf("DN Election timer fired ");
 	printf("DN [beacon_count: %u] [car_count: %u][battery_voltage: %lu] [score: %lu] [sink_score: %lu]\n", beacon_count, car_count, battery_voltage, score, sink_score);

		// see if anything needs to be changed
		if 	( 	( score < sink_score && sink_id == TOS_NODE_ID ) ||
		        ( score == sink_score && sink_id >= TOS_NODE_ID ) ||
		        ( score > sink_score )
		    )
		{
			//if I am the sink, but my score drops, or my score as good as the sink, and my id <= sink_id, or my score is better than sink score.

			election_msg_t* spkt;
			election_msg_t el;
			struct sockaddr_in6 dest;

// 		if (score < sink_score && sink_id == TOS_NODE_ID)
// 			printf("DN I will not be the sink\n");
// 		else
// 			printf("DN I will become the sink\n");

			memset( &dest.sin6_addr, 0, sizeof( struct in6_addr ) );
			memcpy( dest.sin6_addr.s6_addr, call RPLRoute.getDodagId(), sizeof( struct in6_addr ) );
			dest.sin6_port = htons( PORT_SINKELECTION );

// 		call Leds.led2On();
			//  ok so i am the new sink
			sink_score = score;
			sink_id = TOS_NODE_ID;

			//  let everyone know i am the new sink...
			//spkt = (election_msg_t*)(call Packet.getPayload(&pkt, sizeof(election_msg_t)));
			spkt = &el;

			spkt->score = score;
			spkt->node_id = TOS_NODE_ID;
			spkt->ttl = IAMSINK_TTL;
			spkt->iter = election_iter;
			//call ElectionSend.send(AM_BROADCAST_ADDR, &el, sizeof(election_msg_t));
			call ElectionUDP.sendto( &dest, &el, sizeof( election_msg_t ) );
		}

		call ElectionTimer.startOneShot( TIMER_RUN_ELECTION );
	}

	event void
	DataTimer.fired()
	{
		//  lets generate data...debug or btags or whatever

		data_iter++;

		temp_btagloc.the_btag.mote_id = htons( TOS_NODE_ID );
		temp_btagloc.the_btag.curr_sink = htons( sink_id );
		temp_btagloc.the_btag.myscore = htonl( score );
		temp_btagloc.the_btag.sink_score = htonl( sink_score );
		temp_btagloc.the_btag.qsize = htons( btag_table_in );
		temp_btagloc.the_btag.iter = htons( data_iter );
		temp_btagloc.the_btag.bcnt = htons( beacon_count );
		temp_btagloc.the_btag.ccnt = htons( car_count );
		temp_btagloc.the_btag.volt = htonl( battery_voltage );
		temp_btagloc.the_btag.rpl_root_id = htons( rpl_root_addr );
		
		temp_btagloc.location.id = htons( TOS_NODE_ID );


		atomic
		{
			memcpy( &( btagloc_table[btag_table_in] ), &temp_btagloc, sizeof( btagloc_t ) );
			btag_table_in++;
			btag_table_in = btag_table_in % MAX_BUFFER;
		}

		if ( sink_id == TOS_NODE_ID )
		{
//  		call Leds.led2On();
			// add message to outgoing car buffer...
// 		printf("DN now I'm the sink, just save the data into my buffer\n");
		}
		else
		{
// 		printf("DN I have a sink %d, send all data to it\n", sink_id);

//  		call Leds.led2Off();
			if( sink_id != TOS_NODE_ID && btag_table_in != btag_table_out )
			{
				call SendTimer.startOneShot( 100 );
			}
		}

		call DataTimer.startOneShot( TIMER_BLDG_TAG_GEN );
	}

	event void
	BtagDataUDP.recvfrom( struct sockaddr_in6 *from, void *payload, uint16_t len, struct ip6_metadata *meta )
	{

		//  received some data...if i am the sink, copy to buff, else rebroadcast

		btagloc_t* temper = ( btagloc_t* ) payload;

     printf("DN some data recved from %d\n", ((from->sin6_addr.in6_u.u6_addr16[7]>>8 & 0x00ff) | from->sin6_addr.in6_u.u6_addr16[7]<<8));

		//  why need own message?
		if 	(	(
		            ( from->sin6_addr.in6_u.u6_addr16[7]>>8 & 0x00ff ) |
		            from->sin6_addr.in6_u.u6_addr16[7] << 8
		        ) == TOS_NODE_ID
		    )
			return ;


// 	call Leds.led1Toggle();

		//  if i am the sink...
		if ( sink_id == TOS_NODE_ID )
		{
// 		printf("DN copying to buf @ %d\n", btag_table_in);
			// add message to outgoing car buffer...
			atomic
			{
				printf("put it into my buffer\n");
				memcpy( &btagloc_table[btag_table_in], temper, sizeof( btagloc_t ) );
				btag_table_in++;
				btag_table_in = btag_table_in % MAX_BUFFER;
			}
		}
		else
		{
			//  TODO: rebroadcast
			//	TODO: rebroadcast is meaningless in RPL
			//call DataSend.send(AM_BROADCAST_ADDR, msg, sizeof(btag_t));
		}
	}


	election_msg_t sinkmsg;
	uint16_t index;

//	probably sends the sink id to everynode in the rpl tree
	event void
	BroadTimer.fired()
	{
		struct sockaddr_in6 dest;
		struct route_entry * routing_table;
		int routing_table_sz;
		uint8_t i;

		routing_table = call RoutingTable.getTable( &routing_table_sz );

		for ( i = index; i < routing_table_sz; i++ )
		{
			if ( routing_table[i].valid )
			{
				if 	( sink_id ==
				        ( ( routing_table[i].prefix.in6_u.u6_addr16[7]>>8 & 0x00ff ) | routing_table[i].prefix.in6_u.u6_addr16[7]<<8 )
				    )
					continue;

 			printf(	"DN send to node%d\n",((routing_table[i].prefix.in6_u.u6_addr16[7]>>8 & 0x00ff) | routing_table[i].prefix.in6_u.u6_addr16[7]<<8));

				//delay(60000);
				memset( &dest.sin6_addr, 0, sizeof( struct in6_addr ) );
				memcpy( &dest.sin6_addr, &routing_table[i].prefix, sizeof( struct in6_addr ) );

				if ( sink_id == ( ( routing_table[i].prefix.in6_u.u6_addr16[7]>>8 & 0x00ff ) | routing_table[i].prefix.in6_u.u6_addr16[7]<<8 ) )
					continue;

 			printf("DN send to node%d\n", ((routing_table[i].prefix.in6_u.u6_addr16[7]>>8 & 0x00ff) | routing_table[i].prefix.in6_u.u6_addr16[7]<<8));

				//delay(60000);
				memset( &dest.sin6_addr, 0, sizeof( struct in6_addr ) );
				memcpy( &dest.sin6_addr, &routing_table[i].prefix, sizeof( struct in6_addr ) );
				//memcpy(&dest.sin6_addr, &MULTICAST_ADDR, sizeof(struct in6_addr));

				dest.sin6_port = htons( PORT_SINKELECTION );
				call ElectionUDP.sendto( &dest, &sinkmsg, sizeof( election_msg_t ) );

				//printf_in6addr(&routing_table[i].prefix);
				//printf("/%i\t\t", routing_table[i].prefixlen);
				//printf_in6addr(&routing_table[i].next_hop);
				//printf("\t\t%i\n", routing_table[i].ifindex);
				break;
				//memcpy(&dest.sin6_addr, &MULTICAST_ADDR, sizeof(struct in6_addr));

				dest.sin6_port = htons( PORT_SINKELECTION );
				call ElectionUDP.sendto( &dest, &sinkmsg, sizeof( election_msg_t ) );

				//printf_in6addr(&routing_table[i].prefix);
				//printf("/%i\t\t", routing_table[i].prefixlen);
				//printf_in6addr(&routing_table[i].next_hop);
				//printf("\t\t%i\n", routing_table[i].ifindex);
				break;
			}
		}

		//printf("index: %d\n", i);
		if( i != routing_table_sz )
			call BroadTimer.startOneShot( 20 );
		index = ++i;

	}

	event void
	ElectionUDP.recvfrom ( struct sockaddr_in6 *from, void *payload, uint16_t len, struct ip6_metadata *meta )
	{

		election_msg_t* iamsink;
		uint32_t tempsink_score;

		iamsink = ( election_msg_t* ) payload;
		memcpy( &sinkmsg, iamsink, sizeof( election_msg_t ) );

 	printf("DN Election Received from %d [score:%lu]\n", iamsink->node_id, iamsink->score);

		if( TOS_NODE_ID == rpl_root_addr )
		{

// 		printf("DN I'm the root, I do the broadcast\n");
			sink_id = iamsink->node_id;

			index = 0;
			//post broadcast();
			call BroadTimer.startOneShot( 100 );

		}
		else
		{
			if( iamsink->node_id == TOS_NODE_ID )
				return ;

			if ( iamsink->iter <= elecsfilter[iamsink->node_id] )
				return ;

			elecsfilter[iamsink->node_id] = iamsink->iter;

			tempsink_score = iamsink->score; // score of the recvd sink

			//  begin the crux
			if ( score <= tempsink_score ) // || (score == tempsink_score && iamsink->node_id < TOS_NODE_ID))
			{
				//  he is the sink..
				//  just rebroadcast
				if( !election_timer_started )
				{
					call ElectionTimer.startOneShot( TIMER_RUN_ELECTION );
					election_timer_started = 1;
				}

// 			printf("DN I'm a normal node, I choose my sink to %d\n", iamsink->node_id);

				sink_id = iamsink->node_id;
				sink_score = tempsink_score;
// 			call Leds.led2Off();
			}

			if ( score > tempsink_score )
			{
				//  i am the actual sink...do not rebroadcast this
// 			call Leds.led2On();
			}
		}
	}

	event void
	SendTimer.fired()
	{
		struct sockaddr_in6 dest;
		memset( &dest.sin6_addr, 0, sizeof( struct in6_addr ) );

		if( sink_id == TOS_NODE_ID )
		{
			call Leds.led2Toggle();
			memcpy( &dest.sin6_addr, &MULTICAST_ADDR, sizeof( struct in6_addr ) );
// 		inet_pton6("fec0::100", &dest.sin6_addr);

			dest.sin6_port = htons( PORT_BTAG_COLLECT_ON_VEHICLE );
			printf("<<<<broadcast sent %d\n", btag_table_out);
// 		printf("DN <<<<broadcast sent frm: %d, snk: %d, scr: %ld, snkscr: %ld, qsize: %d, iter: %d, bcnt: %d, ccnt:%d, volt:%ld \n\r",
// 						btag_table[btag_table_out].mote_id,
// 						btag_table[btag_table_out].curr_sink,
// 						btag_table[btag_table_out].myscore,
// 						btag_table[btag_table_out].sink_score,
// 						btag_table[btag_table_out].qsize,
// 						btag_table[btag_table_out].iter,
// 						btag_table[btag_table_out].bcnt,
// 						btag_table[btag_table_out].ccnt,
// 						btag_table[btag_table_out].volt);
		}
		else
		{
			//memcpy(&dest.sin6_addr, &MULTICAST_ADDR, sizeof(struct in6_addr));
			inet_pton6( "fec0::/64", &dest.sin6_addr );
			dest.sin6_addr.in6_u.u6_addr16[7] = ( ( ( uint16_t )sink_id << 8 ) | ( ( uint16_t )sink_id >> 8 ) ) & 0xffff;
			dest.sin6_port = htons( PORT_BTAG_COLLECT_ON_SINK );
			//printf("<<<<unicast sent %d\n", btag_table_out);
// 		printf("DN <<<<unicast sent frm: %d, snk: %d, scr: %ld, snkscr: %ld, qsize: %d, iter: %d, bcnt: %d, ccnt:%d, volt:%ld \n\r",
// 						btag_table[btag_table_out].mote_id,
// 						btag_table[btag_table_out].curr_sink,
// 						btag_table[btag_table_out].myscore,
// 						btag_table[btag_table_out].sink_score,
// 						btag_table[btag_table_out].qsize,
// 						btag_table[btag_table_out].iter,
// 						btag_table[btag_table_out].bcnt,
// 						btag_table[btag_table_out].ccnt,
// 						btag_table[btag_table_out].volt);
		}
		//inet_pton6("fec0::/64", &dest.sin6_addr);
		//dest.sin6_addr.in6_u.u6_addr16[7] = (((uint16_t )9 << 8) | ((uint16_t )9 >> 8)) & 0xffff;


		atomic
		{
			call BtagDataUDP.sendto( &dest, &( btagloc_table[btag_table_out] ), sizeof( btagloc_t ) );
			//printf_in6addr(&routing_table[i].prefix);
			//printf("/%i\t\t", routing_table[i].prefixlen);
			//printf_in6addr(&routing_table[i].next_hop);
			//printf("\t\t%i\n", routing_table[i].ifindex);
			btag_table_out++;
			btag_table_out = btag_table_out % MAX_BUFFER;

			if( btag_table_in != btag_table_out )
			{
				call SendTimer.startOneShot( 30 );
			}
			//else
			//  call TestTimer.startOneShot(30000);
		}

	}

// event void
// TestTimer.fired()
// {
// 	struct route_entry * routing_table;
// 	int routing_table_sz;
// 	uint8_t i;
// 	printf("DN [beacon_count: %u] [car_count: %u][battery_voltage: %lu] [score: %lu] [sink_score: %lu]\n",
// 	beacon_count, car_count, battery_voltage, score, sink_score);
//
// 	routing_table = call RoutingTable.getTable(&routing_table_sz);
//
//
// 	printf("DN \n=========routing table\n");
// 	for (i = 0; i < routing_table_sz; i++)
// 	{
// 		if (routing_table[i].valid)
// 		{
// 			printf("DN ==========[%d] %d\n", i, ((routing_table[i].prefix.in6_u.u6_addr16[7]>>8 & 0x00ff) | routing_table[i].prefix.in6_u.u6_addr16[7]<<8));
// 		}
// 	}
//
// 	printf("\n\n");
//
// 	call TestTimer.startOneShot(30 * 1024L); //30s
// }

//		to age the beacons and expire them
	event void
	ResetBeaconTimer.fired()
	{
		if ( beacon_count > 0 )
			beacon_count--;

		call ResetBeaconTimer.startOneShot( 6000 );

	}

	event void
	ProgrammerUDP.recvfrom( struct sockaddr_in6 *from, void *payload, uint16_t len, struct ip6_metadata *meta )
	{
		btagloc_t* temp = ( btagloc_t* ) payload;
		uint16_t destid = ntohs( temp->the_btag.mote_id );

// 	call Leds.led1Toggle();

		if ( destid == TOS_NODE_ID )
		{
			memcpy( &temp_btagloc, payload, len );
			call Leds.led1Toggle();
		}
		else
		{
			struct sockaddr_in6 dest;
			memset( &dest.sin6_addr, 0, sizeof( struct in6_addr ) );

			inet_pton6( "fec0::/64", &dest.sin6_addr );
			dest.sin6_addr.in6_u.u6_addr16[7] = ( ( ( uint16_t )destid << 8 ) | ( ( uint16_t )destid >> 8 ) ) & 0xffff;
			dest.sin6_port = htons( 9999 );

			call ProgrammerUDP.sendto( &dest, payload, sizeof( btagloc_t ) );

		}

	}


	event void
	BeaconRecvUDP.recvfrom( struct sockaddr_in6 *from, void *payload, uint16_t len, struct ip6_metadata *meta )
	{

		beacon_msg_t* beacon = ( beacon_msg_t* ) payload;

		printf("received beacon\n");

		if( !election_timer_started )
		{
// 		printf("DN start sink election timer\n");
			call ElectionTimer.startOneShot( TIMER_RUN_ELECTION );
			election_timer_started = 1;
		}

		if ( beacon->beacon_id > CAR_MAX_ID )
		{
			beacon->beacon_id = ( beacon->beacon_id ) % MAX_NEIGHS_ID;
		}
		//  update car stats....first time seeing car?
		if( cars[beacon->beacon_id] == 0 )
		{
			beacon_count++;
			car_count++;
			//      cars[beacon->beacon_id] = beacon->beacon_cnt;
			cars[beacon->beacon_id] = beacon_count;
		}
		else
		{
			printf("%u, %u\n", beacon->beacon_cnt, cars[beacon->beacon_id]);
			//  seen this car before...so update only new beacons
			//      if(beacon->beacon_cnt >= cars[beacon->beacon_id])
			//      {
			//        //aged beacon
			//        if (beacon->beacon_cnt-cars[beacon->beacon_id] > 5){
			//          beacon_count++;
			//        }
			//
			//        cars[beacon->beacon_id] = beacon->beacon_cnt;
			//      }
			beacon_count++;
			cars[beacon->beacon_id] = beacon_count;
		}

		//    if(beacon_count>30)
		//      beacon_count=30;
		//
		//    if(car_count>5)
		//      car_count=5;

		//  also send data to car right now
		if( sink_id == TOS_NODE_ID && btag_table_in != btag_table_out )
		{
			call SendTimer.startOneShot( 100 );
		}
	}


	event void
	SplitControl.stopDone( error_t e ) {}

// 	async event void UartStream.sendDone(uint8_t *buf, uint16_t len, error_t error)
//  {
//  }
// 
//  async event void UartStream.receivedByte(uint8_t byte)
//  {
//  }
// 
//  async event void UartStream.receiveDone(uint8_t* buf, uint16_t len, error_t error)
//  {
//  }

}//finis

