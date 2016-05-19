//
//  BTagMapView.m
//  DNet
//
//  Created by Harsha on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BTagMapView.h"

@interface BTagMapView ()

@end

@implementation BTagMapView
@synthesize mainmap;

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
    
    CLLocationCoordinate2D center; //disaster city
    center.latitude = 30.639;
    center.longitude = -96.339;
    
    MKCoordinateSpan span;
    span.latitudeDelta = 0.01;
    span.longitudeDelta = 0.01;
    
    MKCoordinateRegion region;
    region.center = center;
    region.span = span;
    
    mainmap.region = [mainmap regionThatFits:region];
}

- (void)viewDidUnload
{
    [self setMainmap:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [mainmap release];
    [super dealloc];
}
@end
