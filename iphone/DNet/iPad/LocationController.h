//
//  LocationController.h
//
//  Created by Jinru on 12/19/09.
//  Copyright 2009 Arizona State University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Common.h"


// protocol for sending location updates to another view controller
@protocol LocationControllerDelegate
@required
- (void)locationUpdate:(CLLocation*)location;
@end

@interface LocationController : NSObject <CLLocationManagerDelegate>  {
    
	CLLocationManager* locationManager;
	CLLocation* location;
	id delegate;
    btagloc_t allbtags[20];
    
}

@property (nonatomic, retain) CLLocationManager* locationManager;
@property (nonatomic, retain) CLLocation* location;
@property (nonatomic, assign) id<LocationControllerDelegate>  delegate;

+ (LocationController*)sharedInstance; // Singleton method
- (btagloc_t *) getbtags;

@end
