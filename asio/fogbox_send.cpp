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

class fogbox_send
{
public:
	fogbox_send( boost::asio::io_service& io_service ) :
		t( io_service, boost::posix_time::seconds( 10 ) )
	{

		DN_DEBUG_MACRO << "Initialized" << std::endl;

		string file_source = "fogbox";

		int retry_cnt = 0;

		try{
			while(true){
				dtnapiconn_.open( "127.0.0.1", 4550 );
				dtnapiconn_.enableNoDelay();	//	for recving shit

				//dtnclient_ = new dtn::api::Client( file_source, dtnapiconn_ );
				dtnclient_ = new dtn::api::Client( file_source, dtnapiconn_, dtn::api::Client::MODE_SENDONLY );
				DN_DEBUG_MACRO << "Created dtn client" << std::endl;

				dtnclient_->connect();
				DN_DEBUG_MACRO << "DTN client connected to ibrdtn daemon" <<std::endl;

				break;
			}
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

		loadMetadata();

		_conn = &dtnapiconn_;
		_client = dtnclient_;
		t.async_wait( boost::bind( &fogbox_send::fogsync, this ) );
	}

	void fogsync()
	{
		//	send stuff now
		string file_destination;

		unsigned int lifetime = 10800;
		int priority = 1;

		for ( int user_id = 1; user_id <= NUM_USERS; user_id++ )
		{
			std::stringstream dirpath;
			dirpath << "/root/rsync/media/USER" << user_id << "/";

			//DN_DEBUG_MACRO << "directory is " << dirpath.str() << std::endl;

			path dir_path( dirpath.str() );

			directory_iterator end_itr; // default construction yields past-the-end
			for ( directory_iterator itr( dir_path ); itr != end_itr; ++itr )
			{
				//	ignore directories
				if ( is_directory( itr->status() ) )
				{
					continue;
				}

				//don't bother tmp files
				if (boost::algorithm::ends_with( itr->leaf(), ".tmp" ))
					continue;

				std::string fqfilename = itr->string();

				std::time_t t = boost::filesystem::last_write_time( fqfilename ) ;

			//	DN_DEBUG_MACRO << "file " << fqfilename << " size " << boost::filesystem::file_size( fqfilename ) << " lmt " << std::ctime( &t );

			//	DN_DEBUG_MACRO << "extension is " << itr->path().extension() << endl;

				if ( ! ( boost::algorithm::ends_with( itr->leaf(), ".jpg" ) || boost::algorithm::ends_with( itr->leaf(), ".JPG" ) ) )
				{
				//	DN_DEBUG_MACRO << "ignoring based on extension" << endl;
					continue;
				}

				ibrcommon::BLOB::Reference ref = ibrcommon::BLOB::create();

				if ( lmt_map.find( fqfilename ) != lmt_map.end() )
				{
				//	DN_DEBUG_MACRO << "lmt in database is " << std::ctime( &lmt_map[fqfilename] );

					//	this is an old file
					if ( t <= lmt_map[fqfilename] )
					{
				//		DN_DEBUG_MACRO << "not sending since old file " << endl;
						continue;
					}

				}


				string username = fqfilename.substr(18,5);
				string truefile = fqfilename.substr(24,fqfilename.length()-1);
				stringstream lockfname;
				lockfname << "/root/rsync/media/"<<username<<"/recv/"<<truefile;

				if ( boost::filesystem::exists( lockfname.str() ) )
				{
				//	DN_DEBUG_MACRO << "this is a received file: "<<truefile<<", don't resend !" << endl;
					continue;
				}

				DN_DEBUG_MACRO << "Found a new file: " << fqfilename <<" size: " << boost::filesystem::file_size( fqfilename ) << std::endl;

				//	file came from rsync, so it is new
				lmt_map[fqfilename] = t;

				DN_DEBUG_MACRO << " sending file " << fqfilename << " to ";
				std::ifstream filer( fqfilename.c_str() );
				( *ref.iostream() ) << fqfilename << "|||" << filer.rdbuf() ;
				( *ref.iostream() ).flush();

				filer.close();


				file_destination = "dtn://router";
				file_destination = fogbox_group_name;
				dtn::api::BLOBBundle b( file_destination, ref );
				b.setPriority( dtn::api::Bundle::BUNDLE_PRIORITY( priority ) );
				b.setLifetime( lifetime );

				//for ( int k = 1; k <= NUM_ROUTERS; k++ )
				{
					//if ( k == dn_utils::gethostnumber() )
					//	continue;

					//cout << k << " ";

					//stringstream temper;
					//temper << file_destination << k << ".dtn/fogbox";

					DN_DEBUG_MACRO << file_destination <<std::endl;

					b.setDestination( file_destination );
					b.setSingleton(false);
					//b.setDestination( temper.str() );

					// send the bundle
					*dtnclient_ << b;
					dtnclient_->flush();
					sleep( 1 );
				}// each destination
				//cout << endl;
			}// each file
		}// each user

		if (!terminated){
			t.expires_at( t.expires_at() + boost::posix_time::seconds( 10 ) );
			t.async_wait( boost::bind( &fogbox_send::fogsync, this ) );
		} else{
			writeMetadata();
		}
	}

	~fogbox_send()
	{

	}

	void writeMetadata(){
		ofstream ost("/root/rsync/media/.fogboxmeta");
		if (!ost){
			DN_DEBUG_MACRO << "unable to open meta data file: /root/rsync/media/.fogboxmeta" << std::endl;
		} else {
			DN_DEBUG_MACRO << "writing meta data file: /root/rsync/media/.fogboxmeta" << std::endl;
			for (std::map<std::string, std::time_t>::iterator itr = lmt_map.begin(); itr != lmt_map.end(); itr++){
				ost << itr->first << " " << itr->second << std::endl;
			}
			ost << "end" << std::endl;
			ost.close();
		}
	}
	
	void loadMetadata(){
		ifstream ist("/root/rsync/media/.fogboxmeta");
		std::string file;
		std::time_t t;
		if (!ist){
			DN_DEBUG_MACRO << "unable to open meta data file: /root/rsync/media/.fogboxmeta" << std::endl;
		} else{
			DN_DEBUG_MACRO << "load meta data successful: /root/rsync/media/.fogboxmeta" << std::endl;
			while(!ist.eof()){
				ist >> file;
				if (file == "end")
					break;
				else
					ist >> t;

				lmt_map[file] = t;
			}
		}
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
			try{
				_client->close();
			} catch (const ibrcommon::IOException &ex) {
				cout << "Error: " << ex.what() << endl;
            } catch (const dtn::api::ConnectionException&) {
                // connection already closed, the daemon was faster
            }
			DN_DEBUG_MACRO << "conn->close()" << endl;
			
			try{
				_conn->close();
			} catch (const std::exception &ex) {
                 cout << "Error: " << ex.what() << endl;
         }
			DN_DEBUG_MACRO << "close done" << endl;

			terminated = true;
		}
	}
}

int main()
{
	DN_DEBUG_MACRO << "starting fogbox_send" << std::endl;

	system( "mkdir -p /root/rsync/media/USER1/" );
	system( "mkdir -p /root/rsync/media/USER2/" );
	system( "mkdir -p /root/rsync/media/USER3/" );
	system( "mkdir -p /root/rsync/media/USER4/" );

	// catch process signals
	signal( SIGINT, term );
	signal( SIGTERM, term );


	boost::asio::io_service io_service;
	fogbox_send myserver( io_service );
	io_service.run();


	return 0;
}










