#!/bin/sh
#
# convert uci configuration into daemon specific format
#

UCI=/sbin/uci

create_file() {
	echo "# -- DO NOT EDIT THIS FILE --" > $1
	echo "# automatic generated configuration file for IBR-DTN daemon" >> $1
	echo "#" >> $1
}

add_param() {
	VALUE=`$UCI -q get $2`
	
	if [ $? == 0 ]; then
		echo "$3 = $VALUE" >> $1
	fi
}

getconfig() {
	$UCI -q get ibrdtn.$1
	return $?
}

if [ "$1" == "--safe-mode" ]; then
	SAFEMODE=yes
	CONFFILE=$2
else
	SAFEMODE=no
	CONFFILE=$1
fi

# create the file and write some header info
create_file $CONFFILE

add_param $CONFFILE "ibrdtn.main.uri" "local_uri"
add_param $CONFFILE "ibrdtn.main.timezone" "timezone"
add_param $CONFFILE "ibrdtn.main.routing" "routing"

if [ "$SAFEMODE" == "yes" ]; then
	if [ -n "`getconfig safemode.forwarding`" ]; then
		add_param $CONFFILE "ibrdtn.safemode.forwarding" "routing_forwarding"
	else
		add_param $CONFFILE "ibrdtn.main.forwarding" "routing_forwarding"
	fi

	if [ -n "`getconfig safemode.maxblock`" ]; then
		add_param $CONFFILE "ibrdtn.safemode.maxblock" "limit_blocksize"
	else
		add_param $CONFFILE "ibrdtn.main.blocksize" "limit_blocksize"
	fi

	if [ -n "`getconfig safemode.storage`" ]; then
		add_param $CONFFILE "ibrdtn.safemode.storage" "limit_storage"
	else
		add_param $CONFFILE "ibrdtn.storage.limit" "limit_storage"
	fi
else
	add_param $CONFFILE "ibrdtn.main.forwarding" "routing_forwarding"
	add_param $CONFFILE "ibrdtn.main.blocksize" "limit_blocksize"
	add_param $CONFFILE "ibrdtn.storage.limit" "limit_storage"
	add_param $CONFFILE "ibrdtn.storage.blobs" "blob_path"
	add_param $CONFFILE "ibrdtn.storage.bundles" "storage_path"
	add_param $CONFFILE "ibrdtn.storage.engine" "storage"
fi

add_param $CONFFILE "ibrdtn.statistic.type" "statistic_type"
add_param $CONFFILE "ibrdtn.statistic.interval" "statistic_interval"
add_param $CONFFILE "ibrdtn.statistic.file" "statistic_file"
add_param $CONFFILE "ibrdtn.statistic.address" "statistic_address"
add_param $CONFFILE "ibrdtn.statistic.port" "statistic_port"

add_param $CONFFILE "ibrdtn.discovery.address" "discovery_address"
add_param $CONFFILE "ibrdtn.discovery.timeout" "discovery_timeout"

add_param $CONFFILE "ibrdtn.security.level" "security_level"
add_param $CONFFILE "ibrdtn.security.bab_key" "security_bab_default_key"
add_param $CONFFILE "ibrdtn.security.key_path" "security_path"

add_param $CONFFILE "ibrdtn.tls.ca" "security_ca"
add_param $CONFFILE "ibrdtn.tls.key" "security_key"
add_param $CONFFILE "ibrdtn.tls.trustedpath" "security_trusted_ca_path"
add_param $CONFFILE "ibrdtn.tls.required" "security_tls_required"
add_param $CONFFILE "ibrdtn.tls.noencryption" "security_tls_disable_encryption"


# iterate through all network interfaces
iter=0
netinterfaces=
while [ 1 == 1 ]; do
	$UCI -q get "ibrdtn.@network[$iter]" > /dev/null
	if [ $? == 0 ]; then
		netinterfaces="${netinterfaces} lan${iter}"
		add_param $CONFFILE "ibrdtn.@network[$iter].type" "net_lan${iter}_type"
		add_param $CONFFILE "ibrdtn.@network[$iter].interface" "net_lan${iter}_interface"
		add_param $CONFFILE "ibrdtn.@network[$iter].port" "net_lan${iter}_port"
		add_param $CONFFILE "ibrdtn.@network[$iter].discovery" "net_lan${iter}_discovery"
	else
		break
	fi
	
	let iter=iter+1
done

# write list of network interfaces
echo "net_interfaces =$netinterfaces" >> $CONFFILE

# iterate through all static routes
iter=0
while [ 1 == 1 ]; do
	$UCI -q get "ibrdtn.@static-route[$iter]" > /dev/null
	if [ $? == 0 ]; then
		PATTERN=`$UCI -q get "ibrdtn.@static-route[$iter].pattern"`
		DESTINATION=`$UCI -q get "ibrdtn.@static-route[$iter].destination"`
		let NUMBER=iter+1
		echo "route$NUMBER = $PATTERN $DESTINATION" >> $CONFFILE
	else
		break
	fi
	
	let iter=iter+1
done

#iterate through all static connections
iter=0
while [ 1 == 1 ]; do
	$UCI -q get "ibrdtn.@static-connection[$iter]" > /dev/null
	if [ $? == 0 ]; then
		let NUMBER=iter+1
		add_param $CONFFILE "ibrdtn.@static-connection[$iter].uri" "static${NUMBER}_uri"
		add_param $CONFFILE "ibrdtn.@static-connection[$iter].address" "static${NUMBER}_address"
		add_param $CONFFILE "ibrdtn.@static-connection[$iter].port" "static${NUMBER}_port"
		add_param $CONFFILE "ibrdtn.@static-connection[$iter].protocol" "static${NUMBER}_proto"
		add_param $CONFFILE "ibrdtn.@static-connection[$iter].immediately" "static${NUMBER}_immediately"
	else
		break
	fi
	
	let iter=iter+1
done