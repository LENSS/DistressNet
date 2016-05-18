#ifndef _DISTRESSNET_H_
#define _DISTRESSNET_H_
#include <stdint.h>

/****************************** data format utils *******************************/

#define SwapTwoBytes(data) \
( (((data) >> 8) & 0x00FF) | (((data) << 8) & 0xFF00) )

#define SwapFourBytes(data)   \
( (((data) >> 24) & 0x000000FF) | (((data) >>  8) & 0x0000FF00) | \
  (((data) <<  8) & 0x00FF0000) | (((data) << 24) & 0xFF000000) )

#if __BYTE_ORDER == __LITTLE_ENDIAN
#	define	NTOHF(data)	swapf(data)
#else
#	define	NTOHF(data)	data
#endif

uint32_t swapf( uint32_t inFloat )
{
	uint32_t retVal;
	unsigned char *floatToConvert = ( unsigned char* ) & inFloat;
	unsigned char *returnFloat = ( unsigned char* ) & retVal;

	// swap the bytes into a temporary buffer
	returnFloat[0] = floatToConvert[3];
	returnFloat[1] = floatToConvert[2];
	returnFloat[2] = floatToConvert[1];
	returnFloat[3] = floatToConvert[0];

	return retVal;
}

union f_and_u 
{
	uint32_t u;
	float f;
};

static float u2f (uint32_t x)
{
  union f_and_u y;
  y.u = x;
  return y.f;
}

static uint32_t f2u (float x)
{
  union f_and_u y;
  y.f = x;
  return y.u;
}


/****************************** message structures *******************************/
/****************************** DONT FORGET NTOHS NTOHL***************************/

typedef struct
{  
	//	anything more than this and data wont be recvd on ppprouter, cos no blip fragmentation implemented
	uint16_t mote_id;           //  2  Mote id
	char address[10];		    // 30  This array size needs to be optimized for the packet size
	char task_force[10];        // 10  ID of group that searched building  
	char date_entered[7];       //  7  Date format ddmmyy
	char time_entered[5];       //  5  Date format hhmm  
	char date_exited[7];        //  7  Date format ddmmyy
	char time_exited[5];        //  5  Date format hhmm  
	char hazards[10];           // 30  This array size needs to be optimized for the packet size
	uint8_t living;            //  2  Number of people alive in the house
	uint8_t dead;              //  2  Number of people dead in the house 

	uint16_t curr_sink;
	uint32_t myscore;
	uint32_t sink_score;
	uint16_t qsize;
	uint16_t iter;
	uint16_t bcnt;
	uint16_t ccnt;
	uint32_t volt;
	uint16_t rpl_root_id;

}__attribute__ ((packed)) btag_t;

typedef struct
{
	uint8_t phoneid;
	float loc_x;
	float loc_y;
}__attribute__ ((packed)) phoneloc_t;

typedef struct
{
	uint16_t beacon_id;
	uint16_t beacon_cnt;
}__attribute__ ((packed)) beacon_msg_t;
 
typedef struct
{
	uint16_t node_id;
	uint32_t score;
	uint16_t ttl;
	uint16_t iter;
}__attribute__ ((packed)) election_msg_t;

typedef struct
{
	uint16_t seq;
	uint16_t root_id;
}__attribute__ ((packed)) rootelection_msg_t;


typedef struct
{
	uint16_t id;
	uint32_t loc_x;
	uint32_t loc_y;
}__attribute__ ((packed)) loc_t;

typedef struct
{
	btag_t the_btag;
	loc_t location;
}__attribute__ ((packed)) btagloc_t;



/****************************** all sorts of constants*******************/


enum 
{
	/****************************** Ports *******************************/	
	PORT_BTAG_COLLECT_ON_SINK = 5676,
	PORT_SINKELECTION = 5677,
	PORT_VEHBEACON = 5678,
	PORT_BTAG_COLLECT_ON_VEHICLE = 5679,
	PORT_BTAG_PROGRAMMER = 9999,
	PORT_ROOTELEC = 8100,

	/****************************** Timers ******************************/
	
 	TIMER_BLDG_TAG_GEN = 1 * 1024L,	//	generate every x secs
 	TIMER_RUN_ELECTION = 1024L*10,		// when to run election
 	TIMER_BATTERYVOLTAGE = 2000,	// Time to sample the voltage of battery
	TIMER_BEACON_BCAST = 2 * 1024L,	//	generate every x secs
	/****************************** Others ******************************/
	IAMSINK_TTL = 5,
};

#endif

