//
//  UDPListenerTab.m
//  DNet
//
//  Created by Harsha on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LocationSenderClass.h"

@interface LocationSenderClass ()

@property (nonatomic, readwrite) BOOL                isStarted;

@end

@implementation LocationSenderClass

@synthesize scrollview = _scrollview;
@synthesize startstopButton = _startstopButton;
@synthesize isStarted;

@synthesize locationManager = _locationManager;
@synthesize locLabel = _locLabel;
@synthesize idChooser = _idChooser;

CLLocation* currLocation = nil;



- (void) appendTxt:(NSString *) string 
{
	self.scrollview.text = [NSString stringWithFormat:@"%@%@", self.scrollview.text, string];
}

- (void)startSystem
{
	self.scrollview.text = @"";
	listenSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
    NSError *error = nil;
    [listenSocket enableBroadcast:TRUE error:&error];

    
	connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
	
	[NSTimer scheduledTimerWithTimeInterval: 2.0
									target: self
									selector:@selector(onTick:)
									userInfo: nil
									repeats:YES]; 
}

- (void)onTick:(NSTimer *)t
{
	
//	[self appendTxt:@"sending loc\n"];
	
	phoneloc_t myloc;
	myloc.phoneid = self.idChooser.selectedSegmentIndex;
//	myloc.loc_x = NTOHF(currLocation.coordinate.latitude);
//	myloc.loc_y = NTOHF(currLocation.coordinate.longitude);
	
	
//	struct loc_obj loc1;
//	loc1.lat = currLocation.coordinate.latitude;
//	loc1.longtude = currLocation.coordinate.longitude;
	
//	NSString *us = FORMAT(@"%+.3f %+.3f\n", currLocation.coordinate.latitude, currLocation.coordinate.longitude);
//	NSData *usd = [us dataUsingEncoding:NSUTF8StringEncoding];
//	NSLog(@"about to send %s", us);
	
	NSData* usd = [NSData dataWithBytes:(void *) &myloc length:sizeof(phoneloc_t)];
	
	[listenSocket sendData:usd toHost:@"225.0.11.5" port:7500 withTimeout:-1 tag:0];
}

- (void)stopSystem
{
	// Stop accepting connections
	[listenSocket close];
	
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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];

	self.scrollview.text = @"starting app\n";
	self.isStarted = FALSE;
	
	if (nil == self.locationManager)
        self.locationManager = [[CLLocationManager alloc] init];
	
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
	self.locationManager.distanceFilter = 1;
	
    [self.locationManager startUpdatingLocation];
	

}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
	uint8_t aBuffer[[data length]];
	[data getBytes:aBuffer];
	
	//	NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length])];
	//	NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
	
	//	NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	NSLog(@"Recvd data of length %d",[data length]);
	[self appendTxt:FORMAT(@"Got something....\n")];
	return FALSE;
}

- (IBAction)startOrStopAction:(id)sender
{
	
	if (!self.isStarted)
	{
		self.scrollview.text = @"Click start to join a multicast group";
		self.isStarted = TRUE;
		[self.startstopButton setTitle:@"Stop" forState:UIControlStateNormal];
		[self startSystem];
	}
	else {
		self.scrollview.text = @"Stopped";
		self.isStarted = FALSE;
		[self.startstopButton setTitle:@"Start" forState:UIControlStateNormal];
		[self stopSystem];
	}
	
	
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
    // If it's a relatively recent event, turn off updates to save power
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
			  newLocation.coordinate.latitude,
			  newLocation.coordinate.longitude);
	currLocation = [newLocation copy];
	self.locLabel.text = FORMAT(@"%+.3f %+.3f\n", currLocation.coordinate.latitude, currLocation.coordinate.longitude);

}


- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	[listenSocket closeAfterSendingAndReceiving];
	
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


- (void)dealloc {
    [super dealloc];
    [listenSocket closeAfterSendingAndReceiving];
}


@end
