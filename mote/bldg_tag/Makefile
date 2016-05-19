COMPONENT=BuildingTagAppC

##### include file that has radio channel/power opts
include ../../channel_include

# enable RPL
#CFLAGS+=-DRPL_ROUTING -DRPL_STORING_MODE -I./rpl
CFLAGS+=-DRPL_ROUTING -DRPL_STORING_MODE -I$(LOWPAN_ROOT)/tos/lib/net/rpl
# CFLAGS+=-DRPL_ROOT_ADDR=0
PFLAGS+=-DIN6_PREFIX=\"fec0::\"

# but not MRHOF
# CFLAGS+=-DRPL_OF_MRHOF

# the sleep interval needs to be set the same for all participating devices
CFLAGS += -DLOW_POWER_LISTENING -DLPL_SLEEP_INTERVAL=200

# use short addresses so it's easier to debug
CFLAGS+=-DBLIP_DERIVE_SHORTADDRS

# also modifiy blip's L2 parameters to reduce media overload
CFLAGS+=-DBLIP_L2_RETRIES=3 -DBLIP_L2_DELAY=103

# enable printf
CFLAGS += -I$(TOSDIR)/lib/printf
#CFLAGS += -DNEW_PRINTF_SEMANTICS -DPRINTFUART_ENABLED -DPRINTF_BUFFER_SIZE=1024

# blip is too fat, so optimize for size
OPTFLAGS = -Os

include $(MAKERULES)
