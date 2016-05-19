#pragma once

//#define DN_DEBUG_MACRO std::cout<<dn_utils::get_time_since_jan12k()<<": " << __func__ << " "
#define DN_DEBUG_MACRO std::cout<<__TIME__<<": " << __func__ << " "

class dn_utils
{
	public:
	static time_t
	get_time_since_jan12k()
	{
		struct timeval now;
		::gettimeofday(&now, 0);
			
		return (now.tv_sec - 946684800);
	}
	
	
	
	static void
	print_btag_sinkstuff(btag_t btag)
	{
		printf("sinkstuff 2/2 frm: %d, snk: %d, scr: %ld, snkscr: %ld, qsize: %d, iter: %d, bcnt: %d, ccnt:%d, volt:%ld, root:%d ", 
            			ntohs(btag.mote_id), 
						ntohs(btag.curr_sink),
						ntohl(btag.myscore),
						ntohl(btag.sink_score),
						ntohs(btag.qsize),
						ntohs(btag.iter),
						ntohs(btag.bcnt),
						ntohs(btag.ccnt),
						ntohl(btag.volt),
						ntohs(btag.rpl_root_id)
						);
		
	}
	
	static void
	print_btagloc_loc(loc_t theloc)
	{
		printf("btagloc.loc id: %d, loc_x: %f, loc_y: %f ", 
            			ntohs(theloc.id), 
						u2f(ntohl(theloc.loc_x)),
						u2f(ntohl(theloc.loc_y))
			  );
		
	}

	
	static void
	print_btag_btagstuff(btag_t btag)
	{
		printf("btagstuff 1/2 id: %d, add: %s, tforce: %s, dent: %s, tent: %s, dext: %s, texit:%s, haz:%s, living:%d, dead:%d ", 
            			ntohs(btag.mote_id), 
						btag.address,
						btag.task_force,
						btag.date_entered,
						btag.time_entered,
						btag.date_exited,
						btag.time_exited,
						btag.hazards,
						btag.living,
						btag.dead
						);
	}
	
	static void
	print_btag(btag_t btag)
	{
		print_btag_btagstuff(btag);
		print_btag_sinkstuff(btag);
	}
	
	static void
	print_btagloc(btagloc_t btagloc)
	{
		print_btagloc_loc(btagloc.location);
		print_btag(btagloc.the_btag);
	}

	static bool
	equals_btag(btag_t b1, btag_t b2)
	{
		if ( 	b1.mote_id == b2.mote_id &&
				b1.living == b2.living &&
				b1.dead == b2.dead &&
				strcmp(b1.address, b2.address) == 0 &&
				strcmp(b1.task_force, b2.task_force) == 0 &&
				strcmp(b1.date_entered, b2.date_entered) == 0 &&
				strcmp(b1.time_entered, b2.time_entered) == 0 &&
				strcmp(b1.date_exited, b2.date_exited) == 0 &&
				strcmp(b1.time_exited, b2.time_exited) == 0 &&
				strcmp(b1.hazards, b2.hazards) == 0)
			return true;
		else
			return false;
	}
	
	static void
	print_raw_bytes(boost::array<unsigned char, 1024> b, std::size_t bytez)
	{
		printf("raw bytes: ");
		for (int i = 0; i < bytez; i++)
			printf("%x ", b.at(i));
		std::cout << std::endl;
	}
	
	static int
	gethostnumber()
	{
		char hostname[1024];
		hostname[1023] = '\0';
		gethostname(hostname, 1023);
		
		std::string hostnamestring(hostname);
		hostnamestring.erase(0, 6);
		
		return atoi(hostnamestring.c_str());
	}

	static std::string
	getwlan0ip()
	{
		std::stringstream temper;
		temper << "192.168." << gethostnumber() << ".1";
		return temper.str();
		
	}
	
	static std::string
	getwlan1ip()
	{
		std::stringstream temper;
		temper << "192.168.50." << gethostnumber();
		return temper.str();
		
	}
	
	static std::string
	getpppmoteip()
	{
		std::stringstream temper;
		temper << "fec0::" << std::hex << (gethostnumber()+51); // CHANGE THIS SHIT TO 50 HACK HACK
		return temper.str();
		
	}
};
