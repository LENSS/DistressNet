//
//  BuildingTagClass.m
//  DNet
//
//  Created by Harsha on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BuildingTagClass.h"
#import <CoreFoundation/CFByteOrder.h>
#import <QuartzCore/QuartzCore.h>




@implementation BuildingTagClass

@synthesize allbox;


btagloc_t allbtaglocs[20];

- (void) appendTxt:(NSString *) string 
{
//	self.scrollview.text = [NSString stringWithFormat:@"%@%@", self.scrollview.text, string];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
//	self.scrollview.text = @"starting app\n";
//	self.scrollview.layer.borderWidth = 5.0f;
//	self.scrollview.layer.borderColor = [[UIColor grayColor] CGColor];
	
    memset(&allbtaglocs, 0, 20*sizeof(btagloc_t));
    
	listenSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
	connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	
	int port = 7004;
	
	NSError *error = nil;
	if(![listenSocket bindToPort:port error:&error])
	{
		[self appendTxt:@"couldnt bind..."];		
		return;
	}
	
	if(![listenSocket joinMulticastGroup:@"225.0.11.5" error:&error])
	{
		[self appendTxt:@"couldnt join multicast"];		
		return;
	}
	[listenSocket enableBroadcast:TRUE error:&error];
	
	[self appendTxt:FORMAT(@"Bound to port %d and joined multicast\n",port)];
	[listenSocket receiveWithTimeout:-1 tag:0];

	
}



- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
//	[self appendTxt:FORMAT(@"Recvd Building tag %d\n", [data length])];
	
	unsigned char aBuffer[[data length]];
	[data getBytes:aBuffer];
	
	btagloc_t t2;
	btag_t t1;
	memcpy(&t2, aBuffer, [data length]);
    memcpy(&t1, &t2.the_btag, sizeof(btag_t));
    
//	[self appendTxt:FORMAT(@"size of data is %d\n", [data length])];
	
	t1.mote_id = ntohs(t1.mote_id);
	t1.living = t1.living;
	t1.dead = t1.dead;
    
    memcpy(&allbtaglocs[t1.mote_id], &t2, sizeof(btagloc_t));
//    NSLog(@"memcpying to %d", t1.mote_id);
    
//	[self appendTxt:FORMAT(@"uint16_t %x %d\n", t1.moteid, sizeof(uint16_t))];
//	[self appendTxt:FORMAT(@"float    %f %d\n", t1.loc   , sizeof(float   ))];
//	[self appendTxt:FORMAT(@"string   %s %d\n", t1.street, sizeof(char))];
//	self.scrollview.text = @"";
	
//    NSLog(@"#%d %s %s by %s ent: %s %s ext: %s %s haz %s, %d Alive %d Dead search Code %d\n", 						   t1.mote_id, t1.address_line_1, t1.address_line_2, t1.task_force, t1.date_entered, t1.time_entered, t1.date_exited, t1.time_exited, t1.hazards, t1.living, t1.dead, t1.search_complete);
    
    
    [[self.allbox objectAtIndex:(t1.mote_id % 4)] setText:
     FORMAT(@"#%d %s by %s ent: %s %s ext: %s %s haz %s, %d Alive %d Dead\n", 						   t1.mote_id, t1.address, t1.task_force, t1.date_entered, t1.time_entered, t1.date_exited, t1.time_exited, t1.hazards, t1.living, t1.dead)];
    
//    
//	[self appendTxt:FORMAT(@"%d\n %s\n %s\n %s\n %d\n %d\n %d\n", 						   t1.moteid, t1.addr1, t1.addr2, t1.force, t1.living, t1.dead, t1.scomp)];
//	NSLog(@"Recvd data of length %d",[data length]);
//	[self appendTxt:FORMAT(@"Got something....\n")];
	
//	t1.moteid = CFSwapInt16HostToBig(t1.moteid);
//	t1.living = CFSwapInt16HostToBig(t1.living);
//	t1.dead =   CFSwapInt16HostToBig(t1.dead);
//	NSData* usd = [NSData dataWithBytes:(void *) &t1 length:sizeof(t1)];
//	[listenSocket sendData:usd toHost:@"225.0.11.5" port:7002 withTimeout:-1 tag:0];
	[listenSocket receiveWithTimeout:-1 tag:0];
	return FALSE;
}

- (IBAction)clearAction:(id)sender
{
//	self.scrollview.text = @"";
}

- (IBAction)resocketAction:(id)sender
{
//	self.scrollview.text = @"resocketing";
	
	[listenSocket closeAfterSendingAndReceiving];
	
	[listenSocket receiveWithTimeout:-1 tag:0];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [self setAllbox:nil];
}


- (void)dealloc {

    [super dealloc];
    [allbox release];
    
    [listenSocket closeAfterSendingAndReceiving];
//    listenSocket = nil;
//    NSLog(@"dealloc called!\n");
}

- (void) doResocket
{
//    NSLog(@"doingresock...");
    [listenSocket close];
}

- (void)onUdpSocketDidClose:(AsyncUdpSocket *)sock;
{
    listenSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    NSLog(@"recreated socket on btagreader...\n");
    int port = 7004;
	
	NSError *error = nil;
	if(![listenSocket bindToPort:port error:&error])
	{
		[self appendTxt:@"couldnt bind..."];		
		return;
	}
	
	if(![listenSocket joinMulticastGroup:@"225.0.11.5" error:&error])
	{
		[self appendTxt:@"couldnt join multicast"];		
		return;
	}
	[listenSocket enableBroadcast:TRUE error:&error];
	
	[self appendTxt:FORMAT(@"Bound to port %d and joined multicast\n",port)];
	[listenSocket receiveWithTimeout:-1 tag:0];

}

@end
