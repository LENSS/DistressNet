COMPONENT=PppRouterC
# PFLAGS += -DENABLE_SPI0_DMA
# PFLAGS += -DCC2420_DEF_CHANNEL=21
include ../../channel_include

# use rpl
# PFLAGS += -DRPL_ROUTING -DRPL_STORING_MODE -I$(LOWPAN_ROOT)/tos/lib/net/rpl
# PFLAGS += -DRPL_OF_MRHOF

# and ppp
PFLAGS += -I$(TOSDIR)/lib/ppp
PFLAGS += -I$(TOSDIR)/lib/fragpool

# this works around fragmentation in the RX buffer pool
PFLAGS += -DPPP_HDLC_RX_FRAME_LIMIT=1 -DPPP_HDLC_TX_FRAME_LIMIT=8

# if you set this, the stack won't use dhcp to assign addresses -- it
# will use this prefix combined with TOS_NODE_ID
PFLAGS += -DIN6_PREFIX=\"fec0::\"

# derive short address from the dhcp address assignment, if possible
PFLAGS += -DBLIP_DERIVE_SHORTADDRS

# CFLAGS += -DCC2420_NO_ADDRESS_RECOGNITION

# CFLAGS += -DNEW_PRINTF_SEMANTICS -DPRINTFUART_ENABLED -DPRINTF_BUFFER_SIZE=1024


include $(MAKERULES)
