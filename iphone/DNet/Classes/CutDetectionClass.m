//
//  DNetViewController.m
//  DNet
//
//  Created by Harsha on 2/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CutDetectionClass.h"
#import <CFNetwork/CFNetwork.h>
#import <CoreFoundation/CFByteOrder.h>


//#include <sys/socket.h>
//#include <netinet/in.h>
//#include <unistd.h>

#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]


@interface CutDetectionClass ()

@property (nonatomic, readwrite) BOOL	isStarted;
@property (nonatomic, readwrite) int	role;
@property (nonatomic, readwrite) float	state;
@property (nonatomic, readwrite) int	iteration;
@property (nonatomic, retain) NSString*	statesaver;
@property (nonatomic, retain)	 NSTimer*	timer;

@end

@implementation CutDetectionClass

#pragma mark * Core transfer code

@synthesize scrollview = _scrollview;
@synthesize startstopButton = _startstopButton;
@synthesize emailButton = _emailButton;
@synthesize isStarted;
@synthesize roleChooser = _roleChooser;
@synthesize role, state, iteration, timer, statesaver;
@synthesize currStateLabel = _currStateLabel;

- (void) appendTxt:(NSString *) string 
{
	self.scrollview.text = [NSString stringWithFormat:@"%@%@", self.scrollview.text, string];
}

- (void) appendSaver:(NSString *) string 
{
	self.statesaver = [NSString stringWithFormat:@"%@%@", self.statesaver, string];
}

- (void)startSystem
{
	self.scrollview.text = @"";
	self.iteration = 0;
	self.state = 0;
	
	self.currStateLabel.text = FORMAT(@"%5.2f", self.state);
	self.role = self.roleChooser.selectedSegmentIndex;
	[self.roleChooser setEnabled:FALSE forSegmentAtIndex:0];
	[self.roleChooser setEnabled:FALSE forSegmentAtIndex:1];
	[self.roleChooser setEnabled:FALSE forSegmentAtIndex:2];
	
	[self appendTxt:FORMAT(@"Your role is %d\n", self.role)];
	
	listenSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
	
	connectedSockets = [[NSMutableArray alloc] initWithCapacity:3];
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	
	int port = 7050;
	
	NSError *error = nil;
	if(![listenSocket bindToPort:port error:&error])
	{
		[self appendTxt:FORMAT(@"Cannot bind to port %d\n",port)];
		return;
	}
	
	if(![listenSocket joinMulticastGroup:@"225.0.11.6" error:&error])
	{
		[self appendTxt:@"couldnt join multicast"];		
		return;
	}
	
	timer = [NSTimer scheduledTimerWithTimeInterval: 2.0
									 target: self
								   selector:@selector(onTick:)
								   userInfo: nil
									repeats:YES]; 
    statesaver = [[NSString alloc] init];
    
	[listenSocket receiveWithTimeout:-1 tag:0];
}

- (void)onTick:(NSTimer *)t
{
	self.iteration++;
	NSLog(@"Iteration %d\n", self.iteration);
	//update and send my state
	float total = 0;
	int count = 0;
	
	//	calc state of neighs
	for (int i = 0; i < MAX_NBR_NUM; i++) 
	{
		if (nbr[i].age < 4 && nbr[i].idee != 99) {
			total += nbr[i].state;
			count++;
		}
		
		nbr[i].age++;
	}
	
	if (self.role == 0) 
	{
		total += 100.0;
		self.state = total;
		
		if (count != 0) 
		{
			self.state = total/count;
		}
	} else {
		self.state = total/(count+1);
	}
	
	self.currStateLabel.text = FORMAT(@"%5.2f", self.state);
    [self appendSaver:FORMAT(@"%d\t%5.2f\n", self.iteration, self.state)];
    
//	[self appendTxt:FORMAT(@"Count %d total %f state %f\n", count, total, self.state)];	
	
	//send the state now
	struct cutdet s1;
	s1.myid = role;
	s1.state = CFConvertFloat32HostToSwapped(self.state);

	NSData* usd = [NSData dataWithBytes:(void *) &s1 length:sizeof(s1)];
	[listenSocket sendData:usd toHost:@"225.0.11.6" port:7050 withTimeout:-1 tag:0];
}

- (void)stopSystem
{
	[self.timer invalidate];
	// Stop accepting connections
	[listenSocket close];
	
	[self.roleChooser setEnabled:TRUE forSegmentAtIndex:0];
	[self.roleChooser setEnabled:TRUE forSegmentAtIndex:1];
	[self.roleChooser setEnabled:TRUE forSegmentAtIndex:2];
	
	[self.roleChooser setSelectedSegmentIndex:self.role];
	
	// Stop any client connections
	int i;
	for(i = 0; i < [connectedSockets count]; i++)
	{
		// Call disconnect on the socket,
		// which will invoke the onSocketDidDisconnect: method,
		// which will remove the socket from the list.
		[[connectedSockets objectAtIndex:i] close];
	}
	

}


- (void)onSocket:(AsyncUdpSocket *)sock didAcceptNewSocket:(AsyncUdpSocket *)newSocket
{
	[connectedSockets addObject:newSocket];
}

- (void)onSocketDidDisconnect:(AsyncUdpSocket *)sock
{
	[connectedSockets removeObject:sock];
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
	unsigned char aBuffer[[data length]];
	[data getBytes:aBuffer];
	
//	[self appendTxt:FORMAT(@"recvd data\n")];

	struct cutdet t1;	
	memcpy(&t1, aBuffer, [data length]);
	
	float t1state = CFConvertFloat32SwappedToHost(t1.state);
	
	if (t1.myid == self.role) {
		return FALSE;
	}
	//	update age
	nbr[t1.myid].age = 0;
	nbr[t1.myid].state = t1state;
	nbr[t1.myid].idee = t1.myid;
	
	[self appendTxt:FORMAT(@"id %d state %f\n", t1.myid, t1state)];
	
//	t1.iteration = CFSwapInt16BigToHost(t1.moteid);
//	t1.state = CF;
	
	//	[self appendTxt:FORMAT(@"uint16_t %x %d\n", t1.moteid, sizeof(uint16_t))];
	//	[self appendTxt:FORMAT(@"float    %f %d\n", t1.loc   , sizeof(float   ))];
	//	[self appendTxt:FORMAT(@"string   %s %d\n", t1.street, sizeof(char))];
	
//	[self appendTxt:FORMAT(@"%d %f %s\n", t1.moteid, t1.loc, t1.street)];
	//	NSLog(@"Recvd data of length %d",[data length]);
	//	[self appendTxt:FORMAT(@"Got something....\n")];
	
	[listenSocket receiveWithTimeout:-1 tag:0];
	return FALSE;
	
}


- (void)gethex:(uint8_t *)packet:(int) len
{
	int i;
	
	for (i = 0; i < len; i++)
		[self appendTxt:FORMAT(@"%02x ",packet[i])];
}





#pragma mark * Actions

- (IBAction)startOrStopAction:(id)sender
{
	#pragma unused(sender)
	
	if (!self.isStarted)
	{
		self.scrollview.text = @"started";
		self.isStarted = TRUE;
		[self.startstopButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self startSystem];
	}
	else {
		self.scrollview.text = @"stopped";
		self.isStarted = FALSE;
		[self.startstopButton setTitle:@"Start" forState:UIControlStateNormal];
		[self stopSystem];
	}


}


- (IBAction)emailAction:(id)sender
{

    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setSubject:FORMAT(@"Your role is %d\n", self.role)];
    [controller setMessageBody:statesaver isHTML:NO]; 
    if (controller) [self presentModalViewController:controller animated:YES];
    [controller release];
    
}

- (void)mailComposeController:(MFMailComposeViewController*)controller  
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"It's away!");
    }
    [self dismissModalViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	self.isStarted = FALSE;
	self.scrollview.text = @"";
	self.role = -1;
	self.iteration = 0;

	//	[self appendTxt:@"This app connects to a serialfowarder and reads\n"];
	for (int i=0; i<MAX_NBR_NUM; i++) 
	{
		nbr[i].age = 0;
		nbr[i].idee = 99;
		nbr[i].state = 0.0;
	}
	
}

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
    [super viewDidUnload];
	self.scrollview = nil;
	self.startstopButton = nil;
}



- (void)dealloc 
{
	[self->_startstopButton release];
	[self->_scrollview release];
	
    [super dealloc];
    
    [listenSocket closeAfterSendingAndReceiving];
    
    
    
    
    
    
    
}

@end
















//- (void)onSocket:(AsyncUdpSocket *)sock didReadData:(NSData *)data withTag:(long)tag
//{
//	uint8_t aBuffer[[data length]];
//	[data getBytes:aBuffer];
//	
////	NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length])];
////	NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
//	
////	NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
////	NSLog(FORMAT(@"Recvd data of length %d: %s",[data length], string));
//	
//	if ([data length] == 2)
//	{
//		NSLog(@"Connected to sf");
//		[self appendTxt:@"Connected to sf\n"];
////		NSString *msg = [[[NSString alloc] initWithData:data] autorelease];
////		NSLog(FORMAT(@"Next packet has length %@",msg));
//		[sock readDataToLength:1 withTimeout:-1 tag:0];
//	}
//	else if ([data length] == 1){
//		NSLog(@"next pkt length is %d", aBuffer[0]);
//		NSLog(@"%@", data);
//		[sock readDataToLength:aBuffer[0] withTimeout:-1 tag:0];
//	}
//	else {		
//		NSLog(@"got full AM pkt of length %d", [data length]);
//		NSLog(@"%@", data);
//		
//		self.scrollview.text = @"";
//		
//		if ([data length] >= 1 + SPACKET_SIZE && aBuffer[0] == SERIAL_TOS_SERIAL_ACTIVE_MESSAGE_ID)
//		{					
//			NSData *bodydata = [data subdataWithRange:NSMakeRange(1, [data length]-1)];
//			uint8_t msgdata[[bodydata length]];
//			[bodydata getBytes:msgdata];
//			
//			tmsg_t *msg = new_tmsg((void*) &msgdata, [bodydata length]);
//			NSLog(@"serial msg length is %d", tmsg_length(msg));
//			
//			[self appendTxt:FORMAT(@"dest: %u\n", spacket_header_dest_get(msg))];
//			[self appendTxt:FORMAT(@"src : %u\n", spacket_header_src_get(msg))];
//			[self appendTxt:FORMAT(@"lgth: %u\n", spacket_header_length_get(msg))];
//			[self appendTxt:FORMAT(@"grp : %u\n", spacket_header_group_get(msg))];
//			[self appendTxt:FORMAT(@"type: %u\n", spacket_header_type_get(msg))];
//			
//			[self gethex:(uint8_t *)tmsg_data(msg) + spacket_data_offset(0) :tmsg_length(msg) - spacket_data_offset(0)];
//			
//			[self appendTxt:@"\n"];
//			
//		}
//		else {
//			[self appendTxt:@"unknown format...\n"];
//		}
//		
//		//	read next pkt length
//		[sock readDataToLength:1 withTimeout:-1 tag:0];
//	}
//
//	[self.scrollview scrollRangeToVisible:NSMakeRange([self.scrollview.text length], 1)];
//	
////	[sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];
////	[sock readDataToLength:1 withTimeout:-1 tag:0];
////	[sock readDataWithTimeout:2 tag:0];
//}





//- (void)onSocket:(AsyncUdpSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
//{
//	
////	// for serialforwarder
////	NSString *us = @"U ";
////	NSData *usd = [us dataUsingEncoding:NSUTF8StringEncoding];
////	
////	[sock writeData:usd withTimeout:-1 tag:1];
////	[self appendTxt:@"Send connection request"];
////	
////	[sock readDataToLength:2 withTimeout:-1 tag:0];
//
//}
