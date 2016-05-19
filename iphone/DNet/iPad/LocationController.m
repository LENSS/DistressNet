//
//  LocationController.m
//
//  Created by Jinru on 12/19/09.
//  Copyright 2009 Arizona State University. All rights reserved.
//

#import "LocationController.h"

static LocationController* sharedCLDelegate = nil;

@implementation LocationController
@synthesize locationManager, location, delegate;

- (id)init
{
 	self = [super init];
	if (self != nil) {
		self.locationManager = [[[CLLocationManager alloc] init] autorelease];
		self.locationManager.delegate = self;
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = 1;
    }
	return self;
}

- (void)dealloc
{
	/* ... */
    [super dealloc];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager*)manager
	didUpdateToLocation:(CLLocation*)newLocation
		   fromLocation:(CLLocation*)oldLocation
{
    
    self.location = [newLocation copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"lalala" object:newLocation];
    
}

- (void)locationManager:(CLLocationManager*)manager
	   didFailWithError:(NSError*)error
{
    /* ... */
    
}

#pragma mark -
#pragma mark Singleton Object Methods
// THE FOLLOWING CODE IS NO LONGER SUPPORTED IN ARC
+ (LocationController*)sharedInstance {
    @synchronized(self) {
        if (sharedCLDelegate == nil) {
            [[self alloc] init];
        }
    }
    return sharedCLDelegate;
}

- (btagloc_t*) getbtags {
    return allbtags;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedCLDelegate == nil) {
            sharedCLDelegate = [super allocWithZone:zone];
            return sharedCLDelegate;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}

- (oneway void) release {
    //do nothing
}

- (id)autorelease {
    return self;
}
@end