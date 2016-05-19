tftp_client

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/select.h>
#include <sys/time.h>
#include<time.h>
#define BUFFERSIZE 512
char buffer[BUFFERSIZE+4];
int MAX_SERVER=1;
int global_time;
struct server {//data stucture for server
	int fd;//-1 non-exist
	//char username[MAX_NAME];
	char buffer[BUFFERSIZE+4];
	int size;
	int limit;		
	struct sockaddr_in addr;
	int addr_len;
	int state;//0 1 2
	FILE *f;
	uint16_t block;//block number
	unsigned int filesize;
	int time;//last sending time
	int retry;//this is the nth retry ie  first retry, second retry, third retry..
	int retry_time;//how many seconds should we wait  ie  1,2,4,8
	int last_block;//1 if last block, otherwise 0
	char filename[128];
};
struct server serverdata;
fd_set  rset, allset;//fd set
void server_clean(struct server p){//clean up function for client

	if(p.f!=NULL) fclose(p.f);
	//bzero(p->username,MAX_NAME);
	memset(p.buffer,0,BUFFERSIZE+4);
	FD_CLR(p.fd,&allset);
	if(p.fd!=-1)close(p.fd);
	p.fd=-1;
	p.size=0;
	p.limit=4;	
	p.state=0;
	p.block=1;
	p.filesize=0;
	p.time=0;
	p.retry=0;
	p.retry_time=0;
	p.last_block=0;
	return;
}


void error(const char *msg)
{
	perror(msg);
	exit(-1);
}
void send_wrq(){
        
	uint16_t op=2;
	char *buf=serverdata.buffer;
        int bytes_sent;
        printf("send_wrq entered\n");
	memset(buf,0,BUFFERSIZE+4);
	*(uint16_t *)buf=htons(op);
	
	int filenamelen = strlen(serverdata.filename);
	int netasciilength = strlen("netascii");
	memcpy(buf+2,serverdata.filename,filenamelen+1);	
	*(uint16_t *)(buf+filenamelen+3) = htons(0);
	memcpy(buf+4+filenamelen,"netascii",netasciilength+1);
	bytes_sent = sendto(serverdata.fd,serverdata.buffer,5+filenamelen+netasciilength,0,(struct sockaddr *)&serverdata.addr,sizeof(serverdata.addr));
	printf("bytes sent is %d\n",bytes_sent);
/*	if(bytes_sent >0)
	        printf("No error\n");
        else
	        printf("no bytes transferred\n");*/

}


void send_data(){
	uint16_t op =0;
        if(serverdata.filesize>=BUFFERSIZE)
		 op=3;
	else
		op=6;
		
	char *buf=serverdata.buffer;
        int bytes_sent,n;
        printf("send_Data entered\n");
	memset(buf,0,BUFFERSIZE+4);
	*(uint16_t *)buf=htons(op);
	
	*(uint16_t *)(buf+2)=htons(serverdata.block++);
	if(serverdata.filesize>=BUFFERSIZE)
	{
		serverdata.filesize-=BUFFERSIZE;
		n=fread(buf+4,BUFFERSIZE,1,serverdata.f);
		printf("n============%d\n",n);	
		bytes_sent = sendto(serverdata.fd,serverdata.buffer,4+BUFFERSIZE,0,(struct sockaddr *)&serverdata.addr,sizeof(serverdata.addr));
		printf("bytes sent is %d\n",bytes_sent);
	}
	else{
		*(uint32_t *)(buf+4)=htonl(serverdata.filesize);		
		fread(buf+8,serverdata.filesize,1,serverdata.f);
                bytes_sent = sendto(serverdata.fd,serverdata.buffer,8+serverdata.filesize,0,(struct sockaddr *)&serverdata.addr,serverdata.addr_len);
		printf("bytes sent in last block is %d\n",bytes_sent);
		serverdata.last_block=1;
		if(feof(serverdata.f))
			printf("EOF reached\n");
		return;
	}	
	
}
void state_machine(){//the state machine 
	uint16_t op=ntohs(*(uint16_t *)serverdata.buffer);
	uint16_t blocknum=ntohs(*(uint16_t *)(serverdata.buffer+2));
	char *buf=serverdata.buffer;
	printf("new msg: op==%d and blocknum is %d and serverdata.block is %d\n",op,blocknum,serverdata.block);
		if(op==4 && blocknum==(serverdata.block-1)){
			
			if(serverdata.last_block == 1){	
				server_clean(serverdata);
				serverdata.last_block = 2;
				return;
			}
			printf("state 1\n");		
			send_data();
		}
	else {
                printf("Undecided\n");

	}
}
void retransmit_data(){
	char *buf=serverdata.buffer;
	int n;
	if(serverdata.filesize>=BUFFERSIZE){
	sendto(serverdata.fd,serverdata.buffer,4+BUFFERSIZE,0,(struct sockaddr *)&serverdata.addr,serverdata.addr_len);
	}
	else{		
		sendto(serverdata.fd,serverdata.buffer,4+serverdata.filesize,0,(struct sockaddr *)&serverdata.addr,serverdata.addr_len);
		return;
	}	
}


void retransmit(){
	global_time=(int)time(NULL);
	int diff=global_time-serverdata.time;	
	if(diff>=serverdata.retry_time){//change retry times and retry wait time
		serverdata.retry++;
		if(serverdata.retry==1){
			serverdata.retry_time=1;
		}
		else if (serverdata.retry==2){
			serverdata.retry_time=2;
		}
		else if (serverdata.retry==3){
			serverdata.retry_time=4;
		}
		else if (serverdata.retry==4){
			serverdata.retry_time=8;
		}
		else{
			server_clean(serverdata);
			printf("timeout and disconnect\n");
			return;
		}
	}
	else{
		return;
	}
	//retransmit
	retransmit_data();
	serverdata.time=(int)time(NULL);
}
int main(int argc,char *argv[]){	

	int sockfd, newsockfd, portno,iofd;
	int maxfd,connfd,maxi=-1;
	int i,nready;
	struct sockaddr_in serv_addr,server_addr;
	int serv_len=sizeof(serv_addr);
	socklen_t server_len =sizeof(server_addr);
	int n;
       
       
	if (argc < 4) {
		fprintf(stderr,"ERROR, <local ip> <port> <FIlename>.\n");
		exit(1);
	}
	sockfd = socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP);
	if (sockfd < 0) 
		error("ERROR opening socket");
        server_clean(serverdata);

        strcpy(serverdata.filename,argv[3]);
     
	memset((char *) &serv_addr,0, sizeof(serv_addr));
	memset((char *) &server_addr,0, sizeof(server_addr));
	portno = atoi(argv[2]);
	serv_addr.sin_family = AF_INET;
        inet_pton(AF_INET,argv[1],&serv_addr.sin_addr.s_addr);
        serv_addr.sin_port = htons(portno);
        maxfd=sockfd;
        FD_ZERO(&allset);
        FD_SET(sockfd, &allset);
	
	printf("++++++++++++++++++++++++++Client starts+++++++++++++++++++++++++++\n");
        
        serverdata.f=fopen(serverdata.filename,"r");
                        if(serverdata.f==NULL){
                                //file does not exit
                                printf("file does not exist\n");
                                //send_error(k);
                                //clients[k].state=2;//state change to 2  
                                server_clean(serverdata);
                                exit(1);
                        }
                        else{
                                fseek (serverdata.f , 0 , SEEK_END);
                                serverdata.filesize = ftell (serverdata.f);
                                rewind (serverdata.f);
                                printf("filesize=%d\n",serverdata.filesize);
                                //clients[k].state=1;//state change to 1  
                            
                        }
   
	struct timeval select_timeout;
	select_timeout.tv_sec=8;
	select_timeout.tv_usec=0;
        serverdata.fd=sockfd;
        serverdata.addr = serv_addr;
	serverdata.block = 1;
	send_wrq();
	while(serverdata.last_block!=2){
		//rset=allset;

		nready=select(maxfd+1,&allset,NULL,NULL,&select_timeout);//select return 0 if timeout ,otherwise return # of ready fd
		if(nready==0){//timeout
                        printf("timeout happened");
			//for(i=0;i<=maxi;++i){
				//if((iofd=clients[i].fd)<0) continue;
				retransmit();
			
		//	printf("one second passed\n");
			select_timeout.tv_sec=8;
			select_timeout.tv_usec=0;
			continue;
		}
		//if(FD_ISSET(sockfd,&allset)){
			//new connection
			
				if(n=recvfrom(sockfd, buffer, BUFFERSIZE+4, 0,(struct sockaddr *)&server_addr,(socklen_t *)&server_len)<0) 
				   error("receive error");
				else
				{
				   printf("\n\n\n~~~~~~~~~~~~~~~~~~~~~~~~~Receivedata~~~~~~~~~~~~~~~~~~~~~~~\n");
				   serverdata.fd=sockfd;
                                   serverdata.size=0;
                                   serverdata.addr=server_addr;
                                   serverdata.addr_len=server_len;

				   memset(serverdata.buffer,0,BUFFERSIZE+4);
				   memcpy(serverdata.buffer,buffer,BUFFERSIZE+4);
		                   state_machine();
				}
		            
			}
			printf("last block sent\n");
			/*for(i=0;i<MAX_CLIENT;++i){
				if(clients[i].fd<0){
					clients[i].fd=connfd;
					clients[i].size=0;
					clients[i].addr=cli_addr;
					clients[i].addr_len=cli_len;
					memcpy(clients[i].buffer,buffer,BUFFERSIZE);
					state_machine(i);
					clients[i].time=(int)time(NULL);
					break;
				}
			}
			if(i==MAX_CLIENT){
				printf("too many clients\n");
				continue;
			}
			FD_SET(connfd,&allset);
			if(connfd>maxfd){
				maxfd=connfd;
			}
			if(i>maxi) maxi=i;
			if(--nready<=0){
				continue;
			}*/	
		//}
		//old connection
	/*for(i=0;i<=maxi;++i){
			if((iofd=clients[i].fd)<0) continue;
			if(FD_ISSET(iofd,&rset)){		
				printf("\n\n\n~~~~~~~~~~~~~~~~~~~~~~~~~OLD CONNECTION %d~~~~~~~~~~~~~~~~~~~~~~~\n",i);
				if(n=recvfrom(iofd, buffer, BUFFERSIZE, 0,  (struct sockaddr *)&cli_addr, (socklen_t *)&cli_len)<0) error("receive error");
				memcpy(clients[i].buffer,buffer,BUFFERSIZE);
				state_machine(i);
//				client_read(i);
				if(--nready<=0) break;/
				break;
			}		
		}
			select_timeout.tv_sec=1;
			select_timeout.tv_usec=0;
		//otherwise, timeout*/

	//}
}


