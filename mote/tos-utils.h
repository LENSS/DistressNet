uint16_t
getTOSNodeIDs(struct sockaddr_in6 *from)
{
	return ntohs(from->sin6_addr.s6_addr16[7]);
}

uint16_t
getTOSNodeID(struct in6_addr *from)
{
	return ntohs(from->s6_addr16[7]);
}