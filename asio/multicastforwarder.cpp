#include <ctime>
#include <iostream>
#include <string>
#include <signal.h>
#include <boost/array.hpp>
#include <boost/bind.hpp>
#include <boost/shared_ptr.hpp>
#include <boost/asio.hpp>

#include <boost/archive/text_oarchive.hpp>
#include <boost/archive/text_iarchive.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
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


using boost::asio::ip::udp;

dtn::api::Client *_client = NULL;
ibrcommon::tcpclient *_conn = NULL;

string btag_group_name = "dtn://btaggroup/btag";


class udp_server
{
public:
	btagloc_t allbtags[20];

	udp_server( boost::asio::io_service& io_service ) :
		wlan0socket( io_service, udp::endpoint( udp::v4(), 7009 ) ),
		wlan1socket( io_service, udp::endpoint( boost::asio::ip::address_v4::from_string( dn_utils::getwlan1ip().c_str() ), 7011 ) ),
		t( io_service, boost::posix_time::seconds( 2 ) )

	{
		cout<<"entering udp_server constructor"<<endl;

		boost::asio::ip::address multicast_address = boost::asio::ip::address::from_string( "225.0.11.5" );
		cout<<"1"<<endl;

		boost::asio::ip::multicast::join_group option( multicast_address );

		cout<<"2"<<endl;

		wlan0socket.set_option( option );
		cout<<"3"<<endl;

		DN_DEBUG_MACRO << "Joined multicast group" << std::endl;
		DN_DEBUG_MACRO << "Initialized, starting recv" << std::endl;

		string file_source = "btagsrecv";
		dtnapiconn_.open( "127.0.0.1", 4550 );
		dtnapiconn_.enableNoDelay();	//	for recving shit

		recv_dtnapiconn_.open("127.0.0.1", 4550);
		recv_dtnapiconn_.enableNoDelay();


		dtnclient_ = new dtn::api::Client( file_source, dtnapiconn_ );
		DN_DEBUG_MACRO << "Created dtn client" << std::endl;
		dtnclient_->connect();

		recv_dtnclient_ = new dtn::api::Client(file_source, btag_group_name, recv_dtnapiconn_);
		recv_dtnclient_->connect();

		_conn = &dtnapiconn_;
		_client = dtnclient_;

		for ( int i = 0; i < 20; i++ )
		{
			allbtags[i].the_btag.mote_id = htons( 111 );

		}


		recv_wlan0();
		recv_wlan1();

		t.async_wait( boost::bind( &udp_server::handler, this, _1 ) );
	}

	~udp_server()
	{
		DN_DEBUG_MACRO <<  "Signal caught..." << endl;

	}



private:

	void
	handler( const boost::system::error_code& error )
	{
		DN_DEBUG_MACRO << "started recv bundles" << std::endl;
		dtn::api::Bundle recvdb;

label:
		bool recvd = true;
		try
		{
			//recvdb = dtnclient_->getBundle( 5 );
			recvdb = recv_dtnclient_->getBundle( 5 );
		}
		catch ( const dtn::api::ConnectionTimeoutException& )
		{
			DN_DEBUG_MACRO << "Timeout, didn't recv any bundles" << std::endl;
			recvd = false;
		}

		if ( recvd )
		{
			ibrcommon::BLOB::Reference ref = recvdb.getData();
			btagloc_t btag;
			( *ref.iostream() ).read( ( char* ) &btag, sizeof( btagloc_t ) );

			uint16_t temper = ntohs( btag.the_btag.mote_id );
			memcpy( &allbtags[temper], &btag, sizeof( btagloc_t ) );

			DN_DEBUG_MACRO << "recvd a bundle..." << std::endl;
			DN_DEBUG_MACRO << "btagloc is ";
			dn_utils::print_btagloc( allbtags[temper] );
			printf( "\r\n" );

			goto label;
		}



		for ( int i = 0; i < 20; i++ )
		{
			btagloc_t* btagloc = allbtags + i;
			DN_DEBUG_MACRO << "20 cache idx is " << i << std::endl;

			if ( ntohs( btagloc->the_btag.mote_id ) == 111 )
			{
				DN_DEBUG_MACRO << "btag array idx is 111, continuing" << std::endl;
				continue;
			}

			DN_DEBUG_MACRO << "btagloc is ";
			dn_utils::print_btagloc( *btagloc );
			printf( "\r\n" );

			wlan0socket.async_send_to(
			    boost::asio::buffer( btagloc, sizeof( btagloc_t ) ),
			    udp::endpoint( boost::asio::ip::address_v4::from_string( "225.0.11.5" ), 7004 ),
			    boost::bind( &udp_server::sent_wlan0, this, boost::asio::placeholders::error, boost::asio::placeholders::bytes_transferred )
			);



		}

		t.expires_at( t.expires_at() + boost::posix_time::seconds( 10 ) );
		DN_DEBUG_MACRO << "restarting timer" << std::endl;
		t.async_wait( boost::bind( &udp_server::handler, this, _1 ) );
	}




	void recv_wlan0()
	{
		wlan0socket.async_receive_from(
		    boost::asio::buffer( recvbuf_wlan0 ),
		    remote_wlan0,
		    boost::bind( &udp_server::recvd_on_wlan0, this,
		                 boost::asio::placeholders::error,
		                 boost::asio::placeholders::bytes_transferred ) );

	}

	void recv_wlan1()
	{
		wlan1socket.async_receive_from(
		    boost::asio::buffer( recvbuf_wlan1 ),
		    remote_wlan1,
		    boost::bind( &udp_server::recvd_on_wlan1, this,
		                 boost::asio::placeholders::error,
		                 boost::asio::placeholders::bytes_transferred ) );

	}


	void sent_wlan0( const boost::system::error_code& ec, std::size_t bytez )
	{
		DN_DEBUG_MACRO << "sent " << bytez << " on wlan0 error code " << ec.value() << " " << ec.message() << std::endl;
	}

	void sent_wlan1( const boost::system::error_code& ec, std::size_t bytez )
	{
		DN_DEBUG_MACRO << "sent " << bytez << " on wlan1 error code " << ec.value() << " " << ec.message() << std::endl;
	}

	void
	recvd_on_wlan0( const boost::system::error_code& error, std::size_t bytez )
	{
		DN_DEBUG_MACRO << "recvd " << bytez << " on wlan0" << endl;
		dn_utils::print_raw_bytes( recvbuf_wlan0, bytez );

		if ( !error || error == boost::asio::error::message_size )
		{
			//	incoming data is btagloc
			//	this comes from ipads
			btagloc_t btagloc;
			memcpy( &btagloc, &recvbuf_wlan0, bytez );

			DN_DEBUG_MACRO << "btagloc is ";
			dn_utils::print_btagloc( btagloc );
			printf( "\r\n" );

			for ( int i = 1; i <= 10; i++ )
			{
				std::stringstream temper;
				temper << "192.168.50." << i;
				//	outgoing data is btagloc
				wlan1socket.async_send_to(
				    boost::asio::buffer( recvbuf_wlan0, bytez ),
				    udp::endpoint( boost::asio::ip::address_v4::from_string(
				                       temper.str() ), 7010 ),
				    boost::bind( &udp_server::sent_wlan1, this, boost::asio::placeholders::error, 	boost::asio::placeholders::bytes_transferred )
				);
			}

			recv_wlan0();
		}

	}

	void
	recvd_on_wlan1( const boost::system::error_code& error, std::size_t bytez )
	{
		DN_DEBUG_MACRO << "recvd " << bytez << " on wlan1" << endl;
		dn_utils::print_raw_bytes( recvbuf_wlan1, bytez );


		if ( !error || error == boost::asio::error::message_size )
		{
			//	incoming data is btagloc
			//	this is the fucking data from motes

			btagloc_t btagl;
			memcpy( &btagl, &recvbuf_wlan1, bytez );

			DN_DEBUG_MACRO << "btagloc is ";
			dn_utils::print_btagloc( btagl );
			printf( "\r\n" );


			uint16_t temperid = ntohs( btagl.the_btag.mote_id );
			DN_DEBUG_MACRO << "temperid is " << temperid << endl;


			//TODO: if the received btag data is the same as cached, don't send through DTN
			if (!dn_utils::equals_btag(allbtags[temperid].the_btag, btagl.the_btag)){

			memcpy( &allbtags[temperid], &btagl, sizeof ( btagloc_t ) );

			unsigned int lifetime = 3600;
			int priority = 1;
			ibrcommon::BLOB::Reference ref = ibrcommon::BLOB::create();
			( *ref.iostream() ).write( ( char* ) &btagl, sizeof( btagloc_t ) );
			( *ref.iostream() ).flush();

			string file_destination = "dtn://router";
			file_destination = btag_group_name;
			
			dtn::api::BLOBBundle b( file_destination, ref );
			b.setPriority( dtn::api::Bundle::BUNDLE_PRIORITY( priority ) );
			b.setLifetime( lifetime );

			//for ( int i = 1; i <= 10; i++ )
			//{
			//	if ( i == dn_utils::gethostnumber() )
			//		continue;

				//	also send via dtn
				stringstream temper1;
			//	temper1 << file_destination << i << ".dtn/btagsrecv";
				temper1 << file_destination;
			//	b.setDestination( temper1.str() );

				b.setDestination( file_destination );
				b.setSingleton(false);
				
				// send the bundle
				*dtnclient_ << b;
				dtnclient_->flush();
				DN_DEBUG_MACRO << "sent over dtn to " << temper1.str() << std::endl;

			//}

			} else {
				DN_DEBUG_MACRO << "received the same btag data, don't send over DTN" <<std::endl;
			}

			recv_wlan1();

		}

	}

	udp::endpoint remote_wlan0, remote_wlan1;
	boost::array<unsigned char, 1024> recvbuf_wlan0, recvbuf_wlan1;

	//	multicast listener socket
	udp::socket wlan0socket, wlan1socket;
	boost::asio::deadline_timer t;
	dtn::api::Client* dtnclient_;
	ibrcommon::tcpclient dtnapiconn_;

	dtn::api::Client* recv_dtnclient_;
	ibrcommon::tcpclient recv_dtnapiconn_;
};

void term( int signal )
{
	DN_DEBUG_MACRO << "caught signal, will stfu now" << endl;

	if ( signal >= 1 )
	{
		if ( _client != NULL )
		{
			_client->close();
			_conn->close();
		}
	}
}



int main()
{
	DN_DEBUG_MACRO << "starting server" << std::endl;
	system( "route add -net 225.0.0.0 netmask 255.0.0.0 dev br-lan" );
	DN_DEBUG_MACRO << "added route..." << std::endl;

	DN_DEBUG_MACRO << "my host number is " << dn_utils::gethostnumber() << std::endl;
	DN_DEBUG_MACRO << "will bind to "<< dn_utils::getwlan1ip().c_str() << std::endl;

	// catch process signals
	signal( SIGINT, term );
	signal( SIGTERM, term );


	boost::asio::io_service io_service;

	udp_server myserver( io_service );
	io_service.run();


	return 0;
}
