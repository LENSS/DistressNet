for i in $*
do
	echo "iptables -A INPUT -s 192.168.50.$i -j DROP"
	iptables -A INPUT -s 192.168.50.$i -j DROP
done

