//
//  BTagprogrammer-iPad.m
//  DNet
//
//  Created by Harsha on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BTagprogrammer-iPad.h"
#import "BTagviewer-iPad.h"

@interface BTagprogrammer_iPad ()

@end

@implementation BTagprogrammer_iPad
@synthesize taskforceChooser;
@synthesize idSlider;
@synthesize dentlabel;
@synthesize tentlabel;
@synthesize dexitlabel;
@synthesize texitlabel;
@synthesize idLabel;
@synthesize addressField;
@synthesize livingLabel;
@synthesize deadLabel;
@synthesize mainview;
@synthesize yourlocationLabel;
@synthesize deadSlider;
@synthesize livingSlider;
@synthesize hazardChooser;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSUInteger newLength = [textField.text length] + [string length] - range.length;
	return (newLength > 9) ? NO : YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.addressField setDelegate:self];
	
    
    mainview.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"btag-back.png"]];
    
    listenSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
//	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    NSLog(@"CREATED socket on btagprogrammer...\n");
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locUP:) name:@"lalala" object:nil];
    
    CLLocation* new = [LocationController sharedInstance].location;
    yourlocationLabel.text = FORMAT(@"%+.3f %+.3f\n", new.coordinate.latitude, new.coordinate.longitude);
}

- (void) locUP:(NSNotification *) notifi
{
    NSLog(@"got notifi in pogrammer");
    CLLocation* new = [notifi object];
    yourlocationLabel.text = FORMAT(@"%+.3f %+.3f\n", new.coordinate.latitude, new.coordinate.longitude);
}

- (void)viewDidUnload
{
    [self setMainview:nil];
    [self setYourlocationLabel:nil];
    [self setDeadSlider:nil];
    [self setLivingSlider:nil];
    [self setHazardChooser:nil];
    [self setTaskforceChooser:nil];
    [self setIdSlider:nil];
    [self setDentlabel:nil];
    [self setTentlabel:nil];
    [self setDexitlabel:nil];
    [self setTexitlabel:nil];
    [self setAddressField:nil];
    [self setIdLabel:nil];
    [self setLivingLabel:nil];
    [self setDeadLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return NO;
}

- (void)dealloc {
    [mainview release];
    [yourlocationLabel release];
    [deadSlider release];
    [livingSlider release];
    [hazardChooser release];
    [taskforceChooser release];
    [idSlider release];
    [dentlabel release];
    [tentlabel release];
    [dexitlabel release];
    [texitlabel release];
    [addressField release];
    [idLabel release];
    [livingLabel release];
    [deadLabel release];
    [super dealloc];
}
- (IBAction)programPressed:(id)sender 
{
    CLLocation* btagcurrLocation = [LocationController sharedInstance].location;
    
    //  modify to send a btag_loc_t instead!
    int tempid = round([idSlider value]);
    NSLog(@"tempid is %d", tempid);
    
    btagloc_t* allbtaglocs = [[LocationController sharedInstance] getbtags];
    btagloc_t* combinedbtagloc = allbtaglocs + tempid;
    
    //    NSLog(FORMAT(@"date entered is %s", combinedbtagloc.the_btag.date_entered));
	btag_t* btag = &(combinedbtagloc->the_btag);
    //    memcpy(&btag, &combinedbtagloc.the_btag, sizeof(btag_t));
    
    NSLog(@"id in array is %d living is %d tent is %s", ntohs(btag->mote_id), btag->living, btag->time_entered);
    
	btag->mote_id = htons(tempid);
	strncpy(btag->address, [addressField.text UTF8String], 9);
	strncpy(btag->task_force, [[taskforceChooser titleForSegmentAtIndex:[taskforceChooser selectedSegmentIndex]] UTF8String], 9);
    
    
    
	btag->living = round([self.livingSlider value]);
	btag->dead = round([self.deadSlider value]);
    strncpy(btag->hazards, [[hazardChooser titleForSegmentAtIndex:[hazardChooser selectedSegmentIndex]] UTF8String], 9); 
	
    
    loc_t* loct = & combinedbtagloc->location;
    loct->id = btag->mote_id;
    loct->loc_x = CFConvertFloat32HostToSwapped((float) btagcurrLocation.coordinate.latitude).v;
    loct->loc_y = CFConvertFloat32HostToSwapped((float) btagcurrLocation.coordinate.longitude).v;
	
    NSLog(@"sending data...");
    NSData* usd = [NSData dataWithBytes:(void *) combinedbtagloc length:sizeof(btagloc_t)];
    [listenSocket sendData:usd toHost:@"225.0.11.5" port:7009 withTimeout:-1 tag:0];

}
- (IBAction)sliderChanged:(id)sender 
{
    int discreteValue = lroundf(idSlider.value);
    [self.idSlider setValue:discreteValue];	
	idLabel.text = FORMAT(@"ID: %d", discreteValue);
    
	if (sender == self.idSlider)
    {
        //        NSLog(@"this is the id slider");
        
        btagloc_t* allbtaglocs = [[LocationController sharedInstance] getbtags];
        
        addressField.text = [NSString stringWithCString:allbtaglocs[discreteValue].the_btag.address encoding:NSASCIIStringEncoding];
        
        livingSlider.value = allbtaglocs[discreteValue].the_btag.living;
        deadSlider.value = allbtaglocs[discreteValue].the_btag.dead;
        
        return;
    }
    
    //    NSLog(@"non-id sliders...");
    
    
	discreteValue = round([self.livingSlider value]);
    [self.livingSlider setValue:(float)discreteValue];	
	self.livingLabel.text = FORMAT(@"Living: %d", discreteValue);
	
	discreteValue = round([self.deadSlider value]);
    [self.deadSlider setValue:(float)discreteValue];	
	self.deadLabel.text = FORMAT(@"Dead: %d", discreteValue);
    

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

@end
