#include <ctime>
#include <iostream>
#include <string>
#include <signal.h>
#include <stdlib.h>
#include <boost/array.hpp>
#include <boost/bind.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/asio.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/filesystem.hpp>
#include <boost/algorithm/string.hpp>

#include <ibrdtn/api/Client.h>
#include <ibrdtn/api/FileBundle.h>
#include <ibrdtn/api/BLOBBundle.h>
#include <ibrcommon/net/tcpclient.h>
#include <ibrcommon/thread/Mutex.h>
#include <ibrcommon/thread/MutexLock.h>
#include <ibrcommon/data/BLOB.h>
#include <ibrcommon/Logger.h>

#include "../DistressNet.h"
#include "dn-utils.h"

#define NUM_USERS 4
#define NUM_ROUTERS 10

using namespace boost::filesystem;

dtn::api::Client *_client = NULL;
ibrcommon::tcpclient *_conn = NULL;
string fogbox_group_name = "dtn://fogboxgroup/fogbox";
dtn::data::EID group = std::string(fogbox_group_name);

bool terminated = false;

class fogbox_recv
{
public:
	fogbox_recv( boost::asio::io_service& io_service ) :
		t( io_service, boost::posix_time::seconds( 10 ) )
	{

		DN_DEBUG_MACRO << "Initialized" << std::endl;

		string file_source = "fogbox";

		int retry_cnt = 0;
		while(true){
			try{
				dtnapiconn_.open( "127.0.0.1", 4550 );
				dtnapiconn_.enableNoDelay();	//	for recving shit

				//dtnclient_ = new dtn::api::Client( file_source, dtnapiconn_ );
				dtnclient_ = new dtn::api::Client( file_source, group, dtnapiconn_ );
				DN_DEBUG_MACRO << "Created dtn client" << std::endl;
				
				dtnclient_->connect();
				DN_DEBUG_MACRO << "DTN client connected to ibrdtn daemon" <<std::endl;

				break;
			} catch (const ibrcommon::tcpclient::SocketException& ){
				if (retry_cnt >= 5){
					DN_DEBUG_MACRO << "cannot connect to 127.0.0.1:4550, exiting..." <<std::endl;
					exit(1);
				}
				retry_cnt++;
				DN_DEBUG_MACRO << "cannot connect to 127.0.0.1:4550, retrying..."<<std::endl;
				sleep(2);
			} catch (const dtn::api::ConnectionException& ){
				if (retry_cnt >=5){
					DN_DEBUG_MACRO << "cannot create dtn client, exiting..." <<std::endl;
					exit(1);
				}
				retry_cnt++;
				DN_DEBUG_MACRO << "cannot create dtn client, retrying..." <<std::endl;
				sleep(2);
			}
		}

		

		_conn = &dtnapiconn_;
		_client = dtnclient_;
		t.async_wait( boost::bind( &fogbox_recv::fogsync, this ) );
	}

	void fogsync()
	{
		//DN_DEBUG_MACRO << "timer fired" << std::endl;

		//	check for any recvd bundles

		//DN_DEBUG_MACRO << "started recv bundles" << std::endl;

		dtn::api::Bundle recvdb;

		bool recvd = true;
		try
		{
			recvdb = dtnclient_->getBundle( 5 );
		}
		catch ( const dtn::api::ConnectionTimeoutException& )
		{
		//	DN_DEBUG_MACRO << "Timeout, didn't recv any bundles" << std::endl;
			recvd = false;
		}

		if ( recvd )
		{
			DN_DEBUG_MACRO << "got a bundle!" << std::endl;
			ibrcommon::BLOB::Reference ref = recvdb.getData();

			fstream tmpfile;
			tmpfile.open( "/root/rsync/media/tmpfile", ios::in|ios::out|ios::binary|ios::trunc );
			tmpfile.exceptions( std::ios::badbit | std::ios::eofbit );

			tmpfile << ref.iostream()->rdbuf();
			DN_DEBUG_MACRO << "wrote to temp file" << endl;
			tmpfile.seekg ( 0, ios::beg );

			char c[256];
			tmpfile.get( c,256 );
			ref.iostream()->get( c,256 );

			stringstream filename;

			int counter = 0;
			while ( c[counter] != '|' )
				filename << c[counter++];

			DN_DEBUG_MACRO << "filename is " << filename.str() << endl;

			if ( boost::filesystem::exists( filename.str() ) )
			{
				DN_DEBUG_MACRO << "file exists, not overwriting" << endl;
			} else{
			
				string username = filename.str().substr(18,5);
				string truefile = filename.str().substr(24,filename.str().length()-1);
				stringstream lockfname;
				lockfname << "/root/rsync/media/"<<username<<"/recv/"<<truefile;

				ofstream ost(lockfname.str().c_str());
				ost.close();

				fstream actualfile;
				actualfile.open( filename.str().c_str(), ios::in|ios::out|ios::binary|ios::trunc );
				actualfile.exceptions( std::ios::badbit | std::ios::eofbit );

				tmpfile.seekg ( 0, ios::beg );
				tmpfile.seekg ( counter+3 );
				actualfile << tmpfile.rdbuf();

				DN_DEBUG_MACRO << "wrote to real file " << endl;

				actualfile.close();

				//	update lmt
				std::time_t t = boost::filesystem::last_write_time( filename.str() );
				lmt_map[filename.str()] = t;

				DN_DEBUG_MACRO << "size is " << boost::filesystem::file_size( filename.str() ) << " updated lmt is " << std::ctime( &t );
			}
			tmpfile.close();
		}

		//DN_DEBUG_MACRO << "restarting timer..." << endl;

		//t.expires_at( t.expires_at() + boost::posix_time::seconds( 5 ) );
		//t.async_wait( boost::bind( &fogbox_recv::fogsync, this ) );

		if (!terminated){
			t.expires_at( t.expires_at() + boost::posix_time::seconds( 5 ) );
			t.async_wait( boost::bind( &fogbox_recv::fogsync, this ) );
		}

	}

	~fogbox_recv()
	{

	}


private:
	boost::asio::deadline_timer t;
	dtn::api::Client* dtnclient_;
	ibrcommon::tcpclient dtnapiconn_;
	std::map<std::string, std::time_t> lmt_map;


};


void term( int signal )
{
	DN_DEBUG_MACRO << "caught signal, will stfu now" << endl;

	if ( signal >= 1 )
	{
		if ( _client != NULL )
		{
			DN_DEBUG_MACRO << "client->close()" << endl;
			_client->close();
			DN_DEBUG_MACRO << "conn->close()" << endl;
			_conn->close();
			DN_DEBUG_MACRO << "close done" << endl;

			terminated = true;
		}
	}
}

int main()
{
	DN_DEBUG_MACRO << "starting fogbox server" << std::endl;

	system( "mkdir -p /root/rsync/media/USER1/" );
	system( "mkdir -p /root/rsync/media/USER1/tmp/" );
	system( "mkdir -p /root/rsync/media/USER1/recv/" );

	system( "mkdir -p /root/rsync/media/USER2/" );
	system( "mkdir -p /root/rsync/media/USER2/tmp/" );
	system( "mkdir -p /root/rsync/media/USER2/recv/" );

	system( "mkdir -p /root/rsync/media/USER3/" );
	system( "mkdir -p /root/rsync/media/USER3/tmp/" );
	system( "mkdir -p /root/rsync/media/USER3/recv/" );

	system( "mkdir -p /root/rsync/media/USER4/" );
	system( "mkdir -p /root/rsync/media/USER4/tmp/" );
	system( "mkdir -p /root/rsync/media/USER4/recv/" );



	// catch process signals
	signal( SIGINT, term );
	signal( SIGTERM, term );


	boost::asio::io_service io_service;
	fogbox_recv myserver( io_service );
	io_service.run();


	return 0;
}










