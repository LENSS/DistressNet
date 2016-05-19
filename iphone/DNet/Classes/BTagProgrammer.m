//
//  BTagProgrammer.m
//  DNet
//
//  Created by Harsha Chenji on 3/5/11.
//  Copyright 2011 Texas A&M. All rights reserved.
//

#import "BTagProgrammer.h"
#import "LocationController.h"
#import <CoreFoundation/CFByteOrder.h>

@implementation BTagProgrammer
@synthesize idLabel = _idLabel;
@synthesize idSlider = _idSlider;

@synthesize livingSlider = _livingSlider;
@synthesize deadSlider = _deadSlider;
@synthesize searchSlider = _searchSlider;

@synthesize livingLabel = _livingLabel;
@synthesize deadLabel = _deadLabel;
@synthesize searchLabel = _searchLabel;

@synthesize teamField = _teamField;
@synthesize addr1Field = _addr1Field;
@synthesize addr2Field = _addr2Field;
@synthesize sendButton = _sendButton;
@synthesize loclabel = _loclabel;
@synthesize hazardField = _hazardField;

- (IBAction)sliderAction:(UISlider*) sender
{

	int discreteValue = round([self.idSlider value]);
    [self.idSlider setValue:(float)discreteValue];	
	self.idLabel.text = FORMAT(@"ID: %d", discreteValue);

	if (sender == self.idSlider)
    {
//        NSLog(@"this is the id slider");
        
        btagloc_t* allbtaglocs = [[LocationController sharedInstance] getbtags];
        
        self.addr1Field.text = [NSString stringWithCString:allbtaglocs[discreteValue].the_btag.address encoding:NSASCIIStringEncoding];

        self.livingSlider.value = allbtaglocs[discreteValue].the_btag.living;
        self.deadSlider.value = allbtaglocs[discreteValue].the_btag.dead;
        
        return;
    }
    
//    NSLog(@"non-id sliders...");
    
    
	discreteValue = round([self.livingSlider value]);
    [self.livingSlider setValue:(float)discreteValue];	
	self.livingLabel.text = FORMAT(@"Living: %d", discreteValue);
	
	discreteValue = round([self.deadSlider value]);
    [self.deadSlider setValue:(float)discreteValue];	
	self.deadLabel.text = FORMAT(@"Dead: %d", discreteValue);

	discreteValue = round([self.searchSlider value]);
    [self.searchSlider setValue:(float)discreteValue];	
	self.searchLabel.text = FORMAT(@"Search Code: %d", discreteValue);
    
    
	
}

- (IBAction) sendAction:(id)sender
{
    CLLocation* btagcurrLocation = [LocationController sharedInstance].location;
    
    //  modify to send a btag_loc_t instead!
    int tempid = round([self.idSlider value]);
    NSLog(@"tempid is %d", tempid);
    
    btagloc_t* allbtaglocs = [[LocationController sharedInstance] getbtags];
    btagloc_t* combinedbtagloc = allbtaglocs + tempid;
    
//    NSLog(FORMAT(@"date entered is %s", combinedbtagloc.the_btag.date_entered));
	btag_t* btag = &(combinedbtagloc->the_btag);
//    memcpy(&btag, &combinedbtagloc.the_btag, sizeof(btag_t));
    
    NSLog(@"id in array is %d living is %d tent is %s", ntohs(btag->mote_id), btag->living, btag->time_entered);
    
	btag->mote_id = htons(tempid);
	strncpy(btag->address, [self.addr1Field.text UTF8String], 9);
	strncpy(btag->task_force, [[self.teamField titleForSegmentAtIndex:[self.teamField selectedSegmentIndex]] UTF8String], 9);
    

    
	btag->living = round([self.livingSlider value]);
	btag->dead = round([self.deadSlider value]);
    strncpy(btag->hazards, [[self.hazardField titleForSegmentAtIndex:[self.hazardField selectedSegmentIndex]] UTF8String], 9); 
	
       
    loc_t* loct = & combinedbtagloc->location;
    loct->id = btag->mote_id;
    loct->loc_x = CFConvertFloat32HostToSwapped((float) btagcurrLocation.coordinate.latitude).v;
    loct->loc_y = CFConvertFloat32HostToSwapped((float) btagcurrLocation.coordinate.longitude).v;
	
    NSData* usd = [NSData dataWithBytes:(void *) combinedbtagloc length:sizeof(btagloc_t)];
    [listenSocket sendData:usd toHost:@"225.0.11.5" port:7009 withTimeout:-1 tag:0];
	
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSUInteger newLength = [textField.text length] + [string length] - range.length;
	return (newLength > 9) ? NO : YES;
}

- (IBAction)resocketAction:(id)sender
{
	NSLog(@"Resocketing");
    
    [self doResocket];
}




- (void) doResocket
{
    NSLog(@"doingresock...");
    [listenSocket close];
}

- (void)onUdpSocketDidClose:(AsyncUdpSocket *)sock;
{
    listenSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    NSLog(@"recreated socket on btagprogrammer...\n");
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
	[self.addr1Field setDelegate:self];
	[self.addr2Field setDelegate:self];
	
	listenSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
//	connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    NSLog(@"CREATED socket on btagprogrammer...\n");
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locUP:) name:@"lalala" object:nil];


}

- (void)locUP:(NSNotification* ) noti
{
    CLLocation* btagcurrLocation = [noti object];
    self.loclabel.text = FORMAT(@"%+.3f %+.3f\n", btagcurrLocation.coordinate.latitude, btagcurrLocation.coordinate.longitude);
    
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    NSLog(@"got memory warning\n");
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [self setLoclabel:nil];
    [self setHazardField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
//    listenSocket = nil;
    NSLog(@"nulled out listensocket\n");
    
}


- (void)dealloc {
    [_loclabel release];
    [_hazardField release];
    [super dealloc];
//    [listenSocket closeAfterSendingAndReceiving];
//    listenSocket = nil;
    NSLog(@"dealloc called!\n");
}


@end
