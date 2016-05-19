#include <jni.h>
#include "NativeLib.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/select.h>
#include <sys/time.h>
#include <time.h>
#include "zip.h"
#include "zipint.h"
#include <android/log.h>
//#include <android/asset_manager.h>
#include <sys/param.h>
//#include <sys/kernel.h>
//#include <sys/module.h>
//#include <rc4.h>


#define BUFFERSIZE 512
char buffer[BUFFERSIZE+4];
int MAX_SERVER=1;
int global_time;

//struct zip* pkg_zip;
//struct zip_file *zfile;

struct rc4_state {
         u_char  perm[256];
         u_char  index1;
        u_char  index2;
}rc4state;

void rc4_state_clean(struct rc4_state* p){
    p->index1='\0';
    p->index2='\0';
   memset(p->perm,0,256);
   return;
}
struct server {//data stucture for server
	int fd;//-1 non-exist
	//char username[MAX_NAME];
	char buffer[BUFFERSIZE+4];
	//char encryptedbuffer[BUFFERSIZE+4];
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
	char filepath[256];
	char packageName[128];
};
struct server serverdata;
fd_set  rset, allset;//fd set

JNIEnv *jenv;
jobject jobj;

const char* rc4key= "lensslenss";
void server_clean(struct server p){//clean up function for client

	if(p.f!=NULL) fclose(p.f);
	//bzero(p->username,MAX_NAME);
	memset(p.buffer,0,BUFFERSIZE+4);
	//memset(p.encryptedbuffer,0,BUFFERSIZE+4);
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
	//if(zfile != NULL)
	//zip_fclose(zfile);
	//zfile = NULL;
	return;
}

JNIEXPORT jint JNICALL JNI_OnLoad( JavaVM *vm, void *pvt )
	{
	fprintf( stdout, "* JNI_OnLoad called\n" );
	return JNI_VERSION_1_6;
	}
	



/*JNIEXPORT void JNICALL Java_com_android_fogbox_NativeLib_setAppName
  (JNIEnv * env, jobject object, jstring pkgname){
	const char *buffer = (*env)->GetStringUTFChars( env, pkgname,0);
   int error;    
   pkg_zip = zip_open( buffer, 0, &error );
   strcpy( serverdata.packageName, buffer );
    __android_log_write(ANDROID_LOG_INFO, "tftp-client",serverdata.packageName);
    __android_log_write(ANDROID_LOG_INFO, "tftp-client", "setAppName entered");
   if( pkg_zip == NULL ){
    __android_log_write(ANDROID_LOG_INFO, "tftp-client", "Failed to open apk file");
   }else
   __android_log_write(ANDROID_LOG_INFO, "tftp-client", "opened apk file");
   
   (*env)->ReleaseStringUTFChars(env,pkgname, buffer );
}*/

JNIEXPORT void JNICALL Java_com_android_fogbox_NativeLib_sendFile
  (JNIEnv * env, jobject object,jstring string1, jstring string2, jstring string3)
{
	jenv = env;
	jobj = object;
	//mgr =assetmanager;
	/*if(NULL == mgr) 
	{
		__android_log_write(ANDROID_LOG_INFO, "tftp-client", "asset manager is NULL");
		exit(1);
	}*/
	
	const char *str1 = (*env)->GetStringUTFChars(env, string1, 0);
	const char *str2 = (*env)->GetStringUTFChars(env, string2, 0);
	const char *str3 = (*env)->GetStringUTFChars(env, string3, 0);
	
	__android_log_write(ANDROID_LOG_INFO, "tftp-client", "sendfile entered");
   sendRequestedFile(str1,str2,str3);

   (*env)->ReleaseStringUTFChars(env, string1, str1);
   (*env)->ReleaseStringUTFChars(env, string2, str2);
   (*env)->ReleaseStringUTFChars(env, string3, str3);
	
}
/*JNIEXPORT void JNICALL Java_com_android_fogbox_NativeLib_closezip
  (JNIEnv * env, jobject object)
  {
  	if(pkg_zip != NULL)
  		zip_close(pkg_zip);
  }*/
JNIEXPORT void JNICALL Java_Callbacks_nativeappupdate
  (JNIEnv * env, jobject object, jint count)
{
	jclass cls = (*env)->GetObjectClass(env,object);
	jmethodID mid = (*env)->GetMethodID(env,cls,"appupdate","(I)V");
	if(mid == 0)
	return;
	(*env)->CallVoidMethod(env,object,mid,count);
}
void error(const char *msg)
{
	perror(msg);
	exit(-1);
}

void swap_bytes(u_char *a, u_char *b)
{
	u_char temp;

	temp = *a;
	*a = *b;
	*b = temp;
}
/*
 * Initialize an RC4 state buffer using the supplied key,
 * which can have arbitrary length.
 */
void rc4_init(struct rc4_state* rc4state, const u_char *key, int keylen)
{
	u_char j;
	int i;

	/* Initialize state with identity permutation */
	for (i = 0; i < 256; i++)
	rc4state->perm[i] = (u_char)i; 
	rc4state->index1 = 0;
	rc4state->index2 = 0;
  
	/* Randomize the permutation using key data */
	for (j = i = 0; i < 256; i++) {
		j += rc4state->perm[i] + key[i % keylen]; 
		swap_bytes(&rc4state->perm[i], &rc4state->perm[j]);
	}
}

/*
 * Encrypt some data using the supplied RC4 state buffer.
 * The input and output buffers may be the same buffer.
 * Since RC4 is a stream cypher, this function is used
 * for both encryption and decryption.
 */
void
rc4_crypt(struct rc4_state * rc4state,
	 u_char *inbuf, u_char *outbuf, int buflen)
{
	int i;
	u_char j;

	for (i = 0; i < buflen; i++) {

		/* Update modification indicies */
		rc4state->index1++;
		rc4state->index2 += rc4state->perm[rc4state->index1];

		/* Modify permutation */
		swap_bytes(&rc4state->perm[rc4state->index1],
		    &rc4state->perm[rc4state->index2]);

		/* Encrypt/decrypt next byte */
		j = rc4state->perm[rc4state->index1] + rc4state->perm[rc4state->index2];
		outbuf[i] = inbuf[i] ^ rc4state->perm[j];
	}
}



void send_wrq(){
	//struct rc4_state rc4state;
	char bytessent[128];
	const char* netascii = "netascii";
	uint16_t op=2;
	char *buf=serverdata.buffer;
	//char *enbuf=serverdata.encryptedbuffer;
   
    int bytes_sent;
	memset(buf,0,BUFFERSIZE+4);
	//memset(enbuf,0,BUFFERSIZE+4);
	
	*(uint16_t *)buf=htons(op);

	int filenamelen = strlen(serverdata.filename);
	int netasciilength = strlen(netascii);
	
	sprintf(bytessent,"Netascii length is %d",netasciilength);
     __android_log_write(ANDROID_LOG_INFO, "tftp-client",bytessent);
     
	memcpy(buf+2,serverdata.filename,filenamelen+1);
	*(uint16_t *)(buf+filenamelen+3) = htons(0);
	memcpy(buf+4+filenamelen,netascii,netasciilength+1);
	serverdata.buffer[4+filenamelen+netasciilength]='\0';
	
	sprintf(bytessent,"Bytes originally is %d",sizeof(serverdata.buffer));
     __android_log_write(ANDROID_LOG_INFO, "tftp-client",bytessent);
     
	//rc4_init(&rc4state,rc4key,strlen(rc4key));
	//rc4_crypt(&rc4state,serverdata.buffer,serverdata.encryptedbuffer,sizeof(serverdata.buffer));
	
	//sprintf(bytessent,"Bytes original is %d",sizeof(serverdata.buffer));
     //__android_log_write(ANDROID_LOG_INFO, "tftp-client",bytessent);
     
	//sprintf(bytessent,"Bytes to be sent is %d",sizeof(serverdata.encryptedbuffer));
     //__android_log_write(ANDROID_LOG_INFO, "tftp-client",bytessent);
	bytes_sent = sendto(serverdata.fd,serverdata.buffer,5+filenamelen+netasciilength,0,(struct sockaddr *)&serverdata.addr,sizeof(serverdata.addr));
 	//bytes_sent = sendto(serverdata.fd,serverdata.encryptedbuffer,(5+filenamelen+netasciilength),0,(struct sockaddr *)&serverdata.addr,sizeof(serverdata.addr));
 	//bytes_sent = sendto(serverdata.fd,serverdata.encryptedbuffer,sizeof(serverdata.encryptedbuffer),0,(struct sockaddr *)&serverdata.addr,sizeof(serverdata.addr));
 	 sprintf(bytessent,"Bytes sent is %d",bytes_sent);
     __android_log_write(ANDROID_LOG_INFO, "tftp-client",bytessent);
	
}


void send_data(){
	uint16_t op =0;
	char bytessent[128];
	//struct rc4_state rc4state;
	//rc4_state_clean(&rc4state);
    if(serverdata.filesize>=BUFFERSIZE)
	 op=3;
	else
		op=6;

	char *buf=serverdata.buffer;
	//char *enbuf=serverdata.encryptedbuffer;

    int bytes_sent,n;
	memset(buf,0,BUFFERSIZE+4);
	//memset(enbuf,0,BUFFERSIZE+4);

	//rc4_init(&rc4state,rc4key,strlen(rc4key));

	*(uint16_t *)buf=htons(op);
	*(uint16_t *)(buf+2)=htons(serverdata.block++);
	if(serverdata.filesize>=BUFFERSIZE)
	{
		serverdata.filesize-=BUFFERSIZE;
		n=fread(buf+4,BUFFERSIZE,1,serverdata.f);
		printf("n============%d\n",n);
		//rc4_crypt(&rc4state,serverdata.buffer,serverdata.encryptedbuffer,sizeof(serverdata.buffer));
		bytes_sent = sendto(serverdata.fd,serverdata.buffer,(4+BUFFERSIZE),0,(struct sockaddr *)&serverdata.addr,sizeof(serverdata.addr));
		//bytes_sent = sendto(serverdata.fd,serverdata.encryptedbuffer,(4+BUFFERSIZE),0,(struct sockaddr *)&serverdata.addr,sizeof(serverdata.addr));
		 sprintf(bytessent,"Bytes sent is %d",bytes_sent);
    	__android_log_write(ANDROID_LOG_INFO, "tftp-client",bytessent);
		//printf("bytes sent is %d\n",bytes_sent);
	}
	else{
		*(uint32_t *)(buf+4)=htonl(serverdata.filesize);
		fread(buf+8,serverdata.filesize,1,serverdata.f);
		//rc4_crypt(&rc4state,serverdata.buffer,serverdata.encryptedbuffer,sizeof(serverdata.buffer));
                bytes_sent = sendto(serverdata.fd,serverdata.buffer,(8+serverdata.filesize),0,(struct sockaddr *)&serverdata.addr,serverdata.addr_len);
                //bytes_sent = sendto(serverdata.fd,serverdata.encryptedbuffer,(8+serverdata.filesize),0,(struct sockaddr *)&serverdata.addr,serverdata.addr_len);
		 sprintf(bytessent,"Bytes sent in last block is %d",bytes_sent);
    	__android_log_write(ANDROID_LOG_INFO, "tftp-client",bytessent);
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
	//int count = 1;
	printf("new msg: op==%d and blocknum is %d and serverdata.block is %d\n",op,blocknum,serverdata.block);
		if(op==4 && blocknum==(serverdata.block-1)){
			__android_log_write(ANDROID_LOG_INFO, "tftp-client","State machine entered");
			if(serverdata.last_block == 1){
			__android_log_write(ANDROID_LOG_INFO, "tftp-client","Last block already sent");
				server_clean(serverdata);
				serverdata.last_block = 2;
				return;
			}
			printf("state 1\n");

			send_data();
			/*jclass cls = (*jenv)->GetObjectClass(jenv,jobj);
			jmethodID mid = (*jenv)->GetMethodID(jenv,cls,"appupdate","(I)V");
			(*jenv)->CallVoidMethod(jenv,jobj,mid,count);
			count++;*/
		}
	else {
				__android_log_write(ANDROID_LOG_INFO, "tftp-client","State machine not entered");
                printf("Undecided\n");

	}
}
void retransmit_data(){
	char *buf=serverdata.buffer;


	int n;
	if(serverdata.filesize>=BUFFERSIZE){
	sendto(serverdata.fd,serverdata.buffer,4+BUFFERSIZE,0,(struct sockaddr *)&serverdata.addr,serverdata.addr_len);
	//sendto(serverdata.fd,serverdata.encryptedbuffer,4+BUFFERSIZE,0,(struct sockaddr *)&serverdata.addr,serverdata.addr_len);
	}
	else{
		sendto(serverdata.fd,serverdata.buffer,4+serverdata.filesize,0,(struct sockaddr *)&serverdata.addr,serverdata.addr_len);
		//sendto(serverdata.fd,serverdata.encryptedbuffer,4+serverdata.filesize,0,(struct sockaddr *)&serverdata.addr,serverdata.addr_len);
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

FILE *FileOpen( const char* fname )
{
	uint32_t offset = 0;
   	uint32_t length = 0;
	char tmppath[128];
	//char* assetspath = "/mnt/sdcard/";
	char* assetspath ="/mnt/sdcard/DCIM/Camera/";
	strcpy(serverdata.filepath,assetspath);
   
 //  if (FileExists(fname) != -1)
   strcat(serverdata.filepath,serverdata.filename);
    sprintf(tmppath,"filepath is now %s",serverdata.filepath);
    __android_log_write(ANDROID_LOG_INFO, "tftp-client",tmppath);
   		//zfile = zip_fopen(pkg_zip,serverdata.filepath, 0 );
   		
   //	else
   	//	exit(1);
   		


   /*if( zfile != NULL )
   {
      offset = zfile->fpos;
      serverdata.filesize = zfile->bytes_left;
      zip_fclose( zfile );
      zfile = NULL;
      __android_log_write(ANDROID_LOG_INFO, "tftp-client", "File found");
   } else
   {
   	  __android_log_write(ANDROID_LOG_INFO, "tftp-client", "File NOT found");
      return NULL;
   }

   FILE *fp = NULL;
   fp = fopen( serverdata.packageName, "r" );
   fseek( fp, offset, SEEK_SET );*/
   FILE *fp = NULL;
   fp = fopen( serverdata.filepath, "r" );
   return fp;
}

 sendRequestedFile(char* serverIP,char* portNo, char* fName){
	int sockfd, newsockfd, portno,iofd;
	int maxfd,connfd,maxi=-1;
	int i,nready;
	struct sockaddr_in serv_addr,server_addr;
	int serv_len=sizeof(serv_addr);
	socklen_t server_len =sizeof(server_addr);
	int n;

	char filename[128];

	sockfd = socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP);

	__android_log_write(ANDROID_LOG_INFO, "tftp-client", "sendRequestedFile entered");
	if (sockfd < 0)
	{
		__android_log_write(ANDROID_LOG_INFO, "tftp-client", "error opening socket");
     //   server_clean(serverdata);
    }
	server_clean(serverdata);

    strcpy(serverdata.filename,fName);
    sprintf(filename,"filename is %s",serverdata.filename);
    __android_log_write(ANDROID_LOG_INFO, "tftp-client",filename);
    
	memset((char *) &serv_addr,0, sizeof(serv_addr));
	memset((char *) &server_addr,0, sizeof(server_addr));
	portno = atoi(portNo);
	serv_addr.sin_family = AF_INET;
    inet_pton(AF_INET,serverIP,&serv_addr.sin_addr.s_addr);
    serv_addr.sin_port = htons(portno);
    maxfd=sockfd;
    FD_ZERO(&allset);
    FD_SET(sockfd, &allset);

	printf("++++++++++++++++++++++++++Client starts+++++++++++++++++++++++++++\n");

    serverdata.f=FileOpen(serverdata.filename);

    if(serverdata.f==NULL)
    {
        __android_log_write(ANDROID_LOG_INFO, "tftp-client", "File does not exist");
        //send_error(k);
        //clients[k].state=2;//state change to 2
        server_clean(serverdata);
        exit(1);
    }
    else
    {
    	char filesize[128];
		__android_log_write(ANDROID_LOG_INFO, "tftp-client", "File found");
        fseek (serverdata.f , 0 , SEEK_END);
        serverdata.filesize = ftell (serverdata.f);
        rewind (serverdata.f);
        
         sprintf(filesize,"filesize is %d",serverdata.filesize);
    	__android_log_write(ANDROID_LOG_INFO, "tftp-client",filesize);
        //printf("filesize=%d\n",serverdata.filesize);
        //clients[k].state=1;//state change to 1
    }
//   	if (connect(sockfd,(struct sockaddr *) &serv_addr,sizeof(serv_addr)) < 0)
//    {
//	      __android_log_write(ANDROID_LOG_INFO, "tftp-client", "Error connecting");
//	      exit(1);
//	}

	struct timeval select_timeout;
	select_timeout.tv_sec=16;
	select_timeout.tv_usec=0;
	serverdata.fd=sockfd;
	serverdata.addr = serv_addr;
	serverdata.block = 1;
	send_wrq();
	
	//while(1){
	  while(serverdata.last_block!=2){
		nready=select(maxfd+1,&allset,NULL,NULL,&select_timeout);
//		nready=select(maxfd+1,&allset,NULL,NULL,NULL);//select return 0 if timeout ,otherwise return # of ready fd

		if(nready==0){//timeout
		char blocknum[128];
        __android_log_write(ANDROID_LOG_INFO, "tftp-client", "Timeout happened");
		sprintf(blocknum,"Block num last sent is %d",serverdata.block);
    	__android_log_write(ANDROID_LOG_INFO, "tftp-client",blocknum);
		retransmit();

			select_timeout.tv_sec=16;
			select_timeout.tv_usec=0;
			continue;
		}
		//if(FD_ISSET(sockfd,&allset)){
			//new connection

				if(n=recvfrom(sockfd, buffer, BUFFERSIZE+4, 0,(struct sockaddr *)&server_addr,(socklen_t *)&server_len)<0)
				   __android_log_write(ANDROID_LOG_INFO, "tftp-client","receive error");
				else
				{
					//rc4_init(&rc4state,rc4key,strlen(rc4key));
				   __android_log_write(ANDROID_LOG_INFO, "tftp-client","received some data");
				   serverdata.fd=sockfd;
                   serverdata.size=0;
                   serverdata.addr=server_addr;
                   serverdata.addr_len=server_len;
				  

				   memset(serverdata.buffer,0,BUFFERSIZE+4);
				   //memset(serverdata.encryptedbuffer,0,BUFFERSIZE+4);
				   memcpy(serverdata.buffer,buffer,BUFFERSIZE+4);
				 // memcpy(serverdata.encryptedbuffer,buffer,sizeof(buffer));
				  //rc4_crypt(&rc4state,serverdata.encryptedbuffer,serverdata.buffer,sizeof(serverdata.encryptedbuffer));
				  //memcpy(serverdata.buffer,buffer,BUFFERSIZE+4);
				  //rc4_crypt(serverdata.rc4state,serverdata.encryptedbuffer,serverdata.buffer,strlen(serverdata.encryptedbuffer));
		           state_machine();
				}
//			if(serverdata.last_block == 1)
//				break;
			}
//			serverdata.last_block =0;
			printf("last block sent\n");
			close (sockfd);			/* close the socket */
		
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




























