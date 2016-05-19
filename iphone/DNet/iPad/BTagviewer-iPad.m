//
//  BTagviewer-iPad.m
//  DNet
//
//  Created by Harsha on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BTagviewer-iPad.h"
#import "BtagAnnotation.h"


#define METERS_PER_MILE 1609.344

@interface BTagviewer_iPad ()

@end

@implementation BTagviewer_iPad
@synthesize streetmapimage;
@synthesize textviewforbtag;
@synthesize mainmap;
@synthesize locLabel = _locLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    mainmap.delegate = self;
    
    listenSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
	
	int port = 7004;
	
	NSError *error = nil;
	if(![listenSocket bindToPort:port error:&error])
	{
		return;
	}
	
	if(![listenSocket joinMulticastGroup:@"225.0.11.5" error:&error])
	{
		return;
	}
	[listenSocket enableBroadcast:TRUE error:&error];
	
	[listenSocket receiveWithTimeout:-1 tag:0];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locUP:) name:@"lalala" object:nil];
    
}

- (void) locUP:(NSNotification *) notifi
{
    NSLog(@"got notifi");
    CLLocation* new = [notifi object];
    self.locLabel.text = FORMAT(@"%+.6f %+.6f\n", new.coordinate.latitude, new.coordinate.longitude);
}

- (void)viewDidUnload
{
    [self setTextviewforbtag:nil];
    [self setStreetmapimage:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}



- (IBAction)removeallPressed:(id)sender {
    for (id<MKAnnotation> annotation in mainmap.annotations) {
        
        if (! [annotation isKindOfClass:[MKUserLocation class]] )
            [mainmap removeAnnotation:annotation];
    }
}

- (IBAction)pressedLocate:(id)sender {
    
    CLLocation * mycurrLocation = [LocationController sharedInstance].location;
    
    // 1
    CLLocationCoordinate2D zoomLocation = mycurrLocation.coordinate;
    
    // 2
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    // 3
    MKCoordinateRegion adjustedRegion = [mainmap regionThatFits:viewRegion];                
    // 4
    [mainmap setRegion:adjustedRegion animated:YES];
    
    

}


- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
//    CLLocation * mycurrLocation = [LocationController sharedInstance].location;
	unsigned char aBuffer[[data length]];
	[data getBytes:aBuffer];
	
	btagloc_t t2;	
	memcpy(&t2, aBuffer, [data length]);
    
    //  this is the most recent datarr
    btagloc_t* alllocs = [[LocationController sharedInstance] getbtags];
    uint16_t tempid = ntohs(t2.the_btag.mote_id);
    
    memcpy(alllocs+tempid, &t2, sizeof(btagloc_t));
    
    
//    // fake to make it look like its from the network
//    t2.location.loc_x = CFConvertFloat32HostToSwapped((float) mycurrLocation.coordinate.latitude * (1 + (rand()%5 - 2.5) * 0.00005)).v;
//    
//    
//    t2.location.loc_y = CFConvertFloat32HostToSwapped((float) mycurrLocation.coordinate.longitude * (1 + (rand()%5 - 2.5) * 0.00005)).v;
    
    //  refresh annotations
    [self removeallPressed:nil];
    
    for (int i=0; i<20; i++) {
        if (alllocs[i].the_btag.mote_id != 0) 
        {
            [mainmap addAnnotation:[[BtagAnnotation alloc] initWithData:(alllocs+i)]];
        }
    }

    
    
    [listenSocket receiveWithTimeout:-1 tag:0];
	return FALSE;
  
      
}

- (void) doResocket
{
    [listenSocket close];
}

- (IBAction)switchmaptypePressed:(UISegmentedControl*)sender {

    
    switch (sender.selectedSegmentIndex) {
        case 0:
            mainmap.mapType = MKMapTypeStandard;
            break;
        case 1:
            mainmap.mapType = MKMapTypeSatellite;
            break;
        case 2:
            mainmap.mapType = MKMapTypeHybrid;
            break;
        default:
            mainmap.mapType = MKMapTypeStandard;
            break;
    }
}

- (void)onUdpSocketDidClose:(AsyncUdpSocket *)sock;
{
    listenSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    
	
	int port = 7004;
	
	NSError *error = nil;
	if(![listenSocket bindToPort:port error:&error])
	{
		return;
	}
	
	if(![listenSocket joinMulticastGroup:@"225.0.11.5" error:&error])
	{
		return;
	}
	[listenSocket enableBroadcast:TRUE error:&error];
	
	[listenSocket receiveWithTimeout:-1 tag:0];
}


- (void) mapView:(MKMapView *)datmapView 
             didSelectAnnotationView:(MKAnnotationView *)view
{

    textviewforbtag.text = [view.annotation subtitle];
    // load street view
    
    NSString *temp = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/streetview?size=200x200&location=%f,%f&heading=235&sensor=false", (float) [view.annotation coordinate].latitude, (float) [view.annotation coordinate].longitude];

    NSLog(FORMAT(temp));
    
    streetmapimage.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:temp]]];
    
}
- (void)dealloc {
    [textviewforbtag release];
    [streetmapimage release];
    [super dealloc];
}
@end
