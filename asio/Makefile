CXXFLAGS = -I./include/boost-1_38/ -I/usr/local/include/ibrdtn-0.6/ -I/usr/local/include/ibrcommon-0.6/ -g -shared -fPIC
#CXXFLAGS = -I./include/boost-1_38/ -I/usr/local/include/ibrdtn-0.6/ -I/usr/local/include/ibrcommon-0.6/ -g  
#LDFLAGS =  -L./lib -lboost_system-gcc46-mt -librcommon -lpthread 
LDFLAGS =  -L./lib -lboost_system-gcc46-mt -librcommon -lpthread 
#LDFLAGS =  -L./lib -lboost_system-gcc46-mt -lpthread -l ibrcommon
#LDFLAGS =  -L./lib -lpthread

T=router
ifeq ($(T),router)
	WRT_PATH = /home/chen/Documents/AcademicCVS/trunk/code/openwrt/backfire_10.03.1
	WRT_BUILD = $(WRT_PATH)/build_dir/target-mips_r2_uClibc-0.9.30.1
	WRT_STAGE = $(WRT_PATH)/staging_dir
	WRT_STAGE_TO = $(WRT_STAGE)/toolchain-mips_r2_gcc-4.3.3+cs_uClibc-0.9.30.1
	WRT_STAGE_TA = $(WRT_STAGE)/target-mips_r2_uClibc-0.9.30.1

	CXXFLAGS = -Os -pipe -mips32r2 -mtune=mips32r2 -funit-at-a-time -fhonour-copts -msoft-float -I$(WRT_STAGE_TA)/usr/include -I./include/boost-1_38/
	CXXFLAGS += -I$(WRT_STAGE_TA)/usr/include/ibrcommon-0.8 -I$(WRT_STAGE_TA)/usr/include/ibrdtn-0.8
	LDFLAGS = -Os -pipe -mips32r2 -mtune=mips32r2 -funit-at-a-time -fhonour-copts -msoft-float -L$(WRT_STAGE_TA)/root-ar71xx/usr/lib -lboost_system-mt -lboost_filesystem-mt
	LDFLAGS += -L$(WRT_STAGE_TA)/usr/lib -librdtn -librcommon -lnl -lssl -lcrypto -lz -lm
	
	CC = $(WRT_STAGE_TO)/usr/bin/mips-openwrt-linux-gcc
	CXX = $(WRT_STAGE_TO)/usr/bin/mips-openwrt-linux-g++
	MAGICSTUFF = 

endif

PROGS := btagfaker basesta genericlistener mobilebeaconer_btagcollector multicastforwarder fogbox fogboxrecv tftpd fogbox_send fogbox_recv 
OBJECTS = $(PROGS:=.o)


all:	$(PROGS)

clean:
	rm -rf *.o $(PROGS)

tftpd: tftpd.o
	$(CC) $(LDFLAGS) -o tftpd tftpd.o

gpsreader:	gpsreader.o
	$(CXX) $(LDFLAGS) -lgps -lgpsd -lusb-1.0 -o $@ $< 

gpspipe:	gpspipe.o
	$(CXX) $(LDFLAGS) -lgps -lgpsd -lusb-1.0 -o $@ $< 

twitterClient:	twitterClient.o twitcurl.o oauthlib.o urlencode.o base64.o SHA1.o HMAC_SHA1.o
	$(CXX) $(LDFLAGS) -lcurl -lz -o $@ $^ 

twitterproxy:	twitterproxy.o twitcurl.o oauthlib.o urlencode.o base64.o SHA1.o HMAC_SHA1.o
	$(CXX) $(LDFLAGS) -lcurl -lz -o $@ $^ 

%.o:	%.cpp
# 	$(CXX) $(CXXFLAGS) -c $< -o $@
